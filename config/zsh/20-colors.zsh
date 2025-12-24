#!/usr/bin/env zsh
########################################
# カラー設定
########################################
# 依存: なし

autoload -Uz colors
colors

# zsh用Solarized Darkカラー
# base03: 234, base02: 235, base01: 240, base00: 241
# base0: 244, base1: 245, base2: 254, base3: 230
# yellow: 136, orange: 166, red: 160, magenta: 125
# violet: 61, blue: 33, cyan: 37, green: 64

# 他のモジュールで使用するためにエクスポート
export DEFAULT=$'%{\e[0;0m%}'
export RESET="%{${reset_color}%}"

# Solarized Darkカラー定義
export SOLARIZED_BASE03=$'%{\e[38;5;234m%}'
export SOLARIZED_BASE02=$'%{\e[38;5;235m%}'
export SOLARIZED_BASE01=$'%{\e[38;5;240m%}'
export SOLARIZED_BASE00=$'%{\e[38;5;241m%}'
export SOLARIZED_BASE0=$'%{\e[38;5;244m%}'
export SOLARIZED_BASE1=$'%{\e[38;5;245m%}'
export SOLARIZED_BASE2=$'%{\e[38;5;254m%}'
export SOLARIZED_BASE3=$'%{\e[38;5;230m%}'
export SOLARIZED_YELLOW=$'%{\e[38;5;136m%}'
export SOLARIZED_ORANGE=$'%{\e[38;5;166m%}'
export SOLARIZED_RED=$'%{\e[38;5;160m%}'
export SOLARIZED_MAGENTA=$'%{\e[38;5;125m%}'
export SOLARIZED_VIOLET=$'%{\e[38;5;61m%}'
export SOLARIZED_BLUE=$'%{\e[38;5;33m%}'
export SOLARIZED_CYAN=$'%{\e[38;5;37m%}'
export SOLARIZED_GREEN=$'%{\e[38;5;64m%}'

# Aliases for compatibility
export WHITE="${SOLARIZED_BASE2}"
export GREEN="${SOLARIZED_GREEN}"
export BOLD_GREEN="${SOLARIZED_GREEN}"
export BLUE="${SOLARIZED_BLUE}"
export BOLD_BLUE="${SOLARIZED_BLUE}"
export RED="${SOLARIZED_RED}"
export BOLD_RED="${SOLARIZED_RED}"
export CYAN="${SOLARIZED_CYAN}"
export BOLD_CYAN="${SOLARIZED_CYAN}"
export YELLOW="${SOLARIZED_YELLOW}"
export BOLD_YELLOW="${SOLARIZED_YELLOW}"
export MAGENTA="${SOLARIZED_MAGENTA}"
export BOLD_MAGENTA="${SOLARIZED_MAGENTA}"