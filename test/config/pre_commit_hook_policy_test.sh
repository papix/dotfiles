#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT_DIR/config/git/template/hooks/pre-commit"
CONFIG="$ROOT_DIR/.pre-commit-config.yaml"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

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

# 期待: pre-commit は絶対パスなしで prek に委譲する
assert_file_exists "$HOOK"
assert_contains 'hook-impl' "$HOOK"
assert_contains '--hook-type=pre-commit' "$HOOK"
assert_contains '--skip-on-missing-config' "$HOOK"
assert_contains 'mise exec prek -- prek' "$HOOK"
assert_not_contains '/home/papix/' "$HOOK"
assert_not_contains '--no-verify' "$HOOK"

# 期待: このリポジトリの prek 設定で lint-shell と gitleaks を実行する
assert_file_exists "$CONFIG"
assert_contains 'id: lint-shell' "$CONFIG"
assert_contains 'entry: bash bin/lint-shell' "$CONFIG"
assert_contains 'id: gitleaks' "$CONFIG"
assert_contains 'entry: gitleaks protect --staged --verbose --redact' "$CONFIG"
assert_contains 'pass_filenames: false' "$CONFIG"
assert_contains 'always_run: true' "$CONFIG"

echo "pre_commit_hook_policy_test: ok"
