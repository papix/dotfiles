#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

function assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$expected" != "$actual" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected: ${expected}" >&2
        echo "  actual  : ${actual}" >&2
        return 1
    fi
}

function assert_file_exists() {
    local path="$1"
    local message="$2"
    if [[ ! -e "$path" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  missing: ${path}" >&2
        return 1
    fi
}

function real_path() {
    local path="$1"
    (
        builtin cd -- "$path" >/dev/null 2>&1 && pwd -P
    )
}

function assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  unexpected: ${needle}" >&2
        echo "  actual    : ${haystack}" >&2
        return 1
    fi
}

function assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected: ${needle}" >&2
        echo "  actual  : ${haystack}" >&2
        return 1
    fi
}

function zle() { return 0 }
function bindkey() {
    printf '%s\n' "${(j:\t:)@}" >> "$BINDKEY_MOCK_LOG"
}
function peco() { cat }

export HOME="$TMP_DIR/home"
mkdir -p "$HOME/.ghq/github.com/papix/example-repo"
BINDKEY_MOCK_LOG="$TMP_DIR/bindkey.log"
: > "$BINDKEY_MOCK_LOG"

repo_path="$HOME/.ghq/github.com/papix/example-repo"
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -C "$repo_path" init -q
printf 'hello\n' >"$repo_path/README.md"
git -C "$repo_path" add README.md
git -C "$repo_path" -c user.name=test -c user.email=test@example.com commit -q -m init

unset TMUX
unset SSH_CONNECTION
unset TERM_PROGRAM
unset VSCODE_INJECTION
unset DISABLE_AUTO_TMUX
unset CMUX_WORKSPACE_ID
unset CMUX_SURFACE_ID
export PS1=""
typeset -gA COMMAND_CACHE

function tmux() { return 1 }
function ghq() {
    if [[ "${1:-}" == "root" ]]; then
        print -r -- "$HOME/.ghq"
        return 0
    fi
    if [[ "${1:-}" == "list" && "${2:-}" == "--full-path" ]]; then
        print -r -- "$repo_path"
        return 0
    fi
    return 1
}

source "$ROOT_DIR/config/zsh/81-git.zsh"
source "$ROOT_DIR/config/zsh/82-tmux.zsh"

for fn in work wt wt-new wt-open wt-remove wt-prune wt-worktree-root-path git-switch-worktree peco-worktree; do
    if ! typeset -f "$fn" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: expected function ${fn} to be defined" >&2
        exit 1
    fi
done

if typeset -f work-new >/dev/null 2>&1 || typeset -f work-prune >/dev/null 2>&1; then
    echo "ASSERTION FAILED: work should not expose worktree subcommands" >&2
    exit 1
fi

bindkey_invocations="$(cat "$BINDKEY_MOCK_LOG")"
assert_contains "^[[66;6u\\tpeco-worktree" "$bindkey_invocations" "Ctrl+Shift+B CSI-u should be bound to peco-worktree"
assert_contains "^[[27;6;66~\\tpeco-worktree" "$bindkey_invocations" "Ctrl+Shift+B modifyOtherKeys should be bound to peco-worktree"

cd "$repo_path"
target_path="$(wt-worktree-root-path feature-foo)"
expected_path="$HOME/.worktrees/github.com/papix/example-repo/feature-foo"
assert_eq "$expected_path" "$target_path" "wt-worktree-root-path should use WORKTREE_BASE_DIR fallback with ghq path"

wt new feature-foo >/dev/null 2>&1
assert_file_exists "$expected_path/.git" "wt new should create a linked worktree"
expected_real_path="$(real_path "$expected_path")"
assert_eq "$expected_real_path" "$PWD" "wt new should cd into the created worktree outside tmux/cmux"
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
assert_eq "feature-foo" "$current_branch" "wt new should check out the requested branch inside the new worktree"

cd "$repo_path"
git-switch-worktree feature-foo >/dev/null 2>&1
assert_eq "$expected_real_path" "$PWD" "git-switch-worktree should open the selected worktree"

cd "$repo_path"
function date() {
    if [[ "${1:-}" == "+%Y%m%d-%H%M%S" ]]; then
        print -r -- "20260102-030405"
        return 0
    fi

    command date "$@"
}

wt new >/dev/null 2>&1
auto_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
auto_path="$HOME/.worktrees/github.com/papix/example-repo/worktree-20260102-030405"
auto_real_path="$(real_path "$auto_path")"
assert_eq "worktree-20260102-030405" "$auto_branch" "wt new without args should generate a worktree name"
assert_file_exists "$auto_path/.git" "wt new without args should create a linked worktree"
assert_eq "$auto_real_path" "$PWD" "wt new without args should cd into the generated worktree"

cd "$repo_path"
wt new >/dev/null 2>&1
auto_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
auto_path="$HOME/.worktrees/github.com/papix/example-repo/worktree-20260102-030405-2"
auto_real_path="$(real_path "$auto_path")"
assert_eq "worktree-20260102-030405-2" "$auto_branch" "wt new without args should avoid generated name conflicts"
assert_file_exists "$auto_path/.git" "wt new without args should create a uniquely named worktree"
assert_eq "$auto_real_path" "$PWD" "wt new without args should cd into the uniquely named worktree"

unfunction date

cd "$repo_path"

tmp_bin="$TMP_DIR/bin"
mkdir -p "$tmp_bin"
cat >"$tmp_bin/cmux" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "$CMUX_LOG"
printf 'OK workspace:7\n'
EOF
chmod +x "$tmp_bin/cmux"

old_path="$PATH"
export PATH="$tmp_bin:$PATH"
export CMUX_LOG="$TMP_DIR/cmux.log"
export CMUX_WORKSPACE_ID="workspace:1"
export CMUX_SURFACE_ID="surface:1"
: >"$CMUX_LOG"

wt open feature-foo >/dev/null 2>&1
cmux_invocations="$(cat "$CMUX_LOG")"
assert_contains "new-workspace --name feature-foo --cwd $expected_real_path" "$cmux_invocations" "wt open should create a plain cmux workspace for the worktree"
assert_not_contains "claude" "$cmux_invocations" "wt open should not launch AI tools implicitly"
assert_not_contains "codex" "$cmux_invocations" "wt open should not launch AI tools implicitly"

function peco() {
    local candidate=""
    while IFS= read -r candidate; do
        if [[ "$candidate" == "$expected_path" ]]; then
            print -r -- "$candidate"
            return 0
        fi
    done
    return 0
}

: >"$CMUX_LOG"
wt open >/dev/null 2>&1
cmux_invocations="$(cat "$CMUX_LOG")"
assert_contains "new-workspace --name feature-foo --cwd $expected_real_path" "$cmux_invocations" "wt open without args should select a worktree with peco"

BUFFER=""
CURSOR=0
: >"$CMUX_LOG"
peco-worktree >/dev/null 2>&1
cmux_invocations="$(cat "$CMUX_LOG")"
assert_contains "new-workspace --name feature-foo --cwd $expected_real_path" "$cmux_invocations" "peco-worktree should open the selected worktree"

unfunction peco
function peco() { cat }

export PATH="$old_path"
unset CMUX_LOG
unset CMUX_WORKSPACE_ID
unset CMUX_SURFACE_ID

cd "$repo_path"
rm -rf "$expected_path"
before_prune="$(git -C "$repo_path" worktree list --porcelain)"
if [[ "$before_prune" != *"$expected_path"* ]]; then
    echo "ASSERTION FAILED: expected stale worktree metadata before prune" >&2
    exit 1
fi

wt prune stale >/dev/null 2>&1

after_prune="$(git -C "$repo_path" worktree list --porcelain)"
assert_not_contains "$expected_path" "$after_prune" "wt prune stale should remove metadata for deleted linked worktrees"

echo "worktree_workflow_test: ok"
