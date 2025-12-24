#!/bin/bash
set -eu

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

PACKAGES=(peco tmux tig zsh colordiff tree tldr git neovim shellcheck gh gitleaks)
OS=$(uname)
PWD=$(pwd)

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
        
        # Download latest release
        echo "[HackGen Font] Downloading latest release..."
        HACKGEN_VERSION=$(curl -fsSL https://api.github.com/repos/yuru7/HackGen/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' || true)
        if [ -z "$HACKGEN_VERSION" ]; then
            echo "[HackGen Font] Failed to get latest version, using fallback version"
            HACKGEN_VERSION="2.9.0"
        fi

        local release_base="https://github.com/yuru7/HackGen/releases/download/v${HACKGEN_VERSION}"
        local zip_name="HackGen_NF_v${HACKGEN_VERSION}.zip"
        local checksum_file=""

        # Try to download checksum file if available
        for candidate in SHA256SUMS SHA256SUMS.txt; do
            if curl -fsSL -o "$candidate" "${release_base}/${candidate}"; then
                checksum_file="$candidate"
                break
            fi
        done

        curl -fL --proto '=https' --tlsv1.2 -o "$zip_name" "${release_base}/${zip_name}"

        if [ -n "$checksum_file" ]; then
            local checksum_line=""
            local expected=""
            checksum_line=$(grep -E "[[:space:]]\*?${zip_name}([[:space:]]|$)" "$checksum_file" | head -n 1 || true)
            if [ -n "$checksum_line" ]; then
                expected=$(echo "$checksum_line" | awk '{print $1}')
            else
                checksum_line=$(grep -E "SHA256[[:space:]]*\\(${zip_name}\\)[[:space:]]*=" "$checksum_file" | head -n 1 || true)
                if [ -n "$checksum_line" ]; then
                    expected=$(echo "$checksum_line" | awk -F '=' '{print $2}' | tr -d '[:space:]')
                fi
            fi

            if [ -n "$expected" ]; then
                verify_sha256 "$zip_name" "$expected"
                case $? in
                    0)
                        ;;
                    2)
                        if [ "${ALLOW_UNVERIFIED_DOWNLOAD:-}" != "1" ]; then
                            handle_error "Checksum tool not found. Set ALLOW_UNVERIFIED_DOWNLOAD=1 to continue."
                            return 1
                        fi
                        ;;
                    *)
                        handle_error "Checksum verification failed for ${zip_name}"
                        return 1
                        ;;
                esac
            else
                if [ "${ALLOW_UNVERIFIED_DOWNLOAD:-}" != "1" ]; then
                    handle_error "Checksum entry not found for ${zip_name}. Set ALLOW_UNVERIFIED_DOWNLOAD=1 to continue."
                    return 1
                fi
            fi
        else
            if [ "${ALLOW_UNVERIFIED_DOWNLOAD:-}" != "1" ]; then
                handle_error "Checksum file not found. Set ALLOW_UNVERIFIED_DOWNLOAD=1 to continue."
                return 1
            fi
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
    # for Homebrew
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y build-essential procps curl file git unzip fontconfig
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y gcc-c++ make procps-ng curl file git unzip fontconfig
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm base-devel procps-ng curl file git unzip fontconfig
    else
        echo "[WARNING] No supported package manager found for build dependencies"
    fi

    # Homebrew
    if ! type brew > /dev/null 2>&1; then
        if ! command -v curl >/dev/null 2>&1; then
            echo "[ERROR] curl not found. Install curl before Homebrew setup."
            return 1
        fi

        if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
            eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"
        else
            if [ "${ALLOW_HOMEBREW_INSTALL:-}" != "1" ]; then
                handle_error "Homebrew not found. Set ALLOW_HOMEBREW_INSTALL=1 to run the official install script."
                return 1
            fi
            /bin/bash -c "$(curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
                eval "$("${HOME}/.linuxbrew/bin/brew" shellenv)"
            fi
        fi
    fi
    
    # クリップボードツールのインストール
    # X11環境用
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            sudo apt-get install -y xclip
        fi
    elif command -v yum >/dev/null 2>&1; then
        # RedHat/CentOS系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            sudo yum install -y xclip
        fi
    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux系
        if ! command -v xclip >/dev/null 2>&1; then
            echo "[Clipboard] Installing xclip for X11 clipboard support..."
            sudo pacman -S --noconfirm xclip
        fi
    fi
    
    # Wayland環境用（オプション）
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        if command -v apt-get >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
            echo "[Clipboard] Installing wl-clipboard for Wayland support..."
            sudo apt-get install -y wl-clipboard
        elif command -v pacman >/dev/null 2>&1 && ! command -v wl-copy >/dev/null 2>&1; then
            echo "[Clipboard] Installing wl-clipboard for Wayland support..."
            sudo pacman -S --noconfirm wl-clipboard
        fi
    fi
    
    
    # Setup HackGen font if not installed
    if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
        local font_update_cmd=""
        if command -v fc-cache >/dev/null 2>&1; then
            font_update_cmd="fc-cache -fv $HOME/.local/share/fonts/"
        fi
        install_hackgen_font "$HOME/.local/share/fonts" "$font_update_cmd"
    else
        echo "[WARNING] curl or unzip not found. Skipping HackGen font installation."
    fi
}

function for_mac() {
    mkdir -p "${HOME}/Library/Application Support/Code/User"

    for file in keybindings.json settings.json snippets; do
        set_config_file "/config/vscode/${file}" "/Library/Application Support/Code/User/${file}"
    done

    # Setup HackGen font if not installed
    install_hackgen_font "$HOME/Library/Fonts" ""
}

function for_local() {
    # Homebrew
    if type brew > /dev/null 2>&1; then
        echo "[brew install]"
    else
        handle_error "Setup required: brew" 1
    fi

    brew install "${PACKAGES[@]}" ghq anyenv coreutils golang direnv ag k1LoW/tap/roots pnpm

    # ghq
    git config --global ghq.root "$HOME/.ghq"
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
