import Reference.Specialize

namespace Futamura.Reference
open Ayxg.QfAbv
variable [FPInterpretation]

/-- Simultaneous RHS rewriting; its proof is constructed by recursion. -/
def specializeUpdate (facts : Facts Γ) (u : StateUpdate Γ Δ) :
    { result : StateUpdate Γ Δ // ∀ ρ, Holds facts ρ → result.eval ρ = u.eval ρ } :=
  match u with
  | .nil => ⟨.nil, fun _ _ => rfl⟩
  | .cons rhs rest =>
    let rhs' := specialize facts rhs
    let rest' := specializeUpdate facts rest
    ⟨.cons rhs'.val rest'.val, by
      intro ρ h
      simp only [StateUpdate.eval, rhs'.property ρ h, rest'.property ρ h]⟩

abbrev Tracked (Γ : Ctx) := List (Σ s, Cell Γ s)

/-- Substitute the complete simultaneous update before discovering output facts.
PERFORMANCE TODO (accepted for the reference implementation): `Expr.subst` is
structural and may revisit pointer-shared inputs or expose repeated RHSs. The
following specialization also has the documented DAG traversal cost. These
passes need shared traversal before a bound in distinct DAG nodes is claimed. -/
def afterCell (facts : Facts Γ) (u : StateUpdate Γ Δ) (cell : Cell Δ s) : Expr Γ s :=
  (specialize facts (Expr.subst u.toSubst cell.expr)).val

theorem afterCell_correct (facts : Facts Γ) (u : StateUpdate Γ Δ) (cell : Cell Δ s)
    (ρ : Env Γ) (h : Holds facts ρ) :
    Eval.eval ρ (afterCell facts u cell) = Eval.eval (u.eval ρ) cell.expr := by
  rw [afterCell, specialize_correct facts _ ρ h, Expr.eval_subst,
    StateUpdate.eval_eq_subst_eval]

/-- Known values are retained only when certified reduction produces a literal.
Unknown-address writes therefore lose affected memory facts conservatively. -/
def learn (facts : Facts Γ) (u : StateUpdate Γ Δ) : Tracked Δ → Facts Δ
  | [] => []
  | ⟨s, cell⟩ :: rest =>
    match literal? (afterCell facts u cell) with
    | none => learn facts u rest
    | some value => ⟨s, cell, value⟩ :: learn facts u rest

theorem learn_correct (facts : Facts Γ) (u : StateUpdate Γ Δ) (cells : Tracked Δ)
    (ρ : Env Γ) (h : Holds facts ρ) : Holds (learn facts u cells) (u.eval ρ) := by
  induction cells with
  | nil => exact holds_nil _
  | cons cell rest ih =>
    rcases cell with ⟨s, cell⟩
    dsimp only [learn]
    split
    · exact ih
    · rename_i value found
      apply holds_cons
      · exact (afterCell_correct facts u cell ρ h).symm.trans
          (literal?_sound _ value found ρ)
      · exact ih

/-- Entry is ordinary typed syntax with the static code already bound into it. -/
def seed (entry : StateUpdate Γinput Γ) (cells : Tracked Γ) : Facts Γ :=
  learn [] entry cells

theorem seed_correct (entry : StateUpdate Γinput Γ) (cells : Tracked Γ)
    (input : Env Γinput) : Holds (seed entry cells) (entry.eval input) :=
  learn_correct [] entry cells input (holds_nil input)

def advance (cells : Tracked Γ) (facts : Facts Γ) (u : StateUpdate Γ Γ) : Facts Γ :=
  learn facts u cells

/-- Generic calibration theorem: both the complete update and its next facts
are correct for every satisfying old environment, including mutable code memory. -/
theorem specializeUpdate_correct (cells : Tracked Γ) (facts : Facts Γ)
    (u : StateUpdate Γ Γ) (ρ : Env Γ) (h : Holds facts ρ) :
    (specializeUpdate facts u).val.eval ρ = u.eval ρ ∧
      Holds (advance cells facts u) (u.eval ρ) :=
  ⟨(specializeUpdate facts u).property ρ h, learn_correct facts u cells ρ h⟩

end Futamura.Reference
