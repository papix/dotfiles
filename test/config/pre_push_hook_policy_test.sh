#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT_DIR/config/git/template/hooks/pre-push"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"

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

# 期待: pre-push フックが存在し、gitleaks を実行する
assert_file_exists "$HOOK"
assert_contains 'SKIP:-' "$HOOK"
assert_contains 'gitleaks' "$HOOK"
assert_contains '--log-opts' "$HOOK"
assert_contains 'while read -r local_ref local_sha remote_ref remote_sha' "$HOOK"

# 期待: setup_git_config で pre-push も template 配置される
assert_contains 'set_config_file "/config/git/template/hooks/pre-push"' "$COMMON_LIB"
assert_contains 'chmod +x "${HOME}/.config/git/template/hooks/pre-push"' "$COMMON_LIB"

echo "pre_push_hook_policy_test: ok"
