use aiken/crypto.{ScriptHash}
use aiken/interval.{Interval}
use cardano/address.{Address, Credential, VerificationKey}
use cardano/assets.{AssetName, Lovelace}
use daken/time.{SlotConfig}
use daken/types.{Basis, Blake2b224Hash, TupleAsset}

pub type Action {
  Init {
    ou_session_idx: Int,
    ref_cfg_idx: Int,
    ref_pp_idx: Int,
    withdraw_rmdr_idx: Int,
  }
}

//   Buy { in_session_idx: Int, ou_session_idx: Int}
//   Trigger {}
//   Extend {
//     unique_key: Blake2b224Hash,
//     ref_cfg_idx: Int,
//     ref_pp_idx: Int,
//     ref_market_state_idx: Int,
//     ref_market_param_idx: Int,
//     in_state_idx: Int,
//     ou_state_idx: Int,
//     withdraw_rmdr_idx: Int,
//   }
//   Award {
//     unique_key: Blake2b224Hash,
//     ref_cfg_idx: Int,
//     ref_pp_idx: Int,
//     ref_market_state_idx: Int,
//     ref_market_param_idx: Int,
//     in_state_idx: Int,
//     ou_state_idx: Int,
//     ou_organizer_idx: Int,
//     ou_fee_idx: Int,
//     withdraw_rmdr_idx: Int,
//   }
//   // neu thang thi burn ticket nhan lai ada
//   // neu thua thi chi burn ticket
//   Redeem {
//     unique_key: Blake2b224Hash,
//     ref_cfg_idx: Int,
//     withdraw_rmdr_idx: Int,
//     in_state_idx: Int,
//     ou_state_idx: Option<Int>,
//     ou_organizer_idx: Option<Int>,
//   }

pub type PlatformConfig {
  tk_pp: TupleAsset,
  tour_skh: ScriptHash,
  withdraw_init: ScriptHash,
  withdraw_award: ScriptHash,
  withdraw_redeem: ScriptHash,
  tx_ttl: Int,
  slot: SlotConfig,
}

pub type ProtocolParams {
  // list of supported tokens
  markets: List<TupleAsset>,
  // ttl of tx, unit by slot
  tx_ttl: Int,
  min_duration_in_ms: Int,
  // to support the supply apy for ADA calculation formula
  ada_market: ByteArray,
  // Basic Point, percentage of fee paid to platform  
  fee: Int,
  fee_addr: Address,
}

pub type PredictType {
  Supply
  Borrow
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
