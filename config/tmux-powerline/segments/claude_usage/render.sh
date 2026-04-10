# shellcheck shell=bash

# utilization (0〜100の小数/整数) を0〜100の整数に正規化
function __normalize_pct() {
    local utilization="$1"
    awk -v v="$utilization" 'BEGIN{
		if (v == "" || v !~ /^-?[0-9]+([.][0-9]+)?$/) { print 0; exit }
		p = int(v + 0.5)
		if (p < 0) p = 0
		if (p > 100) p = 100
		print p
	}'
}

# 実使用率の閾値に基づく色を返す
function __usage_color_from_pct() {
    local pct="$1"

    if ((pct >= 80)); then
        echo "$COLOR_HIGH"
    elif ((pct >= 50)); then
        echo "$COLOR_MID"
    else
        echo "$COLOR_LOW"
    fi
}

# ISO8601 → epoch秒変換
function __iso8601_to_epoch() {
    local iso8601="$1"
    [ -n "$iso8601" ] || return 1

    if command -v perl >/dev/null 2>&1; then
        local epoch
        epoch=$(perl -MTime::Local=timegm -e '
my ($raw) = @ARGV;
$raw //= q{};
$raw =~ s/^\s+|\s+$//g;
if ($raw !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})?$/) {
    exit 1;
}
my ($year, $mon, $day, $hour, $min, $sec, $tz) = ($1, $2, $3, $4, $5, $6, $7);
$sec = defined $sec ? $sec : 0;
$tz = defined $tz && length $tz ? $tz : "Z";
my $epoch = timegm($sec, $min, $hour, $day, $mon - 1, $year - 1900);
if ($tz ne "Z") {
    my ($sign, $tzh, $tzm) = ($tz =~ /^([+-])(\d{2}):(\d{2})$/);
    my $offset = ($tzh * 3600) + ($tzm * 60);
    if ($sign eq "+") {
        $epoch -= $offset;
    } else {
        $epoch += $offset;
    }
}
print $epoch;
' "$iso8601" 2>/dev/null || true)
        if [ -n "$epoch" ]; then
            echo "$epoch"
            return 0
        fi
    fi

    if date -d "$iso8601" +%s >/dev/null 2>&1; then
        date -d "$iso8601" +%s
        return 0
    fi

    if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso8601" +%s >/dev/null 2>&1; then
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso8601" +%s
        return 0
    fi

    return 1
}

# 消費ペースに基づく予測で色を決定
# 引数: $1=utilization_pct $2=resets_at(ISO8601) $3=total_window_seconds
function __usage_color() {
    local pct="$1"
    local resets_at="$2"
    local total_window="$3"
    local -i grace_seconds=300

    # utilization が 0 なら予測不要 → 緑
    if ((pct == 0)); then
        echo "$COLOR_LOW"
        return 0
    fi

    if ((total_window <= 0)); then
        __usage_color_from_pct "$pct"
        return 0
    fi

    local resets_at_epoch
    resets_at_epoch=$(__iso8601_to_epoch "$resets_at") || {
        __usage_color_from_pct "$pct"
        return 0
    }
    if [ -z "$resets_at_epoch" ]; then
        __usage_color_from_pct "$pct"
        return 0
    fi

    local now time_remaining time_elapsed
    now=$(date +%s)
    time_remaining=$((resets_at_epoch - now))
    time_elapsed=$((total_window - time_remaining))

    # 開始直後はノイズが大きいので、実使用率ベースへフォールバック
    if ((time_elapsed <= 0 || time_elapsed < grace_seconds)); then
        __usage_color_from_pct "$pct"
        return 0
    fi

    # 予測使用率 = utilization * total_window / time_elapsed
    local projected
    projected=$(awk -v u="$pct" -v tw="$total_window" -v te="$time_elapsed" \
        'BEGIN{print int(u * tw / te)}')
    if [ -z "$projected" ]; then
        __usage_color_from_pct "$pct"
        return 0
    fi

    if ((projected >= 100)); then
        echo "$COLOR_HIGH"
    elif ((projected >= 80)); then
        echo "$COLOR_MID"
    else
        echo "$COLOR_LOW"
    fi
}

# resets_at (ISO8601) をローカル時刻へ変換
# 引数: $1=reset_at(ISO8601) $2=time_format
function __format_local_reset_time() {
    local reset_at="$1"
    local time_format="${2:-%H:%M}"
    [ -n "$reset_at" ] || {
        echo "--:--"
        return 0
    }

    if command -v perl >/dev/null 2>&1; then
        local formatted
        formatted=$(perl -MTime::Local=timegm -MPOSIX=strftime -e '
my ($raw, $fmt) = @ARGV;
$raw //= q{};
$fmt = (defined $fmt && length $fmt) ? $fmt : "%H:%M";
$raw =~ s/^\s+|\s+$//g;
if ($raw !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})?$/) {
    exit 1;
}
my ($year, $mon, $day, $hour, $min, $sec, $tz) = ($1, $2, $3, $4, $5, $6, $7);
$sec = defined $sec ? $sec : 0;
$tz = defined $tz && length $tz ? $tz : "Z";
my $epoch = timegm($sec, $min, $hour, $day, $mon - 1, $year - 1900);
if ($tz ne "Z") {
    my ($sign, $tzh, $tzm) = ($tz =~ /^([+-])(\d{2}):(\d{2})$/);
    my $offset = ($tzh * 3600) + ($tzm * 60);
    if ($sign eq "+") {
        $epoch -= $offset;
    } else {
        $epoch += $offset;
    }
}
print strftime($fmt, localtime($epoch));
' "$reset_at" "$time_format" 2>/dev/null || true)
        if [ -n "$formatted" ]; then
            echo "$formatted"
            return 0
        fi
    fi

    if date -d "$reset_at" +"$time_format" >/dev/null 2>&1; then
        date -d "$reset_at" +"$time_format"
        return 0
    fi

    if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$reset_at" +"$time_format" >/dev/null 2>&1; then
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$reset_at" +"$time_format"
        return 0
    fi

    echo "--:--"
}

# reset時刻が有効な場合のみ「（〜...）」を返す
# 引数: $1=reset_local_time
function __render_reset_suffix() {
    local reset_local_time="${1:-}"
    [ -n "$reset_local_time" ] || return 0

    # "--:--" / "--:00" / "--/-- --:--" など不明値は非表示
    if [[ "$reset_local_time" == *"--"* ]]; then
        return 0
    fi

    printf '（〜%s）' "$reset_local_time"
}

# 既存表示に rate limited を追記
# 引数: $1=base_output $2=label
function __append_rate_limited_suffix() {
    local base_output="$1"
    local label="$2"
    if [ -z "$base_output" ]; then
        printf '%s rate limited\n' "$label"
        return 0
    fi
    if [[ "$base_output" == *" rate limited" ]]; then
        printf '%s\n' "$base_output"
    else
        printf '%s rate limited\n' "$base_output"
    fi
}

# stale cache があればそれに注記、無ければ最小表示を返す
# 引数: $1=label
function __render_rate_limited_output() {
    local label="$1"
    local stale_output
    stale_output=$(__use_stale_cache) || {
        printf '%s rate limited\n' "$label"
        return 0
    }
    __append_rate_limited_suffix "$stale_output" "$label"
}
