#!/usr/bin/env zsh
########################################
# エディタ設定
########################################


# vimコマンドの実装 - 常にnvimにリダイレクト
function vim() {
    if command -v nvim >/dev/null 2>&1; then
        nvim "$@"
    else
        command vim "$@"
    fi
}

# viコマンドの実装 - 常にnvimにリダイレクト
function vi() {
    if command -v nvim >/dev/null 2>&1; then
        nvim "$@"
    else
        command vi "$@"
    fi
}

# エディタ選択のデバッグ用関数
function which-editor() {
    echo "Current EDITOR: $EDITOR"
    
    case "$EDITOR" in
        cursor)
            echo "Will use: cursor"
            if command -v cursor >/dev/null 2>&1; then
                echo "cursor command: found at $(command -v cursor)"
            else
                echo "cursor command: NOT FOUND"
            fi
            ;;
        nvim)
            echo "Will use: nvim"
            if command -v nvim >/dev/null 2>&1; then
                echo "nvim command: found at $(command -v nvim)"
            else
                echo "nvim command: NOT FOUND"
            fi
            ;;
        *)
            echo "Will use: $EDITOR"
            if command -v "$EDITOR" >/dev/null 2>&1; then
                echo "$EDITOR command: found at $(command -v "$EDITOR")"
            else
                echo "$EDITOR command: NOT FOUND"
            fi
            ;;
    esac
    
    echo ""
    echo "vim command resolves to:"
    if command -v nvim >/dev/null 2>&1; then
        echo "  nvim ($(command -v nvim))"
    else
        echo "  vim ($(command -v vim))"
    fi
    
    echo "vi command resolves to:"
    if command -v nvim >/dev/null 2>&1; then
        echo "  nvim ($(command -v nvim))"
    else
        echo "  vi ($(command -v vi))"
    fi
}
