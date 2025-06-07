# shellcheck disable=SC2148
# *** function section (common functions) *************************************

# === <common> ================================================================

	# --- set minimum display size --------------------------------------------
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
	              _TEXT_SPCE="$(printf "%${_SIZE_COLS:-80}s" "")"
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

# -----------------------------------------------------------------------------
# descript: debug print
#   input :   $@   : input value
#   output: stderr : output
#   return:        : unused
# shellcheck disable=SC2317
function fnDebugout() {
	if [[ -z "${_DBGS_FLAG:-}" ]]; then
		return
	fi
	printf "${FUNCNAME[1]}: %q\n" "${@:-}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :        : unused
#   output: stderr : output
#   return:        : unused
# shellcheck disable=SC2317
function fnDebug_parameter_list() {
	if [[ -z "${_DBGS_FLAG:-}" ]]; then
		return
	fi
	printf "${FUNCNAME[1]}: %q\n" "${!__@}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: is numeric
#   input :   $1   : input value
#   output: stdout :             : =0 (numer)
#     "   :        :             : !0 (not number)
#   return:        : unused
# shellcheck disable=SC2317
function fnIsNumeric() {
	[[ ${1:?} =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo -n "0" || echo -n "1"
}

# -----------------------------------------------------------------------------
# descript: substr
#   input :   $1   : input value
#   input :   $2   : starting position
#   input :   $3   : number of characters
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnSubstr() {
	echo -n "${1:$((${2:-1}-1)):${3:-${#1}}}"
}

# -----------------------------------------------------------------------------
# descript: string output
#   input :   $1   : number of characters
#   input :   $2   : output character
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnString() {
	echo "" | IFS= awk '{s=sprintf("%'"${1:?}"'s",""); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
}

# -----------------------------------------------------------------------------
# descript: ltrim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnLtrim() {
	echo -n "${1#"${1%%[!"${IFS}"]*}"}"	# ltrim
}

# -----------------------------------------------------------------------------
# descript: rtrim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnRtrim() {
	echo -n "${1%"${1##*[!"${IFS}"]}"}"	# rtrim
}

# -----------------------------------------------------------------------------
# descript: trim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnTrim() {
	declare       __WORK=""
	__WORK="$(fnLtrim "$1")"
	fnRtrim "${__WORK}"
}

# -----------------------------------------------------------------------------
# descript: date diff
#   input :   $1   : date 1
#   input :   $2   : date 2
#   output: stdout :        :   0 ($1 = $2)
#     "   :        :        :   1 ($1 < $2)
#     "   :        :        :  -1 ($1 > $2)
#     "   :        :        : emp (error)
#   return:        : status
# shellcheck disable=SC2317
function fnDateDiff() {
	declare       __TGET_DAT1="${1:?}"	# date1
	declare       __TGET_DAT2="${2:?}"	# date2
	declare -i    __RTCD=0				# return code

	if ! __TGET_DAT1="$(TZ=UTC date -d "${__TGET_DAT1//%20/ }" "+%s")"; then
		__RTCD="$?"
		printf "%20.20s: %s\n" "failed" "${__TGET_DAT1}"
		exit "${__RTCD}"
	fi
	if ! __TGET_DAT2="$(TZ=UTC date -d "${__TGET_DAT2//%20/ }" "+%s")"; then
		__RTCD="$?"
		printf "%20.20s: %s\n" "failed" "${__TGET_DAT2}"
		exit "${__RTCD}"
	fi
	  if [[ "${__TGET_DAT1}" -eq "${__TGET_DAT2}" ]]; then echo -n "0"
	elif [[ "${__TGET_DAT1}" -lt "${__TGET_DAT2}" ]]; then echo -n "1"
	elif [[ "${__TGET_DAT1}" -gt "${__TGET_DAT2}" ]]; then echo -n "-1"
	else                                                   echo -n ""
	fi
}

# -----------------------------------------------------------------------------
# descript: print with centering
#   input :   $1   : print width
#   input :   $2   : input value
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnCenter() {
	declare       __TEXT=""				# trimmed string
	declare -i    __LEFT=0				# count of space on left
	declare -i    __RIGT=0				# count of space on right

	__TEXT="$(fnTrim "${2:-}")"
	__LEFT=$(((${1:?} - "${#__TEXT}") / 2))
	__RIGT=$((${1:?} - "${__LEFT}" - "${#__TEXT}"))
	printf "%${__LEFT}s%-s%${__RIGT}s" "" "${__TEXT}" ""
}

# -----------------------------------------------------------------------------
# descript: print with screen control
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnPrintf() {
	declare -r    __TRCE="$(set -o | grep -E "^xtrace\s*on$")"
	set +x
	# -------------------------------------------------------------------------
	declare       __NCUT=""				# no cutting flag
	declare       __FMAT=""				# format parameter
	declare       __UTF8=""				# formatted utf8
	declare       __SJIS=""				# formatted sjis (cp932)
	declare       __PLIN=""				# formatted string without attributes
	declare       __ESCF=""				# escape characters front
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	# https://www.tohoho-web.com/ex/dash-tilde.html
	# -------------------------------------------------------------------------
	case "${1:?}" in
		--no-cutting) __NCUT="true"; shift;;
		*           ) ;;
	esac
	# -------------------------------------------------------------------------
	__FMAT="${1}"
	shift
	# shellcheck disable=SC2059
	printf -v __UTF8 -- "${__FMAT}" "${@:-}"
	# -------------------------------------------------------------------------
	if [[ -z "${__NCUT}" ]]; then
		__SJIS="$(echo -n "${__UTF8}" | iconv -f UTF-8 -t CP932 -c -s || true)"
		__PLIN="${__SJIS//"${_CODE_ESCP}["[0-9]m/}"
		__PLIN="${__PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
		__PLIN="${__PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
		if [[ "${#__PLIN}" -gt "${_SIZE_COLS}" ]]; then
			__WORK="${__SJIS}"
			while true
			do
				case "${__WORK}" in
					"${_CODE_ESCP}"\[[0-9]*m*)
						__WORK="${__WORK/#"${_CODE_ESCP}["[0-9]m/}"
						__WORK="${__WORK/#"${_CODE_ESCP}["[0-9][0-9]m/}"
						__WORK="${__WORK/#"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
						;;
					*) break;;
				esac
			done
			__ESCF="${__SJIS%"${__WORK}"}"
			# -----------------------------------------------------------------
			__WORK="${__SJIS:"${#__ESCF}":"${_SIZE_COLS}"}"
			while true
			do
				__PLIN="${__WORK//"${_CODE_ESCP}["[0-9]m/}"
				__PLIN="${__PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
				__PLIN="${__PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
				__PLIN="${__PLIN%%"${_CODE_ESCP}"*}"
				if [[ "${#__PLIN}" -eq "${_SIZE_COLS}" ]]; then
					break
				fi
				__WORK="${__SJIS:"${#__ESCF}":$(("${#__WORK}"+"${_SIZE_COLS}"-"${#__PLIN}"))}"
			done
			__WORK="${__ESCF}${__WORK}"
			__UTF8="$(echo -n "${__WORK}" | iconv -f CP932 -t UTF-8 -c -s 2> /dev/null || true)"
		fi
	fi
	printf "%s%b%s\n" "${_TEXT_RESET}" "${__UTF8}" "${_TEXT_RESET}"
	if [[ -n "${__TRCE}" ]]; then
		set -x
	else
		set +x
	fi
}
