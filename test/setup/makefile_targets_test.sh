#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MAKEFILE="$ROOT_DIR/Makefile"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

if [[ ! -f "$MAKEFILE" ]]; then
    echo "ASSERTION FAILED: expected Makefile at $MAKEFILE" >&2
    exit 1
fi

assert_contains '.PHONY: all test lint format doctor doctor-json' "$MAKEFILE"
assert_contains 'all: test lint' "$MAKEFILE"
assert_contains 'test:' "$MAKEFILE"
assert_contains 'lint:' "$MAKEFILE"
assert_contains 'format:' "$MAKEFILE"
assert_contains 'doctor:' "$MAKEFILE"
assert_contains 'doctor-json:' "$MAKEFILE"
assert_contains 'bash test/run.sh' "$MAKEFILE"
assert_contains 'bash bin/lint-shell' "$MAKEFILE"
assert_contains 'shfmt -w -i 4' "$MAKEFILE"
# shellcheck disable=SC2016
assert_contains 'bash setup.sh --doctor --profile "$(PROFILE)"' "$MAKEFILE"
# shellcheck disable=SC2016
assert_contains 'bash setup.sh --doctor --json --profile "$(PROFILE)"' "$MAKEFILE"

echo "makefile_targets_test: ok"
