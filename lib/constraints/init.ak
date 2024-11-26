use aiken/collection/list
use aiken/crypto
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{Value}
use cardano/transaction.{InlineDatum, Input, Output, ValidityRange}
use constants
use types.{PlatformConfig, SessionDatum}
use utils

pub fn constraints(
  session: Output,
  ref_cfg_dt: Data,
  inputs: List<Input>,
  mint: Value,
  validity_range: ValidityRange,
) {
  expect platform_cfg: PlatformConfig = ref_cfg_dt

  let (_, tx_end_time) = utils.get_transaction_time(validity_range)

  let expect_session_token_id = inputs |> utils.get_nft_name()
  let expect_session_organizer_nft = crypto.blake2b_224(expect_session_token_id)

  expect Output {
    address: Address { payment_credential: Script(pid), .. },
    value: session_val,
    datum: InlineDatum(session_dt),
    reference_script: session_ref_script,
  } = session
  expect session_datum: SessionDatum = session_dt
  // verify ranges
  let (valid_options, opts) =
    session_datum.ticket_options
      |> utils.is_valid_range(expect_session_token_id)
  // calculate expect values
  let expect_session_tokens = list.foldr(
      opts,
      assets.zero,
      fn(a, z) {
        assets.add(z, pid, a, session_datum.max_ticket_count_per_option)
      },
    )
      |> assets.add(pid, expect_session_token_id, 1)    
  let expect_session_value = expect_session_tokens |> assets.add(assets.ada_policy_id, assets.ada_asset_name, constants.min_ada)      
  let expect_mint_value =
    expect_session_tokens      
      |> assets.add(pid, expect_session_organizer_nft, 1)
  // verify oracle policy
  let valid_oracle_policy =
    platform_cfg.markets |> list.any(fn(a) { a == session_datum.oracle_policy })
  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(session_time_low), .. },
    upper_bound: IntervalBound { bound_type: Finite(session_time_hi), .. },
  } = session_datum.session_time
  // verify ticket_price
  let valid_ticket_price = (session_datum.ticket_price >= platform_cfg.min_ticket_price) && (session_datum.ticket_price % 1_000_000 == 0)
  and {
    (session_ref_script == None)?,
    valid_oracle_policy?,
    (session_datum.session_token_id == expect_session_token_id)?,
    valid_options?,
    (list.length(opts) > 1)?,
    valid_ticket_price?,
    (tx_end_time < session_time_low)?,
    (session_time_low < session_time_hi)?,
    (expect_session_value == session_val)?,
    (expect_mint_value == mint)?,
    (session_datum.result_params == None)?,
    (session_datum.ticket_win == None)?,
    (session_datum.organizer_conversion_ratio == None)?,    
  }
}
