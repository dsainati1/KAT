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

%start parse_term parse_equation  /* entry points */
%type <Ast.equation> parse_equation
%type <Ast.term> parse_term

%%

parse_term:
  term EOL { $1 }
;
parse_equation:
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