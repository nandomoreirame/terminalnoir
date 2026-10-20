BATS ?= bats
SCRIPTS := scripts/build scripts/install-vscode scripts/build-gtk-icons $(wildcard scripts/ports/*.sh)

.PHONY: build test lint install-vscode

build:
	scripts/build

test:
	$(BATS) tests

lint:
	shellcheck -x $(SCRIPTS)

install-vscode:
	scripts/install-vscode
