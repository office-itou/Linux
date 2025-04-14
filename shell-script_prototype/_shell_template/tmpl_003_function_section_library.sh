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

# --- text color test ---------------------------------------------------------
function funcDebug_color() {
	printf "%s : %-22.22s : %s\n" "${_TEXT_RESET}"            "_TEXT_RESET"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BOLD}"             "_TEXT_BOLD"             "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_FAINT}"            "_TEXT_FAINT"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_ITALIC}"           "_TEXT_ITALIC"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_UNDERLINE}"        "_TEXT_UNDERLINE"        "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BLINK}"            "_TEXT_BLINK"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_FAST_BLINK}"       "_TEXT_FAST_BLINK"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_REVERSE}"          "_TEXT_REVERSE"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_CONCEAL}"          "_TEXT_CONCEAL"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_STRIKE}"           "_TEXT_STRIKE"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_GOTHIC}"           "_TEXT_GOTHIC"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_DOUBLE_UNDERLINE}" "_TEXT_DOUBLE_UNDERLINE" "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NORMAL}"           "_TEXT_NORMAL"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_ITALIC}"        "_TEXT_NO_ITALIC"        "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_UNDERLINE}"     "_TEXT_NO_UNDERLINE"     "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_BLINK}"         "_TEXT_NO_BLINK"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_REVERSE}"       "_TEXT_NO_REVERSE"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_CONCEAL}"       "_TEXT_NO_CONCEAL"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_NO_STRIKE}"        "_TEXT_NO_STRIKE"        "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BLACK}"            "_TEXT_BLACK"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_RED}"              "_TEXT_RED"              "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_GREEN}"            "_TEXT_GREEN"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_YELLOW}"           "_TEXT_YELLOW"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BLUE}"             "_TEXT_BLUE"             "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_MAGENTA}"          "_TEXT_MAGENTA"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_CYAN}"             "_TEXT_CYAN"             "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_WHITE}"            "_TEXT_WHITE"            "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_DEFAULT}"          "_TEXT_DEFAULT"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_BLACK}"         "_TEXT_BG_BLACK"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_RED}"           "_TEXT_BG_RED"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_GREEN}"         "_TEXT_BG_GREEN"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_YELLOW}"        "_TEXT_BG_YELLOW"        "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_BLUE}"          "_TEXT_BG_BLUE"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_MAGENTA}"       "_TEXT_BG_MAGENTA"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_CYAN}"          "_TEXT_BG_CYAN"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_WHITE}"         "_TEXT_BG_WHITE"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BG_DEFAULT}"       "_TEXT_BG_DEFAULT"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_BLACK}"         "_TEXT_BR_BLACK"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_RED}"           "_TEXT_BR_RED"           "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_GREEN}"         "_TEXT_BR_GREEN"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_YELLOW}"        "_TEXT_BR_YELLOW"        "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_BLUE}"          "_TEXT_BR_BLUE"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_MAGENTA}"       "_TEXT_BR_MAGENTA"       "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_CYAN}"          "_TEXT_BR_CYAN"          "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_WHITE}"         "_TEXT_BR_WHITE"         "${_TEXT_RESET}"
	printf "%s : %-22.22s : %s\n" "${_TEXT_BR_DEFAULT}"       "_TEXT_BR_DEFAULT"       "${_TEXT_RESET}"
}

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
		return
	fi
	printf "%s\n" "$3"
	diff -y -W "${_SIZE_COLS}" --suppress-common-lines "$1" "$2" || true
}

# --- IPv6 full address -------------------------------------------------------
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
function funcIPv6GetRevAddr() {
	declare -r    _INPT_ADDR="$1"
	echo "${_INPT_ADDR//:/}"                 | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}

# --- IPv4 netmask conversion -------------------------------------------------
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

# --- is numeric --------------------------------------------------------------
function funcIsNumeric() {
	[[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo 0 || echo 1
}

# --- substr ------------------------------------------------------------------
function funcSubstr() {
	echo "${1:${2:-0}:${3:-${#1}}}"
}

# --- string output -----------------------------------------------------------
function funcString() {
	echo "" | IFS= awk '{s=sprintf("%'"$1"'s"," "); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
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

# --- download ----------------------------------------------------------------
function funcCurl() {
	declare -i    _RET_CD=0
	declare -i    I
	declare       _INPT_URL=""
	declare       _OUTP_DIR=""
	declare       _OUTP_FILE=""
	declare       _MSG_FLG=""
	declare -a    _OPT_PRM=()
	declare -a    _ARY_HED=()
	declare       _ERR_MSG=""
	declare       _WEB_SIZ=""
	declare       _WEB_TIM=""
	declare       _WEB_FIL=""
	declare       _LOC_INF=""
	declare       _LOC_SIZ=""
	declare       _LOC_TIM=""
	declare       __TEXT_SIZ=""

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			http://* | https://* )
				_OPT_PRM+=("${1}")
				_INPT_URL="${1}"
				;;
			--output-dir )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUTP_DIR="${1}"
				;;
			--output )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUTP_FILE="${1}"
				;;
			--quiet )
				_MSG_FLG="true"
				;;
			* )
				_OPT_PRM+=("${1}")
				;;
		esac
		shift
	done
	if [[ -z "${_OUTP_FILE}" ]]; then
		_OUTP_FILE="${_INPT_URL##*/}"
	fi
	if ! _ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${_INPT_URL}" 2> /dev/null)"); then
		_RET_CD="$?"
		_ERR_MSG=$(echo "${_ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "${_ERR_MSG} [${_RET_CD}]: ${_INPT_URL}"
		fi
		return "${_RET_CD}"
	fi
	_WEB_SIZ=$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	_WEB_TIM=$(TZ=UTC date -d "$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	_WEB_FIL="${_OUTP_DIR:-.}/${_INPT_URL##*/}"
	if [[ -n "${_OUTP_DIR}" ]] && [[ ! -d "${_OUTP_DIR}/." ]]; then
		mkdir -p "${_OUTP_DIR}"
	fi
	if [[ -n "${_OUTP_FILE}" ]] && [[ -e "${_OUTP_FILE}" ]]; then
		_WEB_FIL="${_OUTP_FILE}"
	fi
	if [[ -n "${_WEB_FIL}" ]] && [[ -e "${_WEB_FIL}" ]]; then
		_LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_WEB_FIL}")
		_LOC_TIM=$(echo "${_LOC_INF}" | awk '{print $6;}')
		_LOC_SIZ=$(echo "${_LOC_INF}" | awk '{print $5;}')
		if [[ "${_WEB_TIM:-0}" -eq "${_LOC_TIM:-0}" ]] && [[ "${_WEB_SIZ:-0}" -eq "${_LOC_SIZ:-0}" ]]; then
			if [[ -z "${_MSG_FLG}" ]]; then
				printf "%s\n" "same    file: ${_WEB_FIL}"
			fi
			return
		fi
	fi

	__TEXT_SIZ="$(funcUnit_conversion "${_WEB_SIZ}")"

	if [[ -z "${_MSG_FLG}" ]]; then
		printf "%s\n" "get     file: ${_WEB_FIL} (${__TEXT_SIZ})"
	fi
	if curl "${_OPT_PRM[@]}"; then
		return $?
	fi

	for ((I=0; I<3; I++))
	do
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "retry  count: ${I}"
		fi
		if curl --continue-at "${_OPT_PRM[@]}"; then
			return "$?"
		else
			_RET_CD="$?"
		fi
	done
	if [[ "${_RET_CD}" -ne 0 ]]; then
		rm -f "${:?}"
	fi
	return "${_RET_CD}"
}

# --- service status ----------------------------------------------------------
function funcServiceStatus() {
	declare -i    _RET_CD=0
	declare       _SRVC_STAT=""
	_SRVC_STAT="$(systemctl "$@" 2> /dev/null || true)"
	_RET_CD="$?"
	case "${_RET_CD}" in
		4) _SRVC_STAT="not-found";;		# no such unit
		*) _SRVC_STAT="${_SRVC_STAT%-*}";;
	esac
	echo "${_SRVC_STAT:-"undefined"}: ${_RET_CD}"

	# systemctl return codes
	#-------+--------------------------------------------------+-------------------------------------#
	# Value | Description in LSB                               | Use in systemd                      #
	#    0  | "program is running or service is OK"            | unit is active                      #
	#    1  | "program is dead and /var/run pid file exists"   | unit not failed (used by is-failed) #
	#    2  | "program is dead and /var/lock lock file exists" | unused                              #
	#    3  | "program is not running"                         | unit is not active                  #
	#    4  | "program or service status is unknown"           | no such unit                        #
	#-------+--------------------------------------------------+-------------------------------------#
}

# --- function is package -----------------------------------------------------
function funcIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}

# ---- function test ----------------------------------------------------------
function funcDebug_function() {
	declare -r    _MSGS_TITL="call function test"
	declare -r    _FILE_WRK1="${_DIRS_TEMP:-/tmp}/testfile1.txt"
	declare -r    _FILE_WRK2="${_DIRS_TEMP:-/tmp}/testfile2.txt"
	declare -r    _TEST_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
	declare -r -a _CURL_OPTN=(               \
		"--location"                         \
		"--progress-bar"                     \
		"--remote-name"                      \
		"--remote-time"                      \
		"--show-error"                       \
		"--fail"                             \
		"--retry-max-time" "3"               \
		"--retry" "3"                        \
		"--create-dirs"                      \
		"--output-dir" "${_DIRS_TEMP:-/tmp}" \
		"${_TEST_ADDR}"                      \
	)
	declare       _TEST_PARM=""
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${_TEXT_GAP1}"
	mkdir -p "${_FILE_WRK1%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK1}"
		line 00
		line 01
		line 02
		line 03
		line 04
		line 05
		line 06
		line 07
		line 08
		line 09
		line 10
_EOT_
	mkdir -p "${_FILE_WRK2%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK2}"
		line 00
		line 01
		line 02
		line 03
		line 04
		line_05
		line 06
		line 07
		line 08
		line 09
		line 10
_EOT_

	# --- text print test -----------------------------------------------------
	funcPrintf "---- text print test ${_TEXT_GAP1}"
	H1=""
	H2=""
	for ((I=1; I<="${_SIZE_COLS}"+10; I++))
	do
		if [[ $((I % 10)) -eq 0 ]]; then
			H1+="         $((I%100/10))"
		fi
		H2+="$((I%10))"
	done
	funcPrintf "${H1}"
	funcPrintf "${H2}"
	# shellcheck disable=SC2312
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(funcString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "$(funcString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BG_CYAN}"   "$(funcString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
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
#	echo ""

	# --- text color test -----------------------------------------------------
	funcPrintf "---- text color test ${_TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcDebug_color"
	funcDebug_color
	echo ""

	# --- printf --------------------------------------------------------------
	funcPrintf "---- printf ${_TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcPrintf"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_RESET}"            "_TEXT_RESET"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BOLD}"             "_TEXT_BOLD"             "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_FAINT}"            "_TEXT_FAINT"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_ITALIC}"           "_TEXT_ITALIC"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_UNDERLINE}"        "_TEXT_UNDERLINE"        "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BLINK}"            "_TEXT_BLINK"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_FAST_BLINK}"       "_TEXT_FAST_BLINK"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_REVERSE}"          "_TEXT_REVERSE"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_CONCEAL}"          "_TEXT_CONCEAL"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_STRIKE}"           "_TEXT_STRIKE"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_GOTHIC}"           "_TEXT_GOTHIC"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_DOUBLE_UNDERLINE}" "_TEXT_DOUBLE_UNDERLINE" "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NORMAL}"           "_TEXT_NORMAL"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_ITALIC}"        "_TEXT_NO_ITALIC"        "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_UNDERLINE}"     "_TEXT_NO_UNDERLINE"     "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_BLINK}"         "_TEXT_NO_BLINK"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_REVERSE}"       "_TEXT_NO_REVERSE"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_CONCEAL}"       "_TEXT_NO_CONCEAL"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_NO_STRIKE}"        "_TEXT_NO_STRIKE"        "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BLACK}"            "_TEXT_BLACK"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_RED}"              "_TEXT_RED"              "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_GREEN}"            "_TEXT_GREEN"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_YELLOW}"           "_TEXT_YELLOW"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BLUE}"             "_TEXT_BLUE"             "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_MAGENTA}"          "_TEXT_MAGENTA"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_CYAN}"             "_TEXT_CYAN"             "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_WHITE}"            "_TEXT_WHITE"            "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_DEFAULT}"          "_TEXT_DEFAULT"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_BLACK}"         "_TEXT_BG_BLACK"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_RED}"           "_TEXT_BG_RED"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_GREEN}"         "_TEXT_BG_GREEN"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_YELLOW}"        "_TEXT_BG_YELLOW"        "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_BLUE}"          "_TEXT_BG_BLUE"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_MAGENTA}"       "_TEXT_BG_MAGENTA"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_CYAN}"          "_TEXT_BG_CYAN"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_WHITE}"         "_TEXT_BG_WHITE"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BG_DEFAULT}"       "_TEXT_BG_DEFAULT"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_BLACK}"         "_TEXT_BR_BLACK"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_RED}"           "_TEXT_BR_RED"           "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_GREEN}"         "_TEXT_BR_GREEN"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_YELLOW}"        "_TEXT_BR_YELLOW"        "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_BLUE}"          "_TEXT_BR_BLUE"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_MAGENTA}"       "_TEXT_BR_MAGENTA"       "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_CYAN}"          "_TEXT_BR_CYAN"          "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_WHITE}"         "_TEXT_BR_WHITE"         "${_TEXT_RESET}"
	funcPrintf "%s : %-22.22s : %s" "${_TEXT_BR_DEFAULT}"       "_TEXT_BR_DEFAULT"       "${_TEXT_RESET}"
	echo ""

	# --- diff ----------------------------------------------------------------
	funcPrintf "---- diff ${_TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcDiff \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	funcDiff "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" "function test"
	funcPrintf "--no-cutting" "diff -y -W \"${_SIZE_COLS}\" --suppress-common-lines \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${_SIZE_COLS}" --suppress-common-lines "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff -y -W \"${_SIZE_COLS}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${_SIZE_COLS}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff --color=always -y -W \"${_SIZE_COLS}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff --color=always -y -W "${_SIZE_COLS}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	echo ""

	# --- substr --------------------------------------------------------------
	funcPrintf "---- substr ${_TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcSubstr \"${_TEST_PARM}\" 1 19"
	funcPrintf "--no-cutting" "         1         2         3         4"
	funcPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	funcPrintf "--no-cutting" "${_TEST_PARM}"
	funcSubstr "${_TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	funcPrintf "---- service status ${_TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcServiceStatus \"sshd.service\""
	funcServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	funcPrintf "---- IPv6 full address ${_TEXT_GAP1}"
	_TEST_PARM="fe80::1"
	funcPrintf "--no-cutting" "funcIPv6GetFullAddr \"${_TEST_PARM}\""
	funcIPv6GetFullAddr "${_TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	funcPrintf "---- IPv6 reverse address ${_TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcIPv6GetRevAddr \"${_TEST_PARM}\""
	funcIPv6GetRevAddr "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	funcPrintf "---- IPv4 netmask conversion ${_TEXT_GAP1}"
	_TEST_PARM="24"
	funcPrintf "--no-cutting" "funcIPv4GetNetmask \"${_TEST_PARM}\""
	funcIPv4GetNetmask "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	funcPrintf "---- IPv4 cidr conversion ${_TEXT_GAP1}"
	_TEST_PARM="255.255.255.0"
	funcPrintf "--no-cutting" "funcIPv4GetNetCIDR \"${_TEST_PARM}\""
	funcIPv4GetNetCIDR "${_TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	funcPrintf "---- is numeric ${_TEXT_GAP1}"
	_TEST_PARM="123.456"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""
	_TEST_PARM="abc.def"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	funcPrintf "---- string output ${_TEXT_GAP1}"
	_TEST_PARM="50"
	funcPrintf "--no-cutting" "funcString \"${_TEST_PARM}\" \"#\""
	funcString "${_TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	funcPrintf "---- print with screen control ${_TEXT_GAP1}"
	_TEST_PARM="test"
	funcPrintf "--no-cutting" "funcPrintf \"${_TEST_PARM}\""
	funcPrintf "${_TEST_PARM}"
	echo ""

	# --- unit conversion -----------------------------------------------------
	for _TEST_PARM in \
		"bad"         \
		"1"           \
		"123"         \
		"1234"        \
		"123456"      \
		"1234567"     \
		"12345678"
	do
		funcUnit_conversion "${_TEST_PARM}"
		echo ""
	done

	# --- download ------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		funcPrintf "---- download ${_TEXT_GAP1}"
		funcPrintf "--no-cutting" "funcCurl ${_CURL_OPTN[*]}"
		funcCurl "${_CURL_OPTN[@]}"
		echo ""
	fi

	# -------------------------------------------------------------------------
	rm -f "${_FILE_WRK1}" "${_FILE_WRK2}"
	ls -l "${_DIRS_TEMP:-/tmp}"
}
