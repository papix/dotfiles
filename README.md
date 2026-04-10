# dotfiles

## インストール

### 必要なもの

- Git
- cURL
- zsh
- unzip

```
$ git clone git@github.com:papix/dotfiles.git ~/.ghq/github.com/papix/dotfiles
$ cd ~/.ghq/github.com/papix/dotfiles
$ bash setup.sh
```

`setup.sh` は macOS / Linux で zsh が利用可能な場合、対話環境でデフォルトシェルを zsh に変更します（失敗時は警告して継続）。

### 環境変数

| 変数 | 説明 |
|------|------|
| `ALLOW_HOMEBREW_INSTALL=1` | Homebrew 公式インストーラの実行を許可（Linux） |
| `DISABLE_AUTO_TMUX=1` | tmux 自動起動を無効化 |

### Git hooks

- `pre-commit`: `lint-shell` と `gitleaks` を実行します。
- `pre-push`: push 対象コミットに対して `gitleaks` を実行します。
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

# HackGen フォントをインストール
./setup.sh --with-hackgen

# Homebrew 自動インストールを許可
./setup.sh --allow-homebrew-install

# 両方有効
./setup.sh --allow-homebrew-install --with-hackgen
```

## 謝辞

- https://github.com/masawada/dotfiles/
