# *** function section (common functions) *************************************

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

# --- print with screen control -----------------------------------------------
# shellcheck disable=SC2317
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
			_TEXT_WORK="${_TEXT_SJIS:"${#_ESCP_FRNT}":"${_SIZE_COLS}"}"
			while true
			do
				_TEXT_PLIN="${_TEXT_WORK//"${_CODE_ESCP}["[0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN//"${_CODE_ESCP}["[0-9][0-9][0-9]m/}"
				_TEXT_PLIN="${_TEXT_PLIN%%"${_CODE_ESCP}"*}"
				if [[ "${#_TEXT_PLIN}" -eq "${_SIZE_COLS}" ]]; then
					break
				fi
				_TEXT_WORK="${_TEXT_SJIS:"${#_ESCP_FRNT}":$(("${#_TEXT_WORK}"+"${_SIZE_COLS}"-"${#_TEXT_PLIN}"))}"
			done
			_TEXT_WORK="${_ESCP_FRNT}${_TEXT_WORK}"
			_TEXT_UTF8="$(echo -n "${_TEXT_WORK}" | iconv -f CP932 -t UTF-8 -c -s 2> /dev/null || true)"
		fi
	fi
	printf "%s%b%s\n" "${_TEXT_RESET}" "${_TEXT_UTF8}" "${_TEXT_RESET}"
	if [[ -n "${_FLAG_TRCE:-}" ]]; then
		set -x
	else
		set +x
	fi
}

# --- unit conversion ---------------------------------------------------------
# shellcheck disable=SC2317
function funcUnit_conversion() {
	declare -r -a _TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC_UNIT=0
	declare       _WORK_TEXT=""
	declare -i    I=0
	# --- is numeric ----------------------------------------------------------
	if [[ ! ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		printf "%'s Byte" "?"
		return
	fi
	# --- Byte ----------------------------------------------------------------
	if [[ "$1" -lt 1024 ]]; then
		printf "%'d Byte" "$1"
		return
	fi
	# --- numfmt --------------------------------------------------------------
	if command -v numfmt > /dev/null 2>&1; then
		echo -n "$1" | numfmt --to=iec-i --suffix=B
		return
	fi
	# --- calculate -----------------------------------------------------------
	for ((I=3; I>0; I--))
	do
		_CALC_UNIT=$((1024**I))
		if [[ "$1" -ge "${_CALC_UNIT}" ]]; then
			_WORK_TEXT="$(echo "$1" "${_CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')"
			printf "%s %s" "${_WORK_TEXT}" "${_TEXT_UNIT[I]}"
			return
		fi
	done
	echo -n "$1"
}

# --- IPv4 netmask conversion -------------------------------------------------
# shellcheck disable=SC2317
function funcIPv4GetNetmask() {
	declare -r    _INPT_ADDR="$1"
	declare -i    _LOOP=$((32-_INPT_ADDR))
	declare -i    _WORK=1
	declare       _DEC_ADDR=""
	while [[ "${_LOOP}" -gt 0 ]]
	do
		_LOOP=$((_LOOP-1))
		_WORK=$((_WORK*2))
	done
	_DEC_ADDR="$((0xFFFFFFFF ^ (_WORK-1)))"
	printf '%d.%d.%d.%d'              \
	    $(( _DEC_ADDR >> 24        )) \
	    $(((_DEC_ADDR >> 16) & 0xFF)) \
	    $(((_DEC_ADDR >>  8) & 0xFF)) \
	    $(( _DEC_ADDR        & 0xFF))
}

# --- IPv4 cidr conversion ----------------------------------------------------
# shellcheck disable=SC2317
function funcIPv4GetNetCIDR() {
	declare -r    _INPT_ADDR="$1"
	declare -a    _OCTETS=()
	declare -i    _MASK=0
	echo "${_INPT_ADDR}" | \
	    awk -F '.' '{
	        split($0, _OCTETS);
	        for (I in _OCTETS) {
	            _MASK += 8 - log(2^8 - _OCTETS[I])/log(2);
	        }
	        print _MASK
	    }'
}

# --- IPv6 full address -------------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetFullAddr() {
	declare       _INPT_ADDR="$1"
	declare -r    _INPT_FSEP="${_INPT_ADDR//[^:]/}"
	declare -r -i _CONT_FSEP=$((7-${#_INPT_FSEP}))
	declare       _OUTP_TEMP=""
	_OUTP_TEMP="$(printf "%${_CONT_FSEP}s" "")"
	_INPT_ADDR="${_INPT_ADDR/::/::${_OUTP_TEMP// /:}}"
	IFS= mapfile -d ':' -t _OUTP_ARRY < <(echo -n "${_INPT_ADDR/%:/::}")
	printf ':%04x' "${_OUTP_ARRY[@]/#/0x0}" | cut -c 2-
}

# --- IPv6 reverse address ----------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetRevAddr() {
	declare -r    _INPT_ADDR="$1"
	echo "${_INPT_ADDR//:/}"                 | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}
