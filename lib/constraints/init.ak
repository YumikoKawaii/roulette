use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId, Value}
use cardano/transaction.{InlineDatum, Input, Output, ValidityRange}
use constants
use daken/flist
use daken/inputs_hash
use daken/time.{SlotConfig}
use daken/types.{OK} as common_types
use types.{ProtocolParams, SessionDatum}
use utils

pub fn constraints(
  pp_dt: Data,
  pid: PolicyId,
  ou_session_idx: Int,
  inputs: List<Input>,
  outputs: List<Output>,
  mint: Value,
  validity_range: ValidityRange,
  tx_ttl: Int,
  slot: SlotConfig,
) {
  expect pp_datum: ProtocolParams = pp_dt

  expect OK((_, tx_end_time)) =
    time.tx_validity_valid_with_boundaries(
      validity_range,
      slot.slot_length,
      Some(tx_ttl),
      True,
    )

  let expect_unique_key = inputs_hash.blake2b_224_sort_asc(inputs)

  expect Output {
    address: Address { payment_credential: ou_session_pkh, .. } as ou_session_addr,
    value: ou_session_val,
    datum: InlineDatum(ou_session_dt),
    reference_script: ou_session_ref_script,
  } = outputs |> flist.get(ou_session_idx)

  expect session_datum: SessionDatum = ou_session_dt

  // verify market state policy
  let valid_oracle_policy =
    pp_datum.markets |> list.any(fn(a) { a == session_datum.oracle_policy })

  // verify ranges
  let (valid_options, opts) =
    session_datum.ticket_options |> utils.is_valid_range(expect_unique_key)

  // verify tokens quantity
  let expect_ou_session_value =
    assets.from_asset_list(
      [
        Pair(
          pid,
          list.foldr(
            opts,
            [],
            fn(a, z) { [Pair(a, session_datum.ticket_per_option), ..z] },
          ),
        ),
      ],
    )
      |> assets.add(assets.ada_policy_id, assets.ada_asset_name, constants.min_ada)

  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(session_time_low), .. },
    ..
  } = session_datum.session_time

  and {
    (ou_session_ref_script == None)?,
    valid_oracle_policy?,
    valid_options?,
    (session_datum.ticket_price % 1_000_000 == 0)?,
    (tx_end_time < session_time_low)?,    
    (expect_ou_session_value == ou_session_val)?,
    (session_datum.oracle_params == None)?,
    (session_datum.ticket_win == None)?,
    (session_datum.tx_ttl == tx_ttl)?,
    (session_datum.slot == slot)?,
  }
}
