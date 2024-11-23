use cardano/address.{Credential}
use cardano/transaction.{Transaction}
use constraints/redeem
use daken/types.{TupleAsset} as daken_types
use types.{Action, PlatformConfig, Redeem}
use utils

validator execute(tk_cfg: TupleAsset) {
  withdraw(
    rdmr: Action,
    _acc: Credential,
    Transaction { inputs, outputs, mint, reference_inputs, .. }: Transaction,
  ) {
    when rdmr is {
      Redeem { ref_cfg_idx, in_session_idx, ou_session_idx, .. } -> {
        expect PlatformConfig { tour_skh: pid, .. } =
          utils.get_input_by_idx(reference_inputs, ref_cfg_idx, tk_cfg)
        redeem.constraints(
          pid,
          in_session_idx,
          ou_session_idx,
          inputs,
          outputs,
          mint,
        )
      }
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail @"This purpose is not supported"
  }
}
