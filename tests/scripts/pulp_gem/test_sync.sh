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

cleanup

# Prepare
expect_succ pulp gem remote create --name "cli_test_gem_remote" --url "$GEM_REMOTE_URL"
expect_succ pulp gem repository create --name "cli_test_gem_repository"

# Test without remote (should fail)
expect_fail pulp gem repository sync --repository "cli_test_gem_repository"
# Test with remote
expect_succ pulp gem repository sync --repository "cli_test_gem_repository" --remote "cli_test_gem_remote"

if pulp debug has-plugin --name "gem" --specifier ">=0.0.1.dev"
then
  # Preconfigure remote
  expect_succ pulp gem repository update --repository "cli_test_gem_repository" --remote "cli_test_gem_remote"
  # Test with remote
  expect_succ pulp gem repository sync --repository "cli_test_gem_repository"
fi

# Verify sync
expect_succ pulp gem repository version list --repository "cli_test_gem_repository"
expect_succ test "$(echo "$OUTPUT" | jq -r length)" -eq 2
expect_succ pulp gem repository version show --repository "cli_test_gem_repository" --version 1
expect_succ test "$(echo "$OUTPUT" | jq -r '.content_summary.present."gem.gem".count')" -eq 4

# Test repair the version
expect_succ pulp gem repository version repair --repository "cli_test_gem_repository" --version 1
expect_succ test "$(echo "$OUTPUT" | jq -r '.state')" = "completed"

# Delete version again
expect_succ pulp gem repository version destroy --repository "cli_test_gem_repository" --version 1
