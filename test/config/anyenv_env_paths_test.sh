#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_LINK_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$TMP_LINK_HOME"' EXIT

setup_anyenv_home() {
    local target_home="$1"

    mkdir -p "$target_home/.anyenv/envs/plenv/bin" "$target_home/.anyenv/envs/plenv/shims"
    mkdir -p "$target_home/.anyenv/envs/rbenv/bin" "$target_home/.anyenv/envs/rbenv/shims"
}

setup_anyenv_home "$TMP_HOME"
setup_anyenv_home "$TMP_LINK_HOME"

PLENV_ROOT_DIR="$TMP_HOME/.anyenv/envs/plenv"
RBENV_ROOT_DIR="$TMP_HOME/.anyenv/envs/rbenv"
LINK_PLENV_ROOT_DIR="$TMP_LINK_HOME/.anyenv/envs/plenv"
LINK_RBENV_ROOT_DIR="$TMP_LINK_HOME/.anyenv/envs/rbenv"

# bash_env.sh と claude_env.sh が source する env-common.sh をテスト用 config に配置
mkdir -p "$TMP_HOME/.config"
cp "$ROOT_DIR/config/env-common.sh" "$TMP_HOME/.config/env-common.sh"

mkdir -p "$TMP_LINK_HOME/.config"
ln -s "$ROOT_DIR/config/bash_env.sh" "$TMP_LINK_HOME/.config/bash_env.sh"
ln -s "$ROOT_DIR/config/claude_env.sh" "$TMP_LINK_HOME/.config/claude_env.sh"

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

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "unexpected: $needle" >&2
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

run_bash_env_via_symlink() {
    env -i HOME="$TMP_LINK_HOME" PATH="/usr/bin:/bin" BASH_ENV="$TMP_LINK_HOME/.config/bash_env.sh" bash -c '
        printf "PLENV_ROOT=%s\n" "${PLENV_ROOT:-}"
        printf "RBENV_ROOT=%s\n" "${RBENV_ROOT:-}"
        printf "PATH=%s\n" "$PATH"
    '
}

run_claude_env_via_symlink() {
    env -i HOME="$TMP_LINK_HOME" PATH="/usr/bin:/bin" CLAUDE_ENV_FILE="$TMP_LINK_HOME/.config/claude_env.sh" sh -c '
        . "$CLAUDE_ENV_FILE"
        printf "PLENV_ROOT=%s\n" "${PLENV_ROOT:-}"
        printf "RBENV_ROOT=%s\n" "${RBENV_ROOT:-}"
        printf "PATH=%s\n" "$PATH"
    '
}

for file in \
    "$ROOT_DIR/config/claude_env.sh" \
    "$ROOT_DIR/config/bash_env.sh" \
    "$ROOT_DIR/config/husky/init.sh"; do
    output="$(run_posix_env_file "$file")"
    path_value="$(printf '%s\n' "$output" | sed -n 's/^PATH=//p')"

    assert_contains "$output" "PLENV_ROOT=$PLENV_ROOT_DIR" "$file should export PLENV_ROOT"
    assert_contains "$output" "RBENV_ROOT=$RBENV_ROOT_DIR" "$file should export RBENV_ROOT"
    assert_contains "$path_value" "$TMP_HOME/.local/bin" "$file should add local bin"
    assert_contains "$path_value" "$PLENV_ROOT_DIR/bin" "$file should add plenv bin"
    assert_contains "$path_value" "$PLENV_ROOT_DIR/shims" "$file should add plenv shims"
    assert_path_occurs_before "$path_value" "$TMP_HOME/.local/bin" "$PLENV_ROOT_DIR/shims" "$file should prioritize local bin over anyenv shims"
    assert_path_occurs_before "$path_value" "$PLENV_ROOT_DIR/shims" "$PLENV_ROOT_DIR/bin" "$file should place plenv shims before bin"
done

zsh_output="$(run_zshenv)"
zsh_path_value="$(printf '%s\n' "$zsh_output" | sed -n 's/^PATH=//p')"

assert_contains "$zsh_output" "PLENV_ROOT=$PLENV_ROOT_DIR" "zshenv should export PLENV_ROOT"
assert_contains "$zsh_output" "RBENV_ROOT=$RBENV_ROOT_DIR" "zshenv should export RBENV_ROOT"
assert_contains "$zsh_path_value" "$TMP_HOME/.local/bin" "zshenv should add local bin"
assert_contains "$zsh_path_value" "$PLENV_ROOT_DIR/bin" "zshenv should add plenv bin"
assert_contains "$zsh_path_value" "$PLENV_ROOT_DIR/shims" "zshenv should add plenv shims"
assert_path_occurs_before "$zsh_path_value" "$TMP_HOME/.local/bin" "$PLENV_ROOT_DIR/shims" "zshenv should prioritize local bin over anyenv shims"
assert_path_occurs_before "$zsh_path_value" "$PLENV_ROOT_DIR/shims" "$PLENV_ROOT_DIR/bin" "zshenv should place plenv shims before bin"

for label in bash_env_symlink claude_env_symlink; do
    if [[ "$label" = bash_env_symlink ]]; then
        output="$(run_bash_env_via_symlink)"
    else
        output="$(run_claude_env_via_symlink)"
    fi

    path_value="$(printf '%s\n' "$output" | sed -n 's/^PATH=//p')"
    assert_contains "$output" "PLENV_ROOT=$LINK_PLENV_ROOT_DIR" "$label should resolve env-common.sh from the symlink target"
    assert_contains "$output" "RBENV_ROOT=$LINK_RBENV_ROOT_DIR" "$label should export RBENV_ROOT via the symlink target"
    assert_contains "$path_value" "$TMP_LINK_HOME/.local/bin" "$label should add local bin"
    assert_contains "$path_value" "$LINK_PLENV_ROOT_DIR/bin" "$label should add plenv bin"
    assert_contains "$path_value" "$LINK_PLENV_ROOT_DIR/shims" "$label should add plenv shims"
done

TMP_MISSING_COMMON_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$TMP_LINK_HOME" "$TMP_MISSING_COMMON_HOME"' EXIT
cp "$ROOT_DIR/config/bash_env.sh" "$TMP_MISSING_COMMON_HOME/bash_env.sh"
cp "$ROOT_DIR/config/claude_env.sh" "$TMP_MISSING_COMMON_HOME/claude_env.sh"

missing_bash_output="$(env -i HOME="$TMP_MISSING_COMMON_HOME/home" PATH="/usr/bin:/bin" BASH_ENV="$TMP_MISSING_COMMON_HOME/bash_env.sh" bash -c 'printf "OK\n"' 2>&1)"
assert_contains "$missing_bash_output" "OK" "bash_env should not abort when env-common.sh is missing"
assert_not_contains "$missing_bash_output" "No such file" "bash_env should not emit missing env-common.sh errors"

missing_claude_output="$(env -i HOME="$TMP_MISSING_COMMON_HOME/home" PATH="/usr/bin:/bin" CLAUDE_ENV_FILE="$TMP_MISSING_COMMON_HOME/claude_env.sh" sh -c '. "$CLAUDE_ENV_FILE"; printf "OK\n"' 2>&1)"
assert_contains "$missing_claude_output" "OK" "claude_env should not abort when env-common.sh is missing"
assert_not_contains "$missing_claude_output" "No such file" "claude_env should not emit missing env-common.sh errors"

echo "anyenv_env_paths_test: ok"
