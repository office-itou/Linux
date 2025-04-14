#!/bin/bash

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	declare -i    _SIZE_ROWS=25
	declare -i    _SIZE_COLS=80

	if command -v tput > /dev/null 2>&1; then
		_SIZE_ROWS=$(tput lines)
		_SIZE_COLS=$(tput cols)
	fi
	if [[ "${_SIZE_ROWS:-0}" -lt 25 ]]; then
		_SIZE_ROWS=25
	fi
	if [[ "${_SIZE_COLS:-0}" -lt 80 ]]; then
		_SIZE_COLS=80
	fi

	readonly      _SIZE_ROWS
	readonly      _SIZE_COLS

	declare       _TEXT_SPCE=""
	              _TEXT_SPCE="$(printf "%${_SIZE_COLS}s" "")"
	readonly      _TEXT_SPCE

	declare -r    _TEXT_GAP1="${_TEXT_SPCE// /-}"
	declare -r    _TEXT_GAP2="${_TEXT_SPCE// /=}"

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- constant for colors -------------------------------------------------
	# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
	declare -r    _TEXT_RESET="${_CODE_ESCP}[0m"				# reset all attributes
	declare -r    _TEXT_BOLD="${_CODE_ESCP}[1m"					# 
	declare -r    _TEXT_FAINT="${_CODE_ESCP}[2m"				# 
	declare -r    _TEXT_ITALIC="${_CODE_ESCP}[3m"				# 
	declare -r    _TEXT_UNDERLINE="${_CODE_ESCP}[4m"			# set underline
	declare -r    _TEXT_BLINK="${_CODE_ESCP}[5m"				# 
	declare -r    _TEXT_FAST_BLINK="${_CODE_ESCP}[6m"			# 
	declare -r    _TEXT_REVERSE="${_CODE_ESCP}[7m"				# set reverse display
	declare -r    _TEXT_CONCEAL="${_CODE_ESCP}[8m"				# 
	declare -r    _TEXT_STRIKE="${_CODE_ESCP}[9m"				# 
	declare -r    _TEXT_GOTHIC="${_CODE_ESCP}[20m"				# 
	declare -r    _TEXT_DOUBLE_UNDERLINE="${_CODE_ESCP}[21m"	# 
	declare -r    _TEXT_NORMAL="${_CODE_ESCP}[22m"				# 
	declare -r    _TEXT_NO_ITALIC="${_CODE_ESCP}[23m"			# 
	declare -r    _TEXT_NO_UNDERLINE="${_CODE_ESCP}[24m"		# reset underline
	declare -r    _TEXT_NO_BLINK="${_CODE_ESCP}[25m"			# 
	declare -r    _TEXT_NO_REVERSE="${_CODE_ESCP}[27m"			# reset reverse display
	declare -r    _TEXT_NO_CONCEAL="${_CODE_ESCP}[28m"			# 
	declare -r    _TEXT_NO_STRIKE="${_CODE_ESCP}[29m"			# 
	declare -r    _TEXT_BLACK="${_CODE_ESCP}[30m"				# text dark black
	declare -r    _TEXT_RED="${_CODE_ESCP}[31m"					# text dark red
	declare -r    _TEXT_GREEN="${_CODE_ESCP}[32m"				# text dark green
	declare -r    _TEXT_YELLOW="${_CODE_ESCP}[33m"				# text dark yellow
	declare -r    _TEXT_BLUE="${_CODE_ESCP}[34m"				# text dark blue
	declare -r    _TEXT_MAGENTA="${_CODE_ESCP}[35m"				# text dark purple
	declare -r    _TEXT_CYAN="${_CODE_ESCP}[36m"				# text dark light blue
	declare -r    _TEXT_WHITE="${_CODE_ESCP}[37m"				# text dark white
	declare -r    _TEXT_DEFAULT="${_CODE_ESCP}[39m"				# 
	declare -r    _TEXT_BG_BLACK="${_CODE_ESCP}[40m"			# text reverse black
	declare -r    _TEXT_BG_RED="${_CODE_ESCP}[41m"				# text reverse red
	declare -r    _TEXT_BG_GREEN="${_CODE_ESCP}[42m"			# text reverse green
	declare -r    _TEXT_BG_YELLOW="${_CODE_ESCP}[43m"			# text reverse yellow
	declare -r    _TEXT_BG_BLUE="${_CODE_ESCP}[44m"				# text reverse blue
	declare -r    _TEXT_BG_MAGENTA="${_CODE_ESCP}[45m"			# text reverse purple
	declare -r    _TEXT_BG_CYAN="${_CODE_ESCP}[46m"				# text reverse light blue
	declare -r    _TEXT_BG_WHITE="${_CODE_ESCP}[47m"			# text reverse white
	declare -r    _TEXT_BG_DEFAULT="${_CODE_ESCP}[49m"			# 
	declare -r    _TEXT_BR_BLACK="${_CODE_ESCP}[90m"			# text black
	declare -r    _TEXT_BR_RED="${_CODE_ESCP}[91m"				# text red
	declare -r    _TEXT_BR_GREEN="${_CODE_ESCP}[92m"			# text green
	declare -r    _TEXT_BR_YELLOW="${_CODE_ESCP}[93m"			# text yellow
	declare -r    _TEXT_BR_BLUE="${_CODE_ESCP}[94m"				# text blue
	declare -r    _TEXT_BR_MAGENTA="${_CODE_ESCP}[95m"			# text purple
	declare -r    _TEXT_BR_CYAN="${_CODE_ESCP}[96m"				# text light blue
	declare -r    _TEXT_BR_WHITE="${_CODE_ESCP}[97m"			# text white
	declare -r    _TEXT_BR_DEFAULT="${_CODE_ESCP}[99m"			# 

# --- string output -----------------------------------------------------------
function funcString() {
	declare       _TEXT_WORK=""			#
	printf -v _TEXT_WORK -- "%${1:-0}s" ""
	echo -n "${_TEXT_WORK// /"${2:-}"}"
}

# --- print with screen control -----------------------------------------------
function funcPrintf() {
	declare -r    _FLAG_TRCE="$(set -o | grep "^xtrace\s*on$")"
	set +x
	# -------------------------------------------------------------------------
	declare       _FLAG_NCUT=""			# no cutting flag
	declare       _TEXT_FMAT=""			# format parameter
	declare       _TEXT_UTF8=""			# formatted utf8
	declare       _TEXT_SJIS=""			# formatted sjis (cp932)
	declare       _TEXT_PLIN=""			# formatted string without attributes
	declare       _TEXT_WORK=""			# 
	declare       _ESCP_FRNT=""			# escape characters front
	# -------------------------------------------------------------------------
	# https://www.tohoho-web.com/ex/dash-tilde.html
	# -------------------------------------------------------------------------
	case "$1" in
		--no-cutting) _FLAG_NCUT="true"; shift;;
		*           ) ;;
	esac
	# -------------------------------------------------------------------------
	_TEXT_FMAT="${1:-}"
	shift
	# shellcheck disable=SC2059
	printf -v _TEXT_UTF8 -- "${_TEXT_FMAT}" "${@:-}"
	# -------------------------------------------------------------------------
	if [[ -z "${_FLAG_NCUT:-}" ]]; then
		_TEXT_SJIS="$(echo -n "${_TEXT_UTF8:-}" | iconv -f UTF-8 -t CP932 -c -s || true)"
		_TEXT_PLIN="${_TEXT_SJIS//"${_CODE_ESCP}["[0-9]m/}"
		_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
		_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
		if [[ "${#_TEXT_PLIN}" -gt "${_SIZE_COLS}" ]]; then
			_TEXT_WORK="${_TEXT_SJIS}"
			while true
			do
				case "${_TEXT_WORK}" in
					"${_CODE_ESCP}"\[[0-9]*m*)
						_TEXT_WORK="${_TEXT_WORK/#"${_CODE_ESCP}["[0-9]m/}"
						_TEXT_WORK="${_TEXT_WORK/#"${_CODE_ESCP}["[0-9][0-9]m/}"
						_TEXT_WORK="${_TEXT_WORK/#"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
						;;
					*) break;;
				esac
			done
			_ESCP_FRNT="${_TEXT_SJIS%"${_TEXT_WORK}"}"
			# -----------------------------------------------------------------
#set -x
			_TEXT_WORK="${_TEXT_SJIS:"${#_ESCP_FRNT}":"${_SIZE_COLS}"}"
#printf "${_TEXT_RESET}%s(%6d)=[%q]${_TEXT_RESET}\n" "_TEXT_SJIS" "${#_TEXT_SJIS}" "${_TEXT_SJIS}"
#printf "${_TEXT_RESET}%s(%6d)=[%q]${_TEXT_RESET}\n" "_TEXT_WORK" "${#_TEXT_WORK}" "${_TEXT_WORK}"
			while true
			do
				_TEXT_PLIN="${_TEXT_WORK//"${_CODE_ESCP}["[0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN%%"${_CODE_ESCP}"*}"
#printf "${_TEXT_RESET}%s(%6d)=[%q]${_TEXT_RESET}\n" "_TEXT_PLIN" "${#_TEXT_PLIN}" "${_TEXT_PLIN}"
				if [[ "${#_TEXT_PLIN}" -eq "${_SIZE_COLS}" ]]; then
					break
				fi
				_TEXT_WORK="${_TEXT_SJIS:"${#_ESCP_FRNT}":$(("${#_TEXT_WORK}"+"${_SIZE_COLS}"-"${#_TEXT_PLIN}"))}"
#printf "${_TEXT_RESET}%s(%6d)=[%q]${_TEXT_RESET}\n" "_TEXT_WORK" "${#_TEXT_WORK}" "${_TEXT_WORK}"
			done
			_TEXT_WORK="${_ESCP_FRNT}${_TEXT_WORK}"
#printf "${_TEXT_RESET}%s(%6d)=[%q]${_TEXT_RESET}\n" "_TEXT_WORK" "${#_TEXT_WORK}" "${_TEXT_WORK}"
			_TEXT_UTF8="$(echo -n "${_TEXT_WORK}" | iconv -f CP932 -t UTF-8 -c -s 2> /dev/null || true)"
#set +x
		fi
	fi
	printf "%s%b%s\n" "${_TEXT_RESET}" "${_TEXT_UTF8}" "${_TEXT_RESET}"
	if [[ -n "${_FLAG_TRCE:-}" ]]; then
		set -x
	else
		set +x
	fi
}

	funcPrintf "${_TEXT_BG_GREEN}=== test ==="
	# shellcheck disable=SC2312
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(funcString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "===" "${_TEXT_BR_YELLOW}${_TEXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_YELLOW}" "===" "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(funcString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}${_TEXT_BG_GREEN}" "===" "${_TEXT_BR_YELLOW}${_TEXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "$(funcString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BG_CYAN}"   "$(funcString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	funcPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９${_TEXT_BG_RED}０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	funcPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９${_TEXT_BG_RED}０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０${_TEXT_BG_RED}１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	funcPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０${_TEXT_BG_RED}１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"

exit 0
