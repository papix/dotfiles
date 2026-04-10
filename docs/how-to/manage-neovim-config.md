# Neovim設定の運用と切り戻し

## 概要
このドキュメントでは、dotfilesで管理しているNeovim設定の構成確認、障害時の切り戻し、復旧後の確認手順を説明します。

## 現在の構成（init.lua + core）

- エントリポイント: `~/.config/nvim/init.lua`
- 共通設定: `~/.vimrc` を `vim.cmd([[source ~/.vimrc]])` で読み込み
- Neovim固有設定:
  - `config/nvim/lua/core/bootstrap.lua` (lazy.nvimの初期化)
  - `config/nvim/lua/core/options.lua` (Neovim固有オプション)
  - `config/nvim/lua/core/providers.lua` (provider無効化)
  - `config/nvim/lua/core/clipboard.lua` (SSH + tmux時のOSC52)

設定ファイルの実体はこのリポジトリ配下にあり、`setup.sh` で `~/.config/nvim/init.lua` にリンクされます。

## 変更時の最小確認

```bash
# リポジトリ内テスト
bash test/run.sh

# Neovim単体のヘルスチェック
vim +checkhealth +qa
```

## 切り戻し手順（トラブル時）

1. 現在の `init.lua` をバックアップ
```bash
cp ~/.config/nvim/init.lua ~/.config/nvim/init.lua.backup.$(date +%Y%m%d%H%M%S)
```

2. 最小構成の `init.lua` へ一時切り戻し
```bash
cat > ~/.config/nvim/init.lua <<'EOF'
-- 緊急切り戻し用
vim.cmd([[source ~/.vimrc]])
EOF
```

3. 起動確認
```bash
vim --clean
vim +qa
```

4. 問題箇所を調査後、リポジトリ側の `config/nvim/init.lua` と `config/nvim/lua/core/*.lua` を修正

## lazy.nvimブートストラップ障害の確認ポイント

- `git` コマンドが利用可能か
- `~/.local/share/nvim/lazy/lazy.nvim` への書き込み権限があるか
- プロキシ/ネットワーク制限がないか

問題が継続する場合は、`config/nvim/lua/core/bootstrap.lua` のエラーメッセージを確認してください。
