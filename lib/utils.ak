use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto
use aiken/interval.{Finite, Interval, IntervalBound, IntervalBoundType, PositiveInfinity}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{AssetName}
use cardano/transaction.{InlineDatum, Input, Output, OutputReference, Withdraw, ValidityRange}
use constants
use daken/convert
use daken/flist
use daken/inputs_hash
use daken/types.{Redeemers, TupleAsset} as daken_types
use daken/time.{Seconds}
use types.{ResultParams}

pub fn get_input_by_idx(
  ref_inputs: List<Input>,
  idx: Int,
  tk: TupleAsset,
) -> Data {
  expect Input {
    output: Output { value: ref_val, datum: InlineDatum(ref_dt), .. },
    ..
  } = ref_inputs |> flist.get(idx)
  let (pid, tn) = tk
  expect assets.quantity_of(ref_val, pid, tn) == 1
  ref_dt
}

pub fn get_input_by_idx_with_remain(
  ref_inputs: List<Input>,
  idx: Int,
  tk: TupleAsset,
) -> (Data, List<Input>) {
  expect (
    Some(Input {
      output: Output { value: ref_val, datum: InlineDatum(ref_dt), .. },
      ..
    }),
    remain,
  ) = ref_inputs |> flist.get_with_tail(idx)
  let (pid, tn) = tk
  expect assets.quantity_of(ref_val, pid, tn) == 1
  (ref_dt, remain)
}

pub fn require_withdraw_idx(
  rdmrs: Redeemers,
  wd: Credential,
  idx: Int,
  expect_rdmr: Data,
) {
  when rdmrs |> pairs.get_all(Withdraw(wd)) is {
    [] -> fail @"not found withdraw redeemer"
    [_, ..] as f -> (flist.get(f, idx) == expect_rdmr)?
  }
}

pub fn calculate_apy(
  trigger_params: ResultParams,
  award_params: ResultParams,
) -> Int {
  let n =
    ( award_params.interest_index - trigger_params.interest_index ) * constants.year_in_ms
  let d =
    trigger_params.interest_index * (
      award_params.interest_time - trigger_params.interest_time
    )
  n * constants.basis_base / d
}

pub fn is_valid_range(
  self: List<Int>,
  session_token_id: ByteArray,
) -> (Bool, List<AssetName>) {
  self |> do_check_valid_range(session_token_id, 0, 0)
}

fn do_check_valid_range(
  self: List<Int>,
  session_token_id: ByteArray,
  idx: Int,
  prev: Int,
) -> (Bool, List<AssetName>) {
  when self is {
    [] -> (prev > 0, [get_ticket_token_name(session_token_id, idx)])
    [x, ..rest] ->
      if x > prev {
        let (rcs_bool, opts) =
          do_check_valid_range(rest, session_token_id, idx + 1, x)
        (
          True && rcs_bool,
          [get_ticket_token_name(session_token_id, idx), ..opts],
        )
      } else {
        (False, [])
      }
  }
}

pub fn get_nft_name(inputs: List<Input>) -> AssetName {
  inputs_hash.blake2b_224_quicksort_asc(inputs)
}

pub fn get_ticket_token_name(
  unique_key: ByteArray,
  option_idx: Int,
) -> AssetName {
  option_idx
    |> convert.int_to_digit
    |> bytearray.concat(unique_key, _)
    |> crypto.blake2b_224
}

pub fn get_input_by_out_ref(
  inputs: List<Input>,
  out_ref: OutputReference,
) -> Option<Input> {
  inputs
    |> list.foldr(
        None,
        fn(a, z) {
          if a.output_reference == out_ref {
            Some(a)
          } else {
            z
          }
        },
      )
}

pub fn get_transaction_time(validity_range: ValidityRange) -> (Seconds, Seconds) {
  expect Interval {
    lower_bound: IntervalBound { bound_type: Finite(tx_start_time), .. },
    upper_bound: IntervalBound { bound_type: Finite(tx_end_time), .. },
  } = validity_range
  (tx_start_time, tx_end_time)
}

pub fn generate_options(boudaries: List<Int>, prev: Int) -> List<Interval<Int>> {
  when boudaries is {
    [] -> [generate_option(Finite(prev), PositiveInfinity, True)]
    [x, ..rest] -> {
      [generate_option(Finite(prev), Finite(x), False), ..generate_options(rest, x)]
    }
  }
}

fn generate_option(from: IntervalBoundType<Int>, to: IntervalBoundType<Int>, is_upper_inclusive: Bool) -> Interval<Int> {
  Interval{
    lower_bound: IntervalBound {bound_type: from, is_inclusive: True},
    upper_bound: IntervalBound {bound_type: to, is_inclusive: is_upper_inclusive},
  }
}