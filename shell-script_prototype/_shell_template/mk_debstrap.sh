#!/bin/bash

###############################################################################
##
##	create container shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/08/16
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/08/16 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# shellcheck disable=SC2148
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
	declare       _DBGS_LOGS=""			# debug file (empty: normal, else: debug)

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"${LOGNAME:-"$(whoami || true)"}"}"

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
    declare -r    _SUDO_USER="${SUDO_USER:-}"
    declare       _SUDO_HOME="${SUDO_HOME:-}"
    if [[ -n "${_SUDO_USER}" ]] && [[ -z "${_SUDO_HOME}" ]]; then
        _SUDO_HOME="$(awk -F ':' '$1=="'"${_SUDO_USER}"'" {print $6;}' /etc/passwd)"
    fi
	readonly      _SUDO_HOME
	declare       _DIRS_TEMP=""
	              _DIRS_TEMP="$(mktemp -qd -p "${_SUDO_HOME:-/tmp}" "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
#	declare -r    TMPDIR="${_DIRS_TEMP:-?}"

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# -----------------------------------------------------------------------------
# descript: trap
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
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

	# shellcheck disable=SC2148
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
			"mmdebstrap" \
		)
		# ---------------------------------------------------------------------
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_ARCH_OTHR:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g' || true)"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			echo "please install these:"
			if [[ -n "${SUDO_USER:-}" ]] || { [[ -z "${SUDO_USER:-}" ]] && [[ "${_USER_NAME:-}" != "root" ]]; }; then
				echo -n "sudo "
			fi
			echo "apt-get install ${PAKG_FIND% *}" 1>&2
			exit 1
		fi
	fi

	# shellcheck disable=SC2148
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
	declare       _DIRS_CHRT=""			# container file

	# --- common data file ----------------------------------------------------
	declare       _PATH_CONF=""			# common configuration file
	declare       _PATH_MDIA=""			# media data file
	declare       _PATH_DSTP=""			# debstrap data file

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

	# --- tftp / web server network parameter ---------------------------------
	declare       _SRVR_HTTP="http"		# server connection protocol (http or https)
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

	# --- ipxe menu file ------------------------------------------------------
	declare       _MENU_IPXE=""

	# --- grub menu file ------------------------------------------------------
	declare       _MENU_GRUB=""

	# --- syslinux menu file --------------------------------------------------
	declare       _MENU_SLNX=""			# bios
	declare       _MENU_UEFI=""			# uefi x86_64

	# --- list data -----------------------------------------------------------
	declare -a    _LIST_MDIA=()			# media information
	declare -a    _LIST_DSTP=()			# debstrap information

	# --- curl / wget parameter -----------------------------------------------
	declare       _COMD_CURL=""
	declare       _COMD_WGET=""
	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=3" "--quiet")
	if command -v curl  > /dev/null 2>&1; then _COMD_CURL="true"; fi
	if command -v wget  > /dev/null 2>&1; then _COMD_WGET="true"; fi
	if command -v wget2 > /dev/null 2>&1; then _COMD_WGET="ver2"; fi
	readonly      _COMD_CURL
	readonly      _COMD_WGET

	# --- rsync parameter -----------------------------------------------------
	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--update" "--delete")

	# --- ram disk parameter --------------------------------------------------
	declare -r -a _OPTN_RDSK=("root=/dev/ram0" "load_ramdisk=1" "ramdisk_size=1024000" "overlay-size=80%")

	# --- boot type parameter -------------------------------------------------
	declare -r    _TYPE_ISOB="isoboot"	# iso media boot
	declare -r    _TYPE_PXEB="pxeboot"	# pxe boot
	declare -r    _TYPE_USBB="usbboot"	# usb stick boot

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
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
function fnSubstr() {
	echo -n "${1:$((${2:-1}-1)):${3:-${#1}}}"
}

# -----------------------------------------------------------------------------
# descript: string output
#   input :   $1   : number of characters
#   input :   $2   : output character
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnString() {
	echo "" | IFS= awk '{s=sprintf("%'"${1:?}"'s",""); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
}

# -----------------------------------------------------------------------------
# descript: ltrim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnLtrim() {
	echo -n "${1#"${1%%[!"${IFS}"]*}"}"	# ltrim
}

# -----------------------------------------------------------------------------
# descript: rtrim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnRtrim() {
	echo -n "${1%"${1##*[!"${IFS}"]}"}"	# rtrim
}

# -----------------------------------------------------------------------------
# descript: trim
#   input :   $1   : input
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
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
# shellcheck disable=SC2317,SC2329
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

# shellcheck disable=SC2148
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
# shellcheck disable=SC2317,SC2329
function fnIPv4GetNetmask() {
	fnDebugout ""
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
# shellcheck disable=SC2317,SC2329
function fnIPv6GetFullAddr() {
	fnDebugout ""
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
# shellcheck disable=SC2317,SC2329
function fnIPv6GetRevAddr() {
	fnDebugout ""
	echo "${1//:/}" | \
	    awk '{
	        for(i=length();i>1;i--)              \
	            printf("%c.", substr($0,i,1));   \
	            printf("%c" , substr($0,1,1));}'
}

# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <common> ================================================================

# -----------------------------------------------------------------------------
# descript: initialization
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnInitialization() {
	declare       __PATH=""				# full path
	declare       __WORK=""				# work variables
	declare       __LINE=""				# work variable
	declare       __NAME=""				# variable name
	declare       __VALU=""				# value
	declare       __DEVS=""				# device name
	# --- common configuration file -------------------------------------------
	              _PATH_CONF="/srv/user/share/conf/_data/common.cfg"
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_CONF##*/}"}" \
		"${_PATH_CONF}"
	do
		if [[ -f "${__PATH}" ]]; then
			_PATH_CONF="${__PATH}"
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
	_DIRS_CHRT="${_DIRS_CHRT:-:_DIRS_SHAR_:/chroot}"
#	_PATH_CONF="${_PATH_CONF:-:_DIRS_DATA_:/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-:_DIRS_DATA_:/media.dat}"
	_PATH_DSTP="${_PATH_DSTP:-:_DIRS_DATA_:/debstrap.dat}"
	_CONF_KICK="${_CONF_KICK:-:_DIRS_TMPL_:/kickstart_rhel.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-:_DIRS_TMPL_:/user-data_ubuntu}"
	_CONF_SEDD="${_CONF_SEDD:-:_DIRS_TMPL_:/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-:_DIRS_TMPL_:/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-:_DIRS_TMPL_:/yast_opensuse.xml}"
	_CONF_AGMA="${_CONF_AGMA:-:_DIRS_TMPL_:/agama_opensuse.json}"
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/autoinst_cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/autoinst_cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/autoinst_cmd_part.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/autoinst_cmd_run.sh}"
	_SRVR_HTTP="${_SRVR_HTTP:-http}"
	_SRVR_PROT="${_SRVR_PROT:-"${_SRVR_HTTP}"}"
	_SRVR_NICS=""
	while read -r __DEVS
	do
		__VALU="$(ip -4 -brief address show dev "${__DEVS}")"
		if [[ -n "${__VALU:-}" ]]; then
			_SRVR_NICS="${__DEVS}"
			_SRVR_ADDR="$(echo "${__VALU}" | awk '{print $3;}')"
			_SRVR_CIDR="${_SRVR_ADDR##*/}"
			_SRVR_ADDR="${_SRVR_ADDR%/*}"
			break
		fi
	done < <(ls /sys/class/net/ || true)
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
	_SRVR_NICS="${_SRVR_NICS%@*}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}' || true)"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}' || true)"}"
		__WORK="$(ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null)"
		if echo "${__WORK}" | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}' || true)"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(fnIPv4GetNetmask "${_SRVR_CIDR}")"}"
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
	_IPV4_MASK="${_IPV4_MASK:-"$(fnIPv4GetNetmask "${_IPV4_CIDR}")"}"
	_IPV4_GWAY="${_IPV4_GWAY:-"${_SRVR_GWAY}"}"
	_IPV4_NSVR="${_IPV4_NSVR:-"${_SRVR_NSVR}"}"
	_IPV4_UADR="${_IPV4_UADR:-"${_SRVR_UADR}"}"
#	_NMAN_NAME="${_NMAN_NAME:-""}"
	_MENU_TOUT="${_MENU_TOUT:-5}"
	_MENU_RESO="${_MENU_RESO:-1024x768}"
	_MENU_DPTH="${_MENU_DPTH:-16}"
	_MENU_MODE="${_MENU_MODE:-791}"
	# --- gets the setting value ----------------------------------------------
	while read -r __LINE
	do
		__LINE="${__LINE%%#*}"
		__LINE="${__LINE//["${IFS}"]/ }"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__NAME="${__LINE%%=*}"
		__VALU="${__LINE#*=}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		case "${__NAME:-}" in
			DIRS_TOPS) _DIRS_TOPS="${__VALU:-"${_DIRS_TOPS:-}"}";;
			DIRS_HGFS) _DIRS_HGFS="${__VALU:-"${_DIRS_HGFS:-}"}";;
			DIRS_HTML) _DIRS_HTML="${__VALU:-"${_DIRS_HTML:-}"}";;
			DIRS_SAMB) _DIRS_SAMB="${__VALU:-"${_DIRS_SAMB:-}"}";;
			DIRS_TFTP) _DIRS_TFTP="${__VALU:-"${_DIRS_TFTP:-}"}";;
			DIRS_USER) _DIRS_USER="${__VALU:-"${_DIRS_USER:-}"}";;
			DIRS_SHAR) _DIRS_SHAR="${__VALU:-"${_DIRS_SHAR:-}"}";;
			DIRS_CONF) _DIRS_CONF="${__VALU:-"${_DIRS_CONF:-}"}";;
			DIRS_DATA) _DIRS_DATA="${__VALU:-"${_DIRS_DATA:-}"}";;
			DIRS_KEYS) _DIRS_KEYS="${__VALU:-"${_DIRS_KEYS:-}"}";;
			DIRS_TMPL) _DIRS_TMPL="${__VALU:-"${_DIRS_TMPL:-}"}";;
			DIRS_SHEL) _DIRS_SHEL="${__VALU:-"${_DIRS_SHEL:-}"}";;
			DIRS_IMGS) _DIRS_IMGS="${__VALU:-"${_DIRS_IMGS:-}"}";;
			DIRS_ISOS) _DIRS_ISOS="${__VALU:-"${_DIRS_ISOS:-}"}";;
			DIRS_LOAD) _DIRS_LOAD="${__VALU:-"${_DIRS_LOAD:-}"}";;
			DIRS_RMAK) _DIRS_RMAK="${__VALU:-"${_DIRS_RMAK:-}"}";;
			DIRS_CHRT) _DIRS_CHRT="${__VALU:-"${_DIRS_CHRT:-}"}";;
#			PATH_CONF) _PATH_CONF="${__VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${__VALU:-"${_PATH_MDIA:-}"}";;
			PATH_DSTP) _PATH_DSTP="${__VALU:-"${_PATH_DSTP:-}"}";;
			CONF_KICK) _CONF_KICK="${__VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${__VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${__VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${__VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${__VALU:-"${_CONF_YAST:-}"}";;
			CONF_AGMA) _CONF_AGMA="${__VALU:-"${_CONF_AGMA:-}"}";;
			SHEL_ERLY) _SHEL_ERLY="${__VALU:-"${_SHEL_ERLY:-}"}";;
			SHEL_LATE) _SHEL_LATE="${__VALU:-"${_SHEL_LATE:-}"}";;
			SHEL_PART) _SHEL_PART="${__VALU:-"${_SHEL_PART:-}"}";;
			SHEL_RUNS) _SHEL_RUNS="${__VALU:-"${_SHEL_RUNS:-}"}";;
			SRVR_HTTP) _SRVR_HTTP="${__VALU:-"${_SRVR_HTTP:-}"}";;
			SRVR_PROT) _SRVR_PROT="${__VALU:-"${_SRVR_PROT:-}"}";;
			SRVR_NICS) _SRVR_NICS="${__VALU:-"${_SRVR_NICS:-}"}";;
			SRVR_MADR) _SRVR_MADR="${__VALU:-"${_SRVR_MADR:-}"}";;
			SRVR_ADDR) _SRVR_ADDR="${__VALU:-"${_SRVR_ADDR:-}"}";;
			SRVR_CIDR) _SRVR_CIDR="${__VALU:-"${_SRVR_CIDR:-}"}";;
			SRVR_MASK) _SRVR_MASK="${__VALU:-"${_SRVR_MASK:-}"}";;
			SRVR_GWAY) _SRVR_GWAY="${__VALU:-"${_SRVR_GWAY:-}"}";;
			SRVR_NSVR) _SRVR_NSVR="${__VALU:-"${_SRVR_NSVR:-}"}";;
			SRVR_UADR) _SRVR_UADR="${__VALU:-"${_SRVR_UADR:-}"}";;
			NWRK_HOST) _NWRK_HOST="${__VALU:-"${_NWRK_HOST:-}"}";;
			NWRK_WGRP) _NWRK_WGRP="${__VALU:-"${_NWRK_WGRP:-}"}";;
			NICS_NAME) _NICS_NAME="${__VALU:-"${_NICS_NAME:-}"}";;
#			NICS_MADR) _NICS_MADR="${__VALU:-"${_NICS_MADR:-}"}";;
			IPV4_ADDR) _IPV4_ADDR="${__VALU:-"${_IPV4_ADDR:-}"}";;
			IPV4_CIDR) _IPV4_CIDR="${__VALU:-"${_IPV4_CIDR:-}"}";;
			IPV4_MASK) _IPV4_MASK="${__VALU:-"${_IPV4_MASK:-}"}";;
			IPV4_GWAY) _IPV4_GWAY="${__VALU:-"${_IPV4_GWAY:-}"}";;
			IPV4_NSVR) _IPV4_NSVR="${__VALU:-"${_IPV4_NSVR:-}"}";;
#			IPV4_UADR) _IPV4_UADR="${__VALU:-"${_IPV4_UADR:-}"}";;
#			NMAN_NAME) _NMAN_NAME="${__VALU:-"${_NMAN_NAME:-}"}";;
			MENU_TOUT) _MENU_TOUT="${__VALU:-"${_MENU_TOUT:-}"}";;
			MENU_RESO) _MENU_RESO="${__VALU:-"${_MENU_RESO:-}"}";;
			MENU_DPTH) _MENU_DPTH="${__VALU:-"${_MENU_DPTH:-}"}";;
			MENU_MODE) _MENU_MODE="${__VALU:-"${_MENU_MODE:-}"}";;
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
	_DIRS_CHRT="${_DIRS_CHRT//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
#	_PATH_CONF="${_PATH_CONF//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_MDIA="${_PATH_MDIA//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_DSTP="${_PATH_DSTP//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_CONF_KICK="${_CONF_KICK//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_CLUD="${_CONF_CLUD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDD="${_CONF_SEDD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDU="${_CONF_SEDU//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_YAST="${_CONF_YAST//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_AGMA="${_CONF_AGMA//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_SHEL_ERLY="${_SHEL_ERLY//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_LATE="${_SHEL_LATE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_PART="${_SHEL_PART//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_RUNS="${_SHEL_RUNS//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
#	_SRVR_HTTP="${_SRVR_HTTP:-}"
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
	readonly      _DIRS_CHRT
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _PATH_DSTP
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
	readonly      _CONF_AGMA
	readonly      _SRVR_HTTP
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
	_LIST_DIRS=(                                                                                                                                                                        \
		"${_DIRS_TOPS:?}"                                                                                                                                                               \
		"${_DIRS_HGFS:?}"                                                                                                                                                               \
		"${_DIRS_HTML:?}"                                                                                                                                                               \
		"${_DIRS_SAMB:?}"/{adm/{commands,profiles},pub/{contents/{disc,dlna/{movies,others,photos,sounds}},resource/{image/{linux,windows},source/git},software,hardware,_license},usr} \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg}                                                                       \
		"${_DIRS_USER:?}"                                                                                                                                                               \
		"${_DIRS_SHAR:?}"                                                                                                                                                               \
		"${_DIRS_CONF:?}"/{agama,autoyast,kickstart,nocloud,preseed,script,windows}                                                                                                     \
		"${_DIRS_DATA:?}"                                                                                                                                                               \
		"${_DIRS_KEYS:?}"                                                                                                                                                               \
		"${_DIRS_TMPL:?}"                                                                                                                                                               \
		"${_DIRS_SHEL:?}"                                                                                                                                                               \
		"${_DIRS_IMGS:?}"                                                                                                                                                               \
		"${_DIRS_ISOS:?}"                                                                                                                                                               \
		"${_DIRS_LOAD:?}"                                                                                                                                                               \
		"${_DIRS_RMAK:?}"                                                                                                                                                               \
		"${_DIRS_CHRT:?}"                                                                                                                                                               \
	)
	readonly      _LIST_DIRS
	# --- symbolic link list --------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	_LIST_LINK=(                                                                                                                                                                        \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_TFTP:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"r  ${_DIRS_TFTP:?}/${_DIRS_CONF##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/menu-bios/syslinux.cfg              ${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"                                                                         \
		"r  ${_DIRS_TFTP:?}/${_DIRS_CONF##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg             ${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"                                                                        \
	)
	readonly      _LIST_LINK
	# --- autoinstall configuration file --------------------------------------
	              _AUTO_INST="autoinst.cfg"
	readonly      _AUTO_INST
	# --- initial ram disk of mini.iso including preseed ----------------------
	              _MINI_IRAM="initps.gz"
	readonly      _MINI_IRAM
	# --- ipxe menu file ------------------------------------------------------
	              _MENU_IPXE="${_DIRS_TFTP}/autoexec.ipxe"
	readonly      _MENU_IPXE
	# --- grub menu file ------------------------------------------------------
	              _MENU_GRUB="${_DIRS_TFTP}/boot/grub/grub.cfg"
	readonly      _MENU_GRUB
	# --- syslinux menu file --------------------------------------------------
	              _MENU_SLNX="${_DIRS_TFTP}/menu-bios/syslinux.cfg"
	readonly      _MENU_SLNX
	              _MENU_UEFI="${_DIRS_TFTP}/menu-efi64/syslinux.cfg"
	readonly      _MENU_UEFI
}

# -----------------------------------------------------------------------------
# descript: create common configuration file
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_conf() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    __TMPL="${_PATH_CONF:?}.template"
	declare       __RNAM=""				# rename path
	declare       __PATH=""				# full path
	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			create) shift; break;;
			*     ) __NAME_REFR="${*:-}"; return;;
		esac
	done
	__NAME_REFR="${*:-}"
	# --- check file exists ---------------------------------------------------
	if [[ -f "${__TMPL:?}" ]]; then
		__RNAM="${__TMPL}.$(TZ=UTC find "${__TMPL}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${__TMPL}" "${__RNAM}"
	fi
	# --- delete old files ----------------------------------------------------
	for __PATH in $(find "${__TMPL%/*}" -name "${__TMPL##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${__PATH:?}"
	done
	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TMPL}" || true
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
		DIRS_CHRT="${_DIRS_CHRT//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"		# container file

		# --- common data file --------------------------------------------------------
		#PATH_CONF="${_PATH_CONF//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# common configuration file (this file)
		PATH_MDIA="${_PATH_MDIA//"${_DIRS_DATA}"/:_DIRS_DATA_:}"		# media data file
		PATH_DSTP="${_PATH_DSTP//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# debstrap data file

		# --- pre-configuration file templates ----------------------------------------
		CONF_KICK="${_CONF_KICK//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for rhel
		CONF_CLUD="${_CONF_CLUD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for ubuntu cloud-init
		CONF_SEDD="${_CONF_SEDD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for debian
		CONF_SEDU="${_CONF_SEDU//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for ubuntu
		CONF_YAST="${_CONF_YAST//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for opensuse autoyast
		CONF_AGMA="${_CONF_AGMA//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for opensuse agama

		# --- shell script ------------------------------------------------------------
		SHEL_ERLY="${_SHEL_ERLY//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run early
		SHEL_LATE="${_SHEL_LATE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run late
		SHEL_PART="${_SHEL_PART//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run after partition
		SHEL_RUNS="${_SHEL_RUNS//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run preseed/run

		# --- tftp / web server network parameter -------------------------------------
		SRVR_HTTP="${_SRVR_HTTP:-}"						# server connection protocol (http or https)
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
		NTPS_ADDR="ntp.nict.jp"				    # ntp server address
		NTPS_IPV4="61.205.120.130"		    	# ntp server ipv4 address

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

# -----------------------------------------------------------------------------
# descript: create directory
#   n-ref :   $1   : return value : options
#   input :   $@   : input vale
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_directory() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    __DATE="$(date +"%Y%m%d%H%M%S")"
	declare       __FORC=""				# force parameter
	declare       __RTIV=""				# add/relative flag
	declare       __TGET=""				# taget path
	declare       __LINK=""				# symlink path
	declare       __BACK=""				# backup path
	declare -a    __LIST=()				# work variable
	declare -i    I=0
	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			create) shift; __FORC="true"; break;;
			update) shift; __FORC=""; break;;
			*     ) __NAME_REFR="${*:-}"; return;;
		esac
	done
	__NAME_REFR="${*:-}"
	# --- create directory ----------------------------------------------------
	mkdir -p "${_LIST_DIRS[@]:?}"
	# --- create symbolic link ------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	for I in "${!_LIST_LINK[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_LINK[I]}")
		case "${__LIST[0]}" in
			a) ;;
			r) ;;
			*) continue;;
		esac
		__RTIV="${__LIST[0]}"
		__TGET="${__LIST[1]:-}"
		__LINK="${__LIST[2]:-}"
		# --- check target file path ------------------------------------------
		if [[ -z "${__LINK##*/}" ]]; then
			__LINK="${__LINK%/}/${__TGET##*/}"
#		else
#			if [[ ! -e "${__TGET}" ]]; then
#				touch "${__TGET}"
#			fi
		fi
		# --- check target directory ------------------------------------------
		if [[ -z "${__TGET##*/}" ]] && [[ ! -e "${__TGET%%/}"/. ]]; then
			fnPrintf "%20.20s: %s" "create directory" "${__TGET%%/}"
			mkdir -p "${__TGET%%/}"
		fi
		# --- force parameter -------------------------------------------------
#		__BACK="${__LINK}.back.${__DATE}"
#		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
#			fnPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
#			mv "${__LINK}" "${__BACK}"
#		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			fnPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			fnPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			fnPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		fnPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
		case "${__RTIV}" in
			r) ln -sr "${__TGET}" "${__LINK}";;
			*) ln -s  "${__TGET}" "${__LINK}";;
		esac
	done
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
		case "${__LIST[1]}" in
			o) ;;
			*) continue;;
		esac
		case "${__LIST[13]}" in
			-) continue;;
			*) ;;
		esac
		case "${__LIST[25]}" in
			-) continue;;
			*) ;;
		esac
		__TGET="${__LIST[25]}/${__LIST[13]##*/}"
		__LINK="${__LIST[13]}"
		# --- check target file path ------------------------------------------
#		if [[ ! -e "${__TGET}" ]]; then
#			touch "${__TGET}"
#		fi
		# --- check target directory ------------------------------------------
		if [[ -n "${__LIST[25]##*-}" ]] && [[ ! -e "${__LIST[25]}"/. ]]; then
			fnPrintf "%20.20s: %s" "create directory" "${__LIST[25]}"
			mkdir -p "${__LIST[25]}"
		fi
		# --- force parameter -------------------------------------------------
#		__BACK="${__LINK}.back.${__DATE}"
#		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
#			fnPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
#			mv "${__LINK}" "${__BACK}"
#		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			fnPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			fnPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			fnPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		fnPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
		ln -s "${__TGET}" "${__LINK}"
	done
}

# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <debstrap data> =========================================================

# -----------------------------------------------------------------------------
# descript: get debstrap data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnGet_debstrap_data() {
	declare       __PATH=""				# full path
	declare       __LINE=""				# work variable
	# --- list data -----------------------------------------------------------
	_LIST_DSTP=()
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_DSTP##*/}"}" \
		"${_PATH_DSTP}"
	do
		if [[ ! -s "${__PATH}" ]]; then
			continue
		fi
		while IFS=$'\n' read -r __LINE
		do
			__LINE="${__LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
			__LINE="${__LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
			__LINE="${__LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
			__LINE="${__LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
			__LINE="${__LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
			__LINE="${__LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
			__LINE="${__LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
			__LINE="${__LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
			__LINE="${__LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
			__LINE="${__LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
			__LINE="${__LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
			__LINE="${__LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
			__LINE="${__LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
			__LINE="${__LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
			__LINE="${__LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
			__LINE="${__LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
			__LINE="${__LINE//:_DIRS_CHRT_:/"${_DIRS_CHRT}"}"
			_LIST_DSTP+=("${__LINE}")
		done < "${__PATH:?}"
		if [[ -n "${_DBGS_FLAG:-}" ]]; then
			printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_DSTP[@]}" 1>&2
		fi
		break
	done
	if [[ -z "${_LIST_DSTP[*]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "data file not found: [${_PATH_DSTP}]" 1>&2
#		exit 1
	fi
}

# shellcheck disable=SC2148
# === <creating> ==============================================================

function fnCreate_debian() {
	fnDebugout ""
	declare -r    __TGET="${1:?}"		 					# target
	declare -r    __CODE="${2:?}"							# code name
	declare -r    __COMP="${3:-}"							# components
	declare -r    __PACK="${4:-}"							# packages
	declare -r    __KEYS="${_DIRS_KEYS}"					# keyring
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"			# target directory
	declare -r    __HOOK="rm -f \$1/etc/hostname"
	declare -r -a __OPTN=( \
		"--variant=minbase" \
		"--mode=sudo" \
		"--format=directory" \
		"${__KEYS:+--keyring=${__KEYS//,/ }}" \
		"${__PACK:+--include=${__PACK//,/ }}" \
		"${__COMP:+--components=${__COMP//,/ }}" \
		"${__HOOK:+--customize-hook=${__HOOK}}" \
		"${__CODE}" \
		"${__DIRS}" \
	)
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	# shellcheck disable=SC2016
	mmdebstrap "${__OPTN[@]}"
}

function fnCreate_rhel() {
	fnDebugout ""
	declare -r    __TGET="${1:?}"		 										# target
	declare -r    __PACK="${2:-}"												# packages
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"								# target directory
	declare -r    __REPO="${_DIRS_CONF}/_repository/${__TGET%-*}.repo"			# repository
	declare -r    __VERS="${__TGET##*-}"										# release verion
	declare -a    __INST=( \
		"--assumeyes" \
		"--config=${__REPO}" \
		"--installroot=${__DIRS}" \
		"--releasever=${__VERS}" \
		"install" \
		"dnf" \
		"dnf-command(config-manager)" \
	)
	case "${__TGET}" in
		rockylinux-*   ) __INST+=("rocky-repos");;
		*              ) __INST+=("${__TGET%-*}-repos");;
	esac
	declare -a    __EPEL=( \
		"${__DIRS}" \
		"dnf" \
		"--assumeyes" \
		"install" \
		"epel-release" \
	)
	declare -a    __INCL=()
	read -r -a __INCL < <(echo "${__PACK//,/ }")
	declare -r -a __OPTN=( \
		"${__DIRS}" \
		"dnf" \
		"--assumeyes" \
		"install" \
		"${__INCL[@]}" \
	)
	declare       __STAT=""				# work variables
	declare       __WORK=""				# work variables
	case "${__TGET}" in
		fedora-*       ) __EPEL=();;
		miraclelinux-* ) __EPEL=();;
		centos-stream-*) ;;
		*              ) ;;
	esac
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	dnf "${__INST[@]:-}"
	mount -t proc /proc/         "${__DIRS}/proc/"                                         && _LIST_RMOV+=("${__DIRS}/proc/" )
	mount --rbind /sys/          "${__DIRS}/sys/"  && mount --make-rslave "${__DIRS}/sys/" && _LIST_RMOV+=("${__DIRS}/sys/" )
	[[ -L "${__DIRS}/etc/resolv.conf" ]] && mkdir -p "${__DIRS}/run/systemd/resolve/"
	echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "${__DIRS}/etc/resolv.conf"
	if [[ -n "${__EPEL[*]:-}" ]]; then
		if ! chroot "${__EPEL[@]:-}"; then
			__STAT="$?"
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%-10.10s: %s${_CODE_ESCP}[m\n${_CODE_ESCP}[m${_CODE_ESCP}[93m%s${_CODE_ESCP}[m\n" "error" "${__TGET}" "EPEL: ${__EPEL[*]:-}"
		fi
	fi
	if ! chroot "${__OPTN[@]:-}"; then
		__STAT="$?"
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%-10.10s: %s${_CODE_ESCP}[m\n${_CODE_ESCP}[m${_CODE_ESCP}[93m%s${_CODE_ESCP}[m\n" "error" "${__TGET}" "OPTN: ${__OPTN[*]:-}"
	fi
	[[ -e "${__DIRS}/etc/resolv.conf.orig" ]] && mv -b "${__DIRS}/etc/resolv.conf.orig" "${__DIRS}/etc/resolv.conf"
	umount --recursive     "${__DIRS}/sys/"
	umount                 "${__DIRS}/proc/"
	if [[ -n "${__STAT:-}" ]]; then
		exit "${__STAT}"
	fi
}

function fnCreate_opensuse() {
	declare -r    __TGET="${1:?}"		 					# target
	declare -r    __PACK="${2:-}"							# packages
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"			# target directory
	declare -r    __REPO="${_DIRS_CONF}/_repository/"		# repository
	declare -r    __VERS="${__TGET##*-}"					# release verion
	declare -a    __INST=()
	read -r -a __INST < <(echo "${__PACK//,/ }")
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	zypper \
		--non-interactive \
		--reposd-dir "${__REPO}" \
		--no-gpg-checks \
		--installroot "${__DIRS}" \
		--releasever "${__VERS}" \
		install \
			"${__INST[@]}"

}

# -----------------------------------------------------------------------------
# descript: executing the action
#   n-ref :   $1   : return value : serialized target data
#   input :   $@   : option parameter
#   output: stdout : message
#   return:        : unused
function fnExec() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare       __TGET=""				# target
	declare -a    __LINE=()				# work variables
	declare -i    I=0					# work variables

	while [[ -n "${1:-}" ]]
	do
		__TGET="$1"
		shift
		for I in "${!_LIST_DSTP[@]}"
		do
			read -r -a __LINE < <(echo "${_LIST_DSTP[I]}")
			if [[ "${__LINE[0]}" != "o" ]]; then
				continue
			fi
			if [[ "${__LINE[1]}" = "${__TGET}" ]]; then
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%-10.10s: %s${_CODE_ESCP}[m\n" "start" "${__LINE[1]}"
				case "${__LINE[1]:-}" in
					debian-*        ) fnCreate_debian "${__LINE[1]}" "${__LINE[2]}" "main,contrib,non-free,non-free-firmware" "${__LINE[5]}";;
					ubuntu-*        ) fnCreate_debian "${__LINE[1]}" "${__LINE[2]}" "main,multiverse,restricted,universe"     "${__LINE[5]}";;
					fedora-*        | \
					centos-stream-* | \
					almalinux-*     | \
					rockylinux-*    | \
					miraclelinux-*  ) fnCreate_rhel "${__LINE[1]}" "${__LINE[5]}";;
					opensuse-*      ) fnCreate_opensuse "${__LINE[1]}" "${__LINE[5]}";;
					*)	break 2;;
				esac
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%-10.10s: %s${_CODE_ESCP}[m\n" "complete" "${__LINE[1]}"
				break
			fi
		done
	done
	__NAME_REFR="${*:-}"
	fnDebug_parameter_list
}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# descript: debug out parameter for skel_mk_custom_iso.sh
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnDebug_parameter() {
	declare       __CHAR="_"			# variable initial letter
	declare       __NAME=""				#          name
	declare       __VALU=""				#          value

#	if [[ -z "${_DBGS_FLAG:-}" ]]; then
#		return
#	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for __CHAR in {A..Z} {a..z} "_"
#	do
		for __NAME in $(eval printf "%q\\\n"  \$\{\!"${__CHAR}"\@\})
		do
			__NAME="${__NAME#\'}"
			__NAME="${__NAME%\'}"
			if [[ -z "${__NAME}" ]]; then
				continue
			fi
			case "${__NAME}" in
				_TEXT_*| \
				__CHAR | \
				__NAME | \
				__VALU ) continue;;
				*) ;;
			esac
			__VALU="$(eval printf "%q" \$\{"${__NAME}":-\})"
			printf "%s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
		done
#	done
}

# -----------------------------------------------------------------------------
# descript: help for skel_mk_custom_iso.sh
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ${_PROG_PATH:-"$0"} [command (options)]

		  create for the container file:
		    debian-nn
		    ubuntu-nn.nn
		    fedora-nn
		    centos-stream-nn
		    almalinux-nn
		    rockylinux-nn
		    miraclelinux-nn
		    opensuse-nn
_EOT_
}

# === main ====================================================================

# -----------------------------------------------------------------------------
# descript: main for skel_mk_custom_iso.sh
#   input :   $@   : option parameter
#   output: stdout : unused
#   return:        : unused
function fnMain() {
	declare -i    __time_start=0		# start of elapsed time
	declare -i    __time_end=0			# end of elapsed time
	declare -i    __time_elapsed=0		# result of elapsed time
	declare -r -a __OPTN_PARM=("${@:-}") # option parameter
#	declare -a    __RETN_PARM=()		# name reference
	declare       __COMD=""				# command type
	declare -a    __OPTN=()				# option parameter
	declare       __TGET=""				# target
	declare       __RANG=""				# range
	declare       __RSLT=""				# result
	declare       __RETN=""				# return value
	declare -a    __MDIA=()				# selected media list by type
	declare -i    __RNUM=0				# record number
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	declare -a    __LIST=()				# work variables
#	declare -i    I=0					# work variables
#	declare -i    J=0					# work variables

	# --- help ----------------------------------------------------------------
	if [[ -z "${__OPTN_PARM[*]:-}" ]]; then
		fnHelp
		exit 0
	fi
	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:-"$(whoami || true)"}" != "root" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "run as root user."
		exit 1
	fi
	# --- get command line ----------------------------------------------------
	set -f -- "${__OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			--dbglog) shift; _DBGS_LOGS="/tmp/${_PROG_PROC}.$(date +"%Y%m%d%H%M%S" || true).log";;
			help    ) shift; fnHelp; exit 0;;
			*       ) shift;;
		esac
	done
	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	fnInitialization					# initialization
	fnGet_debstrap_data					# get debstrap data

	set -f -- "${__OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		__OPTN=()
		case "${1:-}" in
			create  ) shift; fnExec "__RSLT" "${@:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			help    ) shift; fnHelp; break;;
			debug   ) shift; fnDebug_parameter; break;;
			*       ) shift; __OPTN=("${@:-}");;
		esac
		set -f -- "${__OPTN[@]}"
	done

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end-__time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))
}

# *** main processing section *************************************************
	fnMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
