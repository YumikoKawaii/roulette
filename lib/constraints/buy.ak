use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{AssetName}
use cardano/transaction.{InlineDatum, Input, Output, ValidityRange}
use types.{SessionDatum}
use utils

pub fn constraints(
  in_session: Input,
  ou_sesison: Output,
  tickets: List<AssetName>,
  validity_range: ValidityRange,
) {
  expect Input {
    output: Output {
      address: Address { payment_credential: Script(pid), .. } as in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  } = in_session
  expect in_session_datum: SessionDatum = in_session_dt
    
  expect Output {
    address: ou_session_addr,
    value: ou_session_val,
    datum: InlineDatum(ou_session_dt),
    reference_script: ou_reference_script,
  } = ou_sesison

  // verify Session Verification NFT
  let valid_utxo = (in_session_val |> assets.quantity_of(pid, in_session_datum.session_token_id)) == 1

  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(session_time_low), .. },
    ..
  } = in_session_datum.session_time

  let expect_session_value = tickets |> list.foldr(
    in_session_val,
    fn(a, z) {
      let ticket_qty = assets.quantity_of(in_session_val, pid, a) - assets.quantity_of(ou_session_val,pid,a)
      z |> assets.add(assets.ada_policy_id, assets.ada_asset_name, ticket_qty * in_session_datum.ticket_price) |> assets.add(pid, a, -ticket_qty)
    }
  )   

  let (_, tx_end_time) = utils.get_transaction_time(validity_range)

  and {
    (in_session_addr == ou_session_addr)?,
    (tx_end_time < session_time_low)?,
    (in_session_dt == ou_session_dt)?,
    (expect_session_value == ou_session_val)?,
    (ou_reference_script == None)?,
    valid_utxo?,
  }
}
