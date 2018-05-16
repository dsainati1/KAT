
(***********************************************
 * syntax
 ***********************************************)

  type id = string

  (* character encoding *)
  let utf8 = ref false

  type term =
  | Act of id
  | Plus of term list
  | Times of term list
  | Star of term
  | Zero
  | One
  
  type equation = Eq of term * term

(***********************************************
 * output
 ***********************************************)

  let assoc_to_string (op : string) (id : string) (s : string list) : string =
    match s with
      [] -> id
    | _ -> String.concat op s

(* higher precedence binds tighter *)
  let out_precedence (t : term) : int =
    match t with
      Plus _ -> 0
    | Times _ -> 1
    | Star _ -> 2
    | _ -> 3 (* variables and constants *)

  let rec term_to_string (t : term) : string =
    (* parenthesize as dictated by surrounding precedence *)
    let protect (x : term) : string =
      let s = term_to_string x in
      if out_precedence t <= out_precedence x then s else "(" ^ s ^ ")" in
    match t with
    | Act x -> x
    | Plus x -> assoc_to_string " + " "0" (List.map protect x)
    | Times x -> assoc_to_string "." "1" (List.map protect x)
    | Star x -> (protect x) ^ "*"
    | Zero -> "0"
    | One -> "1"

  let eqn_to_string (e : equation) =
    match e with 
    | Eq (s,t) -> term_to_string s ^ "= " ^ term_to_string t