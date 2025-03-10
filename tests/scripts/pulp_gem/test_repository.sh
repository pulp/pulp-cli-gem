#!/bin/bash

set -eu
# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "gem" || exit 23

cleanup() {
  pulp gem repository destroy --name "cli_test_gem_repo" || true
  pulp gem remote destroy --name "cli_test_gem_remote1" || true
  pulp gem remote destroy --name "cli_test_gem_remote2" || true
}
trap cleanup EXIT

REMOTE1_HREF="$(pulp gem remote create --name "cli_test_gem_remote1" --url "http://a/" | jq -r '.pulp_href')"
REMOTE2_HREF="$(pulp gem remote create --name "cli_test_gem_remote2" --url "http://b/" | jq -r '.pulp_href')"

expect_succ pulp gem repository list

expect_succ pulp gem repository create --name "cli_test_gem_repo" --description "Test repository for CLI tests"
if pulp debug has-plugin --name "gem" --specifier ">=0.1.0"
then
  expect_succ pulp gem repository update --repository "cli_test_gem_repo" --description "" --remote "cli_test_gem_remote1"
else
  expect_succ pulp gem repository update --repository "cli_test_gem_repo" --description ""
fi
expect_succ pulp gem repository show --repository "cli_test_gem_repo"
if pulp debug has-plugin --name "gem" --specifier ">=0.1.0"
then
  expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = "$REMOTE1_HREF"
  expect_succ pulp gem repository update --repository "cli_test_gem_repo" --remote "$REMOTE2_HREF"
  expect_succ pulp gem repository show --repository "cli_test_gem_repo"
  expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = "$REMOTE2_HREF"
  expect_succ pulp gem repository update --repository "cli_test_gem_repo" --remote ""
  expect_succ pulp gem repository show --repository "cli_test_gem_repo"
  expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = "null"
fi
expect_succ test "$(echo "$OUTPUT" | jq -r '.description')" = ""
expect_succ pulp gem repository list
test "$(echo "$OUTPUT" | jq -r '.|length')" != "0"

if pulp debug has-plugin --name "gem" --specifier ">=0.4.0.dev"
then
  # Remove this condition, once the feature is merged.
  if [ "$(pulp debug openapi operation-ids | jq -r '[.[]|select(startswith("repositories_gem_gem_my_permission"))]|length')" = 1 ]
  then
    expect_succ pulp gem repository role my-permissions --repository "cli_test_gem_repo"
    expect_succ pulp gem repository role list --repository "cli_test_gem_repo"
    expect_succ pulp gem repository role add --role gem.gemrepository_viewer --user admin --repository "cli_test_gem_repo"
    expect_succ pulp gem repository role remove --role gem.gemrepository_viewer --user admin --repository "cli_test_gem_repo"
  fi
fi

expect_succ pulp gem repository destroy --name "cli_test_gem_repo"
