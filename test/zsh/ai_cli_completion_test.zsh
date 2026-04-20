#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
AI_MODULE_FILE="$ROOT_DIR/config/zsh/84-ai-cli.zsh"
COMPLETION_FILE="$ROOT_DIR/config/zsh/40-completion.zsh"
ENV_FILE="$ROOT_DIR/config/zsh/10-env.zsh"
CODEX_COMPLETION_FILE="$ROOT_DIR/config/zsh/completions/_codex"
CLAUDE_COMPLETION_FILE="$ROOT_DIR/config/zsh/completions/_claude"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        return 1
    fi
}

assert_file_exists() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ASSERTION FAILED: expected file $path" >&2
        return 1
    fi
}

wait_for_file() {
    local path="$1"
    local attempt

    for attempt in {1..50}; do
        if [[ -f "$path" ]]; then
            return 0
        fi
        /bin/sleep 0.05
    done

    echo "ASSERTION FAILED: expected file $path to appear" >&2
    return 1
}

# 期待: 独自 completion ディレクトリを fpath に追加する
assert_contains 'local zsh_completion_dir' "$ENV_FILE"
assert_contains 'zsh_completion_dir="${${(%):-%x}:A:h}/completions"' "$ENV_FILE"
assert_contains '${zsh_completion_dir}(N-/)' "$ENV_FILE"

# 期待: zsh 標準の cache layer と complist を有効にする
assert_contains 'zmodload zsh/complist' "$COMPLETION_FILE"
assert_contains 'typeset -g ZSH_COMPLETION_CACHE_DIR=' "$COMPLETION_FILE"
assert_contains "zstyle ':completion:*' use-cache on" "$COMPLETION_FILE"
assert_contains "zstyle ':completion:*' cache-path \"\${ZSH_COMPLETION_CACHE_DIR}\"" "$COMPLETION_FILE"

# 期待: codex / claude 用の async prewarm モジュールを提供する
assert_file_exists "$AI_MODULE_FILE"
assert_contains '__dotfiles_maybe_refresh_codex_completion_async' "$AI_MODULE_FILE"
assert_contains '__dotfiles_maybe_refresh_claude_scope_async' "$AI_MODULE_FILE"

# 期待: codex は version 付きキャッシュ生成と async refresh を提供する
assert_file_exists "$CODEX_COMPLETION_FILE"
assert_contains '__dotfiles_generate_codex_completion_cache' "$CODEX_COMPLETION_FILE"
assert_contains '__dotfiles_maybe_refresh_codex_completion_async' "$CODEX_COMPLETION_FILE"
assert_contains 'codex completion zsh' "$CODEX_COMPLETION_FILE"

# 期待: claude は scope ごとの cache と subcommand 補完を提供する
assert_file_exists "$CLAUDE_COMPLETION_FILE"
assert_contains '__dotfiles_generate_claude_scope_cache' "$CLAUDE_COMPLETION_FILE"
assert_contains '__dotfiles_maybe_refresh_claude_scope_async' "$CLAUDE_COMPLETION_FILE"
assert_contains 'completion_specs+=("1:command:->claude-command")' "$CLAUDE_COMPLETION_FILE"
assert_contains 'claude "$@" --help' "$CLAUDE_COMPLETION_FILE"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/bin"

cat >"$tmp_dir/bin/codex" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
    printf '%s\n' 'codex-cli test'
    exit 0
fi

if [[ "${1:-}" == "completion" && "${2:-}" == "zsh" ]]; then
    cat <<'INNER'
#compdef codex
_codex() {
    return 42
}
INNER
    exit 0
fi

exit 1
SCRIPT
chmod +x "$tmp_dir/bin/codex"

cat >"$tmp_dir/bin/claude" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
    printf '%s\n' '2.1.104 (Claude Code)'
    exit 0
fi

if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude [options] [command] [prompt]

Options:
  --permission-mode <mode>  Permission mode (choices: "default", "auto")
  --plugin-dir <path>       Load plugins from a directory
  -h, --help                Display help for command

Commands:
  install [options] [target]  Install Claude Code native build
  plugin|plugins [options]    Manage Claude Code plugins
INNER
    exit 0
fi

if [[ "${1:-}" == "install" && "${2:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude install [options] [target]

Options:
  --force              Force installation even if already installed
  --target-dir <path>  Installation directory
  -h, --help           Display help for command
INNER
    exit 0
fi

if [[ "${1:-}" == "plugin" && "${2:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude plugin [options] [command]

Options:
  --verbose          Enable verbose mode
  --registry <path>  Registry manifest path
  -h, --help         Display help for command

Commands:
  install|i [options] <plugin>  Install a plugin from available marketplaces
  marketplace                   Manage Claude Code marketplaces
INNER
    exit 0
fi

if [[ "${1:-}" == "plugin" && "${2:-}" == "marketplace" && "${3:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude plugin marketplace [options] [command]

Options:
  --json     Print JSON output
  -h, --help Display help for command

Commands:
  list       List marketplaces
INNER
    exit 0
fi

exit 1
SCRIPT
chmod +x "$tmp_dir/bin/claude"

export PATH="$tmp_dir/bin:$PATH"
export XDG_CACHE_HOME="$tmp_dir/cache"
source "$CODEX_COMPLETION_FILE"
source "$CLAUDE_COMPLETION_FILE"

# 期待: codex 補完 cache は関数名を衝突させずにロードできる
if ! __dotfiles_prepare_codex_completion; then
    echo "ASSERTION FAILED: expected codex completion cache generation to succeed" >&2
    exit 1
fi

if [[ ! -f "$XDG_CACHE_HOME/zsh/completions/_codex.generated.zsh" ]]; then
    echo "ASSERTION FAILED: expected generated codex completion cache file" >&2
    exit 1
fi

set +e
__dotfiles_generated_codex_completion
exit_code=$?
set -e
if [[ "$exit_code" != '42' ]]; then
    echo "ASSERTION FAILED: expected generated codex completion to preserve function body (actual: $exit_code)" >&2
    exit 1
fi

# 期待: codex の async refresh は cache を再生成できる
rm -f "$XDG_CACHE_HOME/zsh/completions/_codex.generated.zsh" "$XDG_CACHE_HOME/zsh/completions/codex.version"
unfunction __dotfiles_generated_codex_completion 2>/dev/null || true
__DOTFILES_CODEX_COMPLETION_READY=0
__dotfiles_maybe_refresh_codex_completion_async
wait_for_file "$XDG_CACHE_HOME/zsh/completions/_codex.generated.zsh"

# 期待: 壊れた相対パス文字列を受けても作業ディレクトリを汚さない
pollution_dir="$(mktemp -d)"
(
    cd "$pollution_dir" || exit 1

    function __dotfiles_codex_completion_cache_dir() {
        print -r -- '1001 65534 65534 1001__dotfiles_codex_completion_cache_dir)'
    }

    function __dotfiles_codex_completion_lock_dir() {
        print -r -- '1001 65534 65534 1001__dotfiles_codex_completion_lock_dir)'
    }

    if __dotfiles_codex_acquire_completion_lock; then
        echo "ASSERTION FAILED: expected codex lock acquisition to reject unsafe relative paths" >&2
        exit 1
    fi

    if [[ -e "$pollution_dir/1001 65534 65534 1001__dotfiles_codex_completion_cache_dir)" || -e "$pollution_dir/1001 65534 65534 1001__dotfiles_codex_completion_lock_dir)" ]]; then
        echo "ASSERTION FAILED: expected codex completion helpers to avoid creating cwd artifacts" >&2
        exit 1
    fi
)
rm -rf "$pollution_dir"

# 期待: claude root scope の cache から command と option を生成する
if ! __dotfiles_prepare_claude_scope_cache; then
    echo "ASSERTION FAILED: expected claude root scope cache generation to succeed" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_COMMANDS}" != *'plugin:Manage Claude Code plugins'* ]]; then
    echo "ASSERTION FAILED: expected plugin command in claude root scope cache" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_OPTION_SPECS}" != *'--permission-mode'* ]]; then
    echo "ASSERTION FAILED: expected permission-mode option in claude root scope cache" >&2
    exit 1
fi

# 期待: claude plugin scope の option / command を生成する
if ! __dotfiles_prepare_claude_scope_cache plugin; then
    echo "ASSERTION FAILED: expected claude plugin scope cache generation to succeed" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_COMMANDS}" != *'marketplace:Manage Claude Code marketplaces'* ]]; then
    echo "ASSERTION FAILED: expected marketplace command in claude plugin scope cache" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_OPTION_SPECS}" != *'--registry'* ]]; then
    echo "ASSERTION FAILED: expected registry option in claude plugin scope cache" >&2
    exit 1
fi

# 期待: claude nested scope も on-demand に生成できる
if ! __dotfiles_prepare_claude_scope_cache plugin marketplace; then
    echo "ASSERTION FAILED: expected claude plugin marketplace scope cache generation to succeed" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_OPTION_SPECS}" != *'--json'* ]]; then
    echo "ASSERTION FAILED: expected json option in claude plugin marketplace scope cache" >&2
    exit 1
fi

# 期待: claude の async refresh は root / subcommand scope を再生成できる
rm -f "$XDG_CACHE_HOME/zsh/completions/claude.root.commands" "$XDG_CACHE_HOME/zsh/completions/claude.root.options" "$XDG_CACHE_HOME/zsh/completions/claude.root.version"
__dotfiles_maybe_refresh_claude_scope_async
wait_for_file "$XDG_CACHE_HOME/zsh/completions/claude.root.commands"

rm -f "$XDG_CACHE_HOME/zsh/completions/claude.plugin.commands" "$XDG_CACHE_HOME/zsh/completions/claude.plugin.options" "$XDG_CACHE_HOME/zsh/completions/claude.plugin.version"
__dotfiles_maybe_refresh_claude_scope_async plugin
wait_for_file "$XDG_CACHE_HOME/zsh/completions/claude.plugin.commands"

# 期待: claude も壊れた相対パス文字列では lock directory を作らない
pollution_dir="$(mktemp -d)"
(
    cd "$pollution_dir" || exit 1

    function __dotfiles_claude_completion_cache_dir() {
        print -r -- '1001 65534 65534 1001__dotfiles_claude_completion_cache_dir)'
    }

    function __dotfiles_claude_scope_lock_dir() {
        print -r -- '1001 65534 65534 1001__dotfiles_claude_scope_lock_dir)'
    }

    if __dotfiles_claude_acquire_scope_lock plugin; then
        echo "ASSERTION FAILED: expected claude lock acquisition to reject unsafe relative paths" >&2
        exit 1
    fi

    if [[ -e "$pollution_dir/1001 65534 65534 1001__dotfiles_claude_completion_cache_dir)" || -e "$pollution_dir/1001 65534 65534 1001__dotfiles_claude_scope_lock_dir)" ]]; then
        echo "ASSERTION FAILED: expected claude completion helpers to avoid creating cwd artifacts" >&2
        exit 1
    fi
)
rm -rf "$pollution_dir"

# 期待: scope ごとの version 管理により nested scope の stale cache も再生成される
cat >"$tmp_dir/bin/claude" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
    printf '%s
' '2.2.0 (Claude Code)'
    exit 0
fi

if [[ $# -eq 0 || "${1:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude [options] [command] [prompt]

Options:
  --permission-mode <mode>  Permission mode (choices: "default", "auto")
  --plugin-dir <path>       Load plugins from a directory
  -h, --help                Display help for command

Commands:
  install [options] [target]  Install Claude Code native build
  plugin|plugins [options]    Manage Claude Code plugins
INNER
    exit 0
fi

if [[ "${1:-}" == "plugin" && "${2:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude plugin [options] [command]

Options:
  --verbose          Enable verbose mode
  --registry <path>  Registry manifest path
  -h, --help         Display help for command

Commands:
  install|i [options] <plugin>  Install a plugin from available marketplaces
  marketplace                   Manage Claude Code marketplaces
INNER
    exit 0
fi

if [[ "${1:-}" == "plugin" && "${2:-}" == "marketplace" && "${3:-}" == "--help" ]]; then
    cat <<'INNER'
Usage: claude plugin marketplace [options] [command]

Options:
  --yaml     Print YAML output
  -h, --help Display help for command

Commands:
  list       List marketplaces
INNER
    exit 0
fi

exit 1
SCRIPT
chmod +x "$tmp_dir/bin/claude"

if ! __dotfiles_prepare_claude_scope_cache plugin marketplace; then
    echo "ASSERTION FAILED: expected stale nested claude scope cache access to succeed" >&2
    exit 1
fi

for attempt in {1..50}; do
    if [[ -f "$XDG_CACHE_HOME/zsh/completions/claude.plugin__marketplace.options" ]] && grep -F -- '--yaml' "$XDG_CACHE_HOME/zsh/completions/claude.plugin__marketplace.options" >/dev/null 2>&1; then
        break
    fi
    /bin/sleep 0.05
done

if ! __dotfiles_prepare_claude_scope_cache plugin marketplace; then
    echo "ASSERTION FAILED: expected refreshed nested claude scope cache to load" >&2
    exit 1
fi

if [[ "${(j:,:)__DOTFILES_CLAUDE_PARSED_OPTION_SPECS}" != *'--yaml'* ]]; then
    echo "ASSERTION FAILED: expected nested claude scope cache to refresh after version change" >&2
    exit 1
fi

echo "ai_cli_completion_test: ok"
