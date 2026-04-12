#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PLATFORM_LIB="$ROOT_DIR/setup/lib/platform.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mock_temp_dir="$tmp_dir/mock-temp"
font_dir="$tmp_dir/fonts"

set +e
MOCK_TEMP_DIR="$mock_temp_dir" FONT_DIR="$font_dir" PLATFORM_LIB="$PLATFORM_LIB" bash <<'EOF'
set -euo pipefail
source "$PLATFORM_LIB"

verify_sha256() { return 0; }
log_action() { :; }
log_info() { :; }
log_warn() { :; }
log_error() { :; }
handle_error() { return 1; }
mktemp() {
    mkdir -p "$MOCK_TEMP_DIR"
    printf '%s\n' "$MOCK_TEMP_DIR"
}
curl() {
    local out_file=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -o)
            out_file="$2"
            shift 2
            ;;
        *)
            shift
            ;;
        esac
    done

    : >"$out_file"
}
unzip() {
    mkdir -p "HackGen_NF_v2.10.0"
    : >"HackGen_NF_v2.10.0/mock.ttf"
}
fc-cache() { return 1; }

install_hackgen_font "$FONT_DIR" 1
EOF
exit_code=$?
set -e

if [[ "$exit_code" -eq 0 ]]; then
    echo "ASSERTION FAILED: install_hackgen_font should fail when fc-cache fails" >&2
    exit 1
fi

if [[ -d "$mock_temp_dir" ]]; then
    echo "ASSERTION FAILED: temporary directory should be removed even when fc-cache fails" >&2
    exit 1
fi

echo "hackgen_cleanup_test: ok"
