#!/usr/bin/env zsh
########################################
# 初期化
########################################

# zshrcをコンパイルして高速化
if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
fi

# ローカル設定を最初に読み込み（PATH等をCOMMAND_CACHEに反映させるため）
if [[ -f "${HOME}/.zshrc.local" ]]; then
    source "${HOME}/.zshrc.local"
fi

# パフォーマンス向上のためのコマンド存在キャッシュ
typeset -gA COMMAND_CACHE
local commands_to_check=(
    # パッケージマネージャーと環境ツール
    brew anyenv direnv
    # シェルユーティリティ
    gls gsed
    # ドキュメントと表示
    cpandoc tldr colordiff
    # バージョン管理と開発
    tmux peco ag
    # エディタ
    nvim
)

for cmd in $commands_to_check; do
    if type $cmd > /dev/null 2>&1; then
        COMMAND_CACHE[$cmd]=1
    fi
done

# エイリアスを読み込み（後で60-aliases.zshに移動予定）
if ( test -f "${HOME}/.zshrc.alias" ); then
    source "${HOME}/.zshrc.alias"
fi