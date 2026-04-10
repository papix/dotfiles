# Zsh モジュラー設定

## 概要
zshの設定を機能別に分割し、管理しやすくしました。`~/.config/zsh/`ディレクトリ内のファイルが番号順に自動的に読み込まれます。

## ディレクトリ構造
```
~/.config/zsh/
├── 00-init.zsh       # 初期化とローカル設定の読み込み
├── 10-env.zsh        # 環境変数と外部ツールの初期化
├── 20-colors.zsh     # Solarized Darkカラー定義
├── 30-options.zsh    # シェルオプションとキーバインド
├── 40-completion.zsh # 補完設定
├── 50-prompt.zsh     # プロンプトとVCS情報
├── 60-aliases.zsh    # エイリアス定義
├── 70-functions.zsh  # 汎用関数
├── 80-peco.zsh       # peco関連の関数
├── 81-git.zsh        # Git関連の関数
├── 82-tmux.zsh       # tmux統合
├── 90-external.zsh   # 外部ツールの設定
└── 91-interactive-plugins.zsh # 補助プラグイン読み込み
```

## 各ファイルの説明

### 00-init.zsh
- zshrcのコンパイル
- ローカル設定ファイル（~/.zshrc.local）の読み込み

### 10-env.zsh
- 環境変数設定（GOPATH、言語設定など）
- Homebrew、mise、direnvの初期化
- fpath設定

### 20-colors.zsh
- Solarized Darkカラースキームの定義
- 旧互換性のためのカラーエイリアス

### 30-options.zsh
- シェルオプション（履歴、ビープ音無効化など）
- viモードとキーバインド設定

### 40-completion.zsh
- zsh補完システムの設定
- 補完表示のカスタマイズ

### 50-prompt.zsh
- プロンプトの定義
- VCS（Git/SVN/Hg/Bzr）情報の表示設定

### 60-aliases.zsh
- すべてのエイリアス定義
- ls、git、Perl、その他のコマンドエイリアス

### 70-functions.zsh
- 汎用的なユーティリティ関数
  - cdup: 親ディレクトリへの移動
  - epoch: エポック時間の変換
  - copy-to-clipboard: OSC52を使用したクリップボードコピー
  - vim: $EDITORで開く

### 80-peco.zsh
- peco関連のインタラクティブ機能
  - 履歴検索（Ctrl+R）
  - ファイル検索（Ctrl+F）
  - SSH接続先選択
  - リポジトリ選択（Ctrl+S）

### 81-git.zsh
- Git関連の関数
  - ブランチ操作
  - リポジトリルートへの移動（Ctrl+P）
  - インタラクティブなgit add

### 82-tmux.zsh
- tmuxセッション管理
- ワークスペース名の自動設定
- VSCode/Cursor環境での無効化

### 90-external.zsh
- 外部ツールの設定
  - Rancher Desktop
  - Bun

### 91-interactive-plugins.zsh
- `zsh-autosuggestions` の読み込み
- `zsh-syntax-highlighting` の読み込み
- 非対話シェルでは無効化

## カスタマイズ方法

### 新しいモジュールの追加
1. `~/.config/zsh/`に新しいファイルを作成
2. ファイル名は`番号-機能名.zsh`の形式で命名
3. 読み込み順序は番号で制御

### 既存モジュールの無効化
モジュールを無効にするには、ファイル名を`.bak`などに変更するか、削除します。

## 移行ガイド

### 既存の設定からの移行
1. バックアップを作成: `cp ~/.zshrc ~/.zshrc.backup`
2. モジュラー設定を適用: 新しい`~/.zshrc`をシンボリックリンクで設定
3. 動作確認: `source ~/.zshrc`でエラーがないことを確認

### トラブルシューティング
- 読み込み順序の問題: ファイル名の番号を調整
- 特定の機能が動作しない: 該当するモジュールファイルを確認
- パフォーマンスの問題: 不要なモジュールを無効化
