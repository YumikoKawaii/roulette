use cardano/address.{Credential}
use cardano/transaction.{Transaction}
use constraints/redeem
use daken/types.{TupleAsset} as daken_types
use types.{Action, Redeem}

validator execute(_tk_cfg: TupleAsset) {
  withdraw(
    rdmr: Action,
    _acc: Credential,
    Transaction { inputs, outputs, mint, .. }: Transaction,
  ) {
    when rdmr is {
      Redeem { in_session_idx, ou_session_idx, .. } ->
        redeem.constraints(
          in_session_idx,
          ou_session_idx,
          inputs,
          outputs,
          mint,
        )
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail @"This purpose is not supported"
  }
}
