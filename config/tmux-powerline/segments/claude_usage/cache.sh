# shellcheck shell=bash

# キャッシュ文字列から末尾の旧タイムスタンプ表記を除去
# 引数: $1=cache_content
function __sanitize_cache_output() {
    local cache_content="$1"
    printf '%s\n' "$cache_content" | sed -E 's/[[:space:]]+#\[fg=[^]]+\]updated at[[:space:]]*:.*$//; s/[[:space:]]+updated at[[:space:]]*:.*$//; s/%#\[fg=[^]]+\]（/%#[default]（/g'
}

# キャッシュが最大経過秒内なら内容を返す
# 引数: $1=cache_file $2=max_age_seconds
function __cat_cache_if_fresh() {
    local target_file="$1"
    local max_age="$2"
    [ -f "$target_file" ] || return 1
    [ ! -L "$target_file" ] || return 1

    # Linux: stat -c %Y, macOS: stat -f %m (順序が重要)
    local cache_age
    cache_age=$(($(date +%s) - $(__file_mtime_epoch "$target_file")))
    if [ "$cache_age" -lt "$max_age" ]; then
        __print_cache_content "$target_file"
        return 0
    fi
    return 1
}

# 現在時刻のローカル表示を返す
# 引数: $1=time_format
function __format_local_now() {
    local time_format="${1:-%m/%d %H:%M}"
    date +"$time_format" 2>/dev/null || echo "--/-- --:--"
}

# キャッシュファイルのmtime epochを返す
# 引数: $1=cache_file
function __file_mtime_epoch() {
    local target_file="$1"
    stat -c %Y "$target_file" 2>/dev/null || stat -f %m "$target_file" 2>/dev/null || echo 0
}

# epoch秒をローカル時刻文字列へ変換
# 引数: $1=epoch_seconds $2=time_format
function __format_epoch_local() {
    local epoch_seconds="$1"
    local time_format="${2:-%m/%d %H:%M}"

    if date -d "@$epoch_seconds" +"$time_format" >/dev/null 2>&1; then
        date -d "@$epoch_seconds" +"$time_format"
        return 0
    fi

    if date -r "$epoch_seconds" +"$time_format" >/dev/null 2>&1; then
        date -r "$epoch_seconds" +"$time_format"
        return 0
    fi

    echo "--/-- --:--"
}

# キャッシュ内容を読み込み、旧タイムスタンプ表記を除去して返す
# 引数: $1=cache_file
function __print_cache_content() {
    local target_file="$1"
    local cache_content
    cache_content=$(cat "$target_file") || return 1
    __sanitize_cache_output "$cache_content"
}

# YYYYMMDDHHMM を 15分単位のキーに丸める
# 例: 202603052359 -> 202603052345
# 引数: $1=yyyymmddhhmm
function __to_quarter_hour_key() {
    local ymdhm="$1"
    if [[ ! "$ymdhm" =~ ^[0-9]{12}$ ]]; then
        return 1
    fi

    local base minute minute_num quarter
    base="${ymdhm:0:10}"
    minute="${ymdhm:10:2}"
    minute_num=$((10#$minute))
    quarter=$(((minute_num / 15) * 15))
    printf '%s%02d\n' "$base" "$quarter"
}

# 同じ15分帯（ローカル時刻）ならキャッシュを返す
# 引数: $1=cache_file
function __cat_cache_if_current_quarter_hour() {
    local target_file="$1"
    __is_current_quarter_file "$target_file" || return 1
    __print_cache_content "$target_file"
    return 0
}

# 対象ファイルが同じ15分帯（ローカル時刻）なら成功
# 引数: $1=target_file
function __is_current_quarter_file() {
    local target_file="$1"
    [ -f "$target_file" ] || return 1
    [ ! -L "$target_file" ] || return 1

    local mtime_epoch now_ymdhm cache_ymdhm now_quarter_key cache_quarter_key
    mtime_epoch=$(__file_mtime_epoch "$target_file")
    now_ymdhm=$(__format_local_now "%Y%m%d%H%M")
    cache_ymdhm=$(__format_epoch_local "$mtime_epoch" "%Y%m%d%H%M")
    now_quarter_key=$(__to_quarter_hour_key "$now_ymdhm") || return 1
    cache_quarter_key=$(__to_quarter_hour_key "$cache_ymdhm") || return 1

    if [ "$now_quarter_key" = "$cache_quarter_key" ]; then
        return 0
    fi
    return 1
}

# 古いキャッシュを使用（API障害時のフォールバック）
function __use_stale_cache() {
    __cat_cache_if_fresh "$CACHE_FILE" "$STALE_CACHE_MAX" && return 0
    __cat_cache_if_fresh "$LEGACY_CACHE_FILE" "$STALE_CACHE_MAX" && return 0
    return 1
}

# 文字列が非負整数か判定
# 引数: $1=value
function __is_positive_integer() {
    local value="$1"
    [[ "$value" =~ ^[0-9]+$ ]]
}

# Retry-After (秒) から次回再試行epochを保存
# 引数: $1=retry_after_seconds
function __set_retry_after_from_seconds() {
    local retry_after_seconds="$1"
    __is_positive_integer "$retry_after_seconds" || return 1
    local retry_after_num=$((10#$retry_after_seconds))
    [ "$retry_after_num" -gt 0 ] || return 1
    local next_retry_epoch=$(($(date +%s) + retry_after_num))
    __write_retry_after_state "$next_retry_epoch"
}

# Retry-After stateを書き込む（アトミック）
# 引数: $1=next_retry_epoch
function __write_retry_after_state() {
    local next_retry_epoch="$1"
    __is_positive_integer "$next_retry_epoch" || return 1
    mkdir -p "$CACHE_DIR" || return 1
    [ ! -L "$RETRY_AFTER_STATE_FILE" ] || return 1

    local tmp_state
    tmp_state=$(mktemp "${RETRY_AFTER_STATE_FILE}.XXXXXX") || return 1
    if ! printf '%s' "$next_retry_epoch" >"$tmp_state"; then
        rm -f "$tmp_state"
        return 1
    fi
    if ! mv -f "$tmp_state" "$RETRY_AFTER_STATE_FILE"; then
        rm -f "$tmp_state"
        return 1
    fi
}

# Retry-After stateから次回再試行epochを読み込む
function __read_retry_after_state() {
    [ -f "$RETRY_AFTER_STATE_FILE" ] || return 1
    [ ! -L "$RETRY_AFTER_STATE_FILE" ] || return 1

    local next_retry_epoch
    next_retry_epoch=$(head -n 1 "$RETRY_AFTER_STATE_FILE" 2>/dev/null | tr -d '[:space:]')
    __is_positive_integer "$next_retry_epoch" || return 1
    echo "$next_retry_epoch"
}

# Retry-After が有効なら成功。期限切れならstateを消す
function __is_retry_after_active() {
    local next_retry_epoch now_epoch
    next_retry_epoch=$(__read_retry_after_state) || return 1
    now_epoch=$(date +%s)
    if [ "$next_retry_epoch" -gt "$now_epoch" ]; then
        return 0
    fi
    __clear_retry_after_state
    return 1
}

# Retry-After state を削除
function __clear_retry_after_state() {
    rm -f "$RETRY_AFTER_STATE_FILE" 2>/dev/null || true
}

# API失敗マーカーを更新（同一15分帯での再試行抑制に利用）
function __mark_api_failure() {
    mkdir -p "$CACHE_DIR" || return 1
    [ ! -L "$FAILURE_MARKER_FILE" ] || return 1

    local tmp_marker
    tmp_marker=$(mktemp "${FAILURE_MARKER_FILE}.XXXXXX") || return 1
    if ! : >"$tmp_marker"; then
        rm -f "$tmp_marker"
        return 1
    fi
    if ! mv -f "$tmp_marker" "$FAILURE_MARKER_FILE"; then
        rm -f "$tmp_marker"
        return 1
    fi
}

# API成功時は失敗マーカーを削除
function __clear_api_failure_marker() {
    rm -f "$FAILURE_MARKER_FILE" 2>/dev/null || true
}

# アトミック書き込みでキャッシュファイルを更新（レースコンディション対策）
function __write_cache() {
    local content="$1"
    mkdir -p "$CACHE_DIR"
    local tmp_cache
    tmp_cache=$(mktemp "${CACHE_FILE}.XXXXXX") || {
        return 0
    }
    if ! printf '%s' "$content" >"$tmp_cache"; then
        rm -f "$tmp_cache"
        return 0
    fi
    if ! mv -f "$tmp_cache" "$CACHE_FILE"; then
        rm -f "$tmp_cache"
    fi
}
