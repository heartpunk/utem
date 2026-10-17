import Ayxg.QfAbv.Update

namespace Futamura.Reference
open Ayxg.QfAbv

deriving instance DecidableEq for Var

inductive Literal : TermSort → Type where
  | bool (value : Bool) : Literal .bool
  | bv {w : Nat} (value : BitVec w) : Literal (.bv w)
  deriving DecidableEq

def Literal.expr {Γ : Ctx} : Literal s → Expr Γ s
  | .bool b => .boolLit b
  | .bv v => .bvLit _ v.toNat

def Literal.value : Literal s → Denote s
  | .bool b => b
  | .bv v => v

variable [FPInterpretation]

@[simp] theorem Literal.eval_expr (v : Literal s) (ρ : Env Γ) :
    Eval.eval ρ v.expr = v.value := by
  cases v <;> simp [Literal.expr, Literal.value, Eval.eval]

def literal? : Expr Γ s → Option (Literal s)
  | .boolLit b => some (.bool b)
  | .bvLit w v => some (.bv (BitVec.ofNat w v))
  | _ => none

theorem literal?_sound (e : Expr Γ s) (v : Literal s)
    (h : literal? e = some v) (ρ : Env Γ) : Eval.eval ρ e = v.value := by
  cases e <;> simp only [literal?] at h
  all_goals try contradiction
  all_goals cases h; rfl

inductive Cell (Γ : Ctx) : TermSort → Type where
  | variable : Var Γ s → Cell Γ s
  | memory {iw vw : Nat} : Var Γ (.array iw vw) → BitVec iw → Cell Γ (.bv vw)
  deriving DecidableEq

def Cell.expr : Cell Γ s → Expr Γ s
  | .variable x => .var x
  | .memory x address => .select _ _ (.var x) (.bvLit _ address.toNat)

structure Fact (Γ : Ctx) where
  sort : TermSort
  cell : Cell Γ sort
  value : Literal sort
  deriving DecidableEq

abbrev Facts (Γ : Ctx) := List (Fact Γ)

def Holds (facts : Facts Γ) (ρ : Env Γ) : Prop :=
  ∀ f ∈ facts, Eval.eval ρ f.cell.expr = f.value.value

@[simp] theorem holds_nil (ρ : Env Γ) : Holds [] ρ := by
  intro f h
  cases h

def lookup (cell : Cell Γ s) : Facts Γ → Option (Literal s)
  | [] => none
  | f :: rest =>
    if hs : f.sort = s then
      if (hs ▸ f.cell) = cell then some (hs ▸ f.value) else lookup cell rest
    else lookup cell rest

theorem lookup_sound (facts : Facts Γ) (cell : Cell Γ s)
    (v : Literal s) (ρ : Env Γ) (h : Holds facts ρ)
    (found : lookup cell facts = some v) : Eval.eval ρ cell.expr = v.value := by
  induction facts with
  | nil => simp [lookup] at found
  | cons f rest ih =>
    have head := h f (by simp)
    have tail : Holds rest ρ := by
      intro g hg
      exact h g (by simp [hg])
    simp only [lookup] at found
    split at found
    next hs =>
      cases f with
      | mk sort stored value =>
        dsimp at hs
        subst sort
        dsimp at found
        split at found
        next hc =>
          subst stored
          cases found
          exact head
        next => exact ih tail found
    next => exact ih tail found

def Cell.weaken (d : Decl) : Cell Γ s → Cell (d :: Γ) s
  | .variable x => .variable (.there x)
  | .memory x address => .memory (.there x) address

@[simp] theorem Cell.eval_weaken (d : Decl) (cell : Cell Γ s)
    (ρ : Env Γ) (value : Denote d.sort) :
    Eval.eval (Env.cons value ρ) (cell.weaken d).expr = Eval.eval ρ cell.expr := by
  cases cell <;> rfl

def Fact.weaken (d : Decl) (f : Fact Γ) : Fact (d :: Γ) :=
  ⟨f.sort, f.cell.weaken d, f.value⟩

def weakenFacts (d : Decl) (facts : Facts Γ) : Facts (d :: Γ) :=
  facts.map (Fact.weaken d)

theorem weakenFacts_sound (d : Decl) (facts : Facts Γ) (ρ : Env Γ)
    (value : Denote d.sort) (h : Holds facts ρ) :
    Holds (weakenFacts d facts) (Env.cons value ρ) := by
  intro f hf
  obtain ⟨old, member, rfl⟩ := List.mem_map.mp hf
  simpa [Fact.weaken] using h old member

theorem holds_cons (f : Fact Γ) (facts : Facts Γ) (ρ : Env Γ)
    (head : Eval.eval ρ f.cell.expr = f.value.value)
    (tail : Holds facts ρ) : Holds (f :: facts) ρ := by
  intro g member
  rcases List.mem_cons.mp member with rfl | member
  · exact head
  · exact tail g member

end Futamura.Reference
