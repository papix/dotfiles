#!/usr/bin/env bash
# shellcheck shell=bash

__format_mem_pct_fixed_width() {
    local value="$1"
    awk -v raw="$value" 'BEGIN {
        if (raw == "" || raw !~ /^-?[0-9]+([.][0-9]+)?$/) {
            printf "%5.1f", 0
            exit
        }
        v = raw + 0
        if (v < 0) v = 0
        if (v > 100) v = 100
        printf "%5.1f", v
    }'
}

__linux_mem_used_pct() {
    local meminfo_path="${TMUX_POWERLINE_SEG_MEM_USED_MEMINFO_PATH:-/proc/meminfo}"
    awk '
        /MemTotal:/ { total=$2 }
        /MemAvailable:/ { available=$2 }
        /MemFree:/ { free=$2 }
        /Buffers:/ { buffers=$2 }
        /^Cached:/ { cached=$2 }
        END {
            if (total <= 0) exit 1
            if (available <= 0) available = free + buffers + cached
            if (available < 0) available = 0
            used = total - available
            if (used < 0) used = 0
            printf "%.1f", (used / total) * 100
        }
    ' "$meminfo_path" 2>/dev/null
}

__macos_mem_used_pct() {
    local page_size=""
    local total_bytes=""
    local vm_stat_output=""

    page_size="$(pagesize 2>/dev/null || true)"
    total_bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
    vm_stat_output="$(vm_stat 2>/dev/null || true)"

    if [ -z "$page_size" ] || [ -z "$total_bytes" ] || [ -z "$vm_stat_output" ]; then
        return 1
    fi

    printf '%s\n' "$vm_stat_output" | awk -v page_size="$page_size" -v total_bytes="$total_bytes" '
        function clean(value) {
            gsub("\\.", "", value)
            return value + 0
        }

        /^Pages free:/ { free=clean($3) }
        /^Pages speculative:/ { speculative=clean($3) }

        END {
            if (page_size <= 0 || total_bytes <= 0) exit 1
            available_pages = free + speculative
            available_bytes = available_pages * page_size
            used_bytes = total_bytes - available_bytes
            if (used_bytes < 0) used_bytes = 0
            printf "%.1f", (used_bytes / total_bytes) * 100
        }
    '
}

run_segment() {
    local mem_used=""

    if tp_shell_is_linux; then
        mem_used="$(__linux_mem_used_pct)" || mem_used=""
    elif tp_shell_is_macos; then
        mem_used="$(__macos_mem_used_pct)" || mem_used=""
    fi

    if [ -n "$mem_used" ]; then
        printf "mem:%s%%" "$(__format_mem_pct_fixed_width "$mem_used")"
        return 0
    fi

    return 1
}
