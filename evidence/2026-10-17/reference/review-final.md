# Fresh final independent review

Reviewer: `/root/final_reference_review`. Read-only source review, including
pinned dependency semantics; no independent builds or axiom execution.

**READY for the stated generic reference first-projection milestone.** No
material correctness issue or scope drift was found.

- **Complete-state invariant:** `StateRel` requires the residual environment to
  equal the source environment with a context tag prepended, and the selected
  context's facts to hold. `StateRel.erase` recovers the complete configuration;
  the proof does not reconstruct it from a lossy abstract state.
- **Facts and mutable code:** `afterCell` substitutes the complete simultaneous
  update before specialization. `learn_correct` proves facts about the actual
  successor environment. Unknown writes conservatively lose facts; there is no
  code-memory immutability premise.
- **Bindings:** sibling let RHSs use the original facts and environment. Fresh
  literal-binder facts are introduced only for the body, with prior facts
  weakened correctly. Dynamic bindings remain. This agrees with AYXG's parallel
  binding semantics.
- **Graph completeness/provenance:** enabled source edges cannot be pruned.
  Membership identifies the exact source edge and context. Both directions
  preserve origin, full successor state and valid facts. Exhausted discovery
  enters empty facts without discarding state.
- **Materialized residual:** `CompiledEdge` stores its symbolic label;
  `compiledSemantics.symbolicLabel` is a field projection. Runtime does not
  invoke specialization. `compiledSystem` captures the emitted list; `project`
  returns that system and the code-bound initializer.
- **Implemented correctness:** `referenceProjector.correct` uses
  `project_correct`, which constructs the relation and discharges the
  obligations. Helper rewrite laws are instantiated locally, not external
  specialization-correctness assumptions.
- **Effects, returns, divergence:** observations use full-state erasure and
  retained edge identity. Step-for-step observed correspondence transports
  actual infinite silent runs both ways. Returns use the explicit terminal sink.

The WRUH composition retains `SymexLaws A` for extraction. It does not assume
correctness of the new specialization leg.

Documented limitations are nonblocking: structural DAG/substitution costs can
be exponential; tracked cells are configured; array aliases and some expressions
remain residual; source-step granularity remains. No transition compression,
Jones-optimality, or second/third-projection claim is made.

The source was reviewed as working-tree content over previous commit
`8d138a8506a58640a93897ead06019f91fbfb428`, which does not contain this new
implementation. `implementation-revision.txt` records the resulting immutable
implementation revision; these fingerprints identify the reviewed bytes.

| File | Reviewed declarations | SHA-256 |
| --- | --- | --- |
| Reference/Graph.lean | CompiledEdge, compiledSemantics, compiledSystem, StateRel, StateRel.erase | b8f8d8be4ebcd2ed8cfa5e43dbf437b270fabb9074c962783875234ed71c8b04 |
| Reference/Transfer.lean | afterCell, learn_correct, specializeUpdate_correct | 77a4a09e0bac583b857727ac56310beefb826767d8c5405da300d8e6ae5888e3 |
| Reference/Binders.lean | consBindings, rewriteLet | c766bd9c0a9d9e65ce39986cca42e79c7103460e0935d592b2a663b8c9117f60 |
| Reference/GraphCorrect.lean | graph_forward, graph_backward | b26fabfe2589b48ce14ee017f8a067305a26b7e65c943bcaf211fe63158fb009 |
| Reference/Contexts.lean | discover, chooseTarget, chooseTarget_consistent | e6b0ed4e7103ce91ede964bf62c9b26b33067681255c4ff05cc76373ca1f2acc |
| Reference/Projector.lean | project, project_correct, referenceProjector, projected_wruh_bisimilar | fa7aeb7180b1d9c4cbf2bc3305ff64bf66d825ee5f5be175e17f231784e6d71c |
| Reference/Strong.lean | divergence_of_step_simulation, StrongBisimulation.weak | 8dcca17e88fed638f44d66e75ab2f346aec4f9e949258a0bb905d23b27ff9f82 |
| Reference/Facts.lean | full module | 8b25a88176570607b355fa545492d79c6941fcae3326731814c437bbf803e14f |
| Reference/Rewrite.lean | full module | de146f8d9f74daf8cc8bf755674df7e31881b89a4fd6c63da829e5e50b28c10b |
| Reference/Specialize.lean | full module | d25b898771338e6b6eddad1b5bd8848930fae29c6353984f184f111eb8c6c5fb |
| Reference/Tagged.lean | full module | 95fbdd420303e224a21f3edbbe66ab824a521fc133c15260c970f94d905b7772 |

Dependency semantics inspected:

- `heartpunk/ayxg` at `5106df06d92620da810c325b8779ce97a14f7f0e`:
  `Ayxg/QfAbv/Eval.lean`, `evalBindings` (114–118), and
  `Ayxg/QfAbv/Update.lean`, `eval`, `eval_eq_subst_eval` (32–37, 83–90).
- `heartpunk/wruh` at `16d77877512d97fad0622a7a6ac401cf8b2dd538`:
  `Wruh/FreshExtraction.lean`, `SymexLaws`, `extract_transition_sound`,
  `extract_transition_complete` (22–31, 60–83).
- Existing `FutamuraCore.lean`: actual infinite `Diverges` and terminal-sink
  `ViewedStep`; unchanged from previous implementation-base commit.

The parent's separate full package/axiom check subsequently passed; see
`package-check.log`, `build-metadata.txt`, and `source-manifest.json`.
