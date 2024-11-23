use cardano/assets.{Lovelace}
use cardano/address
use cardano/transaction.{InlineDatum, Input, NoDatum, Output, OutputReference}
use daken/time.{SlotConfig}
use types.{MarketStateDatum, PlatformConfig}

pub const org_vkh = "org_vkh"

pub const org_stkh = "org_stkh"

pub const tour_skh = "tour_skh"

pub const liqwid_params_skh = "liqwid_params_skh"

pub const policy_id = "tour_skh"

pub const unique_key = "unique_key"

pub const pp_pid = "pp_pid"

pub const pp_tn = "pp_tn"

pub const withdraw_init = "withdraw_init"

pub const withdraw_award = "withdraw_award"

pub const withdraw_redeem = "withdraw_redeem"

pub const withdraw_claim = "withdraw_claim"

pub const organizer_addr =
  address.from_verification_key(org_vkh)
    |> address.with_delegation_key(org_stkh)

pub fn base_platform_config() {
  PlatformConfig {
    tk_pp: (pp_pid, pp_tn),
    tour_skh,
    withdraw_init,
    withdraw_award,
    withdraw_redeem,
    withdraw_claim,
    tx_ttl: 15 * 60 * 1000,
    slot: SlotConfig {
      zero_time: 1596059091000,
      zero_slot: 4492800,
      slot_length: 1000,
    },
  }
}

pub type InputUtxo {
  input: Input,
  redeemer: Data,
}

pub fn user_in() -> Input {
  Input { output_reference: user_outref(), output: user_out() }
}

pub fn tour_state_in(datum: Data, lovelace: Lovelace) -> Input {
  Input {
    output_reference: tour_state_outref(),
    output: tour_state_out(datum, lovelace),
  }
}

pub fn liqwid_params_in(datum: Data) -> Input {
  Input {
    output_reference: liqwid_params_outref(),
    output: liqwid_params_out(datum),
  }
}

fn user_outref() -> OutputReference {
  let out_ref =
    OutputReference { transaction_id: "user_outref", output_index: 0 }
  out_ref
}

fn user_out() -> Output {
  Output {
    address: address.from_verification_key("user wallet"),
    value: assets.from_asset("random", "asset", 10),
    datum: NoDatum,
    reference_script: None,
  }
}

pub fn tour_state_outref() -> OutputReference {
  let out_ref =
    OutputReference { transaction_id: "tour_state_outref", output_index: 0 }
  out_ref
}

pub fn tour_state_out(datum: Data, lovelace: Lovelace) -> Output {
  Output {
    address: address.from_script(tour_skh),
    value: assets.from_asset(policy_id, unique_key, 1)
      |> assets.add(assets.ada_policy_id, assets.ada_asset_name, lovelace),
    datum: InlineDatum(datum),
    reference_script: None,
  }
}

fn liqwid_params_outref() -> OutputReference {
  let out_ref =
    OutputReference { transaction_id: "liqwid_params_outref", output_index: 0 }
  out_ref
}

pub fn liqwid_params_out(datum: Data) -> Output {
  Output {
    address: address.from_script(liqwid_params_skh),
    value: assets.from_asset(pp_pid, pp_tn, 1),
    datum: InlineDatum(datum),
    reference_script: None,
  }
}

pub fn base_market_state_dt() {
  MarketStateDatum {
    total_supply_amt: 925689636133,
    total_reserve_amt: 1289897,
    total_minted_qtoken: 24038342094175,
    total_borrowed_amt: 70677777370,
    total_interest_amt: 1368816081,
    interest_index: 21373266398390847,
    interest_rate: (7673635168679617584207, 2246702255884273023641976832),
    last_interest_at: 1711701543000,
    last_batching_at: 1711701749000,
    qtoken_rate: (997462466367, 45179134412261),
    min_ada: 3000000,
  }
}
