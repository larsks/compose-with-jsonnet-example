all: compose.yaml

compose.yaml: compose.jsonnet node.libsonnet
	jsonnet -o $@ $<

clean:
	rm -f compose.yaml

test: compose.yaml
	pipenv run pytest -v
