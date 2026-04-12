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
| `DISABLE_AUTO_TMUX=1` | tmux 自動起動を無効化 |
| `DOTFILES_1PASSWORD_VAULT` | 1Password の vault 名（既定: `dotfiles`） |
| `DOTFILES_1PASSWORD_ITEM` | 1Password の item 名（既定: `shared-env`） |
| `DOTFILES_1PASSWORD_AUTOLOAD=1` | `bash_env.sh` / `claude_env.sh` で 1Password 自動読込を有効化 |

### Secrets

秘密情報は `~/.zshenv.local` / `~/.zshrc.local` より 1Password を優先できます。既定の参照先は `op://dotfiles/shared-env/NPM_TOKEN` です。`bash_env.sh` / `claude_env.sh` での自動読込は `DOTFILES_1PASSWORD_AUTOLOAD=1` のときだけ有効になり、取得できた値は `XDG_CACHE_HOME` 配下に安全な権限でキャッシュします。

```text
Vault: dotfiles
Item: shared-env
Field: NPM_TOKEN
```

Linux では 1Password CLI (`op`) があれば動作します。デスクトップ連携を使う場合は 1Password for Linux と PolKit agent を別途用意してください。`op` がない、または未サインインの場合は既存キャッシュとローカル環境変数へフォールバックします。

### Git hooks

- `pre-commit`: `lint-shell` と `gitleaks` を実行します。
- `pre-push`: push 対象コミットに対して `gitleaks` を実行します。
- GitHub Actions の `CI` でも `secret-scan` ジョブが `gitleaks` を実行します。
- 既存リポジトリに適用する場合は、各リポジトリで `git init` を実行してください。

## 便利コマンド

- `vless <file...>`: nvim の閲覧専用モードで開き、外部更新時は自動で再読込します。

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
