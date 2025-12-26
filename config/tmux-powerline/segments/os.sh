#!/usr/bin/env bash
# shellcheck shell=bash
# OSセグメント（mac / linux の表示）

TMUX_POWERLINE_SEG_OS_LABEL_MAC_DEFAULT="mac"
TMUX_POWERLINE_SEG_OS_LABEL_LINUX_DEFAULT="linux"

generate_segmentrc() {
    read -r -d '' rccontents <<EORC
# macOSの表示名
export TMUX_POWERLINE_SEG_OS_LABEL_MAC="${TMUX_POWERLINE_SEG_OS_LABEL_MAC_DEFAULT}"
# Linuxの表示名
export TMUX_POWERLINE_SEG_OS_LABEL_LINUX="${TMUX_POWERLINE_SEG_OS_LABEL_LINUX_DEFAULT}"
EORC
    echo "$rccontents"
}

run_segment() {
    local label_mac="${TMUX_POWERLINE_SEG_OS_LABEL_MAC:-$TMUX_POWERLINE_SEG_OS_LABEL_MAC_DEFAULT}"
    local label_linux="${TMUX_POWERLINE_SEG_OS_LABEL_LINUX:-$TMUX_POWERLINE_SEG_OS_LABEL_LINUX_DEFAULT}"
    local uname_out

    uname_out=$(uname -s 2>/dev/null || true)
    case "$uname_out" in
    Darwin)
        echo "$label_mac"
        ;;
    Linux)
        echo "$label_linux"
        ;;
    *)
        if [ -n "$uname_out" ]; then
            echo "$uname_out" | tr '[:upper:]' '[:lower:]'
        fi
        ;;
    esac
}
