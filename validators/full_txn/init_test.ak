// success_init_session
// success_init_multiple_sessions
// fail_init_incorrect_ticket_options_range
// fail_init_incorrect_ticket_options_quantity (number of options < 2)
// fail_init_incorrect_ticket_per_options
// fail_init_incorrect_ticket_price
// fail_init_incorrect_session_token_id
// fail_init_incorrect_session_time_in_past (low > tx_start_time)
// fail_init_oracle_params_not_null
// fail_init_ticket_win_not_null
// fail_init_mint_missing_session_nft
// fail_init_mint_missing_ticket_tokens
// fail_init_incorrect_ref_cfg_idx
// fail_init_incorrect_ou_session_idx

use aiken/collection/dict
use aiken/crypto
use aiken/interval
use cardano/address
use cardano/assets
use cardano/transaction.{InlineDatum, Mint, NoDatum, Output, Transaction}
use constants
use daken/inputs_hash
use full_txn/fixture/output_builder
use full_txn/test_data
use liqwid_sc
use types.{Init, LiqwidSupply, ResultParams, SessionDatum, TicketWin}
use utils

test success_init_session() {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

test fail_init_incorrect_ticket_options_range() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 9],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ticket_options_quantity (number of options < 2)
test fail_init_incorrect_ticket_options_quantity() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ticket_per_options 
test fail_init_incorrect_ticket_per_options() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 2_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ticket_price (< min_price)
test fail_init_too_small_ticket_price() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: 1_000_000,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ticket_price (price%1_000_000 != 0)
test fail_init_incorrect_ticket_price() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: 1_000_000,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_session_token_id
test fail_init_incorrect_datum_session_token_id() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id: "session_token_id",
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_missing_session_verification_nft
test fail_init_missing_session_verification_nft() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_session_organizer_nft
test fail_init_incorrect_session_organizer_nft() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = "crypto.blake2b_224(session_token_id)"

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_missing_session_organizer_nft
test fail_init_missing_session_organizer_nft() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_session_time_in_past (low >= tx_start_time)
test fail_init_incorrect_session_time_in_past() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(100, 125),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_oracle_params_not_null
test fail_init_oracle_params_not_null() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: Some(
            ResultParams { interest_index: 1, interest_time: 2 },
          ),
          ticket_win: None,
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_ticket_win_not_null
test fail_init_ticket_win_not_null() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
        SessionDatum {
          oracle_policy: ("pid1", "asset1"),
          session_token_id,
          predict_type: LiqwidSupply,
          ticket_options: [10, 20],
          max_ticket_count_per_option: 1_000_000,
          ticket_price: test_data.ticket_price,
          session_time: interval.between(100, 400),
          result_params: None,
          ticket_win: Some(TicketWin { asset_win: None, conversion_ratio: 1 }),
          organizer_conversion_ratio: None,
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_organizer_conversion_ratio_not_null
test fail_init_organizer_conversion_ratio_not_null() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
          organizer_conversion_ratio: Some(0),
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_mint_missing_ticket_tokens
test fail_init_mint_missing_ticket_tokens() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ref_cfg_idx
test fail_init_incorrect_ref_cfg_idx() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 0, ref_cfg_idx: 1 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}

// fail_init_incorrect_ou_session_idx
test fail_init_incorrect_ou_session_idx() fail {
  // Reference Inputs
  let cfg = test_data.base_cfg()

  // Inputs
  let org_addr = address.from_verification_key(test_data.organizer_pkh)
  let in_organizer =
    Output {
      address: org_addr,
      value: assets.from_lovelace(20_000_000),
      datum: NoDatum,
      reference_script: None,
    }
      |> output_builder.to_input()
  let session_token_id = inputs_hash.blake2b_224_sort_asc([in_organizer])
  let session_organizer_nft = crypto.blake2b_224(session_token_id)

  // Outputs  
  let out_session =
    Output {
      address: address.from_script(test_data.sm_pkh)
        |> address.with_delegation_key(test_data.organizer_stkh),
      value: assets.from_lovelace(constants.min_ada)
        |> assets.add(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      datum: InlineDatum(
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
        },
      ),
      reference_script: None,
    }

  let rdmr = Init { ou_session_idx: 1, ref_cfg_idx: 0 }
  let rdmr_data: Data = rdmr
  let tx =
    Transaction {
      inputs: [in_organizer],
      reference_inputs: [cfg],
      outputs: [out_session],
      fee: 0,
      mint: assets.from_asset(test_data.sm_pkh, session_token_id, 1)
        |> assets.add(test_data.sm_pkh, session_organizer_nft, 1)
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 0),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 1),
            1_000_000,
          )
        |> assets.add(
            test_data.sm_pkh,
            utils.get_ticket_token_name(session_token_id, 2),
            1_000_000,
          ),
      certificates: [],
      withdrawals: [],
      validity_range: interval.between(50, 75),
      extra_signatories: [],
      redeemers: [Pair(Mint(test_data.sm_pkh), rdmr_data)],
      datums: dict.empty,
      id: #"0000000000000000000000000000000000000000000000000000000000000000",
      votes: [],
      proposal_procedures: [],
      current_treasury_amount: None,
      treasury_donation: None,
    }
  liqwid_sc.execute.mint(test_data.tk_cfg, rdmr, test_data.sm_pkh, tx)
}
