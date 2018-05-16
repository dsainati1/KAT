%{
open Ast
%}

%token <string> ACT
%token ZERO ONE
%token PLUS TIMES STAR
%token LPAREN RPAREN
%token EQ
%token EOL

       
%nonassoc EQ 
%left PLUS
%left TIMES ACT ZERO ONE LPAREN
%nonassoc STAR

%start term_main equation_main  /* entry points */
%type <Ast.equation> equation_main
%type <Ast.term> term_main

%%

term_main:
  term EOL { $1 }
;
equation_main:
  equation EOL { $1 }
;

term:
  | ACT             { Act $1 }
  | ZERO            { Zero }
  | ONE             { One }
  | LPAREN term RPAREN { $2 }
  | term PLUS term  { Plus [$1; $3] }
  | term TIMES term { Times [$1; $3] }
  | term STAR       { Star $1 }
  | term term %prec TIMES { Times [$1; $2] }
;
equation:
    term EQ term { Eq ($1, $3) }
;