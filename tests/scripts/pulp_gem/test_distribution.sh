#!/bin/bash

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "gem" || exit 23

cleanup() {
  pulp gem repository destroy --name "cli_test_gem_repository" || true
  pulp gem remote destroy --name "cli_test_gem_remote" || true
  pulp gem distribution destroy --name "cli_test_gem_distro" || true
  pulp orphan cleanup || true
}
trap cleanup EXIT

if [ "$VERIFY_SSL" = "false" ]
then
  curl_opt="-k"
else
  curl_opt=""
fi

expect_succ pulp gem remote create --name "cli_test_gem_remote" --url "$GEM_REMOTE_URL"
expect_succ pulp gem repository create --name "cli_test_gem_repository"
expect_succ pulp gem repository sync --repository "cli_test_gem_repository" --remote "cli_test_gem_remote"
expect_succ pulp gem publication create --repository "cli_test_gem_repository"
PUBLICATION_HREF=$(echo "$OUTPUT" | jq -r .pulp_href)

expect_succ pulp gem distribution create \
  --name "cli_test_gem_distro" \
  --base-path "cli_test_gem_distro" \
  --publication "$PUBLICATION_HREF"
HREF="$(echo "$OUTPUT" | jq -r '.pulp_href')"
BASE_URL="$(echo "$OUTPUT" | jq -r '.base_url')"

expect_succ curl $curl_opt --head --fail "${BASE_URL}specs.4.8"

expect_succ pulp gem distribution update \
  --distribution "$HREF" \
  --publication ""
expect_succ pulp gem distribution update \
  --distribution "cli_test_gem_distro" \
  --base-path "wrong_path" \
  --repository "cli_test_gem_repository"
expect_succ pulp gem distribution update \
  --distribution "cli_test_gem_distro" \
  --remote "cli_test_gem_remote"

expect_succ pulp gem distribution destroy --distribution "cli_test_gem_distro"
