#!/usr/bin/env bash
set -euo pipefail

function set_config_file() {
    local SOURCE DEST DEST_DIR READLINK
    SOURCE="${DOTFILES_DIR}$1"
    DEST="${HOME}$2"

    # ソースファイルの存在確認
    if [ ! -e "$SOURCE" ]; then
        log_error "Source file not found: $SOURCE"
        return 1
    fi

    # ディレクトリの作成（必要な場合）
    DEST_DIR=$(dirname "$DEST")
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR" || {
            log_error "Failed to create directory: $DEST_DIR"
            return 1
        }
    fi

    # 宛先がディレクトリの場合はバックアップしてからリンク
    if [[ -d "$DEST" && ! -L "$DEST" ]]; then
        log_warn "Destination is a directory, backing up: $DEST"
        if ! mv "$DEST" "$DEST.backup.$(date +%Y%m%d%H%M%S)"; then
            log_error "Failed to backup directory: $DEST"
            return 1
        fi
    fi

    log_action "symbolic link: $SOURCE => $DEST"
    if test -L "$DEST"; then
        READLINK=$(readlink "$DEST")
        if [ "$READLINK" = "$SOURCE" ]; then
            log_info "symbolic link: already exists"
        else
            log_info "symbolic link: overwrite"
            if ln -nfs "$SOURCE" "$DEST" 2>/dev/null; then
                log_info "symbolic link: done"
            else
                log_error "Failed to create symbolic link"
                return 1
            fi
        fi
    else
        if ln -nfs "$SOURCE" "$DEST" 2>/dev/null; then
            log_info "symbolic link: done"
        else
            log_error "Failed to create symbolic link"
            return 1
        fi
    fi
}

function setup_tmux_config() {
    set_config_file "/config/tmux.conf" "/.tmux.conf"

    # Setup tmux-powerline configuration
    mkdir -p "${HOME}/.config/tmux-powerline/themes"
    mkdir -p "${HOME}/.config/tmux-powerline/segments"
    set_config_file "/config/tmux-powerline/themes/custom.sh" "/.config/tmux-powerline/themes/custom.sh"
    set_config_file "/config/tmux-powerline-config.sh" "/.config/tmux-powerline/config.sh"

    # Link custom tmux-powerline segments directory
    if [[ -d "${HOME}/.tmux/plugins/tmux-powerline/segments" ]]; then
        log_action "tmux-powerline: Linking custom segments..."
        # Create a symbolic link for each custom segment
        for segment in "${DOTFILES_DIR}"/config/tmux-powerline/segments/*.sh; do
            if [[ -f "$segment" ]]; then
                segment_name=$(basename "$segment")
                ln -sf "$segment" "${HOME}/.tmux/plugins/tmux-powerline/segments/${segment_name}"
            fi
        done
    fi

    # Install TPM if not installed
    if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
        log_action "TPM: Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
        log_info "TPM: Installation completed. Run prefix + I in tmux to install plugins."
    fi
}

function setup_git_config() {
    # Git template のフック設定
    mkdir -p "${HOME}/.config/git/template/hooks"
    set_config_file "/config/git/template/hooks/pre-commit" "/.config/git/template/hooks/pre-commit"
    chmod +x "${HOME}/.config/git/template/hooks/pre-commit"
    set_config_file "/config/git/template/hooks/pre-push" "/.config/git/template/hooks/pre-push"
    chmod +x "${HOME}/.config/git/template/hooks/pre-push"
    set_config_file "/config/git/template/hooks/post-checkout" "/.config/git/template/hooks/post-checkout"
    chmod +x "${HOME}/.config/git/template/hooks/post-checkout"

    # Husky 用の初期化スクリプト
    set_config_file "/config/husky/init.sh" "/.config/husky/init.sh"

    # init.templateDir の設定
    existing_template=$(git config --global --get init.templateDir 2>/dev/null || true)
    target_template="${HOME}/.config/git/template"

    if [[ -z "$existing_template" ]]; then
        git config --global init.templateDir "$target_template"
        log_info "git hooks: Git template configured for new repositories"
    elif [[ "$existing_template" != "$target_template" ]]; then
        log_warn "init.templateDir is already set to: $existing_template"
        log_warn "Skipping template configuration. To use gitleaks, run:"
        echo "  git config --global init.templateDir '$target_template'"
    else
        log_info "git hooks: Git template already configured"
    fi

    log_info "git hooks: To apply to existing repos, run: git init (in each repo)"

    # グローバルgitignoreの設定
    set_config_file "/config/git/gitignore_global" "/.gitignore_global"
    existing_excludes=$(git config --global --get core.excludesfile 2>/dev/null || true)
    target_excludes="${HOME}/.gitignore_global"

    if [[ -z "$existing_excludes" ]]; then
        git config --global core.excludesfile "$target_excludes"
        log_info "git ignore: Global excludes configured"
    elif [[ "$existing_excludes" != "$target_excludes" ]]; then
        log_warn "core.excludesfile is already set to: $existing_excludes"
        log_warn "Skipping global ignore configuration. To use this repo's file, run:"
        echo "  git config --global core.excludesfile '$target_excludes'"
    else
        log_info "git ignore: Global excludes already configured"
    fi
}

function setup_vim_config() {
    # Setup vim configuration
    set_config_file "/config/vim/vimrc" "/.vimrc"

    # Create .vim directory structure and link only necessary directories
    mkdir -p "${HOME}/.vim"

    # Link vim configuration directories (only colors for custom themes)
    if [[ -d "${DOTFILES_DIR}/config/vim/vim/colors" ]]; then
        set_config_file "/config/vim/vim/colors" "/.vim/colors"
    fi

    # Create vim backup/swap/undo directories (in home directory, not in repo)
    mkdir -p "${HOME}/.vim/backup"
    mkdir -p "${HOME}/.vim/swap"
    mkdir -p "${HOME}/.vim/undo"
}

function setup_neovim_config() {
    # Setup Neovim configuration
    mkdir -p "${HOME}/.config/nvim"
    set_config_file "/config/nvim/init.lua" "/.config/nvim/init.lua"
    set_config_file "/config/nvim/lua" "/.config/nvim/lua"

    # 互換用: init.vim と init.lua の両方が未配置の場合のみ ~/.vimrc を参照
    if [[ ! -e "${HOME}/.config/nvim/init.vim" && ! -e "${HOME}/.config/nvim/init.lua" ]]; then
        ln -s "${HOME}/.vimrc" "${HOME}/.config/nvim/init.vim"
        log_info "Neovim: Created fallback symlink: ~/.config/nvim/init.vim => ~/.vimrc"
    fi
}

function setup_zsh_config() {
    # Setup zsh modules
    mkdir -p "${HOME}/.config"
    if [[ -d "${DOTFILES_DIR}/config/zsh" ]]; then
        # Backup existing directory if not a symlink
        if [[ -e "${HOME}/.config/zsh" ]] && [[ ! -L "${HOME}/.config/zsh" ]]; then
            mv "${HOME}/.config/zsh" "${HOME}/.config/zsh.backup.$(date +%Y%m%d%H%M%S)"
            log_info "zsh modules: Backed up existing config"
        elif [[ -L "${HOME}/.config/zsh" ]]; then
            rm "${HOME}/.config/zsh"
        fi
        # Create symlink instead of copying
        ln -s "${DOTFILES_DIR}/config/zsh" "${HOME}/.config/zsh"
        log_info "zsh modules: ${DOTFILES_DIR}/config/zsh => ${HOME}/.config/zsh (symlink)"
    fi
}

function setup_gwq_config() {
    if [[ -e "${HOME}/.config/gwq/config.toml" && ! -L "${HOME}/.config/gwq/config.toml" ]]; then
        mv "${HOME}/.config/gwq/config.toml" "${HOME}/.config/gwq/config.toml.backup.$(date +%Y%m%d%H%M%S)"
        log_info "gwq config: Backed up existing config"
    fi
    mkdir -p "${HOME}/.config/gwq"
    set_config_file "/config/gwq/config.toml" "/.config/gwq/config.toml"
}

function common() {
    set_config_file "/config/zshrc" "/.zshrc"
    set_config_file "/config/zshenv" "/.zshenv"
    set_config_file "/config/bash_env.sh" "/.config/bash_env.sh"
    set_config_file "/config/claude_env.sh" "/.config/claude_env.sh"

    setup_tmux_config

    mkdir -p "${HOME}/.config/peco"
    set_config_file "/config/peco/config.json" "/.config/peco/config.json"
    set_config_file "/config/tigrc" "/.tigrc"

    setup_gwq_config
    setup_git_config
    setup_vim_config
    setup_neovim_config
    setup_zsh_config

    # Setup bin directory - PATH is now configured in config/zshenv
    # No need to create symlinks since we're using PATH
    log_info "bin directory: PATH will be configured via config/zshenv"
}
