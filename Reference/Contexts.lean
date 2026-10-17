import Reference.Transfer
import FirstFutamura

namespace Futamura.Reference
open Ayxg.QfAbv Ayxg.LTS.QfAbv
variable [FPInterpretation]

abbrev Index (budget : Nat) := Fin (budget + 2)
def fallbackIndex (budget : Nat) : Index budget := ⟨0, by omega⟩
def entryIndex (budget : Nat) : Index budget := ⟨1, by omega⟩

/-- Slots zero and one are reserved for fallback and the specialized entry.
The remaining slots bound context discovery, independently of code or dynamic input. -/
structure ContextTable (Γ : Ctx) (budget : Nat) where
  get : Index budget → Facts Γ
  fallback : get (fallbackIndex budget) = []

/-- A deliberately simple bounded worklist: each round adds one unseen context.
Final graph emission decides all targets from the completed immutable table.
Missing successors enter the empty-facts context with their full state intact. -/
def discover (cells : Tracked Γ) (source : Sketch.System Γ E) (initial : Facts Γ) :
    Nat → List (Facts Γ) → List (Facts Γ)
  | 0, extra => extra
  | fuel + 1, extra =>
    let known := [] :: initial :: extra
    -- Discover from the entry and its successors, never from the generic fallback.
    -- Discard guards already known false so they do not consume the context budget.
    let candidates := (initial :: extra).flatMap fun facts =>
      (source.transAt ()).filterMap fun edge =>
        let label := source.edgeSemantics.symbolicLabel edge
        if literal? (specialize facts label.guard).val = some (.bool false) then none
        else some (advance cells facts label.update)
    match candidates.find? (fun facts => decide (facts ∉ known)) with
    | none => extra
    | some next => discover cells source initial fuel (extra ++ [next])

def buildContexts (budget : Nat) (cells : Tracked Γ) (source : Sketch.System Γ E)
    (entry : StateUpdate Γinput Γ) : ContextTable Γ budget :=
  let initial := seed entry cells
  let extra := discover cells source initial budget []
  { get := fun i =>
      if i.val = 0 then [] else if i.val = 1 then initial else
        (extra[i.val - 2]?).getD []
    fallback := by simp [fallbackIndex] }

theorem buildContexts_entry (budget : Nat) (cells : Tracked Γ)
    (source : Sketch.System Γ E) (entry : StateUpdate Γinput Γ) :
    (buildContexts budget cells source entry).get (entryIndex budget) = seed entry cells := by
  simp [buildContexts, entryIndex]

/-- Search returns its equality proof; no table correctness assumption is postulated. -/
def findContext (table : ContextTable Γ budget) (wanted : Facts Γ) :
    List (Index budget) → Option { i : Index budget // table.get i = wanted }
  | [] => none
  | i :: rest =>
    if h : table.get i = wanted then some ⟨i, h⟩ else findContext table wanted rest

def chooseTarget (table : ContextTable Γ budget) (wanted : Facts Γ) :
    { i : Index budget // table.get i = wanted ∨ table.get i = [] } :=
  match findContext table wanted (List.finRange (budget + 2)) with
  | some found => ⟨found.val, Or.inl found.property⟩
  | none => ⟨fallbackIndex budget, Or.inr table.fallback⟩

theorem chooseTarget_consistent (table : ContextTable Γ budget) (wanted : Facts Γ)
    (ρ : Env Γ) (h : Holds wanted ρ) : Holds (table.get (chooseTarget table wanted).val) ρ := by
  rcases (chooseTarget table wanted).property with exact | empty
  · rw [exact]; exact h
  · rw [empty]; exact holds_nil _

end Futamura.Reference
