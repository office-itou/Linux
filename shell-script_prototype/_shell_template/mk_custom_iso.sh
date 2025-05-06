#!/bin/bash

###############################################################################
##
##	pxeboot configuration shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/04/13
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/04/13 000.0000 J.Itou         first release
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

# shellcheck disable=SC2317
function funcTrap() {
	declare       _PATH=""
	declare -i    I=0
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		_PATH="${_LIST_RMOV[I]}"
		if [[ -e "${_PATH}" ]] && mountpoint --quiet "${_PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${_PATH}" 1>&2
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		fi
	done
	if [[ -e "${_DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${_DIRS_TEMP}" 1>&2
		while read -r _PATH
		do
			printf "[%s]: umount \"%s\"\n" "-" "${_PATH}" 1>&2
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		done < <(grep "${_DIRS_TEMP:?}" /proc/mounts | cut -d ' ' -f 2 | sort -rV || true)
		rm -rf "${_DIRS_TEMP:?}"
	fi
}

	trap funcTrap EXIT

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
			"fdisk" \
			"file" \
			"initramfs-tools-core" \
			"isolinux" \
			"isomd5sum" \
			"procps" \
			"xorriso" \
			"xxd" \
			"cpio" \
			"gzip" \
			"zstd" \
			"xz-utils" \
			"lz4" \
			"bzip2" \
			"lzop" \
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

	# --- shared directory parameter ------------------------------------------
	declare       _DIRS_TOPS=""			# top of shared directory
	declare       _DIRS_HGFS=""			# vmware shared
	declare       _DIRS_HTML=""			# html contents
	declare       _DIRS_SAMB=""			# samba shared
	declare       _DIRS_TFTP=""			# tftp contents
	declare       _DIRS_USER=""			# user file

	# --- shared of user file -------------------------------------------------
	declare       _DIRS_SHAR=""			# shared of user file
	declare       _DIRS_CONF=""			# configuration file
	declare       _DIRS_DATA=""			# data file
	declare       _DIRS_KEYS=""			# keyring file
	declare       _DIRS_TMPL=""			# templates for various configuration files
	declare       _DIRS_SHEL=""			# shell script file
	declare       _DIRS_IMGS=""			# iso file extraction destination
	declare       _DIRS_ISOS=""			# iso file
	declare       _DIRS_LOAD=""			# load module
	declare       _DIRS_RMAK=""			# remake file

	# --- common data file ----------------------------------------------------
	declare       _PATH_CONF=""			# common configuration file
	declare       _PATH_MDIA=""			# media data file

	# --- pre-configuration file templates ------------------------------------
	declare       _CONF_KICK=""			# for rhel
	declare       _CONF_CLUD=""			# for ubuntu cloud-init
	declare       _CONF_SEDD=""			# for debian
	declare       _CONF_SEDU=""			# for ubuntu
	declare       _CONF_YAST=""			# for opensuse

	# --- shell script --------------------------------------------------------
	declare       _SHEL_ERLY=""			# shell commands to run early
	declare       _SHEL_LATE=""			# shell commands to run late
	declare       _SHEL_PART=""			# shell commands to run after partition
	declare       _SHEL_RUNS=""			# shell commands to run preseed/run

# --- tftp / web server network parameter -------------------------------------
	declare       _SRVR_PROT="http"		# server connection protocol (http or tftp)
	declare       _SRVR_NICS=""			# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
	declare       _SRVR_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
	declare       _SRVR_ADDR=""			# IPv4 address          (ex. 192.168.1.11)
	declare       _SRVR_CIDR=""			# IPv4 cidr             (ex. 24)
	declare       _SRVR_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0)
	declare       _SRVR_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
	declare       _SRVR_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _SRVR_UADR=""			# IPv4 address up       (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
	declare       _NWRK_HOST=""			# hostname              (ex. sv-server)
	declare       _NWRK_WGRP=""			# domain                (ex. workgroup)
	declare       _NICS_NAME=""			# network device name   (ex. ens160)
	declare       _NICS_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR=""			# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR=""			# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
#	declare       _IPV4_UADR=""			# IPv4 address up       (ex. 192.168.1)
#	declare       _NMAN_NAME=""			# network manager name  (nm_config, ifupdown, loopback)

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT=""			# timeout
	declare       _MENU_RESO=""			# resolution
	declare       _MENU_DPTH=""			# colors
	declare       _MENU_MODE=""			# screen mode (vga=nnn)

	# --- directory list ------------------------------------------------------
	declare -a    _LIST_DIRS=()

	# --- symbolic link list --------------------------------------------------
	declare -a    _LIST_LINK=()

	# --- autoinstall configuration file --------------------------------------
	declare       _AUTO_INST=""

	# --- initial ram disk of mini.iso including preseed ----------------------
	declare       _MINI_IRAM=""

	# --- list data -----------------------------------------------------------
	declare -a    _LIST_MDIA=()			# media information

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

# === <network> ===============================================================

# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)

# --- IPv4 netmask conversion -------------------------------------------------
# shellcheck disable=SC2317
function funcIPv4GetNetmask() {
	declare       _OCT1=""				# octets
	declare       _OCT2=""				# "
	declare       _OCT3=""				# "
	declare       _OCT4=""				# "
	declare -i    _LOOP=0				# work variables
	declare -i    _CALC=0				# "
	# -------------------------------------------------------------------------
	_OCT1="$(echo "${1:?}." | cut -d '.' -f 1)"
	_OCT2="$(echo "${1}."   | cut -d '.' -f 2)"
	_OCT3="$(echo "${1}."   | cut -d '.' -f 3)"
	_OCT4="$(echo "${1}."   | cut -d '.' -f 4)"
	# -------------------------------------------------------------------------
	if [[ -n "${_OCT1}" ]] && [[ -n "${_OCT2}" ]] && [[ -n "${_OCT3}" ]] && [[ -n "${_OCT4}" ]]; then
		# --- netmask -> cidr -------------------------------------------------
		_CALC=0
		for _LOOP in "${_OCT1}" "${_OCT2}" "${_OCT3}" "${_OCT4}"
		do
			case "${_LOOP}" in
				  0) _CALC=$((_CALC+0));;
				128) _CALC=$((_CALC+1));;
				192) _CALC=$((_CALC+2));;
				224) _CALC=$((_CALC+3));;
				240) _CALC=$((_CALC+4));;
				248) _CALC=$((_CALC+5));;
				252) _CALC=$((_CALC+6));;
				254) _CALC=$((_CALC+7));;
				255) _CALC=$((_CALC+8));;
				*  )                 ;;
			esac
		done
		printf '%d' "${_CALC}"
	else
		# --- cidr -> netmask -------------------------------------------------
		_LOOP=$((32-${1:?}))
		_CALC=1
		while [[ "${_LOOP}" -gt 0 ]]
		do
			_LOOP=$((_LOOP-1))
			_CALC=$((_CALC*2))
		done
		_CALC="$((0xFFFFFFFF ^ (_CALC-1)))"
		printf '%d.%d.%d.%d'              \
		    $(( _CALC >> 24        )) \
		    $(((_CALC >> 16) & 0xFF)) \
		    $(((_CALC >>  8) & 0xFF)) \
		    $(( _CALC        & 0xFF))
	fi
}

# --- IPv6 full address -------------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetFullAddr() {
	declare -r    _FSEP="${1//[^:]/}"
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	# -------------------------------------------------------------------------
	_WORK="$(printf "%$((7-${#_FSEP}))s" "")"
	_WORK="${1/::/::${_WORK// /:}}"
	IFS= mapfile -d ':' -t _ARRY < <(echo -n "${_WORK/%:/::}")
	printf ':%04x' "${_ARRY[@]/#/0x0}" | cut -c 2-
}

# --- IPv6 reverse address ----------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetRevAddr() {
	echo "${1//:/}" | \
	    awk '{
	        for(i=length();i>1;i--)              \
	            printf("%c.", substr($0,i,1));   \
	            printf("%c" , substr($0,1,1));}'
}

# === <media> =================================================================

# --- unit conversion ---------------------------------------------------------
# shellcheck disable=SC2317
function funcUnit_conversion() {
	declare -r -a _UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC=0
	declare       _WORK=""				# work variables
	declare -i    I=0
	# --- is numeric ----------------------------------------------------------
	if [[ ! ${1:?} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		printf "Error [%s]" "$1"
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
		_CALC=$((1024**I))
		if [[ "$1" -ge "${_CALC}" ]]; then
			_WORK="$(echo "$1" "${_CALC}" | awk '{printf("%.1f", $1/$2)}')"
			printf "%s %s" "${_WORK}" "${_UNIT[I]}"
			return
		fi
	done
	echo -n "$1"
}

# --- get volume id -----------------------------------------------------------
# shellcheck disable=SC2317
function funcGetVolID() {
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	_VLID="$(LANG=C file -L "${1:?}")"
	_VLID="${_VLID#*: }"
	_WORK="${_VLID%%\'*}"
	_VLID="${_VLID#"${_WORK}"}"
	_WORK="${_VLID##*\'}"
	_VLID="${_VLID%"${_WORK}"}"
	echo -n "${_WORK}"
}

# --- get file information ----------------------------------------------------
# shellcheck disable=SC2317
function funcGetFileinfo() {
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	# -------------------------------------------------------------------------
	_ARRY=()
	if [[ -n "${1:-}" ]]; then
		_WORK="$(realpath "${1:?}")"		# full path
		_FNAM="${_WORK##*/}"
		_DIRS="${_WORK%"${_FNAM}"}"
		_WORK="$(LANG=C find "${_DIRS:-.}" -name "${_FNAM}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%S+%TZ %s")"
		if [[ -n "${_WORK}" ]]; then
			read -r -a _ARRY < <(echo "${_WORK}")
#			_ARRY[0]					# full path
#			_ARRY[1]					# time stamp
#			_ARRY[2]					# size
			_VLID="$(funcGetVolID "${_ARRY[0]}")"
			_ARRY+=("${_VLID:-''}")		# volume id
		fi
	fi
	echo -n "${_ARRY[*]}"
}

# --- distro to efi image file name -------------------------------------------
# shellcheck disable=SC2317
function funcDistro2efi() {
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	case "${1:?}" in
		debian      | \
		ubuntu      ) _WORK="boot/grub/efi.img";;
		fedora      | \
		centos      | \
		almalinux   | \
		rockylinux  | \
		miraclelinux) _WORK="images/efiboot.img";;
		opensuse    ) _WORK="boot/x86_64/efi";;
		*           ) ;;
	esac
	echo -n "${_WORK}"
}

# === <initrd> ================================================================

# --- Extract a compressed cpio _TGET_FILE ------------------------------------
# shellcheck disable=SC2317
funcXcpio() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination directory
	shift 2

	# shellcheck disable=SC2312
	  if gzip -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${_TGET_FILE}"
	elif zstd -q -c -t "${_TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${_TGET_FILE}"
	elif xzcat -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${_TGET_FILE}"
	elif lz4cat -t <   "${_TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${_TGET_FILE}"
	elif bzip2 -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${_TGET_FILE}"
	elif lzop -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${_TGET_FILE}"
	fi | (
		if [[ -n "${_DIRS_DEST}" ]]; then
			mkdir -p -- "${_DIRS_DEST}"
			# shellcheck disable=SC2312
			cd -- "${_DIRS_DEST}" || exit
		fi
		cpio "$@"
	)
}

# --- Read bytes out of a file, checking that they are valid hex digits -------
# shellcheck disable=SC2317
funcReadhex() {
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# --- Check for a zero byte in a file -----------------------------------------
# shellcheck disable=SC2317
funcCheckzero() {
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# --- Split an initramfs into _TGET_FILEs and call funcXcpio on each ----------
# shellcheck disable=SC2317
funcSplit_initramfs() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination directory
	declare -r -a _OPTS=("--preserve-modification-time" "--no-absolute-filenames" "--quiet")
	declare -i    _CONT=0				# count
	declare -i    _PSTR=0				# start point
	declare -i    _PEND=0				# end point
	declare       _MGIC=""				# magic word
	declare       _DSUB=""				# sub directory
	declare       _SARC=""				# sub archive

	while true
	do
		_PEND="${_PSTR}"
		while true
		do
			# shellcheck disable=SC2310
			if funcCheckzero "${_TGET_FILE}" "${_PEND}"; then
				_PEND=$((_PEND + 4))
				# shellcheck disable=SC2310
				while funcCheckzero "${_TGET_FILE}" "${_PEND}"
				do
					_PEND=$((_PEND + 4))
				done
				break
			fi
			# shellcheck disable=SC2310
			_MGIC="$(funcReadhex "${_TGET_FILE}" "${_PEND}" "6")" || break
			test "${_MGIC}" = "070701" || test "${_MGIC}" = "070702" || break
			_NSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 94))" "8")
			_FSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 54))" "8")
			_PEND=$((_PEND + 110))
			_PEND=$(((_PEND + _NSIZ + 3) & ~3))
			_PEND=$(((_PEND + _FSIZ + 3) & ~3))
		done
		if [[ "${_PEND}" -eq "${_PSTR}" ]]; then
			break
		fi
		_CONT=$((_CONT + 1))
		if [[ "${_CONT}" -eq 1 ]]; then
			_DSUB="early"
		else
			_DSUB="early${_CONT}"
		fi
		# shellcheck disable=SC2312
		dd if="${_TGET_FILE}" skip="${_PSTR}" count="$((_PEND - _PSTR))" iflag=skip_bytes 2> /dev/null |
		(
			if [[ -n "${_DIRS_DEST}" ]]; then
				mkdir -p -- "${_DIRS_DEST}/${_DSUB}"
				# shellcheck disable=SC2312
				cd -- "${_DIRS_DEST}/${_DSUB}" || exit
			fi
			cpio -i "${_OPTS[@]}"
		)
		_PSTR="${_PEND}"
	done
	if [[ "${_PEND}" -gt 0 ]]; then
		_SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${_SARC%/*}"
		dd if="${_TGET_FILE}" skip="${_PEND}" iflag=skip_bytes 2> /dev/null > "${_SARC}"
		funcXcpio "${_SARC}" "${_DIRS_DEST:+${_DIRS_DEST}/main}" -i "${_OPTS[@]}"
		rm -f "${_SARC:?}"
	else
		funcXcpio "${_TGET_FILE}" "${_DIRS_DEST}" -i "${_OPTS[@]}"
	fi
}

# === <mkiso> =================================================================

# --- create iso image --------------------------------------------------------
# shellcheck disable=SC2317
function funcCreate_iso() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_OUTP="${2:?}"	# output path
	shift 2
	declare -r -a _OPTN_XORR=("$@")		# xorrisofs options
	declare -a    _LIST=()				# data list
	declare       _PATH=""				# file name
	              _PATH="$(mktemp -q "${TMPDIR:-/tmp}/${_PATH_OUTP##*/}.XXXXXX")"
	readonly      _PATH

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- create iso image ----------------------------------------------------
	pushd "${_DIRS_TGET}" > /dev/null || exit
	if ! nice -n "${_NICE_VALU:-19}" xorrisofs "${_OPTN_XORR[@]}" -output "${_PATH}" . > /dev/null 2>&1; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [xorriso]" "${_PATH_OUTP##*/}" 1>&2
	else
		if ! cp --preserve=timestamps "${_PATH}" "${_PATH_OUTP}"; then
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [cp]" "${_PATH_OUTP##*/}" 1>&2
		else
			IFS= mapfile -d ' ' -t _LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${_PATH_OUTP}" || true)
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "complete" "${_PATH_OUTP##*/} (${_LIST[4]})" 1>&2
		fi
	fi
	rm -f "${_PATH:?}"
	popd > /dev/null || exit
}

# === <web_tools> =============================================================

# --- get web information -----------------------------------------------------
# shellcheck disable=SC2317
function funcGetWebinfo() {
	declare       _WEBS_ADDR="${1:?}"	# web address
	declare       _FILD=""				# field name
	declare       _VALU=""				# value
	declare       _CODE=""				# status codes
	declare       _LENG=""				# content-length
	declare       _LMOD=""				# last-modified
	declare       _LINE=""				# work variables
	declare -a    _LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    R=0					# work variables

	_LENG=""
	_LMOD=""
	for ((R=0; R<3; R++))
	do
		if ! _LINE="$(wget --trust-server-names --spider --server-response --output-document=- "${_WEBS_ADDR}" 2>&1)"; then
			continue
		fi
		IFS= mapfile -d $'\n' -t _LIST < <(echo "${_LINE}")
		for I in "${!_LIST[@]}"
		do
			_LINE="${_LIST[I],,}"
			_LINE="${_LINE#"${_LINE%%[!"${IFS}"]*}"}"	# ltrim
			_LINE="${_LINE%"${_LINE##*[!"${IFS}"]}"}"	# rtrim
			_FILD="${_LINE%% *}"
			_VALU="${_LINE#* }"
			case "${_FILD%% *}" in
				http/*         ) _CODE="${_VALU%% *}";;
				content-length:) _LENG="${_VALU}";;
				last-modified: ) _LMOD="$(TZ=UTC date -d "${_VALU}" "+%Y/%m/%d%%20%H:%M:%S+%Z")";;
				*) ;;
			esac
		done
		case "${_CODE}" in				# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			1??) break            ;;	# 1xx (Informational): The request was received, continuing process
			2??) break            ;;	# 2xx (Successful)   : The request was successfully received, understood, and accepted
			3??) break            ;;	# 3xx (Redirection)  : Further action needs to be taken in order to complete the request
			4??) sleep 3; continue;;	# 4xx (Client Error) : The request contains bad syntax or cannot be fulfilled
			5??) sleep 3; continue;;	# 5xx (Server Error) : The server failed to fulfill an apparently valid request
			*  ) sleep 3; continue;;	#      Unknown Error
		esac
	done
	echo -n "${_WEBS_ADDR##*/} ${_LMOD} ${_LENG} ${_CODE}"
}

# *** function section (sub functions) ****************************************

# === <common> ================================================================

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       _PATH=""				# file name
	declare       _WORK=""				# work variables
	declare       _LINE=""				# work variable
	declare       _NAME=""				# variable name
	declare       _VALU=""				# value

	# --- common configuration file -------------------------------------------
	              _PATH_CONF="/srv/user/share/conf/_data/common.cfg"
	for _PATH in \
		"${PWD:+"${PWD}/${_PATH_CONF##*/}"}" \
		"${_PATH_CONF}"
	do
		if [[ -f "${_PATH}" ]]; then
			_PATH_CONF="${_PATH}"
			break
		fi
	done
	readonly      _PATH_CONF

	# --- default value when empty --------------------------------------------
	_DIRS_TOPS="${_DIRS_TOPS:-/srv}"
	_DIRS_HGFS="${_DIRS_HGFS:-:_DIRS_TOPS_:/hgfs}"
	_DIRS_HTML="${_DIRS_HTML:-:_DIRS_TOPS_:/http/html}"
	_DIRS_SAMB="${_DIRS_SAMB:-:_DIRS_TOPS_:/samba}"
	_DIRS_TFTP="${_DIRS_TFTP:-:_DIRS_TOPS_:/tftp}"
	_DIRS_USER="${_DIRS_USER:-:_DIRS_TOPS_:/user}"
	_DIRS_SHAR="${_DIRS_SHAR:-:_DIRS_USER_:/share}"
	_DIRS_CONF="${_DIRS_CONF:-:_DIRS_SHAR_:/conf}"
	_DIRS_DATA="${_DIRS_DATA:-:_DIRS_CONF_:/_data}"
	_DIRS_KEYS="${_DIRS_KEYS:-:_DIRS_CONF_:/_keyring}"
	_DIRS_TMPL="${_DIRS_TMPL:-:_DIRS_CONF_:/_template}"
	_DIRS_SHEL="${_DIRS_SHEL:-:_DIRS_CONF_:/script}"
	_DIRS_IMGS="${_DIRS_IMGS:-:_DIRS_SHAR_:/imgs}"
	_DIRS_ISOS="${_DIRS_ISOS:-:_DIRS_SHAR_:/isos}"
	_DIRS_LOAD="${_DIRS_LOAD:-:_DIRS_SHAR_:/load}"
	_DIRS_RMAK="${_DIRS_RMAK:-:_DIRS_SHAR_:/rmak}"
#	_PATH_CONF="${_PATH_CONF:-:_DIRS_DATA_:/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-:_DIRS_DATA_:/media.dat}"
	_CONF_KICK="${_CONF_KICK:-:_DIRS_TMPL_:/kickstart_rhel.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-:_DIRS_TMPL_:/user-data_ubuntu}"
	_CONF_SEDD="${_CONF_SEDD:-:_DIRS_TMPL_:/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-:_DIRS_TMPL_:/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-:_DIRS_TMPL_:/yast_opensuse.xml}"
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/autoinst_cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/autoinst_cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/autoinst_cmd_part.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/autoinst_cmd_run.sh}"
	_SRVR_PROT="${_SRVR_PROT:-http}"
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}' || true)"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}' || true)"}"
		_WORK="$(ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null)"
		if echo "${_WORK}" | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}' || true)"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(funcIPv4GetNetmask "${_SRVR_CIDR}")"}"
	_SRVR_GWAY="${_SRVR_GWAY:-"$(LANG=C ip -4 -brief route list match default | awk '{print $3;}' || true)"}"
	if command -v resolvectl > /dev/null 2>&1; then
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/^Global:/             s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/('"${_SRVR_NICS}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
	fi
	_SRVR_NSVR="${_SRVR_NSVR:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /etc/resolv.conf)"}"
	if [[ "${_SRVR_NSVR:-}" = "127.0.0.53" ]]; then
		_SRVR_NSVR="$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /run/systemd/resolve/resolv.conf)"
	fi
	_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
	_NWRK_HOST="${_NWRK_HOST:-sv-:_DISTRO_:}"
	_NWRK_WGRP="${_NWRK_WGRP:-workgroup}"
	_NICS_NAME="${_NICS_NAME:-"${_SRVR_NICS}"}"
	_NICS_MADR="${_NICS_MADR:-"${_SRVR_MADR}"}"
	_IPV4_ADDR="${_IPV4_ADDR:-"${_SRVR_UADR}".1}"
	_IPV4_CIDR="${_IPV4_CIDR:-"${_SRVR_CIDR}"}"
	_IPV4_MASK="${_IPV4_MASK:-"$(funcIPv4GetNetmask "${_IPV4_CIDR}")"}"
	_IPV4_GWAY="${_IPV4_GWAY:-"${_SRVR_GWAY}"}"
	_IPV4_NSVR="${_IPV4_NSVR:-"${_SRVR_NSVR}"}"
	_IPV4_UADR="${_IPV4_UADR:-"${_SRVR_UADR}"}"
#	_NMAN_NAME="${_NMAN_NAME:-""}"
	_MENU_TOUT="${_MENU_TOUT:-5}"
	_MENU_RESO="${_MENU_RESO:-1024x768}"
	_MENU_DPTH="${_MENU_DPTH:-16}"
	_MENU_MODE="${_MENU_MODE:-791}"

	# --- gets the setting value ----------------------------------------------
	while read -r _LINE
	do
		_LINE="${_LINE%%#*}"
		_LINE="${_LINE//["${IFS}"]/ }"
		_LINE="${_LINE#"${_LINE%%[!"${IFS}"]*}"}"	# ltrim
		_LINE="${_LINE%"${_LINE##*[!"${IFS}"]}"}"	# rtrim
		_NAME="${_LINE%%=*}"
		_VALU="${_LINE#*=}"
		_VALU="${_VALU#\"}"
		_VALU="${_VALU%\"}"
		case "${_NAME:-}" in
			DIRS_TOPS) _DIRS_TOPS="${_VALU:-"${_DIRS_TOPS:-}"}";;
			DIRS_HGFS) _DIRS_HGFS="${_VALU:-"${_DIRS_HGFS:-}"}";;
			DIRS_HTML) _DIRS_HTML="${_VALU:-"${_DIRS_HTML:-}"}";;
			DIRS_SAMB) _DIRS_SAMB="${_VALU:-"${_DIRS_SAMB:-}"}";;
			DIRS_TFTP) _DIRS_TFTP="${_VALU:-"${_DIRS_TFTP:-}"}";;
			DIRS_USER) _DIRS_USER="${_VALU:-"${_DIRS_USER:-}"}";;
			DIRS_SHAR) _DIRS_SHAR="${_VALU:-"${_DIRS_SHAR:-}"}";;
			DIRS_CONF) _DIRS_CONF="${_VALU:-"${_DIRS_CONF:-}"}";;
			DIRS_DATA) _DIRS_DATA="${_VALU:-"${_DIRS_DATA:-}"}";;
			DIRS_KEYS) _DIRS_KEYS="${_VALU:-"${_DIRS_KEYS:-}"}";;
			DIRS_TMPL) _DIRS_TMPL="${_VALU:-"${_DIRS_TMPL:-}"}";;
			DIRS_SHEL) _DIRS_SHEL="${_VALU:-"${_DIRS_SHEL:-}"}";;
			DIRS_IMGS) _DIRS_IMGS="${_VALU:-"${_DIRS_IMGS:-}"}";;
			DIRS_ISOS) _DIRS_ISOS="${_VALU:-"${_DIRS_ISOS:-}"}";;
			DIRS_LOAD) _DIRS_LOAD="${_VALU:-"${_DIRS_LOAD:-}"}";;
			DIRS_RMAK) _DIRS_RMAK="${_VALU:-"${_DIRS_RMAK:-}"}";;
#			PATH_CONF) _PATH_CONF="${_VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${_VALU:-"${_PATH_MDIA:-}"}";;
			CONF_KICK) _CONF_KICK="${_VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${_VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${_VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${_VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${_VALU:-"${_CONF_YAST:-}"}";;
			SHEL_ERLY) _SHEL_ERLY="${_VALU:-"${_SHEL_ERLY:-}"}";;
			SHEL_LATE) _SHEL_LATE="${_VALU:-"${_SHEL_LATE:-}"}";;
			SHEL_PART) _SHEL_PART="${_VALU:-"${_SHEL_PART:-}"}";;
			SHEL_RUNS) _SHEL_RUNS="${_VALU:-"${_SHEL_RUNS:-}"}";;
			SRVR_PROT) _SRVR_PROT="${_VALU:-"${_SRVR_PROT:-}"}";;
			SRVR_NICS) _SRVR_NICS="${_VALU:-"${_SRVR_NICS:-}"}";;
			SRVR_MADR) _SRVR_MADR="${_VALU:-"${_SRVR_MADR:-}"}";;
			SRVR_ADDR) _SRVR_ADDR="${_VALU:-"${_SRVR_ADDR:-}"}";;
			SRVR_CIDR) _SRVR_CIDR="${_VALU:-"${_SRVR_CIDR:-}"}";;
			SRVR_MASK) _SRVR_MASK="${_VALU:-"${_SRVR_MASK:-}"}";;
			SRVR_GWAY) _SRVR_GWAY="${_VALU:-"${_SRVR_GWAY:-}"}";;
			SRVR_NSVR) _SRVR_NSVR="${_VALU:-"${_SRVR_NSVR:-}"}";;
			SRVR_UADR) _SRVR_UADR="${_VALU:-"${_SRVR_UADR:-}"}";;
			NWRK_HOST) _NWRK_HOST="${_VALU:-"${_NWRK_HOST:-}"}";;
			NWRK_WGRP) _NWRK_WGRP="${_VALU:-"${_NWRK_WGRP:-}"}";;
			NICS_NAME) _NICS_NAME="${_VALU:-"${_NICS_NAME:-}"}";;
#			NICS_MADR) _NICS_MADR="${_VALU:-"${_NICS_MADR:-}"}";;
			IPV4_ADDR) _IPV4_ADDR="${_VALU:-"${_IPV4_ADDR:-}"}";;
			IPV4_CIDR) _IPV4_CIDR="${_VALU:-"${_IPV4_CIDR:-}"}";;
			IPV4_MASK) _IPV4_MASK="${_VALU:-"${_IPV4_MASK:-}"}";;
			IPV4_GWAY) _IPV4_GWAY="${_VALU:-"${_IPV4_GWAY:-}"}";;
			IPV4_NSVR) _IPV4_NSVR="${_VALU:-"${_IPV4_NSVR:-}"}";;
#			IPV4_UADR) _IPV4_UADR="${_VALU:-"${_IPV4_UADR:-}"}";;
#			NMAN_NAME) _NMAN_NAME="${_VALU:-"${_NMAN_NAME:-}"}";;
			MENU_TOUT) _MENU_TOUT="${_VALU:-"${_MENU_TOUT:-}"}";;
			MENU_RESO) _MENU_RESO="${_VALU:-"${_MENU_RESO:-}"}";;
			MENU_DPTH) _MENU_DPTH="${_VALU:-"${_MENU_DPTH:-}"}";;
			MENU_MODE) _MENU_MODE="${_VALU:-"${_MENU_MODE:-}"}";;
			*        ) ;;
		esac
	done < <(cat "${_PATH_CONF:-}" 2> /dev/null || true)

	# --- variable substitution -----------------------------------------------
	_DIRS_TOPS="${_DIRS_TOPS:?}"
	_DIRS_HGFS="${_DIRS_HGFS//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_HTML="${_DIRS_HTML//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_SAMB="${_DIRS_SAMB//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_TFTP="${_DIRS_TFTP//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_USER="${_DIRS_USER//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_SHAR="${_DIRS_SHAR//:_DIRS_USER_:/"${_DIRS_USER}"}"
	_DIRS_CONF="${_DIRS_CONF//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_DATA="${_DIRS_DATA//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_KEYS="${_DIRS_KEYS//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_TMPL="${_DIRS_TMPL//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_SHEL="${_DIRS_SHEL//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_IMGS="${_DIRS_IMGS//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_ISOS="${_DIRS_ISOS//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_LOAD="${_DIRS_LOAD//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_RMAK="${_DIRS_RMAK//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
#	_PATH_CONF="${_PATH_CONF//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_MDIA="${_PATH_MDIA//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_CONF_KICK="${_CONF_KICK//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_CLUD="${_CONF_CLUD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDD="${_CONF_SEDD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDU="${_CONF_SEDU//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_YAST="${_CONF_YAST//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_SHEL_ERLY="${_SHEL_ERLY//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_LATE="${_SHEL_LATE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_PART="${_SHEL_PART//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_RUNS="${_SHEL_RUNS//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
#	_SRVR_PROT="${_SRVR_PROT:-}"
#	_SRVR_NICS="${_SRVR_NICS:-}"
#	_SRVR_MADR="${_SRVR_MADR:-}"
#	_SRVR_ADDR="${_SRVR_ADDR:-}"
#	_SRVR_CIDR="${_SRVR_CIDR:-}"
#	_SRVR_MASK="${_SRVR_MASK:-}"
#	_SRVR_GWAY="${_SRVR_GWAY:-}"
#	_SRVR_NSVR="${_SRVR_NSVR:-}"
#	_SRVR_UADR="${_SRVR_UADR:-}"
#	_NWRK_HOST="${_NWRK_HOST:-}"
#	_NWRK_WGRP="${_NWRK_WGRP:-}"
#	_NICS_NAME="${_NICS_NAME:-}"
#	_NICS_MADR="${_NICS_MADR:-}"
	_IPV4_ADDR="${_IPV4_ADDR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_IPV4_CIDR="${_IPV4_CIDR:-}"
#	_IPV4_MASK="${_IPV4_MASK:-}"
	_IPV4_GWAY="${_IPV4_GWAY//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
	_IPV4_NSVR="${_IPV4_NSVR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_IPV4_UADR="${_IPV4_UADR:-}"
#	_NMAN_NAME="${_NMAN_NAME:-}"
#	_MENU_TOUT="${_MENU_TOUT:-}"
#	_MENU_RESO="${_MENU_RESO:-}"
#	_MENU_DPTH="${_MENU_DPTH:-}"
#	_MENU_MODE="${_MENU_MODE:-}"

	# --- making variables read-only ------------------------------------------
	readonly      _DIRS_TOPS
	readonly      _DIRS_HGFS
	readonly      _DIRS_HTML
	readonly      _DIRS_SAMB
	readonly      _DIRS_TFTP
	readonly      _DIRS_USER
	readonly      _DIRS_SHAR
	readonly      _DIRS_CONF
	readonly      _DIRS_DATA
	readonly      _DIRS_KEYS
	readonly      _DIRS_TMPL
	readonly      _DIRS_IMGS
	readonly      _DIRS_ISOS
	readonly      _DIRS_LOAD
	readonly      _DIRS_RMAK
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
	readonly      _SRVR_PROT
	readonly      _SRVR_NICS
	readonly      _SRVR_MADR
	readonly      _SRVR_ADDR
	readonly      _SRVR_CIDR
	readonly      _SRVR_MASK
	readonly      _SRVR_GWAY
	readonly      _SRVR_NSVR
	readonly      _SRVR_UADR
	readonly      _NWRK_HOST
	readonly      _NWRK_WGRP
	readonly      _NICS_NAME
	readonly      _IPV4_ADDR
	readonly      _IPV4_CIDR
	readonly      _IPV4_MASK
	readonly      _IPV4_GWAY
	readonly      _IPV4_NSVR
	readonly      _MENU_TOUT
	readonly      _MENU_RESO
	readonly      _MENU_DPTH
	readonly      _MENU_MODE

	# --- directory list ------------------------------------------------------
	_LIST_DIRS=(                                                                                                        \
		"${_DIRS_TOPS:?}"                                                                                               \
		"${_DIRS_HGFS:?}"                                                                                               \
		"${_DIRS_HTML:?}"                                                                                               \
		"${_DIRS_SAMB:?}"/{cifs,data/{adm/{netlogon,profiles},arc,bak,pub,usr},dlna/{movies,others,photos,sounds}}      \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg}       \
		"${_DIRS_USER:?}"                                                                                               \
		"${_DIRS_SHAR:?}"                                                                                               \
		"${_DIRS_CONF:?}"/{autoyast,kickstart,nocloud,preseed,windows}                                                  \
		"${_DIRS_DATA:?}"                                                                                               \
		"${_DIRS_KEYS:?}"                                                                                               \
		"${_DIRS_TMPL:?}"                                                                                               \
		"${_DIRS_SHEL:?}"                                                                                               \
		"${_DIRS_IMGS:?}"                                                                                               \
		"${_DIRS_ISOS:?}"                                                                                               \
		"${_DIRS_LOAD:?}"                                                                                               \
		"${_DIRS_RMAK:?}"                                                                                               \
	)
	readonly      _LIST_DIRS

	# --- symbolic link list --------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	_LIST_LINK=(                                                                                                        \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/menu-bios/syslinux.cfg              ${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"         \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg             ${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"        \
	)
	readonly      _LIST_LINK

	# --- autoinstall configuration file --------------------------------------
	              _AUTO_INST="autoinst.cfg"
	readonly      _AUTO_INST

	# --- initial ram disk of mini.iso including preseed ----------------------
	              _MINI_IRAM="initps.gz"
	readonly      _MINI_IRAM

	# --- get media data ------------------------------------------------------
	funcGet_media_data
}

# --- create common configuration file ----------------------------------------
function funcCreate_conf() {
	declare -r    _TMPL="${_PATH_CONF:?}.template"
	declare       _RNAM=""				# rename path
	declare       _PATH=""				# file name

	# --- check file exists ---------------------------------------------------
	if [[ -f "${_TMPL:?}" ]]; then
		_RNAM="${_TMPL}.$(TZ=UTC find "${_TMPL}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${_TMPL}" "${_RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	for _PATH in $(find "${_TMPL%/*}" -name "${_TMPL##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${_PATH:?}"
	done

	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_TMPL}" || true
		###############################################################################
		##
		##	common configuration file
		##
		###############################################################################
		
		# === for server environments =================================================
		
		# --- shared directory parameter ----------------------------------------------
		DIRS_TOPS="${_DIRS_TOPS:?}"						# top of shared directory
		DIRS_HGFS="${_DIRS_HGFS//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# vmware shared
		DIRS_HTML="${_DIRS_HTML//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"		# html contents
		DIRS_SAMB="${_DIRS_SAMB//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# samba shared
		DIRS_TFTP="${_DIRS_TFTP//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# tftp contents
		DIRS_USER="${_DIRS_USER//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# user file
		
		# --- shared of user file -----------------------------------------------------
		DIRS_SHAR="${_DIRS_SHAR//"${_DIRS_USER}"/:_DIRS_USER_:}"			# shared of user file
		DIRS_CONF="${_DIRS_CONF//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# configuration file
		DIRS_DATA="${_DIRS_DATA//"${_DIRS_CONF}"/:_DIRS_CONF_:}"			# data file
		DIRS_KEYS="${_DIRS_KEYS//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# keyring file
		DIRS_TMPL="${_DIRS_TMPL//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# templates for various configuration files
		DIRS_SHEL="${_DIRS_SHEL//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# shell script file
		DIRS_IMGS="${_DIRS_IMGS//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# iso file extraction destination
		DIRS_ISOS="${_DIRS_ISOS//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# iso file
		DIRS_LOAD="${_DIRS_LOAD//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# load module
		DIRS_RMAK="${_DIRS_RMAK//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# remake file
		
		# --- common data file --------------------------------------------------------
		#PATH_CONF="${_PATH_CONF//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# common configuration file (this file)
		PATH_MDIA="${_PATH_MDIA//"${_DIRS_DATA}"/:_DIRS_DATA_:}"		# media data file
		
		# --- pre-configuration file templates ----------------------------------------
		CONF_KICK="${_CONF_KICK//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for rhel
		CONF_CLUD="${_CONF_CLUD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for ubuntu cloud-init
		CONF_SEDD="${_CONF_SEDD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for debian
		CONF_SEDU="${_CONF_SEDU//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for ubuntu
		CONF_YAST="${_CONF_YAST//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for opensuse
		
		# --- shell script ------------------------------------------------------------
		SHEL_ERLY="${_SHEL_ERLY//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run early
		SHEL_LATE="${_SHEL_LATE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run late
		SHEL_PART="${_SHEL_PART//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run after partition
		SHEL_RUNS="${_SHEL_RUNS//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run preseed/run
		
		# --- tftp / web server network parameter -------------------------------------
		SRVR_PROT="${_SRVR_PROT:-}"						# server connection protocol (http or tftp)
		SRVR_NICS="${_SRVR_NICS:-}"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
		SRVR_MADR="${_SRVR_MADR//[!:]/0}"			# "              mac    (ex. 00:00:00:00:00:00)
		SRVR_ADDR="${_SRVR_ADDR:-}"				# IPv4 address          (ex. 192.168.1.11)
		SRVR_CIDR="${_SRVR_CIDR:-}"							# IPv4 cidr             (ex. 24)
		SRVR_MASK="${_SRVR_MASK:-}"				# IPv4 subnetmask       (ex. 255.255.255.0)
		SRVR_GWAY="${_SRVR_GWAY:-}"				# IPv4 gateway          (ex. 192.168.1.254)
		SRVR_NSVR="${_SRVR_NSVR:-}"				# IPv4 nameserver       (ex. 192.168.1.254)
		
		# === for creations ===========================================================
		
		# --- network parameter -------------------------------------------------------
		NWRK_HOST="${_NWRK_HOST:-}"				# hostname
		NWRK_WGRP="${_NWRK_WGRP:-}"					# domain
		NICS_NAME="${_NICS_NAME:-}"						# network device name
		IPV4_ADDR="${_IPV4_ADDR:-}"					# IPv4 address
		IPV4_CIDR="${_IPV4_CIDR:-}"							# IPv4 cidr (empty to ipv4 subnetmask, if both to 24)
		IPV4_MASK="${_IPV4_MASK:-}"				# IPv4 subnetmask (empty to ipv4 cidr)
		IPV4_GWAY="${_IPV4_GWAY:-}"				# IPv4 gateway
		IPV4_NSVR="${_IPV4_NSVR:-}"				# IPv4 nameserver
		
		# --- menu timeout ------------------------------------------------------------
		MENU_TOUT="${_MENU_TOUT:-}"							# timeout [sec]
		
		# --- menu resolution ---------------------------------------------------------
		MENU_RESO="${_MENU_RESO:-}"					# resolution ([width]x[height])
		MENU_DPTH="${_MENU_DPTH:-}"							# colors
		
		# --- screen mode (vga=nnn) ---------------------------------------------------
		MENU_MODE="${_MENU_MODE:-}"							# mode (vga=nnn)
		
		### eof #######################################################################
_EOT_
}

# --- get media data ----------------------------------------------------------
function funcGet_media_data() {
	declare       _PATH=""				# file name
	declare       _LINE=""				# work variable

	# --- list data -----------------------------------------------------------
	_LIST_MDIA=()
	for _PATH in \
		"${PWD:+"${PWD}/${_PATH_MDIA##*/}"}" \
		"${_PATH_MDIA}"
	do
		if [[ -f "${_PATH}" ]]; then
			while IFS= read -r -d $'\n' _LINE
			do
				_LINE="${_LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
				_LINE="${_LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
				_LINE="${_LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
				_LINE="${_LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
				_LINE="${_LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
				_LINE="${_LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
				_LINE="${_LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
				_LINE="${_LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
				_LINE="${_LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
				_LINE="${_LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
				_LINE="${_LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
				_LINE="${_LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
				_LINE="${_LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
				_LINE="${_LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
				_LINE="${_LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
				_LINE="${_LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
				_LIST_MDIA+=("${_LINE}")
			done < "${_PATH:?}"
			if [[ -n "${_DBGS_FLAG:-}" ]]; then
				printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_MDIA[@]}"
			fi
			break
		fi
	done
}

# --- put media data ----------------------------------------------------------
function funcPut_media_data() {
	declare       _RNAM=""				# rename path
	declare       _LINE=""				# work variable
	declare -a    _LIST=()				# work variable
	declare -i    I=0
	declare -i    J=0

	# --- check file exists ---------------------------------------------------
	if [[ -f "${_PATH_MDIA:?}" ]]; then
		_RNAM="${_PATH_MDIA}.$(TZ=UTC find "${_PATH_MDIA}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${_PATH_MDIA}" "${_RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	for _PATH in $(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${_PATH:?}"
	done

	# --- list data -----------------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		_LINE="${_LIST_MDIA[I]}"
		_LINE="${_LINE//"${_DIRS_RMAK}"/:_DIRS_RMAK_:}"
		_LINE="${_LINE//"${_DIRS_LOAD}"/:_DIRS_LOAD_:}"
		_LINE="${_LINE//"${_DIRS_ISOS}"/:_DIRS_ISOS_:}"
		_LINE="${_LINE//"${_DIRS_IMGS}"/:_DIRS_IMGS_:}"
		_LINE="${_LINE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"
		_LINE="${_LINE//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"
		_LINE="${_LINE//"${_DIRS_KEYS}"/:_DIRS_KEYS_:}"
		_LINE="${_LINE//"${_DIRS_DATA}"/:_DIRS_DATA_:}"
		_LINE="${_LINE//"${_DIRS_CONF}"/:_DIRS_CONF_:}"
		_LINE="${_LINE//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"
		_LINE="${_LINE//"${_DIRS_USER}"/:_DIRS_USER_:}"
		_LINE="${_LINE//"${_DIRS_TFTP}"/:_DIRS_TFTP_:}"
		_LINE="${_LINE//"${_DIRS_SAMB}"/:_DIRS_SAMB_:}"
		_LINE="${_LINE//"${_DIRS_HTML}"/:_DIRS_HTML_:}"
		_LINE="${_LINE//"${_DIRS_HGFS}"/:_DIRS_HGFS_:}"
		_LINE="${_LINE//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"
		read -r -a _LIST < <(echo "${_LINE}")
		for J in "${!_LIST[@]}"
		do
			_LIST[J]="${_LIST[J]:--}"						# null
			_LIST[J]="${_LIST[J]// /%20}"					# blank
		done
		printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-27s %-15s %-15s %-85s %-27s %-15s %-43s %-85s %-27s %-15s %-43s %-85s %-85s %-85s %-27s %-85s\n" \
			"${_LIST[@]}" \
		>> "${_PATH_MDIA:?}"
	done
}

# --- create_directory --------------------------------------------------------
function fncCreate_directory() {
	declare -n    _NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    _DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare       _FORC_PRAM=""			# force parameter
	declare       _RTIV_FLAG=""			# add/relative flag
	declare       _TGET_PATH=""			# taget path
	declare       _LINK_PATH=""			# symlink path
	declare       _BACK_PATH=""			# backup path
	declare       _LINE=""				# work variable
	declare -i    I=0

	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-f | --force) shift; _NAME_REFR="${*:-}"; _FORC_PRAM="true";;
			*           )        _NAME_REFR="${*:-}"; break;;
		esac
	done

	# --- create directory ----------------------------------------------------
	mkdir -p "${_LIST_DIRS[@]:?}"

	# --- create symbolic link ------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	for I in "${!_LIST_LINK[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_LINK[I]}")
		case "${_LINE[0]}" in
			a) ;;
			r) ;;
			*) continue;;
		esac
		_RTIV_FLAG="${_LINE[0]}"
		_TGET_PATH="${_LINE[1]:-}"
		_LINK_PATH="${_LINE[2]:-}"
		# --- check target file path ------------------------------------------
		if [[ -z "${_LINK_PATH##*/}" ]]; then
			_LINK_PATH="${_LINK_PATH%/}/${_TGET_PATH##*/}"
#		else
#			if [[ ! -e "${_TGET_PATH}" ]]; then
#				touch "${_TGET_PATH}"
#			fi
		fi
		# --- force parameter -------------------------------------------------
		_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
		if [[ -n "${_FORC_PRAM:-}" ]] && [[ -e "${_LINK_PATH}" ]] && [[ ! -e "${_BACK_PATH##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${_LINK_PATH} -> ${_BACK_PATH##*/}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH} -> ${_BACK_PATH}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH} -> ${_LINK_PATH}"
		case "${_RTIV_FLAG}" in
			r) ln -sr "${_TGET_PATH}" "${_LINK_PATH}";;
			*) ln -s  "${_TGET_PATH}" "${_LINK_PATH}";;
		esac
	done

	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_MDIA[I]}")
		case "${_LINE[1]}" in
			o) ;;
			*) continue;;
		esac
		case "${_LINE[13]}" in
			-) continue;;
			*) ;;
		esac
		case "${_LINE[25]}" in
			-) continue;;
			*) ;;
		esac
		_TGET_PATH="${_LINE[25]}/${_LINE[13]##*/}"
		_LINK_PATH="${_LINE[13]}"
		# --- check target file path ------------------------------------------
#		if [[ ! -e "${_TGET_PATH}" ]]; then
#			touch "${_TGET_PATH}"
#		fi
		# --- force parameter -------------------------------------------------
		_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
		if [[ -n "${_FORC_PRAM:-}" ]] && [[ -e "${_LINK_PATH}" ]] && [[ ! -e "${_BACK_PATH##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${_LINK_PATH} -> ${_BACK_PATH##*/}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH} -> ${_BACK_PATH}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH} -> ${_LINK_PATH}"
		ln -s "${_TGET_PATH}" "${_LINK_PATH}"
	done
}

# --- media information [new] -------------------------------------------------
#  0: type          ( 14)   TEXT           NOT NULL     media type
#  1: entry_flag    ( 15)   TEXT           NOT NULL     [m] menu, [o] output, [else] hidden
#  2: entry_name    ( 39)   TEXT           NOT NULL     entry name (unique)
#  3: entry_disp    ( 39)   TEXT           NOT NULL     entry name for display
#  4: version       ( 23)   TEXT                        version id
#  5: latest        ( 23)   TEXT                        latest version
#  6: release       ( 15)   TEXT                        release date
#  7: support       ( 15)   TEXT                        support end date
#  8: web_regexp    (143)   TEXT                        web file  regexp
#  9: web_path      (143)   TEXT                        "         path
# 10: web_tstamp    ( 27)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 11: web_size      ( 15)   BIGINT                      "         file size
# 12: web_status    ( 15)   TEXT                        "         download status
# 13: iso_path      ( 85)   TEXT                        iso image file path
# 14: iso_tstamp    ( 27)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT          "           file size
# 16: iso_volume    ( 43)   TEXT            "           volume id
# 17: rmk_path      ( 85)   TEXT            remaster    file path
# 18: rmk_tstamp    ( 27)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 85)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 85)   TEXT                        kernel    file path
# 23: cfg_path      ( 85)   TEXT                        config    file path
# 24: cfg_tstamp    ( 27)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 85)   TEXT                        symlink   directory or file path

# ----- create preseed.cfg ----------------------------------------------------
function funcCreate_preseed() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
	declare       _WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_SEDD}" "${_TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${_TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${_TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${_TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_desktop*)
			sed -i "${_TGET_PATH}"                                              \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g                                                }'
			;;
		*)	;;
	esac
	# --- for ubiquity --------------------------------------------------------
	case "${_TGET_PATH}" in
		*_ubiquity_*)
			IFS= _WORK=$(
				sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${_TGET_PATH}" | \
				sed -e 's/\\/\\\\/g'                                                 \
				    -e 's/d-i/ubiquity/'                                             \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'        | \
				sed -e ':l; N; s/\n/\\n/; b l;' || true
			)
			if [[ -n "${_WORK}" ]]; then
				sed -i "${_TGET_PATH}"                                   \
				    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } ' \
				    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } '
				sed -i "${_TGET_PATH}"                                    \
				    -e "\%ubiquity/success_command%i \\${_WORK}"
			fi
			sed -i "${_TGET_PATH}"                        \
			    -e "\%ubiquity/download_updates% s/^#/ /" \
			    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
			    -e "\%ubiquity/reboot%           s/^#/ /"
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}"
}

# ----- create nocloud --------------------------------------------------------
function funcCreate_nocloud() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_CLUD}" "${_TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${_TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${_TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${_TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_desktop.*)
			sed -i "${_TGET_PATH}"                                             \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${_DIRS}/meta-data"      --reference "${_TGET_PATH}"
	touch -m "${_DIRS}/network-config" --reference "${_TGET_PATH}"
#	touch -m "${_DIRS}/user-data"      --reference "${_TGET_PATH}"
	touch -m "${_DIRS}/vendor-data"    --reference "${_TGET_PATH}"
	# -------------------------------------------------------------------------
	chmod --recursive ugo-x "${_DIRS}"
}

# ----- create kickstart.cfg --------------------------------------------------
function funcCreate_kickstart() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables
	declare       _DSTR_VERS=""			# distribution version
	declare       _DSTR_NUMS=""			# "            number
	declare       _DSTR_NAME=""			# "            name
	declare       _DSTR_SECT=""			# "            section
	declare -r    _BASE_ARCH="x86_64"	# base architecture
	declare -r    _WEBS_ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_KICK}" "${_TGET_PATH}"

	# -------------------------------------------------------------------------
#	_DSTR_NUMS="\$releasever"
	_DSTR_VERS="${_TGET_PATH#*_}"
	_DSTR_VERS="${_DSTR_VERS%%_*}"
	_DSTR_NUMS="${_DSTR_VERS##*-}"
	_DSTR_NAME="${_DSTR_VERS%-*}"
	_DSTR_SECT="${_DSTR_NAME/-/ }"

	# --- initializing the settings -------------------------------------------
	sed -i "${_TGET_PATH}"                              \
	    -e "/^cdrom$/      s/^/#/                     " \
	    -e "/^url[ \t]\+/  s/^/#/g                    " \
	    -e "/^repo[ \t]\+/ s/^/#/g                    " \
	    -e "s/:_HOST_NAME_:/${_DSTR_NAME}/            " \
	    -e "s%:_WEBS_ADDR_:%${_WEBS_ADDR}%g           " \
	    -e "s%:_DISTRO_:%${_DSTR_NAME}-${_DSTR_NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#cdrom$/ s/^#//                         "
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/           { " \
			    -e "/^#url[ \t]\+/  s/^#//g                   " \
			    -e "/^#repo[ \t]\+/ s/^#//g                 } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#.*(web address).*$/,/^$/             { " \
			    -e "/^#url[ \t]\+/  s/^#//g                   " \
			    -e "/^#repo[ \t]\+/ s/^#//g                   " \
			    -e "s/\$releasever/${_DSTR_NUMS}/g            " \
			    -e "s/\$basearch/${_BASE_ARCH}/g            } " \
			;;
		*)	;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e "/%packages/,/%end/ {"                       \
	    -e "/desktop/ s/^-//g  }"                       \
	    "${_TGET_PATH}"                                 \
	>   "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}" "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
}

# ----- create autoyast.xml ---------------------------------------------------
function funcCreate_autoyast() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables
	declare       _DSTR_VERS=""			# distribution version
	declare       _DSTR_NUMS=""			# "            number

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_YAST}" "${_TGET_PATH}"

	# -------------------------------------------------------------------------
	_DSTR_VERS="${_TGET_PATH#*_}"
	_DSTR_VERS="${_DSTR_VERS%%_*}"
	_DSTR_NUMS="${_DSTR_VERS##*-}"

	# --- by media ------------------------------------------------------------
	case "${_TGET_PATH}" in
		*_web*|\
		*_dvd*)
			sed -i "${_TGET_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/false/true/'
			;;
		*)
			sed -i "${_TGET_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/true/false/'
			;;
	esac
	# --- by version ----------------------------------------------------------
	case "${_TGET_PATH}" in
		*tumbleweed*)
			sed -i "${_TGET_PATH}"                                     \
			    -e '\%<add_on_products .*>%,\%<\/add_on_products>% { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${_TGET_PATH}"                                               \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%            { ' \
			    -e '/<!-- leap/,/leap -->/                                   { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${_DSTR_NUMS}/%g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                    ' \
			    -e '/^leap -->/  s/^/<!-- /g                                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%                  '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop lxde$/ s/$/ -->/g ' \
	    -e '/^desktop lxde -->/  s/^/<!-- /g' \
	    "${_TGET_PATH}"                            \
	>   "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}"
}

# ----- create pre-configuration file templates -------------------------------
function funcCreate_precon() {
	declare -n    _NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    _OPTN_PRAM=()			# option parameter
	declare -a    _LIST=()				# data list
	declare       _PATH=""				# file name
	declare       _TYPE=""				# configuration type
#	declare       _WORK=""				# work variables
	declare -i    I=0					# work variables

	# --- option parameter ----------------------------------------------------
	_OPTN_PRAM=()
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			all      ) _OPTN_PRAM+=("preseed" "nocloud" "kickstart" "autoyast");;
			preseed  | \
			nocloud  | \
			kickstart| \
			autoyast ) _OPTN_PRAM+=("$1");;
			*        ) break;;
		esac
		shift
	done
	_NAME_REFR="${*:-}"
	if [[ -z "${_OPTN_PRAM[*]}" ]]; then
		return
	fi

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create pre-conf file" ""

	# -------------------------------------------------------------------------
	_LIST=()
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_MDIA[I]}")
		case "${_LINE[1]}" in			# entry_flag
			o) ;;
			*) continue;;
		esac
		case "${_LINE[23]}" in			# cfg_path
			-) continue;;
			*) ;;
		esac
		_PATH="${_LINE[23]}"
		_TYPE="${_PATH%/*}"
		_TYPE="${_TYPE##*/}"
		if ! echo "${_OPTN_PRAM[*]}" | grep -q "${_TYPE}"; then
			continue
		fi
		_LIST+=("${_PATH}")
		case "${_PATH}" in
			*dvd.*) _LIST+=("${_PATH/_dvd/_web}");;
			*)	;;
		esac
	done
	mapfile -d $'\n' -t _LIST < <(IFS=  printf "%s\n" "${_LIST[@]}" | sort -Vu || true)
	# -------------------------------------------------------------------------
	for _PATH in "${_LIST[@]}"
	do
		_TYPE="${_PATH%/*}"
		_TYPE="${_TYPE##*/}"
		case "${_TYPE}" in
			preseed  ) funcCreate_preseed   "${_PATH}";;
			nocloud  ) funcCreate_nocloud   "${_PATH}/user-data";;
			kickstart) funcCreate_kickstart "${_PATH}";;
			autoyast ) funcCreate_autoyast  "${_PATH}";;
			*)	;;
		esac
	done

	# -------------------------------------------------------------------------
	# debian_*_oldold  : debian-10(buster)
	# debian_*_old     : debian-11(bullseye)
	# debian_*         : debian-12(bookworm)/13(trixie)/14(forky)/testing/sid/~
	# ubuntu_*_oldold  : ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubuntu_*_old     : ubuntu-20.04(focal)/22.04(jammy)
	# ubuntu_*         : ubuntu-23.04(lunar)/~
	# ubiquity_*_oldold: ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubiquity_*_old   : ubuntu-20.04(focal)/22.04(jammy)
	# ubiquity_*       : ubuntu-23.04(lunar)/~
	# -------------------------------------------------------------------------
}

# === <remastering> ===========================================================

# --- create boot options for preseed -----------------------------------------
function funcRemastering_preseed() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="auto=true preseed/file=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		case "${_TGET_LIST[2]}" in
			ubuntu-desktop-* | \
			ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}automatic-ubiquity noprompt ${_WORK}";;
			*-mini-*         ) _BOPT+="${_BOPT:+" "}${_WORK/\/cdrom/}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-*         ) _BOPT+="${_BOPT:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	_BOPT+="${_BOPT:+" "}netcfg/disable_autoconfig=true"
	_BOPT+="${_NICS_NAME:+"${_BOPT:+" "}netcfg/choose_interface=${_NICS_NAME}"}"
	_BOPT+="${_NWRK_HOST:+"${_BOPT:+" "}netcfg/get_hostname=${_HOST}.${_NWRK_WGRP}"}"
	_BOPT+="${_IPV4_ADDR:+"${_BOPT:+" "}netcfg/get_ipaddress=${_IPV4_ADDR}"}"
	_BOPT+="${_IPV4_MASK:+"${_BOPT:+" "}netcfg/get_netmask=${_IPV4_MASK}"}"
	_BOPT+="${_IPV4_GWAY:+"${_BOPT:+" "}netcfg/get_gateway=${_IPV4_GWAY}"}"
	_BOPT+="${_IPV4_NSVR:+"${_BOPT:+" "}netcfg/get_nameservers=${_IPV4_NSVR}"}"
	# --- locale --------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                ) _BOPT+="${_BOPT:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for nocloud -----------------------------------------
function funcRemastering_nocloud() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for nocloud" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="automatic-ubiquity noprompt autoinstall ds='nocloud;s=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}'"
		case "${_TGET_LIST[2]}" in
			ubuntu-live-18.* ) _BOPT+="${_BOPT:+" "}boot=casper ${_WORK}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-live-18.04) _BOPT+="${_BOPT:+" "}ip=${_NICS_NAME},${_IPV4_ADDR},${_IPV4_MASK},${_IPV4_GWAY} hostname=${_HOST}.${_NWRK_WGRP}";;
		*                ) _BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}::${_NICS_NAME}:${_IPV4_ADDR:+static}:${_IPV4_NSVR} hostname=${_HOST}.${_NWRK_WGRP}";;
	esac
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for kickstart ---------------------------------------
function funcRemastering_kickstart() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for kickstart" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}:${_HOST}.${_NWRK_WGRP}:${_NICS_NAME}:none,auto6 nameserver=${_IPV4_NSVR}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for autoyast ----------------------------------------
function funcRemastering_autoyast() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for autoyast" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		opensuse-*-15* ) _WORK="eth0";;
		*              ) _WORK="${_NICS_NAME}";;
	esac
	_BOPT+="${_BOPT:+" "}hostname=${_HOST}.${_NWRK_WGRP} ifcfg=${_WORK}=${_IPV4_ADDR}/${_IPV4_CIDR},${_IPV4_GWAY},${_IPV4_NSVR},${_NWRK_WGRP}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options -----------------------------------------------------
function funcRemastering_boot_options() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables

	# --- create boot options -------------------------------------------------
	case "${_TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${_TGET_LIST[23]}" in
				*/preseed/* ) _WORK="$(funcRemastering_preseed "${_TGET_LIST[@]}")";;
				*/nocloud/* ) _WORK="$(funcRemastering_nocloud "${_TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) _WORK="$(funcRemastering_kickstart "${_TGET_LIST[@]}")";;
		opensuse     ) _WORK="$(funcRemastering_autoyast "${_TGET_LIST[@]}")";;
		*            ) ;;
	esac
	_WORK+="${_MENU_MODE:+"${_WORK:+" "}vga=${_MENU_MODE}"}"
	_WORK+="${_WORK:+" "}fsck.mode=skip"
	echo -n "${_WORK}"
}

# --- create path for configuration file --------------------------------------
function funcRemastering_path() {
	declare -r    _PATH_TGET="${1:?}"	# target path
	declare -r    _DIRS_TGET="${2:?}"	# directory
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name

	_FNAM="${_PATH_TGET##*/}"
	_DIRS="${_PATH_TGET%"${_FNAM}"}"
	_DIRS="${_DIRS#"${_DIRS_TGET}"}"
	_DIRS="${_DIRS%%/}"
	_DIRS="${_DIRS##/}"
	echo -n "${_DIRS:+/"${_DIRS}"}/${_FNAM}"
}

# --- create autoinstall configuration file for isolinux ----------------------
function funcRemastering_isolinux_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd

	# --- header section ------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_MENU}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FTHM}" || true
		menu resolution ${_MENU_RESO/x/ }
		menu title Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}
		menu background splash.png
		menu color title	* #FFFFFFFF *
		menu color border	* #00000000 #00000000 none
		menu color sel		* #ffffffff #76a1d0ff *
		menu color hotsel	1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg	* #ffffffff #00000000 *
		menu color help		37;40 #ffdddd00 #00000000 none
		menu vshift 8
		menu rows 32
		menu helpmsgrow 34
		menu cmdlinerow 36
		menu timeoutrow 36
		menu tabmsgrow 38
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
		timeout ${_MENU_TOUT:-5}0
		default auto_install

_EOT_
	# --- standard installation mode ------------------------------------------
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
		label auto_install
		  menu label ^Automatic installation
		  menu default
		  kernel ${_FKNL}
		  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
		
_EOT_
		# --- graphical installation mode -------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
				label auto_install_gui
				  menu label ^Automatic installation of gui
				  kernel ${_FKNL}
				  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
			
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing isolinux for autoinstall ----------------------------------------
function funcRemastering_isolinux() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# isolinux.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTHM="${_FNAM%/*}/theme.txt"
		_FTMP="${_PATH}.tmp"
		if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${_PATH}"; then
			sed -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${_PAUT}"'' \
			    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${_FTHM}"'' \
				"${_PATH}"                                                                    \
			>	"${_FTMP}"
		else
			sed -e '0,/\([Ll]abel\|LABEL\)/ {'                     \
				-e '/\([Ll]abel\|LABEL\)/i include '"${_PAUT}"'\n' \
				-e '}'                                             \
				"${_PATH}"                                         \
			>	"${_FTMP}"
		fi
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for isolinux --------------
		funcRemastering_isolinux_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'isolinux.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
		sed -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   d}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               d'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 d'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           d'  \
			"${_PATH}"                                                                   \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- create autoinstall configuration file for grub --------------------------
function funcRemastering_grub_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _FTHM=""				# theme.txt
	declare       _FPNG=""				# splash.png

	# --- theme section -------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_MENU}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	for _DIRS in / /isolinux /boot/grub /boot/grub/theme
	do
		_FPNG="${_DIRS}/splash.png"
		if [[ -e "${_DIRS_TGET}/${_FPNG}" ]]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}" || true
				desktop-image: "${_FPNG}"
_EOT_
			break
		fi
	done
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}" || true
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}"
		message-font: "Unifont Regular 16"
		terminal-font: "Unifont Regular 16"
		terminal-border: "0"
		
		#help bar at the bottom
		+ label {
		  top = 100%-50
		  left = 0
		  width = 100%
		  height = 20
		  text = "@KEYMAP_SHORT@"
		  align = "center"
		  color = "#ffffff"
		  font = "Unifont Regular 16"
		}
		
		#boot menu
		+ boot_menu {
		  left = 10%
		  width = 80%
		  top = 20%
		  height = 50%-80
		  item_color = "#a8a8a8"
		  item_font = "Unifont Regular 16"
		  selected_item_color= "#ffffff"
		  selected_item_font = "Unifont Regular 16"
		  item_height = 16
		  item_padding = 0
		  item_spacing = 4
		  icon_width = 0
		  icon_heigh = 0
		  item_icon_space = 0
		}
		
		#progress bar
		+ progress_bar {
		  id = "__timeout__"
		  left = 15%
		  top = 100%-80
		  height = 16
		  width = 70%
		  font = "Unifont Regular 16"
		  text_color = "#000000"
		  fg_color = "#ffffff"
		  bg_color = "#a8a8a8"
		  border_color = "#ffffff"
		  text = "@TIMEOUT_NOTIFICATION_LONG@"
		}
_EOT_
	# --- header section ------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH}" || true
		#set gfxmode=${_MENU_RESO:+"${_MENU_RESO}${_MENU_DPTH:+x"${_MENU_DPTH}"},"}auto
		#set default=0
		set timeout=${_MENU_TOUT:-5}
		set timeout_style=menu
		set theme=${_FTHM#"${_DIRS_TGET}"}
		export theme
		
_EOT_
	# --- standard installation mode ------------------------------------------
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
			menuentry 'Automatic installation' {
			  set gfxpayload=keep
			  set background_color=black
			  echo 'Loading kernel ...'
			  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
			  echo 'Loading initial ramdisk ...'
			  initrd ${_FIRD}
			}

_EOT_
	# --- graphical installation mode -----------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
				menuentry 'Automatic installation of gui' {
				  set gfxpayload=keep
				  set background_color=black
				  echo 'Loading kernel ...'
				  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
				  echo 'Loading initial ramdisk ...'
				  initrd ${_FIRD}
				}
				
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing grub for autoinstall --------------------------------------------
function funcRemastering_grub() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# grub.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTMP="${_PATH}.tmp"
		if ! grep -qEi '^menuentry[ \t]+.*$' "${_PATH}"; then
			continue
		fi
		sed -e '0,/^menuentry/ {'                    \
			-e '/^menuentry/i source '"${_PAUT}"'\n' \
			-e '}'                                   \
				"${_PATH}"                           \
			>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for grub ------------------
		funcRemastering_grub_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'grub.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
		sed -e '/^[ \t]*\(\|set[ \t]\+\)default=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)timeout=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)theme=/   d' \
			"${_PATH}"                               \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- copy auto-install files -------------------------------------------------
function funcRemastering_copy() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# file name
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _BASE=""				# base name
	declare       _EXTN=""				# extension

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "copy" "auto-install files" 1>&2

	# -------------------------------------------------------------------------
	for _PATH in        \
		"${_SHEL_ERLY}" \
		"${_SHEL_LATE}" \
		"${_SHEL_PART}" \
		"${_SHEL_RUNS}" \
		"${_TGET_LIST[23]}"
	do
		if [[ ! -e "${_PATH}" ]]; then
			continue
		fi
		_DIRS="${_DIRS_TGET}${_PATH#"${_DIRS_CONF}"}"
		_DIRS="${_DIRS%/*}"
		mkdir -p "${_DIRS}"
		case "${_PATH}" in
			*/script/*   )
				printf "%20.20s: %s\n" "copy" "${_PATH#"${_DIRS_CONF}"/}" 1>&2
				cp -a "${_PATH}" "${_DIRS}"
				chmod ugo+xr-w "${_DIRS}/${_PATH##*/}"
				;;
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
#				_SEED="${_PATH%/*}"
#				_SEED="${_SEED##*/}"
				_FNAM="${_PATH##*/}"
				_WORK="${_FNAM%.*}"
				_EXTN="${_FNAM#"${_WORK}"}"
				_BASE="${_FNAM%"${_EXTN}"}"
				_WORK="${_BASE#*_*_}"
				_WORK="${_BASE%"${_WORK}"}"
				_WORK="${_PATH#*"${_WORK:-${_BASE%%_*}}"}"
				_WORK="${_PATH%"${_WORK}"*}"
				printf "%20.20s: %s\n" "copy" "${_WORK#"${_DIRS_CONF}"/}*${_EXTN}" 1>&2
				find "${_WORK%/*}" -name "${_WORK##*/}*${_EXTN}" -exec cp -a '{}' "${_DIRS}" \;
				find "${_DIRS}" -exec chmod ugo+r-xw '{}' \;
				;;
			*/windows/*  ) ;;
			*            ) ;;
		esac
	done
}

# --- remastering for initrd --------------------------------------------------
function funcRemastering_initrd() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _DTMP=""				# directory (extract)
	declare       _DTOP=""				# directory (main)
	declare       _DIRS=""				# directory

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "remake" "initrd" 1>&2

	# -------------------------------------------------------------------------
	_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
	_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"					# kernel
	_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"					# initrd
	_DTMP="$(mktemp -qd "${TMPDIR:-/tmp}/${_FIRD##*/}.XXXXXX")"

	# --- extract -------------------------------------------------------------
	funcSplit_initramfs "${_DIRS_TGET}${_FIRD}" "${_DTMP}"
	_DTOP="${_DTMP}"
	if [[ -d "${_DTOP}/main/." ]]; then
		_DTOP+="/main"
	fi
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DTOP}" "${_TGET_LIST[@]}"
#	ln -s "${_TGET_LIST[23]#"${_DIRS_CONF}"}" "${_DTOP}/preseed.cfg"
	# --- repackaging ---------------------------------------------------------
	pushd "${_DTOP}" > /dev/null || exit
		find . | cpio --format=newc --create --quiet | gzip > "${_DIRS_TGET}${_FIRD%/*}/${_MINI_IRAM}" || true
	popd > /dev/null || exit

	rm -rf "${_DTMP:?}"
}

# --- remastering for media ---------------------------------------------------
function funcRemastering_media() {
	declare -r    _DIRS_TGET="${1:?}"						# target directory
	shift
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
#	declare       _PATH=""									# file name
	declare       _FMBR=""									# "         (mbr.img)
	declare       _FEFI=""									# "         (efi.img)
	declare       _FCAT=""									# "         (boot.cat or boot.catalog)
	declare       _FBIN=""									# "         (isolinux.bin or eltorito.img)
	declare       _FHBR=""									# "         (isohdpfx.bin)
	declare       _VLID=""									# 
	declare -i    _SKIP=0									# 
	declare -i    _SIZE=0									# 

	# --- pre-processing ------------------------------------------------------
#	_PATH="${_DWRK}/${_TGET_LIST[17]##*/}.tmp"				# file path
	_FCAT="$(find "${_DIRS_TGET}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
	_FBIN="$(find "${_DIRS_TGET}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
	_VLID="$(funcGetVolID "${_TGET_LIST[13]}")"
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	# --- create iso image file -----------------------------------------------
	if [[ -e "${_DIRS_TGET}/${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (hybrid)" 1>&2
		_FHBR="$(find /usr/lib  -iname 'isohdpfx.bin' -type f || true)"
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-cache-inodes \
			${_FHBR:+-isohybrid-mbr "${_FHBR}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			-boot-load-size 4 -boot-info-table \
			-no-emul-boot \
			-eltorito-alt-boot ${_FEFI:+-e "${_FEFI}"} \
			-no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
	else
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (grub2-mbr)" 1>&2
		_FMBR="${_DWRK}/mbr.img"
		_FEFI="${_DWRK}/efi.img"
		# --- extract the mbr template ----------------------------------------
		dd if="${_TGET_LIST[13]}" bs=1 count=446 of="${_FMBR}" > /dev/null 2>&1
		# --- extract efi partition image -------------------------------------
		_SKIP=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $2;}' || true)
		_SIZE=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $4;}' || true)
		dd if="${_TGET_LIST[13]}" bs=512 skip="${_SKIP}" count="${_SIZE}" of="${_FEFI}" > /dev/null 2>&1
		# --- create iso image file -------------------------------------------
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			${_FMBR:+--grub2-mbr "${_FMBR}"} \
			--mbr-force-bootable \
			${_FEFI:+-append_partition 2 0xEF "${_FEFI}"} \
			-appended_part_as_gpt \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			-no-emul-boot \
			-boot-load-size 4 -boot-info-table \
			--grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
			-no-emul-boot
	fi
}

# --- remastering -------------------------------------------------------------
function funcRemastering() {
	declare -i    _time_start=0								# start of elapsed time
	declare -i    _time_end=0								# end of elapsed time
	declare -i    _time_elapsed=0							# result of elapsed time
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
	declare -r    _DOVL="${_DWRK}/overlay"					# overlay
	declare -r    _DUPR="${_DOVL}/upper"					# upperdir
	declare -r    _DLOW="${_DOVL}/lower"					# lowerdir
	declare -r    _DWKD="${_DOVL}/work"						# workdir
	declare -r    _DMRG="${_DOVL}/merged"					# merged
	declare       _PATH=""									# file name
	declare       _FEFI=""									# "         (efiboot.img)
	declare       _BOPT=""									# boot options
	
	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" "${_TGET_LIST[13]##*/}" 1>&2

	# --- pre-check -----------------------------------------------------------
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	if [[ -z "${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "unknown target" "${_TGET_LIST[2]%%-*} [${_TGET_LIST[13]##*/}]" 1>&2
		return
	fi
	if [[ ! -s "${_TGET_LIST[13]}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[93m%20.20s: %s${_CODE_ESCP}[m\n" "not exist" "${_TGET_LIST[13]##*/}" 1>&2
		return
	fi
	if mountpoint --quiet "${_DMRG}"; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "already mounted" "${_DMRG#"${_DWRK}"/}" 1>&2
		return
	fi

	# --- pre-processing ------------------------------------------------------
	printf "%20.20s: %s\n" "start" "${_DMRG#"${_DWRK}"/}" 1>&2
	rm -rf "${_DOVL:?}"
	mkdir -p "${_DUPR}" "${_DLOW}" "${_DWKD}" "${_DMRG}"

	# --- main processing -----------------------------------------------------
	mount -r "${_TGET_LIST[13]}" "${_DLOW}"
	mount -t overlay overlay -o lowerdir="${_DLOW}",upperdir="${_DUPR}",workdir="${_DWKD}" "${_DMRG}"
	# --- create boot options -------------------------------------------------
	_BOPT="$(funcRemastering_boot_options "${_TGET_LIST[@]}")"
	# --- create autoinstall configuration file for isolinux ------------------
	funcRemastering_isolinux "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- create autoinstall configuration file for grub ----------------------
	funcRemastering_grub "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DMRG}" "${_TGET_LIST[@]}"
	# --- remastering for initrd ----------------------------------------------
	case "${_TGET_LIST[2]}" in
		*-mini-*         ) funcRemastering_initrd "${_DMRG}" "${_TGET_LIST[@]}";;
		*                ) ;;
	esac
	# --- create iso image file -----------------------------------------------
	funcRemastering_media "${_DMRG}" "${_TGET_LIST[@]}"
	umount "${_DMRG}"
	umount "${_DLOW}"

	# --- post-processing -----------------------------------------------------
	rm -rf "${_DOVL:?}"
	printf "%20.20s: %s\n" "finish" "${_DMRG#"${_DWRK}"/}" 1>&2

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true)" "finish" "${_TGET_LIST[13]##*/}" 1>&2
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%10dd%02dh%02dm%02ds: %-20.20s: %s${_CODE_ESCP}[m\n" "$((_time_elapsed/86400))" "$((_time_elapsed%86400/3600))" "$((_time_elapsed%3600/60))" "$((_time_elapsed%60))" "elapsed" "${_TGET_LIST[13]##*/}" 1>&2
}

# --- debug out parameter -----------------------------------------------------
funcDebug_parameter() {
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
function funcHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ./${_PROG_PATH##*/} [command (options)]
		
		  iso image files:
		    create|update|download [all|(mini|net|dvd|live {a|all|id})|version]
		      empty             : waiting for input
		      all               : all target
		      mini|net|dvd|live : each target
		        all             : all of each target
		        id number       : selected id
		
		  list files:
		    list [create|update|download]
		      empty             : display of list data
		      create            : update / download list files
		
		  config files:
		    conf [create]
		      create            : create common configuration file
		
		  pre-config files:
		    preconf [all|(preseed|nocloudkickstart|autoyast)]
		      all               : all pre-config files
		      preseed           : preseed.cfg
		      nocloud           : nocloud
		      kickstart         : kickstart.cfg
		      autoyast          : autoyast.xml
		
		  symbolic link:
		    link
		      create            : create symbolic link
		
		  debug print and test
		    debug [func|text|parm]
		      parm              : display of main internal parameters
_EOT_
}

# === main ====================================================================

function funcMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	declare -a    _LIST=()				# work variables
	declare -i    I=0					# work variables

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME}" != "root" ]]; then
		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
		exit 1
	fi

	# --- get command line ----------------------------------------------------
	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			help    ) shift; funcHelp; exit 0;;
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
	funcInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			create  )					# force create
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
						o) ;;
						*) continue;;
					esac
					funcRemastering "${_LIST[@]}"
					funcPut_media_data
				done
				;;
			update  )					# create new files only
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
						o) ;;
						*) continue;;
					esac
					# --- web original iso file -------------------------------
					_WORK="$(funcGetWebinfo "${_LIST[9]}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[10]="${_ARRY[1]}"					# web_tstamp
					_LIST[11]="${_ARRY[2]}"					# web_size
					_LIST[12]="${_ARRY[3]}"					# web_status
					# --- local original iso file -----------------------------
					_WORK="$(funcGetFileinfo "${_LIST[13]}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[13]="${_ARRY[0]}"					# iso_path
					_LIST[14]="${_ARRY[1]}"					# iso_tstamp
					_LIST[15]="${_ARRY[2]}"					# iso_size
					_LIST[16]="${_ARRY[3]}"					# iso_volume
					# --- local remastering iso file --------------------------
					_WORK="$(funcGetFileinfo "${_LIST[17]}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[17]="${_ARRY[0]}"					# rmk_path
					_LIST[18]="${_ARRY[1]}"					# rmk_tstamp
					_LIST[19]="${_ARRY[2]}"					# rmk_size
					_LIST[20]="${_ARRY[3]}"					# rmk_volume
					# --- config file  ----------------------------------------
					_WORK="$(funcGetFileinfo "${_LIST[17]}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[23]="${_ARRY[0]}"					# cfg_path
					_LIST[24]="${_ARRY[1]}"					# cfg_tstamp
					# ---------------------------------------------------------
					if [[ -n "${_LIST[13]##-}" ]] && [[ -n "${_LIST[14]##-}" ]] && [[ -n "${_LIST[15]##-}" ]]; then
						if [[ -n  "${_LIST[9]##-}" ]] && [[ -n "${_LIST[10]##-}" ]] && [[ -n "${_LIST[11]##-}" ]]; then
							if [[ -n "${_LIST[17]##-}" ]] && [[ -n "${_LIST[18]##-}" ]] && [[ -n "${_LIST[19]##-}" ]]; then
								_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[10]}")"
								if [[ "${_WORK}" -eq 0 ]] && [[ "${_LIST[15]}" -ne "${_LIST[11]}" ]]; then
									_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[18]}")"
									if [[ "${_WORK}" -lt 0 ]]; then
										continue
									fi
									if [[ -n "${_LIST[23]##-}" ]] && [[ -n "${_LIST[24]##-}" ]]; then
										_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[24]}")"
										if [[ "${_WORK}" -lt 0 ]]; then
											continue
										fi
									fi
								fi
							fi
						fi
					fi
					funcRemastering "${_LIST[@]}"
				done
				;;
			download)					# download only
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
						o) ;;
						*) continue;;
					esac
				done
				;;
			link    )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						create   ) shift; fncCreate_directory _RETN_PARM "${@:-}"; funcPut_media_data;;
						update   ) ;;
						download ) ;;
						*        ) break;;
					esac
				done
				;;
			list    )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						create   ) shift; funcPut_media_data;;
						update   ) ;;
						download ) ;;
						*        ) break;;
					esac
				done
				;;
			conf    )
				shift
				case "${1:-}" in
					create   ) shift; funcCreate_conf;;
					*        ) ;;
				esac
				;;
			preconf )
				shift
				funcCreate_precon _RETN_PARM "${@:-}"
				;;
			help    ) shift; funcHelp; break;;
			debug   )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						parm) shift; funcDebug_parameter;;
						*   ) break;;
					esac
				done
				;;
			*       ) shift;;
		esac
		_RETN_PARM=("${_RETN_PARM:-"${@:-}"}")
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
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
