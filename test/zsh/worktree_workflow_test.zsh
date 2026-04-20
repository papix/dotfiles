#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

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

function assert_file_exists() {
    local path="$1"
    local message="$2"
    if [[ ! -e "$path" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  missing: ${path}" >&2
        return 1
    fi
}

function assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  unexpected: ${needle}" >&2
        echo "  actual    : ${haystack}" >&2
        return 1
    fi
}

function zle() { return 0 }
function bindkey() { return 0 }

export HOME="$TMP_DIR/home"
mkdir -p "$HOME/.ghq/github.com/papix/example-repo"

repo_path="$HOME/.ghq/github.com/papix/example-repo"
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "$repo_path" init -q
printf 'hello\n' >"$repo_path/README.md"
git -C "$repo_path" add README.md
git -C "$repo_path" -c user.name=test -c user.email=test@example.com commit -q -m init

unset TMUX
unset SSH_CONNECTION
unset TERM_PROGRAM
unset VSCODE_INJECTION
unset DISABLE_AUTO_TMUX
export PS1=""
typeset -gA COMMAND_CACHE

function tmux() { return 1 }
function ghq() {
    if [[ "${1:-}" == "root" ]]; then
        print -r -- "$HOME/.ghq"
        return 0
    fi
    if [[ "${1:-}" == "list" && "${2:-}" == "--full-path" ]]; then
        print -r -- "$repo_path"
        return 0
    fi
    return 1
}

source "$ROOT_DIR/config/zsh/81-git.zsh"
source "$ROOT_DIR/config/zsh/82-tmux.zsh"

for fn in work work-new work-prune work-ensure-worktree work-worktree-root-path; do
    if ! typeset -f "$fn" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected function ${fn} to be defined" >&2
        exit 1
    fi
done

cd "$repo_path"
target_path="$(work-worktree-root-path feature-foo)"
expected_path="$HOME/.worktrees/github.com/papix/example-repo/feature-foo"
assert_eq "$expected_path" "$target_path" "work-worktree-root-path should use WORKTREE_BASE_DIR fallback with ghq path"

work-new feature-foo >/dev/null 2>&1
assert_eq "$expected_path" "$PWD" "work-new should cd into the created worktree outside tmux"
assert_file_exists "$expected_path/.git" "work-new should create a linked worktree"
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
assert_eq "feature-foo" "$current_branch" "work-new should check out the requested branch inside the new worktree"

cd "$repo_path"
rm -rf "$expected_path"
before_prune="$(git -C "$repo_path" worktree list --porcelain)"
if [[ "$before_prune" != *"$expected_path"* ]]; then
    echo "ASSERTION FAILED: expected stale worktree metadata before prune" >&2
    exit 1
fi

work-prune stale >/dev/null 2>&1

after_prune="$(git -C "$repo_path" worktree list --porcelain)"
assert_not_contains "$expected_path" "$after_prune" "work-prune stale should remove metadata for deleted linked worktrees"

echo "worktree_workflow_test: ok"
