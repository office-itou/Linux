#!/bin/bash

###############################################################################
#
#	template shell script
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2025/11/01
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2025/11/01 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#
###############################################################################

# *** global section **********************************************************

	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)
	declare       _DBGS_LOGS=""			# debug file (empty: normal, else: debug)
	declare       _DBGS_PARM=""			# debug file (empty: normal, else: debug)
	declare       _DBGS_SIMU=""			# debug flag (empty: normal, else: simulation)
	declare -a    _DBGS_FAIL=()			# debug flag (empty: success, else: failure)

	# --- working directory ---------------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -a    _PROG_PARM=()
	read -r -a _PROG_PARM < <(printf "%s\n" "${@:-}")
	readonly      _PROG_PARM
	declare       _PROG_DIRS="${_PROG_PATH%/*}"
	              _PROG_DIRS="$(realpath "${_PROG_DIRS%/}")"
	readonly      _PROG_DIRS
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"

	# --- user data -----------------------------------------------------------
	declare -r    _USER_NAME="${USER:-"${LOGNAME:-"$(whoami || true)"}"}"		# execution user name
	declare -r    _SUDO_USER="${SUDO_USER:-"${_USER_NAME}"}"					# real user name
	declare -r    _SUDO_HOME="${SUDO_HOME:-"${HOME:-}"}"						# "         home directory

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:-}" != "root" ]]; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "run as root user."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "your username is ${_USER_NAME}."
		exit 1
	fi

	# --- working directory ---------------------------------------------------
	declare -r    _DIRS_WTOP="${_SUDO_HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
	mkdir -p   "${_DIRS_WTOP}"

	# --- temporary directory -------------------------------------------------
	declare       _DIRS_TEMP="${_DIRS_WTOP}"
	              _DIRS_TEMP="$(mktemp -qtd -p "${_DIRS_TEMP}" "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- set minimum display size --------------------------------------------
	declare -i    _SIZE_ROWS=25
	declare -i    _SIZE_COLS=80

	if command -v tput > /dev/null 2>&1; then
		_SIZE_ROWS=$(tput lines)
		_SIZE_COLS=$(tput cols)
	fi
	[[ "${_SIZE_ROWS:-0}" -lt 25 ]] &&_SIZE_ROWS=25
	[[ "${_SIZE_COLS:-0}" -lt 80 ]] &&_SIZE_COLS=80
	readonly      _SIZE_ROWS
	readonly      _SIZE_COLS

	declare       _TEXT_SPCE=""
	              _TEXT_SPCE="$(printf "%${_SIZE_COLS:-80}s" "")"
	readonly      _TEXT_SPCE

	declare -r    _TEXT_GAP1="${_TEXT_SPCE// /-}"
	declare -r    _TEXT_GAP2="${_TEXT_SPCE// /=}"

	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_CURR="${PWD}"						# current directory

	# --- shared directory parameter ------------------------------------------
	declare       _DIRS_TOPS="/srv"							# top of shared directory
	declare       _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
	declare       _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
	declare       _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
	declare       _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	declare       _DIRS_USER="${_DIRS_TOPS}/user"			# user file

	# --- shared of user file -------------------------------------------------
	declare       _DIRS_SHAR="${_DIRS_USER}/share"			# shared of user file
	declare       _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
	declare       _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
	declare       _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
	declare       _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
	declare       _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
	declare       _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
	declare       _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
	declare       _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
	declare       _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
	declare       _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
	declare       _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file
	declare       _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
	declare       _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file (chroot)

	# --- common data file (prefer non-empty current file) --------------------
	declare       _FILE_CONF="common.cfg"					# common configuration file
	declare       _FILE_DIST="distribution.dat"				# distribution data file
	declare       _FILE_MDIA="media.dat"					# media data file
	declare       _FILE_DSTP="debstrap.dat"					# debstrap data file
	declare       _PATH_CONF=""								# common configuration file
	              _PATH_CONF="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_DATA}" -maxdepth 1 -name "${_FILE_CONF:?}" -size +0 -print -quit)"
	readonly      _PATH_CONF
	declare       _PATH_DIST=""								# distribution data file
	              _PATH_DIST="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_DATA}" -maxdepth 1 -name "${_FILE_DIST:?}" -size +0 -print -quit)"
	readonly      _PATH_DIST
	declare       _PATH_MDIA=""								# media data file
	              _PATH_MDIA="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_DATA}" -maxdepth 1 -name "${_FILE_MDIA:?}" -size +0 -print -quit)"
	readonly      _PATH_MDIA
	declare       _PATH_DSTP=""								# debstrap data file
	              _PATH_DSTP="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_DATA}" -maxdepth 1 -name "${_FILE_DSTP:?}" -size +0 -print -quit)"
	readonly      _PATH_DSTP

	# --- pre-configuration file templates ------------------------------------
	declare       _FILE_KICK="kickstart_rhel.cfg"			# for rhel
	declare       _FILE_CLUD="user-data_ubuntu"				# for ubuntu cloud-init
	declare       _FILE_SEDD="preseed_debian.cfg"			# for debian
	declare       _FILE_SEDU="preseed_ubuntu.cfg"			# for ubuntu
	declare       _FILE_YAST="yast_opensuse.xml"			# for opensuse
	declare       _FILE_AGMA="agama_opensuse.json"			# for opensuse
	declare       _CONF_KICK=""								# for rhel
	              _CONF_KICK="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_KICK:?}" -size +0 -print -quit)"
	readonly      _CONF_KICK
	declare       _CONF_CLUD=""								# for ubuntu cloud-init
	              _CONF_CLUD="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_CLUD:?}" -size +0 -print -quit)"
	readonly      _CONF_CLUD
	declare       _CONF_SEDD=""								# for debian
	              _CONF_SEDD="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_SEDD:?}" -size +0 -print -quit)"
	readonly      _CONF_SEDD
	declare       _CONF_SEDU=""								# for ubuntu
	              _CONF_SEDU="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_SEDU:?}" -size +0 -print -quit)"
	readonly      _CONF_SEDU
	declare       _CONF_YAST=""								# for opensuse
	              _CONF_YAST="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_YAST:?}" -size +0 -print -quit)"
	readonly      _CONF_YAST
	declare       _CONF_AGMA=""								# for opensuse
	              _CONF_AGMA="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_AGMA:?}" -size +0 -print -quit)"
	readonly      _CONF_AGMA

	# --- shell script --------------------------------------------------------
	declare       _FILE_ERLY="autoinst_cmd_early.sh"		# shell commands to run early
	declare       _FILE_LATE="autoinst_cmd_late.sh"			# "              to run late
	declare       _FILE_PART="autoinst_cmd_part.sh"			# "              to run after partition
	declare       _FILE_RUNS="autoinst_cmd_run.sh"			# "              to run preseed/run
	declare       _SHEL_ERLY=""								# shell commands to run early
	              _SHEL_ERLY="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_ERLY:?}" -size +0 -print -quit)"
	readonly      _SHEL_ERLY
	declare       _SHEL_LATE=""								# "              to run late
	              _SHEL_LATE="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_LATE:?}" -size +0 -print -quit)"
	readonly      _SHEL_LATE
	declare       _SHEL_PART=""								# "              to run after partition
	              _SHEL_PART="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_PART:?}" -size +0 -print -quit)"
	readonly      _SHEL_PART
	declare       _SHEL_RUNS=""								# "              to run preseed/run
	              _SHEL_RUNS="$(find "${_DIRS_CURR}" "${_SUDO_HOME}" "${_DIRS_TMPL}" -maxdepth 1 -name "${_FILE_RUNS:?}" -size +0 -print -quit)"
	readonly      _SHEL_RUNS

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
	declare       _IPV4_UADR=""			# IPv4 address up       (ex. 192.168.1)
	declare       _NMAN_NAME=""			# network manager name  (nm_config, ifupdown, loopback)
	declare       _NTPS_ADDR=""			# ntp server address    (ntp.nict.jp)
	declare       _NTPS_IPV4=""			# ntp server ipv4 addr  (61.205.120.130)

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT="5"		# timeout (sec)
#	declare       _MENU_RESO="1280x720"	# resolution (widht x hight): 16:9
	declare       _MENU_RESO="854x480"	# "                         : 16:9 (for vmware)
#	declare       _MENU_RESO="1024x768"	# "                         :  4:3
	declare       _MENU_DPTH=""			# colors
	declare       _MENU_MODE="791"		# screen mode (vga=nnn)
	declare       _MENU_SPLS="splash.png" # splash file

	# --- directory list ------------------------------------------------------
#	declare -a    _LIST_DIRS=()

	# --- symbolic link list --------------------------------------------------
#	declare -a    _LIST_LINK=()

	# --- autoinstall configuration file --------------------------------------
#	declare       _AUTO_INST=""

	# --- initial ram disk of mini.iso including preseed ----------------------
#	declare       _MINI_IRAM=""

	# --- ipxe menu file ------------------------------------------------------
#	declare       _MENU_IPXE=""

	# --- grub menu file ------------------------------------------------------
#	declare       _MENU_GRUB=""

	# --- syslinux menu file --------------------------------------------------
#	declare       _MENU_SLNX=""			# bios
#	declare       _MENU_UEFI=""			# uefi x86_64

	# --- list data -----------------------------------------------------------
	declare -a    _LIST_DIST=()			# distribution information
	declare -a    _LIST_MDIA=()			# media information
	declare -a    _LIST_DSTP=()			# debstrap information

	# --- curl / wget parameter -----------------------------------------------
#	declare       _COMD_CURL=""
#	declare       _COMD_WGET=""
#	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
#	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=60" "--quiet")
#	if command -v curl  > /dev/null 2>&1; then _COMD_CURL="true"; fi
#	if command -v wget  > /dev/null 2>&1; then _COMD_WGET="true"; fi
#	if command -v wget2 > /dev/null 2>&1; then _COMD_WGET="ver2"; fi
#	readonly      _COMD_CURL
#	readonly      _COMD_WGET

	# --- rsync parameter -----------------------------------------------------
#	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--update" "--delete")

	# --- ram disk parameter --------------------------------------------------
#	declare -r -a _OPTN_RDSK=("root=/dev/ram0")

	# --- boot type parameter -------------------------------------------------
#	declare -r    _TYPE_ISOB="isoboot"	# iso media boot
#	declare -r    _TYPE_PXEB="pxeboot"	# pxe boot
#	declare -r    _TYPE_USBB="usbboot"	# usb stick boot

	# --- mkosi target distribution -------------------------------------------
	declare       _TGET_DIST=""			# distribution (fedora, debian, kali, ubuntu, arch, opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
	declare       _TGET_VERS=""			# release version (code name or number)
	declare       _TGET_VNUM=""			# "               (number)
	declare       _TGET_CODE=""			# "               (code name)

	# --- mkosi output image format type --------------------------------------
	declare       _TGET_MDIA="directory" # format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)

	# --- live media parameter ------------------------------------------------
	declare       _DIRS_LIVE="LiveOS"	# live / LiveOS
	declare       _FILE_LIVE="squashfs.img" # filesystem.squashfs / squashfs.img

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: debug print
#   input :     $@     : input value
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2317,SC2329
function fnDebugout() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	printf "${FUNCNAME[1]}: %q\n" "${@:-}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :            : unused
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2317,SC2329
function fnDebugout_parameters() {
	[[ -z "${_DBGS_PARM:-}" ]] && return
	printf "${FUNCNAME[1]}: %q\n" "${!__@}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: print out of list data
#   input :     $@     : input value
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _SIZE_COLS : read
# shellcheck disable=SC2317,SC2329
function fnDebugout_list() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	printf "[%-.$((_SIZE_COLS-2))s]\n" "${@:-}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: print out of all variables
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var :            : unused
#   memo  : https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
# shellcheck disable=SC2317,SC2329
function fnDebug_allparameter() {
	declare       __CHAR=""				# variable initial letter
	declare       __NAME=""				#          name
	declare       __VALU=""				#          value
	for __CHAR in {A..Z} {a..z} "_" "__"
	do
		for __NAME in $(eval printf "%q\\\n" \$\{\!"${__CHAR}"\@\})
		do
			__NAME="${__NAME#\'}"
			__NAME="${__NAME%\'}"
			[[ -z "${__NAME:-}" ]] && continue
			case "${__NAME}" in
				__CHAR | \
				__NAME | \
				__VALU ) continue;;
				*) ;;
			esac
			__VALU="$(eval printf "%q" \$\{"${__NAME}":-\})"
			printf "%s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
		done
	done
}

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : section (start, complete, remove, umount, failed, ...)
#   input :     $2     : message
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2317,SC2329
function fnMsgout() {
	{
		case "${1:-}" in
			start    | complete) printf "\033[m${_PROG_NAME}: \033[92m--- %-8.8s: %s ---\033[m\n" "$1" "$2";;
			remove   | umount  ) printf "\033[m${_PROG_NAME}: \033[93m    %-8.8s: %s\033[m\n"     "$1" "$2";;
			failed             ) printf "\033[m${_PROG_NAME}: \033[91m    %-8.8s: %s\033[m\n"     "$1" "$2";;
			*                  ) printf "\033[m${_PROG_NAME}: \033[37m%12.12s: %s\033[m\n"        "$1" "$2";;
		esac
	} 1>&2
}

# -----------------------------------------------------------------------------
# descript: executing the convert
#   input :     $@     : option parameter
#   output:   stdout   : unused
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2317,SC2329
function fnExec_convert() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	if ! convert "${__TGET_OPTN[@]}"; then
		__RTCD="$?"
		fnMsgout "failed" "convert (${__RTCD})"
		fnMsgout "failed" "convert ${__TGET_OPTN[*]}"
	fi
	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: executing the mkosi
#   input :     $@     : option parameter
#   output:   stdout   : unused
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2317,SC2329
function fnExec_mkosi() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	if ! mkosi "${__TGET_OPTN[@]}"; then
		__RTCD="$?"
		fnMsgout "failed" "mkosi (${__RTCD})"
		fnMsgout "failed" "mkosi ${__TGET_OPTN[*]}"
	fi
	return "${__RTCD}"
}

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _PATH_CONF : read
#   g-var : _FILE_CONF : read
#   g-var : _LIST_CONF : write
# shellcheck disable=SC2317,SC2329
function fnGet_conf_data() {
	declare -r    __SIZE="$((_SIZE_COLS-2))"
	# --- list data -----------------------------------------------------------
	if [[ -z "${_PATH_CONF}" ]]; then
		fnMsgout "failed" "not found: [${_FILE_CONF}]"
		exit 1
	fi
	_LIST_CONF=()
	IFS= mapfile -d $'\n' -t _LIST_CONF < <(expand -t 4 "${_PATH_CONF}" || true)
	if [[ "${#_LIST_CONF[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${_PATH_CONF}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_CONF[@]}"
	fnDebugout_parameters
}

# -----------------------------------------------------------------------------
# descript: get distribution data
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _PATH_DIST : read
#   g-var : _FILE_DIST : read
#   g-var : _LIST_DIST : write
# shellcheck disable=SC2317,SC2329
function fnGet_dist_data() {
	declare -r    __SIZE="$((_SIZE_COLS-2))"
	# --- list data -----------------------------------------------------------
	if [[ -z "${_PATH_DIST}" ]]; then
		fnMsgout "failed" "not found: [${_FILE_DIST}]"
		exit 1
	fi
	_LIST_DIST=()
	IFS= mapfile -d $'\n' -t _LIST_DIST < <(expand -t 4 "${_PATH_DIST}" || true)
	if [[ "${#_LIST_DIST[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${_PATH_DIST}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_DIST[@]}"
	fnDebugout_parameters
}

# *** main section ************************************************************

	# === initialize ==========================================================

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnInitialize() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	fnGet_conf_data						# get common configuration data
	fnGet_dist_data						# get distribution data

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}

	# === rootfs ==============================================================

# -----------------------------------------------------------------------------
# descript: rootfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnRootfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare -r -a __OPTN=(\
		--force \
		--wipe-build-dir \
		--architecture=x86-64 \
		--root-password=r00t \
		--bootable=yes \
		--bootloader=systemd-boot \
		--selinux-relabel=yes \
		--with-network=yes \
		${__TGET_INCL:+--include="${__TGET_INCL}"} \
		${__TGET_MDIA:+--format="${__TGET_MDIA}"} \
		${__DIRS_WDIR:+--output-directory="${__DIRS_WDIR}"} \
		${__DIRS_CACH:+--cache-directory="${__DIRS_CACH}"} \
		${__DIRS_CACH:+--package-cache-dir="${__DIRS_CACH}"} \
		${__TGET_DIST:+--distribution="${__TGET_DIST%%-*}"} \
		${__TGET_VERS:+--release="${__TGET_VERS}"} \
		${__COMD_MKOS:+"${__COMD_MKOS}"} \
	)

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}

	# === container ===========================================================

# -----------------------------------------------------------------------------
# descript: container
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnContainer() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"
	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}

	# === squashfs ============================================================

# -----------------------------------------------------------------------------
# descript: squashfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnSquashfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"
	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}

	# === cdfs ================================================================

# -----------------------------------------------------------------------------
# descript: cdfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnCdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"
	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}

	# === trap ================================================================

# -----------------------------------------------------------------------------
# descript: trap
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : read
#   g-var : _LIST_RMOV : read
#   g-var : _DIRS_TEMP : read
# shellcheck disable=SC2317,SC2329
function fnTrap() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __MPNT=""				# mount point
	declare -i    I=0

	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	if [[ "${#_DBGS_FAIL[@]}" -gt 0 ]]; then
		fnMsgout "failed" "${_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]}"
		fnMsgout "failed" "Working files will be deleted when this shell exits."
		read -r -p "Press enter key to exit..."
	fi

	_LIST_RMOV=("${_LIST_RMOV[@]}")
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
		if mountpoint --quiet "${__PATH}"; then
			fnMsgout "umount" "${__PATH}"
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}"
		fi
		case "${__PATH}" in
			"${_DIRS_TEMP:?}")
				fnMsgout "remove" "${__PATH}"
				rm -rf "${__PATH:?}"
				;;
			*) ;;
		esac
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	fnDebugout_parameters
}

	# === help ================================================================

function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ${_PROG_PATH:-"$0"} [command (options)]
_EOT_
	exit 0
}

	# === main ================================================================

# -----------------------------------------------------------------------------
# descript: main
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _DBGS_FAIL : unused
function fnMain() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	fnInitialize
	fnRootfs
	fnContainer
	fnSquashfs
	fnCdfs

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

	[[ "${#_PROG_PARM[@]}" -le 0 ]] && fnHelp

	# --- get command line ----------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--testparm ) shift; fnDebug_allparameter; exit 0;;
			--debug    | \
			--dbg      ) shift; _DBGS_FLAG="true"; set -x;;
			--debugout | \
			--dbgout   ) shift; _DBGS_FLAG="true";;
			--dbglog   ) shift; _DBGS_LOGS="/tmp/${_PROG_PROC}.$(date +"%Y%m%d%H%M%S" || true).log";;
			--debugparm| \
			--dbgparm  ) shift; _DBGS_PARM="true";;
			--simu     ) shift; _DBGS_SIMU="true";;
			help       ) shift; fnHelp;;
			*          ) shift;;
		esac
	done

	if set -o | grep -qE "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	trap fnTrap EXIT

	declare -i    __time_start=0		# elapsed time: start
	declare -i    __time_end=0			# "           : end
	declare -i    __time_elapsed=0		# "           : result

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	fnMain
	fnDebugout_parameters

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))

	exit 0

# *** memo ********************************************************************

# text color: \033[xxm
#	|   color    | bright | reverse|  dark  |
#	| black      |   90   |   40   |   30   |
#	| red        |   91   |   41   |   31   |
#	| green      |   92   |   42   |   32   |
#	| yellow     |   93   |   43   |   33   |
#	| blue       |   94   |   44   |   34   |
#	| purple     |   95   |   45   |   35   |
#	| light blue |   96   |   46   |   36   |
#	| white      |   97   |   47   |   37   |
# text attribute
#	| reset            | \033[m   | reset all attributes  |
#	| bold             | \033[1m  |                       |
#	| faint            | \033[2m  |                       |
#	| italic           | \033[3m  |                       |
#	| underline        | \033[4m  | set underline         |
#	| blink            | \033[5m  |                       |
#	| fast blink       | \033[6m  |                       |
#	| reverse          | \033[7m  | set reverse display   |
#	| conceal          | \033[8m  |                       |
#	| strike           | \033[9m  |                       |
#	| gothic           | \033[20m |                       |
#	| double underline | \033[21m |                       |
#	| normal           | \033[22m |                       |
#	| no italic        | \033[23m | reset underline       |
#	| no underline     | \033[24m |                       |
#	| no blink         | \033[25m |                       |
#	| no reverse       | \033[27m | reset reverse display |
# source: https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233

### eof #######################################################################
