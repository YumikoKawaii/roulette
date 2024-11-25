// use cardano/address.{Credential}
// use cardano/transaction.{Transaction}
// use constraints/award
// use daken/types.{TupleAsset} as daken_types
// use types.{Action, Award, PlatformConfig}
// use utils

// validator execute(tk_cfg: TupleAsset) {
//   withdraw(rdmr: Action, _acc: Credential, self: Transaction) {
//     when rdmr is {
//       Award {
//         ref_cfg_idx,
//         ref_pp_idx,
//         ref_market_state_idx,
//         in_session_idx,
//         ou_session_idx,
//         ou_fee_idx,
//         ..
//       } -> {
//         let Transaction {
//           inputs,
//           outputs,
//           mint,
//           validity_range,
//           reference_inputs,
//           ..
//         } = self
//         let (ref_cfg_dt, refs_remain) =
//           utils.get_input_by_idx_with_remain(
//             reference_inputs,
//             ref_cfg_idx,
//             tk_cfg,
//           )
//         expect PlatformConfig { tk_pp, tour_skh: pid, .. } = ref_cfg_dt
//         let (ref_pp_dt, refs_remain_2) =
//           refs_remain |> utils.get_input_by_idx_with_remain(ref_pp_idx, tk_pp)
//         award.constraints(
//           pid,
//           ref_pp_dt,
//           ref_market_state_idx,
//           in_session_idx,
//           ou_session_idx,
//           ou_fee_idx,
//           inputs,
//           outputs,
//           refs_remain_2,
//           mint,
//           validity_range,
//         )
//       }
//       _ -> fail @"unsupport"
//     }
//   }

//   else(_) {
//     fail @"This purpose is not supported"
//   }
// }
