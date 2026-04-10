#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT_DIR/.github/workflows/ci.yml"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_matches() {
    local pattern="$1"
    local file="$2"
    if ! grep -E -- "$pattern" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to match pattern '$pattern' in $file" >&2
        return 1
    fi
}

if [[ ! -f "$WORKFLOW" ]]; then
    echo "ASSERTION FAILED: expected workflow file $WORKFLOW" >&2
    exit 1
fi

assert_contains 'on:' "$WORKFLOW"
assert_contains 'pull_request:' "$WORKFLOW"
assert_contains 'push:' "$WORKFLOW"
assert_contains '      - main' "$WORKFLOW"
assert_not_contains '      - master' "$WORKFLOW"
assert_contains 'permissions:' "$WORKFLOW"
assert_contains 'contents: read' "$WORKFLOW"
assert_contains 'concurrency:' "$WORKFLOW"
assert_contains 'cancel-in-progress: true' "$WORKFLOW"
assert_contains 'strategy:' "$WORKFLOW"
assert_contains 'matrix:' "$WORKFLOW"
assert_contains 'os: [ubuntu-latest, macos-latest]' "$WORKFLOW"
assert_contains 'timeout-minutes:' "$WORKFLOW"
assert_matches 'uses:[[:space:]]+actions/checkout@[0-9a-f]{40}' "$WORKFLOW"
assert_not_contains 'uses: actions/checkout@v4' "$WORKFLOW"
assert_contains 'bash test/run.sh' "$WORKFLOW"
assert_contains 'bash bin/lint-shell' "$WORKFLOW"
assert_contains 'shfmt -d' "$WORKFLOW"
assert_contains 'shellcheck shfmt zsh tmux' "$WORKFLOW"
assert_contains 'brew install shellcheck shfmt tmux' "$WORKFLOW"

echo "github_actions_test: ok"
