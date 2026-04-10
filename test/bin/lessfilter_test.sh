#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
LESSFILTER="$ROOT_DIR/bin/lessfilter"

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

assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: $message" >&2
        echo "  expected to contain: $needle" >&2
        echo "  actual            : $haystack" >&2
        exit 1
    fi
}

if [[ ! -x "$LESSFILTER" ]]; then
    echo "ASSERTION FAILED: lessfilter script must exist and be executable" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

sample="$tmp_dir/sample.txt"
printf 'hello world\n' >"$sample"
base_path="$PATH"

# batcat 優先
mock_bin="$tmp_dir/mock1"
mkdir -p "$mock_bin"
cat >"$mock_bin/bat" <<'MOCK'
#!/usr/bin/env bash
echo "BAT:$*"
MOCK
chmod +x "$mock_bin/bat"
cat >"$mock_bin/batcat" <<'MOCK'
#!/usr/bin/env bash
echo "BATCAT:$*"
MOCK
chmod +x "$mock_bin/batcat"

out="$(PATH="$mock_bin:$base_path" "$LESSFILTER" "$sample")"
assert_contains "BAT:" "$out" "lessfilter should prefer bat when available"

# lesspipe フォールバック
mock_bin2="$tmp_dir/mock2"
mkdir -p "$mock_bin2"
cat >"$mock_bin2/bat" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$mock_bin2/bat"
cat >"$mock_bin2/batcat" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$mock_bin2/batcat"
cat >"$mock_bin2/lesspipe" <<'MOCK'
#!/usr/bin/env bash
echo "LESSPIPE:$*"
MOCK
chmod +x "$mock_bin2/lesspipe"

out2="$(PATH="$mock_bin2:$base_path" "$LESSFILTER" "$sample")"
assert_contains "LESSPIPE:" "$out2" "lessfilter should use lesspipe when bat/batcat are unavailable"

# 最終フォールバックは cat
mock_bin3="$tmp_dir/mock3"
mkdir -p "$mock_bin3"
cat >"$mock_bin3/bat" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$mock_bin3/bat"
cat >"$mock_bin3/batcat" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$mock_bin3/batcat"
cat >"$mock_bin3/lesspipe" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
chmod +x "$mock_bin3/lesspipe"
out3="$(PATH="$mock_bin3:$base_path" "$LESSFILTER" "$sample")"
assert_eq "hello world" "$out3" "lessfilter should fallback to cat"

echo "lessfilter_test: ok"
