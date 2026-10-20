# UTEM

## human overview

so uhm uh. utem exists basically bcz [wruh](https://github.com/heartpunk/wruh) can at present and for the near term future only handle binaries. and there's lots of interpreted langs and bytecode and whatnot in this world. and so it turns out that practically speaking, we needed a 1st futamura projector so we could take the models wruh can give us of binaries and use them models of a langs interpreter plus the code the lang would interpret (like, some python or ruby or js program) and turn it into yet another model for us.

tl;dr: utem makes it so instead of wruh just letting us make ayxg sts models of binary programs we can also in principle make ayxg sts models of all interpreted programs and hence all programs. afaik there is no reason at this point why we can't, w/a lot of coordinated effort and tryign hard and believing in our collective selves, get models of all software in lean such that we can prove it all. utem is a core of that bootstrap.

### review status

i've checked it over like skim-like and the walkthru that's gonna be committed soon-like at [ufda main](https://github.com/heartpunk/ufda) but it is admittedly not read in its entirety every character by me. astra and deepseek both agree it is a first futamura projector. it doesn't seem like it could not be from what i've seen. the types correspond clear as day. but it is not 100% properly reviewed yet, and it should be given what it intends to do.

## Generated Overview

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
| IFRL | `9aa5e2953b840c3ec0879c2c4fa068dee3348498` | Shared Nix inputs and toolchain infrastructure |
| AYXG | `fe01a093ea197b84e92f11f18804814d8f9a9448` | Typed STS, QF_ABV syntax and semantics, patched FloatLib environment |
| WRUH | `d9bfd5e92e9bf96bf0eb9b6e3ad49a2ae5998eec` | `Wruh.FreshExtraction` and `SymexLaws` |

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
