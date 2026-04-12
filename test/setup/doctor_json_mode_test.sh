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

json_output="$(bash "$SETUP_SH" --doctor --json)"
assert_text_contains '"mode":"doctor"' "$json_output"
assert_text_contains '"profile":"' "$json_output"
assert_text_contains '"package_files":[' "$json_output"
assert_text_contains '"commands":[' "$json_output"
assert_text_contains '"name":"shfmt"' "$json_output"

set +e
bash "$SETUP_SH" --json >/tmp/setup-json-only.out 2>/tmp/setup-json-only.err
json_only_exit_code=$?
set -e
if [[ "$json_only_exit_code" -eq 0 ]]; then
    echo "ASSERTION FAILED: --json without --doctor should exit non-zero" >&2
    exit 1
fi

json_only_err="$(cat /tmp/setup-json-only.err)"
assert_text_contains '--json can only be used with --doctor' "$json_only_err"

echo "doctor_json_mode_test: ok"
