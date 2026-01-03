#!/bin/bash

###############################################################################
#
#	custom iso image creation and pxeboot configuration shell
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
	              _DIRS_TEMP="$(mktemp -qd "${_DIRS_TEMP}/${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- command line parameter ----------------------------------------------
	declare       _COMD_LINE=""	  	# command line parameter
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
	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--update" "--delete")

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
				*/*/*) printf "\033[m${1:-}: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		caution            ) printf "\033[m${1:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}:     \033[36m%-8.8s: %s\033[m\n"        "${1#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
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
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
function fnTargetsys() {
	declare       ___VIRT=""
	declare       ___CNTR=""
	if command -v systemctl > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt || true)"
		___CNTR="$(systemctl is-system-running || true)"
	fi
	printf "%s,%s" "${___VIRT:-}" "${___CNTR:-}"
	unset ___VIRT
	unset ___CNTR
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

	case "${__TGET_ISOS}" in
		*.iso) ;;
		*    ) return;;
	esac
	if [[ ! -s "${__TGET_ISOS}" ]]; then
		return
	fi
	printf "\033[m%-8s: %s\033[m\n" "rsync" "${__TGET_ISOS##*/}"
	rm -rf "${__TEMP:?}"
	mkdir -p "${__TEMP}" "${__TGET_DEST}"
	mount -o ro,loop "${__TGET_ISOS}" "${__TEMP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_OPTN_RSYC[@]}" "${__TEMP}/." "${__TGET_DEST}/" 2>/dev/null || true
	umount "${__TEMP}"
	chmod -R +r,u+w "${__TGET_DEST}/" 2>/dev/null || true
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
	__WORK="$(fnTargetsys)"
	case "${__WORK##*,}" in
		offline) _TGET_CNTR="true";;
		*      ) _TGET_CNTR="";;
	esac
	readonly _TGET_CNTR
	readonly _TGET_VIRT="${__WORK%,*}"

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
# descript: make directory
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_symlink_dir() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create directory ----------------------------------------------------
	mkdir -p \
		"${_DIRS_TOPS:?}" \
		"${_DIRS_HGFS:?}" \
		"${_DIRS_HTML:?}" \
		"${_DIRS_SAMB:?}"/adm/{commands,profiles} \
		"${_DIRS_SAMB:?}"/pub/{_license,contents/{disc,dlna/{movies,others,photos,sounds}},hardware,software} \
		"${_DIRS_SAMB:?}"/pub/resource/git \
		"${_DIRS_SAMB:?}"/usr \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,locale,i386-pc,i386-efi,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg} \
		"${_DIRS_USER:?}"/private \
		"${_DIRS_SHAR:?}" \
		"${_DIRS_CONF:?}"/{_data,_keyring,_repository/opensuse,_template} \
		"${_DIRS_CONF:?}"/_mkosi/mkosi.{build.d,clean.d,conf.d,extra,finalize.d,postinst.d,postoutput.d,prepare.d,repart,sync.d} \
		"${_DIRS_CONF:?}"/{agama,autoyast,kickstart,nocloud/{ubuntu_desktop,ubuntu_server},preseed,script,windows} \
		"${_DIRS_IMGS:?}" \
		"${_DIRS_ISOS:?}"/{linux,windows} \
		"${_DIRS_ISOS:?}"/linux/{debian,ubuntu,fedora,centos,almalinux,rockylinux,miraclelinux,opensuse,memtest86plus} \
		"${_DIRS_ISOS:?}"/windows/{windows-{10,11},winpe,ati,aomei} \
		"${_DIRS_LOAD:?}" \
		"${_DIRS_RMAK:?}" \
		"${_DIRS_CACH:?}" \
		"${_DIRS_CTNR:?}" \
		"${_DIRS_CHRT:?}"
	# --- change file mode ----------------------------------------------------
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB}/"
	chmod -R 2770 "${_DIRS_SAMB}/"
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_CONF}/"
	chmod -R 2775 "${_DIRS_CONF}/"
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_ISOS}/"
	chmod -R 2775 "${_DIRS_ISOS}/"
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_RMAK}/"
	chmod -R 2775 "${_DIRS_RMAK}/"
	# --- create symbolic link ------------------------------------------------
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ]] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ]] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ]] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ]] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ]] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_TFTP##*/}"               ]] && ln -s "${_DIRS_TFTP#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_CONF##*/}"               ]] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}"               ]] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}"               ]] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}"               ]] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_RMAK##*/}"               ]] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ]] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ]] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ]] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ]] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ]] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ]] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_CONF##*/}"    ]] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_IMGS##*/}"    ]] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_ISOS##*/}"    ]] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_LOAD##*/}"    ]] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_RMAK##*/}"    ]] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" ]] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"
	# --- create index.html ---------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_HTML}/index.html"
		"Hello, world!" from ${_NICS_HOST}
_EOT_
	# --- create autoexec.ipxe ------------------------------------------------
	touch "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"
	touch "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg"
	# --- create autoexec.ipxe ------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_DIRS_TFTP:?}/autoexec.ipxe"
		#!ipxe

		cpuid --ext 29 && set arch amd64 || set arch x86

		dhcp

		set optn-timeout 1000
		set menu-timeout 0
		isset \${menu-default} || set menu-default exit

		:start

		:menu
		menu Select the OS type you want to boot
		item --gap --                                   --------------------------------------------------------------------------
		item --gap --                                   [ System command ]
		item -- shell                                   - iPXE shell
		#item -- shutdown                               - System shutdown
		item -- restart                                 - System reboot
		item --gap --                                   --------------------------------------------------------------------------
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

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: make symlink
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_symlink() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __FORC=""				# force parameter
	declare       __PTRN=""				# pattern
	declare       __LINE=""				# work
	declare -a    __LIST=()				# work
	declare -i    I=0

	# --- get target ----------------------------------------------------------
	__PTRN=""
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			create   ) __FORC="true"; shift; break;;
			update   ) __FORC=""    ; shift; break;;
			*) break;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"

	# --- create directory ----------------------------------------------------
	[[ -n "${__FORC:-}" ]] && fnMk_symlink_dir

	# --- create symbolic link [iso files] ------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]:-}"
		read -r -a __LIST < <(echo "${__LINE:-}")
		case "${__LIST[1]##-}" in		# entry_flag
			'') continue;;
			o ) ;;
			* ) continue;;
		esac
		case "${__LIST[14]##-}" in		# iso_path
			'') continue;;
			- ) continue;;
			* ) ;;
		esac
		case "${__LIST[26]##-}" in		# lnk_path
			'') continue;;
			- ) continue;;
			* ) ;;
		esac
		[[ -h "${__LIST[14]}" ]] && continue
		fnMsgout "${_PROG_NAME:-}" "create" "${__LIST[13]}"
		mkdir -p "${__LIST[14]%/*}"
		ln -s "${__LIST[26]}/${__LIST[14]##*/}" "${__LIST[14]}"
	done
	unset __OPTN __FORC __PTRN __LINE __LIST I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: make preseed.cfg
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_preseed() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_SEDD}" "${__TGET_PATH}"
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                             \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g'                                                   \
			    -e 's/connman/network-manager/                              } '
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}"
	unset __REAL __DIRS __OWNR
#	unset __TGET_PATH
}

# -----------------------------------------------------------------------------
# descript: make nocloud
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_CLUD}" "${__TGET_PATH}"
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${__TGET_PATH%/*}/meta-data"      --reference "${__TGET_PATH}"
	touch -m "${__TGET_PATH%/*}/network-config" --reference "${__TGET_PATH}"
#	touch -m "${__TGET_PATH%/*}/user-data"      --reference "${__TGET_PATH}"
	touch -m "${__TGET_PATH%/*}/vendor-data"    --reference "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH%/*}"/*
	unset __REAL __DIRS __OWNR
#	unset __TGET_PATH
}

# -----------------------------------------------------------------------------
# descript: make kickstart.cfg
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_kickstart() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __NAME=""				# "            name
	declare       __SECT=""				# "            section
	declare       __ADDR=""				# repository
	declare -r    __ARCH="x86_64"		# base architecture
	declare       __WORK=""				# work
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_KICK}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__WORK="${__TGET_PATH##*/}"			# file name
	__VERS="${__WORK#*_}"				# ks_(name)-(nums)_ ...: (ex: ks_fedora-42_dvd_desktop.cfg)
	__VERS="${__VERS%%_*}"				# vers="(name)-(nums)"
	__NUMS="${__VERS##*-}"
	__NAME="${__VERS%-*}"
	__SECT="${__NAME/-/ }"
	__ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"
	# --- initializing the settings -------------------------------------------
	sed -i "${__TGET_PATH}"                     \
	    -e "/^cdrom$/      s/^/#/             " \
	    -e "/^url[ \t]\+/  s/^/#/g            " \
	    -e "/^repo[ \t]\+/ s/^/#/g            " \
	    -e "s/:_HOST_NAME_:/${__NAME}/        " \
	    -e "s%:_WEBS_ADDR_:%${__ADDR}%g       " \
	    -e "s%:_DISTRO_:%${__NAME}-${__NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#cdrom$/ s/^#//             " \
			    -e "/^#.*(${__SECT}).*$/,/^$/   { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^cdrom$/ s/^/#/              " \
			    -e "/^#.*(${__SECT}).*$/,/^$/   { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g    } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^cdrom$/ s/^/#/              " \
			    -e "/^#.*(web address).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_fedora*)
			sed -i "${__TGET_PATH}"                 \
			    -e "/%packages/,/%end/          { " \
			    -e "/^epel-release/ s/^/#/      } "
			;;
		*)
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#.*(EPEL).*$/,/^$/        { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
	esac
	# --- desktop -------------------------------------------------------------
	cp --backup "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	sed -i "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}" \
	    -e "/%packages/,/%end/                         {" \
	    -e "/#@.*-desktop/,/^[^#]/ s/^#//g             }"
	case "${__NUMS}" in
		[1-9]) ;;
		*    )
			sed -i "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}" \
			    -e "/%packages/,/%end/                         {" \
			    -e "/^kpipewire$/ s/^/#/g                      }"
			;;
	esac
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	unset __VERS __NUMS __NAME __SECT __ADDR __WORK __REAL __DIRS __OWNR
}

# -----------------------------------------------------------------------------
# descript: make autoyast.xml
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_autoyast() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __WORK=""				# work
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_YAST}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__WORK="${__TGET_PATH##*/}"			# file name
	__VERS="${__WORK#*_}"				# autoinst_(name)-(nums)_ ...: (ex: autoinst_tumbleweed_net_desktop.xml)
	__VERS="${__VERS%%_*}"				# vers="(name)-(nums)"
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
			    -e '\%<add_on_products .*>%,\%</add_on_products>%  { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e '\%<packages .*>%,\%</packages>%                { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${__TGET_PATH}"                                          \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%        { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${__NUMS}/%g   " \
			    -e '/<!-- leap$/ s/$/ -->/g                              } ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e '\%<packages .*>%,\%</packages>%                      { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e '/<!-- leap$/ s/$/ -->/g                              } ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%              '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop$/       s/$/ -->/g '         \
	    -e '/^desktop -->/        s/^/<!-- /g'         \
	    -e '/<!-- desktop gnome$/ s/$/ -->/g '         \
	    -e '/^desktop gnome -->/  s/^/<!-- /g'         \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}"
	unset __VERS __NUMS __WORK __REAL __DIRS __OWNR
}

# -----------------------------------------------------------------------------
# descript: make autoinst.json
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_agama() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
#	declare       __PDCT=""				# product name
	declare       __PDID=""				# "       id
	declare       __WORK=""				# work variables
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_AGMA}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__WORK="${__TGET_PATH##*/}"			# file name
	__VERS="${__WORK#*_}"				# autoinst_(name)-(nums)_ ...: (ex: autoinst_leap-16.0_desktop.json)
	__VERS="${__VERS%%_*}"				# vers="(name)-(nums)"
	__VERS="${__VERS,,}"
	__NUMS="${__VERS##*-}"
#	__PDCT="${__VERS%%-*}"
	__PDID="${__VERS//-/_}"
	__PDID="${__PDID^}"
	# --- by product id -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_tumbleweed_*) __PDID="Tumbleweed";;
		*             ) __PDID="openSUSE_Leap";;
	esac
	# --- by media ------------------------------------------------------------
	# --- by version ----------------------------------------------------------
	case "${__TGET_PATH}" in
		*_tumbleweed_*) __WORK="leap";;
		*             ) __WORK="tumbleweed";;
	esac
	sed -i "${__TGET_PATH}"                                   \
	    -e '/"product": {/,/}/                             {' \
	    -e '/"id":/ s/"[^ ]\+"$/"'"${__PDID}"'"/           }' \
	    -e '/"extraRepositories": \[/,/\]/                 {' \
	    -e '\%^// '"${__WORK}"'%,\%^// '"${__WORK}"'%d      ' \
	    -e '\%^//.*$%d                                     }' \
	    -e '\%^// fixed parameter%,\%^// fixed parameter%d  '
	# --- desktop -------------------------------------------------------------
	__WORK="${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	cp "${__TGET_PATH}" "${__WORK}"
	sed -i "${__TGET_PATH}"                   \
	    -e '/"patterns": \[/,/\]/          {' \
	    -e '\%^// desktop%,\%^// desktop%d }' \
	    -e '/"packages": \[/,/\]/          {' \
	    -e '\%^// desktop%,\%^// desktop%d }'
	sed -i "${__WORK}"                        \
	    -e '/"patterns": \[/,/\]/          {' \
	    -e '\%^//.*$%d                     }' \
	    -e '/"packages": \[/,/\]/          {' \
	    -e '\%^//.*$%d                     }'
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}" "${__WORK}"
	unset __VERS __NUMS __PDCT __PDID __WORK __REAL __DIRS __OWNR
}

# -----------------------------------------------------------------------------
# descript: make preconfiguration files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __PTRN=""				# pattern
	declare -a    __TGET=()				# target
	declare       __LINE=""				# data line
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path

	# --- get target ----------------------------------------------------------
	__PTRN=""
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			a|all    ) __PTRN="agama|autoyast|kickstart|nocloud|preseed"; shift; break;;
			agama    ) ;;
			autoyast ) ;;
			kickstart) ;;
			nocloud  ) ;;
			preseed  ) ;;
			*) break;;
		esac
		__PTRN="${__PTRN:+"${__PTRN}|"}$1"
		shift
	done
	__NAME_REFR="${*:-}"

	# --- create a file  ------------------------------------------------------
	if [[ -n "${__PTRN:-}" ]]; then
		IFS= mapfile -d $'\n' -t __TGET < <(\
			printf "%s\n" "${_LIST_MDIA[@]}" | \
			awk -v ptrn="@/.*\/${__PTRN}\/.*/" '$2=="o" && $25!~/.*-$/ && $25~ptrn {
				print $25
				switch ($25) {
					case /.*\/agama\/.*/:
						sub("_leap-[0-9]+.[0-9]+", "_tumbleweed", $25)
						print $25
						break
					case /.*\/kickstart\/.*/:
						sub("_dvd", "_web", $25)
						print $25
						break
					default:
						break
				}
			}' | sort -uV || true \
		)
		for __PATH in "${__TGET[@]}"
		do
			case "${__PATH}" in
				*/preseed/*  ) fnMk_preconf_preseed   "${__PATH}";;
				*/nocloud/*  ) fnMk_preconf_nocloud   "${__PATH}/user-data";;
				*/kickstart/*) fnMk_preconf_kickstart "${__PATH}";;
				*/autoyast/* ) fnMk_preconf_autoyast  "${__PATH}";;
				*/agama/*    ) fnMk_preconf_agama     "${__PATH}";;
				*)	;;
			esac
		done
	fi
	unset __OPTN __PTRN __TGET __LINE __LIST __PATH

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
	declare -i    __TSMP=0
	declare -i    __TNOW=0
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
		if [[ -n "${__WORK:-}" ]] && [[ "${__MDIA[$((_OSET_MDIA+9))]##*.}" = "iso" ]]; then
			__TSMP="${__MDIA[$((_OSET_MDIA+10))]:-"0"}${__MDIA[$((_OSET_MDIA+10))]:+"$(TZ=UTC date -d "${__MDIA[$((_OSET_MDIA+10))]//%20/ }" "+%s")"}"
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
# descript: extract the compressed cpio
#   input :   $1   : target file
#   input :   $2   : destination directory
#   input :   $@   : cpio options
#   output: stdout : unused
#   return:        : unused
function fnXcpio() {
	  if gzip -t       "${1:?}" > /dev/null 2>&1 ; then gzip -c -d    "${1:?}"
	elif zstd -q -c -t "${1:?}" > /dev/null 2>&1 ; then zstd -q -c -d "${1:?}"
	elif xzcat -t      "${1:?}" > /dev/null 2>&1 ; then xzcat         "${1:?}"
	elif lz4cat -t <   "${1:?}" > /dev/null 2>&1 ; then lz4cat        "${1:?}"
	elif bzip2 -t      "${1:?}" > /dev/null 2>&1 ; then bzip2 -c -d   "${1:?}"
	elif lzop -t       "${1:?}" > /dev/null 2>&1 ; then lzop -c -d    "${1:?}"
	fi | (
		if [[ -n "${2:?}" ]]; then
			mkdir -p -- "${2:?}"
			cd -- "${2:?}" || exit
			shift
		fi
		shift
		cpio "${@:-}"
	)
}

# -----------------------------------------------------------------------------
# descript: extract the initrd
#   input :     $1     : target initrd file
#   input :     $2     : destination directory
#   output:   stdout   : message
#   return:            : unused
function fnXinitrd() {
	declare -r    __TGET_FILE="${1:?}"	# target initrd file
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
			if dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'; then
				__PEND=$((__PEND + 4))
				while dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
				do
					__PEND=$((__PEND + 4))
				done
				break
			fi
			__MGIC="$(dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count="6" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]6$')" || break
			case "${__MGIC}" in
				"070701" | "070702") ;;
				*                  ) break;;
			esac
			__NSIZ=0x$(dd if="${__TGET_FILE:?}" bs=1 skip="$((__PEND + 94))" count="8" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]8$')
			__FSIZ=0x$(dd if="${__TGET_FILE:?}" bs=1 skip="$((__PEND + 54))" count="8" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]8$')
			__PEND=$((__PEND + 110))
			__PEND=$(((__PEND + __NSIZ + 3) & ~3))
			__PEND=$(((__PEND + __FSIZ + 3) & ~3))
		done
		[[ "${__PEND}" -eq "${__PSTR}" ]] && break
		((__CONT+=1))
		__DSUB="early"
		[[ "${__CONT}" -gt 1 ]] && __DSUB+="${__CONT}"
		dd if="${__TGET_FILE}" skip="${__PSTR}" count="$((__PEND - __PSTR))" iflag=skip_bytes 2> /dev/null | (
			if [[ -n "${__DIRS_DEST}" ]]; then
				mkdir -p -- "${__DIRS_DEST}/${__DSUB}"
				cd -- "${__DIRS_DEST}/${__DSUB}" || exit
			fi
			cpio -i "${__OPTS[@]}"
		)
		__PSTR="${__PEND}"
	done
	if [[ "${__PEND}" -le 0 ]]; then
		fnXcpio "${__TGET_FILE}" "${__DIRS_DEST}" -i "${__OPTS[@]}"
	else
		__SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${__SARC%/*}"
		dd if="${__TGET_FILE}" skip="${__PEND}" iflag=skip_bytes 2> /dev/null > "${__SARC}"
		fnXcpio "${__SARC}" "${__DIRS_DEST:+${__DIRS_DEST}/main}" -i "${__OPTS[@]}"
		rm -f "${__SARC:?}"
	fi
}

# -----------------------------------------------------------------------------
# descript: make boot options for preseed
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_option_preseed() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}auto=true preseed/file=/cdrom${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/file=\/cdrom/url=\$\{srvraddr\}}"
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
			ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*                        ) __WORK="${__WORK/\/cdrom/}";;
			*                               ) ;;
		esac
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${__MDIA[$((_OSET_MDIA+2))]}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
			ubuntu-*) __WORK="${__WORK:+"${__WORK} "}netcfg/target_network_config=NetworkManager";;
			*       ) ;;
		esac
		__WORK="${__WORK:+"${__WORK} "}netcfg/disable_autoconfig=true"
		__WORK="${__WORK:+"${__WORK} "}netcfg/choose_interface=\${ethrname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_hostname=\${hostname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_ipaddress=\${ipv4addr}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_netmask=\${ipv4mask}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_gateway=\${ipv4gway}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_nameservers=\${ipv4nsvr}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+22))]#"${_DIRS_LOAD}"} iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_RMAK##*/}/${__MDIA[$((_OSET_MDIA+14))]##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: make boot options for nocloud
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_option_nocloud() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=/cdrom${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/\/cdrom/url=\$\{srvraddr\}}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${__MDIA[$((_OSET_MDIA+2))]}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
			ubuntu-live-18.04   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
			*                   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
		esac
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="ip=dhcp";;
		*   ) __WORK="${__WORK:-"ip=dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+22))]#"${_DIRS_LOAD}"} iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_RMAK##*/}/${__MDIA[$((_OSET_MDIA+14))]##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: make boot options for kickstart
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_option_kickstart() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}inst.ks=hd:sr0:${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/hd:sr0:/\$\{srvraddr\}}"
			__WORK="${__WORK/_dvd/_web}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK:+"${__WORK} "}inst.repo=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}"
		else
			__WORK="${__WORK:+"${__WORK} "}inst.stage2=hd:LABEL=${__MDIA[$((_OSET_MDIA+17))]}"
		fi
	else
		case "${2}" in
			clive) __WORK="${__WORK:+"${__WORK} "}root=live:\${srvraddr}/${_DIRS_RMAK##*/}/${__MDIA[$((_OSET_MDIA+14))]##*/}";;
			*    ) __WORK="${__WORK:+"${__WORK} "}root=live:\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: make boot options for autoyast
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_option_autoyast() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}autoyast=cd:${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/cd:/\$\{srvraddr\}}"
			__WORK="${__WORK/_dvd/_web}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			case "${__MDIA[$((_OSET_MDIA+2))]}" in
				opensuse-leap*netinst*      ) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/distribution/leap/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}/repo/oss/";;
				opensuse-tumbleweed*netinst*) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
				*                           ) __WORK="${__WORK:+"${__WORK} "}install=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}";;
			esac
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: make boot options for agama
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_option_agama() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}live.password=install inst.auto=dvd:${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/dvd:/\$\{srvraddr\}}"
			__WORK="${__WORK/_dvd/_web}"
		else
			__WORK="${__WORK:+"${__WORK}?devices=sr0"}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
		case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
			opensuse-*-15*) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
			*             ) ;;
		esac
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]:-}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
				opensuse-leap*netinst*      ) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/distribution/leap/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}/repo/oss/";;
				opensuse-tumbleweed*netinst*) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
				*                           ) __WORK="${__WORK:+"${__WORK} "}install=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}";;
			esac
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: make boot options
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_boot_options() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __MDIA=("${@:-}")
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		debian-*|live-debian-*| \
		ubuntu-*|live-ubuntu-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/preseed/*) fnMk_boot_option_preseed "${__TGET_TYPE}" "${@}";;
				*/nocloud/*) fnMk_boot_option_nocloud "${__TGET_TYPE}" "${@}";;
				*          ) ;;
			esac
			;;
		fedora-*      |live-fedora-*      | \
		centos-*      |live-centos-*      | \
		almalinux-*   |live-almalinux-*   | \
		rockylinux-*  |live-rockylinux-*  | \
		miraclelinux-*|live-miraclelinux-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/kickstart/*) fnMk_boot_option_kickstart "${__TGET_TYPE}" "${@}";;
				*            ) ;;
			esac
			;;
		opensuse-*|live-opensuse-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/autoyast/*) fnMk_boot_option_autoyast "${__TGET_TYPE}" "${@}";;
				*/agama/*   ) fnMk_boot_option_agama    "${__TGET_TYPE}" "${@}";;
				*           ) ;;
			esac
			;;
		* ) ;;
	esac
}

# -----------------------------------------------------------------------------
# descript: clear pxeboot menu
#   input :     $@     : file name
#   output:   stdout   : message
#   return:            : unused
function fnMk_pxeboot_clear_menu() {
	declare       __DIRS=""
	__DIRS="$(fnDirname "${1:?}")"
	if [[ -z "${__DIRS:-}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "invalid value: [${1:-}]"
		return
	fi
	mkdir -p "${__DIRS:?}"
	: > "${1:?}"
}

# -----------------------------------------------------------------------------
# descript: make header and footer for ipxe menu in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_hdrftr() {
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		#!ipxe

		cpuid --ext 29 && set arch amd64 || set arch x86

		dhcp

		set optn-timeout 1000
		set menu-timeout 0
		isset ${menu-default} || set menu-default exit

		:start

		:menu
		menu Select the OS type you want to boot
		item --gap --                                   --------------------------------------------------------------------------
		item --gap --                                   [ System command ]
		item -- shell                                   - iPXE shell
		#item -- shutdown                               - System shutdown
		item -- restart                                 - System reboot
		item --gap --                                   --------------------------------------------------------------------------
		choose --timeout ${menu-timeout} --default ${menu-default} selected || goto menu
		goto ${selected}

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
}

# -----------------------------------------------------------------------------
# descript: make Windows section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_windows() {
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w${__MDIA[$((_OSET_MDIA+2))]##*-}.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}

# -----------------------------------------------------------------------------
# descript: make WinPE section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_winpe() {
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}

# -----------------------------------------------------------------------------
# descript: make aomei backup section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_aomei() {
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_m86p() {
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		iseq \${platform} efi && set knlfile \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || set knlfile \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit
_EOT_
}

# -----------------------------------------------------------------------------
# descript: make linux section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe_linux() {
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
#		mini    ) ;;
#		netinst ) ;;
#		dvd     ) ;;
#		liveinst) ;;
		live    ) __ENTR="live-";;		# original media live mode
#		tool    ) ;;					# tools
#		clive   ) ;;					# custom media live mode
#		cnetinst) ;;					# custom media install mode
#		system  ) ;;					# system command
		*       ) __ENTR="";;			# original media install mode
	esac
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) ;;
	esac
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	if [[ -z "${__ENTR:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${__MDIA[$((_OSET_MDIA+2))]}
			prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && set openmenu 1 ||
			set hostname ${__HOST:-}
			set ethrname ${__NICS:-}
			set ipv4addr ${_IPV4_ADDR:-}${__CIDR:-}
			set ipv4mask ${_IPV4_MASK:-}
			set ipv4gway ${_IPV4_GWAY:-}
			set ipv4nsvr ${_IPV4_NSVR:-}
			form                                    Configure Network Options
			item hostname                           Hostname
			item ethrname                           Interface
			item ipv4addr                           IPv4 address/netmask
			item ipv4gway                           IPv4 gateway
			item ipv4nsvr                           IPv4 nameservers
			isset \${openmenu} && present ||
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set autoinst ${__BOPT[0]:-}
			set language ${__BOPT[1]:-}
			set networks ${__BOPT[2]:-}
			set otheropt ${__BOPT[@]:3}
			form                                    Configure Autoinstall Options
			item autoinst                           Auto install
			item language                           Language
			item networks                           Network
			item otheropt                           Other options
			isset \${openmenu} && present ||
			echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || goto error
			boot || goto error
			exit
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${__ENTR:-}${__MDIA[$((_OSET_MDIA+2))]}
			set hostname ${__HOST:-}
			set ethrname ${__NICS:-}
			set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
			set ipv4gway ${_IPV4_GWAY:-}
			set ipv4nsvr ${_IPV4_NSVR:-}
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set autoinst ${__BOPT[0]:-}
			set language ${__BOPT[1]:-}
			set networks ${__BOPT[2]:-}
			set otheropt ${__BOPT[@]:3}
			echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || goto error
			boot || goto error
			exit
_EOT_
	fi
	unset __BOPT= __ENTR __CIDR __WORK
}

# -----------------------------------------------------------------------------
# descript: make make ipxe menu
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_ipxe() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __ENTR=""
	declare       __WORK=""
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_ipxe_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[$((_OSET_MDIA+1))]}" in
		m)								# (menu)
			[[ "${__LIST_MDIA[$((_OSET_MDIA+3))]:-}" = "%20" ]] && return
			__WORK="$(printf "%-48.48s[ %s ]" "item --gap --" "${__LIST_MDIA[$((_OSET_MDIA+3))]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[$((_OSET_MDIA+2))]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[$((_OSET_MDIA+14))]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[$((_OSET_MDIA+0))]}" in
#				mini    ) ;;
#				netinst ) ;;
#				dvd     ) ;;
#				liveinst) ;;
				live    ) __ENTR="live-";;		# original media live mode
#				tool    ) ;;					# tools
#				clive   ) ;;					# custom media live mode
#				cnetinst) ;;					# custom media install mode
#				system  ) ;;					# system command
				*       ) __ENTR="";;			# original media install mode
			esac
			__WORK="$(printf "%-48.48s%-54.54s %19.19s" "item -- ${__ENTR:-}${__LIST_MDIA[$((_OSET_MDIA+2))]}" "- ${__LIST_MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__LIST_MDIA[$((_OSET_MDIA+15))]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			case "${__LIST_MDIA[$((_OSET_MDIA+2))]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_ipxe_windows "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_ipxe_winpe   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_ipxe_aomei   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_ipxe_m86p    "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				*                      ) __WORK="$(fnMk_pxeboot_ipxe_linux   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
			esac
			sed -i "${__TGET_PATH}" -e "/^:shell$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}

# -----------------------------------------------------------------------------
# descript: make header and footer for grub.cfg in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_hdrftr() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
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
}

# -----------------------------------------------------------------------------
# descript: make Windows section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_windows() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		    set isofile="(${_SRVR_PROT:?},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}"
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
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make WinPE section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_winpe() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		    set isofile="(${_SRVR_PROT:?},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}"
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
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make aomei backup section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_aomei() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		    set isofile="(${_SRVR_PROT:?},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}"
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
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_m86p() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		    set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		    set knladdr=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		    insmod net
		    insmod http
		    insmod progress
		    echo Loading boot files ...
		    if [ "\${grub_platform}" = "pc" ]; then
		      linux \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		    else
		      linux \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		    fi
		  }
		fi
_EOT_
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make linux section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub_linux() {
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) ;;
	esac
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		menuentry '${__ENTR:-}' {
		  echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		  set hostname=${__HOST:-}
		  set ethrname=${__NICS:-}
		  set ipv4addr=${_IPV4_ADDR:-}${__CIDR:-}
		  set ipv4mask=${_IPV4_MASK:-}
		  set ipv4gway=${_IPV4_GWAY:-}
		  set ipv4nsvr=${_IPV4_NSVR:-}
		  set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		  set autoinst=${__BOPT[0]:-}
		  set language=${__BOPT[1]:-}
		  set networks=${__BOPT[2]:-}
		  set otheropt=${__BOPT[@]:3}
		  set options=\${autoinst} \${language} \${networks} \${otheropt}
		  set knladdr=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  insmod net
		  insmod http
		  insmod progress
		  echo Loading boot files ...
		  linux  \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		  initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		}
_EOT_
	unset __ENTR __BOPT __ENTR __CIDR __WORK
}

# -----------------------------------------------------------------------------
# descript: make grub.cfg for pxeboot
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_grub() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __SPCS=""				# tabs string (space)
	declare       __ENTR=""
	declare       __WORK=""
	# --- tab string ----------------------------------------------------------
	__SPCS="$(printf "%$(("${__CONT_TABS}" * 2))s" "")"
	# --- menu list -----------------------------------------------------------
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_grub_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[$((_OSET_MDIA+1))]}" in
		m)								# (menu)
			case "${__LIST_MDIA[$((_OSET_MDIA+3))]}" in
				System%20command) ;;
				%20             ) __WORK="${__SPCS}}\n";;
				*               ) __WORK="${__SPCS}submenu '[ ${__LIST_MDIA[$((_OSET_MDIA+3))]//%20/ } ... ]' {";;
			esac
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[$((_OSET_MDIA+2))]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[$((_OSET_MDIA+14))]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[$((_OSET_MDIA+2))]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_grub_windows "${__LIST_MDIA[@]}")";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_grub_winpe   "${__LIST_MDIA[@]}")";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_grub_aomei   "${__LIST_MDIA[@]}")";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_grub_m86p    "${__LIST_MDIA[@]}")";;
				*                      ) __WORK="$(fnMk_pxeboot_grub_linux   "${__LIST_MDIA[@]}")";;
			esac
			__WORK="$(printf "%s" "${__WORK}" | sed -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;')"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}

# -----------------------------------------------------------------------------
# descript: make header and footer for syslinux in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_hdrftr() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		path ./
		prompt 0
		timeout 0
		default vesamenu.c32

		${_MENU_RESO:+"menu resolution ${_MENU_RESO/x/ }"}

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
}

# -----------------------------------------------------------------------------
# descript: make Windows section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_windows() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  memdisk
		  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}
		  append iso raw
_EOT_
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make WinPE section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_winpe() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  memdisk
		  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}
		  append iso raw
_EOT_
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make aomei backup section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_aomei() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  memdisk
		  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}
		  append iso raw
_EOT_
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_m86p() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
_EOT_
	unset __ENTR
}

# -----------------------------------------------------------------------------
# descript: make linux section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx_linux() {
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) ;;
	esac
	case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	__BOPT=("${__BOPT[@]//\$\{srvraddr\}/${_SRVR_PROT:?}:\/\/${_SRVR_ADDR:?}}")
	__BOPT=("${__BOPT[@]//\$\{hostname\}/${__HOST:-}}")
	__BOPT=("${__BOPT[@]//\$\{ethrname\}/${__NICS:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4addr\}/${_IPV4_ADDR:-}${__CIDR:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4mask\}/${_IPV4_MASK:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4gway\}/${_IPV4_GWAY:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4nsvr\}/${_IPV4_NSVR:-}}")
	__BOPT=("${__BOPT[@]:1}")
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		  initrd ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		  append ${__BOPT[@]} --- quiet
_EOT_
	unset __ENTR __BOPT __ENTR __CIDR __WORK
}

# -----------------------------------------------------------------------------
# descript: make syslinux for pxeboot
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
function fnMk_pxeboot_slnx() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __SPCS=""				# tabs string (space)
	declare       __ENTR=""
	declare       __WORK=""
	# --- tab string ----------------------------------------------------------
	__SPCS="$(printf "%$(("${__CONT_TABS}" * 2))s" "")"
	# --- menu list -----------------------------------------------------------
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_slnx_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[$((_OSET_MDIA+1))]}" in
		m) ;;							# (menu)
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[$((_OSET_MDIA+2))]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[$((_OSET_MDIA+14))]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[$((_OSET_MDIA+2))]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_slnx_windows "${__LIST_MDIA[@]}")";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_slnx_winpe   "${__LIST_MDIA[@]}")";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_slnx_aomei   "${__LIST_MDIA[@]}")";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_slnx_m86p    "${__LIST_MDIA[@]}")";;
				*                      ) __WORK="$(fnMk_pxeboot_slnx_linux   "${__LIST_MDIA[@]}")";;
			esac
			__WORK="$(printf "%s" "${__WORK}" | sed -e ':l; N; s/\n/\\n/; b l;')"
			sed -i "${__TGET_PATH}" -e "/^label System-command$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}

# -----------------------------------------------------------------------------
# descript: make pxeboot files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_pxeboot() {
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
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# data array
	declare -i    __TABS=0				# tab count
	declare       __WORK=""
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
			a|all    ) __PTRN=(["mini"]=".*" ["netinst"]=".*" ["dvd"]=".*" ["liveinst"]=".*" ["live"]=".*" ["tool"]=".*"); shift; break;;
			mini     ) ;;
			netinst  ) ;;
			dvd      ) ;;
			liveinst ) ;;
			live     ) ;;
			tool     ) ;;
			clive    ) shift; continue;;
			cnetinst ) shift; continue;;
			system   ) shift; continue;;
			*) break;;
		esac
		case "${__TGID:-}" in
			a|all           ) __PTRN["${__TYPE}"]=".*";;
			[0-9]|[0-9][0-9]) __PTRN["${__TYPE}"]="${__PTRN["${__TYPE}"]:+"${__PTRN["${__TYPE}"]} "}${__TGID}";;
			*               ) ;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	# --- create pxeboot menu file --------------------------------------------
	fnMk_pxeboot_clear_menu "${_PATH_IPXE:?}"				# ipxe
	fnMk_pxeboot_clear_menu "${_PATH_GRUB:?}"				# grub
	fnMk_pxeboot_clear_menu "${_PATH_SLNX:?}"				# syslinux (bios)
	fnMk_pxeboot_clear_menu "${_PATH_UEFI:?}"				# syslinux (efi64)
	for __TYPE in "${_LIST_TYPE[@]}"
	do
		[[ -z "${__PTRN["${__TYPE:-}"]:-}" ]] && continue
		__TGID="${__PTRN["${__TYPE:-}"]// /|}"
		fnMk_print_list __LINE "${__TYPE:-}" "${__TGID:-}"
		IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			case "${__MDIA[$((_OSET_MDIA+1))]}" in
				m)						# (menu)
					[[ "${__MDIA[$((_OSET_MDIA+3))]}" = "%20" ]] && __TABS=$((__TABS-1))
					[[ "${__TABS}" -lt 0 ]] && __TABS=0
					;;
				o)						# (output)
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
						*) ;;
					esac
					# --- rsync -----------------------------------------------
					fnRsync "${__MDIA[$((_OSET_MDIA+14))]}" "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}"
					;;
				*) ;;					# (hidden)
			esac
			# --- create menu file --------------------------------------------
			fnMk_pxeboot_ipxe "${_PATH_IPXE:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# ipxe
			fnMk_pxeboot_grub "${_PATH_GRUB:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# grub
			fnMk_pxeboot_slnx "${_PATH_SLNX:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (bios)
			fnMk_pxeboot_slnx "${_PATH_UEFI:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (efi64)
			# --- tab ---------------------------------------------------------
			case "${__MDIA[$((_OSET_MDIA+1))]}" in
				m)						# (menu)
					[[ "${__MDIA[$((_OSET_MDIA+3))]}" != "%20" ]] && __TABS=$((__TABS+1))
					[[ "${__TABS}" -lt 0 ]] && __TABS=0
					;;
				o) ;;					# (output)
				*) ;;					# (hidden)
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
	unset __OPTN __PTRN __TYPE __LINE __TGET __MDIA __RETN __ARRY __TABS I J

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
#   input :     $2     : configuration files
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_conf() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_CONF="${2:?}"	# configuration files
	declare       __PATH=""				# target path
	declare       __SRCS=""				# source path
	declare       __DEST=""				# destination path
	declare       __FILE=""				# full path
	declare       __DIRS=""				# directory
	declare       __BASE=""				# base name
	declare       __FNAM=""				# file name
	declare       __EXTN=""				# extension
	declare       __WORK=""

	for __PATH in         \
		"${_PATH_ERLY:-}" \
		"${_PATH_LATE:-}" \
		"${_PATH_PART:-}" \
		"${_PATH_RUNS:-}" \
		"${__FILE_CONF}"
	do
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
		__FILE="${__PATH#"${_DIRS_CONF%/*}/"}"
		__DIRS="$(fnDirname   "${__FILE:-}")"
		__BASE="$(fnBasename  "${__FILE:-}")"
		__FNAM="$(fnFilename  "${__FILE:-}")"
		__EXTN="$(fnExtension "${__FILE:-}")"
		__DEST="${__DIRS_TGET}/${__DIRS:?}"
		case "${__PATH}" in
			*/script/*   )
				printf "\033[m%-8s: %s\033[m\n" "copy" "${__FILE}"
				mkdir -p "${__DEST:?}"
				cp --preserve=timestamps "${__PATH}" "${__DEST}"
				chmod ugo+rx-w "${__DEST}/${__BASE}"
				;;
			*/agama/*    | \
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
				__WORK="${__FNAM#*_*_}"
				__WORK="${__FNAM%"${__WORK:-}"}"
				__WORK="${__WORK:+"${__WORK}*${__EXTN:+".${__EXTN}"}"}"
				if [[ -d "${__PATH}"/. ]]; then
					__WORK="${__WORK:-"${__BASE%"${__BASE##*_}"}*"}"
				else
					__WORK="${__WORK:-"${__BASE:-}"}"
				fi
				find "${__PATH%/*}" -maxdepth 1 -name "${__WORK:-}" | sort -uV | while read -r __SRCS
				do
					printf "\033[m%-8s: %s\033[m\n" "copy" "${__SRCS#"${_DIRS_CONF%/*}/"}"
					mkdir -p "${__DEST:?}"
					if [[ -d "${__SRCS:?}"/. ]]; then
						cp -R --preserve=timestamps "${__SRCS}" "${__DEST}"
						find "${__DEST}/${__SRCS##*/}" -type f -exec chmod ugo+r-xw {} \;
					else
						cp --preserve=timestamps "${__SRCS}" "${__DEST}"
						chmod ugo+r-xw "${__DEST}/${__SRCS##*/}"
					fi
				done
				;;
			*) ;;
		esac
	done
}

# -----------------------------------------------------------------------------
# descript: make autoinst.cfg files for grub.cfg
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : theme.txt file name
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : nic name
#   input :     $7     : host name
#   input :     $8     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_grub_autoinst() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare -r    __PATH_THME="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __PATH_GUIS="${6:-}"
	declare -r    __NICS_NAME="${7:?}"
	declare -r    __NWRK_HOST="${8:?}"
	declare -r    __IPV4_CIDR="${9:-}"
	declare -r -a __OPTN_BOOT=("${@:10}")
	declare       __DIRS=""
	declare       __TITL=""
	__TITL="$(printf "%s%s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	# --- common settings -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		set default="0"
		set timeout="${_MENU_TOUT:-5}"

		if [ "x\${feature_default_font_path}" = "xy" ] ; then
		  font="unicode"
		else
		  font="\${prefix}/fonts/font.pf2"
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
		  set gfxpayload="keep"
		  export gfxmode
		  export gfxpayload
		  if [ "\${grub_platform}" = "efi" ]; then
		    insmod efi_gop
		    insmod efi_uga
		  else
		    insmod vbe
		    insmod vga
		  fi
		  insmod video_bochs
		  insmod video_cirrus
		  insmod gfxterm
		  insmod gettext
		  insmod png
		  terminal_output gfxterm
		fi

		#set timeout_style=menu
		#set color_normal=light-gray/black
		#set color_highlight=white/dark-gray
		#export color_normal
		#export color_highlight

		set theme=${__PATH_THME:-}
		export theme

		#insmod play
		#play 960 440 1 0 4 440 1
_EOT_
	# --- default--------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

		menuentry 'Automatic installation' {
		  echo 'Loading ${__TITL:+"${__TITL} "}...'
		  set gfxpayload="keep"
		  set background_color="black"
		  set hostname="${__NWRK_HOST}"
		  set ethrname="${__NICS_NAME}"
		  set ipv4addr="${_IPV4_ADDR:-}${__IPV4_CIDR:-}"
		  set ipv4mask="${_IPV4_MASK:-}"
		  set ipv4gway="${_IPV4_GWAY:-}"
		  set ipv4nsvr="${_IPV4_NSVR:-}"
		  set srvraddr="${_SRVR_PROT:?}://${_SRVR_ADDR:?}"
		  set autoinst="${__OPTN_BOOT[0]:-}"
		  set language="${__OPTN_BOOT[1]:-}"
		  set networks="${__OPTN_BOOT[2]:-}"
		  set otheropt="${__OPTN_BOOT[@]:3}"
		  set options="\${autoinst} \${language} \${networks} \${otheropt}"
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  linux  ${__PATH_FKNL:-} \${options} --- quiet
		  initrd ${__PATH_FIRD:-}
		}
_EOT_
	# --- gui -----------------------------------------------------------------
	if [[ -n "${__PATH_GUIS:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

			menuentry 'Automatic installation gui' {
			  echo 'Loading ${__TITL:+"${__TITL} "}...'
			  set gfxpayload="keep"
			  set background_color="black"
			  set hostname="${__NWRK_HOST}"
			  set ethrname="${__NICS_NAME}"
			  set ipv4addr="${_IPV4_ADDR:-}${__IPV4_CIDR:-}"
			  set ipv4mask="${_IPV4_MASK:-}"
			  set ipv4gway="${_IPV4_GWAY:-}"
			  set ipv4nsvr="${_IPV4_NSVR:-}"
			  set srvraddr="${_SRVR_PROT:?}://${_SRVR_ADDR:?}"
			  set autoinst="${__OPTN_BOOT[0]:-}"
			  set language="${__OPTN_BOOT[1]:-}"
			  set networks="${__OPTN_BOOT[2]:-}"
			  set otheropt="${__OPTN_BOOT[@]:3}"
			  set options="\${autoinst} \${language} \${networks} \${otheropt}"
			  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			  echo 'Loading boot files ...'
			  linux  ${__PATH_FKNL:-} \${options} --- quiet
			  initrd ${__PATH_GUIS:-}
			}
_EOT_
	fi
	# --- system command ------------------------------------------------------
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
#
#		menuentry '[ System command ]' {
#		  true
#		}
#
#		menuentry '- System shutdown' {
#		  echo "System shutting down ..."
#		  halt
#		}
#
#		menuentry '- System restart' {
#		  echo "System rebooting ..."
#		  reboot
#		}
#
#		if [ "\${grub_platform}" = "efi" ]; then
#		  menuentry '- Boot from next volume' {
#		    exit 1
#		  }
#
#		  menuentry '- UEFI Firmware Settings' {
#		    fwsetup
#		  }
#		fi
#_EOT_
	unset __DIRS __TITL
}

# -----------------------------------------------------------------------------
# descript: make theme.txt files for grub.cfg
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_grub_theme() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare       __TITL=""
	__TITL="$(printf "%s%s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		desktop-image: ":_DTPIMG_:"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		${__TITL:+"title-text: \"Boot Menu: ${__TITL}"\"}
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
	unset __TITL
}

# -----------------------------------------------------------------------------
# descript: make grub.cfg files
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : iso file time stamp
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : nic name
#   input :     $7     : host name
#   input :     $8     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_grub() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NICS_NAME="${6:?}"
	declare -r    __NWRK_HOST="${7:?}"
	declare -r    __IPV4_CIDR="${8:-}"
	declare -r -a __OPTN_BOOT=("${@:9}")
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __BASE=""				# base name
	declare       __FILE=""				# file name
	declare       __PAUT=""				# autoinst.cfg
	declare       __PTHM=""				# theme.txt
	declare       __SPLS=""				# splash.png
	declare       __CONF=""				# configuration files
	declare       __WORK=""
	__SPLS=""
	while read -r __CONF
	do
		__DIRS="$(fnDirname "${__CONF#"${__TGET_DIRS}"}")"
		__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
		__PTHM="${__DIRS%/}/theme.txt"
		__DIRS="$(fnDirname  "${__PATH_FIRD}")"
		__BASE="$(fnBasename "${__PATH_FIRD}")"
		__GUIS=""
		if [[ -e "${__TGET_DIRS}/${__DIRS#/}/gtk/${__BASE:?}" ]]; then
			__GUIS="/${__DIRS#/}/gtk/${__BASE}"
		fi
		# --- create files ----------------------------------------------------
		fnMk_isofile_grub_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__TGET_DIRS}/${__PTHM}"
		fnMk_isofile_grub_autoinst "${__FILE_NAME:-}" "${__TIME_STMP:-}" "${__PTHM#"${__TGET_DIRS}"}" "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__GUIS}" "${__NICS_NAME:-}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__TGET_DIRS}/${__PAUT}"
		# --- insert autoinst.cfg ---------------------------------------------
		sed -i "${__CONF}"                            \
		    -e '0,/^menuentry/ {'                     \
		    -e '/^menuentry/i source '"${__PAUT}"'\n' \
		    -e '}'
		# --- splash.png ------------------------------------------------------
		                          __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/boot/*'     -iname "${_MENU_SPLS:-}")"
		[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/isolinux/*' -iname "${_MENU_SPLS:-}")"
		[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/*'          -iname "${_MENU_SPLS:-}")"
		if [[ -n "${__PATH:-}" ]]; then
			__WORK="$(file "${__PATH:-}" | awk '{sub("[^0-9]+","",$8); print $8;}')"
			[[ "${__WORK:-"0"}" -ge 8 ]] && __SPLS="${__PATH}"
		fi
	done < <(find "${__TGET_DIRS}" -name grub.cfg -exec grep -ilE 'menuentry .*install' {} \;)
	if [[ -n "${__SPLS:-}" ]]; then
		__SPLS="${__SPLS#"${__TGET_DIRS}"}"
		sed -i "${__TGET_DIRS}/${__PTHM}"                              \
			-e '/desktop-image:/ s/:_DTPIMG_:/'"${__SPLS//\//\\\/}"'/'
	else
		sed -i "${__TGET_DIRS}/${__PTHM}" \
			-e '/desktop-image:/d'
	fi
	# --- comment out ---------------------------------------------------------
	find "${__TGET_DIRS}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __CONF
	do
		sed -i "${__CONF}"                                              \
		    -e '/^[ \t]*\(\|set[ \t]\+\)default=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)timeout=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/              s/^/#/g'
#		    -e '/^[ \t]*\(\|set[ \t]\+\)theme=/                s/^/#/g' \
#		    -e '/^[ \t]*export theme/                          s/^/#/g' \
# 		    -e '/^[ \t]*if[ \t]\+sleep/,/^[ \t]*fi/            s/^/#/g' \
#		    -e '/^[ \t]*if[ \t]\+background_image/,/^[ \t]*fi/ s/^/#/g'
#		    -e '/^[ \t]*play/                                  s/^/#/g'
	done
	unset __PATH __DIRS __BASE __FILE __PAUT __PTHM
}

# -----------------------------------------------------------------------------
# descript: make autoinst.cfg files for isolinux
#   input :     $1     : kernel path
#   input :     $2     : initrd path
#   input :     $3     : nic name
#   input :     $4     : host name
#   input :     $5     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_ilnx_autoinst() {
	declare -r    __PATH_FKNL="${1:?}"
	declare -r    __PATH_FIRD="${2:?}"
	declare -r    __NICS_NAME="${3:?}"
	declare -r    __NWRK_HOST="${4:?}"
	declare -r    __IPV4_CIDR="${5:-}"
	declare -r -a __OPTN_BOOT=("${@:6}")
	declare -a    __BOPT=()				# boot options
	declare       __DIRS=""
	# --- convert -------------------------------------------------------------
	__BOPT=("${__OPTN_BOOT[@]:-}")
	__BOPT=("${__BOPT[@]//\$\{srvraddr\}/}")
	__BOPT=("${__BOPT[@]//\$\{hostname\}/${__NWRK_HOST:-}}")
	__BOPT=("${__BOPT[@]//\$\{ethrname\}/${__NICS_NAME:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4addr\}/${_IPV4_ADDR:-}${__IPV4_CIDR:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4mask\}/${_IPV4_MASK:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4gway\}/${_IPV4_GWAY:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4nsvr\}/${_IPV4_NSVR:-}}")
	__BOPT=("${__BOPT[@]}")
	# --- default--------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label auto-install
		  menu label ^Automatic installation
		  menu default
		  linux  ${__PATH_FKNL}
		  initrd ${__PATH_FIRD}
		  append ${__BOPT[@]} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
_EOT_
	# --- gui -----------------------------------------------------------------
	__DIRS="$(fnDirname  "${__PATH_FIRD}")"
	if [[ -e "${__DIRS:-}"/gtk/${__PATH_FKNL##*/} ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

			label auto-install-gui
			  menu label ^Automatic installation gui
			  linux  ${__PATH_FKNL}
			  initrd ${__DIRS:-}/gtk/${__PATH_FKNL##*/}
			  append ${__BOPT[@]} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
_EOT_
	fi
	# --- system command ------------------------------------------------------
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
#
#		label System-command
#		  menu label ^[ System command ... ]
#
#		label Hardware-info
#		  menu label ^- Hardware info
#		  com32 hdt.c32
#
#		label System-shutdown
#		  menu label ^- System shutdown
#		  com32 poweroff.c32
#
#		label System-restart
#		  menu label ^- System restart
#		  com32 reboot.c32
#_EOT_
	unset __DIRS
}

# -----------------------------------------------------------------------------
# descript: make theme.txt files for isolinux
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_ilnx_theme() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare       __TITL=""
	__TITL="$(printf "%s%s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		path ./
		prompt 0
		timeout 0
		UI vesamenu.c32

		${_MENU_RESO:+"menu resolution ${_MENU_RESO/x/ }"}
		${__TITL:+"menu title Boot Menu: ${__TITL}"}
		${_MENU_SPLS:+"menu background ${_MENU_SPLS}"}

		# MENU COLOR <Item>  <ANSI Seq.> <foreground> <background> <shadow type>
		menu color   screen       0       #80ffffff    #00000000        std      # background colour not covered by the splash image
		menu color   border       0       #ffffffff    #ee000000        std      # The wire-frame border
		menu color   title        0       #ffff3f7f    #ee000000        std      # Menu title text
		menu color   sel          0       #ff00dfdf    #ee000000        std      # Selected menu option
		menu color   hotsel       0       #ff7f7fff    #ee000000        std      # The selected hotkey (set with ^ in MENU LABEL)
		menu color   unsel        0       #ffffffff    #ee000000        std      # Unselected menu options
		menu color   hotkey       0       #ff7f7fff    #ee000000        std      # Unselected hotkeys (set with ^ in MENU LABEL)
		menu color   tabmsg       0       #c07f7fff    #00000000        std      # Tab text
		menu color   timeout_msg  0       #8000dfdf    #00000000        std      # Timout text
		menu color   timeout      0       #c0ff3f7f    #00000000        std      # Timout counter
		menu color   disabled     0       #807f7f7f    #ee000000        std      # Disabled menu options, including SEPARATORs
		menu color   cmdmark      0       #c000ffff    #ee000000        std      # Command line marker - The '> ' on the left when editing an option
		menu color   cmdline      0       #c0ffffff    #ee000000        std      # Command line - The text being edited
		menu color   scrollbar    0       #40000000    #00000000        std      # Scroll bar
		menu color   pwdborder    0       #80ffffff    #20ffffff        std      # Password box wire-frame border
		menu color   pwdheader    0       #80ff8080    #20ffffff        std      # Password box header
		menu color   pwdentry     0       #80ffffff    #20ffffff        std      # Password entry field
		menu color   help         0       #c0ffffff    #00000000        std      # Help text, if set via 'TEXT HELP ... ENDTEXT'

		menu margin             3
		menu vshift             2
		menu rows               20
		menu tabmsgrow          28
		menu cmdlinerow         30
		menu timeoutrow         30
		menu helpmsgrow         32
		menu hekomsgendrow      35

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		${_MENU_TOUT:+"timeout ${_MENU_TOUT}0"}
		default auto-install
_EOT_
	unset __TITL
}

# -----------------------------------------------------------------------------
# descript: make isolinux files
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : iso file time stamp
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : nic name
#   input :     $7     : host name
#   input :     $8     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_ilnx() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NICS_NAME="${6:?}"
	declare -r    __NWRK_HOST="${7:?}"
	declare -r    __IPV4_CIDR="${8:-}"
	declare -r -a __OPTN_BOOT=("${@:9}")
	__PATH="$(find "${__TGET_DIRS}" -name isolinux.cfg)"
	[[ -z "${__PATH:-}" ]] && return
	__DIRS="$(fnDirname "${__PATH#"${__TGET_DIRS}"}")"
	__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
	__PTHM="${__DIRS%/}/theme.txt"
	# --- create files --------------------------------------------------------
	fnMk_isofile_ilnx_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__TGET_DIRS}/${__PTHM}"
	fnMk_isofile_ilnx_autoinst "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__NICS_NAME:-}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__TGET_DIRS}/${__PAUT}"
	# --- insert autoinst.cfg -------------------------------------------------
	if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${__PATH}"; then
		sed -i "${__PATH}"                                                                   \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PAUT:?}"'' \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${__PTHM:?}"''
	else
		sed -i "${__PATH}"                                      \
		    -e '0,/\([Ll]abel\|LABEL\)/ {'                      \
		    -e '/\([Ll]abel\|LABEL\)/i include '"${__PAUT}"'\n' \
		    -e '}'
	fi
	# --- comment out ---------------------------------------------------------
	find "${__TGET_DIRS}/${__DIRS:-"/"}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __PATH
	do
		sed -i "${__PATH}"                                                               \
		    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   d}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               d'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 d'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           d'
	done
	unset __PATH __DIRS __FILE __PAUT __PTHM
}

# -----------------------------------------------------------------------------
# descript: make customize iso files
#   input :     $1     : target directory
#   input :     $2     : output file name
#   input :     $3     : volume id
#   input :     $4     : grub mbr file name
#   input :     $5     : uefi file name
#   input :     $6     : eltorito catalog file name
#   input :     $7     : eltorito boot file name
#   output:   stdout   : message
#   return:            : unused
function fnMk_isofile_rebuild() {
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
			${__FILE_VLID:+-volid "'${__FILE_VLID}'"} \
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
			${__FILE_VLID:+-volid "'${__FILE_VLID}'"} \
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
	echo "create iso image file ..."
	[[ -n "${__FILE_HBRD:-}" ]] && echo "hybrid mode"
	[[ -n "${__FILE_BIOS:-}" ]] && echo "eltorito mode"
	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! nice -n 19 xorrisofs "${__OPTN[@]}" -output "${__TEMP}" .; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${__FILE_ISOS##*/}" 1>&2
			printf "%s\n" "xorrisofs ${__OPTN[*]} -output ${__TEMP} ."
sleep 600
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
	unset __REAL __DIRS __OWNR

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
	declare       __NAME=""
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
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
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR="/${_IPV4_CIDR:-}"
	declare       __LABL=""
	declare       __FMBR=""
	declare       __FEFI=""
	declare       __SKIP=""
	declare       __SIZE=""
	declare       __FCAT=""
	declare       __FBIN=""
	declare       __HBRD=""
	declare -i    __TABS=0				# tab count
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
								*) ;;
							esac
							# --- rsync ---------------------------------------
							fnRsync "${__MDIA[$((_OSET_MDIA+14))]}" "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}"
							# --- mount ---------------------------------------
							rm -rf "${__DOVL:?}"
							mkdir -p "${__DUPR}" "${__DLOW}" "${__DWKD}" "${__DMRG}"
#							mount -r "${__MDIA[$((_OSET_MDIA+14))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount --bind "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount -t overlay overlay -o lowerdir="${__DLOW}",upperdir="${__DUPR}",workdir="${__DWKD}" "${__DMRG}" && _LIST_RMOV+=("${__DMRG:?}")
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
								*              ) ;;
							esac
							case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
								ubuntu*) __CIDR="";;
								*      ) ;;
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
							fnMk_isofile_rebuild "${__DMRG}" "${__MDIA[$((_OSET_MDIA+18))]}" "${__MDIA[$((_OSET_MDIA+17))]}" "${__HBRD:-}" "${__FMBR:-}" "${__FEFI:-}" "${__FCAT#"${__DMRG}/"}" "${__FBIN#"${__DMRG}/"}"
							__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+18))]}")"
							read -r -a __ARRY < <(echo "${__RETN}")
							__MDIA[_OSET_MDIA+19]="${__ARRY[1]:-}"	# rmk_tstamp
							__MDIA[_OSET_MDIA+20]="${__ARRY[2]:-}"	# rmk_size
							__MDIA[_OSET_MDIA+21]="${__ARRY[3]:-}"	# rmk_volume
							# --- umount --------------------------------------
							umount "${__DMRG}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							umount "${__DLOW}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							rm -rf "${__TEMP:?}"
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
	unset __OPTN __PTRN __TYPE __LINE __TGET __MDIA __RETN __ARRY __TABS I J

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
		    -l|--link   : making directories and symbolic links
		    -c|--conf   : making preconfiguration files
		    -p|--pxe    : making pxeboot menu
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
			-l|--link) fnMk_symlink "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-c|--conf) fnMk_preconf "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-p|--pxe ) fnMk_pxeboot "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-m|--make) fnMk_isofile "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
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
