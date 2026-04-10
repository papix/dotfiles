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
    local os_name profile_name packages_output
    local packages=()
    local package_name=""

    os_name=$(uname -s)
    profile_name="${SETUP_PROFILE:-full}"
    packages_output="$(setup_load_packages "$os_name" "$profile_name")" || {
        handle_error "Failed to load package profile: os=${os_name}, profile=${profile_name}"
        return 1
    }

    while IFS= read -r package_name; do
        [ -n "$package_name" ] || continue
        packages+=("$package_name")
    done <<< "$packages_output"

    # Homebrew
    if type brew > /dev/null 2>&1; then
        if [ "${#packages[@]}" -eq 0 ]; then
            log_warn "No packages configured for profile ${profile_name}. Skipping brew install."
        else
            log_action "brew install (${profile_name})"
            brew install "${packages[@]}"
        fi
        install_platform_homebrew_casks
    else
        handle_error "Homebrew not found. Install Homebrew before running setup.sh."
        return 1
    fi

    setup_mise

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
        cat > "$mise_global_config" << 'TOML'
[tools]
# node = "lts"  # 必要に応じてコメント解除
TOML
        log_info "mise: Global config created at $mise_global_config"
    else
        log_info "mise: Global config already exists."
    fi

    log_info "mise setup completed."
}
