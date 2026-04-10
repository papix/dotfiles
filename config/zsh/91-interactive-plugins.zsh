#!/usr/bin/env zsh
########################################
# インタラクティブ補助プラグイン
########################################

# 非対話シェルでは不要
[[ -o interactive ]] || return 0

typeset brew_prefix=""
if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
fi

# autosuggestions
if [[ -z "${ZSH_AUTOSUGGEST_STRATEGY:-}" ]]; then
    typeset -ga ZSH_AUTOSUGGEST_STRATEGY
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

typeset -a autosuggest_candidates=(
    "${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
)

function zsh_source_first_existing() {
    local candidate
    for candidate in "$@"; do
        if [[ -f "$candidate" ]]; then
            source "$candidate"
            return 0
        fi
    done
    return 1
}

zsh_source_first_existing "${autosuggest_candidates[@]}" || true

# syntax-highlighting は補完設定の後・末尾側で読み込む
typeset -a syntax_highlight_candidates=(
    "${brew_prefix}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)

zsh_source_first_existing "${syntax_highlight_candidates[@]}" || true
