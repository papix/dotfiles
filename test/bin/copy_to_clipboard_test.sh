#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COPY_SCRIPT="$ROOT_DIR/bin/copy-to-clipboard"

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

if [[ ! -x "$COPY_SCRIPT" ]]; then
    echo "ASSERTION FAILED: copy-to-clipboard script must exist and be executable" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mock_bin="$tmp_dir/mock_bin"
out_file="$tmp_dir/copied.txt"
mkdir -p "$mock_bin"

cat >"$mock_bin/pbcopy" <<'MOCK'
#!/usr/bin/env bash
cat > "$MOCK_COPY_OUT"
MOCK
chmod +x "$mock_bin/pbcopy"

base_path="$PATH"

# 期待: 引数が指定された場合は標準入力ではなく引数をコピーする
: >"$out_file"
MOCK_COPY_OUT="$out_file" PATH="$mock_bin:$base_path" "$COPY_SCRIPT" "from-arg"
assert_eq "from-arg" "$(cat "$out_file")" "copy-to-clipboard should copy CLI argument when provided"

# 期待: 引数なしの場合は標準入力をコピーする
: >"$out_file"
printf 'from-stdin' | MOCK_COPY_OUT="$out_file" PATH="$mock_bin:$base_path" "$COPY_SCRIPT"
assert_eq "from-stdin" "$(cat "$out_file")" "copy-to-clipboard should copy stdin when no argument is provided"

echo "copy_to_clipboard_test: ok"
