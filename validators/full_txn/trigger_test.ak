// // success_trigger_supply_session
// // success_trigger_borrow_session
// // fail_trigger_session_incorrect_oracle_policy
// // fail_trigger_session_incorrect_ou_session_idx
// // fail_trigger_session_incorrect_ref_market_state_idx
// // fail_trigger_session_incorrect_datum_wrong_oracle_params
// // fail_trigger_session_datum_change_except_oracle_params

// use aiken/collection/dict
// use aiken/interval
// use cardano/address
// use cardano/assets
// use cardano/transaction.{InlineDatum, Input, Output, Spend, Transaction}
// use constants
// use full_txn/test_data
// use liqwid_sc
// use types.{
//   LiqwidBorrow, LiqwidSupply, MarketStateDatum, ResultParams, SessionDatum,
//   Trigger,
// }
// use utils

// fn base_ms() -> Input {
//   Input {
//     output_reference: test_data.ms_ref,
//     output: Output {
//       address: address.from_verification_key(test_data.wl_pkh),
//       value: assets.from_lovelace(test_data.min_ada)
//         |> assets.add("pid1", "asset1", 1),
//       datum: InlineDatum(
//         MarketStateDatum {
//           total_supply_amt: 0,
//           total_reserve_amt: 0,
//           total_minted_qtoken: 0,
//           total_borrowed_amt: 0,
//           total_interest_amt: 0,
//           interest_index: test_data.trigger_interest_index,
//           last_interest_at: test_data.trigger_interest_time,
//           last_batching_at: 0,
//           interest_rate: (0, 0),
//           qtoken_rate: test_data.trigger_qtoken_rate,
//           min_ada: test_data.min_ada,
//         },
//       ),
//       reference_script: None,
//     },
//   }
// }

// test success_trigger_supply_session() {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // success_trigger_borrow_session
// test success_trigger_borrow_session() {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidBorrow,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_interest_index,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // fail_trigger_session_incorrect_oracle_policy
// test fail_trigger_session_incorrect_oracle_policy() fail {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset2"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // fail_trigger_session_incorrect_ou_session_idx
// test fail_trigger_session_incorrect_ou_session_idx() fail {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 1, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // fail_trigger_session_incorrect_ref_market_state_idx
// test fail_trigger_session_incorrect_ref_market_state_idx() fail {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 1 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // fail_trigger_session_incorrect_datum_wrong_result_params
// test fail_trigger_session_incorrect_datum_wrong_result_params() fail {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_interest_index,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }

// // fail_trigger_session_datum_change (except_result_params)
// test fail_trigger_session_datum_change() fail {
//   let session_token_id = "session_token_id"
//   // Inputs      
//   let session_datum =
//     SessionDatum {
//       oracle_policy: ("pid1", "asset1"),
//       session_token_id,
//       predict_type: LiqwidSupply,
//       ticket_options: [10, 20],
//       max_ticket_count_per_option: 1_000_000,
//       ticket_price: test_data.ticket_price,
//       session_time: interval.between(100, 400),
//       result_params: None,
//       ticket_win: None,
//       organizer_conversion_ratio: None,
//     }
//   let in_session =
//     Input {
//       output_reference: test_data.session_ref,
//       output: Output {
//         address: address.from_script(test_data.sm_pkh)
//           |> address.with_delegation_key(test_data.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_data.sm_pkh, session_token_id, 1)
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 0),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 1),
//               test_data.ticket_per_option,
//             )
//           |> assets.add(
//               test_data.sm_pkh,
//               utils.get_ticket_token_name(session_token_id, 2),
//               test_data.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs    
//   let out_session =
//     Output {
//       address: address.from_script(test_data.sm_pkh)
//         |> address.with_delegation_key(test_data.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(test_data.sm_pkh, session_token_id, 1)
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 0),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 1),
//             test_data.ticket_per_option,
//           )
//         |> assets.add(
//             test_data.sm_pkh,
//             utils.get_ticket_token_name(session_token_id, 2),
//             test_data.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           ticket_options: [],
//           result_params: Some(
//             ResultParams {
//               interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
//               interest_time: test_data.trigger_interest_time,
//             },
//           ),
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_session],
//       reference_inputs: [base_ms()],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(100, 125),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_data.tk_cfg,
//     None,
//     spend_rdmr,
//     test_data.session_ref,
//     tx,
//   )
// }
