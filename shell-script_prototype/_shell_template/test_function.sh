#!/bin/bash

###############################################################################
##
##	common functions test shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/04/15
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/04/15 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************
	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# === data section ========================================================

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"$(whoami || true)"}"

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare       _DIRS_TEMP=""
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
	declare -r    TMPDIR="${_DIRS_TEMP:-?}"

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# -----------------------------------------------------------------------------
# descript: trap
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnTrap() {
	declare       __PATH=""				# full path
	declare -i    I=0
	# --- unmount -------------------------------------------------------------
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ -e "${__PATH}" ]] && mountpoint --quiet "${__PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		fi
	done
	# --- remove temporary ----------------------------------------------------
	if [[ -e "${_DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${_DIRS_TEMP}" 1>&2
		while read -r __PATH
		do
			printf "[%s]: umount \"%s\"\n" "-" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		done < <(grep "${_DIRS_TEMP:?}" /proc/mounts | cut -d ' ' -f 2 | sort -rV || true)
		rm -rf "${_DIRS_TEMP:?}"
	fi
}

	trap fnTrap EXIT

	# -------------------------------------------------------------------------
	declare       _CODE_NAME=""
	              _CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      _CODE_NAME

	if command -v apt-get > /dev/null 2>&1; then
		if ! ls /var/lib/apt/lists/*_"${_CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
			echo "please execute apt-get update:"
			if [[ -n "${SUDO_USER:-}" ]] || { [[ -z "${SUDO_USER:-}" ]] && [[ "${_USER_NAME:-}" != "root" ]]; }; then
				echo -n "sudo "
			fi
			echo "apt-get update" 1>&2
			exit 1
		fi
		# ---------------------------------------------------------------------
		declare       _ARHC_MAIN=""
		              _ARHC_MAIN="$(dpkg --print-architecture)"
		readonly      _ARHC_MAIN
		declare       _ARCH_OTHR=""
		              _ARCH_OTHR="$(dpkg --print-foreign-architectures)"
		readonly      _ARCH_OTHR
		# --- for custom iso --------------------------------------------------
		declare -r -a PAKG_LIST=(\
			"curl" \
			"wget" \
		)
		# ---------------------------------------------------------------------
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_ARCH_OTHR:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g' || true)"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			echo "please install these:"
			if [[ "${_USER_NAME:-}" != "root" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get install ${PAKG_FIND% *}" 1>&2
			exit 1
		fi
	fi

	# --- curl / wget parameter -----------------------------------------------
	declare       _COMD_CURL=""
	declare       _COMD_WGET=""
	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=10" "--quiet")
	if command -v curl  > /dev/null 2>&1; then _COMD_CURL="true"; fi
	if command -v wget  > /dev/null 2>&1; then _COMD_WGET="true"; fi
	if command -v wget2 > /dev/null 2>&1; then _COMD_WGET="ver2"; fi
	readonly      _COMD_CURL
	readonly      _COMD_WGET

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
	declare -r    __TRCE="$(set -o | grep "^xtrace\s*on$")"
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

# === <network> ===============================================================

# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)

# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion (netmask and cidr conversion)
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv4GetNetmask() {
	declare -a    __OCTS=()				# octets
	declare -i    __LOOP=0				# work variables
	declare -i    __CALC=0				# "
	# -------------------------------------------------------------------------
	IFS= mapfile -d '.' -t __OCTS < <(echo -n "${1:?}.")
	# -------------------------------------------------------------------------
	if [[ "${#__OCTS[@]}" -gt 1 ]]; then
		# --- netmask -> cidr -------------------------------------------------
		__CALC=0
		while read -r __LOOP
		do
			case "${__LOOP}" in
				  0) ((__CALC+=0));;
				128) ((__CALC+=1));;
				192) ((__CALC+=2));;
				224) ((__CALC+=3));;
				240) ((__CALC+=4));;
				248) ((__CALC+=5));;
				252) ((__CALC+=6));;
				254) ((__CALC+=7));;
				255) ((__CALC+=8));;
				*  )              ;;
			esac
		done < <(printf "%s\n" "${__OCTS[@]}")
		printf '%d' "${__CALC}"
	else
		# --- cidr -> netmask -------------------------------------------------
		__LOOP=$((32-${1:?}))
		__CALC=1
		while [[ "${__LOOP}" -gt 0 ]]
		do
			__LOOP=$((__LOOP-1))
			__CALC=$((__CALC*2))
		done
		__CALC="$((0xFFFFFFFF ^ (__CALC-1)))"
		printf '%d.%d.%d.%d'              \
		    $(( __CALC >> 24        )) \
		    $(((__CALC >> 16) & 0xFF)) \
		    $(((__CALC >>  8) & 0xFF)) \
		    $(( __CALC        & 0xFF))
	fi
}

# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv6GetFullAddr() {
	declare -r    __FSEP="${1//[^:]/}"
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	# -------------------------------------------------------------------------
	__WORK="$(printf "%$((7-${#__FSEP}))s" "")"
	__WORK="${1/::/::${__WORK// /:}}"
	IFS= mapfile -d ':' -t __ARRY < <(echo -n "${__WORK/%:/::}")
	printf ':%04x' "${__ARRY[@]/#/0x0}" | cut -c 2-
}

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv6GetRevAddr() {
	echo "${1//:/}" | \
	    awk '{
	        for(i=length();i>1;i--)              \
	            printf("%c.", substr($0,i,1));   \
	            printf("%c" , substr($0,1,1));}'
}

# === <media> =================================================================

# -----------------------------------------------------------------------------
# descript: unit conversion
#   n-ref :   $1   : return value : value with units
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnUnit_conversion() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r -a __UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    __CALC=0
	declare       __WORK=""				# work variables
	declare -i    I=0
	# --- is numeric ----------------------------------------------------------
	if [[ ! ${2:?} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		__RETN_VALU="$(printf "Error [%s]" "$2" || true)"
		return
	fi
	# --- Byte ----------------------------------------------------------------
	if [[ "$2" -lt 1024 ]]; then
		__RETN_VALU="$(printf "%'d Byte" "$2" || true)"
		return
	fi
	# --- numfmt --------------------------------------------------------------
	if command -v numfmt > /dev/null 2>&1; then
		__RETN_VALU="$(echo -n "$2" | numfmt --to=iec-i --suffix=B || true)"
		return
	fi
	# --- calculate -----------------------------------------------------------
	for ((I=3; I>0; I--))
	do
		__CALC=$((1024**I))
		if [[ "$2" -ge "${__CALC}" ]]; then
			__WORK="$(echo "$2" "${__CALC}" | awk '{printf("%.1f", $1/$2)}')"
			__RETN_VALU="$(printf "%s %s" "${__WORK}" "${__UNIT[I]}" || true)"
			return
		fi
	done
}

# -----------------------------------------------------------------------------
# descript: get volume id
#   n-ref :   $1   : return value : volume id
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetVolID() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __VLID=""				# volume id
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	if [[ -n "${2:-}" ]] && [[ -s "${2:?}" ]]; then
		if command -v blkid > /dev/null 2>&1; then
			__VLID="$(blkid -s LABEL -o value "$2" || true)"
		else
			__VLID="$(LANG=C file -L "$2")"
			__VLID="${__VLID#*: }"
			__WORK="${__VLID%%\'*}"
			__VLID="${__VLID#"${__WORK}"}"
			__WORK="${__VLID##*\'}"
			__VLID="${__VLID%"${__WORK}"}"
		fi
	fi
	__RETN_VALU="${__VLID:-}"
}

# -----------------------------------------------------------------------------
# descript: get file information
#   n-ref :   $1   : return value : path tmstamp size vol-id
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetFileinfo() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __VLID=""				# volume id
	declare       __RSLT=""				# result
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	# -------------------------------------------------------------------------
	__ARRY=()
	if [[ -n "${2:-}" ]] && [[ -s "${2}" ]]; then
		__WORK="$(realpath -s "$2")"	# full path
		__FNAM="${__WORK##*/}"
		__DIRS="${__WORK%"${__FNAM}"}"
		__WORK="$(LANG=C find "${__DIRS:-.}" -name "${__FNAM}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s")"
		if [[ -n "${__WORK}" ]]; then
			read -r -a __ARRY < <(echo "${__WORK}")
			fnGetVolID __RSLT "${__ARRY[0]}"
			__VLID="${__RSLT#\'}"
			__VLID="${__VLID%\'}"
			__VLID="${__VLID:--}"
			__ARRY+=("${__VLID// /%20}")	# volume id
		fi
	fi
	__RETN_VALU="${__ARRY[*]}"
}

# -----------------------------------------------------------------------------
# descript: distro to efi image file name
#   input :   $1   : input value
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnDistro2efi() {
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	case "${1:?}" in
		debian      | \
		ubuntu      ) __WORK="boot/grub/efi.img";;
		fedora      | \
		centos      | \
		almalinux   | \
		rockylinux  | \
		miraclelinux) __WORK="images/efiboot.img";;
		opensuse    ) __WORK="boot/x86_64/efi";;
		*           ) ;;
	esac
	echo -n "${__WORK}"
}

# === <web_tools> =============================================================

# -----------------------------------------------------------------------------
# descript: get web contents
#   input :   $1   : output path
#   input :   $2   : url
#   output: stdout : message
#   return:        : status
# shellcheck disable=SC2317
function fnGetWeb_contents() {
	declare -a    __OPTN=()				# options
	declare -i    __RTCD=0				# return code
	declare -a    __LIST=()				# data list
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${TMPDIR:-/tmp}/${1##*/}.XXXXXX")"
	readonly      __TEMP
	# -------------------------------------------------------------------------
	__RTCD=0
	if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
		__OPTN=("${_OPTN_WGET[@]}" "--continue" "--show-progress" "--progress=bar" "--output-document=${__TEMP:?}" "${2:?}")
		LANG=C wget "${__OPTN[@]}" 2>&1 || __RTCD="$?"
	else
		__OPTN=("${_OPTN_CURL[@]}" "--progress-bar" "--continue-at" "-" "--create-dirs" "--output-dir" "${__TEMP%/*}" --output "${__TEMP##*/}" "${2:?}")
		LANG=C curl "${__OPTN[@]}" 2>&1 || __RTCD="$?"
	fi
	# -------------------------------------------------------------------------
	if [[ "${__RTCD}" -eq 0 ]]; then
		mkdir -p "${1%/*}"
		if [[ ! -s "$1" ]]; then
			: > "$1"
		fi
		if ! cp --preserve=timestamps "${__TEMP}" "$1"; then
			printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[41m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "error [cp]" "${1##*/}"
		else
			IFS= mapfile -d ' ' -t __LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "$1" || true)
			printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "complete" "${1##*/} (${__LIST[4]})"
		fi
	fi
	# -------------------------------------------------------------------------
	rm -f "${__TEMP:?}"
	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web header
#   n-ref :   $1   : return value : path tmstamp size status contents
#   input :   $2   : url
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_header() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -a    __OPTN=()				# options
#	declare -i    __RTCD=0				# return code
	declare       __RSLT=""				# result
	declare       __FILD=""				# field name
	declare       __VALU=""				# value
	declare       __CODE=""				# status codes
	declare       __LENG=""				# content-length
	declare       __LMOD=""				# last-modified
	declare -a    __LIST=()				# work variables
	declare       __LINE=""				# work variables
	declare -i    I=0					# work variables
	# -------------------------------------------------------------------------
#	__RTCD=0
	__RSLT=""
	if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
		__OPTN=("${_OPTN_WGET[@]}" "--spider" "--server-response" "--output-document=-" "${2:?}")
		__RSLT="$(LANG=C wget "${__OPTN[@]}" 2>&1 || true)"
	else
		__OPTN=("${_OPTN_CURL[@]}" "--header" "${2:?}")
		__RSLT="$(LANG=C curl "${__OPTN[@]}" 2>&1 || true)"
	fi
	# -------------------------------------------------------------------------
	__RSLT="${__RSLT//$'\r\n'/$'\n'}"	# crlf -> lf
	__RSLT="${__RSLT//$'\r'/$'\n'}"		# cr   -> lf
	__RSLT="${__RSLT//></>\n<}"
	__RSLT="${__RSLT#"${__RSLT%%[!"${IFS}"]*}"}"	# ltrim
	__RSLT="${__RSLT%"${__RSLT##*[!"${IFS}"]}"}"	# rtrim
	IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
	for I in "${!__LIST[@]}"
	do
		__LINE="${__LIST[I],,}"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__FILD="${__LINE%% *}"
		__VALU="${__LINE#* }"
		case "${__FILD%% *}" in
			http/*         ) __CODE="${__VALU%% *}";;
			content-length:) __LENG="${__VALU}";;
			last-modified: ) __LMOD="$(TZ=UTC date -d "${__VALU}" "+%Y-%m-%d%%20%H:%M:%S%z")";;
			*              ) ;;
		esac
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${2// /%20} ${__LMOD:--} ${__LENG:--} ${__CODE:--} ${__RSLT// /%20}"
#	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web address completion
#   n-ref :   $1   : return value : address completion path
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_address() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare -r    __PATN='?*[]'			# web file regexp
	declare       __MATC=""				# web file regexp match
	declare -a    __OPTN=()				# options
#	declare -i    __RTCD=0				# return code
	declare       __RSLT=""				# result
	declare       __FILD=""				# field name
	declare       __VALU=""				# value
	declare       __CODE=""				# status codes
	declare       __LENG=""				# content-length
	declare       __LMOD=""				# last-modified
	declare -a    __LIST=()				# work variables
	declare       __LINE=""				# work variables
	declare -i    I=0					# work variables
	# --- URL completion ------------------------------------------------------
	__PATH="${2:?}"
	while [[ -n "${__PATH//[!"${__PATN}"]/}" ]]
	do
		__DIRS="${__PATH%%["${__PATN}"]*}"	# directory
		__DIRS="${__DIRS%/*}"
		__MATC="${__PATH#"${__DIRS}"/}"	# match
		__MATC="${__MATC%%/*}"
		__FNAM="${__PATH#*"${__MATC}"}"	# file name
		__FNAM="${__FNAM#*/}"
		__PATH="${__DIRS}"
		# ---------------------------------------------------------------------
#		__RTCD=0
		__RSLT=""
		if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
			__OPTN=("${_OPTN_WGET[@]}" "--server-response" "--output-document=-" "${__PATH:?}")
			__RSLT="$(LANG=C wget "${__OPTN[@]}" 2>&1 || true)"
		else
			__OPTN=("${_OPTN_CURL[@]}" "--header" "${__PATH:?}")
			__RSLT="$(LANG=C curl "${__OPTN[@]}" 2>&1 || true)"
		fi
		# ---------------------------------------------------------------------
		__RSLT="${__RSLT//$'\r\n'/$'\n'}"	# crlf -> lf
		__RSLT="${__RSLT//$'\r'/$'\n'}"		# cr   -> lf
		__RSLT="${__RSLT//></>\n<}"
		__RSLT="${__RSLT#"${__RSLT%%[!"${IFS}"]*}"}"	# ltrim
		__RSLT="${__RSLT%"${__RSLT##*[!"${IFS}"]}"}"	# rtrim
		IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
		for I in "${!__LIST[@]}"
		do
			__LINE="${__LIST[I],,}"
			__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
			__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
			__FILD="${__LINE%% *}"
			__VALU="${__LINE#* }"
			case "${__FILD%% *}" in
				http/*         ) __CODE="${__VALU%% *}";;
				content-length:) __LENG="${__VALU}";;
				last-modified: ) __LMOD="$(TZ=UTC date -d "${__VALU}" "+%Y-%m-%d%%20%H:%M:%S%z")";;
				*              ) ;;
			esac
		done
		# ---------------------------------------------------------------------
		case "${__CODE}" in				# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			1??) ;;						# 1xx (Informational)
			2??)						# 2xx (Successful)
				IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
				__PATH="$(printf "%s\n" "${__LIST[@]//%20/ }" | sed -ne 's%^.*<a href="'"${__MATC}"'/*">\(.*\)</a>.*$%\1%gp' | sort -rVu | head -n 1 || true)"
				__PATH="${__PATH:+"${__DIRS%%/}/${__PATH%%/}${__FNAM:+/"${__FNAM##/}"}"}"
				;;
			3??) ;;						# 3xx (Redirection)
			4??) ;;						# 4xx (Client Error)
			5??) ;;						# 5xx (Server Error)
			*  ) ;;						# xxx (Unknown Code)
		esac
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${__PATH}"
#	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web information
#   n-ref :   $1   : return value : path tmstamp size status contents
#   input :   $2   : url
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_info() {
#	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __WORK=""				# work variables

	fnGetWeb_address "__WORK" "${2:?}"
	fnGetWeb_header "${1}" "${__WORK}"
}

# -----------------------------------------------------------------------------
# descript: get web status message
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_status() {
	case "${1:?}" in					# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
		100) echo -n "$1: Continue";;
		101) echo -n "$1: Switching Protocols";;
		1??) echo -n "$1: (Informational): The request was received, continuing process";;
		200) echo -n "$1: OK";;
		201) echo -n "$1: Created";;
		202) echo -n "$1: Accepted";;
		203) echo -n "$1: Non-Authoritative Information";;
		204) echo -n "$1: No Content";;
		205) echo -n "$1: Reset Content";;
		206) echo -n "$1: Partial Content";;
		2??) echo -n "$1: (Successful): The request was successfully received, understood, and accepted";;
		300) echo -n "$1: Multiple Choices";;
		301) echo -n "$1: Moved Permanently";;
		302) echo -n "$1: Found";;
		303) echo -n "$1: See Other";;
		304) echo -n "$1: Not Modified";;
		305) echo -n "$1: Use Proxy";;
		306) echo -n "$1: (Unused)";;
		307) echo -n "$1: Temporary Redirect";;
		308) echo -n "$1: Permanent Redirect";;
		3??) echo -n "$1: (Redirection): Further action needs to be taken in order to complete the request";;
		400) echo -n "$1: Bad Request";;
		401) echo -n "$1: Unauthorized";;
		402) echo -n "$1: Payment Required";;
		403) echo -n "$1: Forbidden";;
		404) echo -n "$1: Not Found";;
		405) echo -n "$1: Method Not Allowed";;
		406) echo -n "$1: Not Acceptable";;
		407) echo -n "$1: Proxy Authentication Required";;
		408) echo -n "$1: Request Timeout";;
		409) echo -n "$1: Conflict";;
		410) echo -n "$1: Gone";;
		411) echo -n "$1: Length Required";;
		412) echo -n "$1: Precondition Failed";;
		413) echo -n "$1: Content Too Large";;
		414) echo -n "$1: URI Too Long";;
		415) echo -n "$1: Unsupported Media Type";;
		416) echo -n "$1: Range Not Satisfiable";;
		417) echo -n "$1: Expectation Failed";;
		418) echo -n "$1: (Unused)";;
		421) echo -n "$1: Misdirected Request";;
		422) echo -n "$1: Unprocessable Content";;
		426) echo -n "$1: Upgrade Required";;
		4??) echo -n "$1: (Client Error): The request contains bad syntax or cannot be fulfilled";;
		500) echo -n "$1: Internal Server Error";;
		501) echo -n "$1: Not Implemented";;
		502) echo -n "$1: Bad Gateway";;
		503) echo -n "$1: Service Unavailable";;
		504) echo -n "$1: Gateway Timeout";;
		505) echo -n "$1: HTTP Version Not Supported";;
		5??) echo -n "$1: (Server Error): The server failed to fulfill an apparently valid request";;
		*  ) echo -n "$1: (Unknown Code)";;
	esac
}

# *** function section (sub functions) ****************************************

# -----------------------------------------------------------------------------
# descript: initialization
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnInitialization() {
:
}

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

# --- debug out parameter -----------------------------------------------------
function fnDebug_parameter() {
	declare       _VARS_CHAR="_"		# variable initial letter
	declare       _VARS_NAME=""			#          name
	declare       _VARS_VALU=""			#          value

#	if [[ -z "${_DBGS_FLAG:-}" ]]; then
#		return
#	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for _VARS_CHAR in {A..Z} {a..z} "_"
#	do
		for _VARS_NAME in $(eval printf "%q\\\n"  \$\{\!"${_VARS_CHAR}"\@\})
		do
			_VARS_NAME="${_VARS_NAME#\'}"
			_VARS_NAME="${_VARS_NAME%\'}"
			if [[ -z "${_VARS_NAME}" ]]; then
				continue
			fi
			case "${_VARS_NAME}" in
				_TEXT_*    | \
				_VARS_CHAR | \
				_VARS_NAME | \
				_VARS_VALU ) continue;;
				*) ;;
			esac
			_VARS_VALU="$(eval printf "%q" \$\{"${_VARS_NAME}":-\})"
			printf "%s=[%s]\n" "${_VARS_NAME}" "${_VARS_VALU/#\'\'/}"
		done
#	done
}

# --- help --------------------------------------------------------------------
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ${_PROG_PATH} [command (options)]
		
		  debug print and test
		    debug [func|text|parm]
		      func              : function test
		      text              : text color test
		      parm              : display of main internal parameters
_EOT_
}

# === main ====================================================================

function fnMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference

	# --- check the execution user --------------------------------------------
#	if [[ "${_USER_NAME}" != "root" ]]; then
#		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
#		exit 1
#	fi

	# --- get command line ----------------------------------------------------
	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			help    ) shift; fnHelp; exit 0;;
			*       ) shift;;
		esac
	done

	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	fnInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			help    ) shift; fnHelp; break;;
			debug   )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						func) shift; fnDebug_function;;
						text) shift; fnDebug_color;;
						parm) shift; fnDebug_parameter;;
						*   ) break;;
					esac
				done
				;;
			*       ) shift;;
		esac
		_RETN_PARM=("$@")
		IFS="${_COMD_IFS:-}"
		set -f -- "${_RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
	done

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
}

# *** main processing section *************************************************
	fnMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
