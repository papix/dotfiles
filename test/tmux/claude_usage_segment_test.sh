#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENT="$ROOT_DIR/config/tmux-powerline/segments/claude_usage.sh"
SEGMENT_API="$ROOT_DIR/config/tmux-powerline/segments/claude_usage/api.sh"
SEGMENT_CACHE="$ROOT_DIR/config/tmux-powerline/segments/claude_usage/cache.sh"
SEGMENT_RENDER="$ROOT_DIR/config/tmux-powerline/segments/claude_usage/render.sh"
README_FILE="$ROOT_DIR/config/tmux-powerline/segments/README.md"

assert_contains() {
    local needle="$1"
    local file="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected to contain '$needle' in $file" >&2
        exit 1
    fi
}

assert_not_contains() {
    local needle="$1"
    local file="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
        exit 1
    fi
}

assert_contains_any() {
    local needle="$1"
    shift

    local file
    for file in "$@"; do
        if grep -Fq -- "$needle" "$file"; then
            return 0
        fi
    done

    echo "ASSERTION FAILED: expected to contain '$needle' in one of: $*" >&2
    exit 1
}

assert_not_contains_all() {
    local needle="$1"
    shift

    local file
    for file in "$@"; do
        if grep -Fq -- "$needle" "$file"; then
            echo "ASSERTION FAILED: expected not to contain '$needle' in $file" >&2
            exit 1
        fi
    done
}

assert_text_contains() {
    local needle="$1"
    local text="$2"
    if ! printf '%s\n' "$text" | grep -Fq -- "$needle"; then
        echo "ASSERTION FAILED: expected text to contain '$needle'" >&2
        echo "  actual: $text" >&2
        exit 1
    fi
}

assert_text_not_contains() {
    local needle="$1"
    local text="$2"
    if printf '%s\n' "$text" | grep -Fq -- "$needle"; then
        echo "ASSERTION FAILED: expected text not to contain '$needle'" >&2
        echo "  actual: $text" >&2
        exit 1
    fi
}

# セグメントファイルの存在確認
test -f "$SEGMENT" || {
    echo "FAIL: claude_usage.sh not found" >&2
    exit 1
}
test -f "$SEGMENT_API" || {
    echo "FAIL: claude_usage/api.sh not found" >&2
    exit 1
}
test -f "$SEGMENT_CACHE" || {
    echo "FAIL: claude_usage/cache.sh not found" >&2
    exit 1
}
test -f "$SEGMENT_RENDER" || {
    echo "FAIL: claude_usage/render.sh not found" >&2
    exit 1
}
test -f "$README_FILE" || {
    echo "FAIL: README.md not found" >&2
    exit 1
}
py_bin="python3"
for py_target in '$retry_cache_file' '$retry_date_cache_file' '$symlink_cache_file' '$retry_symlink_cache_file'; do
    assert_not_contains "${py_bin} - \"${py_target}\"" "$0"
done

# 必須関数の存在確認
assert_contains "generate_segmentrc" "$SEGMENT"
assert_contains "run_segment" "$SEGMENT"

# APIエンドポイントの正確性
assert_contains_any "https://api.anthropic.com/api/oauth/usage" "$SEGMENT" "$SEGMENT_API"

# クレデンシャルパスとキーの正確性
assert_contains_any ".claude/.credentials.json" "$SEGMENT" "$SEGMENT_API"
assert_contains_any "claudeAiOauth" "$SEGMENT" "$SEGMENT_API"
assert_contains_any "accessToken" "$SEGMENT" "$SEGMENT_API"

# アトミック書き込みパターン（レースコンディション対策）
assert_contains_any "mktemp" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE"
assert_contains_any "mv -f" "$SEGMENT" "$SEGMENT_CACHE"

# シンボリックリンク攻撃対策
assert_contains_any "! -L" "$SEGMENT" "$SEGMENT_CACHE"

# macOS Keychain サポート
assert_contains_any "security find-generic-password" "$SEGMENT" "$SEGMENT_API"

# reset時刻とパーセンテージ表示
assert_contains_any "resets_at" "$SEGMENT" "$SEGMENT_API"
assert_contains_any "__format_local_reset_time" "$SEGMENT" "$SEGMENT_RENDER"
assert_contains_any "\"%H:%M\"" "$SEGMENT" "$SEGMENT_RENDER"
assert_contains_any "\"%m/%d %H:%M\"" "$SEGMENT" "$SEGMENT_RENDER"
assert_contains_any "（〜" "$SEGMENT" "$SEGMENT_RENDER"
assert_not_contains_all "updated at:" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"
assert_contains_any "rate limited" "$SEGMENT" "$SEGMENT_RENDER"
assert_contains_any "RETRY_AFTER_STATE_FILE" "$SEGMENT" "$SEGMENT_CACHE"
assert_contains_any "retry-after" "$SEGMENT" "$SEGMENT_API"
assert_not_contains_all "python3" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"
assert_not_contains_all 'python3 - "$retry_after_http_date"' "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"
assert_contains_any "Time::Local=timegm" "$SEGMENT_API" "$SEGMENT_RENDER"
assert_contains "#[fg=" "$SEGMENT"
assert_contains "%#[default]" "$SEGMENT"
assert_contains '5h:#[fg=${five_color}]${five_pct}%#[default]' "$SEGMENT"
assert_contains '7d:#[fg=${seven_color}]${seven_pct}%#[default]' "$SEGMENT"
assert_not_contains_all "reset)" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"

# 更新頻度は15分間隔（:00/:15/:30/:45）
assert_contains_any "__cat_cache_if_current_quarter_hour" "$SEGMENT" "$SEGMENT_CACHE"
assert_contains_any "__to_quarter_hour_key" "$SEGMENT" "$SEGMENT_CACHE"
assert_not_contains_all "__cat_cache_if_current_hour" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"
assert_not_contains_all "CACHE_DURATION=600" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"

# API障害時のstaleキャッシュ許容は24時間
assert_contains_any "STALE_CACHE_MAX=86400" "$SEGMENT" "$SEGMENT_CACHE"

# 互換キャッシュ(v2)へフォールバック可能
assert_contains_any "LEGACY_CACHE_FILE" "$SEGMENT" "$SEGMENT_CACHE"
assert_contains_any "__cat_cache_if_fresh" "$SEGMENT" "$SEGMENT_CACHE"

# 旧バー表示依存を除去
assert_not_contains_all "▰" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"
assert_not_contains_all "▱" "$SEGMENT" "$SEGMENT_API" "$SEGMENT_CACHE" "$SEGMENT_RENDER"

# READMEの色閾値説明が実装と一致していること（予測 + フォールバック）
assert_contains "at least 5 minutes have elapsed" "$README_FILE"
assert_contains "projected < 80%" "$README_FILE"
assert_contains "projected 80-99%" "$README_FILE"
assert_contains "projected >= 100%" "$README_FILE"
assert_contains "Falls back to raw utilization thresholds" "$README_FILE"
assert_not_contains "green (0-49%)" "$README_FILE"
assert_not_contains "yellow (50-79%)" "$README_FILE"
assert_not_contains "red (80-100%)" "$README_FILE"

# READMEの更新頻度説明が実装と一致していること
assert_contains "every 15 minutes (at :00, :15, :30, :45)" "$README_FILE"
assert_not_contains "hourly (at minute 0)" "$README_FILE"
assert_not_contains "10 minutes" "$README_FILE"

# READMEの表示位置説明が実装と一致していること
assert_contains "lower-right side of the second status line" "$README_FILE"
assert_not_contains "Add to your theme's right status segments:" "$README_FILE"

# rate limited と Retry-After の挙動検証
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# シンボリックリンク経由で source しても内部モジュールを読み込めること
symlink_source_dir="$tmp_dir/symlink_source"
symlink_segment="$symlink_source_dir/claude_usage.sh"
mkdir -p "$symlink_source_dir"
ln -sf "$SEGMENT" "$symlink_segment"
expected_module_dir="$(cd "$(dirname "$SEGMENT")/claude_usage" && pwd)"
symlink_module_dir="$(
    SEGMENT_PATH="$symlink_segment" bash -c '
set -euo pipefail
source "$SEGMENT_PATH"
type __is_positive_integer >/dev/null 2>&1
printf "%s\n" "$__claude_usage_module_dir"
'
)"
if [ "$symlink_module_dir" != "$expected_module_dir" ]; then
    echo "ASSERTION FAILED: expected module dir '$expected_module_dir', got '$symlink_module_dir'" >&2
    exit 1
fi

source "$SEGMENT"

# __usage_color ユニットテスト（予測ベース + フォールバック）
make_iso8601_future() {
    perl -MPOSIX=strftime -e 'print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time() + $ARGV[0]))' "$1"
}

# utilization=0 → 緑
uc_result=$(__usage_color 0 "$(make_iso8601_future 14400)" 18000)
if [ "$uc_result" != "$COLOR_LOW" ]; then
    echo "ASSERTION FAILED: utilization=0 should be green, got $uc_result" >&2
    exit 1
fi

# ウィンドウ開始5分未満は projected を使わず、実使用率閾値へフォールバック
uc_result=$(__usage_color 90 "$(make_iso8601_future 17900)" 18000)
if [ "$uc_result" != "$COLOR_HIGH" ]; then
    echo "ASSERTION FAILED: early window should fall back to raw utilization, got $uc_result" >&2
    exit 1
fi

# reset時刻が不明なら projected を使わず、実使用率閾値へフォールバック
uc_result=$(__usage_color 90 "" 18000)
if [ "$uc_result" != "$COLOR_HIGH" ]; then
    echo "ASSERTION FAILED: missing reset should fall back to raw utilization, got $uc_result" >&2
    exit 1
fi

# 高消費ペース: 3600s経過・utilization=50% → projected=250% → 赤
uc_result=$(__usage_color 50 "$(make_iso8601_future 14400)" 18000)
if [ "$uc_result" != "$COLOR_HIGH" ]; then
    echo "ASSERTION FAILED: high pace should be red, got $uc_result" >&2
    exit 1
fi

# 中消費ペース: 9000s経過・utilization=42% → projected=84% → 黄
uc_result=$(__usage_color 42 "$(make_iso8601_future 9000)" 18000)
if [ "$uc_result" != "$COLOR_MID" ]; then
    echo "ASSERTION FAILED: medium pace should be yellow, got $uc_result" >&2
    exit 1
fi

# 低消費ペース: 9000s経過・utilization=30% → projected=60% → 緑
uc_result=$(__usage_color 30 "$(make_iso8601_future 9000)" 18000)
if [ "$uc_result" != "$COLOR_LOW" ]; then
    echo "ASSERTION FAILED: low pace should be green, got $uc_result" >&2
    exit 1
fi

orig_path="$PATH"
orig_cache_dir="$CACHE_DIR"
orig_cache_file="$CACHE_FILE"
orig_legacy_cache_file="$LEGACY_CACHE_FILE"
orig_failure_marker_file="$FAILURE_MARKER_FILE"
orig_retry_after_state_file="${RETRY_AFTER_STATE_FILE:-}"

# 旧キャッシュに updated at が含まれていても表示時に除去されること
sanitize_cache_dir="$tmp_dir/sanitize_cache"
sanitize_cache_file="$sanitize_cache_dir/claude_usage_v3.cache"
mkdir -p "$sanitize_cache_dir"
printf '%s' 'CC 5h:#[fg=#97C9C3]6%#[fg=244]（〜21:00） 7d:#[fg=#E06C75]80%#[fg=244]（〜03/06 11:59） #[fg=244]updated at: 03/05 17:34 #[fg=244]' >"$sanitize_cache_file"
CACHE_DIR="$sanitize_cache_dir"
CACHE_FILE="$sanitize_cache_file"
LEGACY_CACHE_FILE="$sanitize_cache_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$sanitize_cache_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$sanitize_cache_dir/claude_usage_retry_after_v1.state"
sanitize_rendered="$(run_segment)"
assert_text_not_contains "updated at:" "$sanitize_rendered"
assert_text_contains "%#[default]（〜21:00） 7d:" "$sanitize_rendered"

# reset時刻が不明な場合は、（〜...）表記を出さず、色は実使用率閾値へフォールバック
unknown_reset_dir="$tmp_dir/unknown_reset"
unknown_reset_bin_dir="$tmp_dir/unknown_reset_bin"
mkdir -p "$unknown_reset_dir" "$unknown_reset_bin_dir"
cat >"$unknown_reset_bin_dir/curl" <<'EOF'
#!/usr/bin/env bash
header_file=""
body_file=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -D)
            header_file="$2"
            shift 2
            ;;
        -o)
            body_file="$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 200\r\n\r\n' > "$header_file"
printf '{"five_hour":{"utilization":90},"seven_day":{"utilization":55}}' > "$body_file"
printf '200'
EOF
chmod +x "$unknown_reset_bin_dir/curl"

PATH="$unknown_reset_bin_dir:$orig_path"
CACHE_DIR="$unknown_reset_dir"
CACHE_FILE="$unknown_reset_dir/claude_usage_v3.cache"
LEGACY_CACHE_FILE="$unknown_reset_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$unknown_reset_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$unknown_reset_dir/claude_usage_retry_after_v1.state"

__get_access_token() {
    echo "dummy-token"
}

unknown_reset_rendered="$(run_segment)"
assert_text_contains '5h:#[fg=#E06C75]90%#[default]' "$unknown_reset_rendered"
assert_text_contains '7d:#[fg=#E5C07B]55%#[default]' "$unknown_reset_rendered"
assert_text_not_contains '（〜' "$unknown_reset_rendered"
assert_text_not_contains '--:00' "$unknown_reset_rendered"
assert_text_not_contains '--:--' "$unknown_reset_rendered"

# 429時は stale cache + rate limited を返し、Retry-After中は再試行しない
retry_cache_dir="$tmp_dir/retry_cache"
retry_cache_file="$retry_cache_dir/claude_usage_v3.cache"
retry_calls_file="$tmp_dir/retry_curl_calls.log"
retry_marker_file="$retry_cache_dir/claude_usage_api_failure.marker"
retry_state_file="$retry_cache_dir/claude_usage_retry_after_v1.state"
mkdir -p "$retry_cache_dir" "$tmp_dir/retry_bin"
printf '%s' 'CC 5h:#[fg=#97C9C3]6%#[fg=244]（〜21:00） 7d:#[fg=#E06C75]80%#[fg=244]（〜03/06 11:59）' >"$retry_cache_file"
: >"$retry_calls_file"
perl -e 'my $p = shift; my $ts = time() - 7200; utime $ts, $ts, $p or exit 1;' "$retry_cache_file"

cat >"$tmp_dir/retry_bin/curl" <<EOF
#!/usr/bin/env bash
echo x >> "$retry_calls_file"
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 429\r\nretry-after: 120\r\n\r\n' > "\$header_file"
printf '{"error":{"message":"Rate limited","type":"rate_limit_error"}}' > "\$body_file"
printf '429'
EOF
chmod +x "$tmp_dir/retry_bin/curl"

PATH="$tmp_dir/retry_bin:$PATH"
CACHE_DIR="$retry_cache_dir"
CACHE_FILE="$retry_cache_file"
LEGACY_CACHE_FILE="$retry_cache_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$retry_marker_file"
RETRY_AFTER_STATE_FILE="$retry_state_file"

__get_access_token() {
    echo "dummy-token"
}

first_rendered="$(run_segment)"
second_rendered="$(run_segment)"

assert_text_contains "rate limited" "$first_rendered"
assert_text_contains "rate limited" "$second_rendered"
assert_text_not_contains "updated at:" "$first_rendered"
assert_text_not_contains "updated at:" "$second_rendered"
curl_calls="$(wc -l <"$retry_calls_file" | tr -d ' ')"
if [ "$curl_calls" -ne 1 ]; then
    echo "ASSERTION FAILED: expected curl to be called once while Retry-After active, got $curl_calls" >&2
    exit 1
fi
test -f "$retry_state_file" || {
    echo "ASSERTION FAILED: expected retry-after state file to be created" >&2
    exit 1
}

# Retry-After が HTTP-date 形式でも再試行抑制されること
retry_date_dir="$tmp_dir/retry_date"
retry_date_cache_file="$retry_date_dir/claude_usage_v3.cache"
retry_date_calls_file="$tmp_dir/retry_date_calls.log"
retry_date_state_file="$retry_date_dir/claude_usage_retry_after_v1.state"
retry_date_marker_file="$retry_date_dir/claude_usage_api_failure.marker"
retry_after_http_date="$(perl -MPOSIX=strftime -e 'print strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime(time() + 180))')"
mkdir -p "$retry_date_dir" "$tmp_dir/retry_date_bin"
printf '%s' 'CC 5h:#[fg=#97C9C3]6%#[default]（〜21:00） 7d:#[fg=#E06C75]80%#[default]（〜03/06 11:59）' >"$retry_date_cache_file"
: >"$retry_date_calls_file"
perl -e 'my $p = shift; my $ts = time() - 7200; utime $ts, $ts, $p or exit 1;' "$retry_date_cache_file"
cat >"$tmp_dir/retry_date_bin/curl" <<EOF
#!/usr/bin/env bash
echo x >> "$retry_date_calls_file"
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 429\r\nretry-after: ${retry_after_http_date}\r\n\r\n' > "\$header_file"
printf '{"error":{"message":"Rate limited","type":"rate_limit_error"}}' > "\$body_file"
printf '429'
EOF
chmod +x "$tmp_dir/retry_date_bin/curl"

PATH="$tmp_dir/retry_date_bin:$orig_path"
CACHE_DIR="$retry_date_dir"
CACHE_FILE="$retry_date_cache_file"
LEGACY_CACHE_FILE="$retry_date_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$retry_date_marker_file"
RETRY_AFTER_STATE_FILE="$retry_date_state_file"

date_first_rendered="$(run_segment)"
date_second_rendered="$(run_segment)"
assert_text_contains "rate limited" "$date_first_rendered"
assert_text_contains "rate limited" "$date_second_rendered"
date_calls="$(wc -l <"$retry_date_calls_file" | tr -d ' ')"
if [ "$date_calls" -ne 1 ]; then
    echo "ASSERTION FAILED: expected curl to be called once with HTTP-date Retry-After, got $date_calls" >&2
    exit 1
fi
test -f "$retry_date_state_file" || {
    echo "ASSERTION FAILED: expected retry-after state file for HTTP-date Retry-After" >&2
    exit 1
}

# Retry-After期限切れ後は再試行され、成功時にstateが消えること
retry_expired_dir="$tmp_dir/retry_expired"
retry_expired_cache_file="$retry_expired_dir/claude_usage_v3.cache"
retry_expired_calls_file="$tmp_dir/retry_expired_calls.log"
retry_expired_state_file="$retry_expired_dir/claude_usage_retry_after_v1.state"
mkdir -p "$retry_expired_dir" "$tmp_dir/retry_expired_bin"
: >"$retry_expired_calls_file"
printf '%s' "$(($(date +%s) - 10))" >"$retry_expired_state_file"
cat >"$tmp_dir/retry_expired_bin/curl" <<EOF
#!/usr/bin/env bash
echo x >> "$retry_expired_calls_file"
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 200\r\n\r\n' > "\$header_file"
printf '{"five_hour":{"utilization":14,"resets_at":"2026-03-06T07:00:00Z"},"seven_day":{"utilization":80,"resets_at":"2026-03-08T02:59:00Z"}}' > "\$body_file"
printf '200'
EOF
chmod +x "$tmp_dir/retry_expired_bin/curl"

PATH="$tmp_dir/retry_expired_bin:$orig_path"
CACHE_DIR="$retry_expired_dir"
CACHE_FILE="$retry_expired_cache_file"
LEGACY_CACHE_FILE="$retry_expired_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$retry_expired_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$retry_expired_state_file"

expired_rendered="$(run_segment)"
assert_text_not_contains "rate limited" "$expired_rendered"
assert_text_not_contains "updated at:" "$expired_rendered"
expired_calls="$(wc -l <"$retry_expired_calls_file" | tr -d ' ')"
if [ "$expired_calls" -ne 1 ]; then
    echo "ASSERTION FAILED: expected curl retry after Retry-After expiration, got $expired_calls" >&2
    exit 1
fi
if [ -f "$retry_expired_state_file" ]; then
    echo "ASSERTION FAILED: expected retry-after state file to be removed on success" >&2
    exit 1
fi

# stale cache が無い状態で429を受けた場合は最小表示 "CC rate limited"
no_stale_dir="$tmp_dir/no_stale"
no_stale_calls_file="$tmp_dir/no_stale_calls.log"
no_stale_state_file="$no_stale_dir/claude_usage_retry_after_v1.state"
mkdir -p "$no_stale_dir" "$tmp_dir/no_stale_bin"
: >"$no_stale_calls_file"
cat >"$tmp_dir/no_stale_bin/curl" <<EOF
#!/usr/bin/env bash
echo x >> "$no_stale_calls_file"
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 429\r\nretry-after: 90\r\n\r\n' > "\$header_file"
printf '{"error":{"message":"Rate limited","type":"rate_limit_error"}}' > "\$body_file"
printf '429'
EOF
chmod +x "$tmp_dir/no_stale_bin/curl"

PATH="$tmp_dir/no_stale_bin:$orig_path"
CACHE_DIR="$no_stale_dir"
CACHE_FILE="$no_stale_dir/claude_usage_v3.cache"
LEGACY_CACHE_FILE="$no_stale_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$no_stale_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$no_stale_state_file"

no_stale_rendered="$(run_segment)"
assert_text_contains "CC rate limited" "$no_stale_rendered"
assert_text_not_contains "updated at:" "$no_stale_rendered"

# 失敗マーカー作成時にシンボリックリンクを追従しないこと
symlink_cache_dir="$tmp_dir/symlink_cache"
symlink_cache_file="$symlink_cache_dir/claude_usage_v3.cache"
symlink_marker_file="$symlink_cache_dir/claude_usage_api_failure.marker"
symlink_victim_file="$tmp_dir/symlink_victim.txt"
symlink_bin_dir="$tmp_dir/symlink_bin"
mkdir -p "$symlink_cache_dir" "$symlink_bin_dir"
printf '%s' 'CC 5h:#[fg=#97C9C3]6%#[fg=244]（〜21:00） 7d:#[fg=#E06C75]80%#[fg=244]（〜03/06 11:59） #[fg=244]updated at: 03/05 17:34 #[fg=244]' >"$symlink_cache_file"
printf '%s' 'SAFE' >"$symlink_victim_file"
ln -sf "$symlink_victim_file" "$symlink_marker_file"
perl -e 'my $p = shift; my $ts = time() - 7200; utime $ts, $ts, $p or exit 1;' "$symlink_cache_file"

cat >"$symlink_bin_dir/curl" <<EOF
#!/usr/bin/env bash
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 500\r\n\r\n' > "\$header_file"
: > "\$body_file"
printf '500'
EOF
chmod +x "$symlink_bin_dir/curl"

PATH="$symlink_bin_dir:$PATH"
CACHE_DIR="$symlink_cache_dir"
CACHE_FILE="$symlink_cache_file"
LEGACY_CACHE_FILE="$symlink_cache_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$symlink_marker_file"
RETRY_AFTER_STATE_FILE="$symlink_cache_dir/claude_usage_retry_after_v1.state"

__get_access_token() {
    echo "dummy-token"
}

run_segment >/dev/null || true

PATH="$orig_path"
CACHE_DIR="$orig_cache_dir"
CACHE_FILE="$orig_cache_file"
LEGACY_CACHE_FILE="$orig_legacy_cache_file"
FAILURE_MARKER_FILE="$orig_failure_marker_file"
if [ -n "$orig_retry_after_state_file" ]; then
    RETRY_AFTER_STATE_FILE="$orig_retry_after_state_file"
else
    unset RETRY_AFTER_STATE_FILE
fi

symlink_victim_content="$(cat "$symlink_victim_file")"
if [ "$symlink_victim_content" != "SAFE" ]; then
    echo "ASSERTION FAILED: expected marker write to avoid symlink target modification" >&2
    exit 1
fi

# Retry-After state 作成時にシンボリックリンクを追従しないこと
retry_symlink_dir="$tmp_dir/retry_symlink"
retry_symlink_cache_file="$retry_symlink_dir/claude_usage_v3.cache"
retry_symlink_state_file="$retry_symlink_dir/claude_usage_retry_after_v1.state"
retry_symlink_victim_file="$tmp_dir/retry_symlink_victim.txt"
retry_symlink_calls_file="$tmp_dir/retry_symlink_calls.log"
retry_symlink_bin_dir="$tmp_dir/retry_symlink_bin"
mkdir -p "$retry_symlink_dir" "$retry_symlink_bin_dir"
printf '%s' 'CC 5h:#[fg=#97C9C3]6%#[fg=244]（〜21:00） 7d:#[fg=#E06C75]80%#[fg=244]（〜03/06 11:59）' >"$retry_symlink_cache_file"
printf '%s' 'SAFE' >"$retry_symlink_victim_file"
ln -sf "$retry_symlink_victim_file" "$retry_symlink_state_file"
: >"$retry_symlink_calls_file"
perl -e 'my $p = shift; my $ts = time() - 7200; utime $ts, $ts, $p or exit 1;' "$retry_symlink_cache_file"
cat >"$retry_symlink_bin_dir/curl" <<EOF
#!/usr/bin/env bash
echo x >> "$retry_symlink_calls_file"
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D)
            header_file="\$2"
            shift 2
            ;;
        -o)
            body_file="\$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 429\r\nretry-after: 180\r\n\r\n' > "\$header_file"
printf '{"error":{"message":"Rate limited","type":"rate_limit_error"}}' > "\$body_file"
printf '429'
EOF
chmod +x "$retry_symlink_bin_dir/curl"

PATH="$retry_symlink_bin_dir:$orig_path"
CACHE_DIR="$retry_symlink_dir"
CACHE_FILE="$retry_symlink_cache_file"
LEGACY_CACHE_FILE="$retry_symlink_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$retry_symlink_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$retry_symlink_state_file"

run_segment >/dev/null || true
retry_symlink_victim_content="$(cat "$retry_symlink_victim_file")"
if [ "$retry_symlink_victim_content" != "SAFE" ]; then
    echo "ASSERTION FAILED: expected retry-after state write to avoid symlink target modification" >&2
    exit 1
fi

# stale cache が無い API 失敗でも、同一15分帯の再試行抑制用マーカーを作成すること
failure_no_cache_dir="$tmp_dir/failure_no_cache"
failure_no_cache_marker="$failure_no_cache_dir/claude_usage_api_failure.marker"
failure_no_cache_bin="$tmp_dir/failure_no_cache_bin"
mkdir -p "$failure_no_cache_dir" "$failure_no_cache_bin"
cat >"$failure_no_cache_bin/curl" <<'EOF'
#!/usr/bin/env bash
header_file=""
body_file=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -D)
            header_file="$2"
            shift 2
            ;;
        -o)
            body_file="$2"
            shift 2
            ;;
        -w)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
printf 'HTTP/2 500\r\n\r\n' > "$header_file"
printf '{}' > "$body_file"
printf '500'
EOF
chmod +x "$failure_no_cache_bin/curl"

PATH="$failure_no_cache_bin:$orig_path"
CACHE_DIR="$failure_no_cache_dir"
CACHE_FILE="$failure_no_cache_dir/claude_usage_v3.cache"
LEGACY_CACHE_FILE="$failure_no_cache_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$failure_no_cache_marker"
RETRY_AFTER_STATE_FILE="$failure_no_cache_dir/claude_usage_retry_after_v1.state"

rm -f "$failure_no_cache_marker"
run_segment >/dev/null || true
if [ ! -f "$failure_no_cache_marker" ]; then
    echo "ASSERTION FAILED: expected failure marker even when stale cache is unavailable" >&2
    exit 1
fi

PATH="$orig_path"
CACHE_DIR="$orig_cache_dir"
CACHE_FILE="$orig_cache_file"
LEGACY_CACHE_FILE="$orig_legacy_cache_file"
FAILURE_MARKER_FILE="$orig_failure_marker_file"
if [ -n "$orig_retry_after_state_file" ]; then
    RETRY_AFTER_STATE_FILE="$orig_retry_after_state_file"
else
    unset RETRY_AFTER_STATE_FILE
fi

# 高消費ペース統合テスト: 5h/7d ともに赤(projected>=100%)
# 5h: 3600s経過(resets_at=now+14400)・utilization=50% → projected=250% → 赤
# 7d: 4800s経過(resets_at=now+600000)・utilization=10% → projected=1260% → 赤
high_pace_dir="$tmp_dir/high_pace"
high_pace_bin_dir="$tmp_dir/high_pace_bin"
mkdir -p "$high_pace_dir" "$high_pace_bin_dir"
five_reset_future=$(perl -MPOSIX=strftime -e 'print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time() + 14400))')
seven_reset_future=$(perl -MPOSIX=strftime -e 'print strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time() + 600000))')
cat >"$high_pace_bin_dir/curl" <<EOF
#!/usr/bin/env bash
header_file=""
body_file=""
while [ "\$#" -gt 0 ]; do
    case "\$1" in
        -D) header_file="\$2"; shift 2 ;;
        -o) body_file="\$2"; shift 2 ;;
        -w) shift 2 ;;
        *) shift ;;
    esac
done
printf 'HTTP/2 200\r\n\r\n' > "\$header_file"
printf '{"five_hour":{"utilization":50,"resets_at":"${five_reset_future}"},"seven_day":{"utilization":10,"resets_at":"${seven_reset_future}"}}' > "\$body_file"
printf '200'
EOF
chmod +x "$high_pace_bin_dir/curl"

PATH="$high_pace_bin_dir:$orig_path"
CACHE_DIR="$high_pace_dir"
CACHE_FILE="$high_pace_dir/claude_usage_v3.cache"
LEGACY_CACHE_FILE="$high_pace_dir/claude_usage_v2.cache"
FAILURE_MARKER_FILE="$high_pace_dir/claude_usage_api_failure.marker"
RETRY_AFTER_STATE_FILE="$high_pace_dir/claude_usage_retry_after_v1.state"

__get_access_token() {
    echo "dummy-token"
}

high_pace_rendered="$(run_segment)"
assert_text_contains "5h:#[fg=${COLOR_HIGH}]50%#[default]" "$high_pace_rendered"
assert_text_contains "7d:#[fg=${COLOR_HIGH}]10%#[default]" "$high_pace_rendered"

echo "claude_usage_segment_test: ok"
