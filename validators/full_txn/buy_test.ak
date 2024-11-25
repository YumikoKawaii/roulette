// // success_buy_ticket_from_a_session
// // success_buy_ticket_from_multiple_sessions
// // fail_buy_ticket_mismatch_ticket_sales
// // fail_buy_ticket_session_datum_change
// // fail_buy_ticket_after_session_time_lowerbound
// // fail_buy_ticket_incorrect_ou_session_idx
// // fail_buy_ticket_incorrect_ticket_name

// use aiken/collection/dict
// use aiken/interval
// use cardano/address
// use cardano/assets
// use cardano/transaction.{InlineDatum,
//   Input, NoDatum, Output, Spend, Transaction}
// use constants
// use daken/inputs_hash
// use full_txn/constants as test_constants
// use liqwid_sc
// use types.{Buy, LiqwidSupply, SessionDatum}
// use utils

// test success_buy_ticket_from_a_session() {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }

// test success_buy_ticket_from_multiple_sessions() {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
//   let sc_0 = test_constants.sm_pkh
//   let sc_1 = "test_constants.sm_pkh"
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
//       oracle_params: None,
//       ticket_win: None,
//       tx_ttl: 15 * 60 * 1000,
//       slot: test_constants.slot_cfg,
//     }
//   let in_session_0 =
//     Input {
//       output_reference: test_constants.session_ref,
//       output: Output {
//         address: address.from_script(sc_0)
//           |> address.with_delegation_key(test_constants.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               sc_0,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               sc_0,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               sc_0,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   let in_session_1 =
//     Input {
//       output_reference: test_constants.session_ref_alter,
//       output: Output {
//         address: address.from_script(sc_1)
//           |> address.with_delegation_key(test_constants.organizer_stkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               sc_1,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               sc_1,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               sc_1,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             sc_0,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           )
//         |> assets.add(
//             sc_1,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session_0 =
//     Output {
//       address: address.from_script(sc_0)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             sc_0,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             sc_0,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             sc_0,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let out_session_1 =
//     Output {
//       address: address.from_script(sc_1)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             sc_1,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             sc_1,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             sc_1,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr_0 =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_0_data: Data = spend_rdmr_0
//   let spend_rdmr_1 =
//     Buy {
//       ou_session_idx: 1,
//       tickets: [utils.get_ticket_token_name(unique_key, 1)],
//     }
//   let spend_rdmr_1_data: Data = spend_rdmr_1
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session_0, in_session_1],
//       reference_inputs: [],
//       outputs: [out_session_0, out_session_1, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Spend(in_session_0.output_reference), spend_rdmr_0_data),
//         Pair(Spend(in_session_1.output_reference), spend_rdmr_1_data),
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
//       spend_rdmr_0,
//       in_session_0.output_reference,
//       tx,
//     ),
//     liqwid_sc.execute.spend(
//       test_constants.tk_cfg,
//       None,
//       spend_rdmr_1,
//       in_session_1.output_reference,
//       tx,
//     ),
//   }
// }

// test fail_buy_ticket_mismatch_ticket_sales() fail {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price + 10_000,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price - 10_000,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }

// test fail_buy_ticket_session_datum_change() fail {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           ..session_datum,
//           ticket_price: test_constants.ticket_price - 10_000,
//         },
//       ),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }

// test fail_buy_ticket_after_session_time_lowerbound() fail {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(125, 150),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }

// test fail_buy_ticket_incorrect_ou_session_idx() fail {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 1,
//       tickets: [utils.get_ticket_token_name(unique_key, 0)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }

// test fail_buy_ticket_incorrect_ticket_name() fail {
//   // Inputs  
//   let in_user =
//     Input {
//       output_reference: test_constants.wl_ref,
//       output: Output {
//         address: address.from_verification_key(test_constants.wl_pkh),
//         value: assets.from_lovelace(test_constants.user_lovelace),
//         datum: NoDatum,
//         reference_script: None,
//       },
//     }
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_user])
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
//       oracle_params: None,
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
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 0),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 1),
//               test_constants.ticket_per_option,
//             )
//           |> assets.add(
//               test_constants.sm_pkh,
//               utils.get_ticket_token_name(unique_key, 2),
//               test_constants.ticket_per_option,
//             ),
//         datum: InlineDatum(session_datum),
//         reference_script: None,
//       },
//     }

//   // Outputs  
//   let out_user =
//     Output {
//       address: address.from_verification_key(test_constants.wl_pkh),
//       value: assets.from_lovelace(
//         test_constants.user_lovelace - test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_sales,
//           ),
//       datum: NoDatum,
//       reference_script: None,
//     }
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(
//         constants.min_ada + test_constants.ticket_sales * test_constants.ticket_price,
//       )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             test_constants.ticket_per_option - test_constants.ticket_sales,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             test_constants.ticket_per_option,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             test_constants.ticket_per_option,
//           ),
//       datum: InlineDatum(session_datum),
//       reference_script: None,
//     }
//   let spend_rdmr =
//     Buy {
//       ou_session_idx: 0,
//       tickets: [utils.get_ticket_token_name(unique_key, 1)],
//     }
//   let spend_rdmr_data: Data = spend_rdmr
//   let tx =
//     Transaction {
//       inputs: [in_user, in_session],
//       reference_inputs: [],
//       outputs: [out_session, out_user],
//       fee: 0,
//       mint: assets.zero,
//       certificates: [],
//       withdrawals: [],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   liqwid_sc.execute.spend(
//     test_constants.tk_cfg,
//     None,
//     spend_rdmr,
//     test_constants.session_ref,
//     tx,
//   )
// }