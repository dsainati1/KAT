open Ast
open Batteries

module Brzozowski = struct
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

type nfa = id * ((id * n_state) list)
and n_state = Final of id * (n_transition list) | NonFinal of id * (n_transition list)
and n_transition = string * (id list)

type dfa = id * ((id * d_state) list)
and d_state = Final of id * (d_transition list) | NonFinal of id * (d_transition list)
and d_transition = string * id

(*===================================================================================
								Utility functions									
====================================================================================*)

let get_n_state_id : n_state -> id = function
	  Final (id, _) -> id
	| NonFinal (id, _) -> id

let print_nfa ((start, states) : nfa) : unit = 
	()


(*===================================================================================
								NFA Construction									
====================================================================================*)

(* Finds all the possible successor states after transitioning from e on s *)
let succs (e : term) (s : string) : term list = 
	(* Plus functions like a nondeterministic choice *)
	let rec choices (e : term) : term list = 
		match e with
		| Plus (e1, e2) -> (choices e1 @ choices e2) |> List.unique
		| _ -> [e] in 
	Brzozowski.d e s |> choices

(* Collects all the states in the nfa generated by term e, where each state
   corresponds to a term formed by the Brzozowski derivative of e *)
let rec collect_states (vars : StringSet.t) (acc : term list) (e : term) : term list = 
	StringSet.fold (fun s lst -> succs e s @ lst) vars [] 
	|> List.unique 
	|> List.filter (fun state -> List.mem state acc) 
	|> List.fold_left (collect_states vars) acc 

(* Constructions a non-deterministic transition from a term and the transition string *)
let term_to_n_transition (e : term) (s : string): n_transition = 
	s, succs e s |> List.map term_to_string

(* Constructs a state from a term e by associating it with the transitions out of it.
   The term is marked final or nonfinal based on its Brzozowski derivative *)
let term_to_n_state (vars : StringSet.t) (e : term) : n_state = 
	let transitions = StringSet.elements vars |> List.map (term_to_n_transition e) in 
	let id = term_to_string e in 
	match Brzozowski.e e with
	| One -> Final (id, transitions)
	| Zero -> NonFinal (id, transitions)
	| _ -> failwith "impossible"

(* Builds an nfa that accepts a regular set equivalent to the input term over the 
   alphabet vars*)
let build_nfa (e : term) (vars : StringSet.t) : nfa = 
	collect_states vars [] e 
	|> List.map (term_to_n_state vars)
	|> List.map (fun state -> get_n_state_id state, state)
	|> Tuple2.make (term_to_string e)

(*===================================================================================
								DFA Construction									
====================================================================================*)

let determinize (n : nfa) : dfa = 
	failwith "unimplemented"

(*===================================================================================
								DFA Minimization									
====================================================================================*)

let minimize (d : dfa) : dfa =
	failwith "unimplemented"

(*===================================================================================
								 Bisimulation									
====================================================================================*)

let equal (d1 : dfa) (d2 : dfa) : string option = 
	None