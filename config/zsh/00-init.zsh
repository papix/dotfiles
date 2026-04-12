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

# COMMAND_CACHE構築前にLinux HomebrewをPATHに追加
# (mise等がHomebrew経由でインストールされているため、先にPATHに追加しないとキャッシュに反映されない)
if [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
    typeset -gx -U path
    path=("/home/linuxbrew/.linuxbrew/bin" ${path})
fi

# パフォーマンス向上のためのコマンド存在キャッシュ
typeset -gA COMMAND_CACHE
local commands_to_check=(
    # パッケージマネージャーと環境ツール
    brew mise direnv
    # シェルユーティリティ
    gls gsed
    # ドキュメントと表示
    cpandoc tldr colordiff
    # バージョン管理と開発
    tmux peco ag gh op
    # エディタ
    nvim
)

for cmd in $commands_to_check; do
    if type $cmd > /dev/null 2>&1; then
        COMMAND_CACHE[$cmd]=1
    fi
done

# 互換用: ローカル環境で ~/.zshrc.alias が存在する場合のみ従来設定を読み込む
if [[ -f "${HOME}/.zshrc.alias" ]]; then
    source "${HOME}/.zshrc.alias"
fi
