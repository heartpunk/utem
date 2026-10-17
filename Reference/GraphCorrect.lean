import Reference.Graph

namespace Futamura.Reference
open Ayxg.QfAbv Ayxg.LTS.QfAbv
variable [FPInterpretation]

/-- Every source step has a residual step carrying the same original edge. -/
theorem graph_forward (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) {s t : Config Unit Γ}
    {r : Config Unit (ResidualCtx budget Γ)} (related : StateRel table s r)
    {edge : E} (step : source.toLTS.Tr s edge t) :
    ∃ residual r', (compiledSystem cells table source).toLTS.Tr r residual r' ∧
      residual.origin = edge ∧ StateRel table t r' := by
  rcases related with ⟨current, he, hf⟩
  rcases (source_step_iff source s t edge).mp step with ⟨member, enabled, updated⟩
  let label := source.edgeSemantics.symbolicLabel edge
  let target := nextContext cells table current label
  let residual := makeEdge cells table source current edge
  let r' : Config Unit (ResidualCtx budget Γ) := ⟨(), tagged target t.env⟩
  refine ⟨residual, r', ?_, rfl, ?_⟩
  · apply (source_step_iff (compiledSystem cells table source) r r' residual).mpr
    refine ⟨?_, ?_, ?_⟩
    · exact (mem_emitEdges_iff cells table source residual).mpr
        ⟨current, edge, member, keepEdge_of_enabled _ _ _ hf enabled, rfl⟩
    · change Eval.eval r.env (compileLabel (table.get current) current target label).guard = true
      rw [he]
      apply (compileLabel_guard _ _ _ _ _ _).mpr
      refine ⟨rfl, ?_⟩
      rw [specialize_correct _ _ _ hf]
      exact enabled
    · change (compileLabel (table.get current) current target label).update.eval r.env =
        tagged target t.env
      rw [he, compileLabel_update _ _ _ _ _ _ hf, updated]
  · refine ⟨target, rfl, ?_⟩
    rw [← updated]
    exact nextContext_holds cells table current label s.env hf

/-- Every residual step is a source step; context facts remain valid afterward. -/
theorem graph_backward (cells : Tracked Γ) (table : ContextTable Γ budget)
    (source : Sketch.System Γ E) {s : Config Unit Γ}
    {r r' : Config Unit (ResidualCtx budget Γ)} (related : StateRel table s r)
    {residual : CompiledEdge budget Γ E}
    (step : (compiledSystem cells table source).toLTS.Tr r residual r') :
    ∃ t, source.toLTS.Tr s residual.origin t ∧ StateRel table t r' := by
  rcases related with ⟨current, he, hf⟩
  rcases (source_step_iff (compiledSystem cells table source) r r' residual).mp step with
    ⟨member, enabled, updated⟩
  obtain ⟨chosen, edge, sourceMember, _, rfl⟩ :=
    (mem_emitEdges_iff cells table source residual).mp member
  let label := source.edgeSemantics.symbolicLabel edge
  change Eval.eval r.env
    (compileLabel (table.get chosen) chosen (nextContext cells table chosen label) label).guard = true at enabled
  rw [he] at enabled
  rcases (compileLabel_guard _ _ _ _ _ _).mp enabled with ⟨same, enabled⟩
  subst chosen
  rw [specialize_correct _ _ _ hf] at enabled
  let t : Config Unit Γ := ⟨(), label.update.eval s.env⟩
  refine ⟨t, ?_, ?_⟩
  · exact (source_step_iff source s t edge).mpr ⟨sourceMember, enabled, rfl⟩
  · refine ⟨nextContext cells table current label, ?_, nextContext_holds cells table current label s.env hf⟩
    change (compileLabel (table.get current) current (nextContext cells table current label) label).update.eval r.env = r'.env at updated
    rw [he, compileLabel_update _ _ _ _ _ _ hf] at updated
    exact updated.symm

end Futamura.Reference
