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
	declare       __PATH=""				# full path
	declare -i    I=0
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
		# --- for pxeboot -----------------------------------------------------
		declare -r -a PAKG_LIST=(\
			"procps" \
			"syslinux-common" \
			"pxelinux" \
			"syslinux-efi" \
			"grub-common" \
			"grub-pc-bin" \
			"grub-efi-amd64-bin" \
			"curl" \
			"rsync" \
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

	# --- rsync parameter -----------------------------------------------------
	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--update" "--delete")

	# --- ram disk parameter --------------------------------------------------
	declare -r -a _OPTN_RDSK=("root=/dev/ram0" "load_ramdisk=1" "ramdisk_size=1024000" "overlay-size=80%")

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
	declare       __TGET_DAT1="${1:?}"	# date1
	declare       __TGET_DAT2="${2:?}"	# date2
	# -------------------------------------------------------------------------
	#  0 : __TGET_DAT1 = __TGET_DAT2
	#  1 : __TGET_DAT1 < __TGET_DAT2
	# -1 : __TGET_DAT1 > __TGET_DAT2
	# emp: error
	if __TGET_DAT1="$(TZ=UTC date -d "${__TGET_DAT1//%20/ }" "+%s")" \
	&& __TGET_DAT2="$(TZ=UTC date -d "${__TGET_DAT2//%20/ }" "+%s")"; then
		  if [[ "${__TGET_DAT1}" -eq "${__TGET_DAT2}" ]]; then
			echo "0"
		elif [[ "${__TGET_DAT1}" -lt "${__TGET_DAT2}" ]]; then
			echo "1"
		elif [[ "${__TGET_DAT1}" -gt "${__TGET_DAT2}" ]]; then
			echo "-1"
		else
			echo ""
		fi
	else
		printf "%20.20s: %s\n" "failed" "${__TGET_DAT1}"
		printf "%20.20s: %s\n" "failed" "${__TGET_DAT2}"
	fi
}

# --- print with screen control -----------------------------------------------
# shellcheck disable=SC2317
function funcPrintf() {
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

# --- IPv4 netmask conversion -------------------------------------------------
# shellcheck disable=SC2317
function funcIPv4GetNetmask() {
	declare -a    __OCTS=()				# octets
	declare -i    __LOOP=0				# work variables
	declare -i    __CALC=0				# "
	# -------------------------------------------------------------------------
	IFS= mapfile -d ':' -t __OCTS < <(echo "${1:?}.")
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
		done < <(printf "%s" "${__OCTS[@]}")
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

# --- IPv6 full address -------------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetFullAddr() {
	declare -r    __FSEP="${1//[^:]/}"
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	# -------------------------------------------------------------------------
	__WORK="$(printf "%$((7-${#__FSEP}))s" "")"
	__WORK="${1/::/::${__WORK// /:}}"
	IFS= mapfile -d ':' -t __ARRY < <(echo -n "${__WORK/%:/::}")
	printf ':%04x' "${__ARRY[@]/#/0x0}" | cut -c 2-
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

# --- get volume id -----------------------------------------------------------
# shellcheck disable=SC2317
function funcGetVolID() {
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

# --- get file information ----------------------------------------------------
# shellcheck disable=SC2317
function funcGetFileinfo() {
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
			funcGetVolID __RSLT "${__ARRY[0]}"
			__VLID="${__RSLT#\'}"
			__VLID="${__VLID%\'}"
			__VLID="${__VLID:--}"
			__ARRY+=("${__VLID// /%20}")	# volume id
		fi
	fi
	__RETN_VALU="${__ARRY[*]}"
}

# --- distro to efi image file name -------------------------------------------
# shellcheck disable=SC2317
function funcDistro2efi() {
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

# === <initrd> ================================================================

# --- Extract a compressed cpio _TGET_FILE ------------------------------------
# shellcheck disable=SC2317
funcXcpio() {
	declare -r    __TGET_FILE="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:-}"	# destination directory
	shift 2

	# shellcheck disable=SC2312
	  if gzip -t       "${__TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${__TGET_FILE}"
	elif zstd -q -c -t "${__TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${__TGET_FILE}"
	elif xzcat -t      "${__TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${__TGET_FILE}"
	elif lz4cat -t <   "${__TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${__TGET_FILE}"
	elif bzip2 -t      "${__TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${__TGET_FILE}"
	elif lzop -t       "${__TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${__TGET_FILE}"
	fi | (
		if [[ -n "${__DIRS_DEST}" ]]; then
			mkdir -p -- "${__DIRS_DEST}"
			# shellcheck disable=SC2312
			cd -- "${__DIRS_DEST}" || exit
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

# --- Split an initramfs into __TGET_FILEs and call funcXcpio on each ----------
# shellcheck disable=SC2317
funcSplit_initramfs() {
	declare -r    __TGET_FILE="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:-}"	# destination directory
	declare -r -a __OPTS=("--preserve-modification-time" "--no-absolute-filenames" "--quiet")
	declare -i    __CONT=0				# count
	declare -i    __PSTR=0				# start point
	declare -i    __PEND=0				# end point
	declare       __MGIC=""				# magic word
	declare -i    __NSIZ=0				# name size
	declare -i    __FSIZ=0				# file size
	declare       __DSUB=""				# sub directory
	declare       __SARC=""				# sub archive

	while true
	do
		__PEND="${__PSTR}"
		while true
		do
			# shellcheck disable=SC2310
			if funcCheckzero "${__TGET_FILE}" "${__PEND}"; then
				__PEND=$((__PEND + 4))
				# shellcheck disable=SC2310
				while funcCheckzero "${__TGET_FILE}" "${__PEND}"
				do
					__PEND=$((__PEND + 4))
				done
				break
			fi
			# shellcheck disable=SC2310
			__MGIC="$(funcReadhex "${__TGET_FILE}" "${__PEND}" "6")" || break
			test "${__MGIC}" = "070701" || test "${__MGIC}" = "070702" || break
			__NSIZ=0x$(funcReadhex "${__TGET_FILE}" "$((__PEND + 94))" "8")
			__FSIZ=0x$(funcReadhex "${__TGET_FILE}" "$((__PEND + 54))" "8")
			__PEND=$((__PEND + 110))
			__PEND=$(((__PEND + __NSIZ + 3) & ~3))
			__PEND=$(((__PEND + __FSIZ + 3) & ~3))
		done
		if [[ "${__PEND}" -eq "${__PSTR}" ]]; then
			break
		fi
		((__CONT+=1))
		if [[ "${__CONT}" -eq 1 ]]; then
			__DSUB="early"
		else
			__DSUB="early${__CONT}"
		fi
		# shellcheck disable=SC2312
		dd if="${__TGET_FILE}" skip="${__PSTR}" count="$((__PEND - __PSTR))" iflag=skip_bytes 2> /dev/null |
		(
			if [[ -n "${__DIRS_DEST}" ]]; then
				mkdir -p -- "${__DIRS_DEST}/${__DSUB}"
				# shellcheck disable=SC2312
				cd -- "${__DIRS_DEST}/${__DSUB}" || exit
			fi
			cpio -i "${__OPTS[@]}"
		)
		__PSTR="${__PEND}"
	done
	if [[ "${__PEND}" -gt 0 ]]; then
		__SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${__SARC%/*}"
		dd if="${__TGET_FILE}" skip="${__PEND}" iflag=skip_bytes 2> /dev/null > "${__SARC}"
		funcXcpio "${__SARC}" "${__DIRS_DEST:+${__DIRS_DEST}/main}" -i "${__OPTS[@]}"
		rm -f "${__SARC:?}"
	else
		funcXcpio "${__TGET_FILE}" "${__DIRS_DEST}" -i "${__OPTS[@]}"
	fi
}

# === <mkiso> =================================================================

# --- create iso image --------------------------------------------------------
# shellcheck disable=SC2317
function funcCreate_iso() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_OUTP="${2:?}"	# output path
	declare -r -a __OPTN_XORR=("${@:3}") # xorrisofs options
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path
	              __PATH="$(mktemp -q "${TMPDIR:-/tmp}/${__PATH_OUTP##*/}.XXXXXX")"
	readonly      __PATH

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- create iso image ----------------------------------------------------
	pushd "${__DIRS_TGET}" > /dev/null || exit
		if ! nice -n "${_NICE_VALU:-19}" xorrisofs "${__OPTN_XORR[@]}" -output "${__PATH}" . > /dev/null 2>&1; then
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [xorriso]" "${__PATH_OUTP##*/}" 1>&2
		else
			if ! cp --preserve=timestamps "${__PATH}" "${__PATH_OUTP}"; then
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [cp]" "${__PATH_OUTP##*/}" 1>&2
			else
				IFS= mapfile -d ' ' -t __LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${__PATH_OUTP}" || true)
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "complete" "${__PATH_OUTP##*/} (${__LIST[4]})" 1>&2
			fi
		fi
		rm -f "${__PATH:?}"
	popd > /dev/null || exit
}

# === <web_tools> =============================================================

# --- get web contents --------------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_contents() {
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

# --- get web header ----------------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_header() {
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

# --- get web address completion ----------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_address() {
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
			2??)						# 2xx (Successful)
				IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
				__PATH="$(printf "%s\n" "${__LIST[@]//%20/ }" | sed -ne 's%^.*<a href="'"${__MATC}"'/*">\(.*\)</a>.*$%\1%gp' | sort -rVu | head -n 1 || true)"
				__PATH="${__PATH:+"${__DIRS%%/}/${__PATH%%/}${__FNAM:+/"${__FNAM##/}"}"}"
				;;
			*)	break;;
		esac
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${__PATH}"
#	return "${__RTCD}"
}

# --- get web information -----------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_info() {
#	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __WORK=""				# work variables

	funcGetWeb_address "__WORK" "${2:?}"
	funcGetWeb_header "${1}" "${__WORK}"
}

# --- get web status message --------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_status() {
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

# === <common> ================================================================

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       __PATH=""				# full path
	declare       __WORK=""				# work variables
	declare       __LINE=""				# work variable
	declare       __NAME=""				# variable name
	declare       __VALU=""				# value

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
	_SRVR_HTTP="${_SRVR_HTTP:-http}"
	_SRVR_PROT="${_SRVR_PROT:-"${_SRVR_HTTP}"}"
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
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
#			PATH_CONF) _PATH_CONF="${__VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${__VALU:-"${_PATH_MDIA:-}"}";;
			CONF_KICK) _CONF_KICK="${__VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${__VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${__VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${__VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${__VALU:-"${_CONF_YAST:-}"}";;
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
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
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

	# --- get media data ------------------------------------------------------
	funcGet_media_data
}

# --- create common configuration file ----------------------------------------
function funcCreate_conf() {
	declare -r    __TMPL="${_PATH_CONF:?}.template"
	declare       __RNAM=""				# rename path
	declare       __PATH=""				# full path

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
	declare       __PATH=""				# full path
	declare       __LINE=""				# work variable

	# --- list data -----------------------------------------------------------
	_LIST_MDIA=()
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_MDIA##*/}"}" \
		"${_PATH_MDIA}"
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
			_LIST_MDIA+=("${__LINE}")
		done < "${__PATH:?}"
		if [[ -n "${_DBGS_FLAG:-}" ]]; then
			printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_MDIA[@]}" 1>&2
		fi
		break
	done
	if [[ -z "${_LIST_MDIA[*]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "data file not found: [${_PATH_MDIA}]" 1>&2
#		exit 1
	fi
}

# --- put media data ----------------------------------------------------------
function funcPut_media_data() {
	declare       __RNAM=""				# rename path
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare -i    I=0
#	declare -i    J=0
	# --- check file exists ---------------------------------------------------
	if [[ -f "${_PATH_MDIA:?}" ]]; then
		__RNAM="${_PATH_MDIA}.$(TZ=UTC find "${_PATH_MDIA}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		printf "%s: \"%s\"\n" "backup" "${__RNAM}" 1>&2
		cp -a "${_PATH_MDIA}" "${__RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	while read -r __PATH
	do
		printf "%s: \"%s\"\n" "remove" "${__PATH}" 1>&2
		rm -f "${__PATH:?}"
	done < <(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}.[0-9]*" | sort -r | tail -n +3  || true)
	# --- list data -----------------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		__LINE="${__LINE//"${_DIRS_RMAK}"/:_DIRS_RMAK_:}"
		__LINE="${__LINE//"${_DIRS_LOAD}"/:_DIRS_LOAD_:}"
		__LINE="${__LINE//"${_DIRS_ISOS}"/:_DIRS_ISOS_:}"
		__LINE="${__LINE//"${_DIRS_IMGS}"/:_DIRS_IMGS_:}"
		__LINE="${__LINE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"
		__LINE="${__LINE//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"
		__LINE="${__LINE//"${_DIRS_KEYS}"/:_DIRS_KEYS_:}"
		__LINE="${__LINE//"${_DIRS_DATA}"/:_DIRS_DATA_:}"
		__LINE="${__LINE//"${_DIRS_CONF}"/:_DIRS_CONF_:}"
		__LINE="${__LINE//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"
		__LINE="${__LINE//"${_DIRS_USER}"/:_DIRS_USER_:}"
		__LINE="${__LINE//"${_DIRS_TFTP}"/:_DIRS_TFTP_:}"
		__LINE="${__LINE//"${_DIRS_SAMB}"/:_DIRS_SAMB_:}"
		__LINE="${__LINE//"${_DIRS_HTML}"/:_DIRS_HTML_:}"
		__LINE="${__LINE//"${_DIRS_HGFS}"/:_DIRS_HGFS_:}"
		__LINE="${__LINE//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"
		read -r -a __LIST < <(echo "${__LINE}")
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]:--}"		# empty
			__LIST[J]="${__LIST[J]// /%20}"	# space
		done
		printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-85s %-47s %-15s %-43s %-85s %-47s %-15s %-43s %-85s %-85s %-85s %-47s %-85s\n" \
			"${__LIST[@]}"
	done > "${_PATH_MDIA:?}"
}

# --- create_directory --------------------------------------------------------
function fncCreate_directory() {
	declare -n    __NAME_REFR="${1:?}"	# name reference
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
			-f | --force) shift; __NAME_REFR="${*:-}"; __FORC="true";;
			*           )        __NAME_REFR="${*:-}"; break;;
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
		# --- force parameter -------------------------------------------------
		__BACK="${__LINK}.back.${__DATE}"
		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			funcPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
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
		# --- force parameter -------------------------------------------------
		__BACK="${__LINK}.back.${__DATE}"
		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			funcPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
		ln -s "${__TGET}" "${__LINK}"
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
# 10: web_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 11: web_size      ( 15)   BIGINT                      "         file size
# 12: web_status    ( 15)   TEXT                        "         download status
# 13: iso_path      ( 85)   TEXT                        iso image file path
# 14: iso_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT          "           file size
# 16: iso_volume    ( 43)   TEXT            "           volume id
# 17: rmk_path      ( 85)   TEXT            remaster    file path
# 18: rmk_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 85)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 85)   TEXT                        kernel    file path
# 23: cfg_path      ( 85)   TEXT                        config    file path
# 24: cfg_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 85)   TEXT                        symlink   directory or file path

# ----- create preseed.cfg ----------------------------------------------------
function funcCreate_preseed() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
	declare       __WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_SEDD}" "${__TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                              \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g                                                }'
			;;
		*)	;;
	esac
	# --- for ubiquity --------------------------------------------------------
	case "${__TGET_PATH}" in
		*_ubiquity_*)
			IFS= __WORK=$(
				sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${__TGET_PATH}" | \
				sed -e 's/\\/\\\\/g'                                                  \
				    -e 's/d-i/ubiquity/'                                              \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'         | \
				sed -e ':l; N; s/\n/\\n/; b l;' || true
			)
			if [[ -n "${__WORK}" ]]; then
				sed -i "${__TGET_PATH}"                                  \
				    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } ' \
				    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } '
				sed -i "${__TGET_PATH}"                                  \
				    -e "\%ubiquity/success_command%i \\${__WORK}"
			fi
			sed -i "${__TGET_PATH}"                       \
			    -e "\%ubiquity/download_updates% s/^#/ /" \
			    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
			    -e "\%ubiquity/reboot%           s/^#/ /"
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# ----- create nocloud --------------------------------------------------------
function funcCreate_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_CLUD}" "${__TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e '/packages:/a \    usrmerge '
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"              \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop.*)
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${__DIRS}/meta-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/network-config" --reference "${__TGET_PATH}"
#	touch -m "${__DIRS}/user-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/vendor-data"    --reference "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	chmod --recursive ugo-x "${__DIRS}"
}

# ----- create kickstart.cfg --------------------------------------------------
function funcCreate_kickstart() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __NAME=""				# "            name
	declare       __SECT=""				# "            section
	declare -r    __ARCH="x86_64"		# base architecture
	declare -r    __ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_KICK}" "${__TGET_PATH}"

	# -------------------------------------------------------------------------
#	__NUMS="\$releasever"
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__NUMS="${__VERS##*-}"
	__NAME="${__VERS%-*}"
	__SECT="${__NAME/-/ }"

	# --- initializing the settings -------------------------------------------
	sed -i "${__TGET_PATH}"                     \
	    -e "/^cdrom$/      s/^/#/             " \
	    -e "/^url[ \t]\+/  s/^/#/g            " \
	    -e "/^repo[ \t]\+/ s/^/#/g            " \
	    -e "s/:_HOST_NAME_:/${__NAME}/        " \
	    -e "s%:__ADDR_:%${__ADDR}%g           " \
	    -e "s%:_DISTRO_:%${__NAME}-${__NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${__TGET_PATH}"    \
			    -e "/^#cdrom$/ s/^#//"
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${__TGET_PATH}"               \
			    -e "/^#.*(${__SECT}).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g     " \
			    -e "/^#repo[ \t]\+/ s/^#//g   } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#.*(web address).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g    } "
			;;
		*)	;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e "/%packages/,/%end/ {"                      \
	    -e "/desktop/ s/^-//g  }"                      \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
}

# ----- create autoyast.xml ---------------------------------------------------
function funcCreate_autoyast() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_YAST}" "${__TGET_PATH}"

	# -------------------------------------------------------------------------
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__NUMS="${__VERS##*-}"

	# --- by media ------------------------------------------------------------
	case "${__TGET_PATH}" in
		*_web*|\
		*_dvd*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/false/true/'
			;;
		*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/true/false/'
			;;
	esac
	# --- by version ----------------------------------------------------------
	case "${__TGET_PATH}" in
		*tumbleweed*)
			sed -i "${__TGET_PATH}"                                    \
			    -e '\%<add_on_products .*>%,\%<\/add_on_products>% { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${__TGET_PATH}"                                          \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%        { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${__NUMS}/%g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%              '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop lxde$/ s/$/ -->/g '          \
	    -e '/^desktop lxde -->/  s/^/<!-- /g'          \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# ----- create pre-configuration file templates -------------------------------
function funcCreate_precon() {
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=()				# option parameter
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path
	declare       __TYPE=""				# configuration type
#	declare       __WORK=""				# work variables
	declare -a    __LINE=()				# work variable
	declare -i    I=0					# work variables

	# --- option parameter ----------------------------------------------------
	__OPTN=()
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			all      ) __OPTN+=("preseed" "nocloud" "kickstart" "autoyast");;
			preseed  | \
			nocloud  | \
			kickstart| \
			autoyast ) __OPTN+=("$1");;
			*        ) break;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	if [[ -z "${__OPTN[*]}" ]]; then
		return
	fi

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create pre-conf file" ""

	# -------------------------------------------------------------------------
	__LIST=()
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LINE < <(echo "${_LIST_MDIA[I]}")
		case "${__LINE[1]}" in			# entry_flag
			o) ;;
			*) continue;;
		esac
		case "${__LINE[23]}" in			# cfg_path
			-) continue;;
			*) ;;
		esac
		__PATH="${__LINE[23]}"
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		if ! echo "${__OPTN[*]}" | grep -q "${__TYPE}"; then
			continue
		fi
		__LIST+=("${__PATH}")
		case "${__PATH}" in
			*dvd.*) __LIST+=("${__PATH/_dvd/_web}");;
			*)	;;
		esac
	done
	IFS= mapfile -d $'\n' -t __LIST < <(IFS=  printf "%s\n" "${__LIST[@]}" | sort -Vu || true)
	# -------------------------------------------------------------------------
	for __PATH in "${__LIST[@]}"
	do
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		case "${__TYPE}" in
			preseed  ) funcCreate_preseed   "${__PATH}";;
			nocloud  ) funcCreate_nocloud   "${__PATH}/user-data";;
			kickstart) funcCreate_kickstart "${__PATH}";;
			autoyast ) funcCreate_autoyast  "${__PATH}";;
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

# === <pxeboot> ===============================================================

# --- file copy ---------------------------------------------------------------
function funcPxeboot_copy() {
	declare -r    __PATH_TGET="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:?}"	# destination directory
	declare       __MNTP=""				# mount point
	declare       __PATH=""				# full path
	              __PATH="$(mktemp -qd "${TMPDIR:-/tmp}/${__DIRS_DEST##*/}.XXXXXX")"
	readonly      __PATH

	if [[ ! -s "${__PATH_TGET}" ]]; then
		return
	fi
	printf "%20.20s: %s\n" "copy" "${__PATH_TGET}" 1>&2
	__MNTP="${__PATH}/mnt"
	rm -rf "${__MNTP:?}"
	mkdir -p "${__MNTP}" "${__DIRS_DEST}"
	mount -o ro,loop "${__PATH_TGET}" "${__MNTP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_OPTN_RSYC[@]}" "${__MNTP}/." "${__DIRS_DEST}/" 2>/dev/null || true
	umount "${__MNTP}"
	chmod -R +r "${__DIRS_DEST}/" 2>/dev/null || true
	rm -rf "${__MNTP:?}"
}

# --- create boot options for preseed -----------------------------------------
function funcPxeboot_preseed() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK="${__WORK:+" "}auto=true preseed/file=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK="${__CONF:+"${__WORK/file=\/cdrom/url=${__CONF}}"}"
		case "${__TGET_LIST[2]}" in
			ubuntu-desktop-*    | \
			ubuntu-legacy-*     ) __WORK="automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*            ) __WORK="${__WORK/\/cdrom/}";;
			*                   ) ;;
		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		case "${__TGET_LIST[2]}" in
			ubuntu-*            ) __WORK+="${__WORK:+" "}netcfg/target_network_config=NetworkManager";;
			*                   ) ;;
		esac
		__WORK+="${__WORK:+" "}netcfg/disable_autoconfig=true"
		__WORK+="${__WORK:+" "}netcfg/choose_interface=\${ethrname}"
		__WORK+="${__WORK:+" "}netcfg/get_hostname=\${hostname}"
		__WORK+="${__WORK:+" "}netcfg/get_ipaddress=\${ipv4addr}"
		__WORK+="${__WORK:+" "}netcfg/get_netmask=\${ipv4mask}"
		__WORK+="${__WORK:+" "}netcfg/get_gateway=\${ipv4gway}"
		__WORK+="${__WORK:+" "}netcfg/get_nameservers=\${ipv4nsvr}"
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		live-debian-*       | \
		live-ubuntu-*       | \
		debian-live-*       ) __WORK+="${__WORK:+" "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*    | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                   ) __WORK+="${__WORK:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]}"
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
#		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for nocloud -----------------------------------------
function funcPxeboot_nocloud() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK="${__WORK:+" "}automatic-ubiquity noprompt autoinstall ds=nocloud\;s=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK="${__CONF:+"${__WORK/\/cdrom/${__CONF}}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		case "${__TGET_LIST[2]}" in
			ubuntu-live-18.04   ) __WORK+="${__WORK:+" "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
			*                   ) __WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]}"
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
#		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for kickstart ---------------------------------------
function funcPxeboot_kickstart() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
#	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
#	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK+="${__WORK:+" "}inst.ks=${__CONF}${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		__WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]/root=\/dev\/ram*[0-9]/}"
	__WORK="${__WORK#"${__WORK%%[!"${IFS}"]*}"}"	# ltrim
	__WORK="${__WORK%"${__WORK##*[!"${IFS}"]}"}"	# rtrim
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}inst.repo=${__IMGS}/${__TGET_LIST[2]}"
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for autoyast ----------------------------------------
function funcPxeboot_autoyast() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
#	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
#	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK+="${__WORK:+" "}autoyast=${__CONF}${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		__WORK+="${__WORK:+" "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
#		case "${__TGET_LIST[2]}" in
#			opensuse-*-15* ) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
#			*              ) ;;
#		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]/root=\/dev\/ram*[0-9]/}"
	__WORK="${__WORK#"${__WORK%%[!"${IFS}"]*}"}"	# ltrim
	__WORK="${__WORK%"${__WORK##*[!"${IFS}"]}"}"	# rtrim
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		opensuse-leap*netinst*      ) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/distribution/leap/${__TGET_LIST[2]##*-}/repo/oss/";;
		opensuse-tumbleweed*netinst*) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
		*                           ) __WORK+="${__WORK:+" "}install=${__IMGS}/${__TGET_LIST[2]}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options -----------------------------------------------------
function funcPxeboot_boot_options() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options

	# --- create boot options -------------------------------------------------
	case "${__TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${__TGET_LIST[23]}" in
				*/preseed/* ) __WORK="$(set -e; funcPxeboot_preseed "${__TGET_LIST[@]}")";;
				*/nocloud/* ) __WORK="$(set -e; funcPxeboot_nocloud "${__TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) __WORK="$(set -e; funcPxeboot_kickstart "${__TGET_LIST[@]}")";;
		opensuse     ) __WORK="$(set -e; funcPxeboot_autoyast "${__TGET_LIST[@]}")";;
		*            ) ;;
	esac
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__BOPT+=("fsck.mode=skip raid=noautodetect${_MENU_MODE:+" vga=${_MENU_MODE}"}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create autoexec.ipxe ----------------------------------------------------
function funcPxeboot_ipxe() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${__PATH_TGET:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			#!ipxe
			
			cpuid --ext 29 && set arch amd64 || set arch x86
			
			dhcp
			
			set optn-timeout 3000
			set menu-timeout 0
			isset \${menu-default} || set menu-default exit
			
			:start
			
			:menu
			menu Select the OS type you want to boot
			item --gap --                           --------------------------------------------------------------------------
			item --gap --                           [ System command ]
			item -- shell                           - iPXE shell
			#item -- shutdown                       - System shutdown
			item -- restart                         - System reboot
			item --gap --                           --------------------------------------------------------------------------
			choose --timeout \${menu-timeout} --default \${menu-default} selected || goto menu
			goto \${selected}
			
			:shell
			echo "Booting iPXE shell ..."
			shell
			goto start
			
			:shutdown
			echo "System shutting down ..."
			poweroff
			exit
			
			:restart
			echo "System rebooting ..."
			reboot
			exit
			
			:error
			prompt Press any key to continue
			exit
			
			:exit
			exit
_EOT_
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
				return
			fi
			__WORK="$(printf "%-40.40s[ %s ]" "item --gap --" "${__TGET_LIST[3]//%20/ }")"
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="${__TGET_LIST[2]}"
			case "${__TGET_LIST[0]}" in
				tool          ) ;;							# tools
				system        ) ;;							# system command
				custom_live   ) ;;							# custom media live mode
				custom_netinst) ;;							# custom media install mode
				live          ) __ENTR="live-${__ENTR}";;	# original media live mode
				*             ) ;;							# original media install mode
			esac
			__WORK="$(printf "%-40.40s%-55.55s%19.19s" "item -- ${__ENTR}" "- ${__TGET_LIST[3]//%20/ } ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
							echo Loading boot files ...
							kernel ipxe/wimboot
							initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
							initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
							initrd -n install.cmd \${cfgaddr}/inst_w${__TGET_LIST[2]##*-}.cmd  install.cmd  || goto error
							initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
							initrd \${knladdr}/boot/bcd                     BCD          || goto error
							initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim     || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							echo Loading boot files ...
							kernel ipxe/wimboot
							initrd \${knladdr}/boot/bcd                     BCD          || goto error
							initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim     || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				memtest86* )			# (memtest86)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							iseq \${platform} efi && set knlfile \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/} || set knlfile \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
							echo Loading boot files ...
							kernel \${knlfile} || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								:${__ENTR}
								echo Loading ${__TGET_LIST[3]//%20/ } ...
								set hostname ${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
								set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
								set ethrname ${_NICS_NAME:-ens160}
								set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
								set ipv4mask ${_IPV4_MASK:-}
								set ipv4gway ${_IPV4_GWAY:-}
								set ipv4nsvr ${_IPV4_NSVR:-}
								set autoinst ${__BOPT[1]:-}
								set networks ${__BOPT[2]:-}
								set language ${__BOPT[3]:-}
								set ramsdisk ${__BOPT[4]:-}
								set isosfile ${__BOPT[5]:-}
								
_EOT_
						)"
					else
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								:${__ENTR}
								echo Loading ${__TGET_LIST[3]//%20/ } ...
								set hostname ${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
								set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
								form                                    Configure Boot Options
								item hostname                           Hostname
								item srvraddr                           Server ip address
								present ||
								set ethrname ${_NICS_NAME:-ens160}
								set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
								set ipv4mask ${_IPV4_MASK:-}
								set ipv4gway ${_IPV4_GWAY:-}
								set ipv4nsvr ${_IPV4_NSVR:-}
								form                                    Configure Boot Options
								item ethrname                           Interface
								item ipv4addr                           IPv4 address
								item ipv4mask                           IPv4 netmask
								item ipv4gway                           IPv4 gateway
								item ipv4nsvr                           IPv4 nameservers
								present ||
								set autoinst ${__BOPT[1]:-}
								set networks ${__BOPT[2]:-}
								set language ${__BOPT[3]:-}
								set ramsdisk ${__BOPT[4]:-}
								set isosfile ${__BOPT[5]:-}
								form                                    Configure Boot Options
								item autoinst                           Auto install
								item networks                           Network
								item language                           Language
								item ramsdisk                           RAM disk
								item isosfile                           ISO file
								present ||
								
_EOT_
						)"
					fi
					__WORK+="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							set options \${autoinst} \${networks} \${language} \${ramsdisk} \${isosfile} ${__BOPT[@]:6}
							echo Loading kernel and initrd ...
							kernel \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/} \${options} --- || goto error
							initrd \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/} || goto error
							boot || goto error
							exit

_EOT_
					)"
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/^:shell$/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create grub.cfg ---------------------------------------------------------
function funcPxeboot_grub() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file
	declare       __SPCS=""				# tabs string (space)

	# --- tab string ----------------------------------------------------------
	if [[ "${__CONT_TABS}" -gt 0 ]]; then
		__SPCS="$(funcString $(("${__CONT_TABS}" * 2)) ' ')"
	else
		__SPCS=""
	fi
	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${_MENU_GRUB:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			set default="0"
			set timeout="-1"
			
			if [ "x\${feature_default_font_path}" = "xy" ] ; then
			  font="unicode"
			else
			  font="\${prefix}/fonts/font.pf2"
			fi
			
			if loadfont "\$font" ; then
			# set lang="ja_JP"
			  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
			  set gfxpayload="keep"
			  if [ "\${grub_platform}" = "efi" ]; then
			    insmod efi_gop
			    insmod efi_uga
			  else
			    insmod vbe
			    insmod vga
			  fi
			  insmod gfxterm
			  insmod gettext
			  terminal_output gfxterm
			fi
			
			set menu_color_normal="cyan/blue"
			set menu_color_highlight="white/blue"
			
			#export lang
			export gfxmode
			export gfxpayload
			export menu_color_normal
			export menu_color_highlight
			
			insmod play
			play 960 440 1 0 4 440 1
			
			menuentry '[ System command ]' {
			  true
			}
			
			menuentry '- System shutdown' {
			  echo "System shutting down ..."
			  halt
			}
			
			menuentry '- System restart' {
			  echo "System rebooting ..."
			  reboot
			}
			
			if [ "\${grub_platform}" = "efi" ]; then
			  menuentry '- Boot from next volume' {
			    exit 1
			  }

			  menuentry '- UEFI Firmware Settings' {
			    fwsetup
			  }
			fi
_EOT_
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
#			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
#				return
#			fi
			__WORK="[ ${__TGET_LIST[3]//%20/ } ... ]"
			case "${__TGET_LIST[3]}" in
				System%20command) return;;
				-               ) __WORK="}\n"                  ;;
				*               ) __WORK="submenu '${__WORK}' {";;
			esac
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="$(printf "%-55.55s%19.19s" "- ${__TGET_LIST[3]//%20/ }  ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							if [ "\${grub_platform}" = "pc" ]; then
							  menuentry '${__ENTR}' {
							    echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							    set isofile="(${_SRVR_PROT},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}"
							    export isofile
							    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							    insmod net
							    insmod http
							    insmod progress
							    echo 'Loading linux ...'
							    linux  memdisk iso raw
							    echo 'Loading initrd ...'
							    initrd \$isofile
							  }
							fi
_EOT_
					)"
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							if [ "\${grub_platform}" = "pc" ]; then
							  menuentry '${__ENTR}' {
							    echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							    set isofile="(${_SRVR_PROT},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}"
							    export isofile
							    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							    insmod net
							    insmod http
							    insmod progress
							    echo 'Loading linux ...'
							    linux  memdisk iso raw
							    echo 'Loading initrd ...'
							    initrd \$isofile
							  }
							fi
_EOT_
					)"
					;;
				memtest86* )			# (memtest86)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							menuentry '${__ENTR}' {
							  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
							  set knladdr="(tftp,${_SRVR_ADDR:?})/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}"
							  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							  insmod net
							  insmod http
							  insmod progress
							  echo 'Loading linux ...'
							  if [ "\${grub_platform}" = "pc" ]; then
							    linux \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
							  else
							    linux \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
							  fi
							}
_EOT_
					)"
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							menuentry '${__ENTR}' {
							  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
_EOT_
					)"
					if [[ -n "${__TGET_LIST[23]##-}" ]] && [[ -n "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK+="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true

								  set hostname="${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
								  set ethrname="${_NICS_NAME:-ens160}"
								  set ipv4addr="${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"
								  set ipv4mask="${_IPV4_MASK:-}"
								  set ipv4gway="${_IPV4_GWAY:-}"
								  set ipv4nsvr="${_IPV4_NSVR:-}"
								  set autoinst="${__BOPT[1]:-}"
_EOT_
						)"
					fi
					__WORK+="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true

							  set networks="${__BOPT[2]:-}"
							  set language="${__BOPT[3]:-}"
							  set ramsdisk="${__BOPT[4]:-}"
							  set isosfile="${__BOPT[5]:-}"
							  set knladdr="(tftp,${_SRVR_ADDR:?})/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}"
							  set options="\${autoinst} \${networks} \${language} \${ramsdisk} \${isosfile} ${__BOPT[@]:6}"
							  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							  insmod net
							  insmod http
							  insmod progress
							  echo 'Loading linux ...'
							  linux  \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/} \${options} ---
							  echo 'Loading initrd ...'
							  initrd \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
							}
_EOT_
					)"
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create syslinux.cfg for bios mode ---------------------------------------
function funcPxeboot_slnx() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file
	declare -i    I=0					# work variables

	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${__PATH_TGET:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			path ./
			prompt 0
			timeout 0
			default vesamenu.c32
			
			menu resolution ${_MENU_RESO/x/ }
			
			menu color screen       * #ffffffff #ee000080 *
			menu color title        * #ffffffff #ee000080 *
			menu color border       * #ffffffff #ee000080 *
			menu color sel          * #ffffffff #76a1d0ff *
			menu color hotsel       * #ffffffff #76a1d0ff *
			menu color unsel        * #ffffffff #ee000080 *
			menu color hotkey       * #ffffffff #ee000080 *
			menu color tabmsg       * #ffffffff #ee000080 *
			menu color timeout_msg  * #ffffffff #ee000080 *
			menu color timeout      * #ffffffff #ee000080 *
			menu color disabled     * #ffffffff #ee000080 *
			menu color cmdmark      * #ffffffff #ee000080 *
			menu color cmdline      * #ffffffff #ee000080 *
			menu color scrollbar    * #ffffffff #ee000080 *
			menu color help         * #ffffffff #ee000080 *
			
			menu margin             4
			menu vshift             5
			menu rows               25
			menu tabmsgrow          31
			menu cmdlinerow         33
			menu timeoutrow         33
			menu helpmsgrow         37
			menu hekomsgendrow      39
			
			menu title - Boot Menu -
			menu tabmsg Press ENTER to boot or TAB to edit a menu entry
			
			label System-command
			  menu label ^[ System command ... ]
			
_EOT_
		case "${__PATH_TGET}" in
			*/menu-bios/*)
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH_TGET}" || true
					label Hardware-info
					  menu label ^- Hardware info
					  com32 hdt.c32

					label System-shutdown
					  menu label ^- System shutdown
					  com32 poweroff.c32

					label System-restart
					  menu label ^- System restart
					  com32 reboot.c32

_EOT_
			;;
			*) ;;
		esac
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
				return
			fi
			__WORK="$(
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
					label ${__TGET_LIST[3]//%20/-}
					  menu label ^[ ${__TGET_LIST[3]//%20/ } ... ]
					
_EOT_
			)"
			sed -i "${__PATH_TGET}" -e "/^label[ \t]\+System-command$/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="$(printf "%-55.55s%19.19s" "- ${__TGET_LIST[3]//%20/ }  ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux  memdisk
									  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}
									  append iso raw

_EOT_
							)"
							;;
						*) ;;
					esac
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux  memdisk
									  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}
									  append iso raw

_EOT_
							)"
							;;
						*) ;;
					esac
					;;
				memtest86* )			# (memtest86)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
									
_EOT_
							)"
							;;
						*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
									
_EOT_
							)"
							;;
					esac
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					__WORK="${__WORK//\$\{hostname\}/"${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"}"
					__WORK="${__WORK//\$\{srvraddr\}/"${_SRVR_PROT}://${_SRVR_ADDR:?}"}"
					__WORK="${__WORK//\$\{ethrname\}/"${_NICS_NAME:-ens160}"}"
					__WORK="${__WORK//\$\{ipv4addr\}/"${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"}"
					__WORK="${__WORK//\$\{ipv4mask\}/"${_IPV4_MASK:-}"}"
					__WORK="${__WORK//\$\{ipv4gway\}/"${_IPV4_GWAY:-}"}"
					__WORK="${__WORK//\$\{ipv4nsvr\}/"${_IPV4_NSVR:-}"}"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								label ${__TGET_LIST[2]}
								  menu label ^${__ENTR}
								  linux  /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
								  initrd /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
								  append ${__BOPT[@]:3}
								
_EOT_
						)"
					else
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								label ${__TGET_LIST[2]}
								  menu label ^${__ENTR}
								  linux  /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
								  initrd /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
								  append ${__BOPT[@]}
								
_EOT_
						)"
					fi
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/^label[ \t]\+System-command$/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create pxeboot menu -----------------------------------------------------
function funcPxeboot() {
	declare -i    __TABS=0				# tabs count
	declare       __LIST=()				# work variable
	declare -i    I=0					# work variables

	rm -f "${_MENU_IPXE:?}" \
	      "${_MENU_GRUB:?}" \
		  "${_MENU_SLNX:?}" \
		  "${_MENU_UEFI:?}"
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
		printf "%20.20s: %s\n" "start" "${__LIST[2]}" 1>&2
		# --- update ----------------------------------------------------------
		case "${1:-}" in
			update  ) ;;
			*       ) funcPxeboot_copy "${__LIST[13]}" "${_DIRS_IMGS}/${__LIST[2]}";;
		esac
		# --- create pxeboot menu ---------------------------------------------
		case "${1:-}" in
			download) ;;
			*       )
				funcPxeboot_ipxe "${_MENU_IPXE}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_grub "${_MENU_GRUB}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_slnx "${_MENU_SLNX}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_slnx "${_MENU_UEFI}" "${__TABS:-"0"}" "${__LIST[@]}"
				;;
		esac
		case "${__LIST[1]}" in
			m)							# (menu)
				if [[ "${__TABS:-"0"}" -eq 0 ]]; then
					__TABS=1
				else
					__TABS=0
				fi
				;;
			o) ;;						# (output)
			*) ;;						# (hidden)
		esac
	done
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
		usage: [sudo] ./${_PROG_PATH:-"${0##*/}"}${_PROG_PATH##*/} [command (options)]
		
		  pxeboot menu files:
		    create
		      empty             : mirroring copy by rsync
		      update            : without copying iso image
		
		  list files:
		    list [create|update|download]
		      empty             : display of list data
		      create            : update / download list files
		
		  config files:
		    conf [create|all|(preseed|nocloudkickstart|autoyast)|version]
		      create            : create common configuration file
		      all               : all config files (without common config file)
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

	# --- help ----------------------------------------------------------------
	if [[ -z "${__OPTN_PARM[*]:-}" ]]; then
		funcHelp
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
			help    ) shift; funcHelp; exit 0;;
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
	funcInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			create  ) shift; funcPxeboot "create"  ;;
			update  ) shift; funcPxeboot "update"  ;;
			download) shift; funcPxeboot "download";;
			link    )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						create   ) shift; fncCreate_directory _RETN_PARM "${@:-}"; funcPut_media_data;;
						update   ) shift;;
						download ) shift;;
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
						update   ) shift;;
						download ) shift;;
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
				funcCreate_precon __RETN_PARM "${@:-}"
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
		_RETN_PARM=("$@")
		IFS="${_COMD_IFS:-}"
		set -f -- "${_RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
	done

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end-__time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
