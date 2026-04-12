#!/usr/bin/env bash
set -euo pipefail

function is_apple_silicon_mac() {
    local arm64_capable=""

    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 1
    fi

    if [[ "$(uname -m)" = "arm64" ]]; then
        return 0
    fi

    if ! command -v sysctl >/dev/null 2>&1; then
        return 1
    fi

    # Rosetta 経由の実行でも Apple Silicon を判定できるようにする
    arm64_capable="$(sysctl -in hw.optional.arm64 2>/dev/null || true)"
    [[ "$arm64_capable" = "1" ]]
}

function install_platform_homebrew_casks() {
    local casks=()

    if is_apple_silicon_mac; then
        casks+=(altair-graphql-client)
    fi

    if [ "${#casks[@]}" -eq 0 ]; then
        return 0
    fi

    log_action "brew install --cask"
    brew install --cask "${casks[@]}"
}

function for_local() {
    local os_name profile_name package_files_output
    local package_files=()
    local package_file=""

    os_name=$(uname -s)
    profile_name="${SETUP_PROFILE:-full}"
    package_files_output="$(setup_list_package_files "$os_name" "$profile_name")" || {
        handle_error "Failed to resolve package files: os=${os_name}, profile=${profile_name}"
        return 1
    }

    while IFS= read -r package_file; do
        [ -n "$package_file" ] || continue
        if [[ ! -f "$package_file" ]]; then
            handle_error "Package file not found: $package_file"
            return 1
        fi
        package_files+=("$package_file")
    done <<<"$package_files_output"

    # Homebrew
    if type brew >/dev/null 2>&1; then
        if [ "${#package_files[@]}" -eq 0 ]; then
            log_warn "No package files configured for profile ${profile_name}. Skipping brew bundle."
        else
            for package_file in "${package_files[@]}"; do
                if brew bundle check --file="$package_file" --no-upgrade >/dev/null 2>&1; then
                    log_info "brew bundle: already satisfied (${package_file})"
                    continue
                fi

                log_action "brew bundle (${profile_name})"
                brew bundle --file="$package_file" --no-upgrade
            done
        fi
        install_platform_homebrew_casks
    else
        handle_error "Homebrew not found. Install Homebrew before running setup.sh."
        return 1
    fi

    setup_mise
    setup_anyenv

    # ghq
    git config --global ghq.root "$HOME/.ghq"
}

function setup_mise() {
    if ! command -v mise >/dev/null 2>&1; then
        log_warn "mise not found. Skipping mise setup."
        return 0
    fi

    local mise_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
    if [ ! -d "$mise_config_dir" ]; then
        mkdir -p "$mise_config_dir"
    fi

    local mise_global_config="$mise_config_dir/config.toml"
    if [ ! -f "$mise_global_config" ]; then
        log_action "mise: Creating global config..."
        cat >"$mise_global_config" <<'TOML'
[tools]
# node = "lts"  # 必要に応じてコメント解除
TOML
        log_info "mise: Global config created at $mise_global_config"
    else
        log_info "mise: Global config already exists."
    fi

    log_info "mise setup completed."
}

function setup_anyenv() {
    if ! command -v anyenv >/dev/null 2>&1; then
        log_warn "anyenv not found. Skipping anyenv setup."
        return 0
    fi

    local anyenv_definition_root="${ANYENV_DEFINITION_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/anyenv/anyenv-install}"
    if [ ! -d "$anyenv_definition_root" ]; then
        log_action "anyenv: Initializing install manifests..."
        if ! anyenv install --force-init; then
            handle_error "anyenv: Failed to initialize install manifests."
            return 1
        fi
        log_info "anyenv: Install manifests initialized at $anyenv_definition_root"
    else
        log_info "anyenv: Install manifests already exist."
    fi

    log_info "anyenv setup completed."
}
