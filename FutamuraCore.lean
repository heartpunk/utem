import Ayxg.LTS

/-!
Semantic core for the AYXG first Futamura projection specification.
The imported LTS is AYXG's actual declaration, not a replacement.
`none` labels silent transitions; `some e` labels observable transitions.
No implementation of specialization is assumed or postulated here.
-/
namespace Futamura

abbrev System (S E : Type) := Ayxg.LTS S (Option E)

inductive SilentPath {S E : Type} (m : System S E) : S → S → Prop where
  | refl (s) : SilentPath m s s
  | cons {s u t} : m.Tr s none u → SilentPath m u t → SilentPath m s t

namespace SilentPath
theorem trans {S E : Type} {m : System S E} {s u t : S}
    (h : SilentPath m s u) (k : SilentPath m u t) : SilentPath m s t := by
  induction h with
  | refl => exact k
  | cons step _ ih => exact .cons step (ih k)
end SilentPath

def WeakStep {S E : Type} (m : System S E) (s : S) (a : Option E) (t : S) : Prop :=
  match a with
  | none => SilentPath m s t
  | some e => ∃ u v, SilentPath m s u ∧ m.Tr u (some e) v ∧ SilentPath m v t

theorem weakStep_single {S E : Type} {m : System S E} {s t : S} {a : Option E}
    (h : m.Tr s a t) : WeakStep m s a t := by
  cases a with
  | none => exact .cons h (.refl _)
  | some e => exact ⟨s, t, .refl _, h, .refl _⟩

/-- Actual infinite silent execution, not arbitrarily long finite executions. -/
def Diverges {S E : Type} (m : System S E) (s : S) : Prop :=
  ∃ run : Nat → S, run 0 = s ∧ ∀ n, m.Tr (run n) none (run (n + 1))

/-- Two-sided weak bisimulation with preservation AND reflection of divergence. -/
structure WeakBisimulation {S T E : Type} (m : System S E) (n : System T E)
    (R : S → T → Prop) : Prop where
  forward : ∀ {s t}, R s t → ∀ {a s'}, m.Tr s a s' →
    ∃ t', WeakStep n t a t' ∧ R s' t'
  backward : ∀ {s t}, R s t → ∀ {a t'}, n.Tr t a t' →
    ∃ s', WeakStep m s a s' ∧ R s' t'
  divergence : ∀ {s t}, R s t → (Diverges m s ↔ Diverges n t)

/-- Canonical semantic relation. There is no user-selectable `relates` parameter. -/
def Bisimilar {S T E : Type} (m : System S E) (n : System T E) (s : S) (t : T) : Prop :=
  ∃ R : S → T → Prop, WeakBisimulation m n R ∧ R s t

namespace WeakBisimulation
variable {S T E : Type} {m : System S E} {n : System T E} {R : S → T → Prop}

theorem symm (h : WeakBisimulation m n R) :
    WeakBisimulation n m (fun t s => R s t) where
  forward := h.backward
  backward := h.forward
  divergence := fun hst => (h.divergence hst).symm

theorem silent (h : WeakBisimulation m n R) {s s' : S} {t : T}
    (hst : R s t) (p : SilentPath m s s') :
    ∃ t', SilentPath n t t' ∧ R s' t' := by
  induction p generalizing t with
  | refl => exact ⟨t, .refl _, hst⟩
  | cons step _ ih =>
    obtain ⟨u, hu, hsu⟩ := h.forward hst step
    obtain ⟨v, hv, hrv⟩ := ih hsu
    exact ⟨v, SilentPath.trans hu hv, hrv⟩

theorem weak (h : WeakBisimulation m n R) {s s' : S} {t : T} {a : Option E}
    (hst : R s t) (p : WeakStep m s a s') :
    ∃ t', WeakStep n t a t' ∧ R s' t' := by
  cases a with
  | none => exact h.silent hst p
  | some e =>
    obtain ⟨u, v, hu, hv, hw⟩ := p
    obtain ⟨tu, htu, hru⟩ := h.silent hst hu
    obtain ⟨tv, htv, hrv⟩ := h.forward hru hv
    obtain ⟨tw, htw, hrw⟩ := h.silent hrv hw
    obtain ⟨x, y, hx, hy, hz⟩ := htv
    exact ⟨tw, ⟨x, y, htu.trans hx, hy, hz.trans htw⟩, hrw⟩
end WeakBisimulation

namespace Bisimilar
variable {S T E : Type} {m : System S E} {n : System T E}

/-- The union of all certified witnesses is itself a certified bisimulation. -/
theorem isBisimulation : WeakBisimulation m n (Bisimilar m n) where
  forward := by
    intro s t h a s' step
    obtain ⟨R, hb, hr⟩ := h
    obtain ⟨t', ht, hr'⟩ := hb.forward hr step
    exact ⟨t', ht, R, hb, hr'⟩
  backward := by
    intro s t h a t' step
    obtain ⟨R, hb, hr⟩ := h
    obtain ⟨s', hs, hr'⟩ := hb.backward hr step
    exact ⟨s', hs, R, hb, hr'⟩
  divergence := by
    rintro s t ⟨R, hb, hr⟩
    exact hb.divergence hr

theorem refl (s : S) : Bisimilar m m s s := by
  refine ⟨Eq, ?_, rfl⟩
  constructor
  · intro x y h a x' step
    subst y
    exact ⟨x', weakStep_single step, rfl⟩
  · intro x y h a y' step
    subst y
    exact ⟨y', weakStep_single step, rfl⟩
  · intro x y h
    subst y
    exact Iff.rfl

theorem symm {s : S} {t : T} (h : Bisimilar m n s t) : Bisimilar n m t s := by
  obtain ⟨R, hb, hr⟩ := h
  exact ⟨fun t s => R s t, hb.symm, hr⟩

/-- Compose semantic correspondences, retaining the divergence condition. -/
theorem trans {U : Type} {p : System U E} {s : S} {t : T} {u : U}
    (h : Bisimilar m n s t) (k : Bisimilar n p t u) : Bisimilar m p s u := by
  obtain ⟨R, hr, hst⟩ := h
  obtain ⟨Q, hq, htu⟩ := k
  refine ⟨(fun s u => ∃ t, R s t ∧ Q t u), ?_, t, hst, htu⟩
  constructor
  · rintro s u ⟨t, hst, htu⟩ a s' step
    obtain ⟨t', ht', hr'⟩ := hr.forward hst step
    obtain ⟨u', hu', hq'⟩ := hq.weak htu ht'
    exact ⟨u', hu', t', hr', hq'⟩
  · rintro s u ⟨t, hst, htu⟩ a u' step
    obtain ⟨t', ht', hq'⟩ := hq.backward htu step
    obtain ⟨s', hs', hr'⟩ := hr.symm.weak hst ht'
    exact ⟨s', hs', t', hr', hq'⟩
  · rintro s u ⟨t, hst, htu⟩
    exact (hr.divergence hst).trans (hq.divergence htu)

/-- Equality of labeled transition relations induces identity bisimulation. -/
theorem of_transition_iff {p : System S E}
    (steps : ∀ s a t, m.Tr s a t ↔ p.Tr s a t) (s : S) : Bisimilar m p s s := by
  refine ⟨Eq, ?_, rfl⟩
  constructor
  · intro s t same a s' step
    subst t
    exact ⟨s', weakStep_single ((steps _ _ _).mp step), rfl⟩
  · intro s t same a t' step
    subst t
    exact ⟨t', weakStep_single ((steps _ _ _).mpr step), rfl⟩
  · intro s t same
    subst t
    constructor
    · rintro ⟨run, first, next⟩
      exact ⟨run, first, fun k => (steps _ _ _).mp (next k)⟩
    · rintro ⟨run, first, next⟩
      exact ⟨run, first, fun k => (steps _ _ _).mpr (next k)⟩

theorem divergence {s : S} {t : T} (h : Bisimilar m n s t) :
    Diverges m s ↔ Diverges n t := isBisimulation.divergence h
end Bisimilar

/-- Finite observable trace, including all finite silent prefixes/suffixes. -/
inductive Trace {S E : Type} (m : System S E) : S → List E → S → Prop where
  | nil {s t} : SilentPath m s t → Trace m s [] t
  | cons {s u t e es} : WeakStep m s (some e) u → Trace m u es t →
      Trace m s (e :: es) t

theorem WeakBisimulation.trace {S T E : Type} {m : System S E} {n : System T E}
    {R : S → T → Prop} (h : WeakBisimulation m n R) {s s' : S} {t : T} {es : List E}
    (hst : R s t) (p : Trace m s es s') :
    ∃ t', Trace n t es t' ∧ R s' t' := by
  induction p generalizing t with
  | nil hp =>
    obtain ⟨t', ht, hr⟩ := h.silent hst hp
    exact ⟨t', .nil ht, hr⟩
  | cons hp _ ih =>
    obtain ⟨u, hu, hru⟩ := h.weak hst hp
    obtain ⟨t', ht, hr⟩ := ih hru
    exact ⟨t', .cons hu ht, hr⟩

def HasTrace {S E : Type} (m : System S E) (s : S) (es : List E) : Prop :=
  ∃ t, Trace m s es t

def DivergesAfter {S E : Type} (m : System S E) (s : S) (es : List E) : Prop :=
  ∃ t, Trace m s es t ∧ Diverges m t

theorem Bisimilar.traces {S T E : Type} {m : System S E} {n : System T E}
    {s : S} {t : T} (h : Bisimilar m n s t) (es : List E) :
    HasTrace m s es ↔ HasTrace n t es := by
  constructor
  · rintro ⟨s', hp⟩
    obtain ⟨t', ht, _⟩ := isBisimulation.trace h hp
    exact ⟨t', ht⟩
  · rintro ⟨t', hp⟩
    obtain ⟨s', hs, _⟩ := isBisimulation.trace h.symm hp
    exact ⟨s', hs⟩

theorem Bisimilar.divergentTraces {S T E : Type} {m : System S E} {n : System T E}
    {s : S} {t : T} (h : Bisimilar m n s t) (es : List E) :
    DivergesAfter m s es ↔ DivergesAfter n t es := by
  constructor
  · rintro ⟨s', hp, hd⟩
    obtain ⟨t', ht, hr⟩ := isBisimulation.trace h hp
    exact ⟨t', ht, hr.divergence.mp hd⟩
  · rintro ⟨t', hp, hd⟩
    obtain ⟨s', hs, hr⟩ := isBisimulation.trace h.symm hp
    exact ⟨s', hs, hr.divergence.mp hd⟩

/-- Returning is observable, distinct from silent deadlock. -/
inductive Observation (Effect Result : Type) where
  | effect : Effect → Observation Effect Result
  | returned : Result → Observation Effect Result

/-- Fixed by the projection specification, not by its implementation. -/
structure Interface (S Edge Input Effect Result : Type) where
  entry : Input → S
  observe : S → Edge → S → Option Effect
  result : S → Option Result

/-- The view retains every underlying transition. A declared result can be
reported to an external terminal sink. Nothing can run after that report.
Whether/where a result is available is part of the supplied interface semantics. -/
inductive ViewedStep {S Edge Input Effect Result : Type}
    (raw : Ayxg.LTS S Edge) (view : Interface S Edge Input Effect Result) :
    Option S → Option (Observation Effect Result) → Option S → Prop where
  | step {s e t} : raw.Tr s e t →
      ViewedStep raw view (some s) ((view.observe s e t).map Observation.effect) (some t)
  | returned {s r} : view.result s = some r →
      ViewedStep raw view (some s) (some (.returned r)) none

def viewed {S Edge Input Effect Result : Type}
    (raw : Ayxg.LTS S Edge) (view : Interface S Edge Input Effect Result) :
    System (Option S) (Observation Effect Result) := ⟨ViewedStep raw view⟩

def Returns {S Effect Result : Type} (m : System S (Observation Effect Result))
    (s : S) (effects : List Effect) (r : Result) : Prop :=
  HasTrace m s (effects.map Observation.effect ++ [.returned r])

theorem Bisimilar.results {S T Effect Result : Type}
    {m : System S (Observation Effect Result)} {n : System T (Observation Effect Result)}
    {s : S} {t : T} (h : Bisimilar m n s t) (effects : List Effect) (r : Result) :
    Returns m s effects r ↔ Returns n t effects r :=
  h.traces _

end Futamura
