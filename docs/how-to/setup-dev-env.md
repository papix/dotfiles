# 開発環境のセットアップ

## 前提条件

- macOS、Linux、またはGitHub Codespaces
- Git 2.0以上
- インターネット接続

## インストール手順

### 1. リポジトリのクローン

```bash
# ghqを使用する場合（推奨）
git clone git@github.com:papix/dotfiles.git ~/.ghq/github.com/papix/dotfiles

# 通常のクローン
git clone git@github.com:papix/dotfiles.git ~/dotfiles
```

### 2. セットアップスクリプトの実行

```bash
cd ~/.ghq/github.com/papix/dotfiles
bash setup.sh
```

このスクリプトは以下を実行します：
- Homebrewのインストール（macOS/Linux）
- 必要なパッケージのインストール
- 設定ファイルのシンボリックリンク作成
- フォントのインストール

### 3. シェルの再起動

```bash
# 新しい設定を反映
exec $SHELL -l
```

## カスタマイズ

### ローカル設定

`~/.zshrc.local`を作成して個人設定を追加：

```bash
# 例: プロキシ設定
export http_proxy="http://proxy.example.com:8080"
export https_proxy="http://proxy.example.com:8080"

# 例: 独自のエイリアス
alias myproject="cd ~/projects/myproject"
```

### 環境変数

重要な環境変数：

```bash
# tmux自動起動の無効化
export DISABLE_AUTO_TMUX=1

# エディタの設定
export EDITOR=nvim
```

## 開発時の品質チェック

```bash
# 既存の回帰テスト
bash test/run.sh

# シェルスクリプト静的解析
bin/lint-shell
```

`bin/lint-shell` は `setup.sh`、`bin/`、`test/` の主要bashスクリプトと、tmux-powerlineセグメントを `shellcheck` で検証します。`shfmt` が利用可能な場合は、シェルスクリプトのフォーマットも確認します。

`full` プロファイルの `setup.sh` は `shellcheck` に加えて `shfmt` も導入します。
## トラブルシューティング

### Homebrewのインストールに失敗

```bash
# 手動でHomebrewをインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### シンボリックリンクの作成に失敗

```bash
# 既存ファイルをバックアップ
mv ~/.zshrc ~/.zshrc.backup

# 再度セットアップ実行
bash setup.sh
```

### フォントが表示されない

1. ターミナルアプリケーションを再起動
2. ターミナルの設定でHackGen Nerd Fontを選択
3. それでも表示されない場合は手動でインストール：
   ```bash
   # macOS
   cp ~/.local/share/fonts/HackGen*.ttf ~/Library/Fonts/
   
   # Linux
   fc-cache -fv
   ```

## 次のステップ

- [Zsh設定のカスタマイズ](./customize-zsh.md)
- [tmuxセッション管理](./manage-tmux-sessions.md)
- [Vimクリップボード設定](./configure-vim-clipboard.md)
