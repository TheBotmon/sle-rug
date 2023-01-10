module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(AStr text, AId id, AType atype)
  | questionComputed(AStr text, AId id, AType atype, AExpr compute)
  | ifq(AExpr cond, list[AQuestion] ifQuestions)
  | ifelseq(AExpr cond, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | intval(int n)
  | boolval(bool b)
  | par(AExpr expr)
  | not(AExpr expr)
  | mul(AExpr expr1, AExpr expr2)
  | div(AExpr expr1, AExpr expr2)
  | add(AExpr expr1, AExpr expr2)
  | sub(AExpr expr1, AExpr expr2)
  | big(AExpr expr1, AExpr expr2)
  | bigeq(AExpr expr1, AExpr expr2)
  | small(AExpr expr1, AExpr expr2)
  | smalleq(AExpr expr1, AExpr expr2)
  | equal(AExpr expr1, AExpr expr2)
  | nequal(AExpr expr1, AExpr expr2)
  | or(AExpr expr1, AExpr expr2)
  | and(AExpr expr1, AExpr expr2)
  ;

data AStr(loc src = |tmp://|)
  = astr(str name)
  ;

data AId(loc src = |tmp:///|)
  = aid(str name)
  ;

data AType(loc src = |tmp:///|)
  = atype(str atype)
  ;