use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{Value}
use cardano/transaction.{InlineDatum, Input, Output, ValidityRange}
use constants
use daken/flist
use types.{SessionDatum}
use utils

pub fn constraints(  
  ou_session_idx: Int,
  inputs: List<Input>,
  outputs: List<Output>,
  mint: Value,
  validity_range: ValidityRange,
) {  
  let (_, tx_end_time) = utils.get_transaction_time(validity_range)

  let expect_session_token_id = inputs |> utils.get_nft_name()

  expect Output {
    address: Address { payment_credential: Script(pid), .. },
    value: ou_session_val,
    datum: InlineDatum(ou_session_dt),
    reference_script: ou_session_ref_script,
  } = outputs |> flist.get(ou_session_idx)
  expect session_datum: SessionDatum = ou_session_dt
  // verify ranges
  let (valid_options, opts) =
    session_datum.ticket_options
      |> utils.is_valid_range(expect_session_token_id)
  // verify tokens quantity  
  let expect_ou_session_value =
    list.foldr(
      opts,
      assets.from_lovelace(constants.min_ada),
      fn(a, z) {
        assets.add(z, pid, a, session_datum.max_ticket_count_per_option)
      },
    )
  // verify Session NFT is mint
  let session_nft_qty = mint |> assets.quantity_of(pid, expect_session_token_id)

  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(session_time_low), .. },
    upper_bound: IntervalBound { bound_type: Finite(session_time_hi), ..},
  } = session_datum.session_time

  and {
    (ou_session_ref_script == None)?,
    (session_datum.session_token_id == expect_session_token_id)?,
    valid_options?,
    (list.length(opts) > 1)?,
    (session_datum.ticket_price % 1_000_000 == 0)?,
    (tx_end_time < session_time_low)?,
    (session_time_low < session_time_hi)?,
    (expect_ou_session_value == ou_session_val)?,
    (session_nft_qty == 1)?,
    (session_datum.result_params == None)?,
    (session_datum.ticket_win == None)?,
  }
}
