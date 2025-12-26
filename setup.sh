#!/bin/bash
set -eu

# 引数と環境変数の初期化
ALLOW_HOMEBREW_INSTALL="${ALLOW_HOMEBREW_INSTALL:-0}"
WITH_HACKGEN="${WITH_HACKGEN:-0}"

# 引数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        --allow-homebrew-install)
            ALLOW_HOMEBREW_INSTALL=1
            shift
            ;;
        --with-hackgen)
            WITH_HACKGEN=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --allow-homebrew-install  Allow automatic Homebrew installation"
            echo "  --with-hackgen            Install HackGen Nerd Font"
            echo "  --help, -h                Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# 廃止フラグの検出と警告
if [ "${ALLOW_UNVERIFIED_DOWNLOAD:-}" = "1" ]; then
    echo "[WARNING] ALLOW_UNVERIFIED_DOWNLOAD is deprecated and ignored."
    echo "[WARNING] HackGen now uses a pinned version with an embedded checksum."
    echo "[WARNING] Use --with-hackgen to install HackGen font."
fi

# エラーハンドリング関数
function handle_error() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "[ERROR] $message" >&2
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        # スクリプトが直接実行された場合
        exit "$exit_code"
    else
        # ソースされた場合（関数内）
        return "$exit_code"
    fi
}

function verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual=""

    if command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    else
        echo "[WARNING] sha256 utility not found. Unable to verify: $file"
        return 2
    fi

    if [ "$actual" != "$expected" ]; then
        echo "[ERROR] SHA256 mismatch for $file"
        return 1
    fi

    return 0
}

# sudo が使えない場合は警告して処理をスキップする
function run_with_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return $?
    fi

    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true >/dev/null 2>&1; then
            sudo "$@"
            return $?
        fi
        if [ -t 0 ]; then
            echo "[INFO] sudo password is required. Please enter your password."
            sudo "$@"
            return $?
        fi
        echo "[WARNING] sudo is required but not available without a password. Skipping: $*"
        return 0
    fi

    echo "[WARNING] sudo not found. Skipping: $*"
    return 0
}

# デフォルトシェルをzshに変更（可能な場合のみ）
function set_default_shell_zsh() {
    local zsh_path=""
    zsh_path=$(command -v zsh || true)

    if [ -z "$zsh_path" ]; then
        echo "[WARNING] zsh not found. Skipping default shell change."
        return 0
    fi

    if [ -f /etc/shells ]; then
        if ! grep -Fqx "$zsh_path" /etc/shells; then
            echo "[WARNING] zsh is not listed in /etc/shells. Skipping default shell change."
            return 0
        fi
    fi

    if [ "$(id -u)" -eq 0 ]; then
        echo "[WARNING] Running as root. Skipping default shell change."
        return 0
    fi

    if [ "${SHELL:-}" = "$zsh_path" ]; then
        echo "[Default Shell] Already set to zsh."
        return 0
    fi

    if ! command -v chsh >/dev/null 2>&1; then
        echo "[WARNING] chsh not found. Skipping default shell change."
        return 0
    fi

    if [ ! -t 0 ]; then
        echo "[WARNING] No TTY available. Skipping default shell change."
        return 0
    fi

    echo "[Default Shell] Changing default shell to zsh..."
    if chsh -s "$zsh_path"; then
        echo "[Default Shell] Updated to ${zsh_path}"
    else
        echo "[WARNING] Failed to change default shell. Please run: chsh -s ${zsh_path}"
    fi
}

# 前提パッケージのインストール（Linux）
function install_prerequisites_linux() {
    echo "[Prerequisites] Installing required packages..."
    if command -v apt-get >/dev/null 2>&1; then
        run_with_sudo apt-get install -y build-essential procps curl file git unzip fontconfig zsh
    elif command -v yum >/dev/null 2>&1; then
        run_with_sudo yum install -y gcc-c++ make procps-ng curl file git unzip fontconfig zsh
    elif command -v pacman >/dev/null 2>&1; then
        run_with_sudo pacman -S --noconfirm base-devel procps-ng curl file git unzip fontconfig zsh
    else
        echo "[WARNING] No supported package manager found for prerequisites"
    fi
}

# 前提パッケージのインストール（macOS）
function install_prerequisites_mac() {
    local missing=()
    local candidate=""

    for candidate in git curl unzip zsh; do
        if ! command -v "$candidate" >/dev/null 2>&1; then
            missing+=("$candidate")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "[Prerequisites] Already installed."
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        handle_error "Homebrew not found. Install prerequisites manually: ${missing[*]}"
        return 1
    fi

    echo "[Prerequisites] Installing: ${missing[*]}"
    brew install "${missing[@]}"
}

PACKAGES=(peco tmux tig zsh colordiff tree tldr git neovim shellcheck gh gitleaks)
OS=$(uname)
PWD=$(pwd)

# HackGen フォント設定（バージョン固定）
# チェックサム算出元: https://github.com/yuru7/HackGen/releases/download/v2.10.0/HackGen_NF_v2.10.0.zip
# 算出方法: curl -fsSLO <URL> && shasum -a 256 HackGen_NF_v2.10.0.zip
HACKGEN_VERSION="2.10.0"
HACKGEN_NF_SHA256="f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428"

# HackGen fontインストール関数
function install_hackgen_font() {
    local font_dir="$1"
    local font_update_cmd="$2"
    
    if ! ls "${font_dir}"/HackGen*.ttf >/dev/null 2>&1; then
        echo "[HackGen Font] Installing HackGen Nerd Font..."
        
        # Create fonts directory
        mkdir -p "${font_dir}"
        
        # Create temporary directory
        TEMP_DIR=$(mktemp -d) || {
            handle_error "Failed to create temporary directory"
            return 1
        }
        cd "$TEMP_DIR" || {
            handle_error "Failed to change to temporary directory: $TEMP_DIR"
            return 1
        }
        
        # Download pinned release
        if [ "$HACKGEN_NF_SHA256" = "REPLACE_WITH_SHA256" ] || [ -z "$HACKGEN_NF_SHA256" ]; then
            handle_error "HACKGEN_NF_SHA256 is not set. Update setup.sh with the pinned checksum."
            return 1
        fi
        echo "[HackGen Font] Downloading v${HACKGEN_VERSION}..."
        local release_base="https://github.com/yuru7/HackGen/releases/download/v${HACKGEN_VERSION}"
        local zip_name="HackGen_NF_v${HACKGEN_VERSION}.zip"

        curl -fL --proto '=https' --tlsv1.2 -o "$zip_name" "${release_base}/${zip_name}"
        if ! verify_sha256 "$zip_name" "$HACKGEN_NF_SHA256"; then
            handle_error "SHA256 verification failed for ${zip_name}"
            return 1
        fi
        
        # Extract and install
        echo "[HackGen Font] Installing fonts..."
        unzip -q "$zip_name"
        cp "HackGen_NF_v${HACKGEN_VERSION}"/*.ttf "${font_dir}/"
        
        # Update font cache if command provided
        if [ -n "$font_update_cmd" ]; then
            eval "$font_update_cmd"
        fi
        
        # Cleanup
        cd - >/dev/null || {
            echo "[WARNING] Failed to return to previous directory"
        }
        rm -rf "$TEMP_DIR" || {
            echo "[WARNING] Failed to remove temporary directory: $TEMP_DIR"
        }
        
        echo "[HackGen Font] Installation completed"
        echo "[HackGen Font] Please set HackGen font in your terminal preferences"
    else
        echo "[HackGen Font] Already installed"
    fi
}

function for_linux() {
    install_prerequisites_linux
    set_default_shell_zsh

    # Homebrew
    if ! type brew > /dev/null 2>&1; then
        if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
            echo "[WARNING] ~/.linuxbrew is deprecated. /home/linuxbrew/.linuxbrew is the recommended prefix."
            eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"
        else
            if [ "$ALLOW_HOMEBREW_INSTALL" = "1" ]; then
                if ! command -v curl >/dev/null 2>&1; then
                    echo "[ERROR] curl not found. Install curl before Homebrew setup."
                    return 1
                fi
                /bin/bash -c "$(curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
                    echo "[WARNING] ~/.linuxbrew is deprecated. /home/linuxbrew/.linuxbrew is the recommended prefix."
                    eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"
                fi
            else
                handle_error "Homebrew not found. Use --allow-homebrew-install to enable automatic install."
                return 1
            fi
        fi
    fi
    
    # クリップボードツールのインストール
    # X11環境用
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            run_with_sudo apt-get install -y xclip
        fi
    elif command -v yum >/dev/null 2>&1; then
        # RedHat/CentOS系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            run_with_sudo yum install -y xclip
        fi
    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            run_with_sudo pacman -S --noconfirm xclip
        fi
    fi
    
    # Wayland環境用（オプション）
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        if command -v apt-get >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
            echo "[Clipboard] Installing wl-clipboard for Wayland support..."
            run_with_sudo apt-get install -y wl-clipboard
        elif command -v pacman >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
            echo "[Clipboard] Installing wl-clipboard for Wayland support..."
            run_with_sudo pacman -S --noconfirm wl-clipboard
        fi
    fi
    
    
    # Setup HackGen font if not installed
    if [ "$WITH_HACKGEN" = "1" ]; then
        if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
            local font_update_cmd=""
            if command -v fc-cache >/dev/null 2>&1; then
                font_update_cmd="fc-cache -fv $HOME/.local/share/fonts/"
            fi
            install_hackgen_font "$HOME/.local/share/fonts" "$font_update_cmd"
        else
            echo "[WARNING] curl or unzip not found. Skipping HackGen font installation."
        fi
    else
        echo "[SKIP] HackGen font installation skipped. Use --with-hackgen to enable."
    fi
}

function for_mac() {
    install_prerequisites_mac
    set_default_shell_zsh

    mkdir -p "${HOME}/Library/Application Support/Code/User"

    for file in keybindings.json settings.json snippets; do
        set_config_file "/config/vscode/${file}" "/Library/Application Support/Code/User/${file}"
    done

    # Setup HackGen font if not installed
    if [ "$WITH_HACKGEN" = "1" ]; then
        install_hackgen_font "$HOME/Library/Fonts" ""
    else
        echo "[SKIP] HackGen font installation skipped. Use --with-hackgen to enable."
    fi
}

function for_local() {
    # Homebrew
    if type brew > /dev/null 2>&1; then
        echo "[brew install]"
        brew install "${PACKAGES[@]}" ghq anyenv coreutils golang direnv ag k1LoW/tap/roots pnpm
    else
        handle_error "Homebrew not found. Install Homebrew before running setup.sh."
        return 1
    fi

    setup_anyenv_nodenv_node

    # ghq
    git config --global ghq.root "$HOME/.ghq"
}

function setup_anyenv_nodenv_node() {
    # anyenvが無い場合はスキップ
    if ! command -v anyenv >/dev/null 2>&1; then
        echo "[WARNING] anyenv not found. Skipping nodenv setup."
        return 0
    fi

    # anyenvの初期化プラグインを確認
    local anyenv_root=""
    anyenv_root="$(anyenv root 2>/dev/null || true)"
    if [ -z "$anyenv_root" ]; then
        anyenv_root="${HOME}/.anyenv"
    fi
    if [ ! -d "${anyenv_root}/plugins/anyenv-install" ]; then
        echo "[anyenv] Initializing plugins..."
        if ! anyenv install --init; then
            echo "[WARNING] anyenv plugin initialization failed. Skipping nodenv setup."
            return 0
        fi
    fi

    # nodenvをanyenv経由で導入
    if [ ! -d "${HOME}/.anyenv/envs/nodenv" ]; then
        echo "[nodenv] Installing via anyenv..."
        if ! anyenv install nodenv; then
            echo "[WARNING] nodenv installation failed"
            return 0
        fi
    else
        echo "[nodenv] Already installed"
    fi

    # nodenvコマンドの解決
    local nodenv_bin=""
    if [ -x "${HOME}/.anyenv/envs/nodenv/bin/nodenv" ]; then
        nodenv_bin="${HOME}/.anyenv/envs/nodenv/bin/nodenv"
    elif command -v nodenv >/dev/null 2>&1; then
        nodenv_bin="$(command -v nodenv)"
    fi

    if [ -z "$nodenv_bin" ]; then
        echo "[WARNING] nodenv not found. Skipping nodenv setup."
        return 0
    fi

    # nodenv rootの解決
    local nodenv_root=""
    nodenv_root="$("$nodenv_bin" root 2>/dev/null || true)"
    if [ -z "$nodenv_root" ]; then
        nodenv_root="${HOME}/.anyenv/envs/nodenv"
    fi

    # node-buildプラグインの導入
    local node_build_dir="${nodenv_root}/plugins/node-build"
    if [ ! -d "$node_build_dir" ]; then
        echo "[nodenv] Installing node-build plugin..."
        mkdir -p "${nodenv_root}/plugins"
        if ! git clone https://github.com/nodenv/node-build.git "$node_build_dir"; then
            echo "[WARNING] node-build installation failed."
            return 0
        fi
    fi

    echo "[nodenv] Setup completed (Node.js installation is skipped)."
}

function set_config_file () {
    SOURCE="${PWD}$1"
    DEST="${HOME}$2"

    # ソースファイルの存在確認
    if [ ! -e "$SOURCE" ]; then
        echo "[ERROR] Source file not found: $SOURCE"
        return 1
    fi

    # ディレクトリの作成（必要な場合）
    DEST_DIR=$(dirname "$DEST")
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR" || {
            echo "[ERROR] Failed to create directory: $DEST_DIR"
            return 1
        }
    fi

    # 宛先がディレクトリの場合はバックアップしてからリンク
    if [[ -d "$DEST" && ! -L "$DEST" ]]; then
        echo "[WARNING] Destination is a directory, backing up: $DEST"
        if ! mv "$DEST" "$DEST.backup.$(date +%Y%m%d%H%M%S)"; then
            echo "[ERROR] Failed to backup directory: $DEST"
            return 1
        fi
    fi

    echo "[symbolic link] $SOURCE => $DEST"
    if test -L "$DEST"; then
        READLINK=$(readlink "$DEST")
        if [ "$READLINK" = "$SOURCE" ]; then
            echo "  already exists"
        else
            echo "  overwrite"
            if ln -nfs "$SOURCE" "$DEST" 2>/dev/null; then
                echo "  done"
            else
                echo "  [ERROR] Failed to create symbolic link"
                return 1
            fi
        fi
    else
        if ln -nfs "$SOURCE" "$DEST" 2>/dev/null; then
            echo "  done"
        else
            echo "  [ERROR] Failed to create symbolic link"
            return 1
        fi
    fi
}

function common() {
    set_config_file "/config/zshrc" "/.zshrc"
    set_config_file "/config/zshenv" "/.zshenv"

    set_config_file "/config/tmux.conf" "/.tmux.conf"
    
    # Setup tmux-powerline configuration
    mkdir -p "${HOME}/.config/tmux-powerline/themes"
    mkdir -p "${HOME}/.config/tmux-powerline/segments"
    set_config_file "/config/tmux-powerline/themes/custom.sh" "/.config/tmux-powerline/themes/custom.sh"
    set_config_file "/config/tmux-powerline-config.sh" "/.config/tmux-powerline/config.sh"
    
    # Link custom tmux-powerline segments directory
    if [[ -d "${HOME}/.tmux/plugins/tmux-powerline/segments" ]]; then
        echo "[tmux-powerline] Linking custom segments..."
        # Create a symbolic link for each custom segment
        for segment in "${PWD}"/config/tmux-powerline/segments/*.sh; do
            if [[ -f "$segment" ]]; then
                segment_name=$(basename "$segment")
                ln -sf "$segment" "${HOME}/.tmux/plugins/tmux-powerline/segments/${segment_name}"
            fi
        done
    fi
    
    # Install TPM if not installed
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
        echo "[TPM] Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
        echo "[TPM] Installation completed. Run prefix + I in tmux to install plugins."
    fi

    mkdir -p "${HOME}/.config/peco"
    set_config_file "/config/peco/config.json" "/.config/peco/config.json"

    set_config_file "/config/tigrc" "/.tigrc"

    # Git template のフック設定
    mkdir -p "${HOME}/.config/git/template/hooks"
    set_config_file "/config/git/template/hooks/pre-commit" "/.config/git/template/hooks/pre-commit"
    chmod +x "${HOME}/.config/git/template/hooks/pre-commit"

    # init.templateDir の設定
    existing_template=$(git config --global --get init.templateDir 2>/dev/null || true)
    target_template="${HOME}/.config/git/template"

    if [[ -z "$existing_template" ]]; then
        git config --global init.templateDir "$target_template"
        echo "[git hooks] Git template configured for new repositories"
    elif [[ "$existing_template" != "$target_template" ]]; then
        echo "[WARNING] init.templateDir is already set to: $existing_template"
        echo "[WARNING] Skipping template configuration. To use gitleaks, run:"
        echo "  git config --global init.templateDir '$target_template'"
    else
        echo "[git hooks] Git template already configured"
    fi

    echo "[git hooks] To apply to existing repos, run: git init (in each repo)"
    
    # Setup vim configuration
    set_config_file "/config/vim/vimrc" "/.vimrc"
    
    # Create .vim directory structure and link only necessary directories
    mkdir -p "${HOME}/.vim"
    
    # Link vim configuration directories (only colors for custom themes)
    if [[ -d "${PWD}/config/vim/vim/colors" ]]; then
        set_config_file "/config/vim/vim/colors" "/.vim/colors"
    fi
    
    # Setup Neovim configuration (symlink to vim config)
    mkdir -p "${HOME}/.config/nvim"
    if [[ -L "${HOME}/.config/nvim/init.vim" ]]; then
        # シンボリックリンクの場合
        READLINK=$(readlink "${HOME}/.config/nvim/init.vim")
        if [[ "$READLINK" = "${HOME}/.vimrc" ]]; then
            echo "[Neovim] Symlink already exists: ~/.config/nvim/init.vim => ~/.vimrc"
        else
            echo "[Neovim] Updating symlink: ~/.config/nvim/init.vim => ~/.vimrc"
            ln -nfs "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
        fi
    elif [[ -e "${HOME}/.config/nvim/init.vim" ]]; then
        # 通常のファイルの場合
        echo "[Neovim] Backing up existing init.vim to init.vim.backup"
        mv "${HOME}/.config/nvim/init.vim" "${HOME}/.config/nvim/init.vim.backup"
        ln -s "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
        echo "[Neovim] Created symlink: ~/.config/nvim/init.vim => ~/.vimrc"
    else
        # ファイルが存在しない場合
        ln -s "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
        echo "[Neovim] Created symlink: ~/.config/nvim/init.vim => ~/.vimrc"
    fi
    
    # Create vim backup/swap/undo directories (in home directory, not in repo)
    mkdir -p "${HOME}/.vim/backup"
    mkdir -p "${HOME}/.vim/swap"
    mkdir -p "${HOME}/.vim/undo"
    
    # Setup zsh modules
    mkdir -p "${HOME}/.config"
    if [[ -d "${PWD}/config/zsh" ]]; then
        # Backup existing directory if not a symlink
        if [[ -e "${HOME}/.config/zsh" ]] && [[ ! -L "${HOME}/.config/zsh" ]]; then
            mv "${HOME}/.config/zsh" "${HOME}/.config/zsh.backup.$(date +%Y%m%d%H%M%S)"
            echo "[zsh modules] Backed up existing config"
        elif [[ -L "${HOME}/.config/zsh" ]]; then
            rm "${HOME}/.config/zsh"
        fi
        # Create symlink instead of copying
        ln -s "${PWD}/config/zsh" "${HOME}/.config/zsh"
        echo "[zsh modules] ${PWD}/config/zsh => ${HOME}/.config/zsh (symlink)"
    fi
    
    # Setup bin directory - PATH is now configured in zsh/05-path.zsh
    # No need to create symlinks since we're using PATH
    echo "[bin directory] PATH will be configured via zsh/05-path.zsh"
}

case $OS in
    Darwin)
        echo "SETUP for Mac"
        common
        for_mac
        for_local
        ;;
    Linux)
        echo "SETUP for Linux"
        common
        for_linux
        for_local
        ;;
    *)
        handle_error "$OS is unsupported" 1
        ;;
esac
