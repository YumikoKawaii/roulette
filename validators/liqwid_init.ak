use cardano/address.{Credential}
use cardano/transaction.{Transaction}
use constraints/init
use daken/types.{TupleAsset} as daken_types
use types.{Action, Init}

validator execute(_tk_cfg: TupleAsset) {
  withdraw(rdmr: Action, _acc: Credential, self: Transaction) {
    when rdmr is {
      Init { ou_session_idx, .. } -> {
        let Transaction { inputs, outputs, mint, validity_range, .. } = self
        init.constraints(ou_session_idx, inputs, outputs, mint, validity_range)
      }
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail @"This purpose is not supported"
  }
}
