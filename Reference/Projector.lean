import Reference.GraphCorrect
import Reference.Strong

namespace Futamura.Reference
open Ayxg.QfAbv Ayxg.LTS.QfAbv
variable [FPInterpretation]

def liftedObservations (observations : Sketch.Observations Γ E Effect Result) :
    Sketch.Observations (ResidualCtx budget Γ) (CompiledEdge budget Γ E) Effect Result where
  effect := fun s edge t => observations.effect (eraseConfig s) edge.origin (eraseConfig t)
  result := fun s => observations.result (eraseConfig s)

inductive ViewRel (table : ContextTable Γ budget) :
    Option (Config Unit Γ) → Option (Config Unit (ResidualCtx budget Γ)) → Prop where
  | terminal : ViewRel table none none
  | active {s r} : StateRel table s r → ViewRel table (some s) (some r)

theorem observed_strong (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) (entry : StateUpdate Γinput Γ)
    (observations : Sketch.Observations Γ E Effect Result) :
    StrongBisimulation
      (viewed source.toLTS (Sketch.interfaceOf entry observations))
      (viewed (compiledSystem cells table source).toLTS
        (Sketch.interfaceOf (taggedEntry budget entry) (liftedObservations observations)))
      (ViewRel table) := by
  constructor
  · intro s r related a s' step
    cases related with
    | terminal => cases step
    | active related =>
      cases step with
      | step raw =>
        obtain ⟨edge, r', next, origin, related'⟩ := graph_forward cells table source related raw
        refine ⟨some r', ?_, .active related'⟩
        have hv := ViewedStep.step
          (view := Sketch.interfaceOf (taggedEntry budget entry) (liftedObservations observations)) next
        simpa [viewed, Sketch.interfaceOf, liftedObservations, related.erase, related'.erase, origin] using hv
      | returned result =>
        refine ⟨none, ViewedStep.returned ?_, .terminal⟩
        simpa [viewed, Sketch.interfaceOf, liftedObservations, related.erase] using result
  · intro s r related a r' step
    cases related with
    | terminal => cases step
    | active related =>
      cases step with
      | step raw =>
        obtain ⟨s', next, related'⟩ := graph_backward cells table source related raw
        refine ⟨some s', ?_, .active related'⟩
        have hv := ViewedStep.step (view := Sketch.interfaceOf entry observations) next
        simpa [viewed, Sketch.interfaceOf, liftedObservations, related.erase, related'.erase] using hv
      | returned result =>
        refine ⟨none, ViewedStep.returned ?_, .terminal⟩
        simpa [viewed, Sketch.interfaceOf, liftedObservations, related.erase] using result

/-- Public closed-residual constructor. Static code is bound in the returned
entry syntax and specialized graph; execution accepts only the remaining input. -/
def project (budget : Nat) (cells : Tracked Γ)
    (sourceEntry : Code → StateUpdate Γinput Γ) :
    Sketch.Project Code E (CompiledEdge budget Γ E) Γ (ResidualCtx budget Γ) Γinput :=
  fun code source =>
    let entry := sourceEntry code
    let table := buildContexts budget cells source entry
    { system := compiledSystem cells table source, entry := taggedEntry budget entry }

/-- The representation's observations are fixed by tag erasure and edge origin,
independently of code and of the projector's discovered contexts. -/
def specification (budget : Nat) (sourceEntry : Code → StateUpdate Γinput Γ)
    (admissible : Code → Expr Γinput .bool)
    (observations : Sketch.Observations Γ E Effect Result) :
    Sketch.ProjectionSpec Code E (CompiledEdge budget Γ E) Γ (ResidualCtx budget Γ) Γinput where
  Effect := Effect
  Result := Result
  sourceEntry := sourceEntry
  admissible := admissible
  sourceObservations := observations
  residualObservations := liftedObservations observations

/-- Universally quantified correctness of the implemented reference projector.
The proof constructs its relation. No specialization law or correspondence is
assumed from the caller. Code memory may change: successor facts are recomputed
from each complete simultaneous update. -/
theorem project_correct (budget : Nat) (cells : Tracked Γ)
    (sourceEntry : Code → StateUpdate Γinput Γ)
    (admissible : Code → Expr Γinput .bool)
    (observations : Sketch.Observations Γ E Effect Result) (code : Code)
    (source : Sketch.System Γ E) :
    ∃ R, Sketch.ProjectionCorrect (specification budget sourceEntry admissible observations)
      code source (project budget cells sourceEntry code source) R := by
  let table := buildContexts budget cells source (sourceEntry code)
  let strong := observed_strong cells table source (sourceEntry code) observations
  refine ⟨ViewRel table, ?_⟩
  constructor
  · intro input _allowed
    apply ViewRel.active
    refine ⟨entryIndex budget, ?_, ?_⟩
    · exact taggedEntry_eval budget (sourceEntry code) input
    · rw [buildContexts_entry]
      exact seed_correct (sourceEntry code) cells input
  · exact strong.weak.forward
  · exact strong.weak.backward
  · exact strong.weak.divergence

def referenceProjector (budget : Nat) (cells : Tracked Γ)
    (sourceEntry : Code → StateUpdate Γinput Γ)
    (admissible : Code → Expr Γinput .bool)
    (observations : Sketch.Observations Γ E Effect Result) :
    Sketch.FirstProjector (specification budget sourceEntry admissible observations) where
  specialize := project budget cells sourceEntry
  correct := project_correct budget cells sourceEntry admissible observations

/-- The implemented projector satisfies the first Futamura result equation for
all code, source STSs, admissible remaining inputs, effect traces and results. -/
theorem first_futamura_equation (budget : Nat) (cells : Tracked Γ)
    (sourceEntry : Code → StateUpdate Γinput Γ)
    (admissible : Code → Expr Γinput .bool)
    (observations : Sketch.Observations Γ E Effect Result) (code : Code)
    (source : Sketch.System Γ E) (input : Env Γinput)
    (allowed : Eval.evalBool input (admissible code) = true)
    (effects : List Effect) (result : Result) :
    Returns (Sketch.residualSystem (specification budget sourceEntry admissible observations)
        (project budget cells sourceEntry code source))
      (some ⟨(), (project budget cells sourceEntry code source).entry.eval input⟩) effects result ↔
    Returns (Sketch.sourceSystem (specification budget sourceEntry admissible observations) code source)
      (some ⟨(), (sourceEntry code).eval input⟩) effects result :=
  (referenceProjector budget cells sourceEntry admissible observations).first_futamura_equation
    code source input allowed effects result

/-- Observe extracted labels through their retained original edge. -/
def extractedObservations (observations : Sketch.Observations Γ E Effect Result) :
    Sketch.Observations Γ (Wruh.FreshExtraction.TaggedSuccessor E Γ) Effect Result where
  effect := fun s successor t => observations.effect s successor.edge t
  result := observations.result

/-- End-to-end composition with WRUH's independent reference semantics. The
only extraction hypothesis is the existing `SymexLaws`; specialization is the
implemented and proved projector above. -/
theorem projected_wruh_bisimilar (budget : Nat) (cells : Tracked Γ)
    (sourceEntry : Code → StateUpdate Γinput Γ)
    (admissible : Code → Expr Γinput .bool)
    (observations : Sketch.Observations Γ E Effect Result)
    (A : Wruh.FreshExtraction.Adapter Binary E Γ)
    (laws : Wruh.FreshExtraction.SymexLaws A) (binary : Binary)
    (code : Code) (input : Env Γinput)
    (allowed : Eval.evalBool input (admissible code) = true) :
    Bisimilar
      (Sketch.residualSystem
        (specification budget sourceEntry admissible (extractedObservations observations))
        (project budget cells sourceEntry code (Wruh.FreshExtraction.extract A binary)))
      (viewed (A.reference binary).toLTS (Sketch.interfaceOf (sourceEntry code) observations))
      (some ⟨(), (project budget cells sourceEntry code
        (Wruh.FreshExtraction.extract A binary)).entry.eval input⟩)
      (some ⟨(), (sourceEntry code).eval input⟩) :=
  ((referenceProjector budget cells sourceEntry admissible (extractedObservations observations)).entry_bisimilar code (Wruh.FreshExtraction.extract A binary) input allowed).symm.trans
      (Sketch.extraction_view_bisimilar A laws binary
        (Sketch.interfaceOf (sourceEntry code) observations) _)

end Futamura.Reference
