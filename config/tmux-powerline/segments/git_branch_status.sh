#!/usr/bin/env bash
# shellcheck shell=bash
# Git branch and commit status segment

# Source lib to get the function get_tmux_pwd
# shellcheck source=lib/tmux_adapter.sh
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"
# shellcheck source=lib/vcs_helper.sh
source "${TMUX_POWERLINE_DIR_LIB}/vcs_helper.sh"

# Default configuration
TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN="${TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN:-50}"
TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL="${TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL:-…}"
TMUX_POWERLINE_SEG_GIT_BRANCH_ICON_COLOR="${TMUX_POWERLINE_SEG_GIT_BRANCH_ICON_COLOR:-0}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Max branch name length
# export TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN="${TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN}"
# Branch truncate symbol
# export TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL="${TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL}"
# Branch icon color (nf-pl-branch)
# export TMUX_POWERLINE_SEG_GIT_BRANCH_ICON_COLOR="${TMUX_POWERLINE_SEG_GIT_BRANCH_ICON_COLOR}"
EORC
	echo "$rccontents"
}

__truncate_branch_name() {
	local branch="$1"
	local max_len="$TMUX_POWERLINE_SEG_GIT_BRANCH_MAX_LEN"
	local trunc_symbol="$TMUX_POWERLINE_SEG_GIT_BRANCH_TRUNCATE_SYMBOL"
	
	if [ "${#branch}" -gt "$max_len" ]; then
		branch=${branch:0:$((max_len - ${#trunc_symbol}))}
		branch="${branch}${trunc_symbol}"
	fi
	
	echo -n "$branch"
}

run_segment() {
	{
		read -r vcs_type
		read -r vcs_rootpath
	} < <(tp_get_vcs_type_and_root_path)
	
	if [[ "$vcs_type" != "git" ]]; then
		return
	fi
	
	tmux_path=$(tp_get_tmux_cwd)
	cd "$tmux_path" || return
	
	# Check if git repository
	local git_dir
	git_dir=$(git rev-parse --git-dir 2>/dev/null)
	[[ -z "$git_dir" ]] && return
	
	local output=""
	
	# Get branch name
	local branch
	# Try symbolic ref first
	if ! branch=$(git symbolic-ref HEAD 2>/dev/null); then
		# Detached HEAD - show short SHA
		branch=":$(git rev-parse --short HEAD 2>/dev/null)"
	else
		# Clean off refs/heads/
		branch=${branch#refs/heads/}
	fi
	
	if [[ -n "$branch" ]]; then
		# Always show branch icon (nf-pl-branch) with color
		output="#[fg=colour${TMUX_POWERLINE_SEG_GIT_BRANCH_ICON_COLOR}]$(printf '\ue0a0') #[fg=${TMUX_POWERLINE_CUR_SEGMENT_FG}]"
		branch=$(__truncate_branch_name "$branch")
		output+="${branch}"
		
		# Add commit status at the end of branch name
		# Check for uncommitted changes (staged, modified, or untracked)
		if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
			# Repository is clean (nf-fa-ok_sign)
			output+=" $(printf '\uf058')"
		else
			# There are uncommitted changes (nf-fa-remove_sign)
			output+=" $(printf '\uf057')"
		fi
	fi
	
	[[ -n "$output" ]] && echo "$output "
}