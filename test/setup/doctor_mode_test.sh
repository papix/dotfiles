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

doctor_output="$(bash "$SETUP_SH" --doctor)"
assert_text_contains 'Doctor mode' "$doctor_output"
assert_text_contains 'Profile:' "$doctor_output"
assert_text_contains 'Required commands' "$doctor_output"
assert_text_contains 'Profile file' "$doctor_output"
assert_text_contains 'shfmt:' "$doctor_output"

echo "doctor_mode_test: ok"
