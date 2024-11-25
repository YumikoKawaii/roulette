use aiken/collection/dict
use cardano/assets.{PolicyId, Value}
use cardano/transaction.{InlineDatum, Input, Output}
use daken/flist
use types.{SessionDatum}

pub fn constraints(
  pid: PolicyId,
  in_session_idx: Int,
  ou_session_idx: Option<Int>,
  inputs: List<Input>,
  outputs: List<Output>,
  mint: Value,
) {
  // find input by idx
  expect Input {
    output: Output {
      address: in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  } = inputs |> flist.get(in_session_idx)
  expect in_session_datum: SessionDatum = in_session_dt
  expect Some((asset_win, net_award_per_ticket, remaining_award_ticket_qty)) =
    in_session_datum.ticket_win
  let (is_burn_session_nft, ticket_award_burn_qty) =
    mint
      |> assets.tokens(pid)
      |> dict.foldl(
          (False, 0),
          fn(token_name, qty, z) {
            if (qty < 0)? {
              if token_name == in_session_datum.unique_key {
                (True, z.2nd)
              } else {
                when asset_win is {
                  None -> (z.1st, z.2nd + qty)
                  Some(asset) ->
                    if token_name == asset {
                      (z.1st, qty)
                    } else {
                      z
                    }
                }
              }
            } else {
              fail
            }
          },
        )
  
  let currenct_volume =
    in_session_val
      |> assets.quantity_of(assets.ada_policy_id, assets.ada_asset_name)
  let remaining_lovelace_qty =
    currenct_volume + ticket_award_burn_qty * net_award_per_ticket - if is_burn_session_nft {
      currenct_volume - remaining_award_ticket_qty * net_award_per_ticket
    } else {
      0
    }
  
  when remaining_lovelace_qty is {
    0 -> True
    _ -> {
      let expect_ou_session_datum =
        SessionDatum {
          ..in_session_datum,
          ticket_win: Some(
            (
              asset_win,
              net_award_per_ticket,
              remaining_award_ticket_qty + ticket_award_burn_qty,
            ),
          ),
        }

      expect Some(ou_s_idx) = ou_session_idx
      // find output by idx
      let Output {
        address: ou_session_addr,
        value: ou_session_val,
        datum: ou_session_dt,
        reference_script: ou_reference_script,
      } = outputs |> flist.get(ou_s_idx)

      and {
        (in_session_addr == ou_session_addr)?,
        (assets.from_lovelace(remaining_lovelace_qty) == ou_session_val)?,
        (InlineDatum(expect_ou_session_datum) == ou_session_dt)?,
        (ou_reference_script == None)?,
      }
    }
  }
}
