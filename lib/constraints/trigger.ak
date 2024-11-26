use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/transaction.{
  InlineDatum, Input, Output, ValidityRange,
}
use cardano/address.{Address, Script}
use cardano/assets
use constants
use types.{LiqwidSupply, MarketStateDatum, ResultParams, SessionDatum}
use utils

pub fn constraints(
  in_session: Input, 
  ou_session: Output,
  ref_ms_dt: Data,
  validity_range: ValidityRange,
) {
  // find input by out_ref
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

  // verify Session Verification NFT
  let valid_utxo = (in_session_val |> assets.quantity_of(pid, in_session_datum.session_token_id)) == 1

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
  } = ou_session

  // find market state
  expect ref_ms: MarketStateDatum = ref_ms_dt

  let result_params =
    when in_session_datum.predict_type is {
      LiqwidSupply -> {
        let (qtoken_rate_num, qtoken_rate_deno) = ref_ms.qtoken_rate
        ResultParams {
          interest_index: qtoken_rate_num * constants.basis_base / qtoken_rate_deno,
          interest_time: ref_ms.last_interest_at,
        }
      }
      _ ->
        ResultParams {
          interest_index: ref_ms.interest_index,
          interest_time: ref_ms.last_interest_at,
        }
    }

  let expect_ou_session_dt =
    SessionDatum { ..in_session_datum, result_params: Some(result_params) }

  let (tx_start_time, tx_end_time) = utils.get_transaction_time(validity_range)

  and {
    (tx_start_time >= in_session_time_low)?,
    (tx_end_time <= in_session_time_hi)?,
    (in_session_addr == ou_session_addr)?,
    (in_session_val == ou_session_val)?,
    (InlineDatum(expect_ou_session_dt) == ou_session_dt)?,
    (ou_reference_script == None)?,
    valid_utxo?,
  }
}
