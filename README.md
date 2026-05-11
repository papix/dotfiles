# dotfiles

## インストール

### 必要なもの

- Git
- cURL
- zsh
- unzip

```bash
git clone git@github.com:papix/dotfiles.git ~/.ghq/github.com/papix/dotfiles
cd ~/.ghq/github.com/papix/dotfiles
bash setup.sh --doctor
bash setup.sh --dry-run
bash setup.sh
```

`setup.sh` は macOS / Linux で zsh が利用可能な場合、対話環境でデフォルトシェルを zsh に変更します（失敗時は警告して継続）。Homebrew パッケージは `Brewfile` / `Brewfile.<os>` / `Brewfile.minimal*` を使って `brew bundle` で適用します。

### セットアッププロファイル

- `full` (デフォルト): 開発ツール一式をインストール
- `minimal`: 最小構成のみをインストール

```bash
# 最小構成
./setup.sh --profile=minimal
```

### 環境変数

| 変数 | 説明 |
|------|------|
| `ALLOW_HOMEBREW_INSTALL=1` | Homebrew 公式インストーラの実行を許可（Linux） |
| `DISABLE_AUTO_TMUX=1` | Linux の tmux 自動起動を無効化 |
| `DOTFILES_CLAUDE_ARGS` | `work` が起動する `claude` へ渡す追加引数 |
| `DOTFILES_CODEX_ARGS` | `work` が起動する `codex` へ渡す追加引数 |

### Secrets

秘密情報は `~/.zshenv.local` / `~/.zshrc.local` などの gitignore 対象ファイル、または OS 側の secret manager で管理してください。`NPM_TOKEN` が未設定の場合は `gh auth token` から安全な権限で `XDG_CACHE_HOME` 配下にキャッシュします。

### Git hooks

- `pre-commit`: `prek` に委譲します。`.pre-commit-config.yaml` があるリポジトリで設定済み hook を実行し、このリポジトリでは `lint-shell` と `gitleaks protect --staged` を実行します。
- `pre-push`: push 対象コミットに対して `gitleaks` を実行します。
- GitHub Actions の `CI` でも `secret-scan` ジョブが `gitleaks` を実行します。
- 既存リポジトリに適用する場合は、各リポジトリで `git init` を実行してください。
- `prek` の hook は `SKIP=lint-shell,gitleaks git commit -m 'message'` のように個別スキップできます。

## 便利コマンド

- `vless <file...>`: nvim の閲覧専用モードで開き、外部更新時は自動で再読込します。
- `work`: tmux または cmux 内で、Claude / Codex / shell の作業レイアウトを開きます。cmux 内では tmux を起動しません。
- `wt`: git worktree を明示的に作成・表示・削除します。`wt new` は名前省略時に `worktree-YYYYmmdd-HHMMSS` 形式で自動命名します。`wt open` / `wt remove` は引数なしで peco 選択できます。cmux 内では worktree ごとに新しい workspace を開きます。
- `Ctrl+B` / `Ctrl+Shift+B`: peco で branch / worktree を選んで切り替えます。

## 破壊的変更 (Breaking Changes)

### v2.0 (2025-12)

- **HackGen フォントのインストールがオプション化**: デフォルトではインストールされません。`--with-hackgen` オプションを指定してください。
- **Homebrew 自動インストールがオプション化**: Homebrew が未インストールの場合、デフォルトではスキップされます。`--allow-homebrew-install` オプションを指定してください。
- **`ALLOW_UNVERIFIED_DOWNLOAD` 環境変数の廃止**: HackGen はバージョン固定 + 埋め込みチェックサムで検証するため、この環境変数は無視されます。

### 新しい使用例

```bash
# 通常実行（オプション機能はスキップ）
./setup.sh

# まず診断だけ確認
./setup.sh --doctor

# 実行前に適用内容を確認
./setup.sh --dry-run

# HackGen フォントをインストール
./setup.sh --with-hackgen

# Homebrew 自動インストールを許可
./setup.sh --allow-homebrew-install

# 最小構成を適用
./setup.sh --profile=minimal

# 両方有効
./setup.sh --allow-homebrew-install --with-hackgen
```

## 謝辞

- https://github.com/masawada/dotfiles/
