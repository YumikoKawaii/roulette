use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{ Transaction}
use daken/types.{TupleAsset} as daken_types
use types.{Action, Init, PlatformConfig}
use utils

validator execute(tk_cfg: TupleAsset) {
  // spend(
  //     _opt: Option<Data>, 
  //     rdmr: Action, 
  //     out_ref: OutputReference, 
  //     Transaction{
  //         inputs,
  //         outputs,
  //         reference_inputs,
  //         validity_range,
  //         redeemers,
  //         ..
  //     }: Transaction) {
  //     when rdmr is {
  //         Init
  //         _ -> fail @"unsupport"
  //     }
  // }
  mint(
    rdmr: Action,
    pid: PolicyId,
    Transaction { redeemers, reference_inputs, .. }: Transaction,
  ) {
    let Init { ref_cfg_idx, withdraw_rmdr_idx, .. } = rdmr

    expect PlatformConfig { tour_skh, withdraw_init, .. } =
      reference_inputs |> utils.get_ref_by_idx(ref_cfg_idx, tk_cfg)

    and {
      (tour_skh == pid)?,
      redeemers
        |> utils.require_withdraw_idx(
            Script(withdraw_init),
            withdraw_rmdr_idx,
            rdmr,
          ),
    }
  }

  else(_) {
    fail
  }
}
