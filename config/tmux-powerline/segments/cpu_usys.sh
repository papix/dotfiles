#!/usr/bin/env bash
# shellcheck shell=bash
# CPU usage segment with explicit user/system labels.

__format_cpu_pct_fixed_width() {
    local value="$1"
    awk -v raw="$value" 'BEGIN {
		if (raw == "" || raw !~ /^-?[0-9]+([.][0-9]+)?$/) {
			printf "%4.1f", 0
			exit
		}
		v = raw + 0
		if (v < 0) v = 0
		# 表示幅を常に4文字に保つため上限を99.9にする
		if (v > 99.9) v = 99.9
		printf "%4.1f", v
	}'
}

run_segment() {
    local cpu_user=""
    local cpu_system=""

    if tp_shell_is_linux; then
        local cpu_line
        cpu_line=$(top -b -n 1 | grep "Cpu(s)" || true)
        cpu_user=$(echo "$cpu_line" | grep -o "[0-9]\+\(\.[0-9]\+\)\? *us\(er\)\?" | awk '{ print $1 }' | head -n 1)
        cpu_system=$(echo "$cpu_line" | grep -o "[0-9]\+\(\.[0-9]\+\)\? *sys\?" | awk '{ print $1 }' | head -n 1)
    elif tp_shell_is_macos; then
        local cpus_line
        cpus_line=$(top -e -l 1 | grep "CPU usage:" | sed 's/CPU usage: //' || true)
        cpu_user=$(echo "$cpus_line" | awk '{print $1}' | sed 's/%//')
        cpu_system=$(echo "$cpus_line" | awk '{print $3}' | sed 's/%//')
    fi

    if [ -n "$cpu_user" ] && [ -n "$cpu_system" ]; then
        printf "usr:%s sys:%s" "$(__format_cpu_pct_fixed_width "$cpu_user")" "$(__format_cpu_pct_fixed_width "$cpu_system")"
        return 0
    fi

    return 1
}
