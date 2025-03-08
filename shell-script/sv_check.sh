#!/bin/bash
###############################################################################
##
##	post-installation test shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/02/16
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/02/16 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		-dbgprt) _DBGPRT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	# --- work variables ------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

	# --- set minimum display size --------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25
	declare       TEXT_GAP1=""
	declare       TEXT_GAP2=""

# *** function section (common functions) *************************************

# --- set color ---------------------------------------------------------------
#	declare -r    ESC="$(printf '\033')"
	declare -r    ESC=$'\033'
	declare -r    TXT_RESET="${ESC}[m"						# reset all attributes
	declare -r    TXT_ULINE="${ESC}[4m"						# set underline
	declare -r    TXT_ULINERST="${ESC}[24m"					# reset underline
	declare -r    TXT_REV="${ESC}[7m"						# set reverse display
	declare -r    TXT_REVRST="${ESC}[27m"					# reset reverse display
	declare -r    TXT_BLACK="${ESC}[90m"					# text black
	declare -r    TXT_RED="${ESC}[91m"						# text red
	declare -r    TXT_GREEN="${ESC}[92m"					# text green
	declare -r    TXT_YELLOW="${ESC}[93m"					# text yellow
	declare -r    TXT_BLUE="${ESC}[94m"						# text blue
	declare -r    TXT_MAGENTA="${ESC}[95m"					# text purple
	declare -r    TXT_CYAN="${ESC}[96m"						# text light blue
	declare -r    TXT_WHITE="${ESC}[97m"					# text white
	declare -r    TXT_BBLACK="${ESC}[40m"					# text reverse black
	declare -r    TXT_BRED="${ESC}[41m"						# text reverse red
	declare -r    TXT_BGREEN="${ESC}[42m"					# text reverse green
	declare -r    TXT_BYELLOW="${ESC}[43m"					# text reverse yellow
	declare -r    TXT_BBLUE="${ESC}[44m"					# text reverse blue
	declare -r    TXT_BMAGENTA="${ESC}[45m"					# text reverse purple
	declare -r    TXT_BCYAN="${ESC}[46m"					# text reverse light blue
	declare -r    TXT_BWHITE="${ESC}[47m"					# text reverse white
	declare -r    TXT_DBLACK="${ESC}[30m"					# text dark black
	declare -r    TXT_DRED="${ESC}[31m"						# text dark red
	declare -r    TXT_DGREEN="${ESC}[32m"					# text dark green
	declare -r    TXT_DYELLOW="${ESC}[33m"					# text dark yellow
	declare -r    TXT_DBLUE="${ESC}[34m"					# text dark blue
	declare -r    TXT_DMAGENTA="${ESC}[35m"					# text dark purple
	declare -r    TXT_DCYAN="${ESC}[36m"					# text dark light blue
	declare -r    TXT_DWHITE="${ESC}[37m"					# text dark white

# --- text color test ---------------------------------------------------------
function funcColorTest() {
	printf "%s : %-12.12s : %s\n" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DBLACK}"   "TXT_DBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DRED}"     "TXT_DRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DGREEN}"   "TXT_DGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DYELLOW}"  "TXT_DYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DBLUE}"    "TXT_DBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DMAGENTA}" "TXT_DMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DCYAN}"    "TXT_DCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DWHITE}"   "TXT_DWHITE"   "${TXT_RESET}"
}

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
		return
	fi
	printf "%s\n" "$3"
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "$1" "$2" || true
}

# --- substr ------------------------------------------------------------------
function funcSubstr() {
	echo "$1" | awk '{print substr($0,'"$2"','"$3"');}'
}

# --- IPv6 full address -------------------------------------------------------
function funcIPv6GetFullAddr() {
#	declare -r    _OLD_IFS="${IFS}"
	declare       _INP_ADDR="$1"
	declare -r    _STR_FSEP="${_INP_ADDR//[^:]}"
	declare -r -i _CNT_FSEP=$((7-${#_STR_FSEP}))
	declare -a    _OUT_ARRY=()
	declare       _OUT_TEMP=""
	if [[ "${_CNT_FSEP}" -gt 0 ]]; then
		_OUT_TEMP="$(eval printf ':%.s' "{1..$((_CNT_FSEP+2))}")"
		_INP_ADDR="${_INP_ADDR/::/${_OUT_TEMP}}"
	fi
	IFS= mapfile -d ':' -t _OUT_ARRY < <(echo -n "${_INP_ADDR/%:/::}")
	_OUT_TEMP="$(printf ':%04x' "${_OUT_ARRY[@]/#/0x0}")"
	echo "${_OUT_TEMP:1}"
}

# --- IPv6 reverse address ----------------------------------------------------
function funcIPv6GetRevAddr() {
	declare -r    _INP_ADDR="$1"
	echo "${_INP_ADDR//:/}"                  | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}

# --- IPv4 netmask conversion -------------------------------------------------
function funcIPv4GetNetmask() {
	declare -r    _INP_ADDR="$1"
#	declare       _DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-_INP_ADDR)-1)))"
	declare -i    _LOOP=$((32-_INP_ADDR))
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
	declare -r    _INP_ADDR="$1"
	declare -a    _OCTETS=()
	declare -i    _MASK=0
	echo "${_INP_ADDR}" | \
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
	if [[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		echo 0
	else
		echo 1
	fi
}

# --- string output -----------------------------------------------------------
function funcString() {
	declare -r    _OLD_IFS="${IFS}"
	IFS=$'\n'
	if [[ "$1" -le 0 ]]; then
		echo ""
	else
		if [[ "$2" = " " ]]; then
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); print s;}'
		else
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
		fi
	fi
	IFS="${_OLD_IFS}"
}

# --- print with screen control -----------------------------------------------
function funcPrintf() {
#	declare -r    _SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
	declare -r    _SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
	set +x
	# https://www.tohoho-web.com/ex/dash-tilde.html
	declare -r    _OLD_IFS="${IFS}"
#	declare -i    _RET_CD=0
	declare       _FLAG_CUT=""
	declare       _TEXT_FMAT=""
	declare -r    _CTRL_ESCP=$'\033['
	declare       _PRNT_STR=""
	declare       _SJIS_STR=""
	declare       _TEMP_STR=""
	declare       _WORK_STR=""
	declare -i    _CTRL_CNT=0
	declare -i    _MAX_COLS="${COLS_SIZE:-80}"
	# -------------------------------------------------------------------------
	IFS=$'\n'
	if [[ "$1" = "--no-cutting" ]]; then					# no cutting print
		_FLAG_CUT="true"
		shift
	fi
	if [[ "$1" =~ %[0-9.-]*[diouxXfeEgGcs]+ ]]; then
		# shellcheck disable=SC2001
		_TEXT_FMAT="$(echo "$1" | sed -e 's/%\([0-9.-]*\)s/%\1b/g')"
		shift
	fi
	# shellcheck disable=SC2059
	_PRNT_STR="$(printf "${_TEXT_FMAT:-%b}" "${@:-}")"
	if [[ -z "${_FLAG_CUT}" ]]; then
		_SJIS_STR="$(echo -n "${_PRNT_STR:-}" | iconv -f UTF-8 -t CP932)"
		_TEMP_STR="$(echo -n "${_SJIS_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
		if [[ "${#_TEMP_STR}" -gt "${_MAX_COLS}" ]]; then
			_CTRL_CNT=$((${#_SJIS_STR}-${#_TEMP_STR}))
			_WORK_STR="$(echo -n "${_SJIS_STR}" | cut -b $((_MAX_COLS+_CTRL_CNT))-)"
			_TEMP_STR="$(echo -n "${_WORK_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
			_MAX_COLS+=$((_CTRL_CNT-(${#_WORK_STR}-${#_TEMP_STR})))
			# shellcheck disable=SC2312
			if ! _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -"${_MAX_COLS}"   | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
				 _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -$((_MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
			fi
		fi
	fi
	printf "%b\n" "${_PRNT_STR:-}"
	IFS="${_OLD_IFS}"
	# -------------------------------------------------------------------------
	if [[ "${_SET_ENV_X}" = "on" ]]; then
		set -x
	else
		set +x
	fi
#	if [[ "${_SET_ENV_E}" = "on" ]]; then
#		set -e
#	else
#		set +e
#	fi
}

# --- unit conversion ---------------------------------------------------------
function funcUnit_conversion() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -r -a _TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC_UNIT=0
	declare -i    I=0

	if [[ "$1" -lt 1024 ]]; then
		printf "%'d Byte" "$1"
		return
	fi

	if command -v numfmt > /dev/null 2>&1; then
		echo "$1" | numfmt --to=iec-i --suffix=B
		return
	fi

	for ((I=3; I>0; I--))
	do
		_CALC_UNIT=$((1024**I))
		if [[ "$1" -ge "${_CALC_UNIT}" ]]; then
			# shellcheck disable=SC2312
			printf "%s %s" "$(echo "$1" "${_CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')" "${_TEXT_UNIT[${I}]}"
			return
		fi
	done
	echo -n "$1"
}

# --- download ----------------------------------------------------------------
function funcCurl() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -i    _RET_CD=0
	declare -i    I
	declare       _INP_URL=""
	declare       _OUT_DIR=""
	declare       _OUT_FILE=""
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
	declare       _TXT_SIZ=""

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			http://* | https://* )
				_OPT_PRM+=("${1}")
				_INP_URL="${1}"
				;;
			--output-dir )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_DIR="${1}"
				;;
			--output )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_FILE="${1}"
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
	if [[ -z "${_OUT_FILE}" ]]; then
		_OUT_FILE="${_INP_URL##*/}"
	fi
	if ! _ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${_INP_URL}" 2> /dev/null)"); then
		_RET_CD="$?"
		_ERR_MSG=$(echo "${_ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
#		echo -e "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		fi
		return "${_RET_CD}"
	fi
	_WEB_SIZ=$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	_WEB_TIM=$(TZ=UTC date -d "$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	_WEB_FIL="${_OUT_DIR:-.}/${_INP_URL##*/}"
	if [[ -n "${_OUT_DIR}" ]] && [[ ! -d "${_OUT_DIR}/." ]]; then
		mkdir -p "${_OUT_DIR}"
	fi
	if [[ -n "${_OUT_FILE}" ]] && [[ -e "${_OUT_FILE}" ]]; then
		_WEB_FIL="${_OUT_FILE}"
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

	_TXT_SIZ="$(funcUnit_conversion "${_WEB_SIZ}")"

	if [[ -z "${_MSG_FLG}" ]]; then
		printf "%s\n" "get     file: ${_WEB_FIL} (${_TXT_SIZ})"
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

# *** function section (sub functions) ****************************************

# === test ====================================================================

	# --- debug parameter -----------------------------------------------------
	declare       DBGS_FLAG="${_DBGOUT:-}"			# debug flag (true: debug, else: normal)
	readonly DBGS_FLAG

	# --- command line parameter ----------------------------------------------
	declare -a    COMD_LINE=("$(cat /proc/cmdline)")	# command line parameter
	readonly COMD_LINE

	# --- chroot parameter ----------------------------------------------------
	declare       DIRS_TGET=""						# target directory
	if [[ -d /target/. ]]; then
		DIRS_TGET="/target"
	elif [[ -d /mnt/sysimage/. ]]; then
		DIRS_TGET="/mnt/sysimage"
	fi
	readonly DIRS_TGET

	# --- system parameter ----------------------------------------------------
	declare       DIST_NAME=""						# distribution name (ex. debian)
	declare       DIST_VERS=""						# release version   (ex. 12)
	declare       DIST_CODE=""						# code name         (ex. bookworm)

	# --- network parameter ---------------------------------------------------
	declare       IPV4_DHCP=""						# true: dhcp, else: fixed address
	declare       NICS_NAME=""						# nic if name       (ex. ens160)
	declare       NICS_MADR=""						# nic if mac        (ex. 00:00:00:00:00:00)
	declare       NICS_IPV4=""						# ipv4 address      (ex. 192.168.1.1)
	declare       NICS_MASK=""						# ipv4 netmask      (ex. 255.255.255.0)
	declare       NICS_BIT4=""						# ipv4 cidr         (ex. 24)
	declare       NICS_DNS4=""						# ipv4 dns          (ex. 192.168.1.254)
	declare       NICS_GATE=""						# ipv4 gateway      (ex. 192.168.1.254)
	declare       NICS_FQDN=""						# hostname fqdn     (ex. sv-server.workgroup)
	declare       NICS_HOST=""						# hostname          (ex. sv-server)
	declare       NICS_WGRP=""						# domain            (ex. workgroup)
	declare       IPV4_UADR=""						# IPv4 address up   (ex. 192.168.1)
	declare       IPV4_LADR=""						# IPv4 address low  (ex. 1)
	declare       IPV6_ADDR=""						# IPv6 address      (ex. ::1)
	declare       IPV6_CIDR=""						# IPv6 cidr         (ex. 64)
	declare       IPV6_FADR=""						# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	declare       IPV6_UADR=""						# IPv6 address up   (ex. 0000:0000:0000:0000)
	declare       IPV6_LADR=""						# IPv6 address low  (ex. 0000:0000:0000:0001)
	declare       IPV6_RADR=""						# IPv6 reverse addr (ex. ...)
	declare       LINK_ADDR=""						# LINK address      (ex. fe80::1)
	declare       LINK_CIDR=""						# LINK cidr         (ex. 64)
	declare       LINK_FADR=""						# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	declare       LINK_UADR=""						# LINK address up   (ex. fe80:0000:0000:0000)
	declare       LINK_LADR=""						# LINK address low  (ex. 0000:0000:0000:0001)
	declare       LINK_RADR=""						# LINK reverse addr (ex. ...)

# --- test of system --------------------------------------------------------
function funcTest_system() {
	declare -r    _FUNC_NAME="funcTest_system"
	declare -a    _LIST=()
	declare       _LINE=""
	declare -i    I=0

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- distribution information --------------------------------------------
	if [[ -e "${DIRS_TGET:-}/etc/os-release" ]]; then
		IFS= mapfile -d $'\n' -t _LIST < <(cat "${DIRS_TGET:-}/etc/os-release" || true)
	elif [[ -e "${DIRS_TGET:-}/etc/lsb-release" ]]; then
		IFS= mapfile -d $'\n' -t _LIST < <(cat "${DIRS_TGET:-}/etc/lsb-release" || true)
	fi
	for I in "${!_LIST[@]}"
	do
		_LINE="${_LIST[I],,}"
		case "${_LINE}" in
			id=*              ) DIST_NAME="${_LINE#id=}"              ;;
			version_codename=*) DIST_CODE="${_LINE#version_codename=}";;
			version=*         ) DIST_VERS="${_LINE#version=}"
			                    DIST_VERS="${DIST_VERS//\"/}"
			                    DIST_VERS="${DIST_VERS%% *}";;
			distrib_id=*      ) DIST_NAME="${_LINE#distrib_id=}"      ;;
			distrib_release=* ) DIST_CODE="${_LINE#distrib_release=}"
			                    DIST_CODE="${DIST_CODE//\"/}"
			                    DIST_CODE="${DIST_CODE%% *}";;
			*                 ) ;;
		esac
	done
	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of network ---------------------------------------------------------
function funcTest_network() {
	declare -r    _FUNC_NAME="funcTest_network"

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	NICS_NAME="${NICS_NAME:-"$(ip -4 -oneline address show primary | grep -E '^2:' | cut -d ' ' -f 2)"}"
	NICS_NAME="${NICS_NAME:-"ens160"}"

	NICS_MADR="${NICS_MADR:-"$(ip -4 -oneline link    show dev "${NICS_NAME}" 2> /dev/null | sed -ne 's%^.*[ \t]link/ether[ \t]\+\([[:alnum:]:]\+\)[ \t].*$%\1%p')"}"
	NICS_IPV4="${NICS_IPV4:-"$(ip -4 -oneline address show dev "${NICS_NAME}" 2> /dev/null | sed -ne 's%^.*[ \t]inet[ \t]\+\([0-9/.]\+\)\+[ \t].*$%\1%p')"}"
	NICS_BIT4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 2)"
	NICS_IPV4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 1)"

	if [[ -z "${NICS_BIT4}" ]]; then
		NICS_BIT4="$(funcIPv4GetNetmask "${NICS_MASK:-"255.255.255.0"}")"
	else
		NICS_MASK="$(funcIPv4GetNetmask "${NICS_BIT4:-"24"}")"
	fi

	NICS_DNS4="${NICS_DNS4:-"$(sed -ne 's/^nameserver[ \]\+\([[:alnum:]:.]\+\)[ \t]*$/\1/p' "${DIRS_TGET:-}/etc/resolv.conf" | sed -e ':l; N; s/\n/,/; b l;')"}"
	NICS_GATE="${NICS_GATE:-"$(ip -4 -oneline route list match default | cut -d ' ' -f 3)"}"
	NICS_FQDN="${NICS_FQDN:-"$(cat "${DIRS_TGET:-}/etc/hostname")"}"
	NICS_HOST="${NICS_HOST:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 1)"}"
	NICS_WGRP="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 2)"}"
	NICS_WGRP="${NICS_WGRP:-"$(awk '$1=="search" {print $2;}' "${DIRS_TGET:-}/etc/resolv.conf")"}"
	NICS_HOST="${NICS_HOST,,}"
	NICS_WGRP="${NICS_WGRP,,}"
	if [[ "${NICS_FQDN}" = "${NICS_HOST}" ]] && [[ -n "${NICS_WGRP}" ]]; then
		NICS_FQDN="${NICS_HOST}.${NICS_WGRP}"
	fi

	IPV4_UADR="${NICS_IPV4%.*}"
	IPV4_LADR="${NICS_IPV4##*.}"
	IPV6_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/! s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
	IPV6_CIDR="${IPV6_ADDR#*/}"
	IPV6_ADDR="${IPV6_ADDR%%/*}"
	IPV6_FADR="$(funcIPv6GetFullAddr "${IPV6_ADDR}")"
	IPV6_UADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	IPV6_LADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	IPV6_RADR=""
	LINK_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/ s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
	LINK_CIDR="${LINK_ADDR#*/}"
	LINK_ADDR="${LINK_ADDR%%/*}"
	LINK_FADR="$(funcIPv6GetFullAddr "${LINK_ADDR}")"
	LINK_UADR="$(echo "${LINK_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	LINK_LADR="$(echo "${LINK_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	LINK_RADR=""

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of dns port --------------------------------------------------------
function funcTest_dns_port() {
	declare -r    _FUNC_NAME="funcTest_dns_port"
	declare       _WORK_TEXT=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- dns port check ------------------------------------------------------
	if command -v ss > /dev/null 2>&1; then
		_WORK_TEXT="ss -tulpn | sed -n '/:53/p'"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
		if ss -tulpn | sed -n '/:53/p' | cut -c -"${COLS_SIZE:-"80"}"; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of nslookup --------------------------------------------------------
function funcTest_nslookup() {
	declare -r    _FUNC_NAME="funcTest_nslookup"
	declare -a    _LIST=()
	declare       _LINE=""
	declare       _WORK_TEXT=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- nslookup check ------------------------------------------------------
	if command -v nslookup > /dev/null 2>&1; then
		_LIST=(
			"${NICS_FQDN%.*}."
			"${NICS_FQDN}"
			"${NICS_FQDN%.*}.local"
			"${NICS_IPV4}"
			"${IPV6_ADDR}"
			"${LINK_ADDR}"
			"www.google.com"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_WORK_TEXT="nslookup ${_LINE}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if nslookup "${_LINE}"; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of dig -------------------------------------------------------------
function funcTest_dig() {
	declare -r    _FUNC_NAME="funcTest_dig"
	declare -a    _LIST=()
	declare       _LINE=""
	declare       _WORK_TEXT=""
	declare       _PRAM_TYPE=""
	declare       _PRAM_ADDR=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- dig check -----------------------------------------------------------
	if command -v nslookup > /dev/null 2>&1; then
		_LIST=(
			"A,${NICS_FQDN%.*}."
			"AAAA,${NICS_FQDN%.*}."
			"A,${NICS_FQDN}"
			"AAAA,${NICS_FQDN}"
			"A,${NICS_FQDN%.*}.local"
			"AAAA,${NICS_FQDN%.*}.local"
			"A,www.google.com"
			"AAAA,www.google.com"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_PRAM_TYPE="${_LINE%%,*}"
			_PRAM_ADDR="${_LINE#*,}"
			_WORK_TEXT="dig ${_PRAM_TYPE} ${_PRAM_ADDR} +nostats +nocomments"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if dig "${_PRAM_ADDR}" "${_PRAM_TYPE}" +nostats +nocomments; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
		_LIST=(
			"${NICS_IPV4}"
			"${IPV6_ADDR}"
			"${LINK_ADDR}"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_WORK_TEXT="dig -x ${_LINE} +nostats +nocomments"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if dig -x "${_LINE}" +nostats +nocomments; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of getent ----------------------------------------------------------
function funcTest_getent() {
	declare -r    _FUNC_NAME="funcTest_getent"
	declare -a    _LIST=()
	declare       _LINE=""
	declare       _WORK_TEXT=""
	declare       _PRAM_TYPE=""
	declare       _PRAM_ADDR=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- getent check --------------------------------------------------------
	if command -v getent > /dev/null 2>&1; then
		_LIST=(
			"${NICS_FQDN%.*}."
			"${NICS_FQDN}"
			"${NICS_FQDN%.*}.local"
			"${NICS_IPV4}"
			"${IPV6_ADDR}"
			"${LINK_ADDR}"
			"www.google.com"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_WORK_TEXT="getent hosts ${_LINE}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if getent hosts "${_LINE}"; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of communication ---------------------------------------------------
function funcTest_communication() {
	declare -r    _FUNC_NAME="funcTest_communication"
	declare -a    _LIST=()
	declare       _LINE=""
	declare       _PRAM_TYPE=""
	declare       _PRAM_ADDR=""
	declare       _WORK_TEXT=""
	declare -i    I=0

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- communication check -------------------------------------------------
	if command -v ping > /dev/null 2>&1; then
		_LIST=(
			"-4,${NICS_FQDN}"
			"-6,${NICS_FQDN}"
			"-4,${NICS_IPV4}"
			"-6,${IPV6_ADDR}"
			"-6,${LINK_ADDR}"
			"-4,www.google.com"
			"-6,www.google.com"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_PRAM_TYPE="${_LINE%%,*}"
			_PRAM_ADDR="${_LINE#*,}"
			_WORK_TEXT="ping ${_PRAM_TYPE} -c 1 ${_PRAM_ADDR}"
			if ping "${_PRAM_TYPE}" -c 1 "${_PRAM_ADDR}" > /dev/null 2>&1; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of ntp -------------------------------------------------------------
function funcTest_ntp() {
	declare -r    _FUNC_NAME="funcTest_ntp"

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- timedatectl check ---------------------------------------------------
	if command -v timedatectl > /dev/null 2>&1; then
		_WORK_TEXT="timedatectl status"
		if timedatectl status; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
		_WORK_TEXT="timedatectl timesync-status"
		if timedatectl timesync-status; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- chronyc check -------------------------------------------------------
	if command -v chronyc > /dev/null 2>&1; then
		_WORK_TEXT="chronyc sources"
		if chronyc sources; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of samba -----------------------------------------------------------
function funcTest_samba() {
	declare -r    _FUNC_NAME="funcTest_samba"
	declare -a    _LIST=()
	declare       _LINE=""
	declare       _WORK_TEXT=""
	declare       _BRWS_ADDR=""
	declare       _BRWS_NAME=""
	declare       _BRWS_WGRP=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- nmblookup check -----------------------------------------------------
	if command -v nmblookup > /dev/null 2>&1; then
		_BRWS_ADDR="$(nmblookup -M -- - | awk '{print $1;}')"
		_BRWS_NAME="$(nmblookup -A "${_BRWS_ADDR}" | awk '$2=="<00>"&&$4!="<GROUP>" {print $1;}')"
		_BRWS_WGRP="$(nmblookup -A "${_BRWS_ADDR}" | awk '$2=="<00>"&&$4=="<GROUP>" {print $1;}')"
		if command -v getent > /dev/null 2>&1; then
			_WORK_TEXT="getent hosts ${_BRWS_NAME,,}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if getent hosts "${_BRWS_NAME,,}"; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		fi
		if command -v traceroute > /dev/null 2>&1; then
			_WORK_TEXT="traceroute -4 ${_BRWS_NAME,,}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if traceroute -4 "${_BRWS_NAME,,}" > /dev/null 2>&1; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
			_WORK_TEXT="traceroute -6 ${_BRWS_NAME,,}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if traceroute -6 "${_BRWS_NAME,,}" > /dev/null 2>&1; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		fi
	fi

	# --- smbclient check -----------------------------------------------------
	if command -v smbclient > /dev/null 2>&1; then
		_LIST=(
			"${NICS_FQDN%.*}."
			"${NICS_FQDN}"
			"${NICS_FQDN%.*}.local"
			"${NICS_IPV4}"
			"${IPV6_ADDR}"
			"${LINK_ADDR}"
		)
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I]}"
			_WORK_TEXT="smbclient -N -L ${_LINE}"
			funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
			if smbclient -N -L "${_LINE}" > /dev/null 2>&1; then
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
			else
				printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
			fi
		done
		_WORK_TEXT="smbclient -N -L ${NICS_FQDN%.*}."
		funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
		if smbclient -N -L "${NICS_FQDN%.*}."; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- pdbedit check -------------------------------------------------------
	if command -v pdbedit > /dev/null 2>&1; then
		_WORK_TEXT="pdbedit -L"
		funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
		if pdbedit -L; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of httpd -----------------------------------------------------------
function funcTest_httpd() {
	declare -r    _FUNC_NAME="funcTest_httpd"
	declare       _WORK_TEXT=""

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- wget check ----------------------------------------------------------
	if command -v wget > /dev/null 2>&1; then
		_WORK_TEXT="wget -4 -q -O /dev/null http://${NICS_FQDN}/"
		funcPrintf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: %s${TXT_RESET}\n" "${_WORK_TEXT} ${TEXT_GAP1}"
		if wget -4 -q -O /dev/null "http://${NICS_FQDN}/"; then
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_GREEN}%s${TXT_RESET}: %s${TXT_RESET}\n" "success" "${_WORK_TEXT}"
		else
			printf "${TXT_RESET}${TXT_DWHITE}${PROG_NAME}${TXT_RESET}: ${TXT_RED}%s${TXT_RESET}: %s${TXT_RESET}\n"   "fail   " "${_WORK_TEXT}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- test of system ----------------------------------------------------------
#function funcTest_() {
#	declare -r    _FUNC_NAME="funcTest_network"
#
#	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"
#
#	# --- complete ------------------------------------------------------------
#	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
#}

# --- print out parameter -----------------------------------------------------
funcPrintout_parameter() {
	declare -r    _FUNC_NAME="funcPrintout_parameter"

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP2}"
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_BGREEN}%s${TXT_RESET}\n" "--- print out start ---"

	# --- print out debug parameter -------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DBGS_FLAG" "${DBGS_FLAG:-}"

	# --- print out command line parameter ------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "COMD_LINE" "${COMD_LINE[*]:-}"

	# --- print out chroot parameter ------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DIRS_TGET" "${DIRS_TGET:-}"

	# --- print out working directory parameter -------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "PROG_PATH" "${PROG_PATH:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "PROG_PARM" "${PROG_PARM[*]:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "PROG_DIRS" "${PROG_DIRS:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "PROG_NAME" "${PROG_NAME:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "PROG_PROC" "${PROG_PROC:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DIRS_TEMP" "${DIRS_TEMP:-}"

	# --- print out system parameter ------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DIST_NAME" "${DIST_NAME:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DIST_VERS" "${DIST_VERS:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "DIST_CODE" "${DIST_CODE:-}"

	# --- print out network parameter -----------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV4_DHCP" "${IPV4_DHCP:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_NAME" "${NICS_NAME:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_MADR" "${NICS_MADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_IPV4" "${NICS_IPV4:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_MASK" "${NICS_MASK:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_BIT4" "${NICS_BIT4:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_DNS4" "${NICS_DNS4:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_GATE" "${NICS_GATE:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_FQDN" "${NICS_FQDN:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_HOST" "${NICS_HOST:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "NICS_WGRP" "${NICS_WGRP:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV4_UADR" "${IPV4_UADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV4_LADR" "${IPV4_LADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_ADDR" "${IPV6_ADDR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_CIDR" "${IPV6_CIDR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_FADR" "${IPV6_FADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_UADR" "${IPV6_UADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_LADR" "${IPV6_LADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "IPV6_RADR" "${IPV6_RADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_ADDR" "${LINK_ADDR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_CIDR" "${LINK_CIDR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_FADR" "${LINK_FADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_UADR" "${LINK_UADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_LADR" "${LINK_LADR:-}"
	printf "${TXT_RESET}${PROG_NAME}: %s=[%s]${TXT_RESET}\n" "LINK_RADR" "${LINK_RADR:-}"

	# -------------------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP1}"
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_BGREEN}%s${TXT_RESET}\n" "--- print out complete ---"
	printf "${TXT_RESET}${PROG_NAME}: %s${TXT_RESET}\n" "${TEXT_GAP2}"

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- initialize --------------------------------------------------------------
funcInitialize() {
	declare -r    _FUNC_NAME="funcInitialize"

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- set system parameter ------------------------------------------------
	if [[ -n "${TERM:-}" ]] \
	&& command -v tput > /dev/null 2>&1; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [[ "${ROWS_SIZE}" -lt 25 ]]; then
		ROWS_SIZE=25
	fi
	if [[ "${COLS_SIZE}" -lt 80 ]]; then
		COLS_SIZE=80
	fi

	readonly ROWS_SIZE
	readonly COLS_SIZE

	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"		# work
	TEXT_GAP1="$(funcString "${TEXT_GAPS}" '-')"
	TEXT_GAP2="$(funcString "${TEXT_GAPS}" '=')"

	readonly TEXT_GAP1
	readonly TEXT_GAP2

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# --- function test -----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    _MSGS_TITL="call function test"
	declare -r    _FILE_WRK1="${DIRS_TEMP}/testfile1.txt"
	declare -r    _FILE_WRK2="${DIRS_TEMP}/testfile2.txt"
	declare -r    _TEST_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
	declare -r -a _CURL_OPTN=(        \
		"--location"                  \
		"--progress-bar"              \
		"--remote-name"               \
		"--remote-time"               \
		"--show-error"                \
		"--fail"                      \
		"--retry-max-time" "3"        \
		"--retry" "3"                 \
		"--create-dirs"               \
		"--output-dir" "${DIRS_TEMP}" \
		"${_TEST_ADDR}"               \
	)
	declare       _TEST_PARM=""
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
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
	funcPrintf "---- text print test ${TEXT_GAP1}"
	H1=""
	H2=""
	for ((I=1; I<="${COLS_SIZE}"+10; I++))
	do
		if [[ $((I % 10)) -eq 0 ]]; then
			H1+="         $((I%100/10))"
		fi
		H2+="$((I%10))"
	done
	funcPrintf "${H1}"
	funcPrintf "${H2}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '->')"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '→')"
	# shellcheck disable=SC2312
	funcPrintf "_$(funcString "${COLS_SIZE}" '→')_"
	echo ""

	# --- text color test -----------------------------------------------------
	funcPrintf "---- text color test ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcColorTest"
	funcColorTest
	echo ""

	# --- printf --------------------------------------------------------------
	funcPrintf "---- printf ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcPrintf"
	funcPrintf "%s : %-12.12s : %s" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#	funcPrintf "%s : %-12.12s : %s" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#	funcPrintf "%s : %-12.12s : %s" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DBLACK}"   "TXT_DBLACK"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DRED}"     "TXT_DRED"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DGREEN}"   "TXT_DGREEN"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DYELLOW}"  "TXT_DYELLOW"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DBLUE}"    "TXT_DBLUE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DMAGENTA}" "TXT_DMAGENTA" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DCYAN}"    "TXT_DCYAN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DWHITE}"   "TXT_DWHITE"   "${TXT_RESET}"
	echo ""

	# --- diff ----------------------------------------------------------------
	funcPrintf "---- diff ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcDiff \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	funcDiff "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" "function test"
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" --suppress-common-lines \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff --color=always -y -W \"${COLS_SIZE}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff --color=always -y -W "${COLS_SIZE}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	echo ""

	# --- substr --------------------------------------------------------------
	funcPrintf "---- substr ${TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcSubstr \"${_TEST_PARM}\" 1 19"
	funcPrintf "--no-cutting" "         1         2         3         4"
	funcPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	funcPrintf "--no-cutting" "${_TEST_PARM}"
	funcSubstr "${_TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	funcPrintf "---- service status ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcServiceStatus \"sshd.service\""
	funcServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	funcPrintf "---- IPv6 full address ${TEXT_GAP1}"
	_TEST_PARM="fe80::1"
	funcPrintf "--no-cutting" "funcIPv6GetFullAddr \"${_TEST_PARM}\""
	funcIPv6GetFullAddr "${_TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	funcPrintf "---- IPv6 reverse address ${TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcIPv6GetRevAddr \"${_TEST_PARM}\""
	funcIPv6GetRevAddr "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	funcPrintf "---- IPv4 netmask conversion ${TEXT_GAP1}"
	_TEST_PARM="24"
	funcPrintf "--no-cutting" "funcIPv4GetNetmask \"${_TEST_PARM}\""
	funcIPv4GetNetmask "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	funcPrintf "---- IPv4 cidr conversion ${TEXT_GAP1}"
	_TEST_PARM="255.255.255.0"
	funcPrintf "--no-cutting" "funcIPv4GetNetCIDR \"${_TEST_PARM}\""
	funcIPv4GetNetCIDR "${_TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	funcPrintf "---- is numeric ${TEXT_GAP1}"
	_TEST_PARM="123.456"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""
	_TEST_PARM="abc.def"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	funcPrintf "---- string output ${TEXT_GAP1}"
	_TEST_PARM="50"
	funcPrintf "--no-cutting" "funcString \"${_TEST_PARM}\" \"#\""
	funcString "${_TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	funcPrintf "---- print with screen control ${TEXT_GAP1}"
	_TEST_PARM="test"
	funcPrintf "--no-cutting" "funcPrintf \"${_TEST_PARM}\""
	funcPrintf "${_TEST_PARM}"
	echo ""

	# --- download ------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		funcPrintf "---- download ${TEXT_GAP1}"
		funcPrintf "--no-cutting" "funcCurl ${_CURL_OPTN[*]}"
		funcCurl "${_CURL_OPTN[@]}"
		echo ""
	fi

	# -------------------------------------------------------------------------
	rm -f "${_FILE_WRK1}" "${_FILE_WRK2}"
	ls -l "${DIRS_TEMP}"
}

# --- main --------------------------------------------------------------------
funcMain() {
	declare -r    _FUNC_NAME="funcMain"

	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- start   : [${_FUNC_NAME}] ---"

	if [[ "${_DBGPRT:-}" = "true" ]]; then
		funcCall_function				# function test
	else
		funcInitialize					# initialize

		funcTest_system					# test of system
		funcTest_network				# test of network

		funcPrintout_parameter			# print out parameter

		funcTest_dns_port				# test of dns port
		funcTest_nslookup				# test of nslookup
		funcTest_dig					# test of dig
		funcTest_getent					# test of getent

		funcTest_communication			# test of communication

		funcTest_ntp					# test of ntp

		funcTest_samba					# test of samba
		funcTest_httpd					# test of httpd
	fi

	# --- complete ------------------------------------------------------------
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_GREEN}%s${TXT_RESET}\n" "--- complete: [${_FUNC_NAME}] ---"
}

# *** main processing section *************************************************
	# --- start ---------------------------------------------------------------
	_start_time=$(date +%s)
	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_BMAGENTA}%s${TXT_RESET}\n" "${_datetime} processing start"
	# --- main ----------------------------------------------------------------
	trap 'rm -rf '"${DIRS_TEMP:?}"'' EXIT
	funcMain
	IFS="${OLD_IFS}"
	# --- complete ------------------------------------------------------------
	_end_time=$(date +%s)
	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "${TXT_RESET}${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds${TXT_RESET}\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
	printf "${TXT_RESET}${PROG_NAME}: ${TXT_BMAGENTA}%s${TXT_RESET}\n" "${_datetime} processing complete"
	exit 0

### eof #######################################################################
