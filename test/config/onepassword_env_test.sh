#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_BIN="$TMP_HOME/.local/bin"
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_BIN"

cat >"$TMP_BIN/op" <<'EOF'
#!/usr/bin/env sh
if [ "$1" = "read" ] && [ "$2" = "op://dotfiles/shared-env/NPM_TOKEN" ]; then
    printf 'token-from-1password'
    exit 0
fi
exit 1
EOF
chmod +x "$TMP_BIN/op"

cat >"$TMP_BIN/gh" <<'EOF'
#!/usr/bin/env sh
printf 'token-from-gh'
EOF
chmod +x "$TMP_BIN/gh"

cat >"$TMP_BIN/find" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x "$TMP_BIN/find"

# bash_env.sh と claude_env.sh が source する env-common.sh をテスト用 config に配置
mkdir -p "$TMP_HOME/.config"
cp "$ROOT_DIR/config/env-common.sh" "$TMP_HOME/.config/env-common.sh"

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

assert_path_starts_with() {
    local path_value="$1"
    local expected_prefix="$2"
    local message="$3"

    case "$path_value" in
    "$expected_prefix" | "$expected_prefix":*)
        ;;
    *)
        echo "ASSERTION FAILED: $message" >&2
        echo "actual path: $path_value" >&2
        return 1
        ;;
    esac
}

run_posix_env_file() {
    local file="$1"
    local path_value="$2"
    local autoload_value="${3:-0}"

    env -i HOME="$TMP_HOME" PATH="$path_value" DOTFILES_1PASSWORD_AUTOLOAD="$autoload_value" sh -c '
        . "$1"
        printf "NPM_TOKEN=%s\n" "${NPM_TOKEN:-}"
        printf "XDG_CACHE_HOME=%s\n" "${XDG_CACHE_HOME:-}"
        printf "PATH=%s\n" "$PATH"
        printf "DOTFILES_1PASSWORD_AUTOLOAD=%s\n" "${DOTFILES_1PASSWORD_AUTOLOAD:-}"
    ' sh "$file"
}

set_stale_mtime() {
    local target_file="$1"
    local timestamp=""

    timestamp="$(date -d '2 days ago' '+%Y%m%d%H%M.%S' 2>/dev/null || true)"
    if [[ -z "$timestamp" ]]; then
        timestamp="$(date -v-2d '+%Y%m%d%H%M.%S' 2>/dev/null || true)"
    fi

    if [[ -z "$timestamp" ]]; then
        echo "ASSERTION FAILED: failed to compute stale timestamp" >&2
        return 1
    fi

    touch -t "$timestamp" "$target_file"
}

for file in \
    "$ROOT_DIR/config/bash_env.sh" \
    "$ROOT_DIR/config/claude_env.sh"; do
    output="$(run_posix_env_file "$file" "/usr/bin:/bin")"
    assert_contains "$output" 'NPM_TOKEN=' "$file should not prompt 1Password by default"
    assert_contains "$output" 'DOTFILES_1PASSWORD_AUTOLOAD=0' "$file should default 1Password autoload to opt-in"
    assert_contains "$output" "XDG_CACHE_HOME=$TMP_HOME/.cache" "$file should set XDG cache home"
    assert_contains "$output" "$TMP_HOME/.local/bin" "$file should add local bin"
    path_value="$(printf '%s\n' "$output" | awk -F= '/^PATH=/{print substr($0,6)}')"
    assert_path_starts_with "$path_value" "$TMP_HOME/.local/bin" "$file should prioritize local bin"

    autoload_output="$(run_posix_env_file "$file" "/usr/bin:/bin" "1")"
    assert_contains "$autoload_output" 'NPM_TOKEN=token-from-1password' "$file should load NPM_TOKEN from 1Password when autoload is enabled"
done

cache_file="$TMP_HOME/.cache/dotfiles/npm-token"
if [[ "$(cat "$cache_file")" != 'token-from-1password' ]]; then
    echo "ASSERTION FAILED: expected 1Password token cache to be written" >&2
    exit 1
fi

printf 'token-from-cache' >"$cache_file"
cache_output="$(run_posix_env_file "$ROOT_DIR/config/bash_env.sh" "/usr/bin:/bin")"
assert_contains "$cache_output" 'NPM_TOKEN=token-from-cache' 'bash_env should fall back to cached NPM_TOKEN'

printf 'stale-token' >"$cache_file"
set_stale_mtime "$cache_file"
for file in \
    "$ROOT_DIR/config/bash_env.sh" \
    "$ROOT_DIR/config/claude_env.sh"; do
    stale_output="$(run_posix_env_file "$file" "/usr/bin:/bin")"
    assert_contains "$stale_output" 'NPM_TOKEN=token-from-gh' "$file should refresh stale cache via gh even when find is unavailable"
done

rm -f "$cache_file"
zsh_output="$(env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1/config/zshenv"
    typeset -gA COMMAND_CACHE
    COMMAND_CACHE[op]=1
    source "$1/config/zsh/10-env.zsh"
    printf "NPM_TOKEN=%s\n" "${NPM_TOKEN:-}"
' zsh "$ROOT_DIR")"
assert_contains "$zsh_output" 'NPM_TOKEN=' 'zsh startup should not prompt 1Password when cache is absent'

printf 'token-from-cache' >"$cache_file"
zsh_cached_output="$(env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1/config/zshenv"
    typeset -gA COMMAND_CACHE
    COMMAND_CACHE[op]=1
    source "$1/config/zsh/10-env.zsh"
    printf "NPM_TOKEN=%s\n" "${NPM_TOKEN:-}"
' zsh "$ROOT_DIR")"
assert_contains "$zsh_cached_output" 'NPM_TOKEN=token-from-cache' 'zsh should load cached NPM_TOKEN during startup'

printf 'stale-token' >"$cache_file"
set_stale_mtime "$cache_file"
zsh_stale_output="$(env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" zsh -df -c '
    source "$1/config/zshenv"
    typeset -gA COMMAND_CACHE
    COMMAND_CACHE[gh]=1
    source "$1/config/zsh/10-env.zsh"
    printf "NPM_TOKEN=%s\n" "${NPM_TOKEN:-}"
' zsh "$ROOT_DIR")"
assert_contains "$zsh_stale_output" 'NPM_TOKEN=token-from-gh' 'zsh should refresh stale cached NPM_TOKEN via gh without relying on find'

echo "onepassword_env_test: ok"
