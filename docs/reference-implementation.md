# Reference first Futamura projector

`Reference.project` accepts fixed code and an AYXG STS and returns a residual
AYXG STS plus typed initialization. The remaining input is the only input to
that residual initializer. Configuration supplies a context budget, tracked
scalar variables/fixed memory addresses, and a typed code-loading function.
`Reference.referenceProjector` pairs this executable construction with the
universally quantified proof required by `FirstFutamura.lean`.

## Construction and proof

| Module | Construction | Proved property |
| --- | --- | --- |
| `Facts` | Literal facts and typed cell lookup | Lookup is valid in every satisfying environment |
| `Rewrite`, `Binders`, `Specialize` | Recursive scalar/memory simplification, preserved parallel lets | Expression denotation is unchanged under known facts |
| `Transfer` | Complete simultaneous update rewriting; seed and next facts | Same complete successor state; inferred facts hold there |
| `Contexts` | Bounded discovery from entry; immutable table and empty fallback | Every selected target has the inferred facts or no assumed facts |
| `Tagged`, `Graph` | Materialized residual edge payloads, context tag, false-guard pruning, source origins | Tag discrimination, update evaluation, and exact emitted membership |
| `GraphCorrect` | Source/residual correspondence | Forward and backward steps preserve complete state and valid context facts |
| `Strong`, `Projector` | Observation view, full theorem, WRUH composition | Effect/result correspondence and actual infinite silent-run preservation/reflection |

For example, under facts `pc = 4` and `memory[4] = ADD`, an edge testing
`memory[pc] = ADD` can lose that test, and `pc := pc + 1` becomes `pc := 5`.
The emitted edge additionally tests its context tag and writes its selected
successor tag. The ordinary source state remains present. A missing specialized
successor context goes to the empty-facts context with that state intact.

The relation is: removing the tag recovers the source state, and the selected
table facts hold of that state. It is constructed by the proof, not supplied as
a premise. No helper evaluator-correctness axiom is assumed. Mutable code memory
is handled by recomputing facts from updates; an unknown write can discard facts.

The first-projection result equation and WRUH bridge are respectively
`Reference.first_futamura_equation` and `Reference.projected_wruh_bisimilar`.
The latter still assumes WRUH's `SymexLaws` for the chosen adapter; the
specialization leg is now proved for the implemented projector.

## Intentional reference limitations

- The context budget limits precision, not semantic validity. Discovery skips
  known-false edges and starts from the seed rather than the generic fallback.
- The tracked-cell list is an explicit configuration argument. A caller can
  choose it from code before invoking `project`; the fixed-list theorem holds
  for every such choice. Automatic indexing-policy selection is not implemented.
- Boolean/bit-vector operations and known-address reads are simplified. FP
  operations and array equality remain residual; specialization does not
  enumerate an array's index domain to evaluate equality.
- Dynamic parallel let RHSs remain shared through bindings. Only literal binder
  values become facts; array aliases are not propagated. Consequently a read
  through `let m' := m` may remain residual despite a known fact about `m`.
- Pointer-shared expression DAGs are traversed structurally. Repeated references
  can therefore cause exponential work in distinct DAG nodes. Substitution has
  related sharing costs. These accepted limitations are marked at `specialize`,
  `afterCell`, and emission; no polynomial/FPT runtime bound is claimed.
- The original state and source-step granularity remain. There is no transition
  compression, general interpreter elimination, or Jones-optimality claim.
- Source edge identity is retained. This is not yet a nested guest/native
  provenance theorem beyond that exact retained origin.

## Literature correspondence

The nearest reference is Jones, Gomard and Sestoft, Chapter 4: specialize program
points by known stores and construct their reachable contexts (§4.4.2–4.4.3,
Figures 4.6–4.7). Their §4.4.4 separates the uncompressed specialized graph from
transition compression. The budget and empty-facts fallback are this
implementation's conservative termination policy, not attributed to the book.
[Book and implementations](https://raspi.itu.dk/people/sestoft/pebook/pebook.html).

Brown and Palsberg, §2 Definition 2.1 and Figure 1, distinguish semantic partial
evaluation/first projection from Jones-optimality (Definition 2.3). Their §3
explains why duplication of dynamic computations matters. Our preserved lets
follow that conservative sharing discipline; no optimality result is borrowed.
[POPL 2018 paper](https://web.cs.ucla.edu/~palsberg/paper/popl18-full.pdf).

## Validation

The integrated `nix develop --command scripts/check` passed on NixOS with Lean
4.34.0 and the pinned AYXG/WRUH PR dependencies. All seven audited reference
proofs, including the full projector and WRUH bridge, report only `propext`,
`Classical.choice`, and `Quot.sound`; none reports `sorryAx`.

The existing reviewer signed off, confirmed the final discovery adjustment,
and a subsequent fresh independent reviewer returned READY. An additional early
drift review also found no blocker. These are source audits; build evidence is
recorded separately.

- [Full package and axiom log](../evidence/2026-10-17/reference/package-check.log).
- [Resource/timing metadata](../evidence/2026-10-17/reference/build-metadata.txt).
- [Exact local source manifest](../evidence/2026-10-17/reference/source-manifest.json)
  and [matching built-source hashes](../evidence/2026-10-17/reference/remote-source-hashes.txt).
- [Existing-reviewer recheck](../evidence/2026-10-17/reference/review-existing.md),
  [early drift review](../evidence/2026-10-17/reference/review-early.md), and
  [fresh final review](../evidence/2026-10-17/reference/review-final.md).

The full check used the existing `fleet-build.slice`, with 8 GiB memory max,
6 GiB high, zero swap and four CPUs. It exited 0, peaked at approximately
762 MiB memory, and used 40.56 CPU seconds. Cached dependencies were retained;
these timings are not a cold dependency build.
