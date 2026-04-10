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

function assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if ! print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected to contain: ${needle}" >&2
        echo "  actual            : ${haystack}" >&2
        return 1
    fi
}

function assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected to not contain: ${needle}" >&2
        echo "  actual                : ${haystack}" >&2
        return 1
    fi
}

function stty() { :; }
function zle() { :; }
function bindkey() {
    printf '%s\n' "${(j:\t:)@}" >> "${BINDKEY_MOCK_LOG}"
}

function inside-git-repository() {
    return "${INSIDE_GIT_REPO:-0}"
}

function ag() {
    printf '%s\n' "z.txt" "a space.txt"
}

function peco() {
    cat >/dev/null || true
    if [[ -n "${PECO_OUTPUT:-}" ]]; then
        printf '%s\n' "${(@f)PECO_OUTPUT}"
    fi
}

tmp_dir="$(mktemp -d)"
NVIM_MOCK_LOG="${tmp_dir}/nvim.log"
BINDKEY_MOCK_LOG="${tmp_dir}/bindkey.log"
ERR_LOG="${tmp_dir}/peco_file_less_test.err"
export NVIM_MOCK_LOG BINDKEY_MOCK_LOG
cat > "${tmp_dir}/nvim" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${NVIM_MOCK_LOG}"
EOF_MOCK
chmod +x "${tmp_dir}/nvim"
PATH="${tmp_dir}:${PATH}"
trap 'rm -rf "${tmp_dir}"' EXIT

source "$ROOT_DIR/config/zsh/80-peco.zsh"

# 期待: 新しい widget が存在する
whence -w peco-file-less >/dev/null
assert_contains "^g\\tpeco-file-less" "$(cat "${BINDKEY_MOCK_LOG}")" "Ctrl+G should be bound to peco-file-less"
assert_contains "^[f\\tpeco-file-less" "$(cat "${BINDKEY_MOCK_LOG}")" "Alt+F should be bound to peco-file-less"
assert_not_contains "27;6;70~" "$(cat "${BINDKEY_MOCK_LOG}")" "Ctrl+Shift+F sequence should be removed"

# 期待: BUFFER なしなら nvim を閲覧専用で起動
INSIDE_GIT_REPO=0
PECO_OUTPUT=$'file1.txt\ndir/file2.txt'
BUFFER=""
: > "${NVIM_MOCK_LOG}"
peco-file-less
typeset -a nvim_args
nvim_args=("${(@f)$(cat "${NVIM_MOCK_LOG}")}")
assert_eq "-R" "${nvim_args[1]}" "nvim should run in readonly mode"
assert_eq "-n" "${nvim_args[2]}" "nvim should disable swapfile"
assert_eq "-i" "${nvim_args[3]}" "nvim should disable shada file"
assert_eq "NONE" "${nvim_args[4]}" "nvim shada file should be NONE"
assert_eq "-c" "${nvim_args[5]}" "nvim should apply readonly lock after startup"
assert_eq "setlocal readonly nomodifiable nomodified" "${nvim_args[6]}" "nvim should lock buffer after init.vim is loaded"
assert_eq "--" "${nvim_args[7]}" "nvim should receive -- separator"
assert_eq "file1.txt" "${nvim_args[8]}" "first selected file should be passed to nvim"
assert_eq "dir/file2.txt" "${nvim_args[9]}" "second selected file should be passed to nvim"

# 期待: BUFFER ありならコマンドラインへ追記
INSIDE_GIT_REPO=0
PECO_OUTPUT=$'a space.txt\nplain.txt'
BUFFER="echo"
: > "${NVIM_MOCK_LOG}"
peco-file-less
assert_contains "echo" "$BUFFER" "buffer should keep original command"
assert_contains "a\\ space.txt" "$BUFFER" "buffer should escape spaces"
assert_contains "plain.txt" "$BUFFER" "buffer should include plain file"
assert_eq "" "$(cat "${NVIM_MOCK_LOG}")" "nvim should not be called when BUFFER exists"

# 期待: Git リポジトリ外なら失敗
INSIDE_GIT_REPO=1
PECO_OUTPUT="file.txt"
BUFFER=""
if peco-file-less 2>"${ERR_LOG}"; then
    echo "ASSERTION FAILED: peco-file-less should fail outside git repo" >&2
    exit 1
fi
assert_contains "Ctrl+G" "$(cat "${ERR_LOG}")" "error message should mention Ctrl+G"

echo "peco_file_less_test: ok"
