module Check

import AST;
import Resolve;
import Message; // see standard library

import IO;
import Set;
import List;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  return {<q.src, q.id.name, q.text.name, getType(q.atype.atype)> | /AQuestion q := f, q has id}; 
}

Type getType(str atype){
  switch(atype){
    case "int": return tint();
    case "str": return tstr();
    case "bool": return tbool();
    default: return tunknown();
  }
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msg = {};
  for(/AQuestion q := f){
    if(q has id){
      msg += check(q, tenv, useDef);
    }
    if(q has cond){
      msg += check(q.cond, tenv, useDef);
      msg += checkBool(typeOf(q.cond, tenv, useDef))? {} : {error("Error: condition not of type bool", q.cond.src)};
    }
  }
  return msg;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msg = {};

  // check declared questions with the same name but different types : error
  if(!isEmpty(tenv[_, q.id.name, _] - {getType(q.atype.atype)})){
    msg += error("Error: <q.id.name> has already been declared with different type", q.atype.src);
  } 

  // check duplicate labels : warning
  if(size(toList(tenv)[_, _, q.text.name])>1){
    msg += warning("Warning: <q.id.name> has a duplicate label", q.id.src);
  }

  // check if the computed type matched the type of the expression: error
  if(q has compute){
    msg += typeOf(q.compute, tenv, useDef)!=getType(q.atype.atype) ? error("Error: computed type is different from the expression", q.compute.src) : {}; 
  }

  // check each expressions
  for(/AExpr expr := q){
    msg += check(expr, tenv, useDef);
  }
  return msg; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
// the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msg = {};
  // check lhs and rhs have the right type
  switch (e) {
    case ref(AId x):
      msg += { error("Error: Undeclared question", x.src) | useDef[x.src] == {} };
    case par(AExpr x):
      msg += check(x, tenv, useDef);
    case not(AExpr x):
      msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
    case add(AExpr x, AExpr y):
      {msg += checkInt(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", x.src)};
       msg += checkInt(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", y.src)};}
    case sub(AExpr x, AExpr y):
      {msg += checkInt(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", x.src)};
       msg += checkInt(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", y.src)};}
    case mul(AExpr x, AExpr y):
      {msg += checkInt(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", x.src)};
       msg += checkInt(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", y.src)};}
    case div(AExpr x, AExpr y):
      {msg += checkInt(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", x.src)};
       msg += checkInt(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected int", y.src)};}
    case big(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};}
    case bigeq(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};}
    case small(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};}
    case smalleq(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};}
    case equal(AExpr x, AExpr y):
      {msg += typeOf(x, tenv, useDef) == typeOf(y, tenv, useDef) ? {} : {error("Error: Unexpected unequal types", x.src)};}
    case nequal(AExpr x, AExpr y):
      {msg += typeOf(x, tenv, useDef) == typeOf(y, tenv, useDef) ? {} : {error("Error: Unexpected unequal types", x.src)};}
    case or(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};}
    case and(AExpr x, AExpr y):
      {msg += checkBool(typeOf(x, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", x.src)};
       msg += checkBool(typeOf(y, tenv, useDef)) ? {} : {error("Error: Unexpected type, expected bool", y.src)};} 
    default : {};
  }
  return msg; 
}

bool checkBool(Type t){
  return t == tbool() || t == tunknown();
}

bool checkInt(Type t){
  return t == tint() || t == tunknown();
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(aid(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case intval(_): return tint();
    case boolval(_): return tbool();
    case par(AExpr x): return typeOf(x, tenv, useDef);
    case not(AExpr): return tbool();
    case add(_, _): return tint();
    case sub(_, _): return tint();
    case mul(_, _): return tint();
    case div(_, _): return tint();
    case big(_, _): return tbool();
    case bigeq(_, _): return tbool();
    case small(_, _): return tbool();
    case smalleq(_, _): return tbool();
    case equal(_, _): return tbool();
    case nequal(_, _): return tbool();
    case or(_, _): return tbool();
    case and(_, _): return tbool();
    default: return tunknown();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

