#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

function_body="$tmp_dir/run_with_sudo.sh"
awk '
    /function run_with_sudo\(\) \{/ {capture=1}
    capture {print}
    capture && /^}/ {exit}
' "$ROOT_DIR/setup.sh" >"$function_body"

if [[ ! -s "$function_body" ]]; then
    echo "ASSERTION FAILED: failed to extract run_with_sudo from setup.sh" >&2
    exit 1
fi

cat >"$tmp_dir/test_runner.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_info() { :; }
log_warn() { :; }
log_error() { :; }

source "$1"

# sudo が見つからない環境をシミュレートする
tmp_bin="$(mktemp -d)"
trap 'rm -rf "$tmp_bin"' EXIT
ln -s "$(command -v id)" "$tmp_bin/id"
ln -s "$(command -v true)" "$tmp_bin/true"
cat > "$tmp_bin/sudo" <<'EOS'
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$tmp_bin/sudo"
PATH="$tmp_bin:/usr/bin:/bin"
if run_with_sudo true; then
    echo "run_with_sudo unexpectedly succeeded without sudo" >&2
    exit 1
fi

echo "run_with_sudo_policy_test: ok"
EOF
chmod +x "$tmp_dir/test_runner.sh"

bash "$tmp_dir/test_runner.sh" "$function_body"
