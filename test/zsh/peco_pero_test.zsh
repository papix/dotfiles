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

function stty() { :; }
function zle() { :; }
function bindkey() { :; }
function ag() {
    printf '%s\n' "src/app.ts:42:matched line"
}
function peco() {
    cat >/dev/null || true
    printf '%s\n' "src/app.ts:42:matched line"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

CODE_MOCK_LOG="${tmp_dir}/code.log"
export CODE_MOCK_LOG
cat > "${tmp_dir}/code" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${CODE_MOCK_LOG}"
EOF_MOCK
chmod +x "${tmp_dir}/code"
PATH="${tmp_dir}:${PATH}"

source "$ROOT_DIR/config/zsh/80-peco.zsh"

EDITOR='code --wait'
pero needle

typeset -a code_args
code_args=("${(@f)$(cat "${CODE_MOCK_LOG}")}")
assert_eq "--wait" "${code_args[1]}" "pero should preserve editor sub-arguments"
assert_eq "-g" "${code_args[2]}" "pero should use -g for VS Code family"
assert_eq "src/app.ts:42" "${code_args[3]}" "pero should pass file and line together"

echo "peco_pero_test: ok"
