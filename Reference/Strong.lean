import FutamuraCore

namespace Futamura

/-- A step-for-step simulation transports actual infinite silent runs. Classical
choice is used only in this Prop-valued proof, never in the executable projector. -/
theorem divergence_of_step_simulation {S T E : Type} {m : System S E} {n : System T E}
    {R : S → T → Prop}
    (step : ∀ {s t}, R s t → ∀ {a s'}, m.Tr s a s' → ∃ t', n.Tr t a t' ∧ R s' t')
    {s t} (related : R s t) (divergent : Diverges m s) : Diverges n t := by
  classical
  rcases divergent with ⟨run, first, next⟩
  have start : R (run 0) t := by rw [first]; exact related
  have advance (k : Nat) (v : { t' : T // R (run k) t' }) :
      ∃ t', n.Tr v.val none t' ∧ R (run (k + 1)) t' := step v.property (next k)
  let lifted : (k : Nat) → { t' : T // R (run k) t' } :=
    Nat.rec ⟨t, start⟩ (fun k v =>
      ⟨Classical.choose (advance k v), (Classical.choose_spec (advance k v)).2⟩)
  refine ⟨fun k => (lifted k).val, rfl, ?_⟩
  intro k
  exact (Classical.choose_spec (advance k (lifted k))).1

structure StrongBisimulation {S T E : Type} (m : System S E) (n : System T E)
    (R : S → T → Prop) : Prop where
  forward : ∀ {s t}, R s t → ∀ {a s'}, m.Tr s a s' → ∃ t', n.Tr t a t' ∧ R s' t'
  backward : ∀ {s t}, R s t → ∀ {a t'}, n.Tr t a t' → ∃ s', m.Tr s a s' ∧ R s' t'

theorem StrongBisimulation.weak {S T E : Type} {m : System S E} {n : System T E}
    {R : S → T → Prop} (h : StrongBisimulation m n R) : WeakBisimulation m n R where
  forward := by
    intro s t related a s' step
    obtain ⟨t', next, related'⟩ := h.forward related step
    exact ⟨t', weakStep_single next, related'⟩
  backward := by
    intro s t related a t' step
    obtain ⟨s', next, related'⟩ := h.backward related step
    exact ⟨s', weakStep_single next, related'⟩
  divergence := by
    intro s t related
    exact ⟨divergence_of_step_simulation h.forward related,
      divergence_of_step_simulation (R := fun t s => R s t) h.backward related⟩

end Futamura
