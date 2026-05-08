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

##### Solarized Darkの適用（iTerm2）
1. Preferences → Profiles → Colors
2. Color Presets... → Import...
3. `config/iterm2/Solarized-Dark.itermcolors` を選択
4. 再度 Color Presets... から `Solarized-Dark` を選択

##### 文字色と背景色の同化を減らす設定
1. Preferences → Profiles → Colors
2. `Minimum Contrast` を有効化して、必要最小限だけスライダーを上げる
3. その後 tmux を再読み込みして表示を確認する（`Ctrl-q r`）

#### cmux

cmuxのターミナル表示はGhostty互換設定を参照します。`bash setup.sh` を実行すると、`config/ghostty/config` が `~/.config/ghostty/config` にシンボリックリンクされます。

既定値はiTerm2の設定に合わせています。

```ini
font-family = "HackGen Console NF"
font-size = 14
theme = "iTerm2 Solarized Dark"
minimum-contrast = 3
term = xterm-256color
```

反映するにはcmuxで `Cmd+Shift+,` を押すか、次を実行します。

```bash
cmux reload-config
```

フォントが既存のsurfaceへ反映されない場合は、新しいsurfaceまたはworkspaceを開き直してください。

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
