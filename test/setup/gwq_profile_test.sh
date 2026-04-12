#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FULL_BREWFILE="$ROOT_DIR/Brewfile"
MINIMAL_BREWFILE="$ROOT_DIR/Brewfile.minimal"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fx -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -Fx -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains 'tap "d-kuro/tap"' "$FULL_BREWFILE"
assert_contains 'brew "gwq"' "$FULL_BREWFILE"
assert_not_contains 'brew "gwq"' "$MINIMAL_BREWFILE"

echo "gwq_profile_test: ok"
