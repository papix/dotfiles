#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
DARWIN_FILE="$ROOT_DIR/config/zsh/15-platform-darwin.zsh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains '_dotfiles_brew_cache_tmp="${_dotfiles_brew_cache}.tmp.$$"' "$DARWIN_FILE"
assert_contains '_dotfiles_brew_cache_key=opt-homebrew' "$DARWIN_FILE"
assert_contains '_dotfiles_brew_cache_key=usr-local' "$DARWIN_FILE"
assert_contains 'brew-shellenv-darwin-${_dotfiles_brew_cache_key}' "$DARWIN_FILE"
assert_contains 'mv "$_dotfiles_brew_cache_tmp" "$_dotfiles_brew_cache"' "$DARWIN_FILE"
assert_contains 'rm -f "$_dotfiles_brew_cache_tmp"' "$DARWIN_FILE"
assert_contains '[[ -f "$_dotfiles_brew_cache" ]] && source "$_dotfiles_brew_cache"' "$DARWIN_FILE"

echo "darwin_brew_cache_policy_test: ok"
