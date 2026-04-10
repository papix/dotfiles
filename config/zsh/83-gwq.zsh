#!/usr/bin/env zsh
########################################
# gwq
########################################
# 依存: 40-completion.zsh (compinitのため)

if [[ -n "$COMMAND_CACHE[gwq]" ]]; then
    source <(gwq completion zsh)
fi
