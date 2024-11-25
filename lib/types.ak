use aiken/crypto.{ScriptHash}
use aiken/interval.{Interval}
use cardano/address.{Address}
use cardano/assets.{AssetName, Lovelace}
use daken/types.{TupleAsset}

pub type Action {
  Init {
    ou_session_idx: Int,
    ref_cfg_idx: Int,    
    withdraw_rdmr_idx: Int,
  }
  Buy { ou_session_idx: Int, tickets: List<AssetName> }
  Trigger { ou_session_idx: Int, ref_market_state_idx: Int }
  Award {
    ref_cfg_idx: Int,    
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
  withdraw_init: ScriptHash,
  withdraw_award: ScriptHash,
  withdraw_redeem: ScriptHash,
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

pub type ResultParams {
  interest_index: Int,
  interest_time: Int,
}

pub type TicketWin {
  asset_win: Option<AssetName>,
  conversion_ratio: Int,
  remaining_award_ticket_qty: Int,
}

pub type SessionDatum {
  oracle_policy: TupleAsset,
  session_token_id: AssetName,
  predict_type: PredictType,
  // boundaries
  // [0, 10%), [10%, 20%), [20%, 40%), [40%, None)
  // -> [1000, 2000, 4000]
  ticket_options: List<Int>,
  max_ticket_count_per_option: Int,
  ticket_price: Lovelace,  
  session_time: Interval<Int>,
  result_params: Option<ResultParams>,
  ticket_win: Option<TicketWin>,  
}
