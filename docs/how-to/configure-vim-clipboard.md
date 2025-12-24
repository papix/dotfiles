# Neovim クリップボード連携設定

## 概要
このドキュメントでは、Neovim（およびVim）でシステムクリップボードとの連携を設定する方法と、各OSでの動作確認手順を説明します。

## 設定内容
`config/vim/vimrc`に以下の機能が実装されています：

- **自動検出**: Neovimは自動的に適切なクリップボードプロバイダを検出
- **クロスプラットフォーム対応**: macOSとLinuxに対応
- **フォールバック機能**: 古いVimやclipboard機能がない場合は外部コマンドを使用

## 各OSでの動作確認

### macOS
1. **前提条件**
   - pbcopy/pbpasteコマンドが標準で利用可能

2. **確認手順**
   ```bash
   # Neovimを起動（vimコマンドでNeovimが起動）
   vim test.txt
   
   # テキストを入力してヤンク
   iHello, World!<ESC>yy
   
   # 別のアプリケーション（メモ帳など）でペースト
   # "Hello, World!"が貼り付けられることを確認
   
   # 別のアプリケーションでテキストをコピー
   # Neovimでpキーを押してペースト
   ```

### Linux (X11環境)
1. **前提条件**
   ```bash
   # xclipのインストール（推奨）
   sudo apt-get install xclip  # Debian/Ubuntu
   sudo yum install xclip      # CentOS/RHEL
   sudo pacman -S xclip        # Arch Linux
   
   # またはxselのインストール
   sudo apt-get install xsel
   ```

2. **確認手順**
   ```bash
   # クリップボードツールの確認
   which xclip || which xsel
   
   # Neovimでの動作確認（macOSと同じ手順）
   ```

### Linux (Wayland環境)
1. **前提条件**
   ```bash
   # wl-clipboardのインストール
   sudo apt-get install wl-clipboard  # Debian/Ubuntu
   sudo pacman -S wl-clipboard        # Arch Linux
   ```

2. **注意事項**
   - 現在の設定はX11用のため、Waylandでは追加設定が必要な場合があります

## トラブルシューティング

### Neovimのインストール
```bash
# macOS
brew install neovim

# Debian/Ubuntu
sudo apt-get install neovim

# Arch Linux
sudo pacman -S neovim
```

### クリップボード機能が有効にならない場合
```bash
# Neovimの健全性チェック
vim +checkhealth

# クリップボードプロバイダの確認
# Neovimは自動的に以下のプロバイダを検出します：
# - macOS: pbcopy/pbpaste
# - Linux: xclip, xsel, wl-copy/wl-paste
```

### vimコマンドでNeovimを起動
`~/.config/zsh/60-aliases.zsh`により、`vim`と`vi`コマンドは自動的にNeovimを起動します。

### SSH経由でのリモート接続時
- tmux使用時はOSCエスケープシーケンスの設定が必要な場合があります
- 詳細は`.tmux.conf`の設定を参照してください

## 設定の無効化
クリップボード連携を無効にしたい場合は、`~/.vimrc.local`に以下を追加：

```vim
" クリップボード連携を無効化
set clipboard=
```