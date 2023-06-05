#!/bin/bash

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "gem" || exit 23

cleanup() {
  pulp gem repository destroy --name "cli_test_gem_repository" || true
  pulp gem remote destroy --name "cli_test_gem_remote" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

pulp gem remote create --name "cli_test_gem_remote" --url "$GEM_REMOTE_URL"
pulp gem repository create --name "cli_test_gem_repository"
pulp gem repository sync --repository "cli_test_gem_repository" --remote "cli_test_gem_remote"

expect_succ pulp gem publication create --repository "cli_test_gem_repository"
PUBLICATION_HREF="$(echo "$OUTPUT" | jq -r .pulp_href)"
expect_succ pulp gem publication destroy --href "$PUBLICATION_HREF"
expect_succ pulp gem publication create --repository "cli_test_gem_repository" --version 0
PUBLICATION_HREF="$(echo "$OUTPUT" | jq -r .pulp_href)"
expect_succ pulp gem publication destroy --href "$PUBLICATION_HREF"
