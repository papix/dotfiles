# 環境変数リファレンス

## コア設定

### `DISABLE_AUTO_TMUX`
- **型**: boolean (1/0)
- **デフォルト**: 0
- **説明**: tmuxの自動起動を無効化
- **使用例**: `export DISABLE_AUTO_TMUX=1`

### `DISABLE_OSC52`
- **型**: boolean (1/0)
- **デフォルト**: 0
- **説明**: クリップボードコピーでOSC52を使わない
- **使用例**: `export DISABLE_OSC52=1`

### `EDITOR`
- **型**: string
- **デフォルト**: `nvim`
- **説明**: デフォルトエディタ
- **使用例**: `export EDITOR=nvim`
- **設定場所**: `config/zshenv`

## セットアップ

### `ALLOW_HOMEBREW_INSTALL`
- **型**: boolean (1/0)
- **デフォルト**: 0
- **説明**: Homebrew未導入時に公式インストーラの実行を許可
- **使用例**: `export ALLOW_HOMEBREW_INSTALL=1`

### `ALLOW_UNVERIFIED_DOWNLOAD`
- **型**: boolean (1/0)
- **デフォルト**: 0
- **説明**: チェックサム取得や検証ができない場合のダウンロード継続を許可
- **使用例**: `export ALLOW_UNVERIFIED_DOWNLOAD=1`

## ツール固有

### Zsh

#### `HISTSIZE`
- **型**: number
- **デフォルト**: 10000000
- **説明**: メモリ上の履歴サイズ
- **設定場所**: `config/zshenv`

#### `SAVEHIST`
- **型**: number
- **デフォルト**: 10000000
- **説明**: ファイルに保存する履歴サイズ
- **設定場所**: `config/zshenv`

### 開発ツール

#### `GOPATH`
- **型**: string
- **デフォルト**: `$HOME/.ghq`
- **説明**: Go言語のワークスペース
- **設定場所**: `config/zshenv`

## プラットフォーム固有

### macOS

#### `HOMEBREW_PREFIX`
- **型**: string
- **デフォルト**: `/opt/homebrew` (ARM) or `/usr/local` (Intel)
- **説明**: Homebrewのインストール先
- **自動設定**: セットアップスクリプトで設定

### Linux

#### `XDG_CONFIG_HOME`
- **型**: string
- **デフォルト**: `$HOME/.config`
- **説明**: 設定ファイルのベースディレクトリ

## ローカル設定

`~/.zshrc.local`で以下のような環境変数を設定可能：

```bash
# プロキシ設定
export http_proxy="http://proxy.example.com:8080"
export https_proxy="http://proxy.example.com:8080"
export no_proxy="localhost,127.0.0.1"

# 独自のパス追加
export PATH="$HOME/bin:$PATH"

# 言語設定
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
```
