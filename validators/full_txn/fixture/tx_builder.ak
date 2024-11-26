use aiken/cbor
use aiken/interval
use aiken/primitive/bytearray
use cardano/address.{Script, StakeCredential}
use cardano/assets.{PolicyId}
use cardano/transaction.{
  Input, Mint, Output, ScriptPurpose, Spend, Transaction, ValidityRange,
  Withdraw,
}
use daken/types.{ScriptKeyHash}

pub fn new() {
  transaction.placeholder
}

pub fn add_fee(self: Transaction, fee_lovelace: Int) {
  Transaction { ..self, fee: fee_lovelace }
}

pub fn add_input(self: Transaction, input: Input) {
  Transaction { ..self, inputs: [input, ..self.inputs] }
}

pub fn add_ref_input(self: Transaction, input: Input) {
  Transaction { ..self, reference_inputs: [input, ..self.reference_inputs] }
}

pub fn add_script_input(self: Transaction, input: Input, redeemer: Data) {
  self
    |> add_input(input)
    |> add_redeemer(Spend(input.output_reference), redeemer)
}

pub fn add_output(self: Transaction, output: Output) {
  Transaction { ..self, outputs: [output, ..self.outputs] }
}

pub fn add_redeemer(self: Transaction, purpose: ScriptPurpose, datum: Data) {
  Transaction { ..self, redeemers: [Pair(purpose, datum), ..self.redeemers] }
}

pub fn add_validity_range(self: Transaction, range: ValidityRange) {
  Transaction { ..self, validity_range: range }
}

pub fn add_validity_slot_range(self: Transaction, from_slot: Int, to_slot: Int) {
  self
    |> add_validity_range(interval.between(from_slot * 1000, to_slot * 1000))
}

pub fn add_mint(
  self: Transaction,
  pid: PolicyId,
  name: ByteArray,
  qty: Int,
  redeemer: Data,
) {
  Transaction {
    ..self,
    mint: self.mint
      |> assets.add(pid, name, qty),
  }
    |> add_redeemer(Mint(pid), redeemer)
}

pub fn add_signer(self: Transaction, vkey: ByteArray) {
  Transaction { ..self, extra_signatories: [vkey, ..self.extra_signatories] }
}

pub fn add_script_withdrawal(
  self: Transaction,
  tour_pkh: ScriptKeyHash,
  reward: Int,
  redeemer: Data,
) {
  let cred = Script(tour_pkh)
  Transaction { ..self, withdrawals: [Pair(cred, reward), ..self.withdrawals] }
    |> add_redeemer(Withdraw(cred), redeemer)
}

pub fn add_zero_withdrawal_script(
  self: Transaction,
  tour_pkh: ScriptKeyHash,
  redeemer: Data,
) {
  let cred = Script(tour_pkh)
  Transaction { ..self, withdrawals: [Pair(cred, 0), ..self.withdrawals] }
    |> add_redeemer(Withdraw(cred), redeemer)
}

pub fn script_purpose_compare(left: ScriptPurpose, right: ScriptPurpose) {
  bytearray.compare(cbor.serialise(left), cbor.serialise(right))
}

pub fn stake_cred_compare(left: StakeCredential, right: StakeCredential) {
  bytearray.compare(cbor.serialise(left), cbor.serialise(right))
}
