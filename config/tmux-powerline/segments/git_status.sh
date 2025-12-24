#!/usr/bin/env bash
# shellcheck shell=bash
# Comprehensive git status showing repository name, commit status, and branch

# Source lib to get the function get_tmux_pwd
# shellcheck source=lib/tmux_adapter.sh
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"
# shellcheck source=lib/vcs_helper.sh
source "${TMUX_POWERLINE_DIR_LIB}/vcs_helper.sh"

# Default configuration
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME:-1}"
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS:-1}"
TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH:-1}"
TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL:-}"
# Commit status symbols are now using nf-fa icons at the end of branch name
TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL:-}"
TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR="${TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR:- }"
TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN="${TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN:-24}"
TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL:-…}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Show repository name (0 or 1)
# export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME}"
# Show commit status (0 or 1)
# export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS}"
# Show branch name (0 or 1)
# export TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH="${TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH}"
# Repository symbol (GitHub repos will show nf-cod-github automatically)
# export TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_REPO_SYMBOL}"
# Branch symbol (nf-pl-branch is shown automatically)
# export TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_BRANCH_SYMBOL}"
# Separator between components
# export TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR="${TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR}"
# Max branch name length
# export TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN="${TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN}"
# Branch truncate symbol
# export TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL="${TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL}"
EORC
	echo "$rccontents"
}

__truncate_branch_name() {
	local branch="$1"
	local max_len="$TMUX_POWERLINE_SEG_GIT_STATUS_MAX_BRANCH_LEN"
	local trunc_symbol="$TMUX_POWERLINE_SEG_GIT_STATUS_TRUNCATE_SYMBOL"
	
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
	
	# Get repository name
	if [[ "$TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_REPO_NAME" == "1" ]]; then
		local repo_name
		local repo_path
		repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
		
		if [[ -n "$repo_path" ]]; then
			# Check if it's under ~/.ghq/
			if [[ "$repo_path" =~ ^$HOME/.ghq/ ]]; then
				# Extract the path after ~/.ghq/
				local ghq_path=${repo_path#$HOME/.ghq/}
				
				# Check if it's github.com
				if [[ "$ghq_path" =~ ^github.com/(.+)$ ]]; then
					repo_name="${BASH_REMATCH[1]}"
					# Add GitHub icon (nf-cod-github)
					output+="$(printf '\uf408') ${repo_name}"
				else
					# For other git hosts, extract host/owner/repo format
					if [[ "$ghq_path" =~ ^([^/]+)/(.+)$ ]]; then
						repo_name="${BASH_REMATCH[2]}"
						output+="${repo_name}"
					fi
				fi
			fi
			# If not under ~/.ghq/, don't show repository name
		fi
	fi
	
	# Get branch name and commit status
	if [[ "$TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_BRANCH" == "1" ]]; then
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
			[[ -n "$output" ]] && output+="${TMUX_POWERLINE_SEG_GIT_STATUS_SEPARATOR}"
			# Always show branch icon (nf-pl-branch)
			output+="$(printf '\ue0a0') "
			branch=$(__truncate_branch_name "$branch")
			output+="${branch}"
			
			# Add commit status at the end of branch name
			if [[ "$TMUX_POWERLINE_SEG_GIT_STATUS_SHOW_COMMIT_STATUS" == "1" ]]; then
				# Check for uncommitted changes (staged, modified, or untracked)
				if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
					# Repository is clean (nf-fa-ok_sign)
					output+=" $(printf '\uf058')"
				else
					# There are uncommitted changes (nf-fa-remove_sign)
					output+=" $(printf '\uf057')"
				fi
			fi
		fi
	fi
	
	[[ -n "$output" ]] && echo "$output"
}