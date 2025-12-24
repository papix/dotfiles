#!/usr/bin/env bash
# Git status segment configuration

# Show repository name (0 or 1)
export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME="1"

# Show commit status (0 or 1)
export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS="1"

# Show branch name (0 or 1)
export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH="1"

# Repository symbol (GitHub repos automatically show nf-cod-github)
# Only repositories under ~/.ghq/ will show repository names
# export TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL=""

# Branch symbol (automatically shows nf-pl-branch)
# export TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL=""

# Commit status is now shown at the end of branch name:
#  nf-fa-ok_sign (✓) for clean repository
#  nf-fa-remove_sign (✗) for uncommitted changes

# Separator between components
export TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR=" "

# Max branch name length
export TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN="24"

# Branch truncate symbol
export TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL="…"