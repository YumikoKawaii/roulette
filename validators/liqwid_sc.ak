use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use constraints/buy
use constraints/trigger
use daken/types.{TupleAsset} as daken_types
use types.{Action, Award, Buy, Init, PlatformConfig, Redeem, Trigger}
use utils

validator execute(tk_cfg: TupleAsset) {
  spend(
    _opt: Option<Data>,
    rdmr: Action,
    out_ref: OutputReference,
    Transaction {
      inputs,
      outputs,
      reference_inputs,
      validity_range,
      redeemers,
      ..
    }: Transaction,
  ) {
    when rdmr is {
      Buy { ou_session_idx, tickets } ->
        buy.constraints(
          ou_session_idx,
          tickets,
          out_ref,
          inputs,
          outputs,
          validity_range,
        )
      Trigger { ou_session_idx, ref_market_state_idx } ->
        trigger.constraints(
          out_ref,
          ou_session_idx,
          ref_market_state_idx,
          inputs,
          outputs,
          reference_inputs,
          validity_range,
        )
      Award { ref_cfg_idx, withdraw_rdmr_idx, .. } |
      Redeem { ref_cfg_idx, withdraw_rdmr_idx, .. } -> {
        expect PlatformConfig { withdraw_award, withdraw_redeem, .. } =
          reference_inputs |> utils.get_input_by_idx(ref_cfg_idx, tk_cfg)
        redeemers
          |> utils.require_withdraw_idx(
              when rdmr is {
                Award { .. } -> Script(withdraw_award)
                Redeem { .. } -> Script(withdraw_redeem)
                _ -> fail @"unsupport"
              },
              withdraw_rdmr_idx,
              rdmr,
            )
      }
      _ -> fail @"unsupport"
    }
  }

  mint(
    rdmr: Action,
    pid: PolicyId,
    Transaction { redeemers, reference_inputs, .. }: Transaction,
  ) {
    when rdmr is {
      Init { ref_cfg_idx, withdraw_rdmr_idx, .. } |
      Award { ref_cfg_idx, withdraw_rdmr_idx, .. } |
      Redeem { ref_cfg_idx, withdraw_rdmr_idx, .. } -> {
        expect PlatformConfig {
          tour_skh,
          withdraw_init,
          withdraw_award,
          withdraw_redeem,
          ..
        } = reference_inputs |> utils.get_input_by_idx(ref_cfg_idx, tk_cfg)
        and {
          (tour_skh == pid)?,
          redeemers
            |> utils.require_withdraw_idx(
                when rdmr is {
                  Init { .. } -> Script(withdraw_init)
                  Award { .. } -> Script(withdraw_award)
                  Redeem { .. } -> Script(withdraw_redeem)
                  _ -> fail @"unsupport"
                },
                withdraw_rdmr_idx,
                rdmr,
              ),
        }
      }
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail
  }
}
