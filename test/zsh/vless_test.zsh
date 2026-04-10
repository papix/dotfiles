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

tmp_dir="$(mktemp -d)"
NVIM_MOCK_LOG="${tmp_dir}/nvim.log"
ERR_LOG="${tmp_dir}/vless.err"
export NVIM_MOCK_LOG

cat > "${tmp_dir}/nvim" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${NVIM_MOCK_LOG}"
EOF_MOCK
chmod +x "${tmp_dir}/nvim"
PATH="${tmp_dir}:${PATH}"
trap 'rm -rf "${tmp_dir}"' EXIT

source "$ROOT_DIR/config/zsh/71-pager.zsh"

whence -w vless >/dev/null

if vless 2>"${ERR_LOG}"; then
    echo "ASSERTION FAILED: vless without args should fail" >&2
    exit 1
fi
assert_contains "Usage: vless <file...>" "$(cat "${ERR_LOG}")" "usage should be shown without args"

sample_file="${tmp_dir}/sample.txt"
printf 'hello\n' > "${sample_file}"
: > "${NVIM_MOCK_LOG}"
vless "${sample_file}"

typeset -a nvim_args
nvim_args=("${(@f)$(cat "${NVIM_MOCK_LOG}")}")
assert_eq "-R" "${nvim_args[1]}" "nvim should run in readonly mode"
assert_eq "-n" "${nvim_args[2]}" "nvim should disable swapfile"
assert_eq "-i" "${nvim_args[3]}" "nvim should disable shada file"
assert_eq "NONE" "${nvim_args[4]}" "nvim shada file should be NONE"
assert_eq "-c" "${nvim_args[5]}" "nvim should apply readonly options"
assert_eq "setlocal readonly nomodifiable nomodified autoread" "${nvim_args[6]}" "nvim should enable autoread in readonly mode"
assert_eq "-c" "${nvim_args[7]}" "nvim should define augroup for checktime"
assert_eq "augroup vless_autoread" "${nvim_args[8]}" "nvim should create vless augroup"
assert_eq "-c" "${nvim_args[9]}" "nvim should clear previous autocmd"
assert_eq "autocmd!" "${nvim_args[10]}" "nvim should clear augroup autocmds"
assert_eq "-c" "${nvim_args[11]}" "nvim should set checktime autocmd"
assert_eq "autocmd CursorHold,CursorHoldI,FocusGained,BufEnter * checktime" "${nvim_args[12]}" "nvim should refresh when file changed"
assert_eq "-c" "${nvim_args[13]}" "nvim should end augroup"
assert_eq "augroup END" "${nvim_args[14]}" "nvim should end augroup"
assert_eq "--" "${nvim_args[15]}" "nvim should receive -- separator"
assert_eq "${sample_file}" "${nvim_args[16]}" "target file should be passed to nvim"

echo "vless_test: ok"
