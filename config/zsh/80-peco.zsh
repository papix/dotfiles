#!/usr/bin/env zsh
########################################
# Peco関数
########################################

# Ctrl+Sでターミナルがフリーズするのを防ぐ
stty stop undef

# pecoで履歴を検索
function peco-history() {
    if command -v tac >/dev/null 2>&1; then
        BUFFER=$(history -n 1 | tac | peco --prompt 'HISTORY >' | head -n 1)
    elif command -v tail >/dev/null 2>&1 && tail -r /dev/null >/dev/null 2>&1; then
        BUFFER=$(history -n 1 | tail -r | peco --prompt 'HISTORY >' | head -n 1)
    else
        BUFFER=$(history -n 1 | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--)print a[i]}' | peco --prompt 'HISTORY >' | head -n 1)
    fi
    CURSOR="${#BUFFER}"
    zle clear-screen
}
zle -N peco-history
bindkey '^r' peco-history

# pecoでファイルを検索
function peco-file() {
    # Gitリポジトリ内か確認
    if ! inside-git-repository; then
        echo "Error: peco-file (Ctrl+F) can only be used inside a Git repository" >&2
        return 1
    fi
    
    if ( test -n "${BUFFER}" ); then
        local selected_files
        selected_files=$(ag -l | sort | peco --prompt 'FILE >' | while IFS= read -r f; do printf '%q ' "$f"; done)
        local cmd="${BUFFER% }"
        BUFFER="${cmd} ${selected_files}"
        CURSOR="${#BUFFER}"
    else
        local selected
        selected=$(ag -l | sort | peco --prompt 'FILE >')
        if ( test -n "${selected}" ); then
            local -a editor_cmd
            editor_cmd=(${(z)EDITOR})
            if (( ${#editor_cmd[@]} == 0 )); then
                return 1
            fi
            local -a files
            files=("${(@f)selected}")
            command "${editor_cmd[@]}" -- "${files[@]}"
        fi
    fi
}
zle -N peco-file
bindkey '^f' peco-file

# 内容を検索してファイルを開く
function pero() {
    if [[ "${EDITOR}" = "code" || "${EDITOR}" = "cursor" ]]; then
        ( ag "${@}" . | peco --exec 'head -n 1 | awk -F : '"'"'{print "-g " $1 ":" $2}'"'"' | xargs -o ${EDITOR}' )
    else
        ( ag "${@}" . | peco --exec 'head -n 1 | awk -F : '"'"'{print "+" $2 " " $1}'"'"' | xargs -o ${EDITOR}' )
    fi
}

# pecoでSSHホストを選択
function peco-ssh() {
    local -a ssh_files
    ssh_files=(${HOME}/.ssh/config(N) ${HOME}/.ssh/conf.d/*(N.))
    if (( ${#ssh_files[@]} == 0 )); then
        return 1
    fi

    local target
    target=$(awk '/^[[:space:]]*Host[[:space:]]+/ {for (i=2; i<=NF; i++) if ($i != "*" && $i !~ /[?*!]/) print $i}' ${ssh_files[@]} | sort -u | peco --prompt 'HOST >' | head -n 1)
    [[ -n "$target" ]] && ssh "$target"
}
alias ss='peco-ssh'

# pecoでリポジトリを選択
function peco-src() {
    if ! command -v roots >/dev/null 2>&1; then
        echo "Error: roots command not found" >&2
        return 1
    fi
    local selected_repos=$(ghq list --full-path | roots | grep -v "/.next"| peco --prompt 'REPOSITORY >' | head -n 1)
    if ( test -n "$selected_repos" ); then
        BUFFER="cd ${selected_repos}"
        zle accept-line
        zle clear-screen
    fi
}
zle -N peco-src
bindkey '^s' peco-src
