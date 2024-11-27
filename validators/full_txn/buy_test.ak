// success_buy_ticket_from_a_session
// success_buy_ticket_from_multiple_sessions
// fail_buy_ticket_mismatch_ticket_sales
// fail_buy_ticket_session_datum_change
// fail_buy_ticket_after_session_time_lowerbound
// fail_buy_ticket_incorrect_ou_session_idx
// fail_buy_ticket_incorrect_ticket_name

use aiken/collection/dict
use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{InlineDatum,
  Input, NoDatum, Output, Spend, Transaction}
use constants
use full_txn/test_data
use liqwid_sc
use types.{Buy, LiqwidSupply, SessionDatum, TicketWin}
use utils

test success_buy_ticket_from_a_session() {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 0,
      tickets: [utils.get_ticket_token_name(session_token_id, 0)],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}

// fail_buy_ticket_mismatch_ticket_sales
test fail_buy_ticket_mismatch_ticket_sales() fail {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales - 10,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 0,
      tickets: [utils.get_ticket_token_name(session_token_id, 0)],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}

// fail_buy_ticket_session_datum_change
test fail_buy_ticket_session_datum_change() fail {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          ticket_win: Some(TicketWin { asset_win: None, conversion_ratio: 1 }),
        },
      ),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 0,
      tickets: [utils.get_ticket_token_name(session_token_id, 0)],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}

// fail_buy_ticket_after_session_time_lowerbound
test fail_buy_ticket_after_session_time_lowerbound() fail {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 0,
      tickets: [utils.get_ticket_token_name(session_token_id, 0)],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}

// fail_buy_ticket_incorrect_ou_session_idx
test fail_buy_ticket_incorrect_ou_session_idx() fail {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 1,
      tickets: [utils.get_ticket_token_name(session_token_id, 0)],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}

// fail_buy_ticket_incorrect_ticket_name
test fail_buy_ticket_incorrect_ticket_name() fail {
  // Inputs  
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key(test_data.wl_pkh),
        value: assets.from_lovelace(test_data.user_lovelace),
        datum: NoDatum,
        reference_script: None,
      },
    }
  let session_token_id = "session_token_id"
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: None,
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }

  // Outputs  
  let out_user =
    Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(
        test_data.user_lovelace - test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_sales,
          ),
      datum: NoDatum,
      reference_script: None,
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_data.ticket_sales * test_data.ticket_price,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option,
          ),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let spend_rdmr =
    Buy {
      ou_session_idx: 0,
      tickets: ["utils.get_ticket_token_name(session_token_id, 0)"],
    }
  let spend_rdmr_data: Data = spend_rdmr
  let tx =
    Transaction {
      inputs: [in_user, in_session],
      reference_inputs: [],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero,
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Spend(test_data.session_ref), spend_rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.spend(
    test_data.tk_cfg,
    None,
    spend_rdmr,
    test_data.session_ref,
    tx,
  )
}
