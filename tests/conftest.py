# from urllib.parse import urljoin

import pytest

pytest_plugins = "pytest_pulp_cli"


@pytest.fixture
def pulp_cli_vars(pulp_cli_vars):
    # PULP_FIXTURES_URL = pulp_cli_vars["PULP_FIXTURES_URL"]
    result = {}
    result.update(pulp_cli_vars)
    result.update(
        {
            # "GEM_REMOTE_URL": urljoin(PULP_FIXTURES_URL, "/gem/"),
            "GEM_REMOTE_URL": "https://repos.fedorapeople.org/pulp/pulp/demo_repos/gems/repo/",
        }
    )
    return result
