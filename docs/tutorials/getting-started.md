# Getting Started

このチュートリアルでは、dotfiles環境を初めてセットアップする方向けに、ステップバイステップで導入方法を説明します。

## 必要なもの

- macOSまたはLinuxを実行しているコンピュータ
- インターネット接続
- 基本的なターミナル操作の知識

## ステップ1: 現在の設定をバックアップ

既存の設定ファイルがある場合は、まずバックアップを作成します：

```bash
# .zshrcのバックアップ
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)

# .tmux.confのバックアップ
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d)

# .vimrcのバックアップ  
[ -f ~/.vimrc ] && cp ~/.vimrc ~/.vimrc.backup.$(date +%Y%m%d)
```

## ステップ2: リポジトリをクローン

```bash
# ホームディレクトリに移動
cd ~

# dotfilesをクローン
git clone https://github.com/papix/dotfiles.git ~/.ghq/github.com/papix/dotfiles

# クローンしたディレクトリに移動
cd ~/.ghq/github.com/papix/dotfiles
```

## ステップ3: セットアップスクリプトを実行

```bash
# 診断と dry-run を確認
bash setup.sh --doctor
bash setup.sh --dry-run

# セットアップを開始
bash setup.sh
```

スクリプトは以下を自動的に行います：
- ✅ OSを検出（macOS/Linux）
- ✅ Homebrewをインストール（未インストールの場合）
- ✅ `Brewfile` に定義されたツールをインストール
- ✅ 設定ファイルのシンボリックリンクを作成
- ✅ フォントをインストール

必要なら、事前に 1Password に以下の secrets を用意してください。

```text
Vault: dotfiles
Item: shared-env
Field: NPM_TOKEN
```

自動読込を有効にしたい場合は、`~/.zshenv.local` などで `export DOTFILES_1PASSWORD_AUTOLOAD=1` を設定してください。

## ステップ4: 新しいシェルセッションを開始

```bash
# 現在のシェルを再起動
exec $SHELL -l
```

## ステップ5: 動作確認

### Zshの確認
```bash
# Zshバージョンを確認
echo $ZSH_VERSION

# プロンプトが変わっていることを確認
# ユーザー名@ホスト名 [現在のディレクトリ] の形式になっているはず
```

### tmuxの確認
```bash
# 新しいターミナルウィンドウを開く
# 自動的にtmuxセッションが開始されるはず

# tmuxセッション一覧を確認
tmux ls
```

### エイリアスの確認
```bash
# gitエイリアスが使えることを確認
g status  # git statusと同じ

# lsエイリアスの確認
ll  # 詳細表示付きls
```

## よくある質問

### Q: tmuxが自動起動しないようにしたい

A: 以下の環境変数を設定します：
```bash
echo 'export DISABLE_AUTO_TMUX=1' >> ~/.zshrc.local
exec $SHELL -l
```

### Q: プロンプトの色が正しく表示されない

A: ターミナルがSolarized Darkテーマに対応していることを確認してください。また、フォントをHackGen Nerd Fontに設定してください。

### Q: 特定のツールがインストールされない

A: `setup.sh`を再度実行するか、手動でインストールしてください：
```bash
# 例: pecoを手動インストール
brew install peco
```

## 次のステップ

基本的なセットアップが完了しました！次は以下のガイドを参考に、環境をカスタマイズしていきましょう：

- [Zsh設定のカスタマイズ方法](../how-to/customize-zsh.md)
- [tmuxセッションの管理](../how-to/manage-tmux-sessions.md)
- [開発環境の詳細設定](../how-to/setup-dev-env.md)

## トラブルシューティング

問題が発生した場合は、以下を試してください：

1. エラーメッセージを確認
2. `setup.sh`のログを確認
3. それでも解決しない場合は、GitHubでIssueを作成
