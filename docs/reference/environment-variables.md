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
- **状態**: 廃止済み。`setup.sh` では警告を出したうえで無視される
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

#### `XDG_CACHE_HOME`
- **型**: string
- **デフォルト**: `$HOME/.cache`
- **説明**: キャッシュのベースディレクトリ。`dotfiles/npm-token` などを保存
- **設定場所**: `config/zshenv`, `config/bash_env.sh`, `config/claude_env.sh`

#### `XDG_STATE_HOME`
- **型**: string
- **デフォルト**: `$HOME/.local/state`
- **説明**: 状態ファイルのベースディレクトリ。zsh 履歴は `$XDG_STATE_HOME/zsh/history`
- **設定場所**: `config/zshenv`, `config/bash_env.sh`, `config/claude_env.sh`

### 開発ツール

#### `DOTFILES_CLAUDE_ARGS`
- **型**: string
- **デフォルト**: 空
- **説明**: `work` が起動する `claude` に渡す追加引数
- **設定場所**: `~/.zshrc.local`

#### `DOTFILES_CODEX_ARGS`
- **型**: string
- **デフォルト**: 空
- **説明**: `work` が起動する `codex` に渡す追加引数
- **設定場所**: `~/.zshrc.local`

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

### Secrets

#### `NPM_TOKEN`
- **型**: string
- **デフォルト**: 空
- **説明**: npm 認証トークン。未設定時は `gh auth token` から `XDG_CACHE_HOME` 配下に安全な権限でキャッシュする
- **設定場所**: `~/.zshenv.local`, `~/.zshrc.local`, `config/bash_env.sh`, `config/claude_env.sh`

## ローカル設定

`~/.zshrc.local` / `~/.zshenv.local` は、プロキシや PATH などの machine-specific な設定に使います。秘密情報は gitignore 対象ファイルか OS 側の secret manager で管理してください。

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
