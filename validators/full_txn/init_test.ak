// init session success
//

use aiken/collection/dict
use aiken/crypto.{ScriptHash}
use aiken/interval
use cardano/address.{Script}
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, Mint, NoDatum, Output, Transaction, Withdraw,
}
use constants
use daken/inputs_hash
use full_txn/constants as test_constants
use full_txn/fixture/output_builder
use liqwid_init
use liqwid_sc
use types.{Init, LiqwidSupply, PlatformConfig, ProtocolParams, SessionDatum}
use utils

fn base_cfg(tour_skh: ScriptHash) {
  PlatformConfig {
    tk_pp: test_constants.tk_pp,
    tour_skh,
    withdraw_init: test_constants.withdraw_init_skh,
    withdraw_award: "",
    withdraw_redeem: "",
    withdraw_claim: "",
    tx_ttl: 15 * 60 * 1000,
    slot: test_constants.slot_cfg,
  }
}

fn base_pp() {
  ProtocolParams {
    markets: [("pid1", "asset1"), ("pid2", "asset2")],
    min_duration_in_ms: 200,
    fee: 500,
    organizer_award: 500,
    fee_addr: address.from_verification_key("fee wallet"),
  }
}

test success_create_session() {
  // Reference Inputs
  let cfg = base_cfg(test_constants.sm_pkh)
  let cfg_in =
    Input {
      output_reference: test_constants.cfg_ref,
      output: Output {
        address: address.from_script(test_constants.sm_pkh),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(test_constants.tk_cfg.1st, test_constants.tk_cfg.2nd, 1),
        datum: InlineDatum(cfg),
        reference_script: None,
      },
    }
  let pp_dt = base_pp()
  let pp_in =
    Input {
      output_reference: test_constants.pp_ref,
      output: Output {
        address: address.from_script(cfg.tk_pp.1st),
        value: assets.from_lovelace(constants.min_ada)
          |> assets.add(cfg.tk_pp.1st, cfg.tk_pp.2nd, 1),
        datum: InlineDatum(pp_dt),
        reference_script: None,
      },
    }

  // Inputs
  let org_addr =
    address.from_verification_key(test_constants.organizer_pkh)
      |> address.with_delegation_key(test_constants.organizer_stkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let unique_key = inputs_hash.blake2b_224_sort_asc([in_organizer])

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_constants.sm_pkh)
        |> address.with_delegation_key(test_constants.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 3),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 4),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          predict_type: LiqwidSupply,
          ticket_options: [
            interval.between(0, 10),
            interval.between(11, 20),
            interval.between(21, 25),
            interval.between(26, 30),
            interval.after(31),
          ],
          ticket_per_option: 1_000_000,
          ticket_price: 1_000_000,
          unique_key,
          session_time: interval.between(100, 400),
          oracle_params: None,
          ticket_win: None,
          tx_ttl: cfg.tx_ttl,
          slot: cfg.slot,
        },
      ),
      reference_script: None,
    }

  let mint_rdmr =
    Init {
      ou_session_idx: 0,
      ref_cfg_idx: 0,
      ref_pp_idx: 0,
      withdraw_rdmr_idx: 0,
    }
  let mint_rdmr_data: Data = mint_rdmr
  let withdraw = Script(test_constants.withdraw_init_skh)
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg_in, pp_in],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_constants.sm_pkh, unique_key, 1)
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 0),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 1),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 2),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 3),
            1_000_000,
          )
        |> assets.add(
            test_constants.sm_pkh,
            utils.get_ticket_token_name(unique_key, 4),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [Pair(withdraw, 0)],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [
        Pair(Mint(test_constants.sm_pkh), mint_rdmr_data),
        Pair(Withdraw(withdraw), mint_rdmr_data),
      ],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  and {
    liqwid_sc.execute.mint(
      test_constants.tk_cfg,
      mint_rdmr,
      test_constants.sm_pkh,
      tx,
    ),
    liqwid_init.execute.withdraw(test_constants.tk_cfg, mint_rdmr, withdraw, tx),
  }
}
