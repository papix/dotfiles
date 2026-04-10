#!/usr/bin/env bash
set -euo pipefail

# HackGen フォント設定（バージョン固定）
# チェックサム算出元: https://github.com/yuru7/HackGen/releases/download/v2.10.0/HackGen_NF_v2.10.0.zip
# 算出方法: curl -fsSLO <URL> && shasum -a 256 HackGen_NF_v2.10.0.zip
HACKGEN_VERSION="2.10.0"
HACKGEN_NF_SHA256="f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428"

# デフォルトシェルをzshに変更（可能な場合のみ）
function set_default_shell_zsh() {
    local zsh_path=""
    zsh_path=$(command -v zsh || true)

    if [ -z "$zsh_path" ]; then
        log_warn "zsh not found. Skipping default shell change."
        return 0
    fi

    if [ -f /etc/shells ]; then
        if ! grep -Fqx "$zsh_path" /etc/shells; then
            log_warn "zsh is not listed in /etc/shells. Skipping default shell change."
            return 0
        fi
    fi

    if [ "$(id -u)" -eq 0 ]; then
        log_warn "Running as root. Skipping default shell change."
        return 0
    fi

    if [ "${SHELL:-}" = "$zsh_path" ]; then
        log_info "Default shell already set to zsh."
        return 0
    fi

    if ! command -v chsh >/dev/null 2>&1; then
        log_warn "chsh not found. Skipping default shell change."
        return 0
    fi

    if [ ! -t 0 ]; then
        log_warn "No TTY available. Skipping default shell change."
        return 0
    fi

    log_action "Changing default shell to zsh..."
    if chsh -s "$zsh_path"; then
        log_info "Default shell updated to ${zsh_path}"
    else
        log_warn "Failed to change default shell. Please run: chsh -s ${zsh_path}"
    fi
}

# 前提パッケージのインストール（Linux）
function install_prerequisites_linux() {
    log_action "Prerequisites: Installing required packages..."
    if command -v apt-get >/dev/null 2>&1; then
        run_with_sudo apt-get install -y build-essential procps curl file git unzip fontconfig zsh
    elif command -v yum >/dev/null 2>&1; then
        run_with_sudo yum install -y gcc-c++ make procps-ng curl file git unzip fontconfig zsh
    elif command -v pacman >/dev/null 2>&1; then
        run_with_sudo pacman -S --noconfirm base-devel procps-ng curl file git unzip fontconfig zsh
    else
        log_warn "No supported package manager found for prerequisites"
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
        log_info "Prerequisites already installed."
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        handle_error "Homebrew not found. Install prerequisites manually: ${missing[*]}"
        return 1
    fi

    log_action "Prerequisites: Installing ${missing[*]}"
    brew install "${missing[@]}"
}

function install_xclip_linux() {
    if command -v xclip >/dev/null 2>&1; then
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        log_action "Clipboard: Installing xclip for X11 clipboard support..."
        run_with_sudo apt-get install -y xclip
        return 0
    fi

    if command -v yum >/dev/null 2>&1; then
        log_action "Clipboard: Installing xclip for X11 clipboard support..."
        run_with_sudo yum install -y xclip
        return 0
    fi

    if command -v pacman >/dev/null 2>&1; then
        log_action "Clipboard: Installing xclip for X11 clipboard support..."
        run_with_sudo pacman -S --noconfirm xclip
        return 0
    fi

    log_warn "Clipboard: No supported package manager for xclip installation. Skipping."
    return 0
}

function install_wl_clipboard_linux() {
    if command -v wl-copy >/dev/null 2>&1; then
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        log_action "Clipboard: Installing wl-clipboard for Wayland support..."
        run_with_sudo apt-get install -y wl-clipboard
        return 0
    fi

    if command -v pacman >/dev/null 2>&1; then
        log_action "Clipboard: Installing wl-clipboard for Wayland support..."
        run_with_sudo pacman -S --noconfirm wl-clipboard
        return 0
    fi

    log_warn "Clipboard: No supported package manager for wl-clipboard installation. Skipping."
    return 0
}

function install_clipboard_tools_linux() {
    install_xclip_linux

    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        install_wl_clipboard_linux
    fi
}

# HackGen fontインストール関数
function install_hackgen_font() {
    local font_dir="$1"
    local font_update_cmd="$2"

    if ! ls "${font_dir}"/HackGen*.ttf >/dev/null 2>&1; then
        log_action "HackGen Font: Installing HackGen Nerd Font..."

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
        log_action "HackGen Font: Downloading v${HACKGEN_VERSION}..."
        local release_base="https://github.com/yuru7/HackGen/releases/download/v${HACKGEN_VERSION}"
        local zip_name="HackGen_NF_v${HACKGEN_VERSION}.zip"

        curl -fL --proto '=https' --tlsv1.2 -o "$zip_name" "${release_base}/${zip_name}"
        if ! verify_sha256 "$zip_name" "$HACKGEN_NF_SHA256"; then
            handle_error "SHA256 verification failed for ${zip_name}"
            return 1
        fi

        # Extract and install
        log_action "HackGen Font: Installing fonts..."
        unzip -q "$zip_name"
        cp "HackGen_NF_v${HACKGEN_VERSION}"/*.ttf "${font_dir}/"

        # Update font cache if command provided
        if [ -n "$font_update_cmd" ]; then
            eval "$font_update_cmd"
        fi

        # Cleanup
        cd - >/dev/null || {
            log_warn "Failed to return to previous directory"
        }
        rm -rf "$TEMP_DIR" || {
            log_warn "Failed to remove temporary directory: $TEMP_DIR"
        }

        log_info "HackGen Font: Installation completed"
        log_info "HackGen Font: Please set HackGen font in your terminal preferences"
    else
        log_info "HackGen Font: Already installed"
    fi
}

function for_linux() {
    install_prerequisites_linux
    set_default_shell_zsh

    # Homebrew
    if ! type brew > /dev/null 2>&1; then
        if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        else
            if [ "$ALLOW_HOMEBREW_INSTALL" = "1" ]; then
                if ! command -v curl >/dev/null 2>&1; then
                    log_error "curl not found. Install curl before Homebrew setup."
                    return 1
                fi
                /bin/bash -c "$(curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                else
                    handle_error "Homebrew installation completed but brew was not found at /home/linuxbrew/.linuxbrew/bin/brew."
                    return 1
                fi
            else
                handle_error "Homebrew not found. Use --allow-homebrew-install to enable automatic install."
                return 1
            fi
        fi
    fi

    install_clipboard_tools_linux

    # Setup HackGen font if not installed
    if [ "$WITH_HACKGEN" = "1" ]; then
        if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
            local font_update_cmd=""
            if command -v fc-cache >/dev/null 2>&1; then
                font_update_cmd="fc-cache -fv $HOME/.local/share/fonts/"
            fi
            install_hackgen_font "$HOME/.local/share/fonts" "$font_update_cmd"
        else
            log_warn "curl or unzip not found. Skipping HackGen font installation."
        fi
    else
        log_skip "HackGen font installation skipped. Use --with-hackgen to enable."
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
        log_skip "HackGen font installation skipped. Use --with-hackgen to enable."
    fi
}
