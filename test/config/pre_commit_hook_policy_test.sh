#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT_DIR/config/git/template/hooks/pre-commit"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: pre-commitはshellcheck(lint-shell)を実行する
assert_contains "\"\$ROOT_DIR/bin/lint-shell\"" "$HOOK"
assert_contains '[lint-shell] Running shellcheck suite...' "$HOOK"

# 期待: SKIPでlint-shell/shellcheckを個別スキップできる
assert_contains 'SKIP:-' "$HOOK"
assert_contains 'lint-shell' "$HOOK"
assert_contains 'shellcheck' "$HOOK"
assert_not_contains '--no-verify' "$HOOK"

echo "pre_commit_hook_policy_test: ok"
