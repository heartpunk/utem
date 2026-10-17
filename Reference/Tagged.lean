import Reference.Contexts

namespace Futamura.Reference
open Ayxg.QfAbv Ayxg.LTS.QfAbv
variable [FPInterpretation]

abbrev tagDecl (budget : Nat) : Decl := ⟨"utem.context", .bv (budget + 2)⟩
abbrev ResidualCtx (budget : Nat) (Γ : Ctx) : Ctx := tagDecl budget :: Γ

def tagValue (i : Index budget) : BitVec (budget + 2) := BitVec.ofNat _ i.val

omit [FPInterpretation] in
theorem self_lt_two_pow (n : Nat) : n < 2 ^ n := by
  induction n with
  | zero => decide
  | succ n ih => rw [Nat.pow_succ]; omega

omit [FPInterpretation] in
@[simp] theorem tagValue_toNat (i : Index budget) : (tagValue i).toNat = i.val := by
  simp [tagValue, Nat.mod_eq_of_lt (Nat.lt_trans i.isLt (self_lt_two_pow _))]

omit [FPInterpretation] in
theorem tagValue_injective {i j : Index budget} (h : tagValue i = tagValue j) : i = j := by
  apply Fin.ext
  have h' := congrArg BitVec.toNat h
  simpa using h'

def tagged (i : Index budget) (ρ : Env Γ) : Env (ResidualCtx budget Γ) :=
  .cons (tagValue i) ρ

def eraseEnv : Env (ResidualCtx budget Γ) → Env Γ
  | .cons _ ρ => ρ

omit [FPInterpretation] in
@[simp] theorem eraseEnv_tagged (i : Index budget) (ρ : Env Γ) :
    eraseEnv (tagged i ρ) = ρ := rfl

def weakenUpdate (d : Decl) : StateUpdate Γ Δ → StateUpdate (d :: Γ) Δ
  | .nil => .nil
  | .cons rhs rest => .cons (rhs.weaken d) (weakenUpdate d rest)

@[simp] theorem weakenUpdate_eval (d : Decl) (u : StateUpdate Γ Δ)
    (value : Denote d.sort) (ρ : Env Γ) :
    (weakenUpdate d u).eval (.cons value ρ) = u.eval ρ := by
  induction u with
  | nil => rfl
  | cons rhs rest ih =>
    simp only [weakenUpdate, StateUpdate.eval, Expr.eval_weaken, ih]

def tagGuard (i : Index budget) : Expr (ResidualCtx budget Γ) .bool :=
  .eqBv (budget + 2) (.var .here) (.bvLit _ i.val)

@[simp] theorem tagGuard_eval (i j : Index budget) (ρ : Env Γ) :
    Eval.eval (tagged j ρ) (tagGuard i) = true ↔ j = i := by
  simp only [tagGuard, tagged, Eval.eval]
  change (tagValue j == tagValue i) = true ↔ j = i
  rw [beq_iff_eq]
  exact ⟨tagValue_injective, fun h => congrArg tagValue h⟩

def taggedUpdate (target : Index budget) (u : StateUpdate Γ Γ) :
    StateUpdate (ResidualCtx budget Γ) (ResidualCtx budget Γ) :=
  .cons (.bvLit _ target.val) (weakenUpdate (tagDecl budget) u)

@[simp] theorem taggedUpdate_eval (target current : Index budget)
    (u : StateUpdate Γ Γ) (ρ : Env Γ) :
    (taggedUpdate target u).eval (tagged current ρ) = tagged target (u.eval ρ) := by
  change Env.cons (d := tagDecl budget) (tagValue target)
    ((weakenUpdate (tagDecl budget) u).eval (.cons (d := tagDecl budget) (tagValue current) ρ)) =
      Env.cons (d := tagDecl budget) (tagValue target) (u.eval ρ)
  rw [weakenUpdate_eval]

def taggedEntry (budget : Nat) (entry : StateUpdate Γinput Γ) :
    StateUpdate Γinput (ResidualCtx budget Γ) :=
  .cons (.bvLit _ 1) entry

@[simp] theorem taggedEntry_eval (budget : Nat) (entry : StateUpdate Γinput Γ)
    (input : Env Γinput) :
    (taggedEntry budget entry).eval input = tagged (entryIndex budget) (entry.eval input) := rfl

end Futamura.Reference
