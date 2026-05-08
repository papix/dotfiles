#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CMUX_CONFIG="$ROOT_DIR/config/cmux/cmux.json"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_json_true() {
    local expression="$1"
    local message="$2"
    if ! jq -e "$expression" "$CMUX_CONFIG" >/dev/null; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_file_exists "$CMUX_CONFIG"
jq -e . "$CMUX_CONFIG" >/dev/null

assert_json_true '.shortcuts.bindings.newTab == ["ctrl+q", "c"]' "cmux should use tmux-like prefix+c for new workspace"
assert_json_true '.shortcuts.bindings.splitDown == ["ctrl+q", "s"]' "cmux should use tmux-like prefix+s for horizontal split"
assert_json_true '.shortcuts.bindings.splitRight == ["ctrl+q", "v"]' "cmux should use tmux-like prefix+v for vertical split"
assert_json_true '.shortcuts.bindings.focusLeft == ["ctrl+q", "h"]' "cmux should use tmux-like prefix+h for pane focus"
assert_json_true '.shortcuts.bindings.focusDown == ["ctrl+q", "j"]' "cmux should use tmux-like prefix+j for pane focus"
assert_json_true '.shortcuts.bindings.focusUp == ["ctrl+q", "k"]' "cmux should use tmux-like prefix+k for pane focus"
assert_json_true '.shortcuts.bindings.focusRight == ["ctrl+q", "l"]' "cmux should use tmux-like prefix+l for pane focus"
assert_json_true '.shortcuts.bindings.selectWorkspaceByNumber == ["ctrl+q", "1"]' "cmux should use tmux-like numbered workspace switching"
assert_json_true '.commands[] | select(.name == "AI Workspace") | .workspace.layout.split == 0.6' "cmux should provide the AI workspace layout"
assert_json_true '.commands[] | select(.name == "AI Workspace") | .workspace.layout.children[0].pane.surfaces[0].command | contains("DOTFILES_CLAUDE_ARGS")' "cmux should use local claude args instead of hard-coded unsafe flags"
assert_json_true '.commands[] | select(.name == "AI Workspace") | .workspace.layout.children[1].children[0].pane.surfaces[0].command | contains("DOTFILES_CODEX_ARGS")' "cmux should use local codex args instead of hard-coded unsafe flags"

assert_contains 'set_config_file_target "/config/cmux/cmux.json" "${config_home}/cmux/cmux.json"' "$COMMON_LIB"

echo "cmux_config_test: ok"
