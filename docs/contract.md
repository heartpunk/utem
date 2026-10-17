# First Futamura projector — contract and reference implementation

The sketch preserves the Obsidian UTEM outline: typed entry maps and explicit
`entry`, `forward`, and `backward` obligations. It incorporates the subsequent
choice of weak steps, observable results/effects, and preservation and reflection
of silent divergence. The residual object contains its own typed entry map.

**Validation passed:** the complete revised `FirstFutamura.lean`, including all
contract declarations and conditional proofs, passed Lean 4.34.0 on NixOS against
the pinned PR sources. There are no `sorry`/`admit` placeholders; the axiom audit
contains only `propext`, `Classical.choice`, and `Quot.sound`.
The original contract-only milestone deferred construction. That work is now
implemented in `Reference/`: `referenceProjector` constructs an inhabitant for
its explicit tag-erasure specification, and `project_correct` proves its full
correctness. This does not assert existence for arbitrary incompatible
specifications. See [the implementation guide](reference-implementation.md).

## Contract and construction goal

The essential declarations in `FirstFutamura.lean` are:

```lean
abbrev System (Γ : Ctx) (Edge : Type) :=
  SymbolicTransitionSystem Unit Γ Edge

structure Residual (Γres Γinput : Ctx) (ResidualEdge : Type) where
  system : System Γres ResidualEdge
  entry : StateUpdate Γinput Γres

abbrev Project (Code SourceEdge ResidualEdge : Type) (Γsrc Γres Γinput : Ctx) :=
  Code → System Γsrc SourceEdge → Residual Γres Γinput ResidualEdge

def FirstFutamuraProblem
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput) : Prop :=
  ∃ project : Project Code SourceEdge ResidualEdge Γsrc Γres Γinput,
    ∀ code source, ∃ R, ProjectionCorrect spec code source (project code source) R

structure FirstProjector
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput) where
  specialize : Project Code SourceEdge ResidualEdge Γsrc Γres Γinput
  correct : ∀ code source, ∃ R,
    ProjectionCorrect spec code source (specialize code source) R
```

`ProjectionSpec` fixes the code loader, admissibility guard, and source/residual
observation semantics. The loader is `Code → StateUpdate Γinput Γsrc`; the
residual entry is a returned `StateUpdate Γinput Γres`. Both entry maps are
finite typed QF_ABV syntax. Observation functions have no code argument and
are fixed before choosing the projector.

For each fixed code and source system, `ProjectionCorrect` requires:

- **Entry:** all admissible inputs initialize related source/residual states.
- **Forward:** every source transition has a residual weak-step match with the
  same observable label and related endpoints.
- **Backward:** every residual transition has a source weak-step match with the
  same observable label and related endpoints.
- **Divergence:** related states agree on the existence of an infinite silent run.

These obligations use AYXG's actual `toLTS` relation.[^ayxg]
The correspondence witness `R` comes from the implementation's proof. The caller
cannot demand an arbitrary relation. `FirstProjector.entry_bisimilar` assembles
these obligations into canonical divergence-preserving weak bisimilarity;
`first_futamura_equation` derives equality of observable result traces.
The `Option` state wrapper provides a terminal sink; an observed return is
therefore distinct from silent deadlock.

## Audit: the original loophole and its repair

The preserved initial draft is `history/FirstFutamura.initial.lean.txt` (SHA256
`02dc28a1741185d0c0202affff3fe5e841a0d74c3da116e4e81a667f264bca94`). Its
residual semantics called `residualInterface code residual.layout`. Consequently,
a permitted specification could choose `Layout = Unit`, keep the source state
shape, and define `residualInterface code () = sourceInterface code`. Returning
`⟨(), source⟩` for every code then satisfied the claimed correspondence by
reflexivity: the returned object had not bound the static argument at all.
Execution was still given that argument separately.

The revised `residualSystem spec residual` receives no code value. The typed
entry map binding fixed data is inside `Residual`, alongside the returned STS.
This closes that external-code channel while retaining the note's structure.

A different construction—returning the unchanged interpreter STS **with a
returned entry map that binds the fixed code**—is a legitimate, unoptimized
solution of the semantic equation when the representations permit it. Futamura
explicitly describes binding a constant before the original body in the s-m-n
construction (1983, p. 14). Rejecting that construction would add an optimization
requirement beyond semantic correctness. The reference implementation now performs constant/memory propagation and
context specialization in addition to binding; it claims no interpreter-overhead
elimination guarantee.

The earlier `enter : Correct spec project` also concealed all simulation
obligations under an entry-like name. They are now visible fields of
`ProjectionCorrect`. Packaging a correctly implemented specializer and its proof
is a valid contract; `Reference.referenceProjector` now constructs that package
for the implemented residual representation.

## WRUH composition and exact assumptions

WRUH already supplies the extracted-to-reference leg, conditional on its
`SymexLaws` contract.[^wruh] The revised sketch transports that exact labeled
relation through a fixed observation view, mapping extracted labels via `.edge`.
It then composes the two legs:

```text
returned residual STS + returned entry map, applied to remaining input
  ≈ extracted interpreter STS, initialized with fixed code + remaining input
  ≈ adapter reference interpreter, identically initialized
```

`projected_reference_bisimilar` explicitly takes:

1. An adapter `A`, binary, and a proof of `SymexLaws A`.
2. The concrete loading/admissibility/observation specification.
3. A constructed `FirstProjector (extractionSpec spec)`, whose `correct` field
   is the new specialization proof.
4. Fixed code, remaining input, and the admissibility proof.

Thus WRUH discharges the extraction leg; it does not discharge the new projector
proof. No theorem claims that every arbitrarily chosen specification is
realizable. The concrete CPython loader and observation decoders still need to
instantiate the stated interface; this sketch does not claim to supply them.

The source and residual edge types can retain native and guest provenance.
This semantic contract does not yet state a separate law for that metadata's
transformation. Likewise, it claims no optimization bound or elimination of
interpreter dispatch. These are distinct from the binding and preservation
obligations above.

## Literature correspondence

Futamura's first-projection equation is `C(P)(D) = I(P,D)`, with
`I_P = α(I,P)` and `C(P) = I_P` (1983, p. 9). Here `P` is `code`, `I` is the
source AYXG STS, `D` is the remaining input, and the returned residual plus its
entry map is `I_P`. The sketch's observable-trace equation is this result equation
extended to effects. Weak bisimulation and explicit silent-divergence agreement
are the project's stronger preservation requirement; they are not attributed as
an already-proved theorem of that paper.

- Futamura, *Partial computation of programs* (1983), pp. 4–6, 9, 14–15.
  [DOI](https://doi.org/10.1007/3-540-11980-9_13).
  Zotero item `KMQDZPQH`, attachment `E7ANWWWX`; page numbers are those printed
  in the library's 35-page scan. Page 14 supplies the constant-binding example.
- Fallin and Bernstein, *Partial Evaluation, Whole-Program Compilation* (2025),
  §2.1–2.2 and §3.5. [Author PDF](https://cfallin.org/pubs/pldi2025_weval.pdf).
  Its distinction between binding interpreter data and producing efficient
  bytecode-erased code supports keeping correctness and optimization separate.
  Its ABI can retain specialized parameters while ignoring their runtime values;
  the binding requirement concerns semantic dependence, not argument spelling.

## Build evidence

The original source manifest and logs are in `evidence/2026-10-17/`.
The repository build entry point is `scripts/check`. The build uses the
local Mac sources, including `.git` metadata for repository snapshots. All AYXG
and WRUH modules in this sketch's import closure are checked from those sources;
FloatLib and Mathlib use the cached dependencies. `ProofAudit.lean` prints the
axioms of the new conditional theorems.

The checked graph is:

```text
Lean 4.34.0 + cached Mathlib / patched FloatLib
  └─ 13 AYXG modules from PR #1 (freshly checked)
       ├─ Wruh.FreshExtraction from PR #2 (freshly checked)
       └─ FutamuraCore (freshly checked)
            └─ FirstFutamura, also importing Wruh.FreshExtraction (checked)
                 └─ ProofAudit (checked; no sorryAx)
```

All 14 upstream modules in this import closure passed in run `r5`; that run then
reported one elaboration error in the sketch's label-transport proof. Run `r6`
checked the corrected sketch and semantic core against those compiled modules,
then passed the axiom audit. Upstream source warnings were retained; warnings
are errors for the new sketch and core. FloatLib/Mathlib were reused from cache,
not rebuilt from source in this run.

- [Complete successful compiler and axiom log](../evidence/2026-10-17/validation-r6.log).
- [PR import-closure compilation log](../evidence/2026-10-17/validation-r5.log).
- [Resource limits, timings, source/output hashes, and unit journal](../evidence/2026-10-17/remote-build-metadata.txt).
- [Exact source manifest](../evidence/2026-10-17/source-manifest.json).
- Host `nixos`; final unit `codex-futamura-20261017-r6.service`, nested under
  `fleet-build.slice`; exit status **0** on 2026-10-17.
- Limits: 8 GiB memory, 6 GiB memory-high, zero swap, four CPU threads.
  Final check peak: 291.6 MiB; CPU: 5.27 seconds. The preceding dependency pass
  peaked at 512.5 MiB and used 61.22 CPU seconds. No resource-limit failure was
  reported; the recorded `r5` failure was the proof-term elaboration error above.
- Checked `FirstFutamura.lean` SHA256:
  `e3b35b82ec620a6ac40ee5e86bded1ab058fe716ac80f462fff4e6fd8abf1643`.
- Checked `FutamuraCore.lean` SHA256:
  `b7ed2f9b74b3c31dc8fd0e0a4c77c22aa17b6131cb1929a85c6ea9c06db60f30`.

These historical results validate the specified contract and its conditional
consequences. The newer reference implementation establishes an inhabitant for
its explicit specification; it does not prove the concrete angr adapter's
`SymexLaws` or supply CPython loading/observation decoders.

[^ayxg]: `heartpunk/ayxg` at `5106df06d92620da810c325b8779ce97a14f7f0e`,
    `Ayxg/LTS/QfAbv/SymbolicTransitionSystem.lean`, `SymbolicTransitionSystem`
    and `SymbolicTransitionSystem.toLTS` (lines 18–39).
    [Pinned source](https://github.com/heartpunk/ayxg/blob/5106df06d92620da810c325b8779ce97a14f7f0e/Ayxg/LTS/QfAbv/SymbolicTransitionSystem.lean#L18-L39).

[^wruh]: `heartpunk/wruh` at `16d77877512d97fad0622a7a6ac401cf8b2dd538`,
    `Wruh/FreshExtraction.lean`, `SymexLaws`, `extract_transition_sound`,
    `extract_transition_complete`, and `extract_bisimulation` (lines 22–31,
    60–83, 189–203).
    [Pinned source](https://github.com/heartpunk/wruh/blob/16d77877512d97fad0622a7a6ac401cf8b2dd538/Wruh/FreshExtraction.lean#L189-L203).
