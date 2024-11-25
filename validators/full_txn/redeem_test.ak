use aiken/collection/dict
use aiken/interval
use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, Spend, Transaction, Withdraw,
}
use constants
use full_txn/constants as test_constants
use liqwid_redeem
use liqwid_sc
use types.{
  LiqwidSupply, PlatformConfig, Redeem, ResultParams, SessionDatum, TicketWin,
}
use utils

fn base_cfg() -> Input {
  Input {
    output_reference: test_constants.cfg_ref,
    output: Output {
      address: address.from_script(test_constants.sm_pkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
      datum: InlineDatum(
        PlatformConfig {
          withdraw_init: "",
          withdraw_award: "",
          withdraw_redeem: test_constants.withdraw_redeem,
          fee: test_constants.platform_fee,
          organizer_award: test_constants.organizer_award,
          fee_addr: address.from_verification_key("fee wallet"),
        },
      ),
      reference_script: None,
    },
  }
}

test success_redeem_by_ticket() {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = base_cfg()
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: test_constants.ticket_per_option,
      ticket_price: test_constants.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_constants.award_qtoken_rate.1st * test_constants.basis_base / test_constants.award_qtoken_rate.2nd,
          interest_time: test_constants.award_interest_time,
        },
      ),
      ticket_win: Some(
        TicketWin(
          Some(utils.get_ticket_token_name(session_token_id, 2)),
          test_constants.conversion_ratio,
          test_constants.remaining_award_ticket_qty,
        ),
      ),
    }
  let in_session =
    Input {
      output_reference: test_constants.session_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh)
          |> address.with_delegation_key(test_constants.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_constants.organizer_prize + test_constants.remaining_award_ticket_qty * test_constants.conversion_ratio,
        ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let in_user =
    Input {
      output_reference: test_constants.wl_ref,
      output: Output {
        address: address.from_verification_key("user wallet"),
        value: assets.from_lovelace(test_constants.min_ada)
          |> assets.add(
              test_constants.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              1_000,
            ),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + test_constants.organizer_prize + (
          test_constants.remaining_award_ticket_qty - 1_000
        ) * test_constants.conversion_ratio,
      ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              test_constants.conversion_ratio,
              test_constants.remaining_award_ticket_qty - 1_000,
            ),
          ),
        },
      ),
      reference_script: None,
    }
  let out_user =
    Output {
      address: address.from_verification_key("user_wallet"),
      value: assets.from_lovelace(
        test_constants.min_ada + 1_000 * test_constants.conversion_ratio,
      ),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Redeem {
      ref_cfg_idx: 0,
      in_session_idx: 0,
      withdraw_rdmr_idx: 0,
      ou_session_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let withdraw = Script(test_constants.withdraw_redeem)
  let tx =
    Transaction {
      inputs: [in_session, in_user],
      reference_inputs: [cfg],
      outputs: [out_session, out_user],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -1_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(500, 525),
      extra_signatories: [],
      redeemers: [
        Pair(Spend(test_constants.session_ref), rdmr_data),
        Pair(Mint(test_constants.sm_pkh), rdmr_data),
        Pair(Withdraw(withdraw), rdmr_data),
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
      rdmr,
      test_constants.session_ref,
      tx,
    ),
    liqwid_sc.execute.mint(
      test_constants.tk_cfg,
      rdmr,
      test_constants.sm_pkh,
      tx,
    ),
    liqwid_redeem.execute.withdraw(test_constants.tk_cfg, rdmr, withdraw, tx),
  }
}
