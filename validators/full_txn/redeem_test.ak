// success_redeem_by_ticket
// success_redeem_by_organizer_nft
// success_redeem_by_ticket_and_nft
// success_redeem_last_lovelace
use aiken/collection/dict
use aiken/crypto
use aiken/interval
use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, Spend, Transaction,
}
use constants
use full_txn/test_data
use liqwid_sc
use types.{LiqwidSupply, Redeem, ResultParams, SessionDatum, TicketWin}
use utils

// success_redeem_by_ticket
test success_redeem_by_ticket() {
  let session_token_id = "session_token_id"
  // Inputs      
  let award_qty = test_data.conversion_ratio * test_data.ticket_sales
  let redeem_ticket_qty = 100
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: test_data.ticket_per_option,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
          interest_time: test_data.award_interest_time,
        },
      ),
      ticket_win: Some(
        TicketWin(
          Some(utils.get_ticket_token_name(session_token_id, 2)),
          test_data.conversion_ratio,
        ),
      ),
      organizer_conversion_ratio: Some(test_data.organizer_prize),
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + award_qty + test_data.organizer_prize,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key("user wallet"),
        value: assets.from_lovelace(test_data.min_ada)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              redeem_ticket_qty,
            ),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + award_qty + test_data.organizer_prize - redeem_ticket_qty * test_data.conversion_ratio,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }

  let rdmr = Redeem { ou_session_idx: Some(0) }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session, in_user],
      reference_inputs: [],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -redeem_ticket_qty,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(500, 525),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_data.session_ref), rdmr_data),
        Pair(Mint(test_data.sm_pkh), rdmr_data),
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
      test_data.tk_cfg,
      None,
      rdmr,
      test_data.session_ref,
      tx,
    ),
    liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx),
  }
}

// success_redeem_by_organizer_nft
test success_redeem_by_organizer_nft() {
  let session_token_id = "session_token_id"
  // Inputs      
  let award_qty = test_data.conversion_ratio * test_data.ticket_sales
  let organizer_nft = crypto.blake2b_224(session_token_id)
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: test_data.ticket_per_option,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
          interest_time: test_data.award_interest_time,
        },
      ),
      ticket_win: Some(
        TicketWin(
          Some(utils.get_ticket_token_name(session_token_id, 2)),
          test_data.conversion_ratio,
        ),
      ),
      organizer_conversion_ratio: Some(test_data.organizer_prize),
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + award_qty + test_data.organizer_prize,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key("user wallet"),
        value: assets.from_lovelace(test_data.min_ada)
          |> assets.add(test_data.sm_pkh, organizer_nft, 1),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(award_qty)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }

  let rdmr = Redeem { ou_session_idx: Some(0) }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session, in_user],
      reference_inputs: [],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero
        |> assets.add(test_data.sm_pkh, organizer_nft, -1),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(500, 525),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_data.session_ref), rdmr_data),
        Pair(Mint(test_data.sm_pkh), rdmr_data),
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
      test_data.tk_cfg,
      None,
      rdmr,
      test_data.session_ref,
      tx,
    ),
    liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx),
  }
}

// success_redeem_by_ticket_and_nft
test success_redeem_by_ticket_and_nft() {
  let session_token_id = "session_token_id"
  let organizer_nft = crypto.blake2b_224(session_token_id)
  // Inputs      
  let award_qty = test_data.conversion_ratio * test_data.ticket_sales
  let redeem_ticket_qty = 100
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: test_data.ticket_per_option,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
          interest_time: test_data.award_interest_time,
        },
      ),
      ticket_win: Some(
        TicketWin(
          Some(utils.get_ticket_token_name(session_token_id, 2)),
          test_data.conversion_ratio,
        ),
      ),
      organizer_conversion_ratio: Some(test_data.organizer_prize),
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + award_qty + test_data.organizer_prize,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key("user wallet"),
        value: assets.from_lovelace(test_data.min_ada)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              redeem_ticket_qty,
            )
          |> assets.add(test_data.sm_pkh, organizer_nft, 1),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        award_qty - redeem_ticket_qty * test_data.conversion_ratio,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(session_datum),
      reference_script: None,
    }
  let rdmr = Redeem { ou_session_idx: Some(0) }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session, in_user],
      reference_inputs: [],
      outputs: [out_session],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -redeem_ticket_qty,
          )
        |> assets.add(test_data.sm_pkh, organizer_nft, -1),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(500, 525),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_data.session_ref), rdmr_data),
        Pair(Mint(test_data.sm_pkh), rdmr_data),
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
      test_data.tk_cfg,
      None,
      rdmr,
      test_data.session_ref,
      tx,
    ),
    liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx),
  }
}

// success_redeem_last_lovelace
test success_redeem_last_lovelace() {
  let session_token_id = "session_token_id"
  // Inputs      
  let redeem_ticket_qty = 2
  let award_qty = test_data.conversion_ratio * redeem_ticket_qty
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: test_data.ticket_per_option,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
          interest_time: test_data.award_interest_time,
        },
      ),
      ticket_win: Some(
        TicketWin(
          Some(utils.get_ticket_token_name(session_token_id, 2)),
          test_data.conversion_ratio,
        ),
      ),
      organizer_conversion_ratio: Some(test_data.organizer_prize),
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(award_qty)
          |> assets.add(test_data.sm_pkh, session_token_id, 1),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let in_user =
    Input {
      output_reference: test_data.wl_ref,
      output: Output {
        address: address.from_verification_key("user wallet"),
        value: assets.from_lovelace(test_data.min_ada)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              redeem_ticket_qty,
            ),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let rdmr = Redeem { ou_session_idx: None }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session, in_user],
      reference_inputs: [],
      outputs: [],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -redeem_ticket_qty,
          )
        |> assets.add(test_data.sm_pkh, session_token_id, -1),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(500, 525),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_data.session_ref), rdmr_data),
        Pair(Mint(test_data.sm_pkh), rdmr_data),
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
      test_data.tk_cfg,
      None,
      rdmr,
      test_data.session_ref,
      tx,
    ),
    liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx),
  }
}
