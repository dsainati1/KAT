open Ast
open Batteries
open Equality

let print_result = function 
	  Equal -> print_endline "equal"
	| NonEqual t -> Printf.printf "nonequal, differ on: \"%s\"\n" t

let eval_term : string -> unit = 
	   Lexing.from_string
	%> Parser.parse_term Lexer.token
	%> automaton_string
	%> print_endline

let eval_equation : string -> unit = 
	   Lexing.from_string
	%> Parser.parse_equation Lexer.token
	%> check_equality
	%> print_result

let rec main () : unit = 
	print_endline "Enter a regular expression or equation";
	let input = read_line () in
	(try eval_equation input
	with 
	  Parsing.Parse_error -> begin
	  	(try eval_term input
	  with Parsing.Parse_error -> print_endline "Parse Error"
	    | Failure s -> print_endline s);
	  end
	| Failure s -> print_endline s);
	main ()

let _ = main ()