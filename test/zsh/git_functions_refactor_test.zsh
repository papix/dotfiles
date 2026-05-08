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

function test_git_switch_branch_does_not_move_to_worktree() {
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
    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q

    cd "${nested_dir}" || exit_code=1

    set +e
    git-switch-branch feature >/dev/null 2>&1
    local checkout_exit_code=$?
    set -e

    if [[ "$checkout_exit_code" -eq 0 ]]; then
        echo "ASSERTION FAILED: git-switch-branch should not bypass git checkout when branch is checked out in another worktree" >&2
        exit_code=1
    fi
    assert_eq "${nested_dir}" "${PWD}" "git-switch-branch should not cd to another worktree implicitly" || exit_code=1

    cd "${original_dir}" || true
    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_peco_branch_does_not_move_to_worktree() {
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
    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q

    function peco() {
        print -r -- "feature"
    }

    BUFFER=""
    CURSOR=0
    cd "${nested_dir}" || exit_code=1

    peco-branch || exit_code=1

    assert_eq "${nested_dir}" "${PWD}" "peco-branch should not cd to another worktree implicitly" || exit_code=1

    cd "${original_dir}" || true
    unfunction peco
    function peco() { cat }
    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_git_switch_branch_checks_out_normal_branch() {
    local tmpdir
    tmpdir=$(mktemp -d)
    local exit_code=0

    local main_repo="${tmpdir}/main"
    mkdir -p "${main_repo}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q
    git -C "${main_repo}" branch feature

    (
        cd "${main_repo}" || exit 1
        git-switch-branch feature >/dev/null 2>&1
        current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
        assert_eq "feature" "$current_branch" "git-switch-branch should check out a normal branch"
    ) || exit_code=1

    rm -rf "${tmpdir}"
    return ${exit_code}
}

test_git_switch_branch_does_not_move_to_worktree
test_peco_branch_does_not_move_to_worktree
test_git_switch_branch_checks_out_normal_branch

echo "git_functions_refactor_test: ok"
