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

# 非対話テスト用の最小スタブ
function zle() { return 0 }
function bindkey() { return 0 }
function peco() { cat }

source "$ROOT_DIR/config/zsh/81-git.zsh"

function init_test_repo() {
    local repo_path="$1"

    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "${repo_path}" init -q
    git -C "${repo_path}" config user.name "CI Test"
    git -C "${repo_path}" config user.email "ci@example.invalid"
}

set +e
missing_arg_output="$(git-switch-branch 2>&1)"
missing_arg_exit_code=$?
set -e

assert_eq "1" "$missing_arg_exit_code" "git-switch-branch should return 1 when branch arg is missing"
assert_contains "Usage: git-switch-branch <branch-name>" "$missing_arg_output" "git-switch-branch should print usage when branch arg is missing"

function test_git_switch_branch_checks_out_branch() {
    local tmpdir
    tmpdir=$(mktemp -d)
    local original_dir="$PWD"
    local exit_code=0

    local repo_path="${tmpdir}/repo"
    mkdir -p "${repo_path}"
    init_test_repo "${repo_path}"
    git -C "${repo_path}" commit --allow-empty -m "init" -q

    local default_branch
    default_branch="$(git -C "${repo_path}" symbolic-ref --short HEAD 2>/dev/null)"
    git -C "${repo_path}" checkout -b feature -q
    git -C "${repo_path}" checkout "${default_branch}" -q

    cd "${repo_path}" || exit_code=1
    git-switch-branch feature >/dev/null 2>&1 || exit_code=1

    local current_branch
    current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
    assert_eq "feature" "$current_branch" "git-switch-branch should checkout the selected branch" || exit_code=1

    cd "${original_dir}" || true
    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_peco_branch_checks_out_selected_branch() {
    local tmpdir
    tmpdir=$(mktemp -d)
    local original_dir="$PWD"
    local exit_code=0

    local repo_path="${tmpdir}/repo"
    mkdir -p "${repo_path}"
    init_test_repo "${repo_path}"
    git -C "${repo_path}" commit --allow-empty -m "init" -q

    local default_branch
    default_branch="$(git -C "${repo_path}" symbolic-ref --short HEAD 2>/dev/null)"
    git -C "${repo_path}" checkout -b feature -q
    git -C "${repo_path}" checkout "${default_branch}" -q

    function peco() {
        print -r -- "feature"
    }

    BUFFER=""
    CURSOR=0
    cd "${repo_path}" || exit_code=1

    if ! peco-branch; then
        exit_code=1
    fi

    local current_branch
    current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
    assert_eq "feature" "$current_branch" "peco-branch should checkout the selected branch" || exit_code=1

    cd "${original_dir}" || true
    unfunction peco
    function peco() { cat }
    rm -rf "${tmpdir}"
    return ${exit_code}
}

test_git_switch_branch_checks_out_branch
test_peco_branch_checks_out_selected_branch

echo "git_functions_refactor_test: ok"
