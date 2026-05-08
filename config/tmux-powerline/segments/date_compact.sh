#!/usr/bin/env bash
# shellcheck shell=bash
# JST/UTCの月日+時刻セグメント。

TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT="${TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT:-%m/%d %H:%M}"
TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ="${TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ:-Asia/Tokyo}"
TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ="${TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ:-UTC}"

generate_segmentrc() {
    read -r -d '' rccontents <<EORC
# date(1) に渡す月日+時刻フォーマット。
export TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT="${TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT}"
export TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ="${TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ}"
export TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ="${TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ}"
EORC
    echo "$rccontents"
}

__date_compact_render_timezone() {
    local timezone="$1"
    local label="$2"
    local value=""

    value="$(TZ="$timezone" date +"$TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT" 2>/dev/null)" || return 1

    printf "%s %s" "$label" "$value"
}

run_segment() {
    local jst_segment=""
    local utc_segment=""

    jst_segment="$(__date_compact_render_timezone "$TMUX_POWERLINE_SEG_DATE_COMPACT_JST_TZ" "JST")" || return 1
    utc_segment="$(__date_compact_render_timezone "$TMUX_POWERLINE_SEG_DATE_COMPACT_UTC_TZ" "UTC")" || return 1

    printf "%s / %s" "$jst_segment" "$utc_segment"

    return 0
}
