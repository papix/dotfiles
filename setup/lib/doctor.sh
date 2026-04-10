#!/usr/bin/env bash
set -euo pipefail

function __setup_doctor_escape_json() {
    local value="$1"
    printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

function __setup_doctor_command_path() {
    local command_name="$1"
    type -P "$command_name" 2>/dev/null || true
}

function __setup_doctor_command_status() {
    local command_name="$1"
    local command_path
    command_path="$(__setup_doctor_command_path "$command_name")"

    if [[ -n "$command_path" ]]; then
        printf '  - %s: ok (%s)\n' "$command_name" "$command_path"
    else
        printf '  - %s: missing\n' "$command_name"
    fi
}

function __setup_doctor_print_text() {
    local os_name="$1"
    local profile_name="${SETUP_PROFILE:-full}"
    local profile_file
    local package_count

    profile_file="$(setup_profile_file_path "$os_name" "$profile_name" 2>/dev/null || true)"

    echo "Doctor mode"
    echo "Profile: ${profile_name}"
    echo "Detected OS: ${os_name}"

    if [[ -n "$profile_file" ]]; then
        if [[ -f "$profile_file" ]]; then
            package_count="$(setup_load_packages "$os_name" "$profile_name" | wc -l | tr -d '[:space:]')"
            echo "Profile file: ${profile_file} (ok)"
            echo "Profile packages: ${package_count}"
        else
            echo "Profile file: ${profile_file} (missing)"
            echo "Profile packages: unavailable"
        fi
    else
        echo "Profile file: unavailable"
        echo "Profile packages: unavailable"
    fi

    echo "Required commands:"
    __setup_doctor_command_status git
    __setup_doctor_command_status curl
    __setup_doctor_command_status zsh
    __setup_doctor_command_status jq
    __setup_doctor_command_status shellcheck
    __setup_doctor_command_status shfmt
    __setup_doctor_command_status brew
}

function __setup_doctor_print_json() {
    local os_name="$1"
    local profile_name="${SETUP_PROFILE:-full}"
    local profile_file profile_exists profile_path_json
    local command_name command_path command_status path_json
    local commands_json="" separator=""
    local escaped_os escaped_profile
    local command_names=(git curl zsh jq shellcheck shfmt brew)

    profile_file="$(setup_profile_file_path "$os_name" "$profile_name" 2>/dev/null || true)"
    profile_exists="false"
    profile_path_json="null"
    if [[ -n "$profile_file" ]]; then
        if [[ -f "$profile_file" ]]; then
            profile_exists="true"
        fi
        profile_path_json="\"$(__setup_doctor_escape_json "$profile_file")\""
    fi

    for command_name in "${command_names[@]}"; do
        command_path="$(__setup_doctor_command_path "$command_name")"
        command_status="missing"
        path_json="null"

        if [[ -n "$command_path" ]]; then
            command_status="ok"
            path_json="\"$(__setup_doctor_escape_json "$command_path")\""
        fi

        commands_json="${commands_json}${separator}{\"name\":\"${command_name}\",\"status\":\"${command_status}\",\"path\":${path_json}}"
        separator=","
    done

    escaped_os="$(__setup_doctor_escape_json "$os_name")"
    escaped_profile="$(__setup_doctor_escape_json "$profile_name")"
    printf '{"mode":"doctor","os":"%s","profile":"%s","profile_file":{"path":%s,"exists":%s},"commands":[%s]}\n' \
        "$escaped_os" "$escaped_profile" "$profile_path_json" "$profile_exists" "$commands_json"
}

function setup_run_doctor() {
    local os_name="$1"

    if [[ "${SETUP_JSON:-0}" = "1" ]]; then
        __setup_doctor_print_json "$os_name"
        return 0
    fi

    __setup_doctor_print_text "$os_name"
}
