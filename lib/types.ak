use aiken/crypto.{ScriptHash}
use aiken/interval.{Interval}
use cardano/address.{Address}
use cardano/assets.{AssetName, Lovelace}
use daken/time.{SlotConfig}
use daken/types.{Basis, TupleAsset}

pub type Action {
  Init {
    ou_session_idx: Int,
    ref_cfg_idx: Int,
    ref_pp_idx: Int,
    withdraw_rdmr_idx: Int,
  }
  Buy { ou_session_idx: Int, tickets: List<AssetName> }
  Trigger { ou_session_idx: Int, ref_market_state_idx: Int }
  Award {
    ref_cfg_idx: Int,
    ref_pp_idx: Int,
    ref_market_state_idx: Int,
    in_session_idx: Int,
    ou_session_idx: Int,
    ou_fee_idx: Int,
    withdraw_rdmr_idx: Int,
  }
  Redeem {
    ref_cfg_idx: Int,
    in_session_idx: Int,
    withdraw_rdmr_idx: Int,
    ou_session_idx: Option<Int>,
  }
}

pub type PlatformConfig {
  tk_pp: TupleAsset,
  tour_skh: ScriptHash,
  withdraw_init: ScriptHash,
  withdraw_award: ScriptHash,
  withdraw_redeem: ScriptHash,
  withdraw_claim: ScriptHash,
  tx_ttl: Int,
  slot: SlotConfig,
}

pub type ProtocolParams {
  // list of supported tokens
  markets: List<TupleAsset>,
  // ttl of tx, unit by slot  
  min_duration_in_ms: Int,
  // Basic Point, percentage of fee paid to platform  
  fee: Int,
  // Basic Point, percentage of fee paid to organizer
  organizer_award: Int,
  fee_addr: Address,
}

pub type MarketStateDatum {
  //use
  total_supply_amt: Int,
  total_reserve_amt: Int,
  total_minted_qtoken: Int,
  //use
  total_borrowed_amt: Int,
  //use
  total_interest_amt: Int,
  interest_index: Int,
  //use
  interest_rate: (Int, Int),
  last_interest_at: Int,
  last_batching_at: Int,
  qtoken_rate: (Int, Int),
  min_ada: Int,
}

pub type PredictType {
  LiqwidSupply
  LiqwidBorrow
}

pub type OracleParams {
  interest_index: Int,
  interest_time: Int,
}

pub type SessionDatum {
  oracle_policy: TupleAsset,
  predict_type: PredictType,
  ticket_options: List<Interval<Basis>>,
  ticket_per_option: Int,
  ticket_price: Lovelace,
  unique_key: AssetName,
  session_time: Interval<Int>,
  oracle_params: Option<OracleParams>,
  ticket_win: Option<(Option<AssetName>, Lovelace, Int)>,
  tx_ttl: Int,
  slot: SlotConfig,
}
