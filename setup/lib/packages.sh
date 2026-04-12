#!/usr/bin/env bash
set -euo pipefail

# Homebrew bundles are managed with Brewfile variants at the repository root.
SETUP_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

function setup_package_os_key() {
    local os_name="$1"
    local os_key
    os_key="$(printf '%s' "$os_name" | tr '[:upper:]' '[:lower:]')"

    case "$os_key" in
    darwin | linux) ;;
    *)
        return 1
        ;;
    esac

    printf '%s\n' "$os_key"
}

function setup_package_bundle_name() {
    local profile_name="${1:-full}"

    case "$profile_name" in
    full)
        printf 'Brewfile\n'
        ;;
    minimal)
        printf 'Brewfile.minimal\n'
        ;;
    *)
        return 1
        ;;
    esac
}

function setup_list_package_files() {
    local os_name="$1"
    local profile_name="${2:-full}"
    local os_key bundle_name

    os_key="$(setup_package_os_key "$os_name")" || return 1
    bundle_name="$(setup_package_bundle_name "$profile_name")" || return 1

    printf '%s/%s\n' "$SETUP_REPO_ROOT" "$bundle_name"
    printf '%s/%s.%s\n' "$SETUP_REPO_ROOT" "$bundle_name" "$os_key"
}

function setup_load_packages() {
    local os_name="$1"
    local profile_name="${2:-full}"
    local package_file=""

    while IFS= read -r package_file; do
        if [[ ! -f "$package_file" ]]; then
            echo "[ERROR] package file not found: $package_file" >&2
            return 1
        fi

        sed -nE 's/^[[:space:]]*(brew|cask|tap)[[:space:]]+"([^"]+)".*$/\2/p' "$package_file"
    done < <(setup_list_package_files "$os_name" "$profile_name")
}
