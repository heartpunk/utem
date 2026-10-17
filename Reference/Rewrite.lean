import Reference.Facts

namespace Futamura.Reference
open Ayxg.QfAbv
variable [FPInterpretation]

/-- A constructed rewrite with its preservation proof, not a law supplied by a caller. -/
abbrev Rewrite (facts : Facts Γ) (original : Expr Γ s) :=
  { result : Expr Γ s // ∀ ρ, Holds facts ρ → Eval.eval ρ result = Eval.eval ρ original }

abbrev Reduction (original : Expr Γ s) :=
  { result : Expr Γ s // ∀ ρ, Eval.eval ρ result = Eval.eval ρ original }

def unchanged (facts : Facts Γ) (e : Expr Γ s) : Rewrite facts e :=
  ⟨e, fun _ _ => rfl⟩

def reduceUnchanged (e : Expr Γ s) : Reduction e := ⟨e, fun _ => rfl⟩

def fromReduction (facts : Facts Γ) (r : Reduction e) : Rewrite facts e :=
  ⟨r.val, fun ρ _ => r.property ρ⟩

def thenReduce (r : Rewrite facts e) (next : Reduction r.val) : Rewrite facts e :=
  ⟨next.val, fun ρ h => (next.property ρ).trans (r.property ρ h)⟩

def thenRewrite (r : Rewrite facts e) (next : Rewrite facts r.val) : Rewrite facts e :=
  ⟨next.val, fun ρ h => (next.property ρ h).trans (r.property ρ h)⟩

def rewriteCell (facts : Facts Γ) (cell : Cell Γ s) : Rewrite facts cell.expr := by
  match h : lookup cell facts with
  | none => exact unchanged facts cell.expr
  | some value =>
    refine ⟨value.expr, ?_⟩
    intro ρ holds
    exact (Literal.eval_expr value ρ).trans (lookup_sound facts cell value ρ holds h).symm

def foldBvBin (op : BvBinOp) (w : Nat) (a b : Expr Γ (.bv w)) :
    Reduction (.bvBin op w a b) := by
  match ha : literal? a, hb : literal? b with
  | some (.bv av), some (.bv bv) =>
    refine ⟨.bvLit w (Eval.BvBinOp.apply w op av bv).toNat, ?_⟩
    intro ρ
    have ea := literal?_sound a (.bv av) ha ρ
    have eb := literal?_sound b (.bv bv) hb ρ
    simp [Eval.eval, ea, eb, Literal.value]
  | _, _ => exact reduceUnchanged _

def foldBvCmp (w : Nat) (a b : Expr Γ (.bv w))
    (make : Expr Γ (.bv w) → Expr Γ (.bv w) → Expr Γ .bool)
    (operation : BitVec w → BitVec w → Bool)
    (law : ∀ (ρ : Env Γ) x y, Eval.eval ρ (make x y) = operation (Eval.eval ρ x) (Eval.eval ρ y)) :
    Reduction (make a b) := by
  match ha : literal? a, hb : literal? b with
  | some (.bv av), some (.bv bv) =>
    refine ⟨.boolLit (operation av bv), ?_⟩
    intro ρ
    have ea := literal?_sound a (.bv av) ha ρ
    have eb := literal?_sound b (.bv bv) hb ρ
    simp only [Eval.eval, law, ea, eb, Literal.value]
  | _, _ => exact reduceUnchanged _

def foldBoolNot (e : Expr Γ .bool) : Reduction (.boolNot e) := by
  match h : literal? e with
  | some (.bool b) =>
    refine ⟨.boolLit (!b), ?_⟩
    intro ρ
    have he := literal?_sound e (.bool b) h ρ
    simp only [Eval.eval, he, Literal.value]
  | none => exact reduceUnchanged _

def foldBoolAnd (a b : Expr Γ .bool) : Reduction (.boolAnd a b) := by
  match ha : literal? a with
  | some (.bool av) =>
    cases av with
    | false =>
      refine ⟨.boolLit false, ?_⟩
      intro ρ
      have ea := literal?_sound a (.bool false) ha ρ
      simp [Eval.eval, ea, Literal.value]
    | true =>
      refine ⟨b, ?_⟩
      intro ρ
      have ea := literal?_sound a (.bool true) ha ρ
      simp [Eval.eval, ea, Literal.value]
  | none =>
    match hb : literal? b with
    | some (.bool bv) =>
      cases bv with
      | false =>
        refine ⟨.boolLit false, ?_⟩
        intro ρ
        have eb := literal?_sound b (.bool false) hb ρ
        simp [Eval.eval, eb, Literal.value]
      | true =>
        refine ⟨a, ?_⟩
        intro ρ
        have eb := literal?_sound b (.bool true) hb ρ
        simp [Eval.eval, eb, Literal.value]
    | none => exact reduceUnchanged _

def foldIte (c : Expr Γ .bool) (a b : Expr Γ s) : Reduction (.ite c a b) := by
  match hc : literal? c with
  | some (.bool cv) =>
    cases cv with
    | false =>
      refine ⟨b, ?_⟩
      intro ρ
      have ec := literal?_sound c (.bool false) hc ρ
      simp [Eval.eval, ec, Literal.value]
    | true =>
      refine ⟨a, ?_⟩
      intro ρ
      have ec := literal?_sound c (.bool true) hc ρ
      simp [Eval.eval, ec, Literal.value]
  | none => exact reduceUnchanged _

def foldBvUnary (wi wo : Nat) (a : Expr Γ (.bv wi))
    (make : Expr Γ (.bv wi) → Expr Γ (.bv wo))
    (operation : BitVec wi → BitVec wo)
    (law : ∀ (ρ : Env Γ) x, Eval.eval ρ (make x) = operation (Eval.eval ρ x)) :
    Reduction (make a) := by
  match ha : literal? a with
  | some (.bv av) =>
    refine ⟨.bvLit wo (operation av).toNat, ?_⟩
    intro ρ
    have ea := literal?_sound a (.bv av) ha ρ
    simp [Eval.eval, law, ea, Literal.value]
  | none => exact reduceUnchanged _

def foldBvBinary (wa wb wo : Nat) (a : Expr Γ (.bv wa)) (b : Expr Γ (.bv wb))
    (make : Expr Γ (.bv wa) → Expr Γ (.bv wb) → Expr Γ (.bv wo))
    (operation : BitVec wa → BitVec wb → BitVec wo)
    (law : ∀ (ρ : Env Γ) x y, Eval.eval ρ (make x y) = operation (Eval.eval ρ x) (Eval.eval ρ y)) :
    Reduction (make a b) := by
  match ha : literal? a, hb : literal? b with
  | some (.bv av), some (.bv bv) =>
    refine ⟨.bvLit wo (operation av bv).toNat, ?_⟩
    intro ρ
    have ea := literal?_sound a (.bv av) ha ρ
    have eb := literal?_sound b (.bv bv) hb ρ
    simp [Eval.eval, law, ea, eb, Literal.value]
  | _, _ => exact reduceUnchanged _

def foldBoolBinary (a b : Expr Γ .bool)
    (make : Expr Γ .bool → Expr Γ .bool → Expr Γ .bool)
    (operation : Bool → Bool → Bool)
    (law : ∀ (ρ : Env Γ) x y, Eval.eval ρ (make x y) = operation (Eval.eval ρ x) (Eval.eval ρ y)) :
    Reduction (make a b) := by
  match ha : literal? a, hb : literal? b with
  | some (.bool av), some (.bool bv) =>
    refine ⟨.boolLit (operation av bv), ?_⟩
    intro ρ
    have ea := literal?_sound a (.bool av) ha ρ
    have eb := literal?_sound b (.bool bv) hb ρ
    simp [Eval.eval, law, ea, eb, Literal.value]
  | _, _ => exact reduceUnchanged _

/-- Reads only traverse syntactically known store addresses, never enumerate arrays. -/
def readAt (facts : Facts Γ) (memory : Expr Γ (.array iw vw)) (address : BitVec iw) :
    Rewrite facts (.select iw vw memory (.bvLit iw address.toNat)) := by
  match memory with
  | .var x => exact rewriteCell facts (.memory x address)
  | .constArray _ _ value => exact ⟨value, fun _ _ => rfl⟩
  | .store _ _ base key value =>
    match hk : literal? key with
    | none => exact unchanged facts _
    | some (.bv storedAddress) =>
      if same : address = storedAddress then
        refine ⟨value, ?_⟩
        intro ρ h
        have ek := literal?_sound key (.bv storedAddress) hk ρ
        simp [Eval.eval, Eval.memLoad, Eval.memStore, ek, Literal.value, same]
      else
        let recursive := readAt facts base address
        refine ⟨recursive.val, ?_⟩
        intro ρ h
        have ek := literal?_sound key (.bv storedAddress) hk ρ
        rw [recursive.property ρ h]
        simp [Eval.eval, Eval.memLoad, Eval.memStore, ek, Literal.value, same]
  | _ => exact unchanged facts _
termination_by sizeOf memory
decreasing_by
  simp_wf
  omega

def rewriteSelect (facts : Facts Γ) (memory : Expr Γ (.array iw vw))
    (key : Expr Γ (.bv iw)) : Rewrite facts (.select iw vw memory key) := by
  match hk : literal? key with
  | none => exact unchanged facts _
  | some (.bv address) =>
    let recursive := readAt facts memory address
    refine ⟨recursive.val, ?_⟩
    intro ρ h
    have ek := literal?_sound key (.bv address) hk ρ
    rw [recursive.property ρ h]
    simp [Eval.eval, ek, Literal.value]

end Futamura.Reference
