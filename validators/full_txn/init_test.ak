// // success_init_session
// // success_init_multiple_sessions
// // fail_init_incorrect_oracle_policy
// // fail_init_incorrect_ticket_options_range
// // fail_init_incorrect_ticket_options_quantity (number of options < 2)
// // fail_init_incorrect_ticket_per_options
// // fail_init_incorrect_ticket_price
// // fail_init_incorrect_unique_key
// // fail_init_incorrect_session_time_range_too_small (hi - low < min_durations_in_ms)
// // fail_init_incorrect_session_time_in_past (low > tx_start_time)
// // fail_init_oracle_params_not_null
// // fail_init_ticket_win_not_null
// // fail_init_incorrect_tx_ttl
// // fail_init_incorrect_slot
// // fail_init_mint_missing_session_nft
// // fail_init_mint_missing_ticket_tokens
// // fail_init_incorrect_ref_cfg_idx
// // fail_init_incorrect_ref_pp_idx
// // fail_init_incorrect_ou_session_idx
// // fail_init_incorrect_withdraw_rdmr_idx

// use aiken/collection/dict
// use aiken/crypto.{ScriptHash}
// use aiken/interval
// use cardano/address.{Script}
// use cardano/assets
// use cardano/transaction.{
//   InlineDatum, Input, Mint, NoDatum, Output, Transaction, Withdraw,
// }
// use constants
// use daken/inputs_hash
// use daken/time.{SlotConfig}
// use full_txn/constants as test_constants
// use full_txn/fixture/output_builder
// use liqwid_init
// use liqwid_sc
// use types.{
//   Init, LiqwidSupply, OracleParams, PlatformConfig, ProtocolParams, SessionDatum,
// }
// use utils

// fn base_cfg(tour_skh: ScriptHash) {
//   PlatformConfig {
//     tk_pp: test_constants.tk_pp,
//     tour_skh,
//     withdraw_init: test_constants.withdraw_init,
//     withdraw_award: "",
//     withdraw_redeem: "",    
//     tx_ttl: 15 * 60 * 1000,
//     slot: test_constants.slot_cfg,
//   }
// }

// fn base_pp() {
//   ProtocolParams {
//     markets: [("pid1", "asset1"), ("pid2", "asset2")],
//     min_duration_in_ms: 200,
//     fee: 500,
//     organizer_award: 500,
//     fee_addr: address.from_verification_key("fee wallet"),
//   }
// }

// test success_init_session() {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 3),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 4),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.between(21, 25),
//             interval.between(26, 30),
//             interval.after(31),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 3),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 4),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test success_init_multiple_sessions() {
//   // Reference Inputs
//   let sm_0 = test_constants.sm_pkh
//   let cfg_0 = base_cfg(sm_0)
//   let cfg_0_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(sm_0),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg_0),
//         reference_script: None,
//       },
//     }
//   let sm_1 = "test_constants.sm_pkh"
//   let cfg_1 = base_cfg(sm_1)
//   let cfg_1_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(sm_1),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg_1),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(test_constants.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_pp.1st, test_constants.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session_0 =
//     Output {
//       address: address.from_script(sm_0)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(sm_0, utils.get_ticket_token_name(unique_key, 0), 1_000_000)
//         |> assets.add(sm_0, utils.get_ticket_token_name(unique_key, 1), 1_000_000),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [interval.between(0, 10), interval.after(11)],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg_0.tx_ttl,
//           slot: cfg_0.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let out_session_1 =
//     Output {
//       address: address.from_script(sm_1)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(sm_1, utils.get_ticket_token_name(unique_key, 0), 1_000_000)
//         |> assets.add(sm_1, utils.get_ticket_token_name(unique_key, 1), 1_000_000),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [interval.between(0, 10), interval.after(11)],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg_1.tx_ttl,
//           slot: cfg_1.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr_0 =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 1,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_0_data: Data = mint_rdmr_0
//   let mint_rdmr_1 =
//     Init {
//       ou_session_idx: 1,
//       ref_cfg_idx: 1,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 1,
//     }
//   let mint_rdmr_1_data: Data = mint_rdmr_1
//   let withdraw = Script(cfg_0.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_0_in, cfg_1_in, pp_in],
//       outputs: [out_session_0, out_session_1],
//       fee: 0,
//       mint: assets.from_asset(sm_0, unique_key, 1)
//         |> assets.add(sm_0, utils.get_ticket_token_name(unique_key, 0), 1_000_000)
//         |> assets.add(sm_0, utils.get_ticket_token_name(unique_key, 1), 1_000_000)
//         |> assets.add(sm_1, unique_key, 1)
//         |> assets.add(sm_1, utils.get_ticket_token_name(unique_key, 0), 1_000_000)
//         |> assets.add(sm_1, utils.get_ticket_token_name(unique_key, 1), 1_000_000),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(sm_0), mint_rdmr_0_data),
//         Pair(Mint(sm_1), mint_rdmr_1_data),
//         Pair(Withdraw(withdraw), mint_rdmr_0_data),
//         Pair(Withdraw(withdraw), mint_rdmr_1_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(test_constants.tk_cfg, mint_rdmr_0, sm_0, tx),
//     liqwid_sc.execute.mint(test_constants.tk_cfg, mint_rdmr_1, sm_1, tx),
//     liqwid_init.execute.withdraw(
//       test_constants.tk_cfg,
//       mint_rdmr_0,
//       withdraw,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(
//       test_constants.tk_cfg,
//       mint_rdmr_1,
//       withdraw,
//       tx,
//     ),
//   }
// }

// test fail_init_incorrect_oracle_policy() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid3", "asset3"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ticket_options_range() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(20),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ticket_options_quantity() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [interval.after(0)],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ticket_per_options() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 500_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ticket_price() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_200_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_unique_key() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = "inputs_hash.blake2b_224_sort_asc([in_organizer])"

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_session_time_range_too_small() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 250),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_session_time_in_past() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(60, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_oracle_params_not_null() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: Some(
//             OracleParams { interest_index: 123, interest_time: 456 },
//           ),
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_ticket_win_not_null() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: Some((None, 1_000_000, 10)),
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_tx_ttl() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: 456,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_slot() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: SlotConfig { zero_time: 0, zero_slot: 0, slot_length: 1 },
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_mint_missing_session_nft() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.zero
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ref_cfg_idx() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 1,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_ref_pp_idx() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 1,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }
// // fail_init_incorrect_ou_session_idx
// test fail_init_incorrect_ou_session_idx() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 1,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 0,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }

// test fail_init_incorrect_withdraw_rdmr_idx() fail {
//   // Reference Inputs
//   let cfg = base_cfg(test_constants.sm_pkh)
//   let cfg_in =
//     Input {
//       output_reference: test_constants.cfg_ref,
//       output: Output {
//         address: address.from_script(test_constants.sm_pkh),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
//         datum: InlineDatum(cfg),
//         reference_script: None,
//       },
//     }
//   let pp_dt = base_pp()
//   let pp_in =
//     Input {
//       output_reference: test_constants.pp_ref,
//       output: Output {
//         address: address.from_script(cfg.tk_pp.1st),
//         value: assets.from_lovelace(constants.min_ada)
//           |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
//         datum: InlineDatum(pp_dt),
//         reference_script: None,
//       },
//     }

//   // Inputs
//   let org_addr =
//     address.from_verification_key(test_constants.organizer_pkh)
//       |> address.with_delegation_key(test_constants.organizer_stkh)
//   let in_organizer =
//     Output {
//       address: org_addr,
//       value: assets.from_lovelace(20_000_000),
//       datum: NoDatum,
//       reference_script: None,
//     }
//       |> output_builder.to_input()
//   let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

//   // Outputs  
//   let out_session =
//     Output {
//       address: address.from_script(test_constants.sm_pkh)
//         |> address.with_delegation_key(test_constants.organizer_stkh),
//       value: assets.from_lovelace(constants.min_ada)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       datum: InlineDatum(
//         SessionDatum {
//           oracle_policy: ("pid1", "asset1"),
//           predict_type: LiqwidSupply,
//           ticket_options: [
//             interval.between(0, 10),
//             interval.between(11, 20),
//             interval.after(21),
//           ],
//           ticket_per_option: 1_000_000,
//           ticket_price: 1_000_000,
//           unique_key,
//           session_time: interval.between(100, 400),
//           oracle_params: None,
//           ticket_win: None,
//           tx_ttl: cfg.tx_ttl,
//           slot: cfg.slot,
//         },
//       ),
//       reference_script: None,
//     }

//   let mint_rdmr =
//     Init {
//       ou_session_idx: 0,
//       ref_cfg_idx: 0,
//       ref_pp_idx: 0,
//       withdraw_rdmr_idx: 1,
//     }
//   let mint_rdmr_data: Data = mint_rdmr
//   let withdraw = Script(cfg.withdraw_init)
//   let tx =
//     Transaction {
//       inputs: [in_organizer],
//       reference_inputs: [cfg_in, pp_in],
//       outputs: [out_session],
//       fee: 0,
//       mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 0),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 1),
//             1_000_000,
//           )
//         |> assets.add(
//             test_constants.sm_pkh,
//             utils.get_ticket_token_name(unique_key, 2),
//             1_000_000,
//           ),
//       certificates: [],
//       withdrawals: [Pair(withdraw, 0)],
//       validity_range: interval.between(50, 75),
//       extra_signatories: [],
//       redeemers: [
//         Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
//         Pair(Withdraw(withdraw), mint_rdmr_data),
//       ],
//       datums: dict.empty,
//       id: #"0000000000000000000000000000000000000000000000000000000000000000",
//       votes: [],
//       proposal_procedures: [],
//       current_treasury_amount: None,
//       treasury_donation: None,
//     }
//   and {
//     liqwid_sc.execute.mint(
//       test_constants.tk_cfg,
//       mint_rdmr,
//       test_constants.sm_pkh,
//       tx,
//     ),
//     liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
//   }
// }