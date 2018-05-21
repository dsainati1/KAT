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

If a single term is entered, a minimal DFA is built and a .dot representation of
the DFA is printed to the commandline, and can be viewed using any graphviz tool, such as
[WebGraphviz](http://www.webgraphviz.com/).

If an equation is entered, minimal DFAs for both of them are generated and bisimulated
to determine equivalence for the two terms.

The minimal DFA is built for a term by building an NFA from a term, determinizing it
and then minimizing it.

To build the NFA, each state in the NFA is a term such that state A transitions to B on input
a if B is the Brzozowski derivative of A on a. The Brzozowski derivative is taken of the input term
until the set of all unique derivative chains of that term is found, and then the terms are connected
in the above fashion until an automaton is constructed. A term/state is final if it can accept the empty string
(the E derivative is 1). The start state of the NFA is the state corresponding to the original term. To leverage
nondeterminism, transitions of the form e -> (e1 + e2) on a are separated into two transitions e -> e1 on a and 
e -> e2 on a, allowing e to transition on a nondeterministically. 

The subset construction is used to determinize NFAs, calculating the set of nondeterministic states reachable
from another set and using these two sets as deterministic states. 