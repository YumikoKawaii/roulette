use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, ValidityRange,
}
use constants
use daken/flist
use daken/time
use daken/types.{OK} as common_types
use types.{LiqwidSupply, MarketStateDatum, OracleParams, SessionDatum}
use utils

pub fn constraints(
  out_ref: OutputReference,
  ou_session_idx: Int,
  ref_market_state_idx: Int,
  inputs: List<Input>,
  outputs: List<Output>,
  ref_inputs: List<Input>,
  validity_range: ValidityRange,
) {
  // find input by out_ref
  expect Some(Input {
    output: Output {
      address: in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  }) = inputs |> utils.get_input_by_out_ref(out_ref)
  expect in_session_datum: SessionDatum = in_session_dt

  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(in_session_time_low), .. },
    upper_bound: IntervalBound { bound_type: Finite(in_session_time_hi), .. },
  } = in_session_datum.session_time

  // find output by index
  let Output {
    address: ou_session_addr,
    value: ou_session_val,
    datum: ou_session_dt,
    reference_script: ou_reference_script,
  } = outputs |> flist.get(ou_session_idx)

  // find market state
  expect ref_ms: MarketStateDatum =
    ref_inputs
      |> utils.get_input_by_idx(
          ref_market_state_idx,
          in_session_datum.oracle_policy,
        )

  let oracle_params =
    when in_session_datum.predict_type is {
      LiqwidSupply -> {
        let (qtoken_rate_num, qtoken_rate_deno) = ref_ms.qtoken_rate
        OracleParams {
          interest_index: qtoken_rate_num * constants.basis_base / qtoken_rate_deno,
          interest_time: ref_ms.last_interest_at,
        }
      }
      _ ->
        OracleParams {
          interest_index: ref_ms.interest_index,
          interest_time: ref_ms.last_interest_at,
        }
    }

  let expect_ou_session_dt =
    SessionDatum { ..in_session_datum, oracle_params: Some(oracle_params) }

  expect OK((tx_start_time, tx_end_time)) =
    time.tx_validity_valid_with_boundaries(
      validity_range,
      in_session_datum.slot.slot_length,
      Some(in_session_datum.tx_ttl),
      True,
    )

  and {
    (tx_start_time >= in_session_time_low)?,
    (tx_end_time <= in_session_time_hi)?,
    (in_session_addr == ou_session_addr)?,
    (in_session_val == ou_session_val)?,
    (InlineDatum(expect_ou_session_dt) == ou_session_dt)?,
    (ou_reference_script == None)?,
  }
}
