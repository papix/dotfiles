#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

# shellcheck disable=SC2034
DOTFILES_DIR="$ROOT_DIR"
HOME="$TMP_HOME"

log_info() { :; }
log_action() { :; }
log_warn() { :; }
log_error() { :; }

assert_symlink_target() {
    local link_path="$1"
    local expected_target="$2"

    if [[ ! -L "$link_path" ]]; then
        echo "ASSERTION FAILED: expected symlink $link_path" >&2
        return 1
    fi

    if [[ "$(readlink "$link_path")" != "$expected_target" ]]; then
        echo "ASSERTION FAILED: expected $link_path -> $expected_target" >&2
        return 1
    fi
}

# shellcheck disable=SC1090
source "$COMMON_LIB"

mkdir -p "$TMP_HOME/.local/bin"
printf 'legacy-binary\n' >"$TMP_HOME/.local/bin/copy-to-clipboard"

setup_bin_links
setup_bin_links

assert_symlink_target "$TMP_HOME/.local/bin/lint-shell" "$ROOT_DIR/bin/lint-shell"
assert_symlink_target "$TMP_HOME/.local/bin/copy-to-clipboard" "$ROOT_DIR/bin/copy-to-clipboard"

backup_matches=("$TMP_HOME"/.local/bin/copy-to-clipboard.backup.*)
if [[ ${#backup_matches[@]} -ne 1 ]]; then
    echo "ASSERTION FAILED: expected one backup for pre-existing local bin file" >&2
    exit 1
fi

if [[ "$(cat "${backup_matches[0]}")" != 'legacy-binary' ]]; then
    echo "ASSERTION FAILED: expected backup to preserve original local bin contents" >&2
    exit 1
fi

echo "local_bin_link_test: ok"
