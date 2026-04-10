PROFILE ?= full

.PHONY: all test lint format doctor doctor-json

all: test lint

test:
	bash test/run.sh

lint:
	bash bin/lint-shell

format:
	shfmt -w -i 4 setup/lib/*.sh bin/lint-shell test/run.sh

doctor:
	bash setup.sh --doctor --profile "$(PROFILE)"

doctor-json:
	bash setup.sh --doctor --json --profile "$(PROFILE)"
