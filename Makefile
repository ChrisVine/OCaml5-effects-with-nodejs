SOURCES = generators.ml async_funcs.ml examples.ml
OBJECTS = $(SOURCES:%.ml=%.cmo)

.SUFFIXES: .ml .mli .cmo .cmi

.mli.cmi:
	ocamlfind ocamlc -package str,js_of_ocaml,js_of_ocaml-ppx -c $< -I .

.ml.cmo:
	ocamlfind ocamlc -package str,js_of_ocaml,js_of_ocaml-ppx -c $< -I .

all: examples.js

examples.cmo: generators.cmi async_funcs.cmi
async_funcs.cmo: async_funcs.cmi generators.cmi
generators.cmo: generators.cmi

examples.byte: $(OBJECTS)
	ocamlfind ocamlc -package str,js_of_ocaml,js_of_ocaml-ppx \
	-linkpkg -o $@ $^

examples.js: examples.byte
	js_of_ocaml --enable=effects --target-env=nodejs $<

exec: examples.js
	node examples.js

.PHONY: docs
docs:
	ocamldoc -html -d docs *.mli

.PHONY: clean
clean:
	rm -f *.js *.byte *.cmi *.cmo
