import Reference.Rewrite

namespace Futamura.Reference
open Ayxg.QfAbv
variable [FPInterpretation]

def mapOne {Γ : Ctx} {facts : Facts Γ} {sa so : TermSort} {a : Expr Γ sa}
    (a' : Rewrite facts a)
    (make : Expr Γ sa → Expr Γ so)
    (op : Denote sa → Denote so)
    (law : ∀ (ρ : Env Γ) x, Eval.eval ρ (make x) = op (Eval.eval ρ x)) :
    Rewrite facts (make a) :=
  ⟨make a'.val, by intro ρ h; simp only [law, a'.property ρ h]⟩

def mapTwo {Γ : Ctx} {facts : Facts Γ} {sa sb so : TermSort} {a : Expr Γ sa} {b : Expr Γ sb}
    (a' : Rewrite facts a) (b' : Rewrite facts b)
    (make : Expr Γ sa → Expr Γ sb → Expr Γ so)
    (op : Denote sa → Denote sb → Denote so)
    (law : ∀ (ρ : Env Γ) x y, Eval.eval ρ (make x y) = op (Eval.eval ρ x) (Eval.eval ρ y)) :
    Rewrite facts (make a b) :=
  ⟨make a'.val b'.val, by intro ρ h; simp only [law, a'.property ρ h, b'.property ρ h]⟩

def mapThree {Γ : Ctx} {facts : Facts Γ} {sa sb sc so : TermSort} {a : Expr Γ sa} {b : Expr Γ sb} {c : Expr Γ sc}
    (a' : Rewrite facts a) (b' : Rewrite facts b) (c' : Rewrite facts c)
    (make : Expr Γ sa → Expr Γ sb → Expr Γ sc → Expr Γ so)
    (op : Denote sa → Denote sb → Denote sc → Denote so)
    (law : ∀ (ρ : Env Γ) x y z, Eval.eval ρ (make x y z) =
      op (Eval.eval ρ x) (Eval.eval ρ y) (Eval.eval ρ z)) :
    Rewrite facts (make a b c) :=
  ⟨make a'.val b'.val c'.val, by
    intro ρ h
    simp only [law, a'.property ρ h, b'.property ρ h, c'.property ρ h]⟩

def mapFour {Γ : Ctx} {facts : Facts Γ} {sa sb sc sd so : TermSort} {a : Expr Γ sa} {b : Expr Γ sb} {c : Expr Γ sc} {d : Expr Γ sd}
    (a' : Rewrite facts a) (b' : Rewrite facts b)
    (c' : Rewrite facts c) (d' : Rewrite facts d)
    (make : Expr Γ sa → Expr Γ sb → Expr Γ sc → Expr Γ sd → Expr Γ so)
    (op : Denote sa → Denote sb → Denote sc → Denote sd → Denote so)
    (law : ∀ (ρ : Env Γ) w x y z, Eval.eval ρ (make w x y z) =
      op (Eval.eval ρ w) (Eval.eval ρ x) (Eval.eval ρ y) (Eval.eval ρ z)) :
    Rewrite facts (make a b c d) :=
  ⟨make a'.val b'.val c'.val d'.val, by
    intro ρ h
    simp only [law, a'.property ρ h, b'.property ρ h, c'.property ρ h, d'.property ρ h]⟩

structure BindingRewrite (facts : Facts Γ) (bs : Bindings Γ Δ) where
  result : Bindings Γ Δ
  known : Facts Δ
  eval_eq : ∀ ρ, Holds facts ρ → Eval.evalBindings ρ result = Eval.evalBindings ρ bs
  holds : ∀ ρ, Holds facts ρ → Holds known (Eval.evalBindings ρ result)

def nilBindings (facts : Facts Γ) : BindingRewrite facts .nil :=
  ⟨.nil, facts, fun _ _ => rfl, fun _ h => h⟩

/-- Sibling RHSs retain the old environment. Only the body sees new literal facts.
Precision limitation: array aliases are not tracked. A binding `m' := m` does not
transport facts about fixed addresses of `m` to `m'`; reads through that alias
remain residual. This loses specialization opportunities, not state information. -/
def consBindings (name : String) (sort : TermSort)
    {rhs : Expr Γ sort} {rest : Bindings Γ Δ}
    (rhs' : Rewrite facts rhs) (rest' : BindingRewrite facts rest) :
    BindingRewrite facts (.cons name sort rhs rest) := by
  let decl : Decl := ⟨name, sort⟩
  match hlit : literal? rhs'.val with
  | none =>
    refine ⟨.cons name sort rhs'.val rest'.result, weakenFacts decl rest'.known, ?_, ?_⟩
    · intro ρ h
      simp only [Eval.evalBindings, rhs'.property ρ h, rest'.eval_eq ρ h]
    · intro ρ h
      exact weakenFacts_sound decl rest'.known _ _ (rest'.holds ρ h)
  | some v =>
    refine ⟨.cons name sort rhs'.val rest'.result,
      ⟨sort, .variable .here, v⟩ :: weakenFacts decl rest'.known, ?_, ?_⟩
    · intro ρ h
      simp only [Eval.evalBindings, rhs'.property ρ h, rest'.eval_eq ρ h]
    · intro ρ h
      apply holds_cons
      · exact literal?_sound rhs'.val v hlit ρ
      · exact weakenFacts_sound decl rest'.known _ _ (rest'.holds ρ h)

/-- Preserve sharing; collapse only a body that has become a literal. -/
def rewriteLet {bs : Bindings Γ Δ} {body : Expr Δ s}
    (bs' : BindingRewrite facts bs) (body' : Rewrite bs'.known body) :
    Rewrite facts (.letPar bs body) := by
  let joined : Rewrite facts (.letPar bs body) :=
    ⟨.letPar bs'.result body'.val, by
      intro ρ h
      dsimp only [Eval.eval]
      rw [body'.property _ (bs'.holds ρ h), bs'.eval_eq ρ h]⟩
  match hlit : literal? body'.val with
  | none => exact joined
  | some value =>
    refine ⟨value.expr, ?_⟩
    intro ρ h
    rw [Literal.eval_expr]
    exact (literal?_sound body'.val value hlit (Eval.evalBindings ρ bs'.result)).symm.trans
      (joined.property ρ h)

end Futamura.Reference
