open Ast
open Batteries

let eval_term : string -> unit =
	Lexing.from_string
	%> Parser.parse_term Lexer.token
	%> term_to_string 
	%> print_endline

let rec main () : unit = 
	print_endline "Enter a regular expression";
	(try read_line () |> eval_term
	with 
	  Parsing.Parse_error -> print_endline "Parse Error"
	| Failure s -> print_endline s);
	main ()

let _ = main ()