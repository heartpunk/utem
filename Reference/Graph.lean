import Reference.Tagged

namespace Futamura.Reference
open Ayxg.QfAbv Ayxg.LTS.QfAbv
variable [FPInterpretation]

/-- Executable residual edge. Its complete QF_ABV payload is materialized during
projection; runtime edge interpretation does not call the specializer. -/
structure CompiledEdge (budget : Nat) (Γ : Ctx) (E : Type) where
  origin : E
  sourceContext : Index budget
  targetContext : Index budget
  label : SymbolicLabel (ResidualCtx budget Γ)

def compileLabel (facts : Facts Γ) (current target : Index budget) (label : SymbolicLabel Γ) :
    SymbolicLabel (ResidualCtx budget Γ) where
  guard := .boolAnd (tagGuard current)
    ((specialize facts label.guard).val.weaken (tagDecl budget))
  update := taggedUpdate target (specializeUpdate facts label.update).val

def nextContext (cells : Tracked Γ) (table : ContextTable Γ budget)
    (current : Index budget) (label : SymbolicLabel Γ) : Index budget :=
  (chooseTarget table (advance cells (table.get current) label.update)).val

def makeEdge (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) (current : Index budget) (edge : E) : CompiledEdge budget Γ E :=
  let label := source.edgeSemantics.symbolicLabel edge
  let target := nextContext cells table current label
  ⟨edge, current, target, compileLabel (table.get current) current target label⟩

def keepEdge (facts : Facts Γ) (label : SymbolicLabel Γ) : Bool :=
  decide (literal? (specialize facts label.guard).val ≠ some (.bool false))

theorem keepEdge_of_enabled (facts : Facts Γ) (label : SymbolicLabel Γ) (ρ : Env Γ)
    (h : Holds facts ρ) (enabled : Eval.eval ρ label.guard = true) :
    keepEdge facts label = true := by
  simp only [keepEdge, decide_eq_true_eq]
  intro falseLiteral
  have hf := literal?_sound _ (.bool false) falseLiteral ρ
  rw [specialize_correct facts label.guard ρ h, enabled] at hf
  cases hf

/-- Emission is finite and retains the source edge as provenance.
PERFORMANCE: candidates and rewrites may be recomputed across contexts and
fields. Pointer-DAG traversal cost is documented at `specialize`; optimizing
that cost is explicitly deferred. -/
def emitEdges (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) : List (CompiledEdge budget Γ E) :=
  (List.finRange (budget + 2)).flatMap fun current =>
    ((source.transAt ()).filter fun edge =>
      keepEdge (table.get current) (source.edgeSemantics.symbolicLabel edge)).map
        (makeEdge cells table source current)

def compiledSemantics : SymbolicEdgeSemantics Unit (ResidualCtx budget Γ) (CompiledEdge budget Γ E) where
  source := fun _ => ()
  symbolicLabel := CompiledEdge.label
  nextControl := fun _ _ => ()

def compiledSystem (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) : Sketch.System (ResidualCtx budget Γ) (CompiledEdge budget Γ E) :=
  let edges := emitEdges cells table source
  { edgeSemantics := compiledSemantics, transAt := fun _ => edges }

theorem mem_emitEdges_iff (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) (residual : CompiledEdge budget Γ E) :
    residual ∈ emitEdges cells table source ↔
      ∃ current edge, edge ∈ source.transAt () ∧
        keepEdge (table.get current) (source.edgeSemantics.symbolicLabel edge) = true ∧
        makeEdge cells table source current edge = residual := by
  simp only [emitEdges, List.mem_flatMap, List.mem_map, List.mem_filter, List.mem_finRange,
    true_and]
  aesop

theorem compileLabel_guard (facts : Facts Γ) (current target actual : Index budget)
    (label : SymbolicLabel Γ) (ρ : Env Γ) :
    Eval.eval (tagged actual ρ) (compileLabel facts current target label).guard = true ↔
      actual = current ∧ Eval.eval ρ (specialize facts label.guard).val = true := by
  change (Eval.eval (tagged actual ρ) (tagGuard current) &&
    Eval.eval (tagged actual ρ) ((specialize facts label.guard).val.weaken (tagDecl budget))) = true ↔ _
  rw [Bool.and_eq_true, tagGuard_eval]
  rw [show Eval.eval (tagged actual ρ)
      ((specialize facts label.guard).val.weaken (tagDecl budget)) =
        Eval.eval ρ (specialize facts label.guard).val from Expr.eval_weaken _ _ _ _]

theorem compileLabel_update (facts : Facts Γ) (current target actual : Index budget)
    (label : SymbolicLabel Γ) (ρ : Env Γ) (h : Holds facts ρ) :
    (compileLabel facts current target label).update.eval (tagged actual ρ) =
      tagged target (label.update.eval ρ) := by
  rw [compileLabel, taggedUpdate_eval, (specializeUpdate facts label.update).property ρ h]

theorem nextContext_holds (cells : Tracked Γ) (table : ContextTable Γ budget)
    (current : Index budget) (label : SymbolicLabel Γ) (ρ : Env Γ)
    (h : Holds (table.get current) ρ) :
    Holds (table.get (nextContext cells table current label)) (label.update.eval ρ) :=
  chooseTarget_consistent table _ _ (learn_correct _ _ _ _ h)

/-- Erasing the additional context field gives the complete source configuration. -/
def eraseConfig (r : Config Unit (ResidualCtx budget Γ)) : Config Unit Γ :=
  ⟨(), eraseEnv r.env⟩

def StateRel (table : ContextTable Γ budget)
    (s : Config Unit Γ) (r : Config Unit (ResidualCtx budget Γ)) : Prop :=
  ∃ current, r.env = tagged current s.env ∧ Holds (table.get current) s.env

theorem StateRel.erase {table : ContextTable Γ budget} {s r}
    (h : StateRel table s r) : eraseConfig r = s := by
  rcases h with ⟨current, he, _⟩
  cases s with
  | mk control env =>
    cases control
    simp [eraseConfig, he]

/-- Unit-control source transitions expose exactly guard and complete update. -/
theorem source_step_iff (source : Sketch.System Γ E) (s t : Config Unit Γ) (edge : E) :
    source.toLTS.Tr s edge t ↔ edge ∈ source.transAt () ∧
      Eval.eval s.env (source.edgeSemantics.symbolicLabel edge).guard = true ∧
      (source.edgeSemantics.symbolicLabel edge).update.eval s.env = t.env := by
  cases s with
  | mk sc se =>
    cases sc
    cases t with
    | mk tc te =>
      cases tc
      simp [SymbolicTransitionSystem.toLTS, SymbolicEdgeSemantics.denotes,
        SymbolicEdgeSemantics.nextConfig, Config.mk.injEq]

end Futamura.Reference
