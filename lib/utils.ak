use aiken/collection/pairs
use aiken/crypto
use aiken/interval.{Finite, Interval, IntervalBound, PositiveInfinity}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{AssetName, Value, PolicyId}
use cardano/transaction.{InlineDatum, Input, Output, Withdraw}
use daken/convert
use daken/flist
use daken/types.{Basis, Blake2b224Hash, Redeemers, TupleAsset} as daken_types

pub fn get_ref_by_idx(ref_inputs: List<Input>, idx: Int, tk: TupleAsset) -> Data {
  expect Input {
    output: Output { value: ref_val, datum: InlineDatum(ref_dt), .. },
    ..
  } = ref_inputs |> flist.get(idx)
  let (pid, tn) = tk
  expect assets.quantity_of(ref_val, pid, tn) == 1
  ref_dt
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

pub fn get_ref_by_idx_with_remain(
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

pub fn get_ticket_token_name(
  unique_key: ByteArray,
  option_idx: Int,
) -> AssetName {
  option_idx
    |> convert.int_to_digit
    |> bytearray.concat(unique_key, _)
    |> crypto.blake2b_224
}

pub fn check_tokens_qty(
  value: Value,
  policy_id: PolicyId,
  tokens: List<AssetName>,
) -> (Bool, Int) {
  do_check_token_qty(value, policy_id, 0, 0, tokens)
}

fn do_check_token_qty(
  value: Value,
  policy_id: PolicyId,
  pre_qty: Int,
  idx: Int,
  tokens: List<AssetName>,
) -> (Bool, Int) {
  when tokens is {
    [] -> (True, pre_qty)
    [x, ..rest] -> {
      let qty = assets.quantity_of(value, policy_id, x)      
      if idx == 0 || (qty == pre_qty && qty > 0) {
        do_check_token_qty(value, policy_id, qty, idx + 1, rest)
      } else {
        (False, pre_qty)
      }
    }
  }
}
