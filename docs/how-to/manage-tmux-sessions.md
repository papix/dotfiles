# tmuxセッション管理

## 概要

このプロジェクトでは、ghqで管理されているリポジトリごとに自動的にtmuxセッションを作成・管理します。

## 自動セッション管理

### セッション名の規則

リポジトリパスに基づいて自動的にセッション名が生成されます：

```
~/.ghq/github.com/user/repo → github-com-user-repo
~/.ghq/gitlab.com/org/project → gitlab-com-org-project
```

### 自動起動の仕組み

1. 新しいターミナルを開く
2. 現在のディレクトリがghq管理下かチェック
3. 該当するtmuxセッションが存在すればアタッチ
4. 存在しなければ新規作成してアタッチ

## 基本的な使い方

### セッション一覧の確認

```bash
# すべてのセッションを表示
tmux ls

# 出力例:
# github-com-papix-dotfiles: 2 windows (created Mon Dec  4 10:23:45 2023)
# github-com-myproject-api: 1 windows (created Mon Dec  4 11:00:12 2023)
```

### セッション間の移動

```bash
# セッション一覧を表示して選択（tmux内で）
Ctrl-b s

# 特定のセッションに切り替え
tmux switch-client -t github-com-papix-dotfiles
```

### セッションから抜ける

```bash
# デタッチ（セッションを残したまま抜ける）
Ctrl-b d

# セッションを終了
exit  # すべてのウィンドウで実行
```

## カスタマイズ

### 自動起動を無効化

特定の環境で自動起動を無効にする：

```bash
# ~/.zshrc.localに追加
export DISABLE_AUTO_TMUX=1
```

### セッション名のカスタマイズ

`config/zsh/82-tmux.zsh`を編集してカスタマイズ可能：

```zsh
# 例: プロジェクト名のみを使用
session_name=$(basename "$ghq_root")
```

## 高度な使い方

### ウィンドウ管理

```bash
# 新しいウィンドウを作成
Ctrl-b c

# ウィンドウ間の移動
Ctrl-b n  # 次のウィンドウ
Ctrl-b p  # 前のウィンドウ
Ctrl-b 0-9  # 番号で移動

# ウィンドウの名前変更
Ctrl-b ,
```

### ペイン分割

```bash
# 水平分割
Ctrl-b %

# 垂直分割  
Ctrl-b "

# ペイン間の移動
Ctrl-b 矢印キー

# ペインのサイズ変更
Ctrl-b Ctrl-矢印キー
```

### セッションの保存と復元

tmux-resurrectを使用している場合：

```bash
# セッションの保存
Ctrl-b Ctrl-s

# セッションの復元
Ctrl-b Ctrl-r
```

## トラブルシューティング

### セッションが自動作成されない

1. 現在のディレクトリがghq管理下か確認：
   ```bash
   pwd | grep -q "$(ghq root)" && echo "OK" || echo "NG"
   ```

2. tmuxが正しくインストールされているか確認：
   ```bash
   which tmux
   tmux -V
   ```

### VSCodeでtmuxが起動してしまう

VSCodeの統合ターミナルでは自動的に無効化されますが、問題がある場合は：

```bash
# settings.jsonに追加
"terminal.integrated.env.osx": {
    "DISABLE_AUTO_TMUX": "1"
}
```

### セッションが残り続ける

不要なセッションを削除：

```bash
# 特定のセッションを削除
tmux kill-session -t session-name

# すべてのセッションを削除
tmux kill-server
```

## ベストプラクティス

1. **プロジェクトごとにセッション**: 1プロジェクト = 1セッション
2. **ウィンドウで機能分離**: エディタ、サーバー、ログなど
3. **定期的なクリーンアップ**: 使わないセッションは削除
4. **セッション名の一貫性**: 自動生成された名前を使用

## 関連設定

- tmux設定: `~/.tmux.conf`
- 自動起動スクリプト: `config/zsh/82-tmux.zsh`
- tmux-powerline設定: `config/tmux-powerline/`