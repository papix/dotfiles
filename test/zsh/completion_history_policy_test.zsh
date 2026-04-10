#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
COMPLETION_FILE="$ROOT_DIR/config/zsh/40-completion.zsh"
OPTIONS_FILE="$ROOT_DIR/config/zsh/30-options.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: compinit は dumpfile を指定して初期化する
assert_contains 'autoload -Uz compinit' "$COMPLETION_FILE"
assert_contains 'compinit -d "${ZSH_COMPDUMP}"' "$COMPLETION_FILE"
assert_contains 'typeset -g ZSH_COMPDUMP=' "$COMPLETION_FILE"

# 期待: 履歴オプションを強化する
assert_contains 'setopt share_history' "$OPTIONS_FILE"
assert_contains 'setopt hist_expire_dups_first' "$OPTIONS_FILE"
assert_contains 'setopt hist_ignore_space' "$OPTIONS_FILE"
assert_contains 'setopt hist_verify' "$OPTIONS_FILE"

echo "completion_history_policy_test: ok"
