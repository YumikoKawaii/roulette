use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}
use utils

validator execute(owner_pkh: VerificationKeyHash) {
  mint(_rdmr: Data, policy_id: PolicyId, self: Transaction) {
    let Transaction { inputs, mint, extra_signatories, .. } = self
    // only allow to mint 1 type of token
    expect [Pair(mint_token_name, mint_token_qty)] =
      mint
        |> assets.tokens(policy_id)
        |> dict.to_pairs()
    and {
      (mint_token_qty == 1)?,
      (mint_token_name == utils.get_nft_name(inputs))?,
      list.has(extra_signatories, owner_pkh)?,
    }
  }

  // The validator will fail if the transaction is not for minting.
  else(_) {
    fail @"This purpose is not supported"
  }
}
