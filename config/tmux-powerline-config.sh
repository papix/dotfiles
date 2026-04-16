#!/usr/bin/env bash
# tmux-powerline user configuration

# Use custom theme
export TMUX_POWERLINE_THEME="custom"

# Enable patched fonts (Powerline symbols)
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

# Theme and segment directories
# config.sh がシンボリックリンクなら、dotfiles側の themes/segments を優先する
tmux_powerline_config_link="${XDG_CONFIG_HOME:-${HOME}/.config}/tmux-powerline/config.sh"
if [[ -L "${tmux_powerline_config_link}" ]]; then
    tmux_powerline_config_target="$(readlink "${tmux_powerline_config_link}")"
    # readlinkが相対パスを返す場合はリンク元ディレクトリ基準で絶対化する
    if [[ -n "${tmux_powerline_config_target}" && "${tmux_powerline_config_target}" != /* ]]; then
        tmux_powerline_config_target="$(cd "$(dirname "${tmux_powerline_config_link}")" && cd "$(dirname "${tmux_powerline_config_target}")" && pwd)/$(basename "${tmux_powerline_config_target}")"
    fi
    tmux_powerline_config_dir="$(cd "$(dirname "${tmux_powerline_config_target}")" && pwd)"
    export TMUX_POWERLINE_DIR_USER_THEMES="${tmux_powerline_config_dir}/tmux-powerline/themes"
    export TMUX_POWERLINE_DIR_USER_SEGMENTS="${tmux_powerline_config_dir}/tmux-powerline/segments"
else
    export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-${HOME}/.config}/tmux-powerline/themes"
    export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-${HOME}/.config}/tmux-powerline/segments"
fi

# Branch name max length
export TMUX_POWERLINE_SEG_VCS_BRANCH_MAX_LEN="50"

# Status bar length
export TMUX_POWERLINE_STATUS_LEFT_LENGTH="60"
export TMUX_POWERLINE_STATUS_RIGHT_LENGTH="150"

# Window list position
export TMUX_POWERLINE_STATUS_JUSTIFICATION="left"

# 2-line status bar
export TMUX_POWERLINE_STATUS_VISIBILITY="2"

# line 1: left segments + window list
# line 2: date + cpu + memory + branch on left + claude usage on right
export TMUX_POWERLINE_WINDOW_STATUS_LINE="0"
export TMUX_POWERLINE_STATUS_FORMAT_WINDOW="${TMUX_POWERLINE_STATUS_FORMAT_LEFT_DEFAULT}${TMUX_POWERLINE_STATUS_FORMAT_WINDOW_DEFAULT}"
export TMUX_POWERLINE_STATUS_FORMAT_LEFT="#[align=left]#(bash -lc 'source \"${HOME}/.tmux/plugins/tmux-powerline/lib/headers.sh\"; tp_process_settings; TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(\"date_compact 31 255\" \"cpu_usys 166 235\" \"mem_used 37 235\" \"git_branch_status 64 235 default_separator no_sep_bg_color no_sep_fg_color no_spacing_disable no_separator_disable\"); tp_print_powerline_side left')"
export TMUX_POWERLINE_STATUS_FORMAT_RIGHT="#[nolist align=right range=right #{E:status-right-style}]#(bash -lc 'source \"${HOME}/.tmux/plugins/tmux-powerline/segments/claude_usage.sh\" >/dev/null 2>&1; run_segment 2>/dev/null')#[norange default]"
