#!/usr/bin/env bash
set -euo pipefail

# Package profiles are managed under setup/profiles/*.txt
SETUP_PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../profiles" && pwd)"

function setup_profile_file_path() {
    local os_name="$1"
    local profile_name="$2"
    local os_key
    os_key="$(printf '%s' "$os_name" | tr '[:upper:]' '[:lower:]')"

    case "$os_key" in
        darwin|linux)
            ;;
        *)
            return 1
            ;;
    esac

    printf '%s/%s-%s.txt\n' "$SETUP_PROFILES_DIR" "$os_key" "$profile_name"
}

function setup_load_packages() {
    local os_name="$1"
    local profile_name="${2:-full}"
    local profile_file
    profile_file="$(setup_profile_file_path "$os_name" "$profile_name")" || return 1

    if [[ ! -f "$profile_file" ]]; then
        echo "[ERROR] package profile file not found: $profile_file" >&2
        return 1
    fi

    local line trimmed
    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="$(printf '%s' "$line" | sed 's/#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
        [[ -n "$trimmed" ]] || continue
        printf '%s\n' "$trimmed"
    done < "$profile_file"
}
