module Transform

import Syntax;
import Resolve;
import AST;

import List;
import IO;
import Relation;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  f.questions = flatten(f.questions, []);
  return f; 
}

list[AQuestion] flatten(list[AQuestion] questions, list[AExpr] ids){
  list[AQuestion] new = [];
  for(q <- questions){
    if(q has id){
      new += ifq(andExpr(ids), [q]);
    } else{
      ids += q.cond;
      new += flatten(q.ifQuestions, ids);
      ids = prefix(ids);
      if(q has elseQuestions){
        ids += not(q.cond);
        new += flatten(q.elseQuestions, ids);
        ids = prefix(ids);
      }
    }
  }
  return new;
}

AExpr andExpr(list[AExpr] exprs){
  AExpr ret = boolval(true);
  for(expr <- exprs){
    ret = and(ret, expr);
  }
  return ret;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  set[loc] use = invert(useDef)[useOrDef];
  for(u <- use){
    use += useDef[u];
  }
  for(/Question q := f){
    if(q.src in use){
      use += q.name.src;
    }
  }
  Id newNameId = [Id]newName;

  f.top = visit(f.top){
    case (Expr e)`<Id oldName>`: {if(oldName.src in use){insert (Expr)`<Id newNameId>`;}}
    case (Question)`<Str text> <Id name> : <Type typeval>`: {if(name.src in use){insert (Question)`<Str text> <Id newNameId> : <Type typeval>`;}}
    case (Question)`<Str text> <Id name> : <Type typeval> = <Expr expr>` :if(name.src in use){insert (Question)`<Str text> <Id newNameId> : <Type typeval> = <Expr expr>`;}
    default: {};
  }
  
  return f; 
} 
 
 
 

