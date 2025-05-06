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

# --- is numeric --------------------------------------------------------------
#function funcIsNumeric() {
#	[[ ${1:?} =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo 0 || echo 1
#}

# --- substr ------------------------------------------------------------------
#function funcSubstr() {
#	echo "${1:${2:-0}:${3:-${#1}}}"
#}

# --- string output -----------------------------------------------------------
# shellcheck disable=SC2317
function funcString() {
#	printf "%${1:-"${_SIZE_COLS}"}s" "" | tr ' ' "${2:- }"
	echo "" | IFS= awk '{s=sprintf("%'"$1"'s"," "); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
}

# --- date diff ---------------------------------------------------------------
# shellcheck disable=SC2317
function funcDateDiff() {
	declare       _DAT1="${1:?}"		# date1
	declare       _DAT2="${2:?}"		# date2
	# -------------------------------------------------------------------------
	#  0 : _DAT1 = _DAT2
	#  1 : _DAT1 < _DAT2
	# -1 : _DAT1 > _DAT2
	# emp: error
	_DAT1="$(TZ=UTC date -d "${_DAT1//%20/ }" "+%s" || exit $?)"
	_DAT2="$(TZ=UTC date -d "${_DAT2//%20/ }" "+%s" || exit $?)"
	  if [[ "${_DAT1}" -eq "${_DAT2}" ]]; then
		echo "0"
	elif [[ "${_DAT1}" -lt "${_DAT2}" ]]; then
		echo "1"
	elif [[ "${_DAT1}" -gt "${_DAT2}" ]]; then
		echo "-1"
	else
		echo ""
	fi
}

# --- print with screen control -----------------------------------------------
# shellcheck disable=SC2317
function funcPrintf() {
	declare -r    _TRCE="$(set -o | grep "^xtrace\s*on$")"
	set +x
	# -------------------------------------------------------------------------
	declare       _NCUT=""				# no cutting flag
	declare       _FMAT=""				# format parameter
	declare       _UTF8=""				# formatted utf8
	declare       _SJIS=""				# formatted sjis (cp932)
	declare       _PLIN=""				# formatted string without attributes
	declare       _ESCF=""				# escape characters front
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	# https://www.tohoho-web.com/ex/dash-tilde.html
	# -------------------------------------------------------------------------
	case "${1:?}" in
		--no-cutting) _NCUT="true"; shift;;
		*           ) ;;
	esac
	# -------------------------------------------------------------------------
	_FMAT="${1}"
	shift
	# shellcheck disable=SC2059
	printf -v _UTF8 -- "${_FMAT}" "${@:-}"
	# -------------------------------------------------------------------------
	if [[ -z "${_NCUT}" ]]; then
		_SJIS="$(echo -n "${_UTF8}" | iconv -f UTF-8 -t CP932 -c -s || true)"
		_PLIN="${_SJIS//"${_CODE_ESCP}["[0-9]m/}"
		_PLIN="${_PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
		_PLIN="${_PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
		if [[ "${#_PLIN}" -gt "${_SIZE_COLS}" ]]; then
			_WORK="${_SJIS}"
			while true
			do
				case "${_WORK}" in
					"${_CODE_ESCP}"\[[0-9]*m*)
						_WORK="${_WORK/#"${_CODE_ESCP}["[0-9]m/}"
						_WORK="${_WORK/#"${_CODE_ESCP}["[0-9][0-9]m/}"
						_WORK="${_WORK/#"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
						;;
					*) break;;
				esac
			done
			_ESCF="${_SJIS%"${_WORK}"}"
			# -----------------------------------------------------------------
			_WORK="${_SJIS:"${#_ESCF}":"${_SIZE_COLS}"}"
			while true
			do
				_PLIN="${_WORK//"${_CODE_ESCP}["[0-9]m/}"
				_PLIN="${_PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
				_PLIN="${_PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
				_PLIN="${_PLIN%%"${_CODE_ESCP}"*}"
				if [[ "${#_PLIN}" -eq "${_SIZE_COLS}" ]]; then
					break
				fi
				_WORK="${_SJIS:"${#_ESCF}":$(("${#_WORK}"+"${_SIZE_COLS}"-"${#_PLIN}"))}"
			done
			_WORK="${_ESCF}${_WORK}"
			_UTF8="$(echo -n "${_WORK}" | iconv -f CP932 -t UTF-8 -c -s 2> /dev/null || true)"
		fi
	fi
	printf "%s%b%s\n" "${_TEXT_RESET}" "${_UTF8}" "${_TEXT_RESET}"
	if [[ -n "${_TRCE}" ]]; then
		set -x
	else
		set +x
	fi
}
