#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DARWIN_FULL="$ROOT_DIR/setup/profiles/darwin-full.txt"
DARWIN_MINIMAL="$ROOT_DIR/setup/profiles/darwin-minimal.txt"
LINUX_FULL="$ROOT_DIR/setup/profiles/linux-full.txt"
LINUX_MINIMAL="$ROOT_DIR/setup/profiles/linux-minimal.txt"

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

assert_contains 'd-kuro/tap/gwq' "$DARWIN_FULL"
assert_contains 'd-kuro/tap/gwq' "$LINUX_FULL"
assert_not_contains 'd-kuro/tap/gwq' "$DARWIN_MINIMAL"
assert_not_contains 'd-kuro/tap/gwq' "$LINUX_MINIMAL"

echo "gwq_profile_test: ok"
