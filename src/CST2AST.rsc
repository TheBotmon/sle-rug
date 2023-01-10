module CST2AST

import Syntax;
import AST;

import ParseTree;

import IO;
import Boolean;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after Form
  AForm af = form("<f.name>", [cst2ast(question) | question <- f.questions], src=f.src);
  return af;
}

default AQuestion cst2ast(Question q) {
  switch(q){
    case (Question)`<Str text> <Id name> : <Type typeval>`: return question(cst2ast(text), cst2ast(name), cst2ast(typeval), src=q.src);
    case (Question)`<Str text> <Id name> : <Type typeval> = <Expr expr>` : {expr.src = q.src; return questionComputed(cst2ast(text), cst2ast(name), cst2ast(typeval), cst2ast(expr), src=q.src);}
    case (Question)`if(<Expr condition>){<Question* questions>}` : {condition.src = q.src; return ifq(cst2ast(condition), [cst2ast(question) | question <- questions], src=q.src);}
    case (Question)`if(<Expr condition>){<Question* questions>}else{<Question* questionsElse>}` : {condition.src = q.src; return ifelseq(cst2ast(condition), [cst2ast(question) | question <- questions], [cst2ast(question) | question <- questionsElse], src=q.src);}
    
    default: throw "question unexpected format";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(aid("<x>", src=x.src), src=x.src);
    case (Expr)`<Int n>`: {return intval(toInt("<n>"), src=e.src);}
    case (Expr)`<Bool b>`: return boolval(fromString("<b>"), src=e.src);
    case (Expr)`(<Expr ex>)`: return par(cst2ast(ex), src=e.src);
    case (Expr)`!<Expr ex>`: return not(cst2ast(ex), src=e.src);
    case (Expr)`<Expr ex1> * <Expr ex2>`: return mul(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> / <Expr ex2>`: return div(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> + <Expr ex2>`: return add(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> - <Expr ex2>`: return sub(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> \> <Expr ex2>`: return big(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> \>= <Expr ex2>`: return bigeq(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> \< <Expr ex2>`: return small(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> \<= <Expr ex2>`: return smalleq(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> == <Expr ex2>`: return equal(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> != <Expr ex2>`: return nequal(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> || <Expr ex2>`: return or(cst2ast(ex1), cst2ast(ex2), src=e.src);
    case (Expr)`<Expr ex1> && <Expr ex2>`: return and(cst2ast(ex1), cst2ast(ex2), src=e.src);  

    default: throw "Unhandled expression:  <e>"; 
  }
}

default AStr cst2ast(Str question){
  return astr("<question>"[1..-1], src=question.src);
}

default AId cst2ast(Id id){
  return aid("<id>", src=id.src);
}

default AType cst2ast(Type t) {
  switch("<t>"){
    case "integer": return atype("int", src=t.src);
    case "string": return atype("str", src=t.src);
    case "boolean": return atype("bool", src=t.src);

    default: throw "Unrecognized type: <t>";
  }
}
