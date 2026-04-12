#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h:h}"

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

function assert_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if ! print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected to contain: ${needle}" >&2
        echo "  actual            : ${haystack}" >&2
        return 1
    fi
}

function assert_not_contains() {
    local needle="$1"
    local haystack="$2"
    local message="$3"
    if print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected to not contain: ${needle}" >&2
        echo "  actual                : ${haystack}" >&2
        return 1
    fi
}

function assert_occurrences() {
    local needle="$1"
    local haystack="$2"
    local expected="$3"
    local message="$4"
    local actual

    actual="$(print -r -- "$haystack" | grep -oF -- "$needle" | wc -l | tr -d ' ')"
    if [[ "$actual" != "$expected" ]]; then
        echo "ASSERTION FAILED: ${message}" >&2
        echo "  expected occurrences: ${expected}" >&2
        echo "  actual occurrences  : ${actual}" >&2
        echo "  needle              : ${needle}" >&2
        echo "  haystack            : ${haystack}" >&2
        return 1
    fi
}

tmp_dir="$(mktemp -d)"
home_dir="${tmp_dir}/home"
tmux_log="${tmp_dir}/tmux.log"
mkdir -p "${home_dir}"
trap 'rm -rf "${tmp_dir}"' EXIT

export HOME="${home_dir}"

typeset -a GIT_REPO_MAP

function set_git_repo_map() {
    GIT_REPO_MAP=("$@")
}

function git_repo_for_path() {
    local path="$1"
    local entry
    local prefix
    local repo_root

    for entry in "${GIT_REPO_MAP[@]:-}"; do
        prefix="${entry%%::*}"
        repo_root="${entry##*::}"
        if [[ -n "$prefix" && "$path" == "$prefix"* ]]; then
            print -r -- "$repo_root"
            return 0
        fi
    done

    return 1
}

function git() {
    if [[ "$1" == "-C" && "$3" == "rev-parse" && "$4" == "--show-toplevel" ]]; then
        local repo_root
        if repo_root="$(git_repo_for_path "$2")"; then
            print -r -- "$repo_root"
            return 0
        fi
        return 1
    fi

    if [[ "$1" == "rev-parse" && "$2" == "--git-dir" ]]; then
        if [[ "${GIT_IS_REPO:-0}" == "1" ]]; then
            echo ".git"
            return 0
        fi
        if git_repo_for_path "$PWD" >/dev/null 2>&1; then
            echo ".git"
            return 0
        fi
        return 1
    fi

    if [[ "$1" == "rev-parse" && "$2" == "--show-toplevel" ]]; then
        if [[ "${GIT_IS_REPO:-0}" == "1" ]] && [[ -n "${GIT_TOPLEVEL:-}" ]]; then
            print -r -- "${GIT_TOPLEVEL}"
            return 0
        fi
        local repo_root
        if repo_root="$(git_repo_for_path "$PWD")"; then
            print -r -- "$repo_root"
            return 0
        fi
        return 1
    fi

    return 1
}

function tmux() {
    if [[ "$1" == "list-panes" ]]; then
        if [[ "$2" == "-t" && -n "${TMUX_LIST_PANES_FAIL_TARGET:-}" && "$3" == "${TMUX_LIST_PANES_FAIL_TARGET}" ]]; then
            return 1
        fi
        if [[ "$2" == "-t" && -n "${TMUX_LIST_PANES_ONLY_TARGET:-}" && "$3" != "${TMUX_LIST_PANES_ONLY_TARGET}" ]]; then
            return 1
        fi
        print -r -- "${TMUX_LIST_PANES_OUTPUT:-}"
        return 0
    fi

    if [[ "$1" == "display-message" && "$2" == "-p" && "$3" == "-t" && "$5" == "#{window_id}" ]]; then
        if [[ -n "${TMUX_DISPLAY_MESSAGE_FAIL_TARGET:-}" && "$4" == "${TMUX_DISPLAY_MESSAGE_FAIL_TARGET}" ]]; then
            return 1
        fi
        [[ -n "${TMUX_DISPLAY_MESSAGE_WINDOW_ID:-}" ]] || return 1
        print -r -- "${TMUX_DISPLAY_MESSAGE_WINDOW_ID}"
        return 0
    fi

    if [[ "$1" == "display-message" && "$2" == "-p" && "$3" == "-t" && "$5" == "#{pane_current_path}" ]]; then
        if [[ -n "${TMUX_DISPLAY_MESSAGE_PANE_CURRENT_PATH:-}" ]]; then
            print -r -- "${TMUX_DISPLAY_MESSAGE_PANE_CURRENT_PATH}"
            return 0
        fi
        print -r -- "${PWD}"
        return 0
    fi

    printf '%s\n' "${(j: :)@}" >> "${tmux_log}"
}

source "$ROOT_DIR/config/zsh/functions/tmux-git-window-name"

repo_one="${HOME}/work/repo-one"
repo_two="${HOME}/work/repo-two"
repo_three="${HOME}/work/repo-three"
ghq_repo="${HOME}/.ghq/github.com/papix/dotfiles"
scratch_dir="${HOME}/projects/sandbox"
mkdir -p "${repo_one}" "${repo_two}" "${repo_three}" "${ghq_repo}" "${scratch_dir}"

mkdir -p "${HOME}/.claude/plugins/example"
mkdir -p "${HOME}/.claude/mcp-servers/example"

# 期待: TMUX未設定時は何もしない
unset TMUX
unset TMUX_PANE
set_git_repo_map "${repo_one}::${repo_one}"
TMUX_LIST_PANES_OUTPUT="${repo_one}"
cd "${repo_one}"
: > "${tmux_log}"
set +u
tmux-git-window-name
set -u
assert_eq "" "$(cat "${tmux_log}")" "should not rename when TMUX is not set"

# 期待: window内pane順でrepo名を重複排除し ` | ` 連結で表示する
export TMUX="session:1.1"
export TMUX_PANE="%3"
set_git_repo_map \
    "${repo_one}::${repo_one}" \
    "${repo_two}::${repo_two}"
TMUX_LIST_PANES_OUTPUT="${repo_one}"$'\n'"${repo_two}/src"$'\n'"${repo_one}/pkg"
cd "${repo_one}"
: > "${tmux_log}"
tmux-git-window-name
rename_with_target_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %3 repo-one | repo-two" "${rename_with_target_log}" "should aggregate unique repos in pane order"
assert_occurrences "repo-one" "${rename_with_target_log}" "1" "should deduplicate same repository name"

# 期待: pane指定のlist-panesが失敗してもwindow_id解決で集約できる
export TMUX="session:1.1b"
export TMUX_PANE="%11"
set_git_repo_map \
    "${repo_one}::${repo_one}" \
    "${repo_two}::${repo_two}"
TMUX_LIST_PANES_OUTPUT="${repo_one}"$'\n'"${repo_two}/src"
TMUX_LIST_PANES_FAIL_TARGET="%11"
TMUX_LIST_PANES_ONLY_TARGET="@11"
TMUX_DISPLAY_MESSAGE_WINDOW_ID="@11"
cd "${repo_one}"
: > "${tmux_log}"
tmux-git-window-name
window_id_retry_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %11 repo-one | repo-two" "${window_id_retry_log}" "should resolve window target from pane target when list-panes with pane target fails"
unset TMUX_LIST_PANES_FAIL_TARGET
unset TMUX_LIST_PANES_ONLY_TARGET
unset TMUX_DISPLAY_MESSAGE_WINDOW_ID

# 期待: repo外paneが混在してもrepoがあればrepoのみ表示する
export TMUX="session:1.2"
export TMUX_PANE="%7"
set_git_repo_map "${repo_two}::${repo_two}"
TMUX_LIST_PANES_OUTPUT="${scratch_dir}"$'\n'"${repo_two}/app"
cd "${scratch_dir}"
: > "${tmux_log}"
tmux-git-window-name
repo_only_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %7 repo-two" "${repo_only_log}" "should show only repositories when at least one repo exists"
assert_not_contains "sandbox" "${repo_only_log}" "should not include non-repository directory name"

# 期待: pane内にrepoが無いときは従来フォールバック名を使う
export TMUX="session:1.3"
export TMUX_PANE="%4"
set_git_repo_map
TMUX_LIST_PANES_OUTPUT="${scratch_dir}"$'\n'"${scratch_dir}/nested"
cd "${scratch_dir}"
: > "${tmux_log}"
tmux-git-window-name
fallback_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %4 sandbox" "${fallback_log}" "should fallback to current directory name when no repo exists in panes"

# 期待: ghq配下repoはrepo名を表示する
export TMUX="session:1.4"
export TMUX_PANE="%5"
set_git_repo_map "${ghq_repo}::${ghq_repo}"
TMUX_LIST_PANES_OUTPUT="${ghq_repo}"
cd "${ghq_repo}"
: > "${tmux_log}"
tmux-git-window-name
ghq_log="$(cat "${tmux_log}")"
assert_contains "dotfiles" "${ghq_log}" "should include ghq repository name"

# 期待: ghq配下の複数repo表示でもGitHub表記を統一する
export TMUX="session:1.4b"
export TMUX_PANE="%6"
set_git_repo_map \
    "${HOME}/.ghq/github.com/papix/dotfiles::${HOME}/.ghq/github.com/papix/dotfiles" \
    "${HOME}/.ghq/github.com/example-owner/example-repo::${HOME}/.ghq/github.com/example-owner/example-repo"
TMUX_LIST_PANES_OUTPUT="${HOME}/.ghq/github.com/papix/dotfiles"$'\n'"${HOME}/.ghq/github.com/example-owner/example-repo"
cd "${HOME}/.ghq/github.com/papix/dotfiles"
: > "${tmux_log}"
tmux-git-window-name
multi_ghq_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %6 "$(printf '\uf408')" papix/dotfiles | "$(printf '\uf408')" example-owner/example-repo" "${multi_ghq_log}" "should use the generic GitHub label when aggregating ghq repositories"

# 期待: TMUX_PANEが空ならフォールバックで従来形式を使う
export TMUX="session:1.5"
export TMUX_PANE=""
set_git_repo_map "${repo_three}::${repo_three}"
TMUX_LIST_PANES_OUTPUT="${repo_three}"
cd "${repo_three}"
: > "${tmux_log}"
tmux-git-window-name
rename_fallback_log="$(cat "${tmux_log}")"
assert_contains "rename-window repo-three" "${rename_fallback_log}" "should rename window without explicit target when TMUX_PANE is empty"
assert_not_contains "rename-window -t" "${rename_fallback_log}" "should fallback without -t when TMUX_PANE is empty"

# 期待: 除外パスではrename-windowしない（plugins）
export TMUX="session:1.6"
export TMUX_PANE="%8"
set_git_repo_map "${repo_one}::${repo_one}"
TMUX_LIST_PANES_OUTPUT="${repo_one}"
cd "${HOME}/.claude/plugins/example"
: > "${tmux_log}"
tmux-git-window-name
assert_eq "" "$(cat "${tmux_log}")" "should skip under ~/.claude/plugins"

# 期待: 除外パスではrename-windowしない（mcp-servers）
export TMUX="session:1.7"
export TMUX_PANE="%9"
set_git_repo_map "${repo_one}::${repo_one}"
TMUX_LIST_PANES_OUTPUT="${repo_one}"
cd "${HOME}/.claude/mcp-servers/example"
: > "${tmux_log}"
tmux-git-window-name
assert_eq "" "$(cat "${tmux_log}")" "should skip under ~/.claude/mcp-servers"

# 期待: 除外paneは集約対象から除外する
export TMUX="session:1.8"
export TMUX_PANE="%10"
set_git_repo_map "${repo_two}::${repo_two}"
TMUX_LIST_PANES_OUTPUT="${HOME}/.claude/plugins/example"$'\n'"${repo_two}"$'\n'"${HOME}/.claude/mcp-servers/example"
cd "${repo_two}"
: > "${tmux_log}"
tmux-git-window-name
skip_excluded_pane_log="$(cat "${tmux_log}")"
assert_contains "rename-window -t %10 repo-two" "${skip_excluded_pane_log}" "should aggregate repositories while ignoring excluded panes"
assert_not_contains "plugins" "${skip_excluded_pane_log}" "should not include excluded pane paths in title"
assert_not_contains "mcp-servers" "${skip_excluded_pane_log}" "should not include excluded pane paths in title"

# worktreeテスト用のディレクトリを作成
worktree_base="${HOME}/.worktrees"
export WORKTREE_BASE_DIR="${worktree_base}"
worktree_papix="${worktree_base}/github.com/papix/dotfiles/feature-foo"
worktree_example="${worktree_base}/github.com/example-owner/example-repo/feature-bar"
worktree_other="${worktree_base}/github.com/other-owner/some-repo/fix-baz"
worktree_trailing_slash="${worktree_base}/github.com/papix/dotfiles/trailing-slash-branch"
mkdir -p "${worktree_papix}" "${worktree_example}" "${worktree_other}" "${worktree_trailing_slash}"

# 期待: worktreeパス（papixオーナー）はworktreeアイコン + 蝶 + repo名
export TMUX="session:2.1"
export TMUX_PANE="%20"
set_git_repo_map "${worktree_papix}::${worktree_papix}"
TMUX_LIST_PANES_OUTPUT="${worktree_papix}"
cd "${worktree_papix}"
: > "${tmux_log}"
tmux-git-window-name
worktree_papix_log="$(cat "${tmux_log}")"
assert_contains "$(printf '\ue727')" "${worktree_papix_log}" "worktree: should include branch icon"
assert_contains "dotfiles" "${worktree_papix_log}" "worktree papix: should include repo name"
assert_not_contains "$(printf '\ue28e')" "${worktree_papix_log}" "worktree papix: should not include owner icon"

# 期待: worktreeパス（任意オーナー）もworktreeアイコン + repo名に統一する
export TMUX="session:2.2"
export TMUX_PANE="%21"
set_git_repo_map "${worktree_example}::${worktree_example}"
TMUX_LIST_PANES_OUTPUT="${worktree_example}"
cd "${worktree_example}"
: > "${tmux_log}"
tmux-git-window-name
worktree_example_log="$(cat "${tmux_log}")"
assert_contains "$(printf '\ue727')" "${worktree_example_log}" "worktree example: should include branch icon"
assert_contains "example-repo" "${worktree_example_log}" "worktree example: should include repo name"
assert_not_contains "example-owner/" "${worktree_example_log}" "worktree example: should not include owner name"

# 期待: worktreeパス（その他オーナー）もworktreeアイコン + repo名に統一する
export TMUX="session:2.3"
export TMUX_PANE="%22"
set_git_repo_map "${worktree_other}::${worktree_other}"
TMUX_LIST_PANES_OUTPUT="${worktree_other}"
cd "${worktree_other}"
: > "${tmux_log}"
tmux-git-window-name
worktree_other_log="$(cat "${tmux_log}")"
assert_contains "$(printf '\ue727')" "${worktree_other_log}" "worktree other: should include branch icon"
assert_contains "some-repo" "${worktree_other_log}" "worktree other: should include repo name"
assert_not_contains "other-owner/" "${worktree_other_log}" "worktree other: should not include owner name"

# 期待: 通常のghqリポジトリにはworktreeアイコンが付かない（回帰防止）
export TMUX="session:2.4"
export TMUX_PANE="%23"
set_git_repo_map "${HOME}/.ghq/github.com/papix/dotfiles::${HOME}/.ghq/github.com/papix/dotfiles"
TMUX_LIST_PANES_OUTPUT="${HOME}/.ghq/github.com/papix/dotfiles"
cd "${HOME}/.ghq/github.com/papix/dotfiles"
: > "${tmux_log}"
tmux-git-window-name
ghq_no_worktree_log="$(cat "${tmux_log}")"
assert_not_contains "$(printf '\ue727')" "${ghq_no_worktree_log}" "ghq repo: should not include branch icon"

# 期待: WORKTREE_BASE_DIR末尾の / は無視してworktree判定できる（回帰防止）
export TMUX="session:2.5"
export TMUX_PANE="%24"
export WORKTREE_BASE_DIR="${worktree_base}/"
set_git_repo_map "${worktree_trailing_slash}::${worktree_trailing_slash}"
TMUX_LIST_PANES_OUTPUT="${worktree_trailing_slash}"
cd "${worktree_trailing_slash}"
: > "${tmux_log}"
tmux-git-window-name
worktree_trailing_slash_log="$(cat "${tmux_log}")"
assert_contains "$(printf '\ue727')" "${worktree_trailing_slash_log}" "worktree trailing slash: should include branch icon"
assert_contains "dotfiles" "${worktree_trailing_slash_log}" "worktree trailing slash: should include repo name"
assert_not_contains "rename-window -t %24 trailing-slash-branch" "${worktree_trailing_slash_log}" "worktree trailing slash: should not fallback to branch directory name"
assert_not_contains "$(printf '\ue28e')" "${worktree_trailing_slash_log}" "worktree trailing slash: should not include owner icon"

# 期待: vibe-kanban配下のworktreeもworktreeアイコン + repo名で表示する
vibe_worktree="/var/tmp/vibe-kanban/worktrees/task-123/dotfiles"
mkdir -p "${vibe_worktree}"
export TMUX="session:2.6"
export TMUX_PANE="%25"
set_git_repo_map "${vibe_worktree}::${vibe_worktree}"
TMUX_LIST_PANES_OUTPUT="${vibe_worktree}"
cd "${vibe_worktree}"
: > "${tmux_log}"
tmux-git-window-name
vibe_worktree_log="$(cat "${tmux_log}")"
assert_contains "$(printf '\ue727')" "${vibe_worktree_log}" "vibe-kanban worktree: should include branch icon"
assert_contains "dotfiles" "${vibe_worktree_log}" "vibe-kanban worktree: should include repo name"
assert_not_contains "$(printf '\uf408')" "${vibe_worktree_log}" "vibe-kanban worktree: should not include github icon"

# 期待: local pathの使用でPATHが壊れても実gitでrepo判定できること（回帰防止）
unfunction git
real_repo="${HOME}/real-path-collision-repo"
mkdir -p "${real_repo}"
command git -C "${real_repo}" init -q
real_repo_label="$(tmux_git_window_name_label_from_path "${real_repo}")"
assert_eq "real-path-collision-repo" "${real_repo_label}" "should resolve repository label even when using external git command"

echo "tmux_git_window_name_test: ok"
