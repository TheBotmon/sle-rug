module IDE

/*
 * Import this module in a Rascal terminal and execute `main()`
 * to enable language services in the IDE.
 */

import util::LanguageServer;
import util::Reflective;

import IO;
import String;

import Syntax;
import AST;
import CST2AST;
import Resolve;
import Check;
import Compile;
import Message;
import ParseTree;
import Transform;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[Form], input, src);
    }),
    lenses(myLenses),
    executor(myCommands),
    summarizer(mySummarizer
        , providesDocumentation = true
        , providesDefinitions = true
        , providesReferences = false
        , providesImplementations = false)
};

str type2str(tint()) = "integer";
str type2str(tbool()) = "boolean";
str type2str(tstr()) = "string";
str type2str(tunknown()) = "unknown";

Summary mySummarizer(loc origin, start[Form] input) {
  AForm ast = cst2ast(input);
  RefGraph g = resolve(ast);
  TEnv tenv = collect(ast);
  set[Message] msgs = check(ast, tenv, g.useDef);

  rel[loc, Message] msgMap = {< m.at, m> | Message m <- msgs };
  
  rel[loc, str] docs = { <u, "Type: <type2str(t)>"> | <loc u, loc d> <- g.useDef, <d, _, _, Type t> <- tenv };
  return summary(origin, messages = msgMap, definitions = g.useDef, documentation = docs);
}

data Command
  = compileQL(start[Form] form);

rel[loc,Command] myLenses(start[Form] input) 
  = {<input@\loc, compileQL(input, title="Compile")>};


void myCommands(compileQL(start[Form] ql)) {
    compile(cst2ast(ql));
}

void main() {
    registerLanguage(
        language(
            pathConfig(srcs = [|std:///|, |project://sle-rug/src|]),
            "QL",
            "myql",
            "IDE",
            "myLanguageContributor"
        )
    );
}


/*
 * Function to compile a file
 * Parameter: the path/name to the file in the example folder
 * Returns the messages (warnings and errors)
 * Outputs a HTML and JS file in the same folder if there were no errors
 */

set[Message] compileFile(str path){
  loc l = |project://sle-rug/examples/| + path;
  str file = readFile(l);
  start[Form] input = parse(#start[Form], file, l);
  AForm ast = cst2ast(input);
  RefGraph g = resolve(ast);
  TEnv tenv = collect(ast);

  //input = rename(input, input.top.questions[0].src, "has", g.useDef);
  
  set[Message] msgs = check(ast, tenv, g.useDef);
  for(Message msg <- msgs){
    switch(msg){
      case error(str s, loc c):
        return msgs;
    }
  }
  myCommands(compileQL(input));
 
  return msgs;
}