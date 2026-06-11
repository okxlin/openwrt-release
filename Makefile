SHELL := /usr/bin/env bash

.PHONY: lint lint-shell lint-yaml lint-structure qa imagebuilder source-build

lint: lint-shell lint-yaml lint-structure

lint-shell:
	@bash scripts/check-env.sh --mode shell

lint-yaml:
	@bash scripts/check-env.sh --mode yaml

lint-structure:
	@bash scripts/check-env.sh --mode structure

qa:
	@bash scripts/check-env.sh --mode all

PROFILE ?= configs/imagebuilder/example-x86_64.env

imagebuilder:
	@bash scripts/build-imagebuilder.sh $(PROFILE)

CONFIG_FILE ?= configs/source/example-x86_64.config

source-build:
	@bash scripts/build-source.sh $(CONFIG_FILE)
