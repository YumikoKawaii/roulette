use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto
use aiken/interval.{Finite, Interval, IntervalBound, PositiveInfinity}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{AssetName}
use cardano/transaction.{InlineDatum, Input, Output, OutputReference, Withdraw}
use constants
use daken/convert
use daken/flist
use daken/inputs_hash
use daken/types.{Basis, Redeemers, TupleAsset} as daken_types
use types.{OracleParams}

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
    [] -> fail @"not found mint redeemer"
    [_, ..] as f -> (flist.get(f, idx) == expect_rdmr)?
  }
}

pub fn calculate_apy(
  trigger_params: OracleParams,
  award_params: OracleParams,
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
  self: List<Interval<Basis>>,
  unique_key: ByteArray,
) -> (Bool, List<AssetName>) {
  self |> do_check_valid_range(unique_key, 0, 0, [])
}

fn do_check_valid_range(
  self: List<Interval<Basis>>,
  unique_key: ByteArray,
  idx: Int,
  pre_end: Int,
  options: List<AssetName>,
) -> (Bool, List<AssetName>) {
  when self is {
    [] -> (pre_end > 0, options)
    [x, ..rest] -> {
      let Interval {
        lower_bound: IntervalBound {
          bound_type: start,
          is_inclusive: start_is_inclusive,
        },
        upper_bound: IntervalBound {
          bound_type: end,
          is_inclusive: end_is_inclusive,
        },
      } = x

      let st_valid =
        if pre_end <= 0 {
          when start is {
            Finite(v) -> v == 0
            _ -> False
          }
        } else {
          when start is {
            Finite(v) -> v == pre_end + 1
            _ -> False
          }
        }

      let (next_pre_end, nd_valid) =
        if rest == [] {
          when end is {
            PositiveInfinity -> (pre_end, True)
            _ -> (pre_end, False)
          }
        } else {
          when end is {
            Finite(v) -> (v, v > pre_end)
            _ -> (pre_end, False)
          }
        }
      if and {
        (start_is_inclusive == True)?,
        (end_is_inclusive == True)?,
        st_valid?,
        nd_valid?,
      } {
        do_check_valid_range(
          rest,
          unique_key,
          idx + 1,
          next_pre_end,
          [get_ticket_token_name(unique_key, idx), ..options],
        )
      } else {
        (False, [get_ticket_token_name(unique_key, idx), ..options])
      }
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
