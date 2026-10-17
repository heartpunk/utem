# UTEM reborn

A typed first Futamura projector contract over AYXG symbolic transition systems,
with a conditional correctness bridge to WRUH's reference semantics.

The contract and its conditional theorems are checked Lean. A specializer
implementation and proof that the projector type is inhabited are deliberately
not supplied. See [the contract and literature audit](docs/contract.md).

## Read the sketch

- [`FirstFutamura.lean`](FirstFutamura.lean): typed code loading, residual STS plus
  initialization, entry/forward/backward/divergence obligations, projector type,
  observable result equation, and WRUH composition.
- [`FutamuraCore.lean`](FutamuraCore.lean): observation interface and
  divergence-preserving weak bisimulation over AYXG's LTS.
- [`tests/ProofAudit.lean`](tests/ProofAudit.lean): prints theorem types and axiom
  dependencies. The checked conditional theorems use only `propext`,
  `Classical.choice`, and `Quot.sound`.

## Dependencies

| Dependency | Pinned revision | Role |
| --- | --- | --- |
| IFRL | `c69a322ec903672a2def1841be661eb6a339c89b` | Shared Nix inputs and toolchain infrastructure |
| AYXG | `5106df06d92620da810c325b8779ce97a14f7f0e` | Typed STS, QF_ABV syntax and semantics, patched FloatLib environment |
| WRUH | `16d77877512d97fad0622a7a6ac401cf8b2dd538` | `Wruh.FreshExtraction` and `SymexLaws` |

Lean is pinned to **4.34.0**. `flake.lock` pins the Nix dependency graph;
`lake-manifest.json` pins the Lean dependencies. WRUH and this package share the
same AYXG checkout. IFRL supplies Nix infrastructure; it is not a Lean import.

## Check

From the repository root:

```sh
nix develop --command scripts/check
```

This builds the library and runs the axiom audit. The AYXG shell supplies the
matching patched FloatLib source; use this environment rather than a bare Lake
invocation. The first build needs the Lean dependency caches or sufficient space
to populate them. For remote builds, transfer source and `.git` together, retain
existing caches, and run the build under the available fleet build reservation.

The normal package command above passed on NixOS on 2026-10-17 using the
pinned dependencies and their caches. See the [package build and axiom log](evidence/2026-10-17/package-check.log)
and [source hashes and resource measurements](evidence/2026-10-17/package-build-metadata.txt).
The original full-sketch check is also retained in
[`evidence/2026-10-17/`](evidence/2026-10-17/). The mathematical source files are
unchanged from that checked sketch.
