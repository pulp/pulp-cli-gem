
GLUE_PLUGINS=$(notdir $(wildcard pulp-glue-gem/pulp_glue/*))
CLI_PLUGINS=$(notdir $(wildcard pulpcore/cli/*))

info:
	@echo Pulp glue
	@echo plugins: $(GLUE_PLUGINS)
	@echo Pulp CLI
	@echo plugins: $(CLI_PLUGINS)

build:
	cd pulp-glue-gem; pyproject-build -n
	pyproject-build -n

black: format

format:
	isort .
	cd pulp-glue-gem; isort .
	black .

lint:
	find tests .ci -name '*.sh' -print0 | xargs -0 shellcheck -x
	isort -c --diff .
	cd pulp-glue-gem; isort -c --diff .
	black --diff --check .
	flake8
	.ci/scripts/check_cli_dependencies.py
	.ci/scripts/check_click_for_mypy.py
	MYPYPATH=pulp-glue-gem mypy
	cd pulp-glue-gem; mypy
	@echo "🙊 Code 🙈 LGTM 🙉 !"

tests/cli.toml:
	cp $@.example $@
	@echo "In order to configure the tests to talk to your test server, you might need to edit $@ ."

test: | tests/cli.toml
	python3 -m pytest -v tests pulp-glue-gem/tests

livetest: | tests/cli.toml
	python3 -m pytest -v tests pulp-glue-gem/tests -m live

unittest:
	python3 -m pytest -v tests pulp-glue-gem/tests -m "not live"

unittest_glue:
	python3 -m pytest -v pulp-glue-gem/tests -m "not live"
.PHONY: build info black lint test
