# セキュリティガイドライン

## 基本原則

1. **最小権限の原則**: 必要最小限の権限で実行
2. **機密情報の保護**: APIキーやパスワードの適切な管理
3. **入力検証**: 外部入力は必ず検証

## 機密情報の管理

### 1Password（推奨）
```text
Vault: dotfiles
Item: shared-env
Field: NPM_TOKEN
```

`op` が利用可能でも、シェル起動や Claude Code 実行のたびに認証プロンプトを出さないよう、自動読込は `DOTFILES_1PASSWORD_AUTOLOAD=1` のときだけ有効です。取得できた値は `XDG_CACHE_HOME` 配下に安全な権限でキャッシュします。

### ローカル環境変数（最終手段）
```bash
# ~/.zshenv.local / ~/.zshrc.local に記載（gitignore対象）
export API_KEY="your-secret-key"
export DATABASE_PASSWORD="your-password"
```

### ファイル権限
```bash
# 機密ファイルは600に設定
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.zshenv.local
chmod 600 ~/.zshrc.local
```

## シェルスクリプト

### 安全なパス設定
```bash
# cron環境など限定的なPATHで実行される場合
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
```

### コマンドインジェクション対策
```bash
# 悪い例
eval "echo $USER_INPUT"

# 良い例
printf '%s\n' "$USER_INPUT"
```

### 引用符の適切な使用
```bash
# 変数は必ずダブルクォート
if [ -f "$FILE_PATH" ]; then
    cat "$FILE_PATH"
fi
```

## ネットワーク通信

### HTTPS優先
```bash
# HTTPではなくHTTPSを使用
git clone https://github.com/user/repo.git
```

### SSH設定
```bash
# ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking yes
```

## ログとエラー処理

### 機密情報のマスク
```bash
# パスワードをログに出力しない
echo "Connecting to database..." >&2
# echo "Password: $DB_PASSWORD" >&2  # NG
```

### 一時ファイルの安全な処理
```bash
# mktempを使用
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# 処理
echo "data" > "$TEMP_FILE"
```

## 定期的なセキュリティチェック

### 依存関係の更新
```bash
# Homebrewパッケージの更新
brew update && brew upgrade

# 古いパッケージの確認
brew outdated
```

### 権限の確認
```bash
# dotfiles内の実行権限確認
find . -type f -perm +111 -ls
```
