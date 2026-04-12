#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
INIT_FILE="$ROOT_DIR/config/zsh/00-init.zsh"
ALIASES_FILE="$ROOT_DIR/config/zsh/60-aliases.zsh"
FUNCTIONS_FILE="$ROOT_DIR/config/zsh/70-functions.zsh"
OPTIONS_FILE="$ROOT_DIR/config/zsh/30-options.zsh"
ZSHENV_FILE="$ROOT_DIR/config/zshenv"
PECO_FILE="$ROOT_DIR/config/zsh/80-peco.zsh"
DARWIN_FILE="$ROOT_DIR/config/zsh/15-platform-darwin.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

# 期待: tree は早期 COMMAND_CACHE に含めない
assert_contains 'tmux peco ag gh op' "$INIT_FILE"
assert_not_contains 'tmux peco ag gh op tree' "$INIT_FILE"
assert_not_contains 'gwq' "$INIT_FILE"

# 期待: ~/.zshrc.alias はローカル互換用途として明記する
assert_contains '# 互換用: ローカル環境で ~/.zshrc.alias が存在する場合のみ従来設定を読み込む' "$INIT_FILE"

# 期待: ag / tree の alias は PATH 確定後の実行に任せて直接定義する
assert_contains "alias ag='ag -S'" "$ALIASES_FILE"
assert_contains "alias tree='tree -N'" "$ALIASES_FILE"
assert_not_contains 'if [[ -n "$COMMAND_CACHE[ag]" ]]; then' "$ALIASES_FILE"
assert_not_contains 'if [[ -n "$COMMAND_CACHE[tree]" ]]; then' "$ALIASES_FILE"

# 期待: sed='gsed' は macOS専用定義に一本化する
assert_not_contains "alias sed='gsed'" "$ALIASES_FILE"
assert_contains "alias sed='gsed'" "$DARWIN_FILE"

# 期待: copy-to-clipboard の一時変数は local 宣言し、stdin はストリームで処理する
assert_contains 'local external b64_payload' "$FUNCTIONS_FILE"
assert_contains "b64_payload=\$(base64 | tr -d '\\n')" "$FUNCTIONS_FILE"

# 期待: no_global_rcs は zshenv 側で有効にする
assert_not_contains 'setopt no_global_rcs' "$OPTIONS_FILE"
assert_contains 'setopt no_global_rcs' "$ZSHENV_FILE"
assert_contains 'export HISTFILE="${XDG_STATE_HOME}/zsh/history"' "$ZSHENV_FILE"
assert_contains 'export DOTFILES_1PASSWORD_VAULT="${DOTFILES_1PASSWORD_VAULT:-dotfiles}"' "$ZSHENV_FILE"

# 期待: pero は EDITOR を配列化して実行する
assert_contains 'editor_cmd=(${(z)EDITOR})' "$PECO_FILE"
assert_contains 'command "${editor_cmd[@]}" -g "${file}:${line}"' "$PECO_FILE"

echo "config_quality_policy_test: ok"
