# --- service status ----------------------------------------------------------
function fnServiceStatus() {
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
function fnIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed' || true
}

# --- diff --------------------------------------------------------------------
function fnDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
		return
	fi
	printf "%s\n" "$3"
	diff -y -W "${_SIZE_COLS}" --suppress-common-lines "$1" "$2" || true
}

# --- download ----------------------------------------------------------------
#function fnCurl() {
#	declare -i    _RET_CD=0
#	declare -i    I
#	declare       _INPT_URL=""
#	declare       _OUTP_DIR=""
#	declare       _OUTP_FILE=""
#	declare       _MSG_FLG=""
#	declare -a    _OPT_PRM=()
#	declare -a    _ARY_HED=()
#	declare       _ERR_MSG=""
#	declare       _WEB_SIZ=""
#	declare       _WEB_TIM=""
#	declare       _WEB_FIL=""
#	declare       _LOC_INF=""
#	declare       _LOC_SIZ=""
#	declare       _LOC_TIM=""
#	declare       __TEXT_SIZ=""
#
#	while [[ -n "${1:-}" ]]
#	do
#		case "${1:-}" in
#			http://* | https://* )
#				_OPT_PRM+=("${1}")
#				_INPT_URL="${1}"
#				;;
#			--output-dir )
#				_OPT_PRM+=("${1}")
#				shift
#				_OPT_PRM+=("${1}")
#				_OUTP_DIR="${1}"
#				;;
#			--output )
#				_OPT_PRM+=("${1}")
#				shift
#				_OPT_PRM+=("${1}")
#				_OUTP_FILE="${1}"
#				;;
#			--quiet )
#				_MSG_FLG="true"
#				;;
#			* )
#				_OPT_PRM+=("${1}")
#				;;
#		esac
#		shift
#	done
#	if [[ -z "${_OUTP_FILE}" ]]; then
#		_OUTP_FILE="${_INPT_URL##*/}"
#	fi
#	if ! _ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${_INPT_URL}" 2> /dev/null)"); then
#		_RET_CD="$?"
#		_ERR_MSG=$(echo "${_ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g' || true)
#		if [[ -z "${_MSG_FLG}" ]]; then
#			printf "%s\n" "${_ERR_MSG} [${_RET_CD}]: ${_INPT_URL}"
#		fi
#		return "${_RET_CD}"
#	fi
#	_WEB_SIZ=$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p' || true)
#	# shellcheck disable=SC2312
#	_WEB_TIM=$(TZ=UTC date -d "$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
#	_WEB_FIL="${_OUTP_DIR:-.}/${_INPT_URL##*/}"
#	if [[ -n "${_OUTP_DIR}" ]] && [[ ! -d "${_OUTP_DIR}/." ]]; then
#		mkdir -p "${_OUTP_DIR}"
#	fi
#	if [[ -n "${_OUTP_FILE}" ]] && [[ -e "${_OUTP_FILE}" ]]; then
#		_WEB_FIL="${_OUTP_FILE}"
#	fi
#	if [[ -n "${_WEB_FIL}" ]] && [[ -e "${_WEB_FIL}" ]]; then
#		_LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_WEB_FIL}")
#		_LOC_TIM=$(echo "${_LOC_INF}" | awk '{print $6;}')
#		_LOC_SIZ=$(echo "${_LOC_INF}" | awk '{print $5;}')
#		if [[ "${_WEB_TIM:-0}" -eq "${_LOC_TIM:-0}" ]] && [[ "${_WEB_SIZ:-0}" -eq "${_LOC_SIZ:-0}" ]]; then
#			if [[ -z "${_MSG_FLG}" ]]; then
#				printf "%s\n" "same    file: ${_WEB_FIL}"
#			fi
#			return
#		fi
#	fi
#
#	fnUnit_conversion "__TEXT_SIZ" "${_WEB_SIZ}"
#
#	if [[ -z "${_MSG_FLG}" ]]; then
#		printf "%s\n" "get     file: ${_WEB_FIL} (${__TEXT_SIZ})"
#	fi
#	if curl "${_OPT_PRM[@]}"; then
#		return $?
#	fi
#
#	for ((I=0; I<3; I++))
#	do
#		if [[ -z "${_MSG_FLG}" ]]; then
#			printf "%s\n" "retry  count: ${I}"
#		fi
#		if curl --continue-at "${_OPT_PRM[@]}"; then
#			return "$?"
#		else
#			_RET_CD="$?"
#		fi
#	done
#	if [[ "${_RET_CD}" -ne 0 ]]; then
#		rm -f "${:?}"
#	fi
#	return "${_RET_CD}"
#}

# --- text color test ---------------------------------------------------------
# shellcheck disable=SC2154
function fnDebug_color() {
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

# ---- function test ----------------------------------------------------------
function fnDebug_function() {
	declare -r    _MSGS_TITL="call function test"
	declare -r    _FILE_WRK1="${_DIRS_TEMP:-/tmp}/testfile1.txt"
	declare -r    _FILE_WRK2="${_DIRS_TEMP:-/tmp}/testfile2.txt"
	declare -r    _TEST_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
#	declare -r -a _CURL_OPTN=(               \
#		"--location"                         \
#		"--progress-bar"                     \
#		"--remote-name"                      \
#		"--remote-time"                      \
#		"--show-error"                       \
#		"--fail"                             \
#		"--retry-max-time" "3"               \
#		"--retry" "3"                        \
#		"--create-dirs"                      \
#		"--output-dir" "${_DIRS_TEMP:-/tmp}" \
#		"${_TEST_ADDR}"                      \
#	)
	declare       _TEST_PARM=""
	declare       _RETN_VALU=""
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	fnPrintf "---- ${_MSGS_TITL} ${_TEXT_GAP1}"
	mkdir -p "${_FILE_WRK1%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK1}" || true
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK2}" || true
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
	fnPrintf "---- text print test ${_TEXT_GAP1}"
	H1=""
	H2=""
	for ((I=1; I<="${_SIZE_COLS}"+10; I++))
	do
		if [[ $((I % 10)) -eq 0 ]]; then
			H1+="         $((I%100/10))"
		fi
		H2+="$((I%10))"
	done
	fnPrintf "${H1}"
	fnPrintf "${H2}"
	# shellcheck disable=SC2312
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(fnString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "$(fnString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BG_CYAN}"   "$(fnString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(fnString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "===" "${_TEXT_BR_YELLOW}${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BG_YELLOW}" "===" "${_TEXT_RESET}${_TEXT_BG_GREEN}"  "$(fnString "${_SIZE_COLS}" '->')" "${_TEXT_RESET}${_TEXT_BG_GREEN}" "===" "${_TEXT_BR_YELLOW}${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_YELLOW}" "$(fnString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	# shellcheck disable=SC2312
	fnPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BG_CYAN}"   "$(fnString "${_SIZE_COLS}" '→')" "${_TEXT_RESET}"
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	fnPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９${_TEXT_BG_RED}０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	fnPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９${_TEXT_BG_RED}０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	fnPrintf  "%s%s%s"  "${_TEXT_RESET}${_TEXT_BR_GREEN}"  "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０${_TEXT_BG_RED}１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
	fnPrintf "_%s%s%s_" "${_TEXT_RESET}${_TEXT_BR_CYAN}"   "１２３４５６７８９０${_TEXT_BR_RED}１２３４５６７８９０${_TEXT_BR_BLUE}１２３４５６７８９０${_TEXT_RESET}１２３４５６７８９０${_TEXT_UNDERLINE}${_TEXT_BR_MAGENTA}１２３４５６７８９０${_TEXT_RESET}１２３４５${_TEXT_BG_YELLOW}６７８９０${_TEXT_BG_RED}１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０" "${_TEXT_RESET}"
#	echo ""

	# --- text color test -----------------------------------------------------
	fnPrintf "---- text color test ${_TEXT_GAP1}"
	fnPrintf "--no-cutting" "fnDebug_color"
	fnDebug_color
	echo ""

	# --- printf --------------------------------------------------------------
	fnPrintf "---- printf ${_TEXT_GAP1}"
	fnPrintf "--no-cutting" "fnPrintf"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_RESET}"            "_TEXT_RESET"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BOLD}"             "_TEXT_BOLD"             "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_FAINT}"            "_TEXT_FAINT"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_ITALIC}"           "_TEXT_ITALIC"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_UNDERLINE}"        "_TEXT_UNDERLINE"        "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BLINK}"            "_TEXT_BLINK"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_FAST_BLINK}"       "_TEXT_FAST_BLINK"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_REVERSE}"          "_TEXT_REVERSE"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_CONCEAL}"          "_TEXT_CONCEAL"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_STRIKE}"           "_TEXT_STRIKE"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_GOTHIC}"           "_TEXT_GOTHIC"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_DOUBLE_UNDERLINE}" "_TEXT_DOUBLE_UNDERLINE" "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NORMAL}"           "_TEXT_NORMAL"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_ITALIC}"        "_TEXT_NO_ITALIC"        "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_UNDERLINE}"     "_TEXT_NO_UNDERLINE"     "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_BLINK}"         "_TEXT_NO_BLINK"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_REVERSE}"       "_TEXT_NO_REVERSE"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_CONCEAL}"       "_TEXT_NO_CONCEAL"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_NO_STRIKE}"        "_TEXT_NO_STRIKE"        "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BLACK}"            "_TEXT_BLACK"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_RED}"              "_TEXT_RED"              "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_GREEN}"            "_TEXT_GREEN"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_YELLOW}"           "_TEXT_YELLOW"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BLUE}"             "_TEXT_BLUE"             "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_MAGENTA}"          "_TEXT_MAGENTA"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_CYAN}"             "_TEXT_CYAN"             "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_WHITE}"            "_TEXT_WHITE"            "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_DEFAULT}"          "_TEXT_DEFAULT"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_BLACK}"         "_TEXT_BG_BLACK"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_RED}"           "_TEXT_BG_RED"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_GREEN}"         "_TEXT_BG_GREEN"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_YELLOW}"        "_TEXT_BG_YELLOW"        "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_BLUE}"          "_TEXT_BG_BLUE"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_MAGENTA}"       "_TEXT_BG_MAGENTA"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_CYAN}"          "_TEXT_BG_CYAN"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_WHITE}"         "_TEXT_BG_WHITE"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BG_DEFAULT}"       "_TEXT_BG_DEFAULT"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_BLACK}"         "_TEXT_BR_BLACK"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_RED}"           "_TEXT_BR_RED"           "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_GREEN}"         "_TEXT_BR_GREEN"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_YELLOW}"        "_TEXT_BR_YELLOW"        "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_BLUE}"          "_TEXT_BR_BLUE"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_MAGENTA}"       "_TEXT_BR_MAGENTA"       "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_CYAN}"          "_TEXT_BR_CYAN"          "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_WHITE}"         "_TEXT_BR_WHITE"         "${_TEXT_RESET}"
	fnPrintf "%s : %-22.22s : %s" "${_TEXT_BR_DEFAULT}"       "_TEXT_BR_DEFAULT"       "${_TEXT_RESET}"
	echo ""

	# --- diff ----------------------------------------------------------------
	fnPrintf "---- diff ${_TEXT_GAP1}"
	fnPrintf "--no-cutting" "fnDiff \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	fnDiff "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" "function test"
	fnPrintf "--no-cutting" "diff -y -W \"${_SIZE_COLS}\" --suppress-common-lines \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${_SIZE_COLS}" --suppress-common-lines "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	fnPrintf "--no-cutting" "diff -y -W \"${_SIZE_COLS}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${_SIZE_COLS}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	fnPrintf "--no-cutting" "diff --color=always -y -W \"${_SIZE_COLS}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff --color=always -y -W "${_SIZE_COLS}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	echo ""

	# --- substr --------------------------------------------------------------
	fnPrintf "---- substr ${_TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	fnPrintf "--no-cutting" "fnSubstr \"${_TEST_PARM}\" 1 19"
	fnPrintf "--no-cutting" "         1         2         3         4"
	fnPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	fnPrintf "--no-cutting" "${_TEST_PARM}"
	fnSubstr "${_TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	fnPrintf "---- service status ${_TEXT_GAP1}"
	fnPrintf "--no-cutting" "fnServiceStatus \"sshd.service\""
	fnServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	fnPrintf "---- IPv6 full address ${_TEXT_GAP1}"
	_TEST_PARM="fe80::1"
	fnPrintf "--no-cutting" "fnIPv6GetFullAddr \"${_TEST_PARM}\""
	fnIPv6GetFullAddr "${_TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	fnPrintf "---- IPv6 reverse address ${_TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	fnPrintf "--no-cutting" "fnIPv6GetRevAddr \"${_TEST_PARM}\""
	fnIPv6GetRevAddr "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	fnPrintf "---- IPv4 netmask conversion ${_TEXT_GAP1}"
	_TEST_PARM="24"
	fnPrintf "--no-cutting" "fnIPv4GetNetmask \"${_TEST_PARM}\""
	fnIPv4GetNetmask "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	fnPrintf "---- IPv4 cidr conversion ${_TEXT_GAP1}"
	_TEST_PARM="255.255.255.0"
	fnPrintf "--no-cutting" "fnIPv4GetNetmask \"${_TEST_PARM}\""
	fnIPv4GetNetmask "${_TEST_PARM}"
#	fnPrintf "--no-cutting" "fnIPv4GetNetCIDR \"${_TEST_PARM}\""
#	fnIPv4GetNetCIDR "${_TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	fnPrintf "---- is numeric ${_TEXT_GAP1}"
	_TEST_PARM="123.456"
	fnPrintf "--no-cutting" "fnIsNumeric \"${_TEST_PARM}\""
	fnIsNumeric "${_TEST_PARM}"
	echo ""
	_TEST_PARM="abc.def"
	fnPrintf "--no-cutting" "fnIsNumeric \"${_TEST_PARM}\""
	fnIsNumeric "${_TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	fnPrintf "---- string output ${_TEXT_GAP1}"
	_TEST_PARM="50"
	fnPrintf "--no-cutting" "fnString \"${_TEST_PARM}\" \"#\""
	fnString "${_TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	fnPrintf "---- print with screen control ${_TEXT_GAP1}"
	_TEST_PARM="test"
	fnPrintf "--no-cutting" "fnPrintf \"${_TEST_PARM}\""
	fnPrintf "${_TEST_PARM}"
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
		fnUnit_conversion "_RETN_VALU" "${_TEST_PARM}"
		echo "${_RETN_VALU}"
	done

	# --- download ------------------------------------------------------------
	fnPrintf "---- download ${_TEXT_GAP1}"
	_PATH="${_DIRS_TEMP:-/tmp}/download/${_TEST_ADDR##*/}"
	fnPrintf "--no-cutting" "fnGetWeb_contents \"${_PATH}\" \"${_TEST_ADDR:?}\""
	fnGetWeb_contents "${_PATH}" "${_TEST_ADDR}"
	LANG=C find "${_PATH%/*}" -name "${_PATH##*/}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s"
	echo ""
#	# shellcheck disable=SC2091,SC2310
#	if $(fnIsPackage 'curl'); then
#		fnPrintf "---- download ${_TEXT_GAP1}"
#		fnPrintf "--no-cutting" "fnCurl ${_CURL_OPTN[*]}"
#		fnCurl "${_CURL_OPTN[@]}"
#		echo ""
#	fi

	# -------------------------------------------------------------------------
	rm -f "${_FILE_WRK1}" "${_FILE_WRK2}"
	ls -l "${_DIRS_TEMP:-/tmp}"
}
