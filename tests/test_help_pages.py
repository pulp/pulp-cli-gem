import typing as t

import click
import pytest
from click.testing import CliRunner
from packaging.version import parse as parse_version
from pulp_cli import __version__ as PULP_CLI_VERSION
from pulp_cli import load_plugins, main
from pytest_subtests.plugin import SubTests

load_plugins()


def traverse_commands(command: click.Command, args: t.List[str]) -> t.Iterator[t.List[str]]:
    yield args

    if isinstance(command, click.Group):
        for name, sub in command.commands.items():
            yield from traverse_commands(sub, args + [name])

        params = command.params
        if params:
            if "--type" in params[0].opts:
                # iterate over commands with specific context types
                assert isinstance(params[0].type, click.Choice)
                for context_type in params[0].type.choices:
                    yield args + ["--type", context_type]

                    for name, sub in command.commands.items():
                        yield from traverse_commands(sub, args + ["--type", context_type, name])


@pytest.fixture
def no_api(monkeypatch: pytest.MonkeyPatch) -> None:
    @property  # type: ignore
    def getter(self: t.Any) -> None:
        pytest.fail("Invalid access to 'PulpContext.api'.", pytrace=False)

    monkeypatch.setattr("pulp_glue.common.context.PulpContext.api", getter)


@pytest.mark.help_page
def test_access_help(no_api: None, subtests: SubTests) -> None:
    """Test, that all help screens are accessible without touching the api property."""
    if parse_version(PULP_CLI_VERSION) < parse_version("0.24"):
        pytest.skip("This test is incompatible with older cli versions.")

    runner = CliRunner()
    for args in traverse_commands(main.commands["gem"], ["gem"]):
        with subtests.test(msg=" ".join(args)):
            result = runner.invoke(main, args + ["--help"], catch_exceptions=False)

            if result.exit_code == 2:
                assert (
                    "not available in this context" in result.stdout
                    or "not available in this context" in result.stderr
                )
            else:
                assert result.exit_code == 0
                assert result.stdout.startswith("Usage:") or result.stdout.startswith(
                    "DeprecationWarning:"
                )
