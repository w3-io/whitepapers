# Security

## BFT Assumptions and Limits

W3.io's security model rests on the standard BFT assumption: fewer than one-third of the validators in any given committee are Byzantine. For a committee of size n, the protocol tolerates up to f = floor((n-1)/3) faulty members. This is a well-understood bound. No BFT protocol survives a 2/3+ adversary.

Within this bound, the protocol guarantees safety (no two honest members reach conflicting decisions) and liveness (decisions are eventually reached, via view change if necessary). Beyond this bound, all bets are off. The protocol does not claim to defend against a supermajority adversary. No system can.

## Attack Scenarios

The protocol's threat model considers several attack classes.

**Faulty leader.** A leader that fails to propose, proposes invalid values, or equivocates (sends different proposals to different members). Defense: automatic view change rotates leadership after timeout. Equivocation is detectable because members share received proposals, and provable on-chain for slashing.

**Network partition.** A subset of validators cannot communicate with the rest. Defense: the consensus protocol's liveness property requires only 2f+1 reachable members. A partition that isolates fewer than f+1 members does not prevent consensus. A larger partition stalls consensus until the partition heals, but does not produce incorrect results.

**Trigger spoofing.** An attacker claims a blockchain event occurred when it did not. Defense: monitor groups (7 members, f=2) independently verify trigger evidence. A single validator's claim is not sufficient. The monitor group runs BFT consensus to reach agreement on the trigger before dispatching execution.

**Bad epoch root.** An attacker attempts to submit a false epoch commitment to the L1 contract. Defense: epoch submission requires a BLS quorum signature from 2f+1 committee members over the epoch tuple (chain ID, contract address, epoch number, validator set version, cumulative root, previous root, receipt count, namespace count). A single Byzantine validator cannot produce a valid quorum signature.

**Replay.** An attacker resubmits a previously valid epoch. Defense: the contract enforces monotonically increasing epoch numbers and root chaining. Resubmitting epoch N when the contract is past epoch N fails because the epoch number is not greater than the last accepted epoch.

**Gossipsub manipulation.** An attacker floods the gossipsub network with invalid messages or withholds valid messages. Defense: gossipsub v1.1 [@gossipsub2020] includes peer scoring, message validation, and flood publishing. Invalid messages are rejected at the protocol level before reaching consensus.

## Validator Set Security

The permissioned validator model provides an additional security layer beyond the BFT assumptions. Every validator operator is KYC-verified, meaning attack attribution is possible. An attacker who equivocates or submits bad data is identifiable and legally accountable, not just slashable.

The `emergencyRemove` function allows the Foundation to remove a compromised validator immediately without waiting for a governance vote. This is a centralized power that exists because the alternative (waiting for governance while a known bad actor participates in consensus) is worse. The power is scoped: it can only remove, not add. It is disclosed and tracked on-chain.

A known unmitigated attack: a compromised `EMERGENCY_ROLE` holder could iteratively call `emergencyRemove` to shrink the validator set until their own validators form a quorum. This is acknowledged. The mitigation is progressive decentralization: remove the privileged role entirely as the network matures. The v1 trust model is an explicit, temporary compromise documented in the governance roadmap (Section 13).

## Epoch Chain Integrity

The settlement layer's epoch chain has several structural integrity properties.

**Monotonic epoch numbers.** The contract rejects any epoch with a number not greater than the last accepted epoch. This prevents replay and reordering.

**Root chaining.** Each epoch submission includes the previous epoch's cumulative root. The contract verifies this matches the stored root. This prevents forking: two different epoch N submissions would need to reference the same previous root, but only one can be accepted.

**Validator set versioning.** Each epoch submission includes the validator set version that produced it. After an emergency removal advances the set version, epochs signed by the old set are rejected even if the signatures are mathematically valid.

**Idempotent submission.** If two validators race to submit the same valid epoch, the first is accepted and the second reverts cheaply. No harm done.

These properties are enforced by the L1 contract, not by the validators. A compromised validator set cannot bypass them without also compromising the L1 chain itself.
