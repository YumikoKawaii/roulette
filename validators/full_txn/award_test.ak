// use aiken/collection/dict
// use aiken/crypto.{ScriptHash}
// use aiken/interval
// use cardano/address.{Script}
// use cardano/assets
// use cardano/transaction.{
//   InlineDatum, Input, Mint, NoDatum, Output, Spend, Transaction, Withdraw,
// }
// use constants
// use full_txn/constants as test_constants
// use liqwid_award
// use liqwid_sc
// use types.{
//   Award, LiqwidBorrow, LiqwidSupply, MarketStateDatum, OracleParams,
//   PlatformConfig, ProtocolParams, SessionDatum,
// }
// use utils

// fn base_cfg(tour_skh: ScriptHash) -> Input {
//   Input {
//     output_reference: test_constants.cfg_ref,
//     output: Output {
//       address: address.from_script(test_constants.sm_pkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//       datum: InlineDatum(
//         PlatformConfig {
//           tk_pp: test_constants.tk_pp,
//           tour_skh,
//           withdraw_init: "",
//           withdraw_award: test_constants.withdraw_award,
//           withdraw_redeem: "",
//           tx_ttl: 15 * 60 * 1000,
//           slot: test_constants.slot_cfg,
//         },
//       ),
//       reference_script: None,
//     },
//   }
// }

// fn base_pp() -> Input {
//   Input {
//     output_reference: test_constants.pp_ref,
//     output: Output {
//       address: address.from_script(test_constants.tk_pp.1st),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_constants.tk_pp.1st, test_constants.tk_pp.2nd, 1),
//       datum: InlineDatum(
//         ProtocolParams {
//           markets: [("pid1", "asset1"), ("pid2", "asset2")],
//           min_duration_in_ms: 200,
//           fee: test_constants.platform_fee,
//           organizer_award: test_constants.organizer_award,
//           fee_addr: address.from_verification_key("fee wallet"),
//         },
//       ),
//       reference_script: None,
//     },
//   }
// }

// fn base_ms() -> Input {
//   Input {
//     output_reference: test_constants.ms_ref,
//     output: Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(test_constants.min_ada)
//         |> assets.add("pid1", "asset1", 1),
//       datum: InlineDatum(
//         MarketStateDatum {
//           total_supply_amt: 0,
//           total_reserve_amt: 0,
//           total_minted_qtoken: 0,
//           total_borrowed_amt: 0,
//           total_interest_amt: 0,
//           interest_index: test_constants.award_interest_index,
//           last_interest_at: test_constants.award_interest_time,
//           last_batching_at: 0,
//           interest_rate: (0, 0),
//           qtoken_rate: test_constants.award_qtoken_rate,
//           min_ada: test_constants.min_ada,
//         },
//       ),
//       reference_script: None,
//     },
//   }
// }

// test success_award_supply_session() {
//   let unique_key = "unique_key"

//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let pp = base_pp()
//   let ms = base_ms()

//   let award_qty = test_constants.ticket_sales * 10 * test_constants.ticket_price
//   let platform_fee = award_qty * test_constants.platform_fee / 10_000
//   let organizer_prize = award_qty * test_constants.organizer_award / 10_000
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       predict_type: LiqwidSupply,
//       ticket_options: [
//         interval.between(0, 10),
//         interval.between(11, 20),
//         interval.after(21),
//       ],
//       ticket_per_option: test_constants.ticket_per_option,
//       ticket_price: test_constants.ticket_price,
//       unique_key,
//       session_time: interval.between(100, 400),
//       oracle_params: Some(
//         OracleParams {
//           interest_index: test_constants.trigger_qtoken_rate.1st * test_constants.basis_base / test_constants.trigger_qtoken_rate.2nd,
//           interest_time: test_constants.trigger_interest_time,
//         },
//       ),
//       ticket_win: None,
//       tx_ttl: 15 * 60 * 1000,
//       slot: test_constants.slot_cfg,
//     }
//   let in_session =
//     Input {
//       output_reference: test_constants.session_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh)
//           |> address.with_delegation_key(test_constants.organizer_stkh),
//         value: assets.from_lovelace(
//           constants.min_ada + test_constants.ticket_sales * 10 * test_constants.ticket_price,
//         )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option - test_constants.ticket_sales * 2,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option - test_constants.ticket_sales * 3,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option - test_constants.ticket_sales * 4,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }
  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + award_qty - platform_fee,
//       ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           oracle_params: Some(OracleParams{
//               interest_index: test_constants.award_qtoken_rate.1st * test_constants.basis_base / test_constants.award_qtoken_rate.2nd,
//                 interest_time: test_constants.award_interest_time,
//             }),
//             ticket_win: Some((
//               Some(utils.get_ticket_token_name(unique_key, 2)),
//               (award_qty - platform_fee - organizer_prize) / (test_constants.ticket_sales * 4),
//               test_constants.ticket_sales * 4, 
//             )),
//         },
//       ),
//       reference_script: None,
//     }
//   let ou_fee =
//     Output {
//       address: address.from_verification_key("fee wallet"),
//       value: assets.from_lovelace(platform_fee),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let rdmr =
//     Award {
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       ref_market_state_idx: 0,
//       in_session_idx: 0,
//       ou_session_idx: 0,
//       ou_fee_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let rdmr_data: Data = rdmr
//   let withdraw = Script(test_constants.withdraw_award)
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [cfg, pp, ms],
//       outputs: [out_session, ou_fee],
//       fee: 0,
//       mint: assets.zero
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             -(test_constants.ticket_per_option - test_constants.ticket_sales * 2),
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             -(test_constants.ticket_per_option - test_constants.ticket_sales * 3),
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             -(test_constants.ticket_per_option - test_constants.ticket_sales * 4),
//           ),
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(500, 525),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Spend(test_constants.session_ref), rdmr_data),
//         Pair(Mint(test_constants.sm_pkh), rdmr_data),
//         Pair(Withdraw(withdraw), rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.spend(
//       test_constants.tk_cfg,
//       None,
//       rdmr,
//       test_constants.session_ref,
//       tx,
//     ),
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_award.execute.withdraw(test_constants.tk_cfg, rdmr, withdraw, tx),
//   }
// }
