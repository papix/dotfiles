#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GIT_REPO_SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/git_repo.sh"
GIT_REPO_HELPER="$ROOT_DIR/config/tmux-powerline/segments/git_repository_helper.sh"
GIT_STATUS_SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/git_status.sh"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        exit 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        exit 1
    fi
}

assert_contains 'git_repository_helper.sh' "$GIT_REPO_SEGMENT"
assert_contains 'git_repository_helper.sh' "$GIT_STATUS_SEGMENT"
# shellcheck disable=SC2016
assert_contains '${trimmed_repo_path#"$HOME"/.ghq/github.com/}' "$GIT_REPO_HELPER"
# shellcheck disable=SC2016
assert_contains '${trimmed_repo_path#"$HOME"/.ghq/}' "$GIT_REPO_HELPER"
# shellcheck disable=SC2016
assert_not_contains '${trimmed_repo_path#$HOME/.ghq/github.com/}' "$GIT_REPO_HELPER"
# shellcheck disable=SC2016
assert_not_contains '${trimmed_repo_path#$HOME/.ghq/}' "$GIT_REPO_HELPER"

echo "ghq_path_expansion_test: ok"
