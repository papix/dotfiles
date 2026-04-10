#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="$ROOT_DIR/.gitignore"

assert_contains_line() {
    local needle="$1"
    if ! grep -Fxq -- "$needle" "$TARGET"; then
        echo "ASSERTION FAILED: .gitignore must contain: $needle" >&2
        exit 1
    fi
}

# 期待: 補完ダンプの生成物をリポジトリ配下で追跡しない
assert_contains_line "config/.zcompdump*"

echo "repo_gitignore_policy_test: ok"
