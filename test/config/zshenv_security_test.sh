#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ZSHENV_FILE="$ROOT_DIR/config/zshenv"

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

# 期待: LESS は重複した -R を持たない
assert_contains "export LESS='-FRX'" "$ZSHENV_FILE"
assert_not_contains "export LESS='-FRX -R'" "$ZSHENV_FILE"

# 期待: XDG と履歴ファイルは state/cache 配下を使う
assert_contains 'export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"' "$ZSHENV_FILE"
assert_contains 'export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"' "$ZSHENV_FILE"
assert_contains 'export HISTFILE="${XDG_STATE_HOME}/zsh/history"' "$ZSHENV_FILE"
assert_contains 'export CLAUDE_ENV_FILE="${XDG_CONFIG_HOME}/claude_env.sh"' "$ZSHENV_FILE"
assert_contains 'export DOTFILES_1PASSWORD_VAULT="${DOTFILES_1PASSWORD_VAULT:-dotfiles}"' "$ZSHENV_FILE"

# 期待: VSCode IPC パス検出は find ベースで安全に行う
assert_contains "find /tmp -maxdepth 1 -name 'vscode-ipc-*'" "$ZSHENV_FILE"
assert_contains "sort -rn |" "$ZSHENV_FILE"
assert_contains "cut -d' ' -f2-" "$ZSHENV_FILE"
assert_not_contains "ls /tmp -t | grep 'vscode-ipc'" "$ZSHENV_FILE"

echo "zshenv_security_test: ok"
