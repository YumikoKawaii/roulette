use cardano/transaction.{OutputReference}
use daken/types.{TupleAsset}

pub const sm_pkh = #"f4c9f9c4252d86702c2f4c2e49e6648c7cffe3c8f2b6b7d779788f50"

pub const organizer_pkh =
  #"d48838fee1e840857dab28a04dd88193aec8c297b67c8150c0a1f5cc"

pub const organizer_stkh =
  #"e908ea93ce658a210924b3545f53df597a93a1a93325b72de149542b"

pub const wl_pkh = #"d48838fee1e840857dab28a04dd88193aec8c297b85d8150c0a1f5cc"

pub const cfg_ref =
  OutputReference {
    transaction_id: #"d95a8085d388b8b2e19efa90ebabd3b7c10a1f9b23050a40207fff6c6217bdd6",
    output_index: 0,
  }

pub const cfg_ref_alter =
  OutputReference {
    transaction_id: #"d95a8085d388b8b2e19efa90ebabd3b7c10a1f9b23050a40207fff6c6217bdd7",
    output_index: 0,
  }

pub const tk_cfg: TupleAsset =
  (
    #"87ffcd5882d01aa79809c61ce2b09516b2ec11036219a2bd3527b38a",
    #"4e677579656e2e4241",
  )

pub const session_ref =
  OutputReference {
    transaction_id: #"b4971034feee28d07f157faf99b850f856d8743494c70b19b521cfe690258e26",
    output_index: 0,
  }

pub const wl_ref =
  OutputReference {
    transaction_id: #"b4971034feee28d07f157faf99b850f856d8da3494c70b19b432cfe690258e27",
    output_index: 0,
  }

pub const ms_ref =
  OutputReference {
    transaction_id: #"b4971034feee28d07f157faf99b850f856d8da3494c70b19b432cfe690258e29",
    output_index: 0,
  }

pub const ticket_per_option = 1_000_000

pub const ticket_sales = 10_000

pub const ticket_price = 10_000_000

pub const conversion_ratio = 2_250_000

pub const organizer_prize = 200_000_000

pub const remaining_award_ticket_qty = 20_000

pub const user_lovelace = 200_000_000_000

pub const platform_fee = 500

pub const organizer_award = 500

pub const basis_base = 10_000

pub const min_ada = 2_000_000

pub const trigger_interest_index = 100

pub const trigger_qtoken_rate = (100, 200)

pub const trigger_interest_time = 1718093543000

pub const award_interest_index = 150

pub const award_qtoken_rate = (105, 205)

pub const award_interest_time = 1718093546000
