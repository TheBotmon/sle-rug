module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  map[str, \Value] ret;
  for(/AQuestion q := f){
    if(q has id){
      switch(q.atype.atype){
        case "int": ret += (q.id.name, vint(0));
        case "bool": ret += (q.id.name, vbool(false));
        case "str": ret += (q.id.name, vstr(""));
      }
    }
  };
  return ret;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q := f){
    venv += eval(q, inp, venv);
  }
  return venv; 
}

  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  if(q has id){
    if(q has compute){
      venv += (q.id.name: eval(q.compute, venv));
    } else if(q.id.name == inp.question){
      venv += (q.id.name: inp.\value);
    }
  } else{
    if(eval(q.cond) == vbool(true)){
      for(AQuestion q2 := q.ifQuestions){
        venv += eval(q2, inp, venv);
      }
    } else if(q has elseQuestions){
      for(AQuestion q2 := q.elseQuestions){
        venv += eval(q2, inp, venv);
      }
    }
  }

  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case intval(int n): return vint(n);
    case boolval(bool b): return vbool(b);
    case par(AExpr x): return eval(x, venv);
    case not(AExpr x): return vbool(!eval(x, venv).b);
    case add(AExpr x, AExpr y): return vint(eval(x, venv).n + eval(y, venv).n);
    case sub(AExpr x, AExpr y): return vint(eval(x, venv).n - eval(y, venv).n);
    case mul(AExpr x, AExpr y): return vint(eval(x, venv).n * eval(y, venv).n);
    case div(AExpr x, AExpr y): return vint(eval(x, venv).n / eval(y, venv).n);
    case big(AExpr x, AExpr y): return vbool(eval(x, venv).b > eval(y, venv).b);
    case bigeq(AExpr x, AExpr y): return vbool(eval(x, venv).b >= eval(y, venv).b);
    case small(AExpr x, AExpr y): return vbool(eval(x, venv).b < eval(y, venv).b);
    case smalleq(AExpr x, AExpr y): return vbool(eval(x, venv).b <= eval(y, venv).b);
    case equal(AExpr x, AExpr y): return vbool(eval(x, venv).b == eval(y, venv).b);
    case nequal(AExpr x, AExpr y): return vbool(eval(x, venv).b != eval(y, venv).b);
    case or(AExpr x, AExpr y): return vbool(eval(x, venv).b || eval(y, venv).b);
    case and(AExpr x, AExpr y): return vbool(eval(x, venv).b && eval(y, venv).b);

    default: throw "Unsupported expression <e>";
  }
}