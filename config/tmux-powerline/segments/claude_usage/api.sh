# shellcheck shell=bash

# APIレスポンス本文を返し、HTTPステータス/Retry-Afterをグローバル変数へ設定
# 引数: $1=access_token
function __call_usage_api() {
    local token="$1"
    API_HTTP_STATUS=""
    API_RETRY_AFTER=""
    API_RESPONSE=""

    local header_file body_file
    header_file=$(mktemp 2>/dev/null) || {
        return 0
    }
    body_file=$(mktemp 2>/dev/null) || {
        rm -f "$header_file"
        return 0
    }

    API_HTTP_STATUS=$(curl -sS --max-time "$CURL_TIMEOUT" --noproxy '*' \
        -D "$header_file" \
        -o "$body_file" \
        -w "%{http_code}" \
        -H "Authorization: Bearer ${token}" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "$CLAUDE_USAGE_API" 2>/dev/null || true)
    API_RETRY_AFTER=$(__extract_retry_after_seconds "$header_file" || true)

    API_RESPONSE=$(cat "$body_file" 2>/dev/null || true)
    rm -f "$header_file" "$body_file"
}

# HTTPヘッダーから Retry-After 秒値を抽出
# 引数: $1=header_file
function __extract_retry_after_seconds() {
    local header_file="$1"
    [ -f "$header_file" ] || return 1

    local retry_after
    retry_after=$(awk 'BEGIN{IGNORECASE=1}
/^retry-after:/ {
line=$0
sub(/\r$/, "", line)
sub(/^[^:]*:[[:space:]]*/, "", line)
print line
exit
	}' "$header_file" 2>/dev/null)

    if __is_positive_integer "$retry_after"; then
        echo "$retry_after"
        return 0
    fi

    __retry_after_http_date_to_seconds "$retry_after"
}

# Retry-After の HTTP-date を秒数に変換
# 引数: $1=retry_after_http_date
function __retry_after_http_date_to_seconds() {
    local retry_after_http_date="$1"
    [ -n "$retry_after_http_date" ] || return 1

    if command -v perl >/dev/null 2>&1; then
        local seconds
        seconds=$(perl -MTime::Local=timegm -e '
my $raw = shift // q{};
$raw =~ s/^\s+|\s+$//g;
if ($raw !~ /^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$/) {
    exit 1;
}
my %month = (
    Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5,
    Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11
);
my ($day, $mon, $year, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
my $retry_epoch = timegm($sec, $min, $hour, $day, $month{$mon}, $year - 1900);
my $delta = $retry_epoch - time();
if ($delta < 0) {
    $delta = 0;
}
print $delta;
' "$retry_after_http_date" 2>/dev/null)
        if __is_positive_integer "$seconds"; then
            echo "$seconds"
            return 0
        fi
    fi

    local retry_epoch now_epoch retry_after_seconds
    retry_epoch=$(date -d "$retry_after_http_date" +%s 2>/dev/null || date -j -f "%a, %d %b %Y %H:%M:%S %Z" "$retry_after_http_date" +%s 2>/dev/null) || return 1
    now_epoch=$(date +%s)
    retry_after_seconds=$((retry_epoch - now_epoch))
    if [ "$retry_after_seconds" -gt 0 ]; then
        echo "$retry_after_seconds"
        return 0
    fi
    echo 0
}

# Linux: ~/.claude/.credentials.json からアクセストークンを取得
function __get_token_linux() {
    local creds_file="$HOME/.claude/.credentials.json"
    [ -f "$creds_file" ] || return 1
    if command -v jq &>/dev/null; then
        jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null
    elif command -v perl >/dev/null 2>&1; then
        perl -MJSON::PP -e '
my $path = shift;
open my $fh, "<", $path or exit 1;
local $/;
my $d = eval { decode_json(<$fh>) };
exit 1 if !$d;
my $token = $d->{claudeAiOauth}{accessToken};
print $token if defined $token;
' "$creds_file" 2>/dev/null
    fi
}

# macOS: Keychainからトークン取得を試み、失敗時はファイルにフォールバック
# サービス名 "Claude Code-credentials" はClaude Codeが標準で使用する名前
function __get_token_macos() {
    local json
    json=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || {
        __get_token_linux
        return
    }
    # KeychainのJSONからaccessTokenを抽出
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || __get_token_linux
    elif command -v perl >/dev/null 2>&1; then
        echo "$json" | perl -MJSON::PP -e '
local $/;
my $d = eval { decode_json(<STDIN>) };
exit 1 if !$d;
my $token = $d->{claudeAiOauth}{accessToken};
print $token if defined $token;
' 2>/dev/null || __get_token_linux
    else
        __get_token_linux
    fi
}

# プラットフォームに応じたトークン取得
function __get_access_token() {
    local uname_s
    uname_s=$(uname -s 2>/dev/null)
    if [ "$uname_s" = "Darwin" ]; then
        __get_token_macos
    else
        __get_token_linux
    fi
}
