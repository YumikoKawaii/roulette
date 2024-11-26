// use cardano/address.{Script}
// use cardano/assets.{PolicyId}
// use cardano/transaction.{OutputReference, Transaction}
// use constraints/init
// use constraints/buy
// use constraints/trigger
// use constraints/award
// use constraints/redeem
// use daken/types.{TupleAsset} as daken_types
// use types.{Action, Award, Buy, Init, PlatformConfig, Redeem, Trigger}
// use utils

// validator execute(tk_cfg: TupleAsset) {
//   spend(
//     _opt: Option<Data>,
//     rdmr: Action,
//     out_ref: OutputReference,
//     Transaction {
//       inputs,
//       outputs,
//       reference_inputs,
//       validity_range,      
//       mint,
//       ..
//     }: Transaction,
//   ) {
//     when rdmr is {
//       Buy { ou_session_idx, tickets } ->
//         buy.constraints(
//           ou_session_idx,
//           tickets,
//           out_ref,
//           inputs,
//           outputs,
//           validity_range,          
//         )
//       Trigger { ou_session_idx, ref_market_state_idx } ->
//         trigger.constraints(
//           out_ref,
//           ou_session_idx,
//           ref_market_state_idx,
//           inputs,
//           outputs,
//           reference_inputs,
//           validity_range,
//         )
//       Award { ref_cfg_idx, ref_market_state_idx, ou_session_idx, ou_fee_idx } -> {
//         award.constraints(
//           out_ref,
//           ref_cfg_idx, 
//           ref_market_state_idx,
//           ou_session_idx,
//           ou_fee_idx,
//           inputs,
//           outputs,
//           reference_inputs,
//           mint, 
//           validity_range,
//         )
//       }
//       Redeem { ou_session_idx } -> {
//         redeem.constraints(
//           out_ref,
//           ou_session_idx,
//           inputs,
//           outputs,
//           mint,
//           validity_range,
//         )
//       }
//       _ -> fail @"unsupport"
//     }
//   }

//   mint(
//     rdmr: Action,
//     pid: PolicyId,
//     Transaction { inputs, outputs, mint, reference_inputs, validity_range, .. }: Transaction,
//   ) {
//     when rdmr is {
//       Init { ou_session_idx, ref_cfg_idx } -> {
//         init.constraints(
//           ou_session_idx,
//           ref_cfg_idx,
//           outputs,
//           reference_inputs,
//           mint,
//           validity_range,
//         )
//       }
//       Award { .. } |
//       Redeem { .. } -> {
//         inputs |> list.any(fn(a){
//           let Input {
//             output: Output {
//               address: Address { payment_credential: Script(in_pid), .. },
//               ..
//             }, 
//             ..
//           } = a
//           in_pid == pid
//         })
//       }
//       _ -> fail @"unsupport"
//     }
//   }

//   else(_) {
//     fail
//   }
// }
