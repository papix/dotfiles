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

### 環境変数

| 変数 | 説明 |
|------|------|
| `ALLOW_HOMEBREW_INSTALL=1` | Homebrew 公式インストーラの実行を許可（Linux） |
| `ALLOW_UNVERIFIED_DOWNLOAD=1` | チェックサム検証なしでのダウンロードを許可 |
| `DISABLE_AUTO_TMUX=1` | tmux 自動起動を無効化 |

## 謝辞

- https://github.com/masawada/dotfiles/
