use aiken/collection/list
use cardano/address.{Address, Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{Input, Output, OutputReference, Transaction}
use constraints/award
use constraints/buy
use constraints/init
use constraints/redeem
use constraints/trigger
use daken/flist
use daken/types.{TupleAsset} as daken_types
use types.{Action, Award, Buy, Init, Redeem, Trigger}
use utils

validator execute(tk_cfg: TupleAsset) {
  spend(
    _opt: Option<Data>,
    rdmr: Action,
    out_ref: OutputReference,
    Transaction { inputs, outputs, reference_inputs, validity_range, mint, .. }: Transaction,
  ) {
    expect Some(in_session) = inputs |> utils.get_input_by_out_ref(out_ref)
    when rdmr is {
      Buy { ou_session_idx, tickets } -> {
        let ou_session = outputs |> flist.get(ou_session_idx)
        buy.constraints(in_session, ou_session, tickets, validity_range)
      }
      Trigger { ou_session_idx, ref_market_state_idx } -> {
        let ou_session = outputs |> flist.get(ou_session_idx)
        trigger.constraints(
          in_session,
          ou_session,
          ref_market_state_idx,
          reference_inputs,
          validity_range,
        )
      }
      Award { ref_cfg_idx, ref_market_state_idx, ou_session_idx, ou_fee_idx } -> {
        expect (Some(ou_session), out_remains) = outputs |> flist.get_with_tail(ou_session_idx)
        let (ref_cfg_dt, ref_remains) =
          reference_inputs |> utils.get_input_by_idx_with_remains(ref_cfg_idx, tk_cfg)
        award.constraints(
          in_session,
          ou_session,
          ou_fee_idx,
          out_remains,
          ref_cfg_dt,
          mint,
          ref_market_state_idx,
          ref_remains,
          validity_range,
        )
      }
      Redeem { ou_session_idx } ->
        redeem.constraints(in_session, ou_session_idx, outputs, mint)
      _ -> fail @"unsupport"
    }
  }

  mint(
    rdmr: Action,
    pid: PolicyId,
    Transaction { inputs, outputs, mint, reference_inputs, validity_range, .. }: Transaction,
  ) {
    when rdmr is {
      Init { ou_session_idx, ref_cfg_idx } -> {
        let output = outputs |> flist.get(ou_session_idx)
        let ref_cfg_dt =
          reference_inputs |> utils.get_input_by_idx(ref_cfg_idx, tk_cfg)
        init.constraints(output, ref_cfg_dt, inputs, mint, validity_range)
      }
      Award { .. } | Redeem { .. } ->
        inputs
          |> list.any(
              fn(a) {
                expect Input {
                  output: Output {
                    address: Address { payment_credential: Script(in_pid), .. },
                    ..
                  },
                  ..
                } = a
                in_pid == pid
              },
            )
      _ -> fail @"unsupport"
    }
  }

  else(_) {
    fail
  }
}
