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
			if [[ -n "${SUDO_USER:-}" ]] || { [[ -z "${SUDO_USER:-}" ]] && [[ "${_USER_NAME}" != "root" ]]; }; then
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
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_ARCH_OTHR:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')"
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
#	[[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo 0 || echo 1
#}

# --- substr ------------------------------------------------------------------
#function funcSubstr() {
#	echo "${1:${2:-0}:${3:-${#1}}}"
#}

# --- string output -----------------------------------------------------------
# shellcheck disable=SC2317
funcString() {
#	printf "%${1:-"${_SIZE_COLS}"}s" "" | tr ' ' "${2:- }"
	echo "" | IFS= awk '{s=sprintf("%'"$1"'s"," "); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
}

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

# *** function section (sub functions) ****************************************

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       _PATH=""				# file name
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
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}')"}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}')"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}')"}"
		if ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}')"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(funcIPv4GetNetmask "${_SRVR_CIDR}")"}"
	_SRVR_GWAY="${_SRVR_GWAY:-"$(LANG=C ip -4 -brief route list match default | awk '{print $3;}')"}"
	if command -v resolvectl > /dev/null 2>&1; then
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/^Global:/             s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/('"${_SRVR_NICS}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
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
	_MENU_TOUT="${_MENU_TOUT:-50}"
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
	for _PATH in $(find "${_TMPL%/*}" -name "${_TMPL##*/}"\* | sort -r | tail -n +3)
	do
		rm -f "${_PATH:?}"
	done

	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_TMPL}"
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
		MENU_TOUT="${_MENU_TOUT:-}"							# timeout [x100 m sec]
		
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
	for _PATH in $(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}"\* | sort -r | tail -n +3)
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
				sed -e ':l; N; s/\n/\\n/; b l;'
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

# --- Extract a compressed cpio _TGET_FILE ------------------------------------
funcXcpio() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination _DIRS_DESTectory
	shift 2

	  if gzip -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${_TGET_FILE}"
	elif zstd -q -c -t "${_TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${_TGET_FILE}"
	elif xzcat -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${_TGET_FILE}"
	elif lz4cat -t <   "${_TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${_TGET_FILE}"
	elif bzip2 -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${_TGET_FILE}"
	elif lzop -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${_TGET_FILE}"
	fi | (
		if [[ -n "${_DIRS_DEST}" ]]; then
			mkdir -p -- "${_DIRS_DEST}"
			cd -- "${_DIRS_DEST}"
		fi
		cpio "$@"
	)
}

# --- Read bytes out of a file, checking that they are valid hex digits -------
funcReadhex() {
	dd < "${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# --- Check for a zero byte in a file -----------------------------------------
funcCheckzero() {
	dd < "${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# --- Split an initramfs into _TGET_FILEs and call funcXcpio on each ----------
funcSplitinitramfs() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination _DIRS_DESTectory
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
			if funcCheckzero "${_TGET_FILE}" "${_PEND}"; then
				_PEND=$((_PEND + 4))
				while funcCheckzero "${_TGET_FILE}" "${_PEND}"
				do
					_PEND=$((_PEND + 4))
				done
				break
			fi
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
		dd < "${_TGET_FILE}" skip="${_PSTR}" count="$((_PEND - _PSTR))" iflag=skip_bytes 2 > /dev/null |
		(
			if [[ -n "${_DIRS_DEST}" ]]; then
				mkdir -p -- "${_DIRS_DEST}/${_DSUB}"
				cd -- "${_DIRS_DEST}/${_DSUB}"
			fi
			cpio -i "${_OPTS[@]}"
		)
		_PSTR="${_PEND}"
	done
	if [[ "${_PEND}" -gt 0 ]]; then
		_SARC="${_DIRS_TEMP}/${FUNCNAME[0]}"
		mkdir -p "${_SARC%/*}"
		dd < "${_TGET_FILE}" skip="${_PEND}" iflag=skip_bytes 2 > /dev/null > "${_SARC}"
		funcXcpio "${_SARC}" "${_DIRS_DEST:+${_DIRS_DEST}/main}" -i "${_OPTS[@]}"
		rm -f "${_SARC:?}"
	else
		funcXcpio "${_TGET_FILE}" "${_DIRS_DEST}" -i "${_OPTS[@]}"
	fi
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DIMG="${_DIRS_IMGS}/${_TGET_LIST[2]}"	# iso file extraction destination (entry)
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
	declare -r    _MNTP="${_DWRK}/mnt"						# mount point
	declare -r    _FIMG="${_DWRK}/img"						# filesystem image
	declare -r    _FRAM="${_DWRK}/ram"						# initrd filesystem image
	declare       _WORK=""									# work variables
	declare       _PATH=""									# file name
	declare       _TGET=""									# target

	# -------------------------------------------------------------------------
	if [[ "${_TGET_LINE[13]}" = "-" ]] || [[ ! -e "${_TGET_LINE[13]}" ]]; then
		funcPrintf "${_TEXT_BG_YELLOW}%20.20s: %s${_TEXT_RESET}" "not exist" "${_TGET_LINE[13]}"
		return
	fi

	# -------------------------------------------------------------------------
	_WORK="$(funcUnit_conversion "${_TGET_LINE[15]}")"
	funcPrintf "%20.20s: %s" "copy" "${_TGET_LINE[13]} ${_WORK}"

	# --- create directory ----------------------------------------------------
	rm -rf "${_DWRK:?}"
	mkdir -p "${_MNTP}" "${_FIMG}" "${_FRAM}"

	# --- copy iso -> hdd -----------------------------------------------------
	mount -o ro,loop "${_TGET_LINE[13]}" "${_MNTP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_RSYC_OPTN[@]}" "${_MNTP}/." "${_DIMG}/" 2>/dev/null || true
	umount "${_MNTP}"
	chmod -R +r "${_DIMG}/" 2>/dev/null || true

	# --- copy boot loader -> hdd ---------------------------------------------
	for _TGET in "${_TGET_LINE[21]}" "${_TGET_LINE[22]}"
	do
		if [[ "${_TGET}" = "-" ]] || [[ ! -e "${_TGET}" ]]; then
			continue
		fi
		_PATH="${_DIMG}/${_TGET}"
		mkdir -p "${_PATH%/*}"
		funcPrintf "%20.20s: %s" "copy" "${_PATH##*/}"
		nice -n "${_NICE_VALU:-19}" rsync "${_RSYC_OPTN[@]}" "${_TGET}" "${_PATH}" 2>/dev/null || true
		chmod +r "${_PATH}" 2>/dev/null || true
	done

	# --- Check the edition and extract the initrd ----------------------------
	case "${_TGET_LIST[2]}" in
		*-mini-*) ;;					# proceed to extracting the initrd
		*       ) return;;
	esac

	# --- copy initrd -> hdd --------------------------------------------------
	find "${_DIMG}" \( -type f -o -type l \) \( -name 'initrd' -o -name 'initrd.*' -o -name 'initrd-[0-9]*' \) | sort -V | \
	while read -r _PATH
	do
		_TGET="${_PATH#"${_DIMG%/}"/}"
		funcPrintf "%20.20s: %s" "copy" "/${_TGET}"
		funcSplitinitramfs "${_PATH}" "${_FRAM}/${_TGET}"
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
			create  ) ;;
			update  ) ;;
			download) ;;
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
