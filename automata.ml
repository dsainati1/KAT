open Ast
open Batteries

module Derivative = struct
	let rec e : term -> term = function
		  Act _ -> Zero
		| One -> One
		| Zero -> Zero
		| Plus (e1, e2) -> Plus (e e1, e e2)
		| Times (e1, e2) -> Times (e e1, e e2)
		| Star _ -> One
	and d (exp : term) : string -> term = fun a -> 
		match exp with
		| Zero -> Zero
		| One -> One
		| Act b when a = b -> One
		| Act b -> Zero
		| Plus (e1, e2) -> Plus (d e1 a, d e2 a) 
		| Times (e1, e2) -> 
			let e1' = Times (d e1 a, e2) in 
			let e2' = Times (e e1, d e2 a) in
			Plus (e1', e2')
		| Star e' -> Times (d e' a, exp)
end

type id = string

type nfa = n_state * (n_state list)
and n_state = Final of id * (n_transition list) | Nonfinal of id * (n_transition list)
and n_transition = string * (n_state list)

type dfa = d_state * (d_state list)
and d_state = Final of id * (d_transition list) | Nonfinal of id * (d_transition list)
and d_transition = string * d_state

let build_nfa (e : term) (vars : StringSet.t) : nfa =
	failwith "unimplemented"

let determinize (n : nfa) : dfa = 
	failwith "unimplemented"

let minimize (d : dfa) : dfa =
	failwith "unimplemented"

let equal (d1 : dfa) (d2 : dfa) : string option = 
	None