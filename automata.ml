open Ast
open Batteries

module Brzozowski = struct
	let rec e : term -> term = function
		  Act _ -> Zero
		| One -> One
		| Zero -> Zero
		| Plus (e1, e2) -> Plus (e e1, e e2) |> simplify
		| Times (e1, e2) -> Times (e e1, e e2) |> simplify
		| Star _ -> One
	and d (exp : term) : string -> term = fun a -> 
		match exp with
		| Zero -> Zero
		| One -> Zero
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

type nfa = id * (n_state list)
and n_state = Final of id * (n_transition list) | NonFinal of id * (n_transition list)
and n_transition = string * (id list)

type dfa = id * (d_state list)
and d_state = Final of id * (d_transition list) | NonFinal of id * (d_transition list)
and d_transition = string * id

(*===================================================================================
								Utility functions									
====================================================================================*)

let get_n_state_id : n_state -> id = function
	  Final (id, _) -> id
	| NonFinal (id, _) -> id

let get_d_state_id : d_state -> id = function
	  Final (id, _) -> id
	| NonFinal (id, _) -> id

let n_state_to_transitions : n_state -> n_transition list = function
		Final (_, t) -> t | NonFinal  (_, t) -> t 

let d_state_to_transitions : d_state -> d_transition list = function
		Final (_, t) -> t | NonFinal  (_, t) -> t 

let id_to_n_state (id : id) : n_state list -> n_state = 
	let state_has_id : n_state -> bool = function
	  Final (s, _) -> s = id
	| NonFinal (s, _) -> s = id in 
	List.find state_has_id

let id_to_d_state (id : id) : d_state list -> d_state = 
	let state_has_id : d_state -> bool = function
	  Final (s, _) -> s = id
	| NonFinal (s, _) -> s = id in 
	List.find state_has_id

let n_state_is_final : n_state -> bool = function
	  Final _ -> true
	| NonFinal _ -> false

let d_state_is_final : d_state -> bool = function
	  Final _ -> true
	| NonFinal _ -> false

(* Bind/Kliesli composition in the list monad *)
let (>>=) : 'a list -> ('a -> 'b list) -> 'b list = 
	fun m -> flip List.map m %> List.flatten 

(* argument reversed List.map for easier function chaining*)
let (>>|) (l : 'a list) (f : ('a -> 'b)) : 'b list = List.map f l

(*===================================================================================
								Printing functions									
====================================================================================*)

(* Produces a dot graph string equivalent to the input nfa *)
let string_of_nfa ((start, states) : nfa) : string = 

	let add_label (state : n_state) (s : string) : string = 
		let id = get_n_state_id state in 
		s ^ "\"" ^ id ^ "\" [label=\"" ^ id ^ "\"" ^
		(match state with
		  Final _ -> " shape=\"doublecircle\"];\n"
		| NonFinal _ -> " shape=\"circle\"];\n") in 

	let add_transitions (state : n_state) : string -> string = 
		let string_of_transition (letter, dest) s = 
			s ^ "\"" ^ get_n_state_id state ^ "\" -> \"" ^ 
			dest ^ "\" [label=\"" ^ letter ^ "\"];\n" in
		n_state_to_transitions state
		>>= (Tuple2.make %> List.map |> uncurry)
		|> List.fold_right string_of_transition in

	let add_start_node graph = 
		graph ^ "START [style=invis];\nSTART -> \"" ^ start ^ "\";\n}" in 

    "digraph NFA {\ncompound=true;\nordering=out;\n"
	|> List.fold_right add_label states
	|> List.fold_right add_transitions states
	|> add_start_node


(*Produces a dot graph string equivalent to the input nfa *)
let string_of_dfa ((start, states) : dfa) : string = 
	let add_label (state : d_state) (s : string) : string = 
		let id = get_d_state_id state in 
		s ^ "\"" ^ id ^ "\" [label=\"" ^ id ^ "\"" ^
		(match state with
		  Final _ -> " shape=\"doublecircle\"];\n"
		| NonFinal _ -> " shape=\"circle\"];\n") in 

	let add_transitions (state : d_state) : string -> string = 
		let transitions : d_state -> d_transition list = function
			Final (_, t) -> t | NonFinal  (_, t) -> t in
		let string_of_transition (letter, dest) s = 
			s ^ "\"" ^ get_d_state_id state ^ "\" -> \"" ^ 
			dest ^ "\" [label=\"" ^ letter ^ "\"];\n" in
		transitions state 
		|> List.fold_right string_of_transition in 

	let add_start_node graph = 
		graph ^ "START [style=invis];\nSTART -> \"" ^ start ^ "\";\n}" in 

    "digraph DFA {\ncompound=true;\nordering=out;\n"
	|> List.fold_right add_label states
	|> List.fold_right add_transitions states
	|> add_start_node

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

	   Brzozowski.d e s 
	|> simplify
	|> choices

(* Collects all the states in the nfa generated by term e, where each state
   corresponds to a term formed by the Brzozowski derivative of e *)
let rec collect_states (vars : StringSet.t) (collected : term list) (e : term) : term list = 
	let accumulate (updates : term list) : term list = 
		List.fold_left (collect_states vars) (collected @ updates) updates in 

	    StringSet.elements vars 
    >>= succs e
    |>  List.unique
    |>  List.filter (flip List.mem collected %> not) 
    |>  accumulate

(* Constructions a non-deterministic transition from a term and the transition string *)
let term_to_n_transition (e : term) (s : string): n_transition = 
	    succs e s 
	>>| term_to_string
	|>  Tuple2.make s

(* Constructs a state from a term e by associating it with the transitions out of it.
   The term is marked final or nonfinal based on its Brzozowski derivative *)
let term_to_n_state (vars : StringSet.t) (e : term) : n_state = 
	let transitions = StringSet.elements vars >>| term_to_n_transition e in 
	let id = term_to_string e in 
	match Brzozowski.e e with
	| One -> Final (id, transitions)
	| Zero -> NonFinal (id, transitions)
	| _ -> failwith "impossible"

(* Builds an nfa that accepts a regular set equivalent to the input term over the 
   alphabet vars*)
let build_nfa (e : term) (vars : StringSet.t) : nfa = 
	    collect_states vars [e] e 
	>>| term_to_n_state vars
	|>  Tuple2.make (term_to_string e) 

(*===================================================================================
								DFA Construction									
====================================================================================*)

type idset = id list

(* Computes the set of reachable deterministic states from an nfa *)
let collect_d_state_ids (start : id) (states : n_state list) : idset list = 
	(* All nstate sets that the input nstate can reach *)
	let reachable_from_state : id -> idset list = 
		   flip id_to_n_state states 
		%> n_state_to_transitions 
	    %> List.map snd in 

	(* All dstates that the input dstate can reach *)
	let reachable_from_state_set (ids : idset) : idset list =
		let get_ith_set (i : int) (sets : idset list list) : idset = 
			    sets 
			>>= flip List.at i 
			|>  List.unique in 
		let collapse_like_states (lst : idset list list) : idset list = 
			let pairwise_map sets : idset list -> idset list = 
				List.mapi (fun ind _ -> get_ith_set ind lst) in 
			lst 
			>>= pairwise_map lst 
			|> List.unique in

		    ids 
		>>| reachable_from_state
		|>  collapse_like_states 
		|>  List.cons ids 
		|>  List.unique in 

 	(* recursively computes the set of all powersets of nondeterministic 
 	   states reachable from the input *)
	let rec compute_reaching_set (sets : idset list) : idset list = 
		let recompute (oldsize : int) (new_set : idset list) = 
			if oldsize = List.length new_set 
			then new_set 
			else compute_reaching_set new_set in 

		    sets
	    >>= reachable_from_state_set
	    >>| List.sort compare
	    |>  List.unique 
	    |>  recompute (List.length sets) in 

	   List.singleton start
	|> reachable_from_state_set
	|> compute_reaching_set 

(* Computes the deterministic state transitions corresponded to by a nondetministic state *)
let get_deterministic_transitions (state : n_state) : (id * string * id) list =
	let pre_transition (id : id) ((l : string), (targets : id list)) : (id * string * id) list = 
		targets >>| Tuple3.make id l in

	let id = get_n_state_id state in 
	n_state_to_transitions state >>= pre_transition id

(* Determinizes the input dfa via the subset construction *)
let determinize ((start, states) : nfa) : dfa = 
	(* Builds a unique name for the deterministic state corresponding to the input set *)
	let name_of_dstate : idset -> id = 
		   List.sort compare
		%> List.fold_left (fun x acc -> acc ^ "," ^ x) "}" 
		%> (^) "{" in 

	(* Builds a list of deterministic states from a list of transitions  *)
	let build_d_states (transitions : (id * string * id) list) : d_state list = 
		(* If any state in this set is final in the nfa*)
		let any_final : id list -> bool = 
			   flip id_to_n_state states
			%> n_state_is_final
			|> List.exists in  

		(* Takes the union of all the destinations of a transition set to produce the target state *)
		let destination_union ((l, dst) : (string * id)) : 
			(string * id list) list -> (string * id list) list =
			   List.cons dst 
			%> List.unique 
			|> List.modify_def [dst] l in

		(* Constructs a deterministic state from a list of non_deterministic states*)
		let build_d_state (id : id list) : d_state = 
			let make_state (trs: d_transition list) : d_state = 
				if any_final id then Final (name_of_dstate id, trs) 
								else NonFinal (name_of_dstate id, trs) in 

			    Tuple3.first
			%>  flip List.mem id 
			|>  flip List.filter transitions 
			>>| Tuple3.get23 
			|>  List.fold_left (flip destination_union) [] 
			>>| Tuple2.map2 name_of_dstate
			|>  make_state in

		    states
        |>  collect_d_state_ids start
        >>| build_d_state in 

	    states 
	>>= get_deterministic_transitions 
	|>  build_d_states 
	|>  Tuple2.make (name_of_dstate [start])

(*===================================================================================
								DFA Minimization									
====================================================================================*)

let minimize (d : dfa) : dfa =
	failwith "unimplemented"

(*===================================================================================
								 Bisimulation									
====================================================================================*)

type sequence = string list

(* Gets the alphabet of a dfa *)
let vars_of_dfa (states : d_state list) : StringSet.t =
	failwith ""

(* All strings of alphabet sigma up to length i *)
let sigma_star (sigma : StringSet.t) (i : int) : sequence list = 
	failwith ""

(* runs the input dfa on the input letter list, and produces whether or not it accepts*)
let accepts (d : dfa) (s : sequence) : bool =
	failwith ""

(* Simulates 2 dfas on an input, and produces where they differ *)
let bisimulate (d1 : dfa) (d2 : dfa) (s : sequence) : sequence option =
	failwith ""

(* Compares equality of two dfas by simulating them on every possible string in their 
   alphabets of length up to the number of states in the larger dfa. Produces None if
   equivalent, or Some x for a string x where they differ.  *)
let equal ((start1, states1) : dfa) ((start2, states2) : dfa) : string option = 
	let flatten_to_string : string list -> string = 
		List.fold_left (fun acc x -> acc ^ "," ^ x) "" in 

	let sigma1 = vars_of_dfa states1 in 
	let sigma2 = vars_of_dfa states2 in 
	let diff = StringSet.sym_diff sigma1 sigma2 in
	
	if neg StringSet.is_empty diff then Some (StringSet.any diff) else

	    List.length states2 
	|>  max (List.length states1) 
	|>  sigma_star sigma1 
	>>| bisimulate (start1, states1) (start1, states2) 
	|>  List.find_opt Option.is_some 
	|>  flip Option.bind identity 
	|>  Option.map flatten_to_string