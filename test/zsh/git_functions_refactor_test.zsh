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

function normalize_existing_path() {
    local path="$1"
    (
        builtin cd -P -- "$path" >/dev/null 2>&1 && pwd
    )
}

function assert_same_path() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    local normalized_expected
    normalized_expected=$(normalize_existing_path "$expected")
    local normalized_actual
    normalized_actual=$(normalize_existing_path "$actual")

    assert_eq "${normalized_expected}" "${normalized_actual}" "${message}"
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

function assert_not_exists() {
    local path="$1"
    local message="$2"
    if [[ -e "$path" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  path should not exist: ${path}" >&2
        return 1
    fi
}

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

function test_worktree_path_detection() {
    local tmpdir
    tmpdir=$(mktemp -d)

    local main_repo="${tmpdir}/main"
    mkdir -p "${main_repo}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q

    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q

    local result
    result=$(cd "${main_repo}" && __git_branch_worktree_path "feature")

    local result_none
    result_none=$(cd "${main_repo}" && __git_branch_worktree_path "nonexistent")

    local exit_code=0
    assert_same_path "${wt_path}" "${result}" "__git_branch_worktree_path should return worktree path for checked-out branch" || exit_code=1
    assert_eq "" "${result_none}" "__git_branch_worktree_path should return empty for branch not in worktree" || exit_code=1

    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_git_switch_branch_moves_to_worktree() {
    setopt localoptions
    unsetopt chase_links

    local tmpdir
    tmpdir=$(mktemp -d)
    local original_dir="${PWD}"
    local exit_code=0

    local main_repo="${tmpdir}/main"
    mkdir -p "${main_repo}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q

    local nested_dir="${main_repo}/src"
    mkdir -p "${nested_dir}"
    local linked_repo="${tmpdir}/main-link"
    ln -s "${main_repo}" "${linked_repo}"
    local linked_nested_dir="${linked_repo}/src"

    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q
    mkdir -p "${wt_path}/src"

    cd "${linked_nested_dir}" || exit_code=1
    git-switch-branch feature >/dev/null 2>&1 || exit_code=1

    local expected_path="${wt_path}/src"
    assert_same_path "${expected_path}" "${PWD}" "git-switch-branch should move to the selected worktree path" || exit_code=1

    cd "${original_dir}" || true
    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_peco_branch_moves_to_worktree() {
    setopt localoptions
    unsetopt chase_links

    local tmpdir
    tmpdir=$(mktemp -d)
    local original_dir="$PWD"
    local exit_code=0

    local main_repo="${tmpdir}/main"
    mkdir -p "${main_repo}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q

    local nested_dir="${main_repo}/src"
    mkdir -p "${nested_dir}"
    local linked_repo="${tmpdir}/main-link"
    ln -s "${main_repo}" "${linked_repo}"
    local linked_nested_dir="${linked_repo}/src"

    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q
    mkdir -p "${wt_path}/src"

    function peco() {
        print -r -- "feature"
    }

    BUFFER=""
    CURSOR=0
    cd "${linked_nested_dir}" || exit_code=1

    if ! peco-branch; then
        exit_code=1
    fi

    local expected_path="${wt_path}/src"
    assert_same_path "${expected_path}" "${PWD}" "peco-branch should move to the selected worktree path" || exit_code=1

    cd "${original_dir}" || true
    unfunction peco
    function peco() { cat }
    rm -rf "${tmpdir}"
    return ${exit_code}
}

test_worktree_path_detection
test_git_switch_branch_moves_to_worktree
test_peco_branch_moves_to_worktree

echo "git_functions_refactor_test: ok"
