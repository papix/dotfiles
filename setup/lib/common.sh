#!/usr/bin/env bash
set -euo pipefail

function setup_config_home() {
    printf '%s\n' "${XDG_CONFIG_HOME:-${HOME}/.config}"
}

function setup_cache_home() {
    printf '%s\n' "${XDG_CACHE_HOME:-${HOME}/.cache}"
}

function setup_state_home() {
    printf '%s\n' "${XDG_STATE_HOME:-${HOME}/.local/state}"
}

function set_config_file_target() {
    local SOURCE DEST DEST_DIR READLINK
    SOURCE="${DOTFILES_DIR}$1"
    DEST="$2"

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
        # 宛先が通常ファイルの場合はバックアップしてからリンク
        if [[ -f "$DEST" && ! -L "$DEST" ]]; then
            log_warn "Destination is a regular file, backing up: $DEST"
            if ! mv "$DEST" "$DEST.backup.$(date +%Y%m%d%H%M%S)"; then
                log_error "Failed to backup file: $DEST"
                return 1
            fi
        fi
        if ln -nfs "$SOURCE" "$DEST" 2>/dev/null; then
            log_info "symbolic link: done"
        else
            log_error "Failed to create symbolic link"
            return 1
        fi
    fi
}

function set_config_file() {
    set_config_file_target "$1" "${HOME}$2"
}

function setup_tmux_config() {
    local config_home
    config_home="$(setup_config_home)"

    set_config_file "/config/tmux.conf" "/.tmux.conf"

    # Setup tmux-powerline configuration
    mkdir -p "${config_home}/tmux-powerline/themes"
    mkdir -p "${config_home}/tmux-powerline/segments"
    set_config_file_target "/config/tmux-powerline/themes/custom.sh" "${config_home}/tmux-powerline/themes/custom.sh"
    set_config_file_target "/config/tmux-powerline-config.sh" "${config_home}/tmux-powerline/config.sh"

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

function is_legacy_post_checkout_hook() {
    local hook_path="$1"
    local link_target=""

    [[ -e "$hook_path" || -L "$hook_path" ]] || return 1

    if [[ -L "$hook_path" ]]; then
        link_target="$(readlink "$hook_path" 2>/dev/null || true)"
        case "$link_target" in
        */config/git/template/hooks/post-checkout)
            return 0
            ;;
        esac
    fi

    [[ -f "$hook_path" ]] || return 1
    grep -F -- '.worktree-sync' "$hook_path" >/dev/null 2>&1 || return 1
    grep -F -- 'git-common-dir' "$hook_path" >/dev/null 2>&1 || return 1
    return 0
}

function cleanup_legacy_post_checkout_hook() {
    local hook_path="$1"

    is_legacy_post_checkout_hook "$hook_path" || return 1
    rm -f "$hook_path"
    log_info "git hooks: Removed legacy post-checkout hook: $hook_path"
}

function cleanup_legacy_git_template_hooks() {
    local config_home legacy_hook
    config_home="$(setup_config_home)"
    legacy_hook="${config_home}/git/template/hooks/post-checkout"

    cleanup_legacy_post_checkout_hook "$legacy_hook" || true
}

function cleanup_legacy_existing_repo_hooks() {
    local repo_root hook_path
    repo_root="${HOME}/.ghq"
    [[ -d "$repo_root" ]] || return 0

    while IFS= read -r hook_path; do
        cleanup_legacy_post_checkout_hook "$hook_path" || true
    done < <(find "$repo_root" \( -type f -o -type l \) -path '*/.git/hooks/post-checkout' -print 2>/dev/null)
}

function setup_git_config() {
    local config_home
    config_home="$(setup_config_home)"

    # Git template のフック設定
    mkdir -p "${config_home}/git/template/hooks"
    cleanup_legacy_git_template_hooks
    cleanup_legacy_existing_repo_hooks
    set_config_file_target "/config/git/template/hooks/pre-commit" "${config_home}/git/template/hooks/pre-commit"
    chmod +x "${config_home}/git/template/hooks/pre-commit"
    set_config_file_target "/config/git/template/hooks/pre-push" "${config_home}/git/template/hooks/pre-push"
    chmod +x "${config_home}/git/template/hooks/pre-push"

    # Husky 用の初期化スクリプト
    set_config_file_target "/config/husky/init.sh" "${config_home}/husky/init.sh"

    # init.templateDir の設定
    existing_template=$(git config --global --get init.templateDir 2>/dev/null || true)
    target_template="${config_home}/git/template"

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
    local config_home
    config_home="$(setup_config_home)"

    # Setup Neovim configuration
    mkdir -p "${config_home}/nvim"
    set_config_file_target "/config/nvim/init.lua" "${config_home}/nvim/init.lua"
    set_config_file_target "/config/nvim/lua" "${config_home}/nvim/lua"

    # 互換用: init.vim と init.lua の両方が未配置の場合のみ ~/.vimrc を参照
    if [[ ! -e "${config_home}/nvim/init.vim" && ! -e "${config_home}/nvim/init.lua" ]]; then
        ln -s "${HOME}/.vimrc" "${config_home}/nvim/init.vim"
        log_info "Neovim: Created fallback symlink: ${config_home}/nvim/init.vim => ~/.vimrc"
    fi
}

function setup_zsh_config() {
    local config_home
    config_home="$(setup_config_home)"

    # Setup zsh modules
    mkdir -p "${config_home}"
    if [[ -d "${DOTFILES_DIR}/config/zsh" ]]; then
        # Backup existing directory if not a symlink
        if [[ -e "${config_home}/zsh" ]] && [[ ! -L "${config_home}/zsh" ]]; then
            mv "${config_home}/zsh" "${config_home}/zsh.backup.$(date +%Y%m%d%H%M%S)"
            log_info "zsh modules: Backed up existing config"
        elif [[ -L "${config_home}/zsh" ]]; then
            rm "${config_home}/zsh"
        fi
        # Create symlink instead of copying
        ln -s "${DOTFILES_DIR}/config/zsh" "${config_home}/zsh"
        log_info "zsh modules: ${DOTFILES_DIR}/config/zsh => ${config_home}/zsh (symlink)"
    fi
}

function setup_bin_links() {
    local source_file link_target existing_target backup_path

    mkdir -p "${HOME}/.local/bin"

    for source_file in "${DOTFILES_DIR}"/bin/*; do
        [[ -f "$source_file" ]] || continue
        [[ -x "$source_file" ]] || continue

        link_target="${HOME}/.local/bin/$(basename "$source_file")"
        if [[ -L "$link_target" ]]; then
            existing_target="$(readlink "$link_target")"
            if [[ "$existing_target" = "$source_file" ]]; then
                log_info "symbolic link: already exists"
                continue
            fi
        fi

        if [[ -e "$link_target" || -L "$link_target" ]]; then
            backup_path="${link_target}.backup.$(date +%Y%m%d%H%M%S)"
            log_warn "symbolic link conflict: backing up ${link_target} to ${backup_path}"
            mv "$link_target" "$backup_path"
        fi

        log_action "symbolic link: $source_file => $link_target"
        ln -s "$source_file" "$link_target"
    done
}

function common() {
    local config_home cache_home state_home
    config_home="$(setup_config_home)"
    cache_home="$(setup_cache_home)"
    state_home="$(setup_state_home)"

    mkdir -p "${state_home}/zsh"
    mkdir -p "${cache_home}/dotfiles"
    set_config_file "/config/zshrc" "/.zshrc"
    set_config_file "/config/zshenv" "/.zshenv"
    set_config_file_target "/config/env-common.sh" "${config_home}/env-common.sh"
    set_config_file_target "/config/bash_env.sh" "${config_home}/bash_env.sh"
    set_config_file_target "/config/claude_env.sh" "${config_home}/claude_env.sh"

    setup_tmux_config

    mkdir -p "${config_home}/peco"
    set_config_file_target "/config/peco/config.json" "${config_home}/peco/config.json"
    set_config_file "/config/tigrc" "/.tigrc"

    setup_git_config
    setup_vim_config
    setup_neovim_config
    setup_zsh_config
    setup_bin_links
}
