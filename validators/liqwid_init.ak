// use cardano/address.{Credential}
// use cardano/transaction.{Transaction}
// use constraints/init
// use daken/types.{TupleAsset} as daken_types
// use types.{Action, Init, PlatformConfig}
// use utils

// validator execute(tk_cfg: TupleAsset) {
//   withdraw(rdmr: Action, _acc: Credential, self: Transaction) {
//     when rdmr is {
//       Init { ou_session_idx, ref_cfg_idx, ref_pp_idx, .. } -> {
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
//         expect PlatformConfig { slot, tx_ttl, tk_pp, tour_skh: pid, .. } =
//           ref_cfg_dt
//         init.constraints(
//           utils.get_input_by_idx(refs_remain, ref_pp_idx, tk_pp),
//           pid,
//           ou_session_idx,
//           inputs,
//           outputs,
//           mint,
//           validity_range,
//           tx_ttl,
//           slot,
//         )
//       }
//       _ -> fail @"unsupport"
//     }
//   }

//   else(_) {
//     fail @"This purpose is not supported"
//   }
// }
