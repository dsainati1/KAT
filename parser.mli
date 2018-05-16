type token =
  | ACT of (string)
  | ZERO
  | ONE
  | PLUS
  | TIMES
  | STAR
  | LPAREN
  | RPAREN
  | EQ
  | EOL

val term_main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.term
val equation_main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.equation
