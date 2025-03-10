#!/bin/bash

set -eu
# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "gem" || exit 23

cleanup() {
  pulp gem remote destroy --name "cli_test_gem_remote" || true
}
trap cleanup EXIT

expect_succ pulp gem remote list

expect_succ pulp gem remote create --name "cli_test_gem_remote" --url "$GEM_REMOTE_URL" --includes '{"panda":null}'

expect_succ pulp gem remote update --remote "cli_test_gem_remote" --policy "on_demand" --prereleases
expect_succ pulp gem remote show --remote "cli_test_gem_remote"
expect_succ pulp gem remote list

expect_succ pulp gem remote destroy --remote "cli_test_gem_remote"
