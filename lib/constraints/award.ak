use aiken/collection/dict
use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/assets.{Value}
use cardano/address.{Address, Script}
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, ValidityRange}
use constants
use daken/flist
use types.{
  LiqwidSupply, MarketStateDatum, ResultParams, PlatformConfig, SessionDatum, TicketWin,
}
use utils

pub fn constraints(  
  cfg_dt: Data,
  ref_ms_idx: Int,
  in_session_idx: Int,
  ou_session_idx: Int,
  ou_fee_idx: Int,
  inputs: List<Input>,
  outputs: List<Output>,
  ref_inputs: List<Input>,
  mint: Value,
  validity_range: ValidityRange,
) {
  expect platform_cfg: PlatformConfig = cfg_dt
  // find input by idx
  expect Input {
    output: Output {
      address: Address { payment_credential: Script(pid), .. } as in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  } = inputs |> flist.get(in_session_idx)
  expect in_session_datum: SessionDatum = in_session_dt

  // find market state
  expect ms_datum: MarketStateDatum =
    ref_inputs
      |> utils.get_input_by_idx(ref_ms_idx, in_session_datum.oracle_policy)

  expect Interval {
    upper_bound: IntervalBound { bound_type: Finite(session_time_hi), .. },
    ..
  } = in_session_datum.session_time
  expect Some(trigger_result_params) = in_session_datum.result_params
  let award_result_params =
    when in_session_datum.predict_type is {
      LiqwidSupply -> {
        let (qtoken_rate_num, qtoken_rate_deno) = ms_datum.qtoken_rate
        ResultParams {
          interest_index: qtoken_rate_num * constants.basis_base / qtoken_rate_deno,
          interest_time: ms_datum.last_interest_at,
        }
      }
      _ ->
        ResultParams {
          interest_index: ms_datum.interest_index,
          interest_time: ms_datum.last_interest_at,
        }
    }
  let apy = utils.calculate_apy(trigger_result_params, award_result_params)
  let (asset_win, ticket_sales, expect_burn_assets) =
    in_session_datum.ticket_options
      |> utils.generate_options(0)
      |> list.indexed_foldr(
          (None, 0, assets.zero),
          fn(idx, r, z) {
            let (asset_accum, sales_accum, burn_assets_accum) = z
            let asset =
              utils.get_ticket_token_name(in_session_datum.session_token_id, idx)
            let remain_qty = assets.quantity_of(in_session_val, pid, asset)
            let sales = in_session_datum.max_ticket_count_per_option - remain_qty
            let (a, s) =
              if r |> interval.contains(apy) {
                if sales > 0 {
                  (Some(asset), sales)
                } else {
                  (None, sales_accum + sales)
                }
              } else {
                if asset_accum == None {
                  (None, sales_accum + sales)
                } else {
                  (asset_accum, sales_accum)
                }
              }
            (a, s, burn_assets_accum |> assets.add(pid, asset, -remain_qty))
          },
        )
  let total_volume =
    assets.quantity_of(
      in_session_val,
      assets.ada_policy_id,
      assets.ada_asset_name,
    ) - constants.min_ada
  let fee_in_lovelace = total_volume * platform_cfg.fee / constants.basis_base
  let conversion_ratio =
    (
      total_volume - fee_in_lovelace - total_volume * platform_cfg.organizer_award / constants.basis_base
    ) / ticket_sales

  let expect_ou_session_datum =
    SessionDatum {
      ..in_session_datum,
      result_params: Some(award_result_params),
      ticket_win: Some(TicketWin{
        asset_win,
        conversion_ratio,
        remaining_award_ticket_qty: ticket_sales,
      }),
    }
  let expect_ou_session_val =
    assets.from_lovelace(total_volume - fee_in_lovelace + constants.min_ada)
  // check burn
  // find session output by idx
  expect (
    Some(Output {
      address: ou_session_addr,
      value: ou_sessison_val,
      datum: ou_session_dt,
      reference_script: ou_sessison_script,
    }),
    tail,
  ) = outputs |> flist.get_with_tail(ou_session_idx)
  // find fee output by idx
  let Output {
    address: ou_fee_addr,
    value: ou_fee_val,
    datum: ou_fee_dt,
    reference_script: ou_fee_script,
  } = tail |> flist.get(ou_fee_idx)

  let mint_assets =
    assets.from_asset_list(
      [
        Pair(
          pid,
          mint
            |> assets.tokens(pid)
            |> dict.to_pairs(),
        ),
      ],
    )

  let (tx_start_time, _) = utils.get_transaction_time(validity_range)
  and {
    (tx_start_time > session_time_hi)?,
    (in_session_addr == ou_session_addr)?,
    (InlineDatum(expect_ou_session_datum) == ou_session_dt)?,
    (expect_ou_session_val == ou_sessison_val)?,
    (ou_sessison_script == None)?,
    (platform_cfg.fee_addr == ou_fee_addr)?,
    (assets.from_lovelace(fee_in_lovelace) == ou_fee_val)?,
    (ou_fee_dt == NoDatum)?,
    (ou_fee_script == None)?,
    (expect_burn_assets == mint_assets)?,
  }
}
