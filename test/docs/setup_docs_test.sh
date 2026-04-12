#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
README_FILE="$ROOT_DIR/README.md"
SETUP_DOC="$ROOT_DIR/docs/how-to/setup-dev-env.md"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_contains 'bash setup.sh --doctor' "$README_FILE"
assert_contains 'bash setup.sh --dry-run' "$README_FILE"
assert_contains 'Vault: dotfiles' "$README_FILE"
assert_contains 'Item: shared-env' "$README_FILE"
assert_contains '1Password CLI (`op`)' "$SETUP_DOC"
assert_contains 'Field: NPM_TOKEN' "$SETUP_DOC"

echo "setup_docs_test: ok"
