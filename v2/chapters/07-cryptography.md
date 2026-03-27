# Cryptography

## Building on Giants

W3.io does not invent new cryptographic primitives. Every algorithm used in the protocol is a well-established, audited, production-grade construction with years of deployment in other systems. The protocol's security properties are inherited from these foundations, not asserted by novel constructions.

This is a deliberate choice. Novel cryptography is interesting research but a poor foundation for a production protocol. The attack surface of a new primitive is unknown by definition. The attack surface of BLS12-381 is understood by thousands of researchers and audited by every major Ethereum consensus client team. W3.io benefits from that scrutiny without paying for it.

The following table summarizes the cryptographic primitives used in the protocol, their purpose, and their provenance.

| Primitive | Purpose | Standard/Library | Used By |
|-----------|---------|-----------------|---------|
| BLS12-381 | Quorum signatures on epoch submissions, receipt signing, trigger confirmation, validator proof of possession | blst [@supranational2023blst], draft-irtf-cfrg-bls-signature [@irtf2022bls] | Ethereum 2.0 (Lighthouse, Prysm, Teku, Lodestar, Nimbus), Cosmos, Polkadot |
| keccak256 | Receipt hashing, namespace ID derivation, SMT key derivation, ABI encoding | Keccak (pre-NIST, Ethereum variant) | Ethereum (native hash function), Solidity `abi.encode` |
| ChaCha20 | Deterministic committee selection PRNG | RFC 8439 [@nir2018chacha20] | TLS 1.3, WireGuard, Linux kernel CSPRNG |
| Ed25519 | Validator identity keys, P2P message signing | RFC 8032 | libp2p, Signal, SSH, Tor |
| SHA-256 | Workflow run block hashchaining, trigger hash derivation | FIPS 180-4 | Bitcoin, TLS, nearly every production system |
| Jellyfish Merkle Tree | Two-level cumulative sparse merkle tree for settlement state | Diem/Aptos [@jellyfish2021] | Aptos, Penumbra |
| SSZ | Wire format for P2P message serialization | Ethereum SSZ specification [@ssz2019] | Ethereum 2.0 consensus layer |

## BLS12-381

W3.io uses BLS12-381 signatures for all protocol-level aggregate signing. BLS (Boneh-Lynn-Shacham) signatures have a unique property that makes them ideal for quorum-based systems: multiple individual signatures can be aggregated into a single signature of constant size, and the aggregate can be verified against the aggregate public key in a single operation. A quorum of 20 validators produces a signature no larger than one validator's signature.

W3.io's BLS implementation wraps the `blst` library [@supranational2023blst], the same library used by every major Ethereum 2.0 consensus client. The protocol uses the min-pk scheme (public keys in G1, signatures in G2), matching Ethereum 2.0's choice. On-chain verification uses EIP-2537 precompiles [@eip2537] for gas-efficient pairing checks. W3.io operates as a custom Avalanche L1 where the chain binary is under the protocol's control, and EIP-2537 precompiles are included in the custom chain configuration.

Four domain separation tags (DSTs) prevent cross-context signature replay:

| Context | DST | Purpose |
|---------|-----|---------|
| Epoch quorum | `W3IO-BLS-EPOCH-V1` | Validators sign the epoch tuple for L1 submission |
| Receipt gossip | `W3IO-BLS-RECEIPT-V1` | Committee members sign individual receipts |
| Trigger confirmation | `W3IO-BLS-TRIGGER-V1` | Monitor group members sign trigger evidence |
| Proof of possession | `W3IO-BLS-POP-V1` | Validators sign their own public key at registration |

A signature produced under one DST cannot be accepted under another, even if the underlying message bytes are identical. This is enforced at the library level: the DST is a required parameter to every sign and verify call.

Every validator must submit a proof of possession (PoP) at registration. The validator signs their own compressed G1 public key using the `W3IO-BLS-POP-V1` DST. The on-chain `ValidatorSet` contract verifies this signature before accepting the key. This prevents rogue public key attacks, where an attacker crafts a public key that cancels out honest validators' keys during aggregation.

W3.io enforces PoP at the type level. The `PopVerifiedKey` type can only be constructed by passing PoP verification. The `verify_aggregate` function requires `PopVerifiedKey` inputs, not raw public keys. This makes it a compile-time error to use an unverified key in aggregate signature verification.

## The Hash Boundary

W3.io uses two hash functions for different layers of the protocol, with a clean boundary between them.

**keccak256** is used for everything that touches the settlement layer or needs EVM compatibility: receipt hashing (`keccak256(abi.encode(receipt))`), namespace ID derivation (`keccak256(creator, nonce)`), SMT key derivation, and any value that will be verified by a Solidity contract. Keccak256 is Ethereum's native hash function [@buterin2014ethereum]. Note that Ethereum's keccak256 uses the original Keccak submission, not the NIST-standardized SHA3-256 (FIPS 202), which uses different padding. The two produce different outputs for the same input. W3.io uses the Ethereum variant for settlement compatibility.

**SHA-256** is used for protocol internals that never cross the EVM boundary: workflow run block hashchaining, trigger hash derivation, and monitor group seed computation. SHA-256 is used in 17 files across 8 crates in the protocol codebase.

The boundary is enforced through the type system. Settlement-layer types use `[u8; 32]` values produced by keccak256. Protocol-internal types use separate newtypes. A keccak256 hash cannot be accidentally passed where a SHA-256 hash is expected.

## ChaCha20 for Committee Selection

Committee selection requires a PRNG that is deterministic (all nodes compute the same shuffle), cryptographically secure (the output cannot be predicted or inverted), and efficient (committee selection happens frequently). ChaCha20 [@nir2018chacha20] meets all three requirements.

The seed is a SHA-256 hash of the cumulative settlement root concatenated with the trigger hash. This seed initializes a ChaCha20 stream cipher, which produces the random bytes needed to drive a Fisher-Yates shuffle over the validator set. The same seed always produces the same committee. Different seeds produce unpredictable committees.

ChaCha20 replaced an earlier linear congruential generator (LCG) that was trivially invertible. An attacker who observed a committee could invert the LCG to recover the seed and predict future committees. ChaCha20 does not have this property. The committee selection change is consensus-breaking: all validators must upgrade simultaneously.
