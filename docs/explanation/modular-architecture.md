# モジュラーアーキテクチャ

## 設計理念

このdotfilesプロジェクトは、以下の原則に基づいたモジュラー設計を採用しています：

1. **単一責任**: 各モジュールは1つの機能に集中
2. **疎結合**: モジュール間の依存を最小化
3. **拡張性**: 新機能の追加が容易
4. **保守性**: 問題の特定と修正が簡単

## Zshモジュール構造

### 番号による読み込み順序

```
00-09: 基礎初期化
10-19: プラットフォーム設定
20-59: コア機能
60-79: ユーザー向け機能
80-89: 外部ツール統合
90-99: その他の設定
```

### 依存関係の管理

```zsh
# 00-init.zsh で COMMAND_CACHE を初期化
typeset -gA COMMAND_CACHE

# 10-env.zsh でコマンドをキャッシュ
for cmd in git tmux nvim; do
    type $cmd > /dev/null 2>&1 && COMMAND_CACHE[$cmd]=1
done

# 60-aliases.zsh で使用
[[ $COMMAND_CACHE[git] ]] && alias g='git'
```

## パフォーマンス最適化戦略

### 起動時間の短縮

1. **コマンド存在確認のキャッシュ**
   - 起動時に1回だけ実行
   - 結果を連想配列に保存

2. **遅延読み込み**
   ```zsh
   # 重い初期化は必要時まで遅延
   volta() {
       unfunction "$0"
       export VOLTA_HOME="$HOME/.volta"
       export PATH="$VOLTA_HOME/bin:$PATH"
       $0 "$@"
   }
   ```

3. **条件付き読み込み**
   ```zsh
   # 必要な環境でのみ読み込み
   [[ -z "$TMUX" ]] && return
   ```

### 非同期処理

tmux-powerlineセグメントでの実装例：

```bash
# セグメント自体は軽量
run_segment() {
    cat "$CACHE_FILE" 2>/dev/null || echo "☀️ --"
}

# 重い処理はバックグラウンドで
update_cache() {
    result=$(curl -s "https://api.example.com/weather")
    echo "$result" > "$CACHE_FILE"
}
```

## クロスプラットフォーム対応

### プラットフォーム検出

```zsh
case "$(uname)" in
    Darwin*)
        # macOS固有の処理
        ;;
    Linux*)
        # Linux固有の処理
        ;;
esac
```

### コマンドの互換性

```bash
# statコマンドの差分吸収
file_size() {
    stat -f%z "$1" 2>/dev/null ||  # macOS
    stat -c%s "$1" 2>/dev/null ||  # Linux
    echo 0
}
```

## 拡張方法

### 新しいモジュールの追加

1. 適切な番号を選択（機能に応じて）
2. `config/zsh/XX-feature.zsh`を作成
3. 必要な場合は`COMMAND_CACHE`を確認
4. プラットフォーム固有の場合は早期リターン

### 既存モジュールの拡張

1. 単一責任の原則を維持
2. 他のモジュールへの影響を最小化
3. パフォーマンスへの影響を考慮

## ベストプラクティス

1. **早期リターン**: 不要な処理をスキップ
2. **キャッシュ活用**: 重複する処理を避ける
3. **エラーハンドリング**: 静かに失敗する
4. **ドキュメント**: 各モジュールの目的を明記