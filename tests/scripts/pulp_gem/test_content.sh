#!/bin/bash

set -eu
# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "gem" || exit 23

cleanup() {
  rm "amber-1.0.0.gem"
  pulp gem repository destroy --name "cli_test_gem_repository" || true
  pulp gem repository destroy --name "cli_test_gem_upload_repository" || true
  pulp orphan cleanup --protection-time 0 || true
}
trap cleanup EXIT

# Test gem upload
wget "https://fixtures.pulpproject.org/gem/gems/amber-1.0.0.gem"
sha256=$(sha256sum "amber-1.0.0.gem" | cut -d' ' -f1)

expect_succ pulp gem repository create --name "cli_test_gem_upload_repository"
expect_succ pulp gem content upload --file "amber-1.0.0.gem" --repository "cli_test_gem_upload_repository"
expect_succ pulp artifact list --sha256 "$sha256"
expect_succ pulp gem content list --checksum "$sha256"
content_href="$(echo "$OUTPUT" | tr '\r\n' ' ' | jq -r .[0].pulp_href)"
expect_succ pulp gem content show --href "$content_href"

expect_succ pulp gem repository create --name "cli_test_gem_repository"
expect_succ pulp gem repository content add --repository "cli_test_gem_repository" --href "$content_href"
expect_succ pulp gem repository content remove --repository "cli_test_gem_repository" --checksum "$sha256"
expect_succ pulp gem repository content modify --repository "cli_test_gem_repository" --add-content "[{\"checksum\":\"$sha256\"}]"
expect_succ pulp gem repository content list --repository "cli_test_gem_repository"
