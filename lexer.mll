{
open Parser
}
let alphanumeric = ['a'-'z' 'A'-'Z' '0'-'9']*
rule token = parse
    [' ' '\t']     { token lexbuf }     (* skip blanks *)
  | ['\n'] { EOL }
  | ['a'-'z'] alphanumeric as id { ACT id }
  | '0'    { ZERO }
  | '1'    { ONE }
  | '+'    { PLUS }
  | '.'    { TIMES }
  | ';'    { TIMES }
  | '*'    { STAR }
  | '('    { LPAREN }
  | ')'    { RPAREN }
  | '='    { EQ }
  | eof    { EOL }
