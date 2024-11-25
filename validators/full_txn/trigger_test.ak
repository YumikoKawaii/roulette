// success_trigger_supply_session
// success_trigger_borrow_session
// success_trigger_multiple_supply_sessions
// fail_trigger_session_incorrect_oracle_policy
// fail_trigger_session_incorrect_ou_session_idx
// fail_trigger_session_incorrect_ref_market_state_idx
// fail_trigger_session_incorrect_datum_wrong_oracle_params
// fail_trigger_session_datum_change_except_oracle_params

use aiken/collection/dict
use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{InlineDatum, Input, Output, Spend, Transaction}
use constants
use full_txn/constants as test_constants
use liqwid_sc
use types.{
  LiqwidBorrow, LiqwidSupply, MarketStateDatum, OracleParams, SessionDatum,
  Trigger,
}
use utils

fn base_ms() -> Input {
  Input {
    output_reference: test_constants.ms_ref,
    output: Output {
      address: address.from_verification_key(test_constants.wl_pkh),
      value: assets.from_lovelace(test_constants.min_ada)
        |> assets.add("pid1", "asset1", 1),
      datum: InlineDatum(
        MarketStateDatum {
          total_supply_amt: 0,
          total_reserve_amt: 0,
          total_minted_qtoken: 0,
          total_borrowed_amt: 0,
          total_interest_amt: 0,
          interest_index: test_constants.prev_interest_index,
          last_interest_at: test_constants.prev_interest_time,
          last_batching_at: 0,
          interest_rate: (0, 0),
          qtoken_rate: test_constants.prev_qtoken_rate,
          min_ada: test_constants.min_ada,
        },
      ),
      reference_script: None,
    },
  }
}

test success_trigger_supply_session() {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test success_trigger_borrow_session() {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidBorrow,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_interest_index,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test success_trigger_multiple_supply_sessions() {
  let unique_key = "unique_key"
  let sc_0 = test_constants.sm_pkh
  let sc_1 = "test_constants.sm_pkh"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session_0 =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(sc_0)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              sc_0,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              sc_0,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              sc_0,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  let in_session_1 =
    Input {
      output_reference: test_constants.session_ref_alter,
      output: Output {
        address: address.from_script(sc_1)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              sc_1,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              sc_1,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              sc_1,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(
          SessionDatum { ..session_datum, predict_type: LiqwidBorrow },
        ),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session_0 =
    Output {
      address: address.from_script(sc_0)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            sc_0,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            sc_0,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            sc_0,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let out_session_1 =
    Output {
      address: address.from_script(sc_1)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            sc_1,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            sc_1,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            sc_1,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          predict_type: LiqwidBorrow,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_interest_index,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }

  let spend_rdmr_0 = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_0_data: Data = spend_rdmr_0
  let spend_rdmr_1 = Trigger { ou_session_idx: 1, ref_market_state_idx: 0 }
  let spend_rdmr_1_data: Data = spend_rdmr_1
  let tx =
    Transaction {
      inputs: [in_session_0, in_session_1],
      reference_inputs: [base_ms()],
      outputs: [out_session_0, out_session_1],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_constants.session_ref), spend_rdmr_0_data),
        Pair(Spend(test_constants.session_ref_alter), spend_rdmr_1_data),
      ],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  and {
    liqwid_sc.execute.spend(
      test_constants.tk_cfg,
      None,
      spend_rdmr_0,
      test_constants.session_ref,
      tx,
    ),
    liqwid_sc.execute.spend(
      test_constants.tk_cfg,
      None,
      spend_rdmr_1,
      test_constants.session_ref_alter,
      tx,
    ),
  }
}

test fail_trigger_session_incorrect_oracle_policy() fail {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid2", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test fail_trigger_session_incorrect_ou_session_idx() fail {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 1, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test fail_trigger_session_incorrect_ref_market_state_idx() fail {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 1 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test fail_trigger_session_incorrect_datum_wrong_oracle_params() fail {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_interest_index,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}

test fail_trigger_session_datum_change_except_oracle_params() fail {
  let unique_key = "unique_key"
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      predict_type: LiqwidSupply,
      ticket_options: [
        interval.between(0, 10),
        interval.between(11, 20),
        interval.after(21),
      ],
      ticket_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      unique_key,
      session_time: interval.between(100, 400),
      oracle_params: None,
      ticket_win: None,
      tx_ttl: 15 * 60 * 1000,
      slot: test_constants.slot_cfg,
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 0),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 1),
              test_constants.ticket_per_option,
            )
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(unique_key, 2),
              test_constants.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs    
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            test_constants.ticket_per_option,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            test_constants.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          predict_type: LiqwidBorrow,
          oracle_params: Some(
            OracleParams {
              interest_index: test_constants.prev_qtoken_rate.1st * test_constants.basis_base / test_constants.prev_qtoken_rate.2nd,
              interest_time: test_constants.prev_interest_time,
            },
          ),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr = Trigger { ou_session_idx: 0, ref_market_state_idx: 0 }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [base_ms()],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_constants.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_constants.tk_cfg,
    None,
    spend_rdmr,
    test_constants.session_ref,
    tx,
  )
}
