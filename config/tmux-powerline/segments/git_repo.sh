#!/usr/bin/env bash
# shellcheck shell=bash
# Git repository name segment - shows repository name for repos under ~/.ghq/

# Source lib to get the function get_tmux_pwd
# shellcheck source=lib/tmux_adapter.sh
source "${TMUX_POWERLINE_DIR_LIB}/tmux_adapter.sh"
# shellcheck source=lib/vcs_helper.sh
source "${TMUX_POWERLINE_DIR_LIB}/vcs_helper.sh"

# Default configuration
TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL:-}"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Repository symbol (GitHub repos will show nf-cod-github automatically)
# export TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL="${TMUX_POWERLINE_SEG_GIT_REPO_SYMBOL}"
EORC
	echo "$rccontents"
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
	local repo_path
	repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
	
	if [[ -n "$repo_path" ]]; then
		# Check if it's under ~/.ghq/
		if [[ "$repo_path" =~ ^$HOME/.ghq/ ]]; then
			# Extract the path after ~/.ghq/
			local ghq_path=${repo_path#$HOME/.ghq/}
			
			# Check if it's github.com
			if [[ "$ghq_path" =~ ^github.com/(.+)$ ]]; then
				local repo_name="${BASH_REMATCH[1]}"
				# Add GitHub icon (nf-cod-github)
				output="$(printf '\uf408') ${repo_name}"
			else
				# For other git hosts, extract host/owner/repo format
				if [[ "$ghq_path" =~ ^([^/]+)/(.+)$ ]]; then
					local repo_name="${BASH_REMATCH[2]}"
					output="${repo_name}"
				fi
			fi
		fi
		# If not under ~/.ghq/, don't show repository name
	fi
	
	[[ -n "$output" ]] && echo "$output"
}