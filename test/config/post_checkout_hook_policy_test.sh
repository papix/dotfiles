#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT_DIR/config/git/template/hooks/post-checkout"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
GITIGNORE_GLOBAL="$ROOT_DIR/config/git/gitignore_global"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

assert_executable() {
    local path="$1"
    if [[ ! -x "$path" ]]; then
        echo "ASSERTION FAILED: expected $path to be executable" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "ASSERTION FAILED: expected $path to not exist" >&2
        return 1
    fi
}

# 期待: post-checkout フックが存在する
assert_file_exists "$HOOK"

# 期待: post-checkout フックが実行権限を持つ
assert_executable "$HOOK"

# 期待: .worktree-sync 読み取りロジックが含まれる
assert_contains '.worktree-sync' "$HOOK"
assert_contains 'git-common-dir' "$HOOK"
assert_contains 'Skipped unsafe path' "$HOOK"

# 期待: setup_git_config で post-checkout も template 配置される
assert_contains 'set_config_file "/config/git/template/hooks/post-checkout"' "$COMMON_LIB"
assert_contains 'chmod +x "${HOME}/.config/git/template/hooks/post-checkout"' "$COMMON_LIB"

# 期待: gitignore_global に .worktree-sync が含まれる
assert_contains '.worktree-sync' "$GITIGNORE_GLOBAL"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

main_repo="$tmp_dir/main"
worktree_parent="$tmp_dir/worktrees"
worktree_path="$worktree_parent/feature"
escaped_source="$tmp_dir/escaped.txt"
escaped_dest="$worktree_parent/escaped.txt"

mkdir -p "$main_repo" "$worktree_parent"
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "$main_repo" init -q
printf 'tracked\n' >"$main_repo/tracked.txt"
git -C "$main_repo" add tracked.txt
git -C "$main_repo" -c user.name=test -c user.email=test@example.com commit -qm init

mkdir -p "$main_repo/config"
printf '.envrc\nconfig/local.txt\n../escaped.txt\n' >"$main_repo/.worktree-sync"
printf 'direnv\n' >"$main_repo/.envrc"
printf 'local\n' >"$main_repo/config/local.txt"
printf 'escaped\n' >"$escaped_source"

mkdir -p "$main_repo/.git/hooks"
if [[ ! "$HOOK" -ef "$main_repo/.git/hooks/post-checkout" ]]; then
    cp "$HOOK" "$main_repo/.git/hooks/post-checkout"
fi
chmod +x "$main_repo/.git/hooks/post-checkout"

git -C "$main_repo" worktree add -b feature "$worktree_path" -q

assert_file_exists "$worktree_path/.envrc"
assert_file_exists "$worktree_path/config/local.txt"
assert_not_exists "$escaped_dest"

echo "post_checkout_hook_policy_test: ok"
