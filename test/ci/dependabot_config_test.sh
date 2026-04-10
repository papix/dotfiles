#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEPENDABOT_FILE="$ROOT_DIR/.github/dependabot.yml"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

if [[ ! -f "$DEPENDABOT_FILE" ]]; then
    echo "ASSERTION FAILED: expected dependabot file $DEPENDABOT_FILE" >&2
    exit 1
fi

assert_contains 'version: 2' "$DEPENDABOT_FILE"
assert_contains 'package-ecosystem: "github-actions"' "$DEPENDABOT_FILE"
assert_contains 'directory: "/"' "$DEPENDABOT_FILE"
assert_contains 'interval: "weekly"' "$DEPENDABOT_FILE"
assert_contains 'target-branch: "main"' "$DEPENDABOT_FILE"
assert_contains 'open-pull-requests-limit:' "$DEPENDABOT_FILE"

echo "dependabot_config_test: ok"
