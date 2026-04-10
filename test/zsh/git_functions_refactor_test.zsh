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

# __git_branch_worktree_path のworktree検出テスト
function test_worktree_path_detection() {
    local tmpdir
    tmpdir=$(mktemp -d)

    # メインリポジトリを作成
    local main_repo="${tmpdir}/main"
    mkdir -p "${main_repo}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q

    # worktreeブランチを作成・追加
    local wt_path="${tmpdir}/wt-feature"
    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q

    # worktreeパスが正しく取得できることを確認
    local result
    result=$(cd "${main_repo}" && __git_branch_worktree_path "feature")

    # worktreeにないブランチは空文字を返すことを確認
    local result_none
    result_none=$(cd "${main_repo}" && __git_branch_worktree_path "nonexistent")

    # アサーション失敗時もクリーンアップできるよう結果を後でチェック
    local exit_code=0
    assert_same_path "${wt_path}" "${result}" "__git_branch_worktree_path should return worktree path for checked-out branch" || exit_code=1
    assert_eq "" "${result_none}" "__git_branch_worktree_path should return empty for branch not in worktree" || exit_code=1

    rm -rf "${tmpdir}"
    return ${exit_code}
}

function test_peco_branch_moves_to_worktree() {
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
    mkdir -p "${wt_path}/src"

    function peco() {
        print -r -- "feature"
    }

    BUFFER=""
    CURSOR=0
    cd "${nested_dir}" || exit_code=1

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

function test_worktree_sync_skips_unsafe_entries() {
    local tmpdir
    tmpdir=$(mktemp -d)
    local original_dir="${PWD}"
    local exit_code=0

    local main_repo="${tmpdir}/main"
    local worktree_parent="${tmpdir}/worktrees"
    local wt_path="${worktree_parent}/feature"
    local escaped_source="${tmpdir}/escaped.txt"
    local escaped_dest="${worktree_parent}/escaped.txt"

    mkdir -p "${main_repo}" "${worktree_parent}"
    init_test_repo "${main_repo}"
    git -C "${main_repo}" commit --allow-empty -m "init" -q

    mkdir -p "${main_repo}/config"
    printf '.envrc\nconfig/local.txt\n../escaped.txt\n' > "${main_repo}/.worktree-sync"
    printf 'direnv\n' > "${main_repo}/.envrc"
    printf 'local\n' > "${main_repo}/config/local.txt"
    printf 'escaped\n' > "${escaped_source}"

    git -C "${main_repo}" worktree add -b feature "${wt_path}" -q

    cd "${wt_path}" || exit_code=1
    worktree-sync >/dev/null 2>&1 || exit_code=1

    [[ -f "${wt_path}/.envrc" ]] || {
        echo "ASSERTION FAILED: worktree-sync should copy .envrc" >&2
        exit_code=1
    }
    [[ -f "${wt_path}/config/local.txt" ]] || {
        echo "ASSERTION FAILED: worktree-sync should copy nested file" >&2
        exit_code=1
    }
    assert_not_exists "${escaped_dest}" "worktree-sync should skip unsafe parent traversal entries" || exit_code=1

    cd "${original_dir}" || true
    rm -rf "${tmpdir}"
    return ${exit_code}
}

test_worktree_path_detection
test_peco_branch_moves_to_worktree
test_worktree_sync_skips_unsafe_entries

echo "git_functions_refactor_test: ok"
