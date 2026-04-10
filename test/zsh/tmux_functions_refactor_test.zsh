#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"

function assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected: ${expected}" >&2
        echo "  actual  : ${actual}" >&2
        return 1
    fi
}

function assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected not to contain: ${needle}" >&2
        echo "  actual                : ${haystack}" >&2
        return 1
    fi
}

tmp_dir="$(mktemp -d)"
home_dir="$tmp_dir/home"
mkdir -p "$home_dir/.ghq/github.com/papix/dotfiles"
trap 'rm -rf "$tmp_dir"' EXIT

export HOME="$home_dir"

# source時の副作用を避ける
unset TMUX
unset SSH_CONNECTION
unset TERM_PROGRAM
unset VSCODE_INJECTION
unset DISABLE_AUTO_TMUX
export PS1=""
typeset -gA COMMAND_CACHE

function tmux() { return 1 }
function ghq() {
    if [[ "${1:-}" == "root" ]]; then
        print -r -- "$HOME/.ghq"
        return 0
    fi
    return 1
}

set +e
source_err_file="$tmp_dir/source.stderr.log"
{ source "$ROOT_DIR/config/zsh/82-tmux.zsh"; } 2>"$source_err_file"
source_exit_code=$?
set -e
source_output="$(cat "$source_err_file")"
assert_eq "0" "$source_exit_code" "sourcing 82-tmux.zsh should not fail under nounset"
assert_not_contains "parameter not set" "$source_output" "sourcing 82-tmux.zsh should not emit nounset warnings"

cd "$HOME/.ghq/github.com/papix/dotfiles"
assert_eq "papix/dotfiles" "$(current-workspace)" "current-workspace should map github.com paths to owner/repo"

assert_eq "default" "$(sanitize_tmux_session_name '---...---')" "sanitize_tmux_session_name should fallback to default"

echo "tmux_functions_refactor_test: ok"
