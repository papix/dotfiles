#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LINT_SCRIPT="$ROOT_DIR/bin/lint-shell"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_executable() {
    local file="$1"
    if [[ ! -x "$file" ]]; then
        echo "ASSERTION FAILED: expected executable file $file" >&2
        return 1
    fi
}

# 期待: shellcheck実行スクリプトを提供する
assert_executable "$LINT_SCRIPT"
assert_contains 'git ls-files' "$LINT_SCRIPT"
assert_contains 'Linting test scripts' "$LINT_SCRIPT"
assert_contains 'shfmt -d' "$LINT_SCRIPT"
assert_contains 'SC1091,SC2034' "$LINT_SCRIPT"
assert_contains 'SC1090,SC2016,SC2329' "$LINT_SCRIPT"

# 期待: スクリプトが正常終了する
"$LINT_SCRIPT"

echo "lint_shell_test: ok"
