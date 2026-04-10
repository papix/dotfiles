#!/usr/bin/env zsh
########################################
# 一般関数
########################################

# 1つ上のディレクトリに移動
function cdup() {
  echo
  cd ..
  zle reset-prompt
}
zle -N cdup
bindkey '^u' cdup

# エポック時間を人間が読める形式に変換
function epoch() {
    if [[ $# -gt 0 ]]; then
        local format='+%Y-%m-%dT%H:%M:%S%z (%Z)'
        case $(uname) in
            Darwin)
                date -r "$1" "$format"
                ;;
            Linux)
                date -d "@$1" "$format"
                ;;
        esac
    else
        date +%s
    fi
}

# OSC52を使用したクリップボードコピー
function copy-to-clipboard() {
    local external payload b64_payload
    external=$(whence -p copy-to-clipboard 2>/dev/null || true)
    if [[ -n "$external" ]]; then
        if [[ $# -eq 0 ]]; then
            cat - | command copy-to-clipboard
        else
            printf '%s' "$1" | command copy-to-clipboard
        fi
        return
    fi

    if [[ $# -eq 0 ]]; then
        payload=$(cat -)
    else
        payload=$(echo -n "$1")
    fi

    # macOSとLinuxでbase64コマンドのオプションが異なる
    case $(uname) in
        Darwin)
            # macOSではオプションなし
            b64_payload=$(printf "%s" "$payload" | base64)
            ;;
        *)
            # Linuxでは-w0オプションで改行なし
            b64_payload=$(printf "%s" "$payload" | base64 -w0)
            ;;
    esac

    # OSC52
    if [[ -n "$TMUX" ]]; then
        printf '\033Ptmux;\033\033]52;c;%s\033\033\\\033\\' "$b64_payload"
    else
        printf "\e]52;c;%s\a" "$b64_payload"
    fi
}

# Codespaces固有の関数は15-platform-codespaces.zshに移動

# compinit関連のセキュリティチェック
function zsh-compaudit-check() {
    autoload -Uz compaudit

    local -a insecure_dirs
    insecure_dirs=("${(@f)$(compaudit 2>/dev/null)}")

    if (( ${#insecure_dirs} == 0 )); then
        echo "compaudit: no insecure directories found"
        return 0
    fi

    echo "compaudit: insecure directories detected"
    printf '%s\n' "${insecure_dirs[@]}"
    return 1
}
