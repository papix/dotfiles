#!/usr/bin/env bash
# shellcheck shell=bash
# Simple git uncommitted changes indicator

# Source lib to get the function get_tmux_pwd
# shellcheck source=lib/tmux_adapter.sh
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"
# shellcheck source=lib/vcs_helper.sh
source "${TMUX_POWERLINE_DIR_LIB}/vcs_helper.sh"

# Default symbols
TMUX_POWERLINE_SEG_GIT_UNCOMMITTED_SYMBOL="${TMUX_POWERLINE_SEG_GIT_UNCOMMITTED_SYMBOL:-✗}"
TMUX_POWERLINE_SEG_GIT_CLEAN_SYMBOL="${TMUX_POWERLINE_SEG_GIT_CLEAN_SYMBOL:-✓}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Symbol for uncommitted changes
# export TMUX_POWERLINE_SEG_GIT_UNCOMMITTED_SYMBOL="${TMUX_POWERLINE_SEG_GIT_UNCOMMITTED_SYMBOL}"
# Symbol for clean repository
# export TMUX_POWERLINE_SEG_GIT_CLEAN_SYMBOL="${TMUX_POWERLINE_SEG_GIT_CLEAN_SYMBOL}"
EORC
	echo "$rccontents"
}

run_segment() {
	{
		read -r vcs_type
		read -r _unused
	} < <(tp_get_vcs_type_and_root_path)
	
	if [[ "$vcs_type" != "git" ]]; then
		return
	fi
	
	tmux_path=$(tp_get_tmux_cwd)
	cd "$tmux_path" || return
	
	# Check if git
	[[ -z $(git rev-parse --git-dir 2>/dev/null) ]] && return
	
	# Check for uncommitted changes (staged, modified, or untracked)
	if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
		# Repository is clean
		echo "${TMUX_POWERLINE_SEG_GIT_CLEAN_SYMBOL} "
	else
		# There are uncommitted changes
		echo "${TMUX_POWERLINE_SEG_GIT_UNCOMMITTED_SYMBOL} "
	fi
}