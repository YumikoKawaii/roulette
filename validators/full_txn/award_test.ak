// success_award_supply_session
// success_award_borrow_session
// success_award_session_fee_too_small
// fail_award_session_incorrect_ticket_win
// fail_award_session_incorrect_organizer_conversion_ratio
// fail_award_session_remaining_tokens_is_not_burnt
// fail_award_session_unexpected_datum_change
// fail_award_sesison_incorrect_assets
// fail_award_session_missing_market_state
// fail_award_session_incorrect_oracle_policy
// fail_award_session_missing_platform_config
// fail_award_session_incorrect_rdmr
use aiken/collection/dict
use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, Spend, Transaction,
}
use constants
use full_txn/test_data
use liqwid_sc
use types.{
  Award, LiqwidBorrow, LiqwidSupply, MarketStateDatum, ResultParams,
  SessionDatum, TicketWin,
}
use utils

fn base_ms() -> Input {
  Input {
    output_reference: test_data.ms_ref,
    output: Output {
      address: address.from_verification_key(test_data.wl_pkh),
      value: assets.from_lovelace(test_data.min_ada)
        |> assets.add("pid1", "asset1", 1),
      datum: InlineDatum(
        MarketStateDatum {
          total_supply_amt: 0,
          total_reserve_amt: 0,
          total_minted_qtoken: 0,
          total_borrowed_amt: 0,
          total_interest_amt: 0,
          interest_index: test_data.award_interest_index,
          last_interest_at: test_data.award_interest_time,
          last_batching_at: 0,
          interest_rate: (0, 0),
          qtoken_rate: test_data.award_qtoken_rate,
          min_ada: test_data.min_ada,
        },
      ),
      reference_script: None,
    },
  }
}

// success_award_supply_session
test success_award_supply_session() {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// success_award_borrow_session
test success_award_borrow_session() {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidBorrow,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_interest_index,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_interest_index,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_incorrect_ticket_win
test fail_award_session_incorrect_ticket_win() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 0)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_incorrect_organizer_conversion_ratio
test fail_award_session_incorrect_organizer_conversion_ratio() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize - 10),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_remaining_tokens_is_not_burnt
test fail_award_session_remaining_tokens_is_not_burnt() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            test_data.ticket_per_option - test_data.ticket_sales * 2,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            test_data.ticket_per_option - test_data.ticket_sales * 3,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            test_data.ticket_per_option - test_data.ticket_sales * 4,
          ),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_unexpected_datum_change
test fail_award_session_unexpected_datum_change() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          session_token_id: "phake_phake_phake",
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_sesison_incorrect_lovelace
test fail_award_sesison_incorrect_lovelace() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(
        constants.min_ada + award_qty - platform_fee - 10_000,
      )
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_missing_market_state
test fail_award_session_missing_market_state() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_incorrect_oracle_policy
test fail_award_session_incorrect_oracle_policy() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid2", "asset2"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_missing_platform_config
test fail_award_session_missing_platform_config() fail {
  let session_token_id = "session_token_id"

  // Reference Inputs  
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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

// fail_award_session_incorrect_rdmr
test fail_award_session_incorrect_rdmr() {
  let session_token_id = "session_token_id"

  // Reference Inputs
  let cfg = test_data.base_cfg()
  let ms = base_ms()

  let award_qty = test_data.ticket_sales * 10 * test_data.ticket_price
  let platform_fee = award_qty * test_data.platform_fee / 10_000
  let organizer_prize = award_qty * test_data.organizer_award / 10_000
  // Inputs      
  let session_datum =
    SessionDatum {
      oracle_policy: ("pid1", "asset1"),
      session_token_id,
      predict_type: LiqwidSupply,
      ticket_options: [10, 20],
      max_ticket_count_per_option: 1_000_000,
      ticket_price: test_data.ticket_price,
      session_time: interval.between(100, 400),
      result_params: Some(
        ResultParams {
          interest_index: test_data.trigger_qtoken_rate.1st * test_data.basis_base / test_data.trigger_qtoken_rate.2nd,
          interest_time: test_data.trigger_interest_time,
        },
      ),
      ticket_win: None,
      organizer_conversion_ratio: None,
    }
  let in_session =
    Input {
      output_reference: test_data.session_ref,
      output: Output {
        address: address.from_script(test_data.sm_pkh)
          |> address.with_delegation_key(test_data.organizer_stkh),
        value: assets.from_lovelace(
          constants.min_ada + test_data.ticket_sales * 10 * test_data.ticket_price,
        )
          |> assets.add(test_data.sm_pkh, session_token_id, 1)
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 0),
              test_data.ticket_per_option - test_data.ticket_sales * 2,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 1),
              test_data.ticket_per_option - test_data.ticket_sales * 3,
            )
          |> assets.add(
              test_data.sm_pkh,
              utils.get_ticket_token_name(session_token_id, 2),
              test_data.ticket_per_option - test_data.ticket_sales * 4,
            ),
        datum: InlineDatum(session_datum),
        reference_script: None,
      },
    }
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada + award_qty - platform_fee)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          ..session_datum,
          result_params: Some(
            ResultParams {
              interest_index: test_data.award_qtoken_rate.1st * test_data.basis_base / test_data.award_qtoken_rate.2nd,
              interest_time: test_data.award_interest_time,
            },
          ),
          ticket_win: Some(
            TicketWin(
              Some(utils.get_ticket_token_name(session_token_id, 2)),
              ( award_qty - platform_fee - organizer_prize ) / (
                test_data.ticket_sales * 4
              ),
            ),
          ),
          organizer_conversion_ratio: Some(organizer_prize),
        },
      ),
      reference_script: None,
    }
  let ou_fee =
    Output {
      address: address.from_verification_key("fee_addr"),
      value: assets.from_lovelace(platform_fee),
      datum: NoDatum,
      reference_script: None,
    }
  let rdmr =
    Award {
      ref_cfg_idx: 0,
      ref_market_state_idx: 0,
      ou_session_idx: 0,
      ou_fee_idx: Some(0),
    }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_session],
      reference_inputs: [cfg, ms],
      outputs: [out_session, ou_fee],
      fee: 0,
      mint: assets.zero
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            -(test_data.ticket_per_option - test_data.ticket_sales * 2),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            -(test_data.ticket_per_option - test_data.ticket_sales * 3),
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            -(test_data.ticket_per_option - test_data.ticket_sales * 4),
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
