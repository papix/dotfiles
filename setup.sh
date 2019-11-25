#!/usr/bin/env bash
set -eu

PACKAGES=(peco tmux tig zsh colordiff tree tldr git)
OS=$(uname)
PWD=$(pwd)

function for_linux() {
    # for Homebrew
    sudo apt-get install -y build-essential procps curl file git

    # Homebrew
    if which brew > /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

function for_mac() {
    mkdir -p "${HOME}/Library/Application\ Support/Code/User"

    for file in keybindings.json settings.json snippets; do
        set_config_file "/config/vscode/${file}" "/Library/Application Support/Code/User/${file}"
    done
}

function for_codespaces() {
    sudo apt-get update
    sudo apt-get install -y ${PACKAGES[@]} silversearcher-ag uuid-runtime

    sudo chsh "$(id -un)" --shell "/usr/bin/zsh"
}

function for_local() {
    # Homebrew
    if command -v "brew" > /dev/null 2>&1; then
        echo "[brew install]"
    else
        echo "[ERROR] Setup required: brew"
        exit 1;
    fi

    brew install ${PACKAGES[@]} ghq anyenv coreutils golang direnv ag k1LoW/tap/roots

    # ghq
    git config --global ghq.root '~/.ghq'
}

function set_config_file () {
    SOURCE="${PWD}$1"
    DEST="${HOME}$2"

    if is_codespaces; then
        echo "[copy] $SOURCE => $DEST"
        cp "$SOURCE" "$DEST"
        echo "  done"
    else 
        echo "[symbolic link] $SOURCE => $DEST"
        if test -L "$DEST"; then
            READLINK=$(readlink "$DEST")
            if [ "$READLINK" = "$SOURCE" ]; then
                echo "  already exists"
            else
                echo "  overwrite"
                ln -nfs "$SOURCE" "$DEST"
            fi
        else
            ln -nfs "$SOURCE" "$DEST"
            echo "  done"
        fi
    fi
}

function is_codespaces() {
    if [ -n "${CODESPACES:-}" ]; then
        return 0
    else
        return 1
    fi
}

function common() {
    set_config_file "/config/zshrc" "/.zshrc"
    set_config_file "/config/zshrc.alias" "/.zshrc.alias"
    set_config_file "/config/zshenv" "/.zshenv"

    set_config_file "/config/tmux.conf" "/.tmux.conf"

    mkdir -p ${HOME}/.config/peco
    set_config_file "/config/peco/config.json" "/.config/peco/config.json"

    set_config_file "/config/tigrc" "/.tigrc"
}

case $OS in
    Darwin)
        echo "SETUP for Mac"
        common
        for_mac
        exit 1;
        for_local
        ;;
    Linux)
        if is_codespaces; then
            echo "SETUP for Codespaces"
            common
            for_codespaces
        else
            echo "SETUP for Linux"
            common
            for_linux
            for_local
        fi
        ;;
    *)
        echo "ERROR: $OS is unsupported"
        exit 1;
        ;;
esac