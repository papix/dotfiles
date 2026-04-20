#!/usr/bin/env zsh
########################################
# AI CLI completion cache
########################################
# 依存: 40-completion.zsh (compinitのため)

[[ -o interactive ]] || return 0

local config_home completion_dir command_entry command_name
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
completion_dir="${config_home}/zsh/completions"

if [[ -f "${completion_dir}/_codex" ]]; then
    source "${completion_dir}/_codex"
    __dotfiles_maybe_refresh_codex_completion_async || true
fi

if [[ -f "${completion_dir}/_claude" ]]; then
    source "${completion_dir}/_claude"
    __dotfiles_maybe_refresh_claude_scope_async || true

    if __dotfiles_load_claude_scope_cache; then
        for command_entry in "${__DOTFILES_CLAUDE_PARSED_COMMANDS[@]}"; do
            command_name="${command_entry%%:*}"
            [[ -n "$command_name" ]] || continue
            __dotfiles_maybe_refresh_claude_scope_async "$command_name" || true
        done
    fi
fi
