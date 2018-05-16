open Ast
open Batteries
open Equality

let print_result = function 
	  Equal -> print_endline "equal"
	| NonEqual t -> Printf.printf "nonequal, differ on: %s\n" t

let eval_equation : string -> unit = 
	Lexing.from_string
	%> Parser.parse_equation Lexer.token
	%> check_equality
	%> print_result

let rec main () : unit = 
	print_endline "Enter a regular expression";
	try read_line () |> eval_equation;
	with 
	  Parsing.Parse_error -> print_endline "Parse Error"
	| Failure s -> print_endline s;
	main ()

let _ = main ()