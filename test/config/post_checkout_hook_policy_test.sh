#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT_DIR/config/git/template/hooks/post-checkout"
COMMON_LIB="$ROOT_DIR/setup/lib/common.sh"
GITIGNORE_GLOBAL="$ROOT_DIR/config/git/gitignore_global"
SETUP_SH="$ROOT_DIR/setup.sh"

assert_file_missing() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "ASSERTION FAILED: expected file to be absent: $path" >&2
        return 1
    fi
}

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_file_missing "$HOOK"
assert_contains 'function cleanup_legacy_post_checkout_hook() {' "$COMMON_LIB"
assert_contains 'function cleanup_legacy_git_template_hooks() {' "$COMMON_LIB"
assert_contains 'function cleanup_legacy_existing_repo_hooks() {' "$COMMON_LIB"
assert_contains 'cleanup_legacy_git_template_hooks' "$COMMON_LIB"
assert_contains 'cleanup_legacy_existing_repo_hooks' "$COMMON_LIB"
assert_not_contains 'set_config_file_target "/config/git/template/hooks/post-checkout" "${config_home}/git/template/hooks/post-checkout"' "$COMMON_LIB"
assert_not_contains 'chmod +x "${config_home}/git/template/hooks/post-checkout"' "$COMMON_LIB"
assert_not_contains '.worktree-sync' "$GITIGNORE_GLOBAL"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

custom_config_home="$tmp_dir/custom-config"
legacy_hook="$custom_config_home/git/template/hooks/post-checkout"
mkdir -p "$(dirname "$legacy_hook")"
cat >"$legacy_hook" <<'EOF'
#!/bin/sh
common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0
[ -f "$main_worktree/.worktree-sync" ] || exit 0
EOF

HOME="$tmp_dir/home" XDG_CONFIG_HOME="$custom_config_home" SETUP_SH="$SETUP_SH" bash <<'EOF'
set -euo pipefail
source "$SETUP_SH"
cleanup_legacy_git_template_hooks
[[ ! -e "$XDG_CONFIG_HOME/git/template/hooks/post-checkout" ]]
EOF

mkdir -p "$(dirname "$legacy_hook")"
cat >"$legacy_hook" <<'EOF'
#!/bin/sh
echo custom
EOF

HOME="$tmp_dir/home" XDG_CONFIG_HOME="$custom_config_home" SETUP_SH="$SETUP_SH" bash <<'EOF'
set -euo pipefail
source "$SETUP_SH"
cleanup_legacy_git_template_hooks
[[ -f "$XDG_CONFIG_HOME/git/template/hooks/post-checkout" ]]
EOF

legacy_repo_hook_dir="$tmp_dir/home/.ghq/example/repo/.git/hooks"
legacy_repo_hook="$legacy_repo_hook_dir/post-checkout"
mkdir -p "$legacy_repo_hook_dir"
cat >"$legacy_repo_hook" <<'EOF'
#!/bin/sh
common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0
[ -f "$main_worktree/.worktree-sync" ] || exit 0
EOF

custom_repo_hook_dir="$tmp_dir/home/.ghq/example/custom/.git/hooks"
custom_repo_hook="$custom_repo_hook_dir/post-checkout"
mkdir -p "$custom_repo_hook_dir"
cat >"$custom_repo_hook" <<'EOF'
#!/bin/sh
echo custom
EOF

HOME="$tmp_dir/home" XDG_CONFIG_HOME="$custom_config_home" SETUP_SH="$SETUP_SH" bash <<'EOF'
set -euo pipefail
source "$SETUP_SH"
cleanup_legacy_existing_repo_hooks
[[ ! -e "$HOME/.ghq/example/repo/.git/hooks/post-checkout" ]]
[[ -f "$HOME/.ghq/example/custom/.git/hooks/post-checkout" ]]
EOF

echo "post_checkout_hook_policy_test: ok"
