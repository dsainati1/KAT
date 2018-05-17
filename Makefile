# Makefile
#
# targets are:
# all: rebuild the project (default)
# clean: remove all objects and executables

SOURCES = ast.ml parser.mli parser.ml lexer.ml automata.ml equality.ml main.ml
CLEAN = parser.ml parser.mli lexer.ml *.cmo *.cmx *.cmi *.o 

.PHONY: all clean

all: ka

clean:
	rm -f ka $(CLEAN)

ka: $(SOURCES)
	ocamlfind ocamlc -package batteries -o ka -linkpkg $(SOURCES)

parser.ml: parser.mly
	ocamlyacc parser.mly

parser.mli: parser.mly
	ocamlyacc parser.mly

lexer.ml: parser.ml parser.mli lexer.mll
	ocamllex lexer.mll