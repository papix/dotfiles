#!/usr/bin/env bash
# tmux-powerline user configuration

# Use custom theme
export TMUX_POWERLINE_THEME="custom"

# Enable patched fonts (Powerline symbols)
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

# Theme and segment directories
export TMUX_POWERLINE_DIR_USER_THEMES="${HOME}/.config/tmux-powerline/themes"
export TMUX_POWERLINE_DIR_USER_SEGMENTS="${HOME}/.config/tmux-powerline/segments"

# Branch name max length
export TMUX_POWERLINE_SEG_VCS_BRANCH_MAX_LEN="50"

# Status bar length
export TMUX_POWERLINE_STATUS_LEFT_LENGTH="60"
export TMUX_POWERLINE_STATUS_RIGHT_LENGTH="150"

# Window list position
export TMUX_POWERLINE_STATUS_JUSTIFICATION="left"