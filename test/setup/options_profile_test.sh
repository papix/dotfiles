#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SETUP_SH="$ROOT_DIR/setup.sh"

assert_text_contains() {
    local needle="$1"
    local text="$2"
    if ! printf '%s\n' "$text" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected output to contain '$needle'" >&2
        echo "actual output: $text" >&2
        return 1
    fi
}

help_output="$(bash "$SETUP_SH" --help)"
assert_text_contains '--dry-run' "$help_output"
assert_text_contains '--profile' "$help_output"
assert_text_contains '--json' "$help_output"

set +e
bash "$SETUP_SH" --profile=invalid >/tmp/setup-invalid.out 2>/tmp/setup-invalid.err
invalid_exit_code=$?
set -e
if [[ "$invalid_exit_code" -eq 0 ]]; then
    echo "ASSERTION FAILED: invalid --profile should exit non-zero" >&2
    exit 1
fi

minimal_output="$(bash "$SETUP_SH" --dry-run --profile=minimal)"
assert_text_contains 'Dry-run mode enabled' "$minimal_output"
assert_text_contains 'Profile: minimal' "$minimal_output"
assert_text_contains 'Would run: common setup' "$minimal_output"
assert_text_contains 'Would run: platform setup' "$minimal_output"
assert_text_contains 'Would run: local package setup' "$minimal_output"

full_output="$(bash "$SETUP_SH" --dry-run --profile=full)"
assert_text_contains 'Profile: full' "$full_output"
assert_text_contains 'Would run: local package setup' "$full_output"

echo "options_profile_test: ok"
