#!/usr/bin/env zsh
########################################
# Pager関数
########################################

function vless() {
    if (( $# == 0 )); then
        echo "Usage: vless <file...>" >&2
        return 1
    fi

    command nvim \
        -R \
        -n \
        -i NONE \
        -c 'setlocal readonly nomodifiable nomodified autoread' \
        -c 'augroup vless_autoread' \
        -c 'autocmd!' \
        -c 'autocmd CursorHold,CursorHoldI,FocusGained,BufEnter * checktime' \
        -c 'augroup END' \
        -- "$@"
}
