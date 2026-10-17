import Wruh.FreshExtraction
import FutamuraCore

/-!
First Futamura projector: revised from the Obsidian UTEM contract's shape.

AYXG PR #1: 5106df06d92620da810c325b8779ce97a14f7f0e
WRUH PR #2: 16d77877512d97fad0622a7a6ac401cf8b2dd538

Retained: typed source/residual entry maps; entry, forward, backward obligations.
Applied corrections: current labeled STS API; the state-correspondence witness
is supplied by the correctness proof, not demanded from the caller; eliminated
silent steps are allowed while divergence is preserved and reflected.

Static binding: the returned residual includes its typed entry map. Executing
it takes only the remaining input. No residual-side function takes `Code`.
Observation decoders are fixed for the source and target representations and
do not depend on code, a projector-chosen layout, or the source STS.

This file specifies the contract. `Reference/Projector.lean` now implements and
proves a concrete inhabitant for its explicit tag-erasure representation.
`projected_reference_bisimilar` remains the generic conditional composition
theorem; the reference module instantiates its specialization leg.

Validation status and exact build evidence are recorded in README.md.
-/
namespace Futamura.Sketch

open _root_.Ayxg.QfAbv _root_.Ayxg.LTS.QfAbv

/-- Control remains inside the complete symbolic environment, as in WRUH. -/
abbrev System (Γ : Ctx) (Edge : Type) :=
  SymbolicTransitionSystem Unit Γ Edge

/-- Fixed interpretation of observable effects and results, without code or
runtime initialization. These are part of the chosen representation's semantics. -/
structure Observations (Γ : Ctx) (Edge Effect Result : Type) where
  effect : Config Unit Γ → Edge → Config Unit Γ → Option Effect
  result : Config Unit Γ → Option Result

/-- The code representation and its loading operation are supplied together.
Both the loader and admissibility guard are finite typed QF_ABV syntax.
`Code` may itself be the chosen source-indexed code-object type. -/
structure ProjectionSpec (Code SourceEdge ResidualEdge : Type)
    (Γsrc Γres Γinput : Ctx) where
  Effect : Type
  Result : Type
  sourceEntry : Code → StateUpdate Γinput Γsrc
  admissible : Code → Expr Γinput .bool
  sourceObservations : Observations Γsrc SourceEdge Effect Result
  residualObservations : Observations Γres ResidualEdge Effect Result

/-- A closed residual AYXG program: transition system plus typed initialization.
Fixed code/data must be bound in these returned values, not supplied to execution. -/
structure Residual (Γres Γinput : Ctx) (ResidualEdge : Type) where
  system : System Γres ResidualEdge
  entry : StateUpdate Γinput Γres

variable [FPInterpretation]
variable {Code SourceEdge ResidualEdge : Type} {Γsrc Γres Γinput : Ctx}

def interfaceOf {Γ Γin : Ctx} {E Effect Result : Type}
    (entry : StateUpdate Γin Γ) (observations : Observations Γ E Effect Result) :
    Interface (Config Unit Γ) E (Env Γin) Effect Result where
  entry := fun input => ⟨(), entry.eval input⟩
  observe := observations.effect
  result := observations.result

def sourceSystem (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput)
    (code : Code) (source : System Γsrc SourceEdge) :=
  viewed source.toLTS (interfaceOf (spec.sourceEntry code) spec.sourceObservations)

def residualSystem (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput)
    (residual : Residual Γres Γinput ResidualEdge) :=
  viewed residual.system.toLTS (interfaceOf residual.entry spec.residualObservations)

/-- These are the actual specialization obligations. `R` is an existential
witness chosen by the implementation's proof, not a semantic assumption imposed
on a caller. `Option` adds the explicit terminal sink from `FutamuraCore`.
Observable labels already include effects and returned results. -/
structure ProjectionCorrect
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput)
    (code : Code) (source : System Γsrc SourceEdge)
    (residual : Residual Γres Γinput ResidualEdge)
    (R : Option (Config Unit Γsrc) → Option (Config Unit Γres) → Prop) : Prop where
  entry : ∀ input, Eval.evalBool input (spec.admissible code) = true →
    R (some ⟨(), (spec.sourceEntry code).eval input⟩)
      (some ⟨(), residual.entry.eval input⟩)
  forward : ∀ {s r}, R s r → ∀ {a s'},
    (sourceSystem spec code source).Tr s a s' →
    ∃ r', WeakStep (residualSystem spec residual) r a r' ∧ R s' r'
  backward : ∀ {s r}, R s r → ∀ {a r'},
    (residualSystem spec residual).Tr r a r' →
    ∃ s', WeakStep (sourceSystem spec code source) s a s' ∧ R s' r'
  divergence : ∀ {s r}, R s r →
    (Diverges (sourceSystem spec code source) s ↔
      Diverges (residualSystem spec residual) r)

/-- Code and source STS in; a closed residual STS with its entry syntax out. -/
abbrev Project (Code SourceEdge ResidualEdge : Type) (Γsrc Γres Γinput : Ctx) :=
  Code → System Γsrc SourceEdge → Residual Γres Γinput ResidualEdge

/-- The open theorem/construction goal, not an assumed correct projector.
In particular, all entry/forward/backward/divergence obligations remain visible
in `ProjectionCorrect`; no claim is made that arbitrary specifications are realizable. -/
def FirstFutamuraProblem
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput) : Prop :=
  ∃ project : Project Code SourceEdge ResidualEdge Γsrc Γres Γinput,
    ∀ code source, ∃ R, ProjectionCorrect spec code source (project code source) R

/-- A solution of that problem, packaged for stating the conditional WRUH theorem. -/
structure FirstProjector
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput) where
  specialize : Project Code SourceEdge ResidualEdge Γsrc Γres Γinput
  correct : ∀ code source, ∃ R,
    ProjectionCorrect spec code source (specialize code source) R

theorem FirstProjector.solves
    {spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput}
    (p : FirstProjector spec) : FirstFutamuraProblem spec :=
  ⟨p.specialize, p.correct⟩

/-- Assemble the explicit obligations into the canonical AYXG-based relation. -/
theorem FirstProjector.entry_bisimilar
    {spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput}
    (p : FirstProjector spec) (code : Code) (source : System Γsrc SourceEdge)
    (input : Env Γinput) (allowed : Eval.evalBool input (spec.admissible code) = true) :
    Bisimilar (sourceSystem spec code source)
      (residualSystem spec (p.specialize code source))
      (some ⟨(), (spec.sourceEntry code).eval input⟩)
      (some ⟨(), (p.specialize code source).entry.eval input⟩) := by
  obtain ⟨R, h⟩ := p.correct code source
  exact ⟨R, ⟨h.forward, h.backward, h.divergence⟩, h.entry input allowed⟩

/-- Futamura's result equation, strengthened to include observable effects. -/
theorem FirstProjector.first_futamura_equation
    {spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput}
    (p : FirstProjector spec) (code : Code) (source : System Γsrc SourceEdge)
    (input : Env Γinput) (allowed : Eval.evalBool input (spec.admissible code) = true)
    (effects : List spec.Effect) (result : spec.Result) :
    Returns (residualSystem spec (p.specialize code source))
      (some ⟨(), (p.specialize code source).entry.eval input⟩) effects result ↔
    Returns (sourceSystem spec code source)
      (some ⟨(), (spec.sourceEntry code).eval input⟩) effects result :=
  (p.entry_bisimilar code source input allowed).symm.results effects result

/-! WRUH composition: interpret each extracted label through `.edge`, retaining
the same states, typed initialization, and observations. -/
open Wruh.FreshExtraction

def extractionInterface {Γ : Ctx} {E Input Effect Result : Type}
    (view : Interface (Config Unit Γ) E Input Effect Result) :
    Interface (Config Unit Γ) (TaggedSuccessor E Γ) Input Effect Result where
  entry := view.entry
  observe := fun s successor t => view.observe s successor.edge t
  result := view.result

def extractionSpec (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput) :
    ProjectionSpec Code (TaggedSuccessor SourceEdge Γsrc) ResidualEdge Γsrc Γres Γinput where
  Effect := spec.Effect
  Result := spec.Result
  sourceEntry := spec.sourceEntry
  admissible := spec.admissible
  sourceObservations := {
    effect := fun s successor t => spec.sourceObservations.effect s successor.edge t
    result := spec.sourceObservations.result
  }
  residualObservations := spec.residualObservations

theorem extraction_view_step_iff {Binary E Input Effect Result : Type} {Γ : Ctx}
    (A : Adapter Binary E Γ) (laws : SymexLaws A) (binary : Binary)
    (view : Interface (Config Unit Γ) E Input Effect Result) (s a t) :
    (viewed (extract A binary).toLTS (extractionInterface view)).Tr s a t ↔
      (viewed (A.reference binary).toLTS view).Tr s a t := by
  constructor
  · intro h
    cases h with
    | step transition =>
      exact .step (extract_transition_sound A laws binary _ _ _ transition)
    | returned result => exact .returned result
  · intro h
    cases h with
    | step transition =>
      obtain ⟨successor, extracted, sameEdge⟩ :=
        extract_transition_complete A laws binary _ _ _ transition
      simpa [extractionInterface, viewed, sameEdge] using
        (ViewedStep.step (view := extractionInterface view) extracted)
    | returned result => exact .returned result

theorem extraction_view_bisimilar {Binary E Input Effect Result : Type} {Γ : Ctx}
    (A : Adapter Binary E Γ) (laws : SymexLaws A) (binary : Binary)
    (view : Interface (Config Unit Γ) E Input Effect Result) (s) :
    Bisimilar (viewed (extract A binary).toLTS (extractionInterface view))
      (viewed (A.reference binary).toLTS view) s s :=
  Bisimilar.of_transition_iff (extraction_view_step_iff A laws binary view) s

/-- Conditional end-to-end theorem. The new specialization proof is exactly
`p.correct`; the extraction assumption is exactly the existing `SymexLaws A`.
The right side uses the adapter's independent reference semantics. -/
theorem projected_reference_bisimilar {Binary : Type}
    (A : Adapter Binary SourceEdge Γsrc) (laws : SymexLaws A) (binary : Binary)
    (spec : ProjectionSpec Code SourceEdge ResidualEdge Γsrc Γres Γinput)
    (p : FirstProjector (extractionSpec spec)) (code : Code) (input : Env Γinput)
    (allowed : Eval.evalBool input (spec.admissible code) = true) :
    Bisimilar
      (residualSystem (extractionSpec spec) (p.specialize code (extract A binary)))
      (viewed (A.reference binary).toLTS
        (interfaceOf (spec.sourceEntry code) spec.sourceObservations))
      (some ⟨(), (p.specialize code (extract A binary)).entry.eval input⟩)
      (some ⟨(), (spec.sourceEntry code).eval input⟩) :=
  (p.entry_bisimilar code (extract A binary) input allowed).symm.trans
    (extraction_view_bisimilar A laws binary
      (interfaceOf (spec.sourceEntry code) spec.sourceObservations) _)

end Futamura.Sketch
