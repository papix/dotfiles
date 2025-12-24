# コーディング規約

## 基本原則

1. **可読性優先**: 複雑な処理よりも理解しやすいコードを
2. **一貫性**: 既存のパターンに従う
3. **パフォーマンス**: 起動時間に影響する処理は最適化

## シェルスクリプト

### ファイル構成
- Shebang: `#!/usr/bin/env bash` または `#!/usr/bin/env zsh`
- エラーハンドリング: `set -euo pipefail` （bashの場合）
- インデント: スペース4つ

### 命名規則
- 関数名: snake_case（例: `update_cache`）
- 変数名: 
  - ローカル変数: snake_case
  - 環境変数: UPPER_SNAKE_CASE
  - 定数: UPPER_SNAKE_CASE

### コメント
- **日本語で記述**（シェルスクリプト内）
- 関数の前に目的を説明
- 複雑なロジックには説明を追加

### エラーメッセージ
- **英語で記述**（echo/printfの出力）
- 明確で実行可能な内容
- 例: `echo "Error: Command not found. Please install git first."`

## Zsh設定

### モジュール構造
```zsh
# 00-init.zsh - 初期化処理
# 番号で読み込み順序を制御
# 機能ごとにファイルを分割
```

### パフォーマンス最適化
```zsh
# コマンド存在確認のキャッシュ
typeset -gA COMMAND_CACHE
if type git > /dev/null 2>&1; then
    COMMAND_CACHE[git]=1
fi

# 使用時
[[ $COMMAND_CACHE[git] ]] && alias g='git'
```

### プラットフォーム対応
```zsh
# 早期リターンパターン
[[ "$(uname)" != "Darwin" ]] && return
# macOS固有の処理
```

## 設定ファイル

### YAML/TOML
- インデント: スペース2つ
- コメントで各セクションを説明

### JSON
- インデント: スペース2つ
- trailing commaなし

## バージョン管理

### コミットメッセージ
- 日本語で記述
- プレフィックス使用:
  - `feat:` 新機能
  - `fix:` バグ修正
  - `docs:` ドキュメント
  - `refactor:` リファクタリング
  - `chore:` その他

### ブランチ戦略
- `master`: メインブランチ
- `feature/*`: 機能開発
- `fix/*`: バグ修正