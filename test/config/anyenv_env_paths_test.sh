#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

PLENV_ROOT_DIR="$TMP_HOME/.anyenv/envs/plenv"
RBENV_ROOT_DIR="$TMP_HOME/.anyenv/envs/rbenv"
mkdir -p "$PLENV_ROOT_DIR/bin" "$PLENV_ROOT_DIR/shims"
mkdir -p "$RBENV_ROOT_DIR/bin" "$RBENV_ROOT_DIR/shims"

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "expected to contain: $needle" >&2
        return 1
    fi
}

assert_path_occurs_before() {
    local path_value="$1"
    local first="$2"
    local second="$3"
    local message="$4"
    local normalized_path
    local suffix

    normalized_path=":$path_value:"

    case "$normalized_path" in
    *":$first:"*) ;;
    *)
        echo "ASSERTION FAILED: $message" >&2
        echo "path: $path_value" >&2
        return 1
        ;;
    esac

    suffix="${normalized_path#*:"$first":}"
    case "$suffix" in
    *":$second:"*) ;;
    *)
        echo "ASSERTION FAILED: $message" >&2
        echo "path: $path_value" >&2
        return 1
        ;;
    esac
}

run_posix_env_file() {
    local file="$1"

    # shellcheck disable=SC2016
    env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" sh -c '
        . "$1"
        printf "PLENV_ROOT=%s\n" "${PLENV_ROOT:-}"
        printf "RBENV_ROOT=%s\n" "${RBENV_ROOT:-}"
        printf "PATH=%s\n" "$PATH"
    ' sh "$file"
}

run_zshenv() {
    # shellcheck disable=SC2016
    env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" zsh -df -c '
        source "$1"
        printf "PLENV_ROOT=%s\n" "${PLENV_ROOT:-}"
        printf "RBENV_ROOT=%s\n" "${RBENV_ROOT:-}"
        printf "PATH=%s\n" "$PATH"
    ' zsh "$ROOT_DIR/config/zshenv"
}

for file in \
    "$ROOT_DIR/config/claude_env.sh" \
    "$ROOT_DIR/config/bash_env.sh" \
    "$ROOT_DIR/config/husky/init.sh"; do
    output="$(run_posix_env_file "$file")"
    path_value="$(printf '%s\n' "$output" | sed -n 's/^PATH=//p')"

    assert_contains "$output" "PLENV_ROOT=$PLENV_ROOT_DIR" "$file should export PLENV_ROOT"
    assert_contains "$output" "RBENV_ROOT=$RBENV_ROOT_DIR" "$file should export RBENV_ROOT"
    assert_contains "$path_value" "$PLENV_ROOT_DIR/bin" "$file should add plenv bin"
    assert_contains "$path_value" "$PLENV_ROOT_DIR/shims" "$file should add plenv shims"
    assert_path_occurs_before "$path_value" "$PLENV_ROOT_DIR/shims" "$PLENV_ROOT_DIR/bin" "$file should place plenv shims before bin"
done

zsh_output="$(run_zshenv)"
zsh_path_value="$(printf '%s\n' "$zsh_output" | sed -n 's/^PATH=//p')"

assert_contains "$zsh_output" "PLENV_ROOT=$PLENV_ROOT_DIR" "zshenv should export PLENV_ROOT"
assert_contains "$zsh_output" "RBENV_ROOT=$RBENV_ROOT_DIR" "zshenv should export RBENV_ROOT"
assert_contains "$zsh_path_value" "$PLENV_ROOT_DIR/bin" "zshenv should add plenv bin"
assert_contains "$zsh_path_value" "$PLENV_ROOT_DIR/shims" "zshenv should add plenv shims"
assert_path_occurs_before "$zsh_path_value" "$PLENV_ROOT_DIR/shims" "$PLENV_ROOT_DIR/bin" "zshenv should place plenv shims before bin"

echo "anyenv_env_paths_test: ok"
