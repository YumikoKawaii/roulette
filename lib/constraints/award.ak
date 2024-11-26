use aiken/collection/dict
use aiken/collection/list
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script}
use cardano/assets.{Value}
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, ValidityRange}
use constants
use daken/flist
use types.{
  LiqwidSupply, MarketStateDatum, PlatformConfig, ResultParams, SessionDatum,
  TicketWin,
}
use utils

pub fn constraints(
  in_session: Input,
  ou_session: Output,
  ou_fee_idx: Option<Int>,
  outputs: List<Output>,
  cfg_dt: Data,
  ms_dt: Data,
  mint: Value,
  validity_range: ValidityRange,
) {
  expect platform_cfg: PlatformConfig = cfg_dt
  expect ms_datum: MarketStateDatum = ms_dt
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
              utils.get_ticket_token_name(
                in_session_datum.session_token_id,
                idx,
              )
            let remain_qty = assets.quantity_of(in_session_val, pid, asset)
            let sales =
              in_session_datum.max_ticket_count_per_option - remain_qty
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
  let platform_fee = {
    let qty = total_volume * platform_cfg.fee / constants.basis_base
    if qty < constants.min_ada {
      0
    } else {
      qty
    }
  }

  let organizer_prize = {
    let qty = total_volume * platform_cfg.organizer_award / constants.basis_base
    if qty < constants.min_ada {
      0
    } else {
      qty
    }
  }

  let conversion_ratio =
    ( total_volume - platform_fee - organizer_prize ) / ticket_sales

  let expect_ou_session_datum =
    SessionDatum {
      ..in_session_datum,
      result_params: Some(award_result_params),
      ticket_win: Some(TicketWin { asset_win, conversion_ratio }),
      organizer_conversion_ratio: Some(organizer_prize),
    }
  let expect_ou_session_val =
    in_session_val
      |> assets.add(assets.ada_policy_id, assets.ada_asset_name, -platform_fee)
  // find session output by idx
  let Output {
    address: ou_session_addr,
    value: ou_sessison_val,
    datum: ou_session_dt,
    reference_script: ou_sessison_script,
  } = ou_session

  let valid_fee =
    when platform_fee is {
      0 -> True
      _ -> {
        expect Some(idx) = ou_fee_idx
        let Output {
          address: ou_fee_addr,
          value: ou_fee_val,
          datum: ou_fee_dt,
          reference_script: ou_fee_script,
        } = outputs |> flist.get(idx)
        and {
          (ou_fee_addr == platform_cfg.fee_addr)?,
          (ou_fee_val == assets.from_lovelace(platform_fee))?,
          (ou_fee_dt == NoDatum)?,
          (ou_fee_script == None)?,
        }
      }
    }

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
    valid_fee?,
    (expect_burn_assets == mint_assets)?,
    valid_utxo?,
  }
}
