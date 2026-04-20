#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
ENV_FILE="$ROOT_DIR/config/zsh/10-env.zsh"

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
        echo "expected not to contain: $needle" >&2
        return 1
    fi
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/bin"

cat >"$tmp_dir/bin/direnv" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "export" && "${2:-}" == "zsh" ]]; then
    printf '%s\n' 'export DIRENV_TEST_VALUE=1'
    printf '%s\n' 'direnv: unloading' >&2
    printf '%s\n' 'direnv: keep-me' >&2
    exit 0
fi

exit 1
EOF_MOCK
chmod +x "$tmp_dir/bin/direnv"

output="$(PATH="$tmp_dir/bin:/usr/bin:/bin" ENV_FILE="$ENV_FILE" zsh -df -c '
    typeset -gA COMMAND_CACHE
    COMMAND_CACHE[direnv]=1
    source "$ENV_FILE"
    __dotfiles_direnv_hook
    printf "VALUE=%s\n" "${DIRENV_TEST_VALUE:-}"
' 2>&1)"

assert_contains "$output" 'VALUE=1' 'direnv hook should still apply exported environment changes'
assert_contains "$output" 'direnv: keep-me' 'direnv hook should preserve non-noisy stderr lines'
assert_not_contains "$output" 'direnv: unloading' 'direnv hook should suppress unloading noise'

echo "direnv_hook_test: ok"
