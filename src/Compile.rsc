module Compile

import AST;
import Resolve;
import IO;
import String;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

HTMLElement form2html(AForm f) {
  return html([htmlHead(f), htmlBody(f)]);
}

HTMLElement htmlHead(AForm f){
  HTMLElement htmlScript = script([]);
  str location = "<f.src[extension="js"].top>";
  int last = findLast(location, "/");
  location = location[last+1..-1];
  htmlScript.src = location;
  HTMLElement head = head([htmlScript]);
  head.title = "Title";
  return head;
}

HTMLElement htmlBody(AForm f){
  HTMLElement body = body(h2([text(f.name)]) + htmlQuestions(f.questions));
  body.onload = "initHtmlElems(); checkComputed(); checkConditions();";
  return body;
}

list[HTMLElement] htmlQuestions(list[AQuestion] f){
  list[HTMLElement] ret = [];

  HTMLElement htmlInput, htmlText, htmlDiv, htmlLabel;
  for(AQuestion q <- f){
    if(q has id){
      htmlText = text(q.text.name);
      ret += h3([htmlText]);

      htmlInput = input();
      htmlInput.id = q.id.name;
      htmlInput.onchange = "onValueChange(\'" + q.id.name + "\')"; 

      switch(q.atype.atype){
        case "str": {
          htmlInput.\type = "text";
          if(q has compute){htmlInput.readonly = "true";};
          ret += p([htmlInput]);
        }
        case "bool": {
          htmlInput.\type = "checkbox";
          if(q has compute){htmlInput.disabled = "true";};
          htmlLabel = label([text("yes")]);
          htmlLabel.\for = q.id.name;
          ret += p([htmlInput, htmlLabel]);
        }
        case "int": {
          htmlInput.\type = "number";
          if(q has compute){htmlInput.readonly = "true";}; 
          ret += p([htmlInput]);
        }
      }

      ret += br();
    }
    else if(q has cond){
      htmlDiv = div(htmlQuestions(q.ifQuestions));
      htmlDiv.class = toString(q.cond);
      ret += htmlDiv;
      if(q has elseQuestions){
        htmlDiv = div(htmlQuestions(q.elseQuestions));
        htmlDiv.class = "!(" + toString(q.cond) + ")";
        ret += htmlDiv;
      }
    }
  }

  return ret;
}


str form2js(AForm f) {
  return jsInitVar(f.questions) + jsInitHtmlElems() + jsInitCond(f.questions) + jsInitCompute(f.questions) + jsInitOnChange(f.questions);
}

str jsInitVar(list[AQuestion] questions){
  str ret = "let valueMap = new Map();\n";
  for(/AQuestion q <- questions){
    if(q has id){
      ret += "valueMap.set(\"<q.id.name>\", ";
      switch(q.atype.atype){
        case "int": ret += "0";
        case "str": ret += "\"\"";
        case "bool": ret += "false";
      }
      ret += ");\n";
    }
  }
  ret += "\n";
  return ret;
}

str jsInitHtmlElems(){
  return "function initHtmlElems(){
  ' \tlet elems = document.getElementsByTagName(\'input\');
  ' \tfor(i=0; i\<elems.length; i++){
  ' \t\tswitch(elems[i].type){
  ' \t\t\tcase \"checkbox\":
  ' \t\t\telems[i].checked = false;
  ' \t\t\tbreak;
  ' \t\t\tcase \"number\":
  ' \t\t\telems[i].value = 0;
  ' \t\t\tbreak;
  ' \t\t\tcase \"text\":
  ' \t\t\telems[i].value = \"\";
  ' \t\t}
  ' \t}
  '}\n";
}

str jsInitCond(list[AQuestion] questions){
  str ret = "function checkConditions(){
  ' let cond = undefined;
  ' let elems = undefined;
  ' let notElems = undefined;
  ' ";
  for(/AQuestion q <- questions){
    if(q has cond){
      ret += "\tcond = <toString(q.cond, b = true)>;
      ' \telems = document.getElementsByClassName(\"<toString(q.cond)>\");
      ' \tnotElems = document.getElementsByClassName(\"!(<toString(q.cond)>)\");
      ' \tArray.prototype.map.call(elems, x =\> x.style = cond ? \"display: block\" : \"display: none\");
      ' \tArray.prototype.map.call(notElems, x =\> x.style = cond ? \"display: none\" : \"display: block\");
      ' ";
    }
  }
  ret += "}\n\n";
  return ret;
}

str jsInitCompute(list[AQuestion] questions){
  str ret = "function checkComputed(){\n\tlet htmlElem=undefined;\n";
  for(/AQuestion q <- questions){
    if(q has compute){
      ret += "\t<q.id.name> = <toString(q.compute)>;
      ' \thtmlElem = document.getElementById(\"<q.id.name>\");
      ' \tif(htmlElem.type == \"checkbox\"){
      ' \t\t htmlElem.checked = <toString(q.compute, b=true)>;
      ' \t} else{
      ' \t\t htmlElem.value = <toString(q.compute, b=true)>;
      ' \t}\n";
    }
  }
  ret += "}\n\n";
  return ret;
}

str jsInitOnChange(list[AQuestion] questions){
  str ret = "function onValueChange(changed){
  ' \tlet htmlElem = document.getElementById(changed);
  ' \tif(htmlElem.type==\"checkbox\"){;
  ' \t\tvalueMap.set(changed, htmlElem.checked);
  ' \t} else{
  ' \t\tvalueMap.set(changed, htmlElem.value);
  ' \t}
  ' \tcheckComputed();
  ' \tcheckConditions();
  ' }";
  return ret;
}

str toString(AExpr expr, bool b = false){
  switch(expr){
    case ref(AId x): return b ? "valueMap.get(\"" + x.name + "\")" : x.name;
    case intval(int n): return "<n>";
    case boolval(bool b): return "<b>";
    case par(AExpr x): return "(" + toString(x, b=b) + ")";
    case not(AExpr x): return "!" + toString(x, b=b);
    case add(AExpr x, AExpr y): return toString(x, b=b) + "+" + toString(y, b=b);
    case sub(AExpr x, AExpr y): return toString(x, b=b) + "-" + toString(y, b=b);
    case mul(AExpr x, AExpr y): return toString(x, b=b) + "*" + toString(y, b=b);
    case div(AExpr x, AExpr y): return toString(x, b=b) + "/" + toString(y, b=b);
    case big(AExpr x, AExpr y): return toString(x, b=b) + "\>" + toString(y, b=b);
    case bigeq(AExpr x, AExpr y): return toString(x, b=b) + "\>=" + toString(y, b=b);
    case small(AExpr x, AExpr y): return toString(x, b=b) + "\<" + toString(y, b=b);
    case smalleq(AExpr x, AExpr y): return toString(x, b=b) + "\<=" + toString(y, b=b);
    case equal(AExpr x, AExpr y): return toString(x, b=b) + "==" + toString(y, b=b);
    case nequal(AExpr x, AExpr y): return toString(x, b=b) + "!=" + toString(y, b=b);
    case or(AExpr x, AExpr y): return toString(x, b=b) + "||" + toString(y, b=b);
    case and(AExpr x, AExpr y): return toString(x, b=b) + "&&" + toString(y, b=b);
    default: return "";
  }
}
