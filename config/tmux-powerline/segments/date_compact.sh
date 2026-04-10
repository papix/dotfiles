#!/usr/bin/env bash
# shellcheck shell=bash
# Compact date segment (day + date + time).

TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT="${TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT:-%a %F %H:%M}"

generate_segmentrc() {
    read -r -d '' rccontents <<EORC
# date(1) format for compact date/time.
export TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT="${TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT}"
EORC
    echo "$rccontents"
}

run_segment() {
    date +"$TMUX_POWERLINE_SEG_DATE_COMPACT_FORMAT"
    return 0
}
