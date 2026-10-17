# UTEM reborn

A generic reference first Futamura projector over AYXG symbolic transition
systems, with a Lean proof of correctness and a bridge to WRUH's reference
semantics conditional on its existing `SymexLaws`.

The implementation binds code in a returned typed initializer, specializes
expressions and complete state updates, discovers bounded facts contexts, and
emits a finite residual STS. It proves entry, two-sided transition correspondence,
observable effects/results, and silent-divergence preservation. See the
[implementation guide](docs/reference-implementation.md) and the original
[contract and literature audit](docs/contract.md).

## Read the implementation

- [`Reference/Projector.lean`](Reference/Projector.lean): executable `project`,
  `project_correct`, inhabited `referenceProjector`, result equation, and
  `projected_wruh_bisimilar` instantiated with this implementation.
- [`Reference/GraphCorrect.lean`](Reference/GraphCorrect.lean): exact forward and
  backward transitions, including origin preservation and context consistency.
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
[`evidence/2026-10-17/`](evidence/2026-10-17/). Those earlier logs cover the original contract. The implemented projector's
[full package build and axiom audit](evidence/2026-10-17/reference/package-check.log)
also passed. Its proof scope, accepted performance limitations and completed
review reports are in the [implementation guide](docs/reference-implementation.md).
