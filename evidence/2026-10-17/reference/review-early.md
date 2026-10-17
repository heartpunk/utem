# Fresh early drift review

Reviewer: `/root/review_reference_drift`. Read-only source review; no build.

**Verdict: no blocking defect found.** This is an implemented generic specializer
with constructed correctness, beyond merely binding code into an unchanged
interpreter.

- `Projector.project` binds static code in returned syntax and materializes
  residual labels. Runtime does not rerun specialization.
- `Specialize.specialize` folds literals, reduces known reads, and preserves
  parallel lets. Helper semantic arguments are supplied internally by constructor
  proofs, not imposed on projector callers.
- `Transfer.learn_correct` derives facts from complete simultaneous updates,
  including mutable code memory and conservative loss of facts on unknown writes.
- `GraphCorrect` covers both directions and exact source-edge identity.
  `observed_strong` and `StrongBisimulation.weak` cover effects, returns and divergence.
- `projected_wruh_bisimilar` uses the implemented projector with `SymexLaws` as
  the remaining extraction assumption.

Nonblocking observations: context budget could be spent on fallback/false-guard
successors (subsequently corrected); array aliases are not propagated through
bindings (documented at `consBindings` and in the implementation guide).

JGS separates specialized-point generation from transition compression.
Brown–Palsberg separates semantic first-projection correctness from
Jones-optimality. The implementation's stated conservative scope matches these
boundaries. This early review is additional to the required final fresh review.
