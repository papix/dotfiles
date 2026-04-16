#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/mem_used.sh"

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

tmp_meminfo="$(mktemp)"
trap 'rm -f "$tmp_meminfo"' EXIT

cat <<'EOF' >"$tmp_meminfo"
MemTotal:       1000 kB
MemFree:         100 kB
MemAvailable:    375 kB
Buffers:          50 kB
Cached:          200 kB
EOF

tp_shell_is_linux() { return 0; }
tp_shell_is_macos() { return 1; }

export TMUX_POWERLINE_SEG_MEM_USED_MEMINFO_PATH="$tmp_meminfo"
linux_output="$(run_segment)"
assert_eq "mem: 62.5%" "$linux_output" "linux mem segment should use MemAvailable when present"

tp_shell_is_linux() { return 1; }
tp_shell_is_macos() { return 0; }

pagesize() {
    echo "4096"
}

sysctl() {
    if [[ "${1:-}" == "-n" && "${2:-}" == "hw.memsize" ]]; then
        echo "16384"
        return 0
    fi
    return 1
}

vm_stat() {
    cat <<'EOF'
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free:                               1.
Pages speculative:                       0.
EOF
}

macos_output="$(run_segment)"
assert_eq "mem: 75.0%" "$macos_output" "macOS mem segment should derive used percent from vm_stat"

echo "mem_used_segment_test: ok"
