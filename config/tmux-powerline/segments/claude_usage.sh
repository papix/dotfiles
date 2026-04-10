# shellcheck shell=bash
# Claude Code APIレートリミット使用率表示セグメント
# 5時間/7日間の使用率(%)と次回reset時刻を表示する

# キャッシュ設定
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-powerline"
CACHE_FILE="${CACHE_DIR}/claude_usage_v3.cache"
LEGACY_CACHE_FILE="${CACHE_DIR}/claude_usage_v2.cache"
FAILURE_MARKER_FILE="${CACHE_DIR}/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="${CACHE_DIR}/claude_usage_retry_after_v1.state"
STALE_CACHE_MAX=86400 # API障害時のフォールバック: 最大24時間

# API設定
CLAUDE_USAGE_API="https://api.anthropic.com/api/oauth/usage"
CURL_TIMEOUT=5
API_HTTP_STATUS=""
API_RETRY_AFTER=""
API_RESPONSE=""

DEFAULT_CURL_TIMEOUT=5
DEFAULT_STALE_CACHE_MAX=86400

# 色設定（projected pace と実使用率フォールバックで共用）
COLOR_LOW="#97C9C3"  # 0-49%: 緑
COLOR_MID="#E5C07B"  # 50-79%: 黄
COLOR_HIGH="#E06C75" # 80-100%: 赤

__claude_usage_script_source="${BASH_SOURCE[0]}"
while [ -L "$__claude_usage_script_source" ]; do
    __claude_usage_script_dir="$(cd -P "$(dirname "$__claude_usage_script_source")" && pwd)"
    __claude_usage_script_source="$(readlink "$__claude_usage_script_source")"
    if [[ "$__claude_usage_script_source" != /* ]]; then
        __claude_usage_script_source="${__claude_usage_script_dir}/${__claude_usage_script_source}"
    fi
done
__claude_usage_script_dir="$(cd -P "$(dirname "$__claude_usage_script_source")" && pwd)"
__claude_usage_module_dir="${__claude_usage_script_dir}/claude_usage"
# shellcheck disable=SC1091
source "${__claude_usage_module_dir}/api.sh"
# shellcheck disable=SC1091
source "${__claude_usage_module_dir}/cache.sh"
# shellcheck disable=SC1091
source "${__claude_usage_module_dir}/render.sh"

generate_segmentrc() {
    read -r -d '' rccontents <<EORC
# Segment label (default: CC for Claude Code)
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_LABEL="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_LABEL:-CC}"
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_CURL_TIMEOUT="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_CURL_TIMEOUT:-${DEFAULT_CURL_TIMEOUT}}"
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_STALE_CACHE_MAX="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_STALE_CACHE_MAX:-${DEFAULT_STALE_CACHE_MAX}}"
export TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE:-0}"
EORC
    echo "$rccontents"
}

function __claude_usage_apply_env_config() {
    local configured_timeout configured_stale_max

    CURL_TIMEOUT="$DEFAULT_CURL_TIMEOUT"
    STALE_CACHE_MAX="$DEFAULT_STALE_CACHE_MAX"

    configured_timeout="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_CURL_TIMEOUT:-}"
    if __is_positive_integer "$configured_timeout" && [ "$configured_timeout" -gt 0 ]; then
        CURL_TIMEOUT="$configured_timeout"
    fi

    configured_stale_max="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_STALE_CACHE_MAX:-}"
    if __is_positive_integer "$configured_stale_max" && [ "$configured_stale_max" -gt 0 ]; then
        STALE_CACHE_MAX="$configured_stale_max"
    fi
}

__claude_usage_apply_env_config

run_segment() {
    __claude_usage_apply_env_config

    if [ "${TMUX_POWERLINE_SEG_CLAUDE_USAGE_DISABLE:-0}" = "1" ]; then
        return 0
    fi

    # 同一15分帯に取得したキャッシュがあれば返す（:00/:15/:30/:45更新）
    __cat_cache_if_current_quarter_hour "$CACHE_FILE" && return 0
    __cat_cache_if_current_quarter_hour "$LEGACY_CACHE_FILE" && return 0

    local label="${TMUX_POWERLINE_SEG_CLAUDE_USAGE_LABEL:-CC}"

    # Retry-After が有効な間はAPI再試行を抑制し、staleキャッシュに注記する
    if __is_retry_after_active; then
        __render_rate_limited_output "$label"
        return 0
    fi

    # 同一15分帯でAPI失敗済みなら、staleキャッシュにフォールバックして再試行を抑制
    if __is_current_quarter_file "$FAILURE_MARKER_FILE"; then
        __use_stale_cache
        return 0
    fi

    # OAuthトークン取得
    local token
    token=$(__get_access_token) || return 0
    [ -n "$token" ] || return 0

    # API呼び出し（トークンはログに出力しない）
    # anthropic-beta ヘッダーはOAuth認証に必須
    # --noproxy: Claude Codeのローカルプロキシ(localhost:3128)を回避して直接接続する
    local response http_status retry_after
    __call_usage_api "$token"
    response="$API_RESPONSE"
    http_status="$API_HTTP_STATUS"
    retry_after="$API_RETRY_AFTER"

    # 429時はRetry-Afterを保存して、staleキャッシュに注記
    if [ "$http_status" = "429" ]; then
        __set_retry_after_from_seconds "$retry_after" || true
        __render_rate_limited_output "$label"
        return 0
    fi

    # API失敗時は古いキャッシュにフォールバック
    if [ "$http_status" != "200" ] || [ -z "$response" ]; then
        __fallback_to_stale_cache_and_mark_failure
        return 0
    fi

    # JSONパース: utilization は 0〜100 の小数/整数、resets_at はISO8601文字列
    local five_hour seven_day five_reset seven_reset
    if command -v jq &>/dev/null; then
        five_hour=$(echo "$response" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
        seven_day=$(echo "$response" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
        five_reset=$(echo "$response" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
        seven_reset=$(echo "$response" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)
    elif command -v perl >/dev/null 2>&1; then
        local parsed
        parsed=$(echo "$response" | perl -MJSON::PP -e '
local $/;
my $raw = <STDIN>;
my $d = eval { decode_json($raw) };
exit 1 if !$d;
my $fh = $d->{five_hour} || {};
my $sd = $d->{seven_day} || {};
print(($fh->{utilization} // q{}), "\n");
print(($sd->{utilization} // q{}), "\n");
print(($fh->{resets_at} // q{}), "\n");
print(($sd->{resets_at} // q{}), "\n");
' 2>/dev/null || true)
        five_hour=$(printf '%s\n' "$parsed" | sed -n '1p')
        seven_day=$(printf '%s\n' "$parsed" | sed -n '2p')
        five_reset=$(printf '%s\n' "$parsed" | sed -n '3p')
        seven_reset=$(printf '%s\n' "$parsed" | sed -n '4p')
    else
        __fallback_to_stale_cache_and_mark_failure
        return 0
    fi

    # パース失敗時（APIレスポンス形式が異なる場合等）は非表示
    if [ -z "$five_hour" ] || [ -z "$seven_day" ]; then
        __fallback_to_stale_cache_and_mark_failure
        return 0
    fi

    local five_pct seven_pct five_color seven_color five_reset_local seven_reset_local
    local five_reset_suffix seven_reset_suffix
    five_pct=$(__normalize_pct "$five_hour")
    seven_pct=$(__normalize_pct "$seven_day")
    five_color=$(__usage_color "$five_pct" "$five_reset" 18000)
    seven_color=$(__usage_color "$seven_pct" "$seven_reset" 604800)
    five_reset_local=$(__format_local_reset_time "$five_reset" "%H:%M")
    seven_reset_local=$(__format_local_reset_time "$seven_reset" "%m/%d %H:%M")
    five_reset_suffix=$(__render_reset_suffix "$five_reset_local")
    seven_reset_suffix=$(__render_reset_suffix "$seven_reset_local")

    local output="${label} 5h:#[fg=${five_color}]${five_pct}%#[default]${five_reset_suffix} 7d:#[fg=${seven_color}]${seven_pct}%#[default]${seven_reset_suffix}"

    # アトミック書き込みでキャッシュ保存
    __write_cache "$output"
    __clear_api_failure_marker
    __clear_retry_after_state

    printf '%s\n' "$output"
}

# API失敗時は stale cache があれば表示し、失敗マーカーは常に更新する
function __fallback_to_stale_cache_and_mark_failure() {
    __use_stale_cache || true
    __mark_api_failure || true
}
