open Batteries

type id = string

type term =
| Act of id
| Plus of term * term
| Times of term * term
| Star of term
| Zero
| One

type equation = term * term

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
  | Plus (x, y) -> protect x ^ " + " ^ protect y
  | Times (x, y) -> protect x ^ " " ^ protect y
  | Star x -> protect x ^ "*"
  | Zero -> "0"
  | One -> "1"

let eqn_to_string ((s,t) : equation) = term_to_string s ^ " = " ^ term_to_string t

(* Simplifies a term by eliminating unnecessary zeroes and ones *)
let rec simplify (t : term) : term = 
  match t with 
  | Act x -> Act x
  | Zero -> Zero
  | One -> One
  | Plus (e1, e2) -> simplify_plus e1 e2
  | Times (e1, e2) -> simplify_times e1 e2
  | Star e -> simplify_star e

and simplify_plus (e1 : term) (e2 : term) : term = 
  let e1' = simplify e1 in 
  let e2' = simplify e2 in 
  let combine3 (e1, e2, e3) : term = 
    let str1 = term_to_string e1 in 
    let str2 = term_to_string e2 in 
    let str3 = term_to_string e3 in 
    if str1 = str2 && str2 = str3 then e1
    else if str1 = str2 then Plus(e1, e3) 
    else if str2 = str3 then Plus(e1, e2)
    else if str3 = str1 then Plus(e2, e3)
    else Plus(Plus(e1, e2), e3) in 

  match e1', e2' with 
  | _, Zero -> e1'
  | Zero, _ -> e2'
  | One, One -> One
  | Plus (e1, e2), e3 -> combine3 (e1, e2, e3)
  | e1, Plus (e2, e3) -> combine3 (e1, e2, e3)
  | e1, e2 when term_to_string e1 = term_to_string e2 -> e1
  | _, _ -> Plus (e1', e2')

and simplify_times (e1 : term) (e2 : term) : term = 
  let e1' = simplify e1 in 
  let e2' = simplify e2 in 
  match e1', e2' with 
  | _, One -> e1'
  | One, _ -> e2'
  | Zero, _ -> Zero
  | _, Zero -> Zero
  | _, _ -> Times (e1', e2')

and simplify_star (e : term) : term = 
  let e' = simplify e in
  match e' with 
  | Zero -> One
  | One -> One
  | _ -> Star e'

module StringSet = Set.Make(String)

let rec vars : term -> StringSet.t = function
  | Zero -> StringSet.empty
  | One -> StringSet.empty
  | Act x -> StringSet.singleton x
  | Times (e1, e2)
  | Plus (e1, e2) -> StringSet.union (vars e1) (vars e2)
  | Star e -> vars e

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