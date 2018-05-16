# CS 6861 Final Project
# Daniel Sainati
# dhs253


This is a tool which will decide equivalence between two terms in 
Kleene Algebra coalgebraically, generating a bisimulation between the 
terms to determine equivalence. 

To build the project, run `make`, and then run `./ka` to launch the executable.
The project requires OCaml version 4.04.2, and depends on ocamlyacc/ocamllex, 
ocamlfind, ocamlbuild and batteries-included, which can be installed using 
opam: `opam install batteries`.

At the suggestion of Professor Kozen, the parser, lexer and AST were based on 
those used for the KATLite project found [here](http://www.cs.cornell.edu/Projects/KAT/KATlite.zip).