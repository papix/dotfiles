#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMUX_CONF="$ROOT_DIR/config/tmux.conf"
TMUX_POWERLINE_CONF="$ROOT_DIR/config/tmux-powerline-config.sh"
TMUX_POWERLINE_THEME="$ROOT_DIR/config/tmux-powerline/themes/custom.sh"
CPU_USYS_SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/cpu_usys.sh"
MEM_USED_SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/mem_used.sh"
DATE_COMPACT_SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/date_compact.sh"
ITERM_SOLARIZED_PROFILE="$ROOT_DIR/config/iterm2/Solarized-Dark.itermcolors"

assert_contains() {
    local needle="$1"
    local file="$2"

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_line_contains() {
    local line_pattern="$1"
    local needle="$2"
    local file="$3"

    local line
    line="$(grep -F -- "$line_pattern" "$file" | head -n 1 || true)"
    if [[ -z "$line" ]]; then
        echo "ASSERTION FAILED: expected line pattern '$line_pattern' in $file" >&2
        return 1
    fi
    if [[ "$line" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: expected '$needle' in line '$line_pattern' of $file" >&2
        echo "  actual line: $line" >&2
        return 1
    fi
}

assert_line_not_contains() {
    local line_pattern="$1"
    local needle="$2"
    local file="$3"

    local line
    line="$(grep -F -- "$line_pattern" "$file" | head -n 1 || true)"
    if [[ -z "$line" ]]; then
        echo "ASSERTION FAILED: expected line pattern '$line_pattern' in $file" >&2
        return 1
    fi
    if [[ "$line" == *"$needle"* ]]; then
        echo "ASSERTION FAILED: expected '$needle' to not be in line '$line_pattern' of $file" >&2
        echo "  actual line: $line" >&2
        return 1
    fi
}

assert_line_ordered_contains() {
    local line_pattern="$1"
    local file="$2"
    shift 2

    local line
    line="$(grep -F -- "$line_pattern" "$file" | head -n 1 || true)"
    if [[ -z "$line" ]]; then
        echo "ASSERTION FAILED: expected line pattern '$line_pattern' in $file" >&2
        return 1
    fi

    local remain="$line"
    local token
    for token in "$@"; do
        if [[ "$remain" != *"$token"* ]]; then
            echo "ASSERTION FAILED: expected token '$token' in order in line '$line_pattern' of $file" >&2
            echo "  actual line: $line" >&2
            return 1
        fi
        remain="${remain#*"$token"}"
    done
}

assert_file_line_order() {
    local first_pattern="$1"
    local second_pattern="$2"
    local file="$3"

    local first_line second_line
    first_line="$(grep -nF -- "$first_pattern" "$file" | head -n 1 | cut -d: -f1 || true)"
    second_line="$(grep -nF -- "$second_pattern" "$file" | head -n 1 | cut -d: -f1 || true)"

    if [[ -z "$first_line" || -z "$second_line" ]]; then
        echo "ASSERTION FAILED: expected both '$first_pattern' and '$second_pattern' in $file" >&2
        return 1
    fi
    if ((first_line >= second_line)); then
        echo "ASSERTION FAILED: expected '$first_pattern' to appear before '$second_pattern' in $file" >&2
        echo "  actual lines: $first_pattern=$first_line, $second_pattern=$second_line" >&2
        return 1
    fi
}

assert_occurrence_count_at_least() {
    local needle="$1"
    local min_count="$2"
    local file="$3"

    local count
    count="$(grep -oF -- "$needle" "$file" | wc -l | tr -d '[:space:]')"
    if ((count < min_count)); then
        echo "ASSERTION FAILED: expected at least $min_count occurrences of '$needle' in $file, got $count" >&2
        return 1
    fi
}

assert_file_exists() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "ASSERTION FAILED: expected file to exist: $file" >&2
        return 1
    fi
}

# 期待: status line は2行表示
assert_contains 'set -g status 2' "$TMUX_CONF"

# 期待: ベース設定としてstatus-format定義がある
assert_contains 'set -g status-format[0]' "$TMUX_CONF"
assert_contains 'set -g status-format[1]' "$TMUX_CONF"
assert_contains 'set -g status-fg colour250' "$TMUX_CONF"

# 期待: tmux-powerline が status=2 を上書き適用する
assert_contains 'export TMUX_POWERLINE_STATUS_VISIBILITY="2"' "$TMUX_POWERLINE_CONF"

# 期待: iTerm2用Solarizedプロファイルをリポジトリで管理する
assert_file_exists "$ITERM_SOLARIZED_PROFILE"
assert_contains '<key>Ansi 0 Color</key>' "$ITERM_SOLARIZED_PROFILE"
assert_contains '<key>Background Color</key>' "$ITERM_SOLARIZED_PROFILE"

# 期待: bell/activity時に index+flags だけ色を切り替えるためのstyle optionを定義する
assert_contains "set -g @tp_window_idx_style 'fg=colour250,bg=colour235'" "$TMUX_CONF"
assert_contains "set -g @tp_window_idx_bell_style 'fg=colour166,bg=colour235,bold'" "$TMUX_CONF"
assert_contains "set -g @tp_window_idx_activity_style 'fg=colour64,bg=colour235,bold'" "$TMUX_CONF"
assert_contains "set -g @tp_window_name_style 'fg=colour252,bg=colour236'" "$TMUX_CONF"

# 期待: tmux既定の reverse を無効化して、bell/activity時のセパレータ色崩れを防ぐ
assert_contains 'set -g window-status-bell-style default' "$TMUX_CONF"
assert_contains 'set -g window-status-activity-style default' "$TMUX_CONF"

# 期待: 1行目は left + window list、2行目は right に分離する
assert_contains 'export TMUX_POWERLINE_WINDOW_STATUS_LINE="0"' "$TMUX_POWERLINE_CONF"
assert_contains 'export TMUX_POWERLINE_STATUS_FORMAT_WINDOW="${TMUX_POWERLINE_STATUS_FORMAT_LEFT_DEFAULT}${TMUX_POWERLINE_STATUS_FORMAT_WINDOW_DEFAULT}"' "$TMUX_POWERLINE_CONF"

# 期待: 上段左の順序は linux(os) > battery > window(session)（branchなし）
assert_contains 'TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(' "$TMUX_POWERLINE_THEME"
assert_contains '"os 238 244"' "$TMUX_POWERLINE_THEME"
assert_contains '"battery 166 235"' "$TMUX_POWERLINE_THEME"
assert_contains '"tmux_session_info 37 234"' "$TMUX_POWERLINE_THEME"
assert_file_line_order '"os 238 244"' '"battery 166 235"' "$TMUX_POWERLINE_THEME"
assert_file_line_order '"battery 166 235"' '"tmux_session_info 37 234"' "$TMUX_POWERLINE_THEME"
assert_not_contains '"git_branch_status 64 235 default_separator no_sep_bg_color no_sep_fg_color no_spacing_disable no_separator_disable"' "$TMUX_POWERLINE_THEME"

# 期待: Powerline記号はフォント対応時と未対応時でフォールバックを維持する
assert_contains 'TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=""' "$TMUX_POWERLINE_THEME"
assert_contains 'TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"' "$TMUX_POWERLINE_THEME"

# 期待: window list は active/inactive のコントラスト差を明確にし、inactiveでも区切り記号を強調する
assert_contains '"#[fg=colour255,bg=colour31,bold]"' "$TMUX_POWERLINE_THEME"
assert_contains '"fg=colour244,bg=colour236"' "$TMUX_POWERLINE_THEME"
assert_contains '"$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD"' "$TMUX_POWERLINE_THEME"

# 期待: 非active window の開始・終了セパレータを維持する
assert_occurrence_count_at_least '"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"' 4 "$TMUX_POWERLINE_THEME"
assert_contains '"#[fg=colour234,bg=colour235]"' "$TMUX_POWERLINE_THEME"
assert_contains '"#[fg=colour235,bg=colour236]"' "$TMUX_POWERLINE_THEME"
assert_contains '"#[fg=colour236,bg=colour234]"' "$TMUX_POWERLINE_THEME"

# 期待: bell/activity は index+flags のみ強調し、window名(#W)の背景は常にグレーに保つ
assert_contains 'window_bell_flag' "$TMUX_POWERLINE_THEME"
assert_contains '#{E:@tp_window_idx_bell_style}' "$TMUX_POWERLINE_THEME"
assert_contains '#{E:@tp_window_idx_activity_style}' "$TMUX_POWERLINE_THEME"
assert_contains '#{E:@tp_window_idx_style}' "$TMUX_POWERLINE_THEME"
assert_contains '" #I#{?window_flags,#F, } "' "$TMUX_POWERLINE_THEME"
assert_contains '"#[#{E:@tp_window_name_style}]"' "$TMUX_POWERLINE_THEME"
assert_contains '" #W "' "$TMUX_POWERLINE_THEME"

# 期待: 条件式の分岐内に style を直書きしない（tmuxフォーマット崩れ防止）
assert_not_contains '#{?window_bell_flag,#[fg=' "$TMUX_POWERLINE_THEME"

# 期待: 下段左は left 描画で表示し、矢印向きも左側向け（右向き）になる
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'tp_print_powerline_side left' "$TMUX_POWERLINE_CONF"
assert_line_not_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'status-right' "$TMUX_POWERLINE_CONF"
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'date_compact 31 255' "$TMUX_POWERLINE_CONF"
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'cpu_usys 166 235' "$TMUX_POWERLINE_CONF"
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'mem_used 37 235' "$TMUX_POWERLINE_CONF"
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' 'git_branch_status 64 235 default_separator no_sep_bg_color no_sep_fg_color no_spacing_disable no_separator_disable' "$TMUX_POWERLINE_CONF"

# 期待: claude usage は下段右に表示する
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_RIGHT=' 'claude_usage.sh' "$TMUX_POWERLINE_CONF"
assert_line_contains 'export TMUX_POWERLINE_STATUS_FORMAT_RIGHT=' 'run_segment' "$TMUX_POWERLINE_CONF"

# 期待: 下段左の順序は date > cpu > mem > branch（branchは下段左の一番右）
assert_line_ordered_contains \
    'export TMUX_POWERLINE_STATUS_FORMAT_LEFT=' \
    "$TMUX_POWERLINE_CONF" \
    'date_compact 31 255' \
    'cpu_usys 166 235' \
    'mem_used 37 235' \
    'git_branch_status 64 235 default_separator no_sep_bg_color no_sep_fg_color no_spacing_disable no_separator_disable'

# 期待: CPUセグメントは usr/sys のプレフィックス付き
assert_contains 'run_segment' "$CPU_USYS_SEGMENT"
assert_contains 'usr:' "$CPU_USYS_SEGMENT"
assert_contains 'sys:' "$CPU_USYS_SEGMENT"
assert_contains '__format_cpu_pct_fixed_width' "$CPU_USYS_SEGMENT"
assert_contains 'printf "%4.1f"' "$CPU_USYS_SEGMENT"

# 期待: Memoryセグメントは mem のプレフィックス付き
assert_contains 'run_segment' "$MEM_USED_SEGMENT"
assert_contains 'mem:' "$MEM_USED_SEGMENT"
assert_contains '__format_mem_pct_fixed_width' "$MEM_USED_SEGMENT"
assert_contains 'printf "%5.1f"' "$MEM_USED_SEGMENT"

# 期待: dateセグメントは曜日+日付+時刻を1セグメントで表示する
assert_contains 'run_segment' "$DATE_COMPACT_SEGMENT"
assert_contains '%a %F %H:%M' "$DATE_COMPACT_SEGMENT"

echo "status_two_lines_test: ok"
