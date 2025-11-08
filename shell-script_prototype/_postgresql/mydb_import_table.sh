#!/bin/bash

###############################################################################
#
#	mydb table data import
#	  developed for debian / postgresql-18
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
#	            : shellcheck -o all -e SC2154 *.sh
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
	declare       _DBGS_WRAP=""			# debug flag (empty: cut to screen width, else: wrap display)
	declare -a    _DBGS_FAIL=()			# debug flag (empty: success, else: failure)

	# --- working directory ---------------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -a    _PROG_PARM=()
	IFS= mapfile -d $'\n' -t _PROG_PARM < <(printf "%s\n" "${@:-}" || true)
	readonly      _PROG_PARM
	declare       _PROG_DIRS="${_PROG_PATH%/*}"
	              _PROG_DIRS="$(realpath "${_PROG_DIRS%/}")"
	readonly      _PROG_DIRS
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
#	declare -r    _PROG_PROC="${_PROG_NAME}.$$"

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
	              _DIRS_TEMP="$(mktemp -qtd -p "${_DIRS_TEMP}" "${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

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

	declare       _FLAG_WIDE=""

	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_CURR="${PWD}"						# current directory

	# --- debug out parameter -------------------------------------------------
	declare -r    _DIRS_DBGS="${_DIRS_WTOP}/${_PROG_NAME}.dbg" # debug out directory
	declare       _DBGS_OUTS=""								# debug out log file name
	              _DBGS_OUTS="${_DIRS_DBGS}/:_COMMAND_:.$(date +"%Y%m%d%H%M%S" || echo "yyyymmddhhmmss").log"
	readonly      _DBGS_OUTS
	mkdir -p   "${_DIRS_DBGS}"

	# --- shared directory parameter ------------------------------------------
	declare       _DIRS_TOPS="/srv"							# top of shared directory
#	declare       _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
#	declare       _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
#	declare       _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
#	declare       _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	declare       _DIRS_USER="${_DIRS_TOPS}/user"			# user file

	# --- shared of user file -------------------------------------------------
	declare       _DIRS_SHAR="${_DIRS_USER}/share"			# shared of user file
	declare       _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
	declare       _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
#	declare       _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
#	declare       _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
#	declare       _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
#	declare       _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
#	declare       _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
#	declare       _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
#	declare       _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
#	declare       _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
#	declare       _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file
#	declare       _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
#	declare       _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file (chroot)

	# --- common data file ----------------------------------------------------
#	declare       _FILE_CONF="common.cfg"					# common configuration file (prefer non-empty current file)
	declare       _FILE_DIST="distribution.dat"				# distribution data file
	declare       _FILE_MDIA="media.dat"					# media data file
#	declare       _FILE_DSTP="debstrap.dat"					# debstrap data file
#	declare       _PATH_CONF="${_DIRS_DATA}/${_FILE_CONF}"	# common configuration file
	declare       _PATH_DIST="${_DIRS_DATA}/${_FILE_DIST}"	# distribution data file
	declare       _PATH_MDIA="${_DIRS_DATA}/${_FILE_MDIA}"	# media data file
#	declare       _PATH_DSTP="${_DIRS_DATA}/${_FILE_DSTP}"	# debstrap data file

	# --- pre-configuration file templates ------------------------------------
#	declare       _FILE_KICK="kickstart_rhel.cfg"			# for rhel
#	declare       _FILE_CLUD="user-data_ubuntu"				# for ubuntu cloud-init
#	declare       _FILE_SEDD="preseed_debian.cfg"			# for debian
#	declare       _FILE_SEDU="preseed_ubuntu.cfg"			# for ubuntu
#	declare       _FILE_YAST="yast_opensuse.xml"			# for opensuse
#	declare       _FILE_AGMA="agama_opensuse.json"			# for opensuse
#	declare       _CONF_KICK="${_DIRS_TMPL}/${_FILE_KICK}"	# for rhel
#	declare       _CONF_CLUD="${_DIRS_TMPL}/${_FILE_CLUD}"	# for ubuntu cloud-init
#	declare       _CONF_SEDD="${_DIRS_TMPL}/${_FILE_SEDD}"	# for debian
#	declare       _CONF_SEDU="${_DIRS_TMPL}/${_FILE_SEDU}"	# for ubuntu
#	declare       _CONF_YAST="${_DIRS_TMPL}/${_FILE_YAST}"	# for opensuse
#	declare       _CONF_AGMA="${_DIRS_TMPL}/${_FILE_AGMA}"	# for opensuse

	# --- shell script --------------------------------------------------------
#	declare       _FILE_ERLY="autoinst_cmd_early.sh"		# shell commands to run early
#	declare       _FILE_LATE="autoinst_cmd_late.sh"			# "              to run late
#	declare       _FILE_PART="autoinst_cmd_part.sh"			# "              to run after partition
#	declare       _FILE_RUNS="autoinst_cmd_run.sh"			# "              to run preseed/run
#	declare       _SHEL_ERLY="${_DIRS_SHEL}/${_FILE_ERLY}"	# shell commands to run early
#	declare       _SHEL_LATE="${_DIRS_SHEL}/${_FILE_LATE}"	# "              to run late
#	declare       _SHEL_PART="${_DIRS_SHEL}/${_FILE_PART}"	# "              to run after partition
#	declare       _SHEL_RUNS="${_DIRS_SHEL}/${_FILE_RUNS}"	# "              to run preseed/run

	# --- tftp / web server network parameter ---------------------------------
#	declare       _SRVR_HTTP="http"		# server connection protocol (http or https)
#	declare       _SRVR_PROT="http"		# server connection protocol (http or tftp)
#	declare       _SRVR_NICS=""			# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
#	declare       _SRVR_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
#	declare       _SRVR_ADDR=""			# IPv4 address          (ex. 192.168.1.11)
#	declare       _SRVR_CIDR=""			# IPv4 cidr             (ex. 24)
#	declare       _SRVR_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0)
#	declare       _SRVR_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
#	declare       _SRVR_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
#	declare       _SRVR_UADR=""			# IPv4 address up       (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
#	declare       _NWRK_HOST=""			# hostname              (ex. sv-server)
#	declare       _NWRK_WGRP=""			# domain                (ex. workgroup)
#	declare       _NICS_NAME=""			# network device name   (ex. ens160)
#	declare       _NICS_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
#	declare       _IPV4_ADDR=""			# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
#	declare       _IPV4_CIDR=""			# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
#	declare       _IPV4_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
#	declare       _IPV4_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
#	declare       _IPV4_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
#	declare       _IPV4_UADR=""			# IPv4 address up       (ex. 192.168.1)
#	declare       _NMAN_NAME=""			# network manager name  (nm_config, ifupdown, loopback)
#	declare       _NTPS_ADDR=""			# ntp server address    (ntp.nict.jp)
#	declare       _NTPS_IPV4=""			# ntp server ipv4 addr  (61.205.120.130)

	# --- menu parameter ------------------------------------------------------
#	declare       _MENU_TOUT="5"		# timeout (sec)
##	declare       _MENU_RESO="1280x720"	# resolution (widht x hight): 16:9
#	declare       _MENU_RESO="854x480"	# "                         : 16:9 (for vmware)
##	declare       _MENU_RESO="1024x768"	# "                         :  4:3
#	declare       _MENU_DPTH="16"		# colors
#	declare       _MENU_MODE="864"		# screen mode (vga=nnn)
#	declare       _MENU_SPLS="splash.png" # splash file

	# --- directory list ------------------------------------------------------
##	declare -a    _LIST_DIRS=()

	# --- symbolic link list --------------------------------------------------
##	declare -a    _LIST_LINK=()

	# --- autoinstall configuration file --------------------------------------
#	declare       _AUTO_INST="autoinst.cfg"

	# --- initial ram disk of mini.iso including preseed ----------------------
#	declare       _MINI_IRAM="initps.gz"

	# --- ipxe menu file ------------------------------------------------------
#	declare       _MENU_IPXE="${_DIRS_TFTP}/autoexec.ipxe"

	# --- grub menu file ------------------------------------------------------
#	declare       _MENU_GRUB="${_DIRS_TFTP}/boot/grub/grub.cfg"

	# --- syslinux menu file --------------------------------------------------
#	declare       _MENU_SLNX="${_DIRS_TFTP}/menu-bios/syslinux.cfg"		# bios
#	declare       _MENU_UEFI="${_DIRS_TFTP}/menu-efi64/syslinux.cfg"	# uefi x86_64

	# --- list data -----------------------------------------------------------
#	declare -a    _LIST_CONF=()			# configuration information
	declare -a    _LIST_DIST=()			# distribution information
	declare -a    _LIST_MDIA=()			# media information
#	declare -a    _LIST_DSTP=()			# debstrap information

	# --- curl / wget parameter -----------------------------------------------
#	declare       _COMD_CURL=""
#	declare       _COMD_WGET=""
#	if command -v curl  > /dev/null 2>&1; then _COMD_CURL="true"; fi
#	if command -v wget  > /dev/null 2>&1; then _COMD_WGET="true"; fi
#	if command -v wget2 > /dev/null 2>&1; then _COMD_WGET="ver2"; fi
#	readonly      _COMD_CURL
#	readonly      _COMD_WGET
#	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
#	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=60" "--quiet")

	# --- rsync parameter -----------------------------------------------------
#	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--update" "--delete")

	# --- ram disk parameter --------------------------------------------------
#	declare -r -a _OPTN_RDSK=("root=/dev/ram0")

	# --- boot type parameter -------------------------------------------------
#	declare -r    _TYPE_ISOB="isoboot"	# iso media boot
#	declare -r    _TYPE_PXEB="pxeboot"	# pxe boot
#	declare -r    _TYPE_USBB="usbboot"	# usb stick boot

	# --- mkosi target distribution -------------------------------------------
#	declare       _TGET_DIST=""			# distribution (fedora, debian, kali, ubuntu, arch, opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
#	declare       _TGET_VERS=""			# release version (code name or number)
#	declare       _TGET_VNUM=""			# "               (number)
#	declare       _TGET_CODE=""			# "               (code name)

	# --- mkosi output image format type --------------------------------------
#	declare       _TGET_MDIA="directory" # format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)

	# --- live media parameter ------------------------------------------------
#	declare       _DIRS_LIVE="LiveOS"	# live / LiveOS
#	declare       _FILE_LIVE="squashfs.img" # filesystem.squashfs / squashfs.img

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: print out of list data
#   input :     $@     : input value
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _DBGS_WRAP : read
#   g-var : _SIZE_COLS : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout_list() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	if [[ -z "${_DBGS_WRAP:-}" ]]; then
		printf "[%-.$((_SIZE_COLS-2))s]\n" "${@:-}" 1>&2
	else
		printf "[%s]\n" "${@:-}" 1>&2
	fi
}

# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :            : unused
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_PARM : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout_parameters() {
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
	[[ -z "${_DBGS_PARM:-}" ]] && return
	for __NAME in "${!__@}"
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME}" in
			''     | \
			__NAME | \
			__VALU ) continue;;
			*) ;;
		esac
		__VALU="${!__NAME:-}"
		printf "${FUNCNAME[1]}: %s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
	done
}

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : section (start, complete, remove, umount, failed, ...)
#   input :     $2     : message
#   input :     $3     : log file name (optional)
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMsgout() {
	{
		case "${1:-}" in
			start    | complete) printf "\033[m${_PROG_NAME}: \033[92m--- %-8.8s: %s ---\033[m\n" "$1" "$2";; # info
			remove   | umount  ) printf "\033[m${_PROG_NAME}: \033[93m    %-8.8s: %s\033[m\n"     "$1" "$2";; # warn
			success            ) printf "\033[m${_PROG_NAME}: \033[92m    %-8.8s: %s\033[m\n"     "$1" "$2";; # info
			failed             ) printf "\033[m${_PROG_NAME}: \033[91m    %-8.8s: %s\033[m\n"     "$1" "$2";; # alert
			*                  ) printf "\033[m${_PROG_NAME}: \033[37m%12.12s: %s\033[m\n"        "$1" "$2";; # normal
		esac
	} | tee -a ${3:+"$3"} 1>&2
}

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: get distribution data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_DIST : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnGet_dist_data() {
	declare       __TGET_PATH="${1:?}"	# target path
	# --- file import ---------------------------------------------------------
	if [[ -z "${__TGET_PATH}" ]]; then
		fnMsgout "failed" "not found: [${__TGET_PATH}]"
		exit 1
	fi
	_LIST_DIST=()
	IFS= mapfile -d $'\n' -t _LIST_DIST < <(expand -t 4 "${__TGET_PATH}" || true)
	if [[ "${#_LIST_DIST[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${__TGET_PATH}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_DIST[@]}"
	fnDebugout_parameters
}

# -----------------------------------------------------------------------------
# descript: get media data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnGet_media_data() {
	declare       __TGET_PATH="${1:?}"	# target path
	# --- file import ---------------------------------------------------------
	if [[ -z "${__TGET_PATH}" ]]; then
		fnMsgout "failed" "not found: [${__TGET_PATH}]"
		exit 1
	fi
	_LIST_MDIA=()
	IFS= mapfile -d $'\n' -t _LIST_MDIA < <(expand -t 4 "${__TGET_PATH}" || true)
	if [[ "${#_LIST_MDIA[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${__TGET_PATH}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_MDIA[@]}"
	fnDebugout_parameters
}

# *** main section ************************************************************

	# === initialize ==========================================================

	# === rootfs ==============================================================

	# === container ===========================================================

	# === squashfs ============================================================

	# === cdfs ================================================================

	# === trap ================================================================

# -----------------------------------------------------------------------------
# descript: trap
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : read
#   g-var : _LIST_RMOV : read
#   g-var : _DIRS_TEMP : read
# shellcheck disable=SC2148,SC2317,SC2329
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

	# === main ================================================================

	fnGet_dist_data  "${_PATH_DIST:?}"	# distribution data file
	fnGet_media_data "${_PATH_MDIA:?}"	# media data file

	__MYDB=(\
		"public.distribution version,name,version_id,code_name,life,release,support,long_term,rhel,kerne,note,wallpaper,create_flag" \
		"public.media        type,entry_flag,entry_name,entry_disp,version,latest,release,support,web_regexp,web_path,web_tstamp,web_size,web_status,iso_path,iso_tstamp,iso_size,iso_volume,rmk_path,rmk_tstamp,rmk_size,rmk_volume,ldr_initrd,ldr_kernel,cfg_path,cfg_tstamp,lnk_path,create_flag" \
	)

	for I in "${!__MYDB[@]}"
	do
		read -r __TABL __FILD < <(echo "${__MYDB[I]}")
		fnMsgout "start" "table: ${__TABL#*.}"
		__LIST=()
		case "${__TABL:-}" in
			'') continue;;
			public.distribution) __LIST=("${_LIST_DIST[@]:1}");;			# distribution information
			public.media       ) __LIST=("${_LIST_MDIA[@]:1}");;			# media information
			*) continue;;
		esac
		__VALU=""
		for J in "${!__LIST[@]}"
		do
			read -r -a __ARRY < <(echo "${__LIST[J]}")
			__LINE=""
			for K in "${!__ARRY[@]}"
			do
				__DATA="${__ARRY[K]:-}"
				__DATA="${__DATA//%20/ }"
				__DATA="${__DATA##-}"
				__DATA="${__DATA:+"'${__DATA}'"}"
				__DATA="${__DATA:-"NULL"}"
				__LINE+="${__LINE:+","}${__DATA:-}"
			done
			__VALU+="${__VALU:+","}(${__LINE:-})"
		done
		fnMsgout "import" "table: ${__TABL#*.}"
		if ! psql --host=localhost --username=dbuser --quiet --dbname=mydb --command="DELETE FROM ${__TABL:?}; INSERT INTO ${__TABL:?}(${__FILD:?}) VALUES ${__VALU};"; then
			fnMsgout "failed" "table: ${__TABL#*.}"
			continue
		fi
		fnMsgout "complete" "table: ${__TABL#*.}"
	done

# --- public.distribution -----------------------------------------------------
#	 0: version       TEXT           NOT NULL
#	 1: name          TEXT           NOT NULL
#	 2: version_id    TEXT           NOT NULL
#	 3: code_name     TEXT
#	 4: life          TEXT
#	 5: release       TEXT
#	 6: support       TEXT
#	 7: long_term     TEXT
#	 8: rhel          TEXT
#	 9: kerne         TEXT
#	10: note          TEXT
#	11: wallpaper     TEXT
#	12: create_flag   TEXT
# --- public.media ------------------------------------------------------------
#	 0: type          TEXT           NOT NULL
#	 1: entry_flag    TEXT           NOT NULL
#	 2: entry_name    TEXT           NOT NULL
#	 3: entry_disp    TEXT           NOT NULL
#	 4: version       TEXT
#	 5: latest        TEXT
#	 6: release       TEXT
#	 7: support       TEXT
#	 8: web_regexp    TEXT
#	 9: web_path      TEXT
#	10: web_tstamp    TIMESTAMP WITH TIME ZONE
#	11: web_size      BIGINT
#	12: web_status    TEXT
#	13: iso_path      TEXT
#	14: iso_tstamp    TEXT
#	15: iso_size      BIGINT
#	16: iso_volume    TEXT
#	17: rmk_path      TEXT
#	18: rmk_tstamp    TIMESTAMP WITH TIME ZONE
#	19: rmk_size      BIGINT
#	20: rmk_volume    TEXT
#	21: ldr_initrd    TEXT
#	22: ldr_kernel    TEXT
#	23: cfg_path      TEXT
#	24: cfg_tstamp    TIMESTAMP WITH TIME ZONE
#	25: lnk_path      TEXT
#	26: create_flag   TEXT
# -----------------------------------------------------------------------------
