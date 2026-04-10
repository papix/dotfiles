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
Ctrl-q m

# 特定のセッションに切り替え
tmux switch-client -t github-com-papix-dotfiles
```

### セッションから抜ける

```bash
# デタッチ（セッションを残したまま抜ける）
Ctrl-q d

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

### ステータスラインを2行表示

この設定では、ステータスラインを下部2行で表示します。

- 1行目: セッション情報（例: `0:4.0`）やOS情報（例: `linux`）+ ウィンドウ一覧（window list）
- 2行目: Git、Claude usage、日付/時刻などの補助情報（tmux-powerline 右側セグメント）

設定を反映するには tmux 内で次を実行します：

```bash
Ctrl-q r
```

### Bell通知（SSH + iTerm2運用）

この設定では、tmuxの `bell` をBEL経路で端末へ通し、`activity` / `silence` は既定で無効です。

- 通知対象: `any`（current / other の両方を扱う）
- BEL伝搬: `monitor-bell on` + `visual-bell off` で端末側ベルを優先
- 補助通知: `tmux-alert-notify` は既定無効（必要時のみ有効化）
- スパム抑制: 有効化時は同一イベントを既定15秒レート制限

`macOS iTerm2 -> SSH -> Linux tmux` で使う場合は、iTerm2 側で bell を無効化しない設定にしてください。

- iTerm2: `Profiles > Terminal > Silence bell` を OFF
- 必要に応じて Notification Center の bell 通知も有効化

主な調整用環境変数:

```bash
# 補助通知機能を有効化（既定は無効）
export TMUX_ALERT_NOTIFY_DISABLE=0

# レート制限秒数を変更（0で無効）
export TMUX_ALERT_NOTIFY_MIN_INTERVAL=30

# 現在windowの通知抑制を無効化
export TMUX_ALERT_NOTIFY_SKIP_FOCUSED=0
```

反映方法:

```bash
Ctrl-q r
```

## 高度な使い方

### ウィンドウ管理

```bash
# 新しいウィンドウを作成
Ctrl-q c

# ウィンドウ間の移動
Ctrl-q n  # 次のウィンドウ
Ctrl-q b  # 前のウィンドウ
Ctrl-q 0-9  # 番号で移動

# ウィンドウの名前変更
Ctrl-q ,
```

### ウィンドウ名とリポジトリの運用ルール

- tmuxのウィンドウ名は、最後に操作したpaneの作業ディレクトリを元に更新されます。
- 同一windowに別リポジトリのpaneを混在させると、ウィンドウ名は最後に操作したpane側のリポジトリ名で上書きされます。
- 安定運用のため、**1 window = 1 repository** を推奨します。

```bash
# 例: 別リポジトリの作業は新しいwindowで開始
Ctrl-q c
```

### ペイン分割

```bash
# 上下分割
Ctrl-q s

# 左右分割
Ctrl-q v

# ペイン間の移動
Ctrl-q h/j/k/l

# ペインのサイズ変更
Ctrl-q < / - / + / >
```

### セッションの保存と復元

tmux-resurrectを使用している場合：

```bash
# セッションの保存
Ctrl-q Ctrl-s

# セッションの復元
Ctrl-q Ctrl-r
```

tmux-continuumを有効化している場合（この設定では有効）：

- 自動保存が定期実行されます
- tmux起動時に前回セッションの復元を試みます

プラグインを初回インストール/更新するには tmux 内で次を実行してください：

```bash
Ctrl-q I
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

### ウィンドウ名が別リポジトリ名になる

同じwindow内に複数paneがあり、paneごとに別リポジトリを開いている場合に発生します。

対処:
1. `Ctrl-q c` でリポジトリごとにwindowを分ける
2. 既存window名がずれた場合は、対象paneをアクティブにして1回コマンド実行して更新する

### 文字色と背景色が同化して見づらい

1. tmux設定の反映状態を確認：
   ```bash
   tmux show -gv window-status-bell-style
   tmux show -gv window-status-activity-style
   ```
   - どちらも `default` になっていることを確認する（`reverse` だと色反転で崩れやすい）。
2. tmuxを再読み込み：
   ```bash
   Ctrl-q r
   ```
3. iTerm2利用時は、`docs/how-to/setup-fonts.md` の `Minimum Contrast` 設定を調整する。
4. アプリ側の色リセット漏れが疑わしい場合は、前景/背景をデフォルトへ戻すANSIリセット（39/49）が使われているか確認する。

## ベストプラクティス

1. **プロジェクトごとにセッション**: 1プロジェクト = 1セッション
2. **ウィンドウで機能分離**: エディタ、サーバー、ログなど
3. **定期的なクリーンアップ**: 使わないセッションは削除
4. **セッション名の一貫性**: 自動生成された名前を使用

## 関連設定

- tmux設定: `~/.tmux.conf`
- 自動起動スクリプト: `config/zsh/82-tmux.zsh`
- tmux-powerline設定: `config/tmux-powerline/`
