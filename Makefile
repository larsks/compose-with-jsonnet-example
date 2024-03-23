all: compose.yaml

compose.yaml: compose.jsonnet node.libsonnet
	jsonnet -o $@ $<
