open Ast
open Automata
open Batteries

(* Equal if the expressions are equal, or 
 * Nonequal if they are not, with the data carried being
 * a string generated by one and not the other *)
type result = Equal | NonEqual of string

let check_equality ((e1 : term), (e2: term)) : result = 
	let open Option in 
	let v = StringSet.union (vars e1) (vars e2) in
	let d1 = build_nfa e1 v |> determinize in 
	let d2 = build_nfa e2 v |> determinize in 
	equal d1 d2 |> map (fun s -> NonEqual s) |? Equal 

let automaton_string (e : term) : string = 
	let n = vars e |> build_nfa e in 
	string_of_nfa n |> print_endline;
	print_endline "";
	determinize n |> string_of_dfa