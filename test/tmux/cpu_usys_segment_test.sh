#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/cpu_usys.sh"

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual  : $actual" >&2
        exit 1
    fi
}

# shellcheck source=/dev/null
source "$SEGMENT"

tp_shell_is_linux() { return 0; }
tp_shell_is_macos() { return 1; }

top() {
    cat <<'EOF'
%Cpu(s): 1.9 us, 3.3 sy,  0.0 ni, 94.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
EOF
}

low_output="$(run_segment)"
assert_eq "usr: 1.9 sys: 3.3" "$low_output" "single-digit values should be left-padded to width 4"

top() {
    cat <<'EOF'
%Cpu(s): 100.0 us, 0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
EOF
}

high_output="$(run_segment)"
assert_eq "usr:99.9 sys: 0.0" "$high_output" "values should stay within 4-char width"

echo "cpu_usys_segment_test: ok"
