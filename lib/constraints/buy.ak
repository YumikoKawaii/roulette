use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{AssetName}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, ValidityRange,
}
use daken/flist
use daken/time
use daken/types.{OK} as common_types
use types.{SessionDatum}
use utils

pub fn constraints(
  ou_session_idx: Int,
  tickets: List<AssetName>,
  out_ref: OutputReference,
  inputs: List<Input>,
  outputs: List<Output>,
  validity_range: ValidityRange,
) {
  // find input by out_ref
  expect Some(Input {
    output: Output {
      address: Address { payment_credential: Script(pid), .. } as in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  }) = inputs |> utils.get_input_by_out_ref(out_ref)
  expect in_session_datum: SessionDatum = in_session_dt

  // find output by idx
  expect Output {
    address: ou_session_addr,
    value: ou_session_val,
    datum: InlineDatum(ou_session_dt),
    reference_script: ou_reference_script,
  } = outputs |> flist.get(ou_session_idx)

  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(session_time_low), .. },
    ..
  } = in_session_datum.session_time
  let sold_ticket_quantity =
    tickets
      |> list.foldr(
          0,
          fn(a, z) {
            z + (
              assets.quantity_of(in_session_val, pid, a) - assets.quantity_of(
                ou_session_val,
                pid,
                a,
              )
            )
          },
        )
  let expect_lovelace_quantity =
    assets.quantity_of(
      in_session_val,
      assets.ada_policy_id,
      assets.ada_asset_name,
    ) + sold_ticket_quantity * in_session_datum.ticket_price
  let ou_lovelace_quantity =
    assets.quantity_of(
      ou_session_val,
      assets.ada_policy_id,
      assets.ada_asset_name,
    )

  expect OK((_, tx_end_time)) =
    time.tx_validity_valid_with_boundaries(
      validity_range,
      in_session_datum.slot.slot_length,
      Some(in_session_datum.tx_ttl),
      True,
    )

  and {
    (in_session_addr == ou_session_addr)?,
    (tx_end_time < session_time_low)?,
    (in_session_dt == ou_session_dt)?,
    (expect_lovelace_quantity == ou_lovelace_quantity)?,
    (ou_reference_script == None)?,
  }
}
