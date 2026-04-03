#!/bin/bash

###############################################################################
#
#	
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2025/11/01
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/04/01 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#	            : shellcheck -o all -e SC2154 *.sh
#
###############################################################################

# *** global section **********************************************************

	# --- include -------------------------------------------------------------
	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
#	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)
	declare       _DBGS_PARM=""			# debug flag (empty: normal, else: debug out parameter)

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
																				# "         home directory
	declare -r    _SUDO_HOME="${SUDO_HOME:-"$(eval echo "~${SUDO_USER:-"${USER:?}"}")"}"

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:-}" != "root" ]]; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "run as root user."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "your username is ${_USER_NAME}."
		exit 1
	fi

	# --- check the command ---------------------------------------------------
	__COMD="gawk"
	if ! command -v "${__COMD}" > /dev/null 2>&1; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "${__COMD} is not installed."
		exit 1
	fi

	# --- working directory ---------------------------------------------------
	declare -r    _DIRS_WTOP="${_SUDO_HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
	mkdir -p   "${_DIRS_WTOP}"
	chown "${_SUDO_USER:?}": "${_DIRS_WTOP}"

	# --- temporary directory -------------------------------------------------
	declare       _DIRS_TEMP="${_DIRS_WTOP}"
	              _DIRS_TEMP="$(mktemp -qd "${_DIRS_TEMP}/${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- command line parameter ----------------------------------------------
	declare       _COMD_LINE=""			# command line parameter
	              _COMD_LINE="$(cat /proc/cmdline || true)"
	readonly      _COMD_LINE
	declare       _NICS_NAME=""			# nic if name   (ex. ens160)
	declare       _NICS_MADR=""			# nic if mac    (ex. 00:00:00:00:00:00)
	declare       _NICS_AUTO=""			# ipv4 dhcp     (ex. empty or dhcp)
	declare       _NICS_IPV4=""			# ipv4 address  (ex. 192.168.1.1)
	declare       _NICS_MASK=""			# ipv4 netmask  (ex. 255.255.255.0)
	declare       _NICS_BIT4=""			# ipv4 cidr     (ex. 24)
	declare       _NICS_DNS4=""			# ipv4 dns      (ex. 192.168.1.254)
	declare       _NICS_GATE=""			# ipv4 gateway  (ex. 192.168.1.254)
	declare       _NICS_FQDN=""			# hostname fqdn (ex. sv-server.workgroup)
	declare       _NICS_HOST=""			# hostname      (ex. sv-server)
	declare       _NICS_WGRP=""			# domain        (ex. workgroup)
	declare       _NMAN_FLAG=""			# nm_config, ifupdown, loopback
	declare       _DIRS_TGET=""			# target directory
	declare       _FILE_ISOS=""			# iso file name
	declare       _FILE_SEED=""			# preseed file name
	# --- target --------------------------------------------------------------
	declare       _TGET_VIRT=""			# virtualization (ex. vmware)
	declare       _TGET_CHRT=""			# is chgroot     (empty: none, else: chroot)
	declare       _TGET_CNTR=""			# is container   (empty: none, else: container)
	# --- set system parameter ------------------------------------------------
	declare       _DIST_NAME=""			# distribution name (ex. debian)
	declare       _DIST_VERS=""			# release version   (ex. 13)
	declare       _DIST_CODE=""			# code name         (ex. trixie)
	declare       _ROWS_SIZE="25"		# screen size: rows
	declare       _COLS_SIZE="80"		# screen size: columns
	declare       _TEXT_SPCE=""			# space
	declare       _TEXT_GAP1=""			# gap1
	declare       _TEXT_GAP2=""			# gap2
	declare       _COMD_BBOX=""			# busybox (empty: inactive, else: active )
										# copy option
	declare       _OPTN_COPY="--preserve=timestamps"
	# --- network parameter ---------------------------------------------------
	declare       _NTPS_ADDR="ntp.nict.jp"		# ntp server address
	declare       _NTPS_IPV4="61.205.120.130"	# ntp server ipv4 address
	declare -r    _NTPS_FBAK="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	declare -r    _IPV6_LHST="::1"				# ipv6 local host address
	declare -r    _IPV4_LHST="127.0.0.1"		# ipv4 local host address
	declare -r    _IPV4_DUMY="127.0.1.1"		# ipv4 dummy address
	declare       _IPV4_UADR=""			# IPv4 address up   (ex. 192.168.1)
	declare       _IPV4_LADR=""			# IPv4 address low  (ex. 1)
	declare       _IPV6_ADDR=""			# IPv6 address      (ex. ::1)
	declare       _IPV6_CIDR=""			# IPv6 cidr         (ex. 64)
	declare       _IPV6_FADR=""			# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	declare       _IPV6_UADR=""			# IPv6 address up   (ex. 0000:0000:0000:0000)
	declare       _IPV6_LADR=""			# IPv6 address low  (ex. 0000:0000:0000:0001)
	declare       _IPV6_RADR=""			# IPv6 reverse addr (ex. ...)
	declare       _LINK_ADDR=""			# LINK address      (ex. fe80::1)
	declare       _LINK_CIDR=""			# LINK cidr         (ex. 64)
	declare       _LINK_FADR=""			# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	declare       _LINK_UADR=""			# LINK address up   (ex. fe80:0000:0000:0000)
	declare       _LINK_LADR=""			# LINK address low  (ex. 0000:0000:0000:0001)
	declare       _LINK_RADR=""			# LINK reverse addr (ex. ...)
	# --- firewalld -----------------------------------------------------------
	declare -r    _FWAL_ZONE="home_use"	# firewalld default zone
										# firewalld service name
	declare -r    _FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
										# firewalld port
	declare -r    _FWAL_PORT="0-65535/tcp 0-65535/udp"
	# --- samba parameter -----------------------------------------------------
	declare -r    _SAMB_USER="sambauser"	# force user
	declare -r    _SAMB_GRUP="sambashare"	# force group
	declare -r    _SAMB_GADM="sambaadmin"	# admin group
											# nsswitch.conf
	declare -r    _SAMB_NSSW="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
	declare       _SHEL_NLIN=""				# login shell (disallow system login to samba user)
	# --- shared directory parameter ------------------------------------------
	declare       _DIRS_TOPS=""			# top of shared directory
	declare       _DIRS_HGFS=""			# vmware shared
	declare       _DIRS_HTML=""			# html contents#
	declare       _DIRS_SAMB=""			# samba shared
	declare       _DIRS_TFTP=""			# tftp contents
	declare       _DIRS_USER=""			# user file
	# --- shared of user file -------------------------------------------------
	declare       _DIRS_PVAT=""			# private contents directory
	declare       _DIRS_SHAR=""			# shared contents directory
	declare       _DIRS_CONF=""			# configuration file
	declare       _DIRS_DATA=""			# data file
	declare       _DIRS_KEYS=""			# keyring file
	declare       _DIRS_MKOS=""			# mkosi configuration files
	declare       _DIRS_TMPL=""			# templates for various configuration files
	declare       _DIRS_SHEL=""			# shell script file
	declare       _DIRS_IMGS=""			# iso file extraction destination
	declare       _DIRS_ISOS=""			# iso file
	declare       _DIRS_LOAD=""			# load module
	declare       _DIRS_RMAK=""			# remake file
	declare       _DIRS_CACH=""			# cache file
	declare       _DIRS_CTNR=""			# container file
	declare       _DIRS_CHRT=""			# container file (chroot)
	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_VADM="/var/admin"	# top of admin working directory
	declare       _DIRS_INST=""			# auto-install working directory
	declare       _DIRS_BACK=""			# top of backup directory
	declare       _DIRS_ORIG=""			# original file directory
	declare       _DIRS_INIT=""			# initial file directory
	declare       _DIRS_SAMP=""			# sample file directory
	declare       _DIRS_LOGS=""			# log file directory
	# --- auto install --------------------------------------------------------
	declare       _FILE_ERLY="autoinst_cmd_early.sh"	# shell commands to run early
	declare       _FILE_LATE="autoinst_cmd_late.sh"		# "              to run late
	declare       _FILE_PART="autoinst_cmd_part.sh"		# "              to run after partition
	declare       _FILE_RUNS="autoinst_cmd_run.sh"		# "              to run preseed/run
	# --- common data file (prefer non-empty current file) --------------------
	declare       _FILE_CONF="common.cfg"				# common configuration file
	declare       _FILE_DIST="distribution.dat"			# distribution data file
	declare       _FILE_MDIA="media.dat"				# media data file
	declare       _FILE_DSTP="debstrap.dat"				# debstrap data file
	# --- pre-configuration file templates ------------------------------------
	declare       _FILE_KICK="kickstart_rhel.cfg"		# for rhel
	declare       _FILE_CLUD="user-data_ubuntu"			# for ubuntu cloud-init
	declare       _FILE_SEDD="preseed_debian.cfg"		# for debian
	declare       _FILE_SEDU="preseed_ubuntu.cfg"		# for ubuntu
	declare       _FILE_YAST="yast_opensuse.xml"		# for opensuse
	declare       _FILE_AGMA="agama_opensuse.json"		# for opensuse

	# === for creations =======================================================

	# --- common data file (prefer non-empty current file) --------------------
	declare       _PATH_CONF=":_DIRS_DATA_:/:_FILE_CONF_:"	# common configuration file
	declare       _PATH_DIST=":_DIRS_DATA_:/:_FILE_DIST_:"	# distribution data file
	declare       _PATH_MDIA=":_DIRS_DATA_:/:_FILE_MDIA_:"	# media data file
	declare       _PATH_DSTP=":_DIRS_DATA_:/:_FILE_DSTP_:"	# debstrap data file
	# --- pre-configuration file templates ------------------------------------
	declare       _PATH_KICK=":_DIRS_TMPL_:/:_FILE_KICK_:"	# for rhel
	declare       _PATH_CLUD=":_DIRS_TMPL_:/:_FILE_CLUD_:"	# for ubuntu cloud-init
	declare       _PATH_SEDD=":_DIRS_TMPL_:/:_FILE_SEDD_:"	# for debian
	declare       _PATH_SEDU=":_DIRS_TMPL_:/:_FILE_SEDU_:"	# for ubuntu
	declare       _PATH_YAST=":_DIRS_TMPL_:/:_FILE_YAST_:"	# for opensuse
	declare       _PATH_AGMA=":_DIRS_TMPL_:/:_FILE_AGMA_:"	# for opensuse
	# --- shell script --------------------------------------------------------
	declare       _PATH_ERLY=":_DIRS_SHEL_:/:_FILE_ERLY_:"	# shell commands to run early
	declare       _PATH_LATE=":_DIRS_SHEL_:/:_FILE_LATE_:"	# "              to run late
	declare       _PATH_PART=":_DIRS_SHEL_:/:_FILE_PART_:"	# "              to run after partition
	declare       _PATH_RUNS=":_DIRS_SHEL_:/:_FILE_RUNS_:"	# "              to run preseed/run
# --- tftp menu ---------------------------------------------------------------
	declare       _FILE_IPXE="autoexec.ipxe"				# ipxe
	declare       _FILE_GRUB="boot/grub/grub.cfg"			# grub
	declare       _FILE_SLNX="menu-bios/syslinux.cfg"		# syslinux (bios)
	declare       _FILE_UEFI="menu-efi64/syslinux.cfg"		# syslinux (efi64)
	declare       _PATH_IPXE=":_DIRS_TFTP_:/:_FILE_IPXE_:"	# ipxe
	declare       _PATH_GRUB=":_DIRS_TFTP_:/:_FILE_GRUB_:"	# grub
	declare       _PATH_SLNX=":_DIRS_TFTP_:/:_FILE_SLNX_:"	# syslinux (bios)
	declare       _PATH_UEFI=":_DIRS_TFTP_:/:_FILE_UEFI_:"	# syslinux (efi64)

	# --- tftp / web server network parameter ---------------------------------
	declare       _SRVR_HTTP="http"							# server connection protocol (http or https)
	declare       _SRVR_PROT="http"							# server connection protocol (http or tftp)
	declare       _SRVR_NICS="ens160"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
	declare       _SRVR_MADR="00:00:00:00:00:00"			#                mac    (ex. 00:00:00:00:00:00)
	declare       _SRVR_ADDR="192.168.1.11"					# IPv4 address          (ex. 192.168.1.11)
	declare       _SRVR_CIDR="24"							# IPv4 cidr             (ex. 24)
	declare       _SRVR_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0)
	declare       _SRVR_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _SRVR_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _SRVR_UADR="192.168.1"					# IPv4 address up       (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
	declare       _NWRK_HOST="sv-:_DISTRO_:"				# hostname              (ex. sv-server)
	declare       _NWRK_WGRP="workgroup"					# domain                (ex. workgroup)
	declare       _NICS_NAME="ens160"						# network device name   (ex. ens160)
	declare       _NICS_MADR=""								#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR="192.168.1.1"					# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR="24"							# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _IPV4_UADR=""								# IPv4 address up       (ex. 192.168.1)
	declare       _NMAN_NAME=""								# network manager name  (nm_config, ifupdown, loopback)
	declare       _NTPS_ADDR="ntp.nict.jp"					# ntp server address    (ntp.nict.jp)
	declare       _NTPS_IPV4="61.205.120.130"				# ntp server ipv4 addr  (61.205.120.130)

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT="5"							# timeout (sec)
	declare       _MENU_RESO="854x480"						# resolution (widht x hight)
	declare       _MENU_DPTH="16"							# colors
	declare       _MENU_MODE="864"							# screen mode (vga=nnn)
	declare       _MENU_SPLS="splash.png"					# splash file

	# --- auto install --------------------------------------------------------
	declare       _AUTO_INST="autoinst.cfg"					# autoinstall configuration file
	declare       _MINI_IRAM="initps.gz"					# initial ram disk of mini.iso including preseed

	# --- list data -----------------------------------------------------------
	declare -a    _LIST_PARM=()								# PARAMETER LIST
	declare -a    _LIST_CONF=()								# common configuration data
	declare -a    _LIST_DIST=()								# distribution information
	declare -a    _LIST_MDIA=()								# media information
	declare -a    _LIST_DSTP=()								# debstrap information
															# media type
	declare -a    _LIST_TYPE=("mini" "netinst" "dvd" "liveinst" "live" "tool" "clive" "cnetinst" "system")
	declare -r -i _OSET_MDIA=2								# media information data offset

	# --- wget / curl options -------------------------------------------------
	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=60" "--quiet")
	declare       _COMD_WGET=""
	if command -v wget2 > /dev/null 2>&1; then
		_COMD_WGET="curl"
	elif command -v wget > /dev/null 2>&1; then
		_COMD_WGET="wget"
	elif command -v curl > /dev/null 2>&1; then
		_COMD_WGET="curl"
	fi
	readonly      _COMD_WGET

	# --- rsync options -------------------------------------------------------
	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--delete")

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: ltrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnLtrim() {
	echo -n "${1#"${1%%[^"${2:-"${IFS}"}"]*}"}"	# ltrim
}

# -----------------------------------------------------------------------------
# descript: rtrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnRtrim() {
	echo -n "${1%"${1##*[^"${2:-"${IFS}"}"]}"}"	# rtrim
}

# -----------------------------------------------------------------------------
# descript: trim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnTrim() {
	declare       __WORK=""
	__WORK="$(fnLtrim "${1:-}"      "${2:-}")"
	__WORK="$(fnRtrim "${__WORK:-}" "${2:-}")"
	echo -n "${__WORK:-}"
	unset __WORK
}

# -----------------------------------------------------------------------------
# descript: dirname
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnDirname() {
	declare       __WORK=""				# work
	__WORK="${1%"${1##*/}"}"
	[[ "${__WORK:-}" != "/" ]] && __WORK="${__WORK%"${__WORK##*[^/]}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: basename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnBasename() {
	declare       __WORK=""				# work
	__WORK="${1#"${1%/*}"}"
	__WORK="${__WORK:-"${1:-}"}"
	__WORK="${__WORK#"${__WORK%%[^/]*}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: extension
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnExtension() {
	declare       __BASE=""				# basename
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__WORK="${__BASE#"${__BASE%.*}"}"
	__WORK="${__WORK#"${__WORK%%[^.]*}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: filename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
function fnFilename() {
	declare       __BASE=""				# basename
	declare       __EXTN=""				# extension
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__EXTN="$(fnExtension "${__BASE:-}")"
	__WORK="${__BASE%".${__EXTN:-}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : title (program name, etc)
#   input :     $2     : section (start, complete, remove, umount, failed, ...)
#   input :     $3     : message
#   output:   stdout   : message
#   return:            : unused
function fnMsgout() {
	case "${2:-}" in
		start    | complete)
			case "${3:-}" in
				*/*/*) printf "\033[m${1:-}\033[m: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}\033[m:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		active             ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		inactive           ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		caution            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}\033[m:     \033[36m%-8.8s: %s\033[m\n"        "${2#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}\033[m: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}\033[m: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}\033[m: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}\033[m: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
	esac
}

# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
function fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
function fnStrmsg() {
	declare      ___TEXT="${1:-}"
	declare      ___TXT1=""
	declare      ___TXT2=""
	___TXT1="$(echo "${___TEXT:-}" | cut -c -3)"
	___TXT2="$(echo "${___TEXT:-}" | cut -c "$((${#___TXT1}+2+${#2}+1+${#_PROG_NAME}+16))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TEXT
	unset ___TXT1
	unset ___TXT2
}

# -----------------------------------------------------------------------------
# descript: get web information data
#   input :     $1     : target url
#   output:   stdout   : output (url,last-modified,content-length,check-date,code,message)
#   return:            : unused
function fnGetWebinfo() {
	awk -v _urls="${1:?}" -v _wget="${2:-"wget"}" '
		function fnAwk_GetWebstatus(_retn, _code,  _mesg) {
			# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			_mesg="Unknown Code"
			switch (_code) {
				case 100: _mesg="Continue"; break
				case 101: _mesg="Switching Protocols"; break
				case 200: _mesg="OK"; break
				case 201: _mesg="Created"; break
				case 202: _mesg="Accepted"; break
				case 203: _mesg="Non-Authoritative Information"; break
				case 204: _mesg="No Content"; break
				case 205: _mesg="Reset Content"; break
				case 206: _mesg="Partial Content"; break
				case 300: _mesg="Multiple Choices"; break
				case 301: _mesg="Moved Permanently"; break
				case 302: _mesg="Found"; break
				case 303: _mesg="See Other"; break
				case 304: _mesg="Not Modified"; break
				case 305: _mesg="Use Proxy"; break
				case 306: _mesg="(Unused)"; break
				case 307: _mesg="Temporary Redirect"; break
				case 308: _mesg="Permanent Redirect"; break
				case 400: _mesg="Bad Request"; break
				case 401: _mesg="Unauthorized"; break
				case 402: _mesg="Payment Required"; break
				case 403: _mesg="Forbidden"; break
				case 404: _mesg="Not Found"; break
				case 405: _mesg="Method Not Allowed"; break
				case 406: _mesg="Not Acceptable"; break
				case 407: _mesg="Proxy Authentication Required"; break
				case 408: _mesg="Request Timeout"; break
				case 409: _mesg="Conflict"; break
				case 410: _mesg="Gone"; break
				case 411: _mesg="Length Required"; break
				case 412: _mesg="Precondition Failed"; break
				case 413: _mesg="Content Too Large"; break
				case 414: _mesg="URI Too Long"; break
				case 415: _mesg="Unsupported Media Type"; break
				case 416: _mesg="Range Not Satisfiable"; break
				case 417: _mesg="Expectation Failed"; break
				case 418: _mesg="(Unused)"; break
				case 421: _mesg="Misdirected Request"; break
				case 422: _mesg="Unprocessable Content"; break
				case 426: _mesg="Upgrade Required"; break
				case 500: _mesg="Internal Server Error"; break
				case 501: _mesg="Not Implemented"; break
				case 502: _mesg="Bad Gateway"; break
				case 503: _mesg="Service Unavailable"; break
				case 504: _mesg="Gateway Timeout"; break
				case 505: _mesg="HTTP Version Not Supported"; break
				default : break
			}
			_mesg=sprintf("%-3s(%s)", _code, _mesg)
			gsub(" ", "%20", _mesg)
			_retn[1]=_mesg
		}
		function fnAwk_GetWebdata(_retn, _urls, _wget,  i, j, _list, _line, _code, _leng, _lmod, _date, _lcat, _ptrn, _dirs, _file, _rear, _mesg, _chek) {
			# --- set pattern part --------------------------------------------
			_ptrn=""
			_dirs=""
			_rear=""
			match(_urls, "/[^/ \t]*\\[[^/ \t]+\\][^/ \t]*")
			if (RSTART == 0) {
				if (_wget == "curl") {
					_comd="LANG=C curl --location --http1.1 --no-progress-meter --no-progress-bar --remote-time --show-error --fail --retry-max-time 3 --retry 3 --connect-timeout 60 --head "_urls" 2>&1"
				} else {
					_comd="LANG=C wget --tries=3 --timeout=60 --quiet --spider --server-response --output-document=- "_urls" 2>&1"
				}
			} else {
				_ptrn=substr(_urls, RSTART+1, RLENGTH-1)
				_dirs=substr(_urls, 1, RSTART-1)
				_rear=substr(_urls, RSTART+RLENGTH+1)
				if (_wget == "curl") {
					_comd="LANG=C curl --location --http1.1 --no-progress-meter --no-progress-bar --remote-time --show-error --fail --retry-max-time 3 --retry 3 --connect-timeout 60 --show-headers --output - "_dirs" 2>&1"
				} else {
					_comd="LANG=C wget --tries=3 --timeout=60 --quiet --server-response --output-document=- "_dirs" 2>&1"
				}
			}
			# --- get web data ------------------------------------------------
			delete _list
			i=0
			while (_comd | getline) {
				_line=$0
				sub("\r", "", _line)
				_list[i++]=_line
			}
			close(_comd)
			# --- get results -------------------------------------------------
			_code=""
			_leng=""
			_lmod=""
			_date=""
			_lcat=""
			_file=""
			for (i in _list) {
				_line=_list[i]
				sub("^[ \t]+", "", _line)
				sub("[ \t]+$", "", _line)
				switch (tolower(_line)) {
					case /^http\/[0-9]+.[0-9]+/:
						sub("[^ \t]+[ \t]+", "", _line)
						sub("[^0-9]+$", "", _line)
						_code=_line
						break
					case /^content-length:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_leng=_line
						break
					case /^last-modified:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_date="TZ=UTC date -d \""_line"\" \"+%Y-%m-%d%%20%H:%M:%S%z\""
						_date | getline _lmod
						break
					case /^location:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_lcat=_line
						break
					default:
						break
				}
				if (length(_ptrn) == 0) {
					continue
				}
				match(_line, "<a href=\""_ptrn"/*\".*>")
				if (RSTART == 0) {
					continue
				}
				match(_line, "\""_ptrn"/*\"")
				if (RSTART == 0) {
					continue
				}
				_file=substr(_line, RSTART, RLENGTH)
				sub("^\"", "", _file)
				sub("\"$", "", _file)
				sub("^/", "", _file)
				sub("/$", "", _file)
			}
			# --- get url -----------------------------------------------------
			delete _mesg
			fnAwk_GetWebstatus(_mesg, _code)
			_date="TZ=UTC date \"+%Y-%m-%d%%20%H:%M:%S%z\""
			_date | getline _chek
			_retn[1]=_urls
			_retn[2]="-"
			_retn[3]="-"
			_retn[4]=_chek
			_retn[5]=_code
			_retn[6]=_mesg[1]
			# --- check the results -------------------------------------------
			if (_code < 200 || _code > 299) {
				return							# other than success
			}
			# --- get file information ----------------------------------------
			if (length(_ptrn) == 0) {
				_retn[2]=_lmod
				_retn[3]=_leng
				return
			}
			# --- pattern completion ------------------------------------------
			_urls=_dirs
			if (length(_file) > 0) {
				_urls=_urls"/"_file
			}
			if (length(_rear) > 0) {
				_urls=_urls"/"_rear
			}
			fnAwk_GetWebdata(_retn, _urls, _wget)
			return
		}
		BEGIN {
			fnAwk_GetWebdata(_retn, _urls, _wget)
			for (i in _retn) {
				if (length(_retn[i]) == 0) {_retn[i]="-"}
				gsub(" ", "%20", _retn[i])
			}
			printf("%s %s %s %s %s %s", _retn[1], _retn[2], _retn[3], _retn[4], _retn[5], _retn[6])
		}
	' || true
}

# -----------------------------------------------------------------------------
# descript: get file information data
#   input :     $1     : file name
#   output:   stdout   : output (path,time stamp,size,volume id)
#   return:            : unused
function fnGetFileinfo() {
	declare       __INFO=""				# file path / size / timestamp
	declare       __VLID=""				# volume id
	declare -a    __LIST=()				# data list
	__LIST=("-" "-" "-")
	__VLID="-"
	__INFO="$(LANG=C find "${1%/*}" -name "${1##*/}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s")"
	if [[ -n "${__INFO:-}" ]]; then
		read -r -a __LIST < <(echo "${__INFO}")
		__LIST[1]="$(TZ=UTC date -d "${__LIST[1]//%20/ }" "+%Y-%m-%d%%20%H:%M:%S%z")"
		__VLID="$(blkid -s LABEL -o value "${1}")"
	fi
	printf "%s %s %s %s" "${__LIST[0]// /%20}" "${__LIST[1]// /%20}" "${__LIST[2]// /%20}" "${__VLID// /%20}"
}

# -----------------------------------------------------------------------------
# descript: message output (debug out)
#   input :     $1     : title
#   input :     $@     : list
#   output:   stdout   : message
#   return:            : unused
function fnDbgout() {
	declare       ___STRT=""
	declare       ___ENDS=""
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	shift
	fnMsgout "\033[36m${_PROG_NAME:-}" "-debugout" "${___STRT}"
	while [[ -n "${1:-}" ]]
	do
		if [[ "${1%%,*}" != "debug" ]] || [[ -n "${_DBGS_FLAG:-}" ]]; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "\033[36m${_PROG_NAME:-}" "-debugout" "${___ENDS}"
	unset ___STRT
	unset ___ENDS
}

# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnDbgparameters() {
	[[ -z "${_DBGS_PARM:-}" ]] && return
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
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
#	unset __NAME __VALU
}

# -----------------------------------------------------------------------------
# descript: Print all global variables (_[A..Z]*)
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   memo  : https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
function fnDbgparameters_all() {
#	[[ -z "${_DBGS_PARM:-}" ]] && return

	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	eval printf "%q\\\n" "\${!_"{{A..Z},{a..z}}"@}" | while read -r __NAME
	do
		[[ -n "${__NAME:-}" ]] && declare -p "${__NAME}"
	done
	unset __NAME

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: find command
#   input :     $1     : command name
#   output:   stdout   : output
#   return:            : unused
function fnFind_command() {
	find "${_DIRS_TGET:-}"/bin/ "${_DIRS_TGET:-}"/sbin/ "${_DIRS_TGET:-}"/usr/bin/ "${_DIRS_TGET:-}"/usr/sbin/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
}

# -----------------------------------------------------------------------------
# descript: wget / curl file download
#   input :     $1     : target url
#   input :     $2     : target path
#   output:   stdout   : message
#   return:            : unused
function fnDownload() {
	declare -r    __TGET_URLS="${1:?}"
	declare -r    __TGET_PATH="${2:?}"
	declare -r    __TGET_SIZE="${3:-}"
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare       __SIZE=""
	declare       __REAL=""
	declare       __OWNR=""
	declare       __PATH=""
	declare       __DIRS=""
	declare       __FNAM=""
#	declare -a    __OPTN=()

	[[ -n "${__TGET_SIZE:-}" ]] && __SIZE="$(echo "${__TGET_SIZE}" | numfmt --to=iec-i --suffix=B || true)"
	printf "\033[mstart   : %s\033[m\n" "${__TGET_PATH##*/}${__SIZE:+" [${__SIZE}]"}"
	__DIRS="$(fnDirname  "${__TEMP}")"
	__FNAM="$(fnBasename "${__TEMP}")"
	case "${_COMD_WGET:-}" in
		curl)
			if ! LANG=C curl "${_OPTN_CURL[@]}" --progress-bar --continue-at - --create-dirs --output-dir "${__DIRS}" --output "${__FNAM}" "${__TGET_URLS}" 2>&1; then
				printf "\033[m\033[41mfailed  : %s [%s]\033[m\n" "curl" "${__TGET_URLS}"
				return
			fi
			;;
		*)
			if ! LANG=C wget "${_OPTN_WGET[@]}" --continue --show-progress --progress=bar --output-document="${__TEMP}" "${__TGET_URLS}" 2>&1; then
				printf "\033[m\033[41mfailed  : %s [%s]\033[m\n" "wget" "${__TGET_URLS}"
				return
			fi
			;;
	esac
	if ! cp --preserve=timestamps "${__TEMP}" "${__TGET_PATH}"; then
		printf "\033[m\033[41mfailed  : %s\033[m\n" "${__TGET_PATH}"
		return
	fi
	__REAL="$(realpath "${__TGET_PATH}")"
#	if [[ -z "${__REAL%"${_DIRS_SAMB:-}"*}" ]]; then
		__DIRS="$(fnDirname "${__TGET_PATH}")"
		__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
		chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
		chmod g+rw,o+r "${__TGET_PATH}"
#	fi
	rm -rf "${__TEMP:?}"
	printf "\033[m\033[92mcomplete: %s\033[m\n" "${__TGET_PATH##*/}"
}

# -----------------------------------------------------------------------------
# descript: rsync
#   input :     $1     : target iso file
#   input :     $2     : destination directory
#   output:   stdout   : output
#   return:            : unused
function fnRsync() {
	declare -r    __TGET_ISOS="${1:?}"	# target iso file
	declare -r    __TGET_DEST="${2:?}"	# destination directory
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare       __SRCS=""
	declare       __DEST=""

	case "${__TGET_ISOS}" in
		*.iso) ;;
		*    ) return;;
	esac
	if [[ ! -s "${__TGET_ISOS}" ]]; then
		return
	fi
	rm -rf "${__TEMP:?}"
	mkdir -p "${__TEMP}" "${__TGET_DEST}"
	mount -o ro,loop "${__TGET_ISOS}" "${__TEMP}"
	__SRCS="$(LANG=C find "${__TEMP}"      -type d -prune -printf "%TY-%Tm-%Td%%20%TH:%TM:%TS%Tz")"
	__DEST="$(LANG=C find "${__TGET_DEST}" -type d -prune -printf "%TY-%Tm-%Td%%20%TH:%TM:%TS%Tz")"
	if [[ "${__SRCS:-}" = "${__DEST}" ]]; then
		printf "\033[m%-8s: %s\033[m\n" "skip" "${__TGET_ISOS##*/}"
	else
		printf "\033[m%-8s: %s\033[m\n" "rsync" "${__TGET_ISOS##*/}"
		nice -n "${_NICE_VALU:-19}" rsync "${_OPTN_RSYC[@]}" "${__TEMP}/." "${__TGET_DEST}/" 2>/dev/null || true
		chmod -R +r,u+w "${__TGET_DEST}/" 2>/dev/null || true
	fi
	umount "${__TEMP}"
	rm -rf "${__TEMP:?}"
}

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: trap
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
# shellcheck disable=SC2329,SC2317
function fnTrap() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __MPNT=""				# mount point
	declare -i    I=0

	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	if [[ "${#_DBGS_FAIL[@]}" -gt 0 ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "${_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]}"
		fnMsgout "${_PROG_NAME:-}" "failed" "Working files will be deleted when this shell exits."
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
			fnMsgout "${_PROG_NAME:-}" "umount" "${__PATH}"
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}"
		fi
		case "${__PATH}" in
			"${_DIRS_TEMP:?}")
				fnMsgout "${_PROG_NAME:-}" "remove" "${__PATH}"
				rm -rf "${__PATH:?}"
				;;
			*) ;;
		esac
	done
	unset __PATH __MPNT I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnInitialize() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __WORK=""				# work

	# --- set system parameter ------------------------------------------------
	if [[ -n "${TERM:-}" ]] \
	&& command -v tput > /dev/null 2>&1; then
		_ROWS_SIZE=$(tput lines || true)
		_COLS_SIZE=$(tput cols  || true)
	fi
	[[ "${_ROWS_SIZE:-"0"}" -lt 25 ]] && _ROWS_SIZE=25
	[[ "${_COLS_SIZE:-"0"}" -lt 80 ]] && _COLS_SIZE=80
	readonly _ROWS_SIZE
	readonly _COLS_SIZE

	_TEXT_SPCE="$(fnString "${_COLS_SIZE}" ' ')"
	_TEXT_GAP1="$(fnString "${_COLS_SIZE}" '-')"
	_TEXT_GAP2="$(fnString "${_COLS_SIZE}" '=')"
	readonly _TEXT_SPCE
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		fnMsgout "${_PROG_NAME:-}" "info" "busybox"
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi
	readonly _COMD_BBOX
	readonly _OPTN_COPY

	# --- target virtualization -----------------------------------------------
	_TGET_VIRT=""						# virtualization (ex. vmware)
	_TGET_CHRT=""						# is chgroot     (empty: none, else: chroot)
	_TGET_CNTR=""						# is container   (empty: none, else: container)
	if command -v systemd-detect-virt > /dev/null 2>&1; then
		_TGET_VIRT="$(systemd-detect-virt --vm || true)"
		systemd-detect-virt --quiet --chroot    && _TGET_CHRT="true"
		systemd-detect-virt --quiet --container && _TGET_CNTR="true"
	fi
	if command -v ischroot > /dev/null 2>&1; then
		ischroot --default-true && _TGET_CHRT="true"
	fi
	readonly _TGET_VIRT
	readonly _TGET_CHRT
	readonly _TGET_CNTR
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_TGET_CHRT=[${_TGET_CHRT:-}]" \
		"info,_TGET_CNTR=[${_TGET_CNTR:-}]"

	_DIRS_TGET=""
	for __DIRS in \
		/target \
		/mnt/sysimage \
		/mnt/
	do
		[[ ! -e "${__DIRS}"/root/. ]] && continue
		_DIRS_TGET="${__DIRS}"
		break
	done
	readonly _DIRS_TGET

	# --- samba ---------------------------------------------------------------
	_SHEL_NLIN="$(fnFind_command 'nologin' | sort -r | head -n 1)"
	_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /usr/sbin/nologin ]]; then echo "/usr/sbin/nologin"; fi)"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /sbin/nologin     ]]; then echo "/sbin/nologin"; fi)"}"
	readonly _SHEL_NLIN

	# --- common configuration data -------------------------------------------
	_PATH_CONF="${_PATH_CONF##*:_*_:*}"
	_PATH_CONF="${_PATH_CONF:-"/srv/user/share/conf/_data/${_FILE_CONF:?}"}"
	for __PATH in \
		"${PWD:+"${PWD}/${_FILE_CONF:?}"}" \
		"${_PATH_CONF:-}"
	do
		[[ ! -e "${__PATH}" ]] && continue
		_PATH_CONF="${__PATH}"
		break
	done
	fnList_conf_Get "${_PATH_CONF}"		# get common configuration data

	# --- media information data ----------------------------------------------
	fnList_mdia_Get "${_PATH_MDIA}"		# get media information data

	unset __PATH __DIRS __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
function fnList_conf_Get() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	IFS= mapfile -d $'\n' -t _LIST_CONF < <(awk '
		{
			delete _parm
			do {
				_line=$0
				match(_line, /^[[:alnum:]]+_[[:alnum:]]+=/)
				if (RSTART > 0) {
					_name=substr(_line, RSTART, RLENGTH)
					sub(/=.*$/, "", _name)
					_cmnt=_line
					sub(/^[^#]+/, "", _cmnt)
					_valu=_line
					_start=index(_valu, _name)
					if (_start > 0) {
						_valu=substr(_valu, _start+length(_name))
					}
					_start=index(_valu, _cmnt)
					if (_start > 0) {
						_valu=substr(_valu, 1, _start-1)
					}
					sub(/^="*/, "", _valu)
					sub(/"* *$/, "", _valu)
					_wval=_valu
					while (1) {
						match(_wval, /:_[[:alnum:]]+_[[:alnum:]]+_:/)
						if (RSTART == 0) {
						break
						}
						_ptrn=substr(_wval, RSTART, RLENGTH)
						_wnam=substr(_ptrn, 3, length(_ptrn)-4)
						sub(_ptrn, _parm[_wnam], _wval)
					}
					_parm[_name]=_wval
					_start=index(_line, _valu)
					if (_start > 0) {
						_line=sprintf("%s%s%s", substr(_line, 1, _start-1), _wval, substr(_line, _start+length(_valu)))
					}
				}
				printf "%s\n", _line
			} while ((getline) > 0)
		}
	' "$1" || true)
	while read -r __LINE
	do
		__NAME="${__LINE%%=*}"
		__VALU="${__LINE#"${__NAME}="}"
		__NAME="${__NAME:+"_${__NAME}"}"
		read -r "${__NAME:?}" < <(eval echo "${__VALU}" || true)
		_LIST_PARM+=("${__NAME}=${!__NAME}")
	done < <(printf "%s\n" "${_LIST_CONF[@]:-}" | grep -E '^[[:alnum:]]+_[[:alnum:]]+=' || true)

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: get media information data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
function fnList_mdia_Get() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	IFS= mapfile -d $'\n' -t _LIST_MDIA < <(awk -v list="${_LIST_PARM[*]}" '
		BEGIN {
			split(list, _arry, " ")
			delete _parm
			for (i in _arry) {
				_name=_arry[i]
				sub(/=.*$/, "", _name)
				_work=_name
				sub(/[[:alnum:]]+$/, "", _work)
				switch (_work) {
					case "_PATH_":
					case "_DIRS_":
					case "_FILE_":
						break
					default:
						continue
						break
				}
				_valu=_arry[i]
				sub(_name, "", _valu)
				sub(/^=/, "", _valu)
				_parm[_name]=_valu
			}
		}
		{
			_line=$0
			while (1) {
				match(_line, /:_[[:alnum:]]+_[[:alnum:]]+_:/)
				if (RSTART == 0) {
					break
				}
				_ptrn=substr(_line, RSTART, RLENGTH)
				_name="_"substr(_line, RSTART+2, RLENGTH-4)
				gsub(_ptrn, _parm[_name], _line)
			}
			printf "%s\n", _line
		}
	' "$1" || true)

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: put media information data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
function fnList_mdia_Put() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	printf "%s\n" "${_LIST_MDIA[@]}" | awk -v list="${_LIST_PARM[*]}" '
		BEGIN {
			split(list, _arry, " ")
			delete _parm
			j = length(_arry)
			for (i in _arry) {
				_name=_arry[i]
				sub(/=.*$/, "", _name)
				_work=_name
				sub(/[[:alnum:]]+$/, "", _work)
				switch (_work) {
					case "_PATH_":
					case "_DIRS_":
					case "_FILE_":
						break
					default:
						continue
						break
				}
				_valu=_arry[i]
				sub(_name, "", _valu)
				sub(/^=/, "", _valu)
				_parm[j--]=_name"="_valu
			}
		}
		{
			_line=$0
			for (j in _parm) {
				_name=_parm[j]
				sub(/=.*$/, "", _name)
				_valu=_parm[j]
				sub(_name, "", _valu)
				sub(/^=/, "", _valu)
				_work=_name
				sub(/^_/, "", _work)
				gsub(_valu, ":_"_work"_:", _line)
			}
			split(_line, _arry, "\n")
			for (i in _arry) {
				split(_arry[i], _list, " ")
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-47s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n", \
					_list[1], _list[2], _list[3], _list[4], _list[5], _list[6], _list[7], _list[8], _list[9], _list[10], \
					_list[11], _list[12], _list[13], _list[14], _list[15], _list[16], _list[17], _list[18], _list[19], _list[20], \
					_list[21], _list[22], _list[23], _list[24], _list[25], _list[26], _list[27], _list[28]
			}
		}
	' > "$1"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}


# -----------------------------------------------------------------------------
# descript: print media list
#   input :     $1     : type
#   output:   stdout   : message
#   return:            : unused
function fnMk_print_list() {
	declare -n    __REFR="${1:?}"		# name reference
	declare -r    __TYPE="${2:?}"		# target type
	declare       __TGID="${3:?}"		# target id
	declare -a    __LIST=()
	declare       __FMTT=""
	declare -a    __MDIA=()
	declare       __RETN=""
	declare -a    __ARRY=()
	declare       __MESG=""
	declare       __FILE=""
	declare       __DIRS=""
	declare       __SEED=""
	declare       __BASE=""
	declare       __EXTE=""
	declare       __WORK=""
	declare       __WRK1=""
	declare       __WRK2=""
	declare       __WRK3=""
	declare       __WRK3=""
	declare       __COLR=""
	declare       __CASH=""
	declare       __TSMP=0
	declare       __TNOW=0
	declare -i    I=0
#	declare -i    J=0

	IFS= mapfile -d $'\n' -t __LIST < <(\
		printf "%s\n" "${_LIST_MDIA[@]}" | \
		awk -v type="${__TYPE:?}" -v reng="^(${__TGID:?})$" '
			BEGIN {
				nums=1
				while ((getline) > 0) {
					if ($1==type) {
						switch ($2) {
							case "m":
								print FNR-1, 0, $0
								break
							case "o":
								if (nums ~ reng) {
									print FNR-1, nums, $0
								}
								nums++
								break
							default:
								break
						}
					}
				}
			}
		' || true
	)
	__REFR="$(printf "%s\n" "${__LIST[@]:-}")"
	if [[ "${#__LIST[@]}" -eq 0 ]]; then
		return
	fi
	__FMTT="%2s:%-$((42+6*_COLS_SIZE/120))s:%-10s:%-10s:%-$((_COLS_SIZE-$((70+6*_COLS_SIZE/120))))s"
	printf "\033[m%c%s\033[m%c\n" "#" "${_TEXT_GAP2:1:$((_COLS_SIZE-2))}" "#"
	printf "\033[m%c${__FMTT}\033[m%c\n" "#" "ID" "Target file name" "ReleaseDay" "SupportEnd" "Memo" "#"
	for I in "${!__LIST[@]}"
	do
		read -r -a __MDIA < <(echo "${__LIST[I]}")
		__MDIA=("${__MDIA[@]//%20/ }")
		case "${__MDIA[$((_OSET_MDIA+1))]}" in
			o) ;;
			*) continue;;
		esac
		# --- web file ----------------------------------------------------
		__RETN="- - - - - -"
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+8))]}" "-")"
		if [[ -n "${__WORK:-}" ]] && [[ "${__MDIA[$((_OSET_MDIA+8))]##*.}" = "iso" ]]; then
			__WORK="${__MDIA[$((_OSET_MDIA+10))]:-"0"}"
			__TSMP="$(TZ=UTC date -d "${__WORK//%20/ }" "+%s")"
			__TNOW="$(TZ=UTC date "+%s")"
			__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+9))]}" "-")"
			if [[ "${__TSMP}" -le $((__TNOW-5*60)) ]] || [[ -z "${__WORK:-}" ]]; then
				__CASH=""
				__RETN="$(fnGetWebinfo "${__MDIA[$((_OSET_MDIA+8))]}" "${_COMD_WGET:-}")"
			else
				__CASH="true"
				__RETN="$(fnGetWebinfo "${__MDIA[$((_OSET_MDIA+9))]}" "${_COMD_WGET:-}")"
			fi
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[_OSET_MDIA+9]="${__ARRY[0]:-"-"}"	# web_path
		__MDIA[_OSET_MDIA+10]="${__ARRY[1]:-"-"}"	# web_tstamp
		__MDIA[_OSET_MDIA+11]="${__ARRY[2]:-"-"}"	# web_size
		__MDIA[_OSET_MDIA+12]="${__ARRY[3]:-"-"}"	# web_check
		__MDIA[_OSET_MDIA+13]="${__ARRY[4]:-"-"}"	# web_status
		__MESG="$(fnTrim "${__ARRY[5]:-"-"}" "-")"	# message
		__MESG="${__MESG//%20/ }"
		case "${__MDIA[$((_OSET_MDIA+13))]}" in
			2[0-9][0-9])
				__MESG=""
				__FILE="$(fnBasename "${__MDIA[$((_OSET_MDIA+9))]}")"
				if [[ -n "${__FILE:-}" ]]; then
					case "${__FILE}" in
						mini.iso) ;;
						*.iso   )
							__DIRS="$(fnDirname "${__MDIA[$((_OSET_MDIA+14))]}")"
							__MDIA[_OSET_MDIA+14]="${__DIRS:-}/${__FILE}"	# iso_path
							;;
						*       ) ;;
					esac
				fi
				;;
			*) ;;
		esac
		# --- iso file ----------------------------------------------------
		__RETN="- - - -"
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")"
		if [[ -n "${__WORK:-}" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+14))]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[_OSET_MDIA+15]="${__ARRY[1]:-"-"}"	# iso_tstamp
		__MDIA[_OSET_MDIA+16]="${__ARRY[2]:-"-"}"	# iso_size
		__MDIA[_OSET_MDIA+17]="${__ARRY[3]:-"-"}"	# iso_volume
		# --- conf file ---------------------------------------------------
		__RETN="- - - -"
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+24))]}" "-")"
		if [[ -n "${__WORK:-}" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+24))]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[_OSET_MDIA+25]="${__ARRY[1]:-"-"}"	# rmk_tstamp
		# --- rmk file ----------------------------------------------------
		__WRK1="$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")"
		__WRK2="$(fnTrim "${__MDIA[$((_OSET_MDIA+18))]}" "-")"
		__WRK3="$(fnTrim "${__MDIA[$((_OSET_MDIA+24))]}" "-")"
		if [[ -n "${__WRK1:-}" ]] \
		&& [[ -n "${__WRK2:-}" ]] \
		&& [[ -n "${__WRK3:-}" ]]; then
			__SEED="${__MDIA[$((_OSET_MDIA+24))]%/*}"
			__SEED="${__SEED##*/}"
			__FILE="${__MDIA[$((_OSET_MDIA+24))]#*"${__SEED:+"${__SEED}/"}"}"
			__WORK="$(fnTrim "${__FILE}" "-")"
			if [[ -n "${__WORK:-}" ]]; then
				__DIRS="$(fnDirname "${__MDIA[$((_OSET_MDIA+18))]}")"
				__BASE="$(fnBasename "${__MDIA[$((_OSET_MDIA+14))]}")"
				__FILE="${__BASE%.*}"
				__EXTE="${__BASE#"${__FILE:+"${__FILE}."}"}"
				__MDIA[_OSET_MDIA+18]="${__DIRS:-}/${__FILE}${__SEED:+"_${__SEED}"}${__EXTE:+".${__EXTE}"}"
			fi
		fi
		__RETN="- - - -"
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+18))]}" "-")"
		if [[ -n "${__WORK:-}" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+18))]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[_OSET_MDIA+19]="${__ARRY[1]:-"-"}"	# rmk_tstamp
		__MDIA[_OSET_MDIA+20]="${__ARRY[2]:-"-"}"	# rmk_size
		__MDIA[_OSET_MDIA+21]="${__ARRY[3]:-"-"}"	# rmk_volume
		# --- decision on next process ------------------------------------
		# download: light blue
		# create  : green
		# error   : red
		__MDIA[_OSET_MDIA+27]="-"				# create_flag
		__WRK1="$(fnTrim "${__MDIA[$((_OSET_MDIA+9))]}"  "-")"
		__WRK2="$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")"
		if [[ -n "${__WRK1:-}" ]] \
		&& [[ -n "${__WRK2:-}" ]]; then
			case "${__MDIA[$((_OSET_MDIA+13))]}" in
				2[0-9][0-9])
					__WRK1="$(fnTrim "${__MDIA[$((_OSET_MDIA+24))]}" "-")"
					__WRK2="$(fnTrim "${__MDIA[$((_OSET_MDIA+18))]}" "-")"
					if [[ ! -e "${__MDIA[$((_OSET_MDIA+14))]}" ]]; then
						__MDIA[_OSET_MDIA+27]="d"	# create_flag (download: original file not found)
					elif [[ "${__MDIA[$((_OSET_MDIA+10))]:-}" != "${__MDIA[$((_OSET_MDIA+15))]:-}" ]] \
					||   [[ "${__MDIA[$((_OSET_MDIA+11))]:-}" != "${__MDIA[$((_OSET_MDIA+16))]:-}" ]]; then
						__MDIA[_OSET_MDIA+27]="d"	# create_flag (download: timestamp or size differs)
					elif [[ -n "${__WRK1:-}" ]] \
					&&   [[ -n "${__WRK2:-}" ]]; then
						__WRK1="${__MDIA[$((_OSET_MDIA+19))]:+"$(TZ=UTC date -d "${__MDIA[$((_OSET_MDIA+19))]//%20/ }" "+%s")"}"
						__WRK2="${__MDIA[$((_OSET_MDIA+15))]:+"$(TZ=UTC date -d "${__MDIA[$((_OSET_MDIA+15))]//%20/ }" "+%s")"}"
						__WRK3="${__MDIA[$((_OSET_MDIA+25))]:+"$(TZ=UTC date -d "${__MDIA[$((_OSET_MDIA+25))]//%20/ }" "+%s")"}"
						if   [[ ! -e "${__MDIA[$((_OSET_MDIA+18))]}" ]]; then
							__MDIA[_OSET_MDIA+27]="c"	# create_flag (create: remake file not found)
						elif [[ "${__WRK2:-"0"}" -gt "${__WRK1:-"0"}" ]] \
						||   [[ "${__WRK3:-"0"}" -gt "${__WRK1:-"0"}" ]]; then
							__MDIA[_OSET_MDIA+27]="c"	# create_flag (create: remake file is out of date)
						else
							__WORK="$(find -L "${_DIRS_SHEL:?}" -newer "${__MDIA[$((_OSET_MDIA+18))]}" -name 'auto*sh')"
							if [[ -n "${__WORK:-}" ]]; then
								__MDIA[_OSET_MDIA+27]="c"	# create_flag (create: remake file is out of date)
							fi
						fi
					fi
					;;
				*) __MDIA[_OSET_MDIA+27]="e";;	# create_flag (error: communication failure)
			esac
		fi
		case "${__MDIA[$((_OSET_MDIA+27))]:-}" in
			d) __COLR="96"; [[ -n "${__CASH:-}" ]] && __COLR="46";;	# download [light blue]
			c) __COLR="92"; [[ -n "${__CASH:-}" ]] && __COLR="42";;	# create   [green]
			e) __COLR="91"; [[ -n "${__CASH:-}" ]] && __COLR="41";;	# error    [red]
			*) __COLR="";;
		esac
		__BASE="$(fnBasename "${__MDIA[$((_OSET_MDIA+14))]}")"
		__SEED="$(fnBasename "${__MDIA[$((_OSET_MDIA+24))]}")"
		__RDAT="$(fnTrim "${__MDIA[$((_OSET_MDIA+6))]%%%20*}" "-")"
		__SUPE="$(fnTrim "${__MDIA[$((_OSET_MDIA+7))]%%%20*}" "-")"
		__MESG="$(fnTrim "${__MESG:-"${__SEED}"}" "-")"
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+15))]}" "-")"
		[[ -n "${__WORK:-}" ]] && __RDAT="$(fnTrim "${__MDIA[$((_OSET_MDIA+15))]%%%20*}" "-")"	# iso_tstamp
		__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+13))]}" "-")"
		[[ -n "${__WORK:-}" ]] && __RDAT="$(fnTrim "${__MDIA[$((_OSET_MDIA+10))]%%%20*}" "-")"	# web_tstamp
		printf "\033[m%c\033[%sm${__FMTT}\033[m%c\n" "#" "${__COLR:-}" "${__MDIA[1]}" "${__BASE}" "${__RDAT:-"20xx-xx-xx"}" "${__SUPE:-"20xx-xx-xx"}" "${__MESG:-}" "#"
		# --- data registration -------------------------------------------
		__MDIA=("${__MDIA[@]// /%20}")
		__LIST[I]="${__MDIA[*]}"
#		J="${__MDIA[0]}"
#		_LIST_MDIA[J]="$(
#			printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
#			"${__MDIA[@]:"${_OSET_MDIA}"}"
#		)"
	done
	printf "\033[m%c%s\033[m%c\n" "#" "${_TEXT_GAP2:1:$((_COLS_SIZE-2))}" "#"
	__REFR="$(printf "%s\n" "${__LIST[@]:-}")"

	unset __LIST __FMTT __MDIA __RETN __ARRY __MESG __FILE __DIRS __SEED __BASE __EXTE __WORK __COLR I J
}










# -----------------------------------------------------------------------------
# descript: make squashfs file
#   input :     $@     : parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_squashfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_SQFS="${2:?}"	# output file name
	declare -r -a __OPTN=(
		"${@:-}"
		-quiet
		-progress
		-noappend
		-no-xattrs
		-ef /.autorelabel /.cache /.viminfo
	)

	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	echo "create squashfs file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	if ! nice -n 19 mksquashfs "${__OPTN[@]}"; then
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [mksquashfs]" "${__FILE_ISOS##*/}" 1>&2
		printf "%s\n" "mksquashfs ${__OPTN[*]}"
	fi
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: make iso files
#   input :     $1     : target directory
#   input :     $2     : output file name
#   input :     $3     : volume id
#   input :     $4     : grub mbr file name
#   input :     $5     : uefi file name
#   input :     $6     : eltorito catalog file name
#   input :     $7     : eltorito boot file name
#   output:   stdout   : message
#   return:            : unused
function fnMk_xorrisofs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_ISOS="${2:?}"	# output file name
	declare -r    __FILE_VLID="${3:-}"	# volume id
	declare -r    __FILE_HBRD="${4:-}"	# iso hybrid mbr file name
	declare -r    __FILE_BIOS="${5:-}"	# grub mbr file name
	declare -r    __FILE_UEFI="${6:-}"	# uefi file name
	declare -r    __FILE_BCAT="${7:-}"	# eltorito catalog file name
	declare -r    __FILE_ETRI="${8:-}"	# eltorito boot file name
	if [[ -n "${__FILE_HBRD:-}" ]]; then
		declare -r -a __OPTN=(\
			-quiet -rational-rock \
			${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"} \
			-joliet -joliet-long \
			-cache-inodes \
			-isohybrid-mbr "${__FILE_HBRD}" \
			${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}"} \
			${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"} \
			-no-emul-boot -boot-load-size 4 -boot-info-table \
			-eltorito-alt-boot -e "${__FILE_UEFI}" -no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
		)
	else
		declare -r -a __OPTN=(\
			-quiet -rational-rock \
			${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"} \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			--grub2-mbr "${__FILE_BIOS}" \
			--mbr-force-bootable \
			-append_partition 2 0xEF "${__FILE_UEFI}" \
			-appended_part_as_gpt \
			${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"} \
			${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}"} \
			-no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' -no-emul-boot
		)
	fi
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	echo "create iso image file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	[[ -n "${__FILE_HBRD:-}" ]] && echo "hybrid mode"
	[[ -n "${__FILE_BIOS:-}" ]] && echo "eltorito mode"
	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! nice -n 19 xorrisofs "${__OPTN[@]}" -output "${__TEMP}" .; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${__FILE_ISOS##*/}" 1>&2
			printf "%s\n" "xorrisofs ${__OPTN[*]} -output ${__TEMP} ."
		else
			if ! cp --preserve=timestamps "${__TEMP}" "${__FILE_ISOS}"; then
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${__FILE_ISOS##*/}" 1>&2
			else
				__REAL="$(realpath "${__FILE_ISOS}")"
				__DIRS="$(fnDirname "${__FILE_ISOS}")"
				__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
				chown "${__OWNR:-"${_SAMB_USER}"}" "${__FILE_ISOS}"
				chmod ugo+r-x,ug+w "${__FILE_ISOS}"
				ls -lh "${__FILE_ISOS}"
				printf "\033[m\033[42m%20.20s: %s\033[m\n" "complete" "${__FILE_ISOS}" 1>&2
			fi
		fi
		rm -f "${__TEMP:?}"
	popd > /dev/null || exit
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __REAL __DIRS __OWNR __time_start __time_end __time_elapsed

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: make iso files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare -A    __PTRN=()				# pattern
	declare       __TYPE=""				# target type
	declare       __TGID=""				# target id
	declare       __FRCE=""				# force flag (empty: update, else: force create)
	declare       __NAME=""
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
	declare       __PATH=""
	declare       __WORK=""
	declare -a    __ARRY=()				# data array
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -qd "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare -r    __DOVL="${__TEMP}/overlay"				# overlay
	declare -r    __DUPR="${__DOVL}/upper"					# upperdir
	declare -r    __DLOW="${__DOVL}/lower"					# lowerdir
	declare -r    __DWKD="${__DOVL}/work"					# workdir
	declare -r    __DMRG="${__DOVL}/merged"					# merged
	declare -a    __BOPT=()
	declare       __FNAM=""
	declare       __TSMP=""
	declare       __DIRD=""				# initrd directory
	declare       __FIRD=""				# initrd file path
	declare       __FKNL=""				# kernel file path
	declare       __NICS=""
	declare       __HOST=""
	declare       __CIDR=""
	declare       __LABL=""
	declare       __FMBR=""
	declare       __FEFI=""
	declare       __SKIP=""
	declare       __SIZE=""
	declare       __FCAT=""
	declare       __FBIN=""
	declare       __HBRD=""
	declare -i    __TABS=0				# tab count
	declare       __INFO=""
	declare -i    I=0
	declare -i    J=0
	# --- get target ----------------------------------------------------------
	__PTRN=()
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__TYPE="${1%%:*}"
		__TGID="${1#"${__TYPE:+"${__TYPE}":}"}"
		__TYPE="${__TYPE,,}"
		__TGID="${__TGID,,}"
		case "${__TYPE:-}" in
			f|force  ) __FRCE="true"; shift; continue;;
			a|all    ) __PTRN=(["mini"]=".*" ["netinst"]=".*" ["dvd"]=".*" ["liveinst"]=".*"); shift; break;;
			mini     ) ;;
			netinst  ) ;;
			dvd      ) ;;
			liveinst ) ;;
			live     ) shift; continue;;
			tool     ) shift; continue;;
			clive    ) shift; continue;;
			cnetinst ) shift; continue;;
			system   ) shift; continue;;
			*) break;;
		esac
		case "${__TGID:-}" in
			''              ) __PTRN["${__TYPE}"]="";;
			a|all           ) __PTRN["${__TYPE}"]=".*";;
			[0-9]|[0-9][0-9]) __PTRN["${__TYPE}"]="${__PTRN["${__TYPE}"]:+"${__PTRN["${__TYPE}"]} "}${__TGID}";;
			*               ) ;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	# --- create custom iso file ----------------------------------------------
	for __TYPE in "${_LIST_TYPE[@]}"
	do
		case "${__TYPE:-}" in
			mini     ) ;;
			netinst  ) ;;
			dvd      ) ;;
			liveinst ) ;;
#			live     ) ;;
#			tool     ) ;;
#			clive    ) ;;
#			cnetinst ) ;;
#			system   ) ;;
			*        ) continue;;
		esac
		if [[ -z "${__PTRN["${__TYPE:-}"]:-}" ]]; then
			if ! echo "${!__PTRN[@]}" | grep -q "${__TYPE}"; then
				continue
			fi
			fnMk_print_list __LINE "${__TYPE:-}" ".*"
			IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
			read -r -p "enter the number to create:" __RANG
			read -r -a __ARRY < <(echo "${__RANG}")
			__PTRN["${__TYPE}"]=""
			for I in "${!__ARRY[@]}"
			do
				__TGID="${__ARRY[I]:-}"
				case "${__TGID:-}" in
					e|exit          ) break 2;;
					a|all           ) __PTRN["${__TYPE}"]="$(seq --separator=' ' 1 "${#__TGET[@]}")"; break;;
					[0-9]|[0-9][0-9]) __PTRN["${__TYPE}"]="${__PTRN["${__TYPE}"]:+"${__PTRN["${__TYPE}"]} "}${__TGID}";;
					*               ) ;;
				esac
			done < <(echo "${__RANG:-}" || true)
			[[ -z "${__PTRN["${__TYPE:-}"]:-}" ]] && continue
			__TGID="${__PTRN["${__TYPE:-}"]// /|}"
			__ARRY=()
			for I in "${!__TGET[@]}"
			do
				read -r -a __MDIA < <(echo "${__TGET[I]}")
				if echo "${__MDIA[1]}" | grep -qE "${__TGID:-}"; then
					__ARRY+=("${__TGET[I]}")
				fi
			done
			__TGET=("${__ARRY[@]:-}")
		else
#			[[ -z "${__PTRN["${__TYPE:-}"]:-}" ]] && continue
			__TGID="${__PTRN["${__TYPE:-}"]// /|}"
			fnMk_print_list __LINE "${__TYPE:-}" "${__TGID:-}"
			IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		fi
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			__MDIA=("${__MDIA[@]//%20/ }")
			case "${__MDIA[$((_OSET_MDIA+1))]}" in
				m) continue;;			# (menu)
				o)						# (output)
					case "${__MDIA[$((_OSET_MDIA+2))]}" in
						windows-*              ) continue;;
						winpe-*|ati*x64|ati*x86) continue;;
						aomei-backupper        ) continue;;
						memtest86*             ) continue;;
						*                      )
							case "${__MDIA[$((_OSET_MDIA+27))]}" in
								c) ;;
								d)
									__RETN="- - - -"
									__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")"
									if [[ -n "${__WORK:-}" ]]; then
										fnDownload "${__MDIA[$((_OSET_MDIA+9))]}" "${__MDIA[$((_OSET_MDIA+14))]}" "${__MDIA[$((_OSET_MDIA+11))]}"
										__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+14))]}")"
									fi
									read -r -a __ARRY < <(echo "${__RETN}")
									__MDIA[_OSET_MDIA+15]="${__ARRY[1]:-}"	# iso_tstamp
									__MDIA[_OSET_MDIA+16]="${__ARRY[2]:-}"	# iso_size
									__MDIA[_OSET_MDIA+17]="${__ARRY[3]:-}"	# iso_volume
									;;
								*) [[ -z "${__FRCE:-}" ]] && continue;;
							esac
							__INFO="$(printf "%s %s : %s" "${__MDIA[$((_OSET_MDIA+0))]}" "${__MDIA[1]}" "${__MDIA[$((_OSET_MDIA+14))]##*/}")"
							printf "\033[m\033[44m%-8s: %s\033[m\n" "start" "${__INFO}"
							# --- rsync ---------------------------------------
							fnRsync "${__MDIA[$((_OSET_MDIA+14))]}" "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}"
							# --- mount ---------------------------------------
							rm -rf "${__DOVL:?}"
							mkdir -p "${__DUPR}" "${__DLOW}" "${__DWKD}" "${__DMRG}"
#							mount -r "${__MDIA[$((_OSET_MDIA+14))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount -r --bind "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount -t overlay overlay -o lowerdir="${__DLOW}",upperdir="${__DUPR}",workdir="${__DWKD}" "${__DMRG}" && _LIST_RMOV+=("${__DMRG:?}")
							# --- create filesystem.packages-remove -----------
							case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
								debian-live-*)
									__PATH="${__DMRG}/live/filesystem.packages-remove"
									if [[ ! -e "${__PATH:?}" ]]; then
										printf "\033[m\033[33m%-8s: %s\033[m\n" "caution" "${__PATH#"${__DMRG}"/}"
										touch "${__PATH:?}"
									fi
									;;
								*            ) ;;
							esac
							# --- create auto install configuration file ------
							__WORK="$(fnMk_boot_options "remake" "${__MDIA[@]:-}")"
							IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
							__FNAM="${__MDIA[$((_OSET_MDIA+14))]##*/}"				# iso_path
							__TSMP="${__MDIA[$((_OSET_MDIA+15))]:-}"				# iso_tstamp
							__TSMP="${__TSMP:+" (${__TSMP:0:19})"}"
							__ENTR="${__MDIA[$((_OSET_MDIA+2))]:-}"					# entry_name
							__FIRD="${__MDIA[$((_OSET_MDIA+22))]#*/"${__ENTR:-}"}"	# ldr_initrd
							__FKNL="${__MDIA[$((_OSET_MDIA+23))]#*/"${__ENTR:-}"}"	# ldr_kernel
							case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
								*-mini-*) __FIRD="${__FIRD%/*}/${_MINI_IRAM:?}";;	# initial ram disk of mini.iso including preseed
								*       ) ;;
							esac
							__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
							__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
							case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
								opensuse-*-15.*) __NICS="eth0";;
								*              ) __NICS="${_NICS_NAME:-"ens160"}";;
							esac
							case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
								ubuntu*) __CIDR="";;
								*      ) __CIDR="/${_IPV4_CIDR:-}";;
							esac
							fnMk_isofile_conf "${__DMRG}" "${__MDIA[$((_OSET_MDIA+24))]}"	# cfg_path
							# --- rebuilding initrd ---------------------------
							case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
								*-mini-*)
									__DIRS="${__TEMP:?}/${__FIRD##*/}"			# extract directory
									fnXinitrd "${__DMRG}${__FIRD}" "${__DIRS}"	# extract the initrd
									__DIRD="${__DIRS}"							# initramfs directory
									[[ -d "${__DIRD}/main/." ]] && __DIRD+="/main"
									# --- copying files for automatic installation
									cp --preserve=timestamps -R "${__DMRG}/${_DIRS_CONF#"${_DIRS_SHAR}"}" "${__DIRD:?}"
									chmod ugo+r-xw "${__DIRD:?}${_DIRS_CONF#"${_DIRS_SHAR}"}/${_DIRS_SHEL#"${_DIRS_CONF:-}"/}"/*
									# --- rebuilding initrd -------------------
									__FIRD="${__FIRD%/*}/${_MINI_IRAM}"
									pushd "${__DIRD}" > /dev/null || exit
										find . | cpio --format=newc --create --quiet | gzip > "${__DMRG}${__FIRD:?}" || true
									popd > /dev/null || exit
									rm -rf "${__DIRS:?}"
									;;
								*       ) ;;
							esac
							fnMk_isofile_grub "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__NICS:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							fnMk_isofile_ilnx "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__NICS:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							# --- rebuild -------------------------------------
							__LABL="$(blkid -o value -s PTTYPE "${__MDIA[$((_OSET_MDIA+14))]}")"
							__HBRD=""
							__FMBR=""
							__FEFI="$(find "${__DMRG}" -type f \( \( -ipath '*/boot/*/*' -o -ipath '*/images/*' \) -a \( -iname 'efi*.img' -o -ipath '*/boot/*/efi' \) \))"
							case "${__LABL:-}" in
#								dos) __HBRD="/usr/lib/ISOLINUX/isohdpfx.bin";;
								dos) __HBRD="${__TEMP}/mbr.img"; __FEFI="${__FEFI#"${__DMRG}/"}";;
								gpt) __FMBR="${__TEMP}/mbr.img";;
								*  ) exit 1;;
							esac
							# --- get mbr image file --------------------------
							dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=1 count=446 of="${__FMBR:-"${__HBRD:-}"}" > /dev/null 2>&1
							# --- get uefi image file -------------------------
							if [[ -z "${__FEFI:-}" ]]; then
								__WORK="$(fdisk -l "${__MDIA[$((_OSET_MDIA+14))]}" 2>&1 | awk '$6~/EFI|ef/ {print $2, $4;}')"
								read -r  __SKIP __SIZE < <(echo "${__WORK:-}")
								__FEFI="${__TEMP}/efi.img"
								dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${__FEFI}" > /dev/null 2>&1
							fi
							# -------------------------------------------------
							__FCAT="$(find "${__DMRG}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \))"
							__FBIN="$(find "${__DMRG}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \))"
							fnMk_xorrisofs "${__DMRG}" "${__MDIA[$((_OSET_MDIA+18))]}" "${__MDIA[$((_OSET_MDIA+17))]}" "${__HBRD:-}" "${__FMBR:-}" "${__FEFI:-}" "${__FCAT#"${__DMRG}/"}" "${__FBIN#"${__DMRG}/"}"
							__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+18))]}")"
							read -r -a __ARRY < <(echo "${__RETN}")
							__MDIA[_OSET_MDIA+19]="${__ARRY[1]:-}"	# rmk_tstamp
							__MDIA[_OSET_MDIA+20]="${__ARRY[2]:-}"	# rmk_size
							__MDIA[_OSET_MDIA+21]="${__ARRY[3]:-}"	# rmk_volume
							# --- umount --------------------------------------
							umount "${__DMRG}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							umount "${__DLOW}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							rm -rf "${__TEMP:?}"
							printf "\033[m\033[44m%-8s: %s\033[m\n" "complete" "${__INFO}"
							;;
					esac
					;;
				*) continue;;			# (hidden)
			esac
			# --- data registration -------------------------------------------
			__MDIA=("${__MDIA[@]// /%20}")
			J="${__MDIA[0]}"
			_LIST_MDIA[J]="$(
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-47s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__MDIA[@]:"${_OSET_MDIA}"}"
			)"
		done
	done
	fnList_mdia_Put "work.txt"
	unset __OPTN __PTRN __TYPE __LINE __TGET __MDIA __RETN __PATH __ARRY __INFO __TABS I J

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: help
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' 1>&2 || true
		usage: [sudo] ${_PROG_PATH:-"$0"} (options) [command]
		  commands:
		    -h|--help   : this message output
		    -m|--make   : making iso files
		    -P|--DBGP   : debug output for internal global variables
		    -T|--TREE   : debug output in a directory tree-like format
		  options:
		    -D|--debug   |--dbg     : debug output with code
		    -O|--debugout|--dbgout  : debug output without code
_EOT_
	exit 0
}

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnMain() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PROC=""
	declare -a    __OPTN=()
	declare       __RSLT=""

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize

	# --- main processing -----------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			-h|--help) fnHelp;;
			-m|--make) fnMk_mkosi_build "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-P|--DBGP) fnDbgparameters_all; break;;
			-T|--TREE) tree --charset C -x -a --filesfirst "${_DIRS_TOPS:-}"; break;;
			*        ) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done
	unset __PROC __OPTN __RSLT

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

	# --- help / debug --------------------------------------------------------
	[[ -z "${_PROG_PARM[*]:-}" ]] && fnHelp
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			-h|--help             ) fnHelp;;
			-D|--debug   |--dbg   ) _DBGS_FLAG="true"; set -x;;
			-O|--debugout|--dbgout) _DBGS_FLAG="true";;
			*                     ) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [[ -n "${_DBGS_FLAG:-}" ]]; then
		fnDbgout "command line" \
			"debug,_COMD_LINE=[${_COMD_LINE:-}]"
	fi

	# --- start ---------------------------------------------------------------
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- main processing -----------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	exit 0

# ### eof #####################################################################
