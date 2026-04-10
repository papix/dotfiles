#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"

if ! command -v tmux >/dev/null 2>&1; then
    echo "ASSERTION FAILED: tmux not found" >&2
    exit 1
fi

tmp_config="$(mktemp)"
socket_name="dotfiles-smoke-$$"
trap 'rm -f "$tmp_config"; tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true' EXIT

# TPM未インストール環境でも設定ロード可否を検証できるよう、plugin起動行を除外した一時設定でsmoke testを行う
grep -Fv "run '~/.tmux/plugins/tpm/tpm'" "$TMUX_CONF" >"$tmp_config"

tmux -L "$socket_name" -f "$tmp_config" new-session -d -s smoke

bell_action="$(tmux -L "$socket_name" show -gv bell-action)"
if [[ "$bell_action" != "any" ]]; then
    echo "ASSERTION FAILED: expected bell-action=any, got '$bell_action'" >&2
    exit 1
fi

monitor_bell="$(tmux -L "$socket_name" show -wgv monitor-bell)"
if [[ "$monitor_bell" != "on" ]]; then
    echo "ASSERTION FAILED: expected monitor-bell=on, got '$monitor_bell'" >&2
    exit 1
fi

tmux -L "$socket_name" kill-server

echo "config_smoke_test: ok"
