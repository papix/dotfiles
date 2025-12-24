# shellcheck shell=bash
# LICENSE This code is not under the same license as the rest of the project as it's "stolen". It's cloned from https://github.com/richoH/dotfiles/blob/master/bin/battery and just some modifications are done so it works for my laptop. Check that URL for more recent versions.

TMUX_POWERLINE_SEG_BATTERY_TYPE_DEFAULT="percentage"
TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS_DEFAULT=5

HEART_FULL="♥"
HEART_EMPTY="♡"
BATTERY_FULL="󱊣"
BATTERY_MED="󱊢"
BATTERY_EMPTY="󱊡"
BATTERY_CHARGE="󰂄"
ADAPTER="󰚥"

# Cache settings
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-powerline"
CACHE_FILE="${CACHE_DIR}/battery.cache"
CACHE_DURATION=60  # 1 minute

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# How to display battery remaining. Can be {percentage, cute, hearts}.
export TMUX_POWERLINE_SEG_BATTERY_TYPE="${TMUX_POWERLINE_SEG_BATTERY_TYPE_DEFAULT}"
# How may hearts to show if cute indicators are used.
export TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS="${TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS_DEFAULT}"
EORC
	echo "$rccontents"
}

run_segment() {
	# macOS以外を無効化したい場合は TMUX_POWERLINE_SEG_BATTERY_MACOS_ONLY=1
	if [ "${TMUX_POWERLINE_SEG_BATTERY_MACOS_ONLY:-0}" = "1" ] && ! tp_shell_is_macos; then
		return
	fi

	# Check cache
	if [ -f "$CACHE_FILE" ] && [ ! -L "$CACHE_FILE" ]; then
		cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
		if [ $cache_age -lt $CACHE_DURATION ]; then
			cat "$CACHE_FILE"
			return 0
		fi
	fi

	__process_settings
	if tp_shell_is_macos; then
		battery_status=$(__battery_macos)
	else
		battery_status=$(__battery_linux)
	fi
	if [ -z "$battery_status" ]; then
		output="$ADAPTER"
	else
		local battery_percent
		battery_percent=$(printf "%s" "$battery_status" | sed -e 's/#\[[^]]*]//g' | grep -Eo '[0-9]+' | tail -n 1)
		case "$TMUX_POWERLINE_SEG_BATTERY_TYPE" in
		"percentage")
			output="${battery_status}"
			;;
		"cute")
			if [ -n "$battery_percent" ]; then
				output=$(__cutinate "$battery_percent")
			else
				output="${battery_status}"
			fi
			;;
		"hearts")
			if [ -n "$battery_percent" ]; then
				output=$(__generate_hearts "$battery_percent")
			else
				output="${battery_status}"
			fi
			;;
		esac
	fi
	
	if [ -n "$output" ]; then
		# Cache the result
		mkdir -p "$CACHE_DIR"
		local tmp_cache
		tmp_cache=$(mktemp "${CACHE_FILE}.XXXXXX") || {
			printf '%s\n' "$output"
			return 0
		}
		if ! printf '%s' "$output" > "$tmp_cache"; then
			rm -f "$tmp_cache"
			printf '%s\n' "$output"
			return 0
		fi
		if ! mv -f "$tmp_cache" "$CACHE_FILE"; then
			rm -f "$tmp_cache"
		fi
		printf '%s\n' "$output"
	fi
}

__process_settings() {
	if [ -z "$TMUX_POWERLINE_SEG_BATTERY_TYPE" ]; then
		export TMUX_POWERLINE_SEG_BATTERY_TYPE="${TMUX_POWERLINE_SEG_BATTERY_TYPE_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS" ]; then
		export TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS="${TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS_DEFAULT}"
	fi
}

__battery_macos() {
	local batt
	batt=$(pmset -g batt 2>/dev/null)
	if printf "%s\n" "$batt" | grep -qi "no batteries"; then
		return
	fi
	local charge
	charge=$(printf "%s\n" "$batt" | grep -Eo '[0-9]+%' | head -n 1 | tr -d '%')
	[[ -z "$charge" ]] && return
	local ac_power=0
	local is_charged=0
	if printf "%s\n" "$batt" | grep -q "AC Power"; then
		ac_power=1
	fi
	if printf "%s\n" "$batt" | grep -qi "charged"; then
		is_charged=1
	fi

	if [[ "$ac_power" -eq 1 ]]; then
		if [[ "$charge" -ge 100 || "$is_charged" -eq 1 ]]; then
			return
		fi
		echo "$BATTERY_CHARGE$charge%"
	else
		if [[ $charge -lt 50 ]]; then
			echo -n "#[fg=colour220]"
			echo "$BATTERY_EMPTY$charge%"
		elif [[ $charge -lt 80 ]]; then
			echo "$BATTERY_MED$charge%"
		else
			echo "$BATTERY_FULL$charge%"
		fi
	fi
}

__battery_linux() {
	case "$SHELL_PLATFORM" in
	"linux")
		__linux_get_bat
		;;
	"bsd")
		__freebsd_get_bat
		;;
	esac
}

__cutinate() {
	perc=$1
	inc=$((100 / TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS))

	for _unused in $(seq "$TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS"); do
		if [ "$perc" -lt 99 ]; then
			echo -n $BATTERY_EMPTY
		else
			echo -n $BATTERY_FULL
		fi
		echo -n " "
		perc=$((perc + inc))
	done
}

__generate_hearts() {
	perc=$1
	num_hearts=$TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS
	hearts_output=""

	for i in $(seq 1 "$num_hearts"); do
		if [ "$perc" -ge $((i * 100 / num_hearts)) ]; then
			hearts_output+="$HEART_FULL "
		else
			hearts_output+="$HEART_EMPTY "
		fi
	done
	echo "$hearts_output"
}

__linux_get_bat() {
	local total_full=0
	local total_now=0

	while read -r bat; do
		local full="$bat/charge_full"
		local now="$bat/charge_now"

		if [ ! -r "$full" ]; then
			full="$bat/energy_full"
		fi
		if [ ! -r "$now" ]; then
			now="$bat/energy_now"
		fi

		if [ -r "$full" ] && [ -r "$now" ]; then
			local bf
			local bn
			bf=$(cat "$full")
			bn=$(cat "$now")
			total_full=$((total_full + bf))
			total_now=$((total_now + bn))
		fi
	done <<<"$(grep -l "Battery" /sys/class/power_supply/*/type | sed -e 's,/type$,,')"

	if [ "$total_full" -gt 0 ]; then
		if [ "$total_now" -gt "$total_full" ]; then
			total_now=$total_full
		fi
		echo "$BATTERY_MED $((100 * total_now / total_full))"
	fi
}

__freebsd_get_bat() {
	echo "$BATTERY_MED $(sysctl -n hw.acpi.battery.life)"
}
