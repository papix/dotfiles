#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/date_compact.sh"

assert_equal() {
    local expected="$1"
    local actual="$2"

    if [[ "$actual" != "$expected" ]]; then
        echo "ASSERTION FAILED: expected '$expected', got '$actual'" >&2
        return 1
    fi
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"

cat >"$tmp_dir/bin/date" <<'EODATE'
#!/usr/bin/env bash
set -euo pipefail

format="${1:-}"

case "${TZ:-}:${format}" in
    "Asia/Tokyo:+%m/%d %H:%M")
        printf "05/01 09:00"
        ;;
    "UTC:+%m/%d %H:%M")
        printf "05/01 00:00"
        ;;
    *)
        echo "unexpected date call: TZ=${TZ:-} format=$format" >&2
        exit 1
        ;;
esac
EODATE
chmod +x "$tmp_dir/bin/date"

run_date_segment() {
    (
        export PATH="$tmp_dir/bin:$PATH"
        unset TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT
        unset TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ
        unset TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ

        source "$SEGMENT"
        run_segment
    )
}

assert_equal \
    "JST 05/01 09:00 / UTC 05/01 00:00" \
    "$(run_date_segment)"

echo "date_compact_segment_test: ok"
