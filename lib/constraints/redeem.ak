use aiken/collection/dict
use aiken/crypto
use cardano/address.{Address, Script}
use cardano/assets.{Value}
use cardano/transaction.{InlineDatum, Input, Output}
use constants
use daken/flist
use types.{SessionDatum, TicketWin}

pub fn constraints(
  in_session: Input,
  ou_session_idx: Option<Int>,
  outputs: List<Output>,
  mint: Value,
) {
  // find input by idx
  expect Input {
    output: Output {
      address: Address { payment_credential: Script(pid), .. } as in_session_addr,
      value: in_session_val,
      datum: InlineDatum(in_session_dt),
      ..
    },
    ..
  } = in_session
  expect in_session_datum: SessionDatum = in_session_dt
  // verify Session Verification NFT
  let valid_utxo =
    (
      in_session_val
        |> assets.quantity_of(pid, in_session_datum.session_token_id)
    ) == 1

  let session_organizer_nft =
    crypto.blake2b_224(in_session_datum.session_token_id)

  expect Some(TicketWin { asset_win, conversion_ratio: ticket_conversion_ratio }) =
    in_session_datum.ticket_win
  let (is_burn_verification_nft, is_burn_organizer_nft, ticket_award_burn_qty) =
    mint
      |> assets.tokens(pid)
      |> dict.foldl(
          (False, False, 0),
          fn(token_name, qty, z) {
            let (verify, organizer, qty_accum) = z
            if (qty < 0)? {
              if token_name == in_session_datum.session_token_id {
                (True, organizer, qty_accum)
              } else if token_name == session_organizer_nft {
                (verify, True, qty_accum)
              } else {
                when asset_win is {
                  None -> (verify, organizer, qty_accum + qty)
                  Some(asset) ->
                    if token_name == asset {
                      (verify, organizer, qty)
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

  let ticket_redeem_qty = ticket_award_burn_qty * ticket_conversion_ratio
  let organizer_award_qty =
    if is_burn_organizer_nft {
      expect Some(v) = in_session_datum.organizer_conversion_ratio
      v + constants.min_ada
    } else {
      0
    }
  let remaining_lovelace_qty =
    (
      in_session_val
        |> assets.quantity_of(assets.ada_policy_id, assets.ada_asset_name)
    ) - ticket_redeem_qty - organizer_award_qty
  and {
    valid_utxo?,
    when remaining_lovelace_qty is {
      0 -> is_burn_verification_nft
      _ -> {
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
          (InlineDatum(in_session_dt) == ou_session_dt)?,
          (ou_reference_script == None)?,
          (!is_burn_verification_nft)?,
        }
      }
    },
  }
}
