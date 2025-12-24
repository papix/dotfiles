# フォント設定ガイド

## HackGen Nerd Font

このdotfilesではtmux-powerlineのために、HackGen Nerd Fontの使用を推奨しています。

### インストール状況の確認

```bash
# Macの場合
ls ~/Library/Fonts/HackGen*NF*.ttf

# Linuxの場合
ls ~/.local/share/fonts/HackGen*NF*.ttf
```

### ターミナルでの設定

#### iTerm2
1. Preferences → Profiles → Text
2. Font: `HackGenConsole NF` または `HackGen35Console NF`を選択
3. Non-ASCII Font: 同じフォントを選択

#### VS Code / Cursor
`settings.json`に以下を追加：
```json
{
  "terminal.integrated.fontFamily": "HackGenConsole NF",
  "editor.fontFamily": "HackGen35Console NF, Menlo, Monaco, 'Courier New', monospace"
}
```

#### Windows Terminal (WSL2)
`settings.json`に以下を追加：
```json
{
  "profiles": {
    "defaults": {
      "fontFace": "HackGenConsole NF"
    }
  }
}
```

### フォントの特徴

- **HackGen**: 日本語プログラミング向けフォント
- **HackGenConsole**: 半角1:全角2の幅で等幅
- **HackGen35**: 全角文字の幅が半角の1.5倍（3:5）
- **NF版**: Nerd Fonts対応でアイコン表示が可能

### tmux-powerlineでの使用

tmux-powerlineは自動的にNerd Fontを検出して適切なアイコンを使用します。
設定ファイル（`~/.config/tmux-powerline/config.sh`）で以下が有効になっていることを確認：

```bash
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"
```

### トラブルシューティング

#### アイコンが正しく表示されない場合
1. ターミナルを再起動
2. フォントキャッシュをクリア：
   ```bash
   # Macの場合
   sudo atsutil databases -remove
   
   # Linuxの場合
   fc-cache -fv
   ```
3. tmuxを再起動

#### フォントが見つからない場合
setup.shを実行してフォントをインストール：
```bash
./setup.sh
```