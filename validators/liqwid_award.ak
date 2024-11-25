use cardano/address.{Credential}
use cardano/transaction.{Transaction}
use constraints/award
use daken/types.{TupleAsset} as daken_types
use types.{Action, Award}
use utils

validator execute(tk_cfg: TupleAsset) {
  withdraw(rdmr: Action, _acc: Credential, self: Transaction) {
    when rdmr is {
      Award {
        ref_cfg_idx,
        ref_market_state_idx,
        in_session_idx,
        ou_session_idx,
        ou_fee_idx,
        ..
      } -> {
        let Transaction {
          inputs,
          outputs,
          mint,
          validity_range,
          reference_inputs,
          ..
        } = self
        let (ref_cfg_dt, refs_remain) =
          utils.get_input_by_idx_with_remain(
            reference_inputs,
            ref_cfg_idx,
            tk_cfg,
          )
        award.constraints(
          ref_cfg_dt,
          ref_market_state_idx,
          in_session_idx,
          ou_session_idx,
          ou_fee_idx,
          inputs,
          outputs,
          refs_remain,
          mint,
          validity_range,
        )
      }
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail @"This purpose is not supported"
  }
}
