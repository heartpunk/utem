import Reference.Binders

namespace Futamura.Reference
open Ayxg.QfAbv
variable [FPInterpretation]

mutual

/-- Certified partial evaluation under known scalar and fixed-address memory facts.

PERFORMANCE TODO (explicitly deferred by the user, 2026-10-17): this structural
traversal revisits pointer-shared Expr subtrees. The supported JSON DAG
  e[0] = var x; e[n+1] = bvBin add w e[n] e[n]
has n+1 distinct nodes but incurs exponential traversal here. Preserving explicit
let bindings prevents RHS substitution blowup, but does not solve pointer-DAG
revisitation. Add context/fact-sensitive memoization before claiming a bound in
DAG-node count. Small inputs are acceptable for this reference implementation;
the semantic theorem remains universally quantified. AYXG 5106df06d92620da810c325b8779ce97a14f7f0e,
Ayxg/QfAbv/JsonCodec.lean, parseDagAt is the relevant shared-input path. -/
def specialize {Γ : Ctx} {s : TermSort} (facts : Facts Γ) (e : Expr Γ s) : Rewrite facts e :=
  match e with
  | .var x => rewriteCell facts (.variable x)
  | .boolLit b => unchanged facts (.boolLit b)
  | .bvLit w n => unchanged facts (.bvLit w n)
  | .rmLit r => unchanged facts (.rmLit r)
  | .fpFromBits f a =>
    let a' := specialize facts a
    mapOne a' (.fpFromBits f) (FPValue.ofBits f) (fun _ _ => rfl)
  | .fpToBits f a =>
    let a' := specialize facts a
    mapOne a' (.fpToBits f) (FPEval.toBits) (fun _ _ => rfl)
  | .fpUnary op f a =>
    let a' := specialize facts a
    mapOne a' (.fpUnary op f) (FPEval.unary op) (fun _ _ => rfl)
  | .fpBinary op f a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    mapTwo a' b' (.fpBinary op f) (FPEval.binary op) (fun _ _ _ => rfl)
  | .fpRounded op f r a b =>
    let r' := specialize facts r
    let a' := specialize facts a
    let b' := specialize facts b
    mapThree r' a' b' (.fpRounded op f) (FPEval.rounded op) (fun _ _ _ _ => rfl)
  | .fpFma f r a b c =>
    let r' := specialize facts r
    let a' := specialize facts a
    let b' := specialize facts b
    let c' := specialize facts c
    mapFour r' a' b' c' (.fpFma f) (FPEval.fma) (fun _ _ _ _ _ => rfl)
  | .fpSqrt f r a =>
    let r' := specialize facts r
    let a' := specialize facts a
    mapTwo r' a' (.fpSqrt f) (FPEval.sqrt) (fun _ _ _ => rfl)
  | .fpRoundToIntegral f r a =>
    let r' := specialize facts r
    let a' := specialize facts a
    mapTwo r' a' (.fpRoundToIntegral f) (FPEval.roundToIntegral) (fun _ _ _ => rfl)
  | .fpCompare op f a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    mapTwo a' b' (.fpCompare op f) (FPEval.compare op) (fun _ _ _ => rfl)
  | .fpClassify op f a =>
    let a' := specialize facts a
    mapOne a' (.fpClassify op f) (FPEval.classify op) (fun _ _ => rfl)
  | .fpToBv signed f w r a =>
    let r' := specialize facts r
    let a' := specialize facts a
    mapTwo r' a' (.fpToBv signed f w) (FPEval.toBV signed w) (fun _ _ _ => rfl)
  | .fpFromBv signed w f r a =>
    let r' := specialize facts r
    let a' := specialize facts a
    mapTwo r' a' (.fpFromBv signed w f) (fun r x => FPEval.fromBV signed f r x) (fun _ _ _ => rfl)
  | .fpCast src dst r a =>
    let r' := specialize facts r
    let a' := specialize facts a
    mapTwo r' a' (.fpCast src dst) (FPEval.cast src dst) (fun _ _ _ => rfl)
  | .eqFp f a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    mapTwo a' b' (.eqFp f) (fun x y => decide (x = y)) (fun _ _ _ => rfl)
  | .eqRoundingMode a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    mapTwo a' b' (.eqRoundingMode) (fun x y => x == y) (fun _ _ _ => rfl)
  | .constArray iw vw a =>
    let a' := specialize facts a
    mapOne a' (.constArray iw vw) (Eval.memConst) (fun _ _ => rfl)
  | .boolNot a =>
    let a' := specialize facts a
    thenReduce (mapOne a' (.boolNot) (fun x => !x) (fun _ _ => rfl)) (foldBoolNot a'.val)
  | .boolAnd a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.boolAnd) (fun x y => x && y) (fun _ _ _ => rfl)) (foldBoolAnd a'.val b'.val)
  | .boolOr a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.boolOr) (fun x y => x || y) (fun _ _ _ => rfl)) (foldBoolBinary a'.val b'.val .boolOr (fun x y => x || y) (fun _ _ _ => rfl))
  | .ite c a b =>
    let c' := specialize facts c
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapThree c' a' b' (.ite) (fun c x y => if c then x else y) (fun _ _ _ _ => rfl)) (foldIte c'.val a'.val b'.val)
  | .bvBin op w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.bvBin op w) (Eval.BvBinOp.apply w op) (fun _ _ _ => rfl)) (foldBvBin op w a'.val b'.val)
  | .bvNot w a =>
    let a' := specialize facts a
    thenReduce (mapOne a' (.bvNot w) (fun x => ~~~x) (fun _ _ => rfl)) (foldBvUnary w w a'.val (.bvNot w) (fun x => ~~~x) (fun _ _ => rfl))
  | .zeroExt w n a =>
    let a' := specialize facts a
    thenReduce (mapOne a' (.zeroExt w n) (BitVec.zeroExtend (w + n)) (fun _ _ => rfl)) (foldBvUnary w (w+n) a'.val (.zeroExt w n) (BitVec.zeroExtend (w+n)) (fun _ _ => rfl))
  | .signExt w n a =>
    let a' := specialize facts a
    thenReduce (mapOne a' (.signExt w n) (BitVec.signExtend (w + n)) (fun _ _ => rfl)) (foldBvUnary w (w+n) a'.val (.signExt w n) (BitVec.signExtend (w+n)) (fun _ _ => rfl))
  | .extract spec a =>
    let a' := specialize facts a
    thenReduce (mapOne a' (.extract spec) (BitVec.extractLsb spec.hi spec.lo) (fun _ _ => rfl)) (foldBvUnary _ spec.width a'.val (.extract spec) (BitVec.extractLsb spec.hi spec.lo) (fun _ _ => rfl))
  | .concat wh wl a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.concat wh wl) (fun x y => x ++ y) (fun _ _ _ => rfl)) (foldBvBinary wh wl (wh+wl) a'.val b'.val (.concat wh wl) (fun x y => x ++ y) (fun _ _ _ => rfl))
  | .select iw vw a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenRewrite (mapTwo a' b' (.select iw vw) Eval.memLoad (fun _ _ _ => rfl))
      (rewriteSelect facts a'.val b'.val)
  | .store iw vw a b c =>
    let a' := specialize facts a
    let b' := specialize facts b
    let c' := specialize facts c
    mapThree a' b' c' (.store iw vw) (Eval.memStore) (fun _ _ _ _ => rfl)
  | .bvUlt w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.bvUlt w) (BitVec.ult) (fun _ _ _ => rfl)) (foldBvCmp w a'.val b'.val (.bvUlt w) (BitVec.ult) (fun _ _ _ => rfl))
  | .bvUle w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.bvUle w) (BitVec.ule) (fun _ _ _ => rfl)) (foldBvCmp w a'.val b'.val (.bvUle w) (BitVec.ule) (fun _ _ _ => rfl))
  | .bvSlt w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.bvSlt w) (BitVec.slt) (fun _ _ _ => rfl)) (foldBvCmp w a'.val b'.val (.bvSlt w) (BitVec.slt) (fun _ _ _ => rfl))
  | .bvSle w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.bvSle w) (BitVec.sle) (fun _ _ _ => rfl)) (foldBvCmp w a'.val b'.val (.bvSle w) (BitVec.sle) (fun _ _ _ => rfl))
  | .eqBv w a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.eqBv w) (fun x y => x == y) (fun _ _ _ => rfl)) (foldBvCmp w a'.val b'.val (.eqBv w) (fun x y => x == y) (fun _ _ _ => rfl))
  | .eqBool a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    thenReduce (mapTwo a' b' (.eqBool) (fun x y => x == y) (fun _ _ _ => rfl)) (foldBoolBinary a'.val b'.val .eqBool (fun x y => x == y) (fun _ _ _ => rfl))
  | .eqArray iw vw a b =>
    let a' := specialize facts a
    let b' := specialize facts b
    mapTwo a' b' (.eqArray iw vw) (Eval.memEqual) (fun _ _ _ => rfl)
  | .letPar bs body =>
    let bs' := specializeBindings facts bs
    rewriteLet bs' (specialize bs'.known body)
termination_by structural e

/-- Parallel RHSs are all specialized using the same pre-binding facts. -/
def specializeBindings {Γ Δ : Ctx} (facts : Facts Γ) (bs : Bindings Γ Δ) :
    BindingRewrite facts bs :=
  match bs with
  | .nil => nilBindings facts
  | .cons name sort rhs rest =>
    consBindings name sort (specialize facts rhs) (specializeBindings facts rest)
termination_by structural bs

end

/-- No evaluator law is an input: preservation follows from the constructed rewrite. -/
theorem specialize_correct (facts : Facts Γ) (e : Expr Γ s) (ρ : Env Γ)
    (h : Holds facts ρ) : Eval.eval ρ (specialize facts e).val = Eval.eval ρ e :=
  (specialize facts e).property ρ h

end Futamura.Reference
