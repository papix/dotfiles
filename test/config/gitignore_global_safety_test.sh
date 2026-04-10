#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="$ROOT_DIR/config/git/gitignore_global"

assert_not_contains_line() {
    local needle="$1"
    if grep -Fxq -- "$needle" "$TARGET"; then
        echo "ASSERTION FAILED: gitignore_global must not contain: $needle" >&2
        exit 1
    fi
}

assert_contains_line() {
    local needle="$1"
    if ! grep -Fxq -- "$needle" "$TARGET"; then
        echo "ASSERTION FAILED: gitignore_global must contain: $needle" >&2
        exit 1
    fi
}

assert_contains_line "/HEAD"
assert_not_contains_line "/config"
assert_not_contains_line "/hooks"
assert_not_contains_line "/objects"
assert_not_contains_line "/refs"

echo "gitignore_global_safety_test: ok"
