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
	declare       _DIRS_TEMP=""			# local
	              _DIRS_TEMP="$(mktemp -qd "${_DIRS_WTOP}/${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP
	declare       _DIRS_RTMP=""			# remote
#	              _DIRS_RTMP="$(mktemp -qd "${_DIRS_PVAT:?}/wrk/mkosi.XXXXXX")"
#	readonly      _DIRS_RTMP

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

	# --- tftp menu -----------------------------------------------------------
	declare       _FILE_IPXE="autoexec.ipxe"				# ipxe
	declare       _FILE_GRUB="boot/grub/grub.cfg"			# grub
	declare       _FILE_SLNX="menu-bios/syslinux.cfg"		# syslinux (bios)
	declare       _FILE_EF64="menu-efi64/syslinux.cfg"		# syslinux (efi64)
	declare       _PATH_IPXE=":_DIRS_TFTP_:/:_FILE_IPXE_:"	# ipxe
	declare       _PATH_GRUB=":_DIRS_TFTP_:/:_FILE_GRUB_:"	# grub
	declare       _PATH_SLNX=":_DIRS_TFTP_:/:_FILE_SLNX_:"	# syslinux (bios)
	declare       _PATH_EF64=":_DIRS_TFTP_:/:_FILE_EF64_:"	# syslinux (efi64)

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

	# --- mkosi command line parameter ----------------------------------------
	declare       _MKOS_BOOT=""			# --bootable=
	declare       _MKOS_OUTP=""			# --output=
	declare       _MKOS_FMAT=""			# --format=
	declare       _MKOS_NWRK=""			# --with-network=
	declare       _MKOS_RECM=""			# --with-recommends
	declare       _MKOS_DIST=""			# --distribution=
	declare       _MKOS_VERS=""			# --release=
	declare       _MKOS_ARCH=""			# --architecture=

	# --- live files ----------------------------------------------------------
	declare       _FILE_RTIM=""			# root image
	declare       _FILE_SQFS=""			# squashfs
	declare       _FILE_MBRF=""			# mbr image
	declare       _FILE_UEFI=""			# uefi image
	declare       _FILE_BCAT=""			# eltorito catalog
	declare       _FILE_ETRI=""			# 
	declare       _FILE_BIOS=""			# 

	declare       _FILE_ICFG=""			# isolinux.cfg
	declare       _FILE_GCFG=""			# grub.cfg
	declare       _FILE_MENU=""			# menu.cfg
	declare       _FILE_THME=""			# theme.cfg

	declare       _DIRS_LIVE=""			# live directory
	declare       _DIRS_MNTP=""			# mount point
	declare       _DIRS_RTFS=""			# root image
	declare       _DIRS_CDFS=""			# cdfs image

	declare       _PATH_VLNZ=""			# kernel
	declare       _PATH_IRAM=""			# initramfs
	declare       _PATH_SPLS=""			# splash.png

	declare       _SECU_OPTN=""			# security option
	declare       _SECU_APPA=""			# " (apparmor)
	declare       _SECU_SLNX=""			# " (selinux)

# *** function section (common functions) *************************************
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
			"${_DIRS_TEMP:?}" | \
			"${_DIRS_RTMP:?}"  )
				fnMsgout "${_PROG_NAME:-}" "remove" "${__PATH}"
				rm -rf "${__PATH:?}" || true
				;;
			/dev/*)
				fnMsgout "${_PROG_NAME:-}" "detach" "${__PATH}"
				losetup --detach "${__PATH}" || true
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
#	_TGET_VIRT=""						# virtualization (ex. vmware)
#	_TGET_CHRT=""						# is chgroot     (empty: none, else: chroot)
#	_TGET_CNTR=""						# is container   (empty: none, else: container)
#	if command -v systemd-detect-virt > /dev/null 2>&1; then
#		_TGET_VIRT="$(systemd-detect-virt --vm || true)"
#		systemd-detect-virt --quiet --chroot    && _TGET_CHRT="true"
#		systemd-detect-virt --quiet --container && _TGET_CNTR="true"
#	fi
#	if command -v ischroot > /dev/null 2>&1; then
#		ischroot --default-true && _TGET_CHRT="true"
#	fi
#	readonly _TGET_VIRT
#	readonly _TGET_CHRT
#	readonly _TGET_CNTR
#	fnDbgout "system parameter" \
#		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
#		"info,_TGET_CHRT=[${_TGET_CHRT:-}]" \
#		"info,_TGET_CNTR=[${_TGET_CNTR:-}]"

#	_DIRS_TGET=""
#	for __DIRS in \
#		/target \
#		/mnt/sysimage \
#		/mnt/
#	do
#		[[ ! -e "${__DIRS}"/root/. ]] && continue
#		_DIRS_TGET="${__DIRS}"
#		break
#	done
#	readonly _DIRS_TGET

	# --- samba ---------------------------------------------------------------
#	_SHEL_NLIN="$(fnFind_command 'nologin' | sort -r | head -n 1)"
#	_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
#	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /usr/sbin/nologin ]]; then echo "/usr/sbin/nologin"; fi)"}"
#	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /sbin/nologin     ]]; then echo "/sbin/nologin"; fi)"}"
#	readonly _SHEL_NLIN

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

	# --- create temporary directory ------------------------------------------
#	declare       _DIRS_RTMP=""			# remote
	              _DIRS_RTMP="$(mktemp -qd "${_DIRS_PVAT:?}/wrk/mkosi.XXXXXX")"
	readonly      _DIRS_RTMP
	              _LIST_RMOV+=("${_DIRS_RTMP:?}")			# temporary

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
	declare -a    __OPTN=()
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
#	https://man.archlinux.org/man/xorrisofs.1.en
#	-quiet								Run quietly
#	-o FILE, -output FILE				Set output file name
#	-R, -rock							Generate Rock Ridge directory information
#	-J, -joliet							Generate Joliet directory information
#	-V ID, -volid ID					Set Volume ID
#	-iso-level number					Specify the ISO 9660 version which defines the limitations of file naming and data file size
#	--grub2-mbr FILE					Set GRUB2 MBR for boot image address patching
#	-partition_offset LBA				Make image mountable by first partition, too
#	-appended_part_as_gpt				mark appended partitions in GPT instead of MBR.
#	-append_partition NUMBER TYPE FILE	Append FILE after image. TYPE is hex: 0x.. or a GUID to be used if -appended_part_as_gpt.
#	-iso_mbr_part_type					Set type byte or GUID of ISO partition in MBR or type GUID if a GPT ISO partition emerges.
#	-c FILE, -eltorito-catalog FILE		Set El Torito boot catalog name
#	--boot-catalog-hide					Hide boot catalog from ISO9660/RR and Joliet
#	-b FILE, -eltorito-boot FILE		Set El Torito boot image name
#	-no-emul-boot						Boot image is 'no emulation' image
#	-boot-load-size #					Set numbers of load sectors
#	-boot-info-table					Patch boot image with info table
#	--grub2-boot-info					Patch boot image at byte 2548
#	-eltorito-alt-boot					Start specifying alternative El Torito boot parameters
#	-e FILE								Set EFI boot image name (more rawly)
#	-graft-points						Allow to use graft points for filenames

#	-isohybrid-mbr FILE										Set SYSLINUX mbr/isohdp[fp]x*.bin for isohybrid
#	-isohybrid-gpt-basdat									Mark El Torito boot image as Basic Data in GPT
#	-isohybrid-apm-hfsplus									Mark El Torito boot image as HFS+ in APM
#	-part_like_isohybrid									Mark in MBR, GPT, APM without -isohybrid-mbr
#	-efi-boot-part DISKFILE|--efi-boot-image				Set data source for EFI System Partition
	__OPTN=()
	__OPTN+=(
		-quiet
		-rock
		-joliet
		${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"}
		-iso-level 3
	)
	if [[ -n "${__FILE_HBRD:-}" ]]; then
		__OPTN+=(
			${__FILE_HBRD:+-isohybrid-mbr "${__FILE_HBRD}"}
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
		)
	else
		__OPTN+=(
			${__FILE_BIOS:+--grub2-mbr "${__FILE_BIOS}"}
			-partition_offset 16
			-appended_part_as_gpt
			-append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "${__FILE_UEFI}"
			-iso_mbr_part_type EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
		)
	fi
	__OPTN+=(
		${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"}
		--boot-catalog-hide
		${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}" -no-emul-boot}
		-boot-load-size 4
		-boot-info-table
		-eltorito-alt-boot
	)
	if [[ -n "${__FILE_HBRD:-}" ]]; then __OPTN+=(-e "${__FILE_UEFI}" -no-emul-boot)
	else                                 __OPTN+=(-e '--interval:appended_partition_2:all::' -no-emul-boot)
	fi
	__OPTN+=(
		-output "${__TEMP}"
		"${__DIRS_TGET:?}"
	)
	readonly      __OPTN
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "create iso image file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	[[ -n "${__FILE_HBRD:-}" ]] && echo "hybrid mode"
	[[ -n "${__FILE_BIOS:-}" ]] && echo "eltorito mode"
#	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! xorrisofs "${__OPTN[@]}"; then
			__RTCD="$?"
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorrisofs]" "${__FILE_ISOS##*/}" 1>&2
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorrisofs]" "xorrisofs ${__OPTN[*]}" 1>&2
			printf "%s\n" "xorrisofs: ${__RTCD:-}"
			exit "${__RTCD:-}"
		else
			if ! cp --preserve=timestamps "${__TEMP}" "${__FILE_ISOS}"; then
				__RTCD="$?"
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${__FILE_ISOS##*/}" 1>&2
				printf "%s\n" "cp: ${__RTCD:-}"
				exit "${__RTCD:-}"
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
#	popd > /dev/null || exit
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
# descript: find code name
#   input :     $1     : distribution
#   input :     $2     : release version number
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
function fnFind_codename() {
	declare -r    __TGET_DIST="${1:?}"	# distribution
	declare -r    __TGET_VERS="${2:?}"	# release version number
	declare       __DIST=""				# distribution
	declare       __VERS=""				# release version number
	declare       __CODE=""				# code name
	declare -r -a __LIST=(
		"name                    version_id              code_name                               life            release         support         long_term       "
		"Debian                  1.1                     Buzz                                    EOL             1996-06-17      -               -               "
		"Debian                  1.2                     Rex                                     EOL             1996-12-12      -               -               "
		"Debian                  1.3                     Bo                                      EOL             1997-06-05      -               -               "
		"Debian                  2.0                     Hamm                                    EOL             1998-07-24      -               -               "
		"Debian                  2.1                     Slink                                   EOL             1999-03-09      2000-10-30      -               "
		"Debian                  2.2                     Potato                                  EOL             2000-08-15      2003-06-30      -               "
		"Debian                  3.0                     Woody                                   EOL             2002-07-19      2006-06-30      -               "
		"Debian                  3.1                     Sarge                                   EOL             2005-06-06      2008-03-31      -               "
		"Debian                  4.0                     Etch                                    EOL             2007-04-08      2010-02-15      -               "
		"Debian                  5.0                     Lenny                                   EOL             2009-02-14      2012-02-06      -               "
		"Debian                  6.0                     Squeeze                                 EOL             2011-02-06      2014-05-31      2016-02-29      "
		"Debian                  7.0                     Wheezy                                  EOL             2013-05-04      2016-04-25      2018-05-31      "
		"Debian                  8.0                     Jessie                                  EOL             2015-04-25      2018-06-17      2020-06-30      "
		"Debian                  9.0                     Stretch                                 EOL             2017-06-17      2020-07-18      2022-06-30      "
		"Debian                  10.0                    Buster                                  EOL             2019-07-06      2022-09-10      2024-06-30      "
		"Debian                  11.0                    Bullseye                                LTS             2021-08-14      2024-08-15      2026-08-31      "
		"Debian                  12.0                    Bookworm                                -               2023-06-10      2026-06-10      2028-06-30      "
		"Debian                  13.0                    Trixie                                  -               2025-08-09      2028-08-09      2030-06-30      "
		"Debian                  14.0                    Forky                                   -               2027-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  15.0                    Duke                                    -               2029-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  testing                 Testing                                 -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  sid                     SID                                     -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Ubuntu                  4.10                    Warty%20Warthog                         EOL             2004-10-20      2006-04-30      -               "
		"Ubuntu                  5.04                    Hoary%20Hedgehog                        EOL             2005-04-08      2006-10-31      -               "
		"Ubuntu                  5.10                    Breezy%20Badger                         EOL             2005-10-12      2007-04-13      -               "
		"Ubuntu                  6.06                    Dapper%20Drake                          EOL             2006-06-01      2009-07-14      2011-06-01      "
		"Ubuntu                  6.10                    Edgy%20Eft                              EOL             2006-10-26      2008-04-25      -               "
		"Ubuntu                  7.04                    Feisty%20Fawn                           EOL             2007-04-19      2008-10-19      -               "
		"Ubuntu                  7.10                    Gutsy%20Gibbon                          EOL             2007-10-18      2009-04-18      -               "
		"Ubuntu                  8.04                    Hardy%20Heron                           EOL             2008-04-24      2011-05-12      2013-05-09      "
		"Ubuntu                  8.10                    Intrepid%20Ibex                         EOL             2008-10-30      2010-04-30      -               "
		"Ubuntu                  9.04                    Jaunty%20Jackalope                      EOL             2009-04-23      2010-10-23      -               "
		"Ubuntu                  9.10                    Karmic%20Koala                          EOL             2009-10-29      2011-04-30      -               "
		"Ubuntu                  10.04                   Lucid%20Lynx                            EOL             2010-04-29      2013-05-09      2015-04-30      "
		"Ubuntu                  10.10                   Maverick%20Meerkat                      EOL             2010-10-10      2012-04-10      -               "
		"Ubuntu                  11.04                   Natty%20Narwhal                         EOL             2011-04-28      2012-10-28      -               "
		"Ubuntu                  11.10                   Oneiric%20Ocelot                        EOL             2011-10-13      2013-05-09      -               "
		"Ubuntu                  12.04                   Precise%20Pangolin                      EOL             2012-04-26      2017-04-28      2019-04-26      "
		"Ubuntu                  12.10                   Quantal%20Quetzal                       EOL             2012-10-18      2014-05-16      -               "
		"Ubuntu                  13.04                   Raring%20Ringtail                       EOL             2013-04-25      2014-01-27      -               "
		"Ubuntu                  13.10                   Saucy%20Salamander                      EOL             2013-10-17      2014-07-17      -               "
		"Ubuntu                  14.04                   Trusty%20Tahr                           EOL             2014-04-17      2019-04-25      2024-04-25      "
		"Ubuntu                  14.10                   Utopic%20Unicorn                        EOL             2014-10-23      2015-07-23      -               "
		"Ubuntu                  15.04                   Vivid%20Vervet                          EOL             2015-04-23      2016-02-04      -               "
		"Ubuntu                  15.10                   Wily%20Werewolf                         EOL             2015-10-22      2016-07-28      -               "
		"Ubuntu                  16.04                   Xenial%20Xerus                          LTS             2016-04-21      2021-04-30      2026-04-23      "
		"Ubuntu                  16.10                   Yakkety%20Yak                           EOL             2016-10-13      2017-07-20      -               "
		"Ubuntu                  17.04                   Zesty%20Zapus                           EOL             2017-04-13      2018-01-13      -               "
		"Ubuntu                  17.10                   Artful%20Aardvark                       EOL             2017-10-19      2018-07-19      -               "
		"Ubuntu                  18.04                   Bionic%20Beaver                         LTS             2018-04-26      2023-05-31      2028-04-26      "
		"Ubuntu                  18.10                   Cosmic%20Cuttlefish                     EOL             2018-10-18      2019-07-18      -               "
		"Ubuntu                  19.04                   Disco%20Dingo                           EOL             2019-04-18      2020-01-23      -               "
		"Ubuntu                  19.10                   Eoan%20Ermine                           EOL             2019-10-17      2020-07-17      -               "
		"Ubuntu                  20.04                   Focal%20Fossa                           LTS             2020-04-23      2025-05-29      2030-04-23      "
		"Ubuntu                  20.10                   Groovy%20Gorilla                        EOL             2020-10-22      2021-07-22      -               "
		"Ubuntu                  21.04                   Hirsute%20Hippo                         EOL             2021-04-22      2022-01-20      -               "
		"Ubuntu                  21.10                   Impish%20Indri                          EOL             2021-10-14      2022-07-14      -               "
		"Ubuntu                  22.04                   Jammy%20Jellyfish                       -               2022-04-21      2027-06-01      2032-04-21      "
		"Ubuntu                  22.10                   Kinetic%20Kudu                          EOL             2022-10-20      2023-07-20      -               "
		"Ubuntu                  23.04                   Lunar%20Lobster                         EOL             2023-04-20      2024-01-25      -               "
		"Ubuntu                  23.10                   Mantic%20Minotaur                       EOL             2023-10-12      2024-07-11      -               "
		"Ubuntu                  24.04                   Noble%20Numbat                          -               2024-04-25      2029-05-31      2034-04-25      "
		"Ubuntu                  24.10                   Oracular%20Oriole                       EOL             2024-10-10      2025-07-10      -               "
		"Ubuntu                  25.04                   Plucky%20Puffin                         -               2025-04-17      2026-01-15      -               "
		"Ubuntu                  25.10                   Questing%20Quokka                       -               2025-10-09      2026-07-09      -               "
		"Ubuntu                  26.04                   Resolute%20Raccoon                      -               2026-04-23      2031-05-29      2036-04-23      "
	)

	__DIST="${__TGET_DIST,,}"
	__VERS="${__TGET_VERS,,}"

	case "${__DIST}-${__VERS}" in
#		debian-11.0         | \
		debian-12.0         | \
		debian-13.0         | \
		debian-14.0         | \
		debian-15.0         | \
		debian-testing      | \
		debian-sid          ) ;;
#		debian-experimental ) ;;
#		ubuntu-16.04        | \
#		ubuntu-18.04        | \
#		ubuntu-20.04        | \
#		ubuntu-22.04        | \
		ubuntu-24.04        | \
		ubuntu-25.04        | \
		ubuntu-25.10        | \
		ubuntu-26.04        ) ;;
#		rhel-*              ) ;;
		fedora-43           | \
		fedora-44           ) ;;
#		centos-8            | \
		centos-9            | \
		centos-10           ) ;;
#		alma-8              | \
		alma-9              | \
		alma-10             ) ;;
#		rocky-8             | \
		rocky-9             | \
		rocky-10            ) ;;
		opensuse-*          ) ;;
		*) echo "not supported: ${__DIST}-${__VERS}"; exit 1;;
	esac
	case "${__DIST}" in
		debian | \
		ubuntu )
			for I in "${!__LIST[@]}"
			do
				read -r -a __LINE < <(echo "${__LIST[I]}")
				[[ "${__LINE[0],,}"  != "${__DIST}" ]] && continue
				[[ "${__LINE[1],,}"  != "${__VERS}" ]] && continue
				__CODE="${__LINE[2],,}"
				__CODE="${__CODE%%\%20*}"
				break
			done
			;;
		*) ;;
	esac
	echo "${__CODE:-}"
}

# -----------------------------------------------------------------------------
# descript: find distribution
#   input :     $1     : distribution
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
function fnFind_distribution() {
	declare -r    __TGET_DIST="${1:?}"	# distribution
	declare       __DIST=""				# distribution

	case "${__TGET_DIST,,}" in
		debian  ) __DIST="Debian";;
		ubuntu  ) __DIST="Ubuntu";;
		fedora  ) __DIST="Fedora";;
		centos  ) __DIST="CentOS-Stream";;
		alma    ) __DIST="AlmaLinux";;
		rocky   ) __DIST="Rocky";;
		opensuse) __DIST="openSUSE";;
#		miracle ) __DIST="MIRACLE-LINUX";;
		*       ) __DIST="${__TGET_DIST,,}";;
	esac
	echo "${__DIST}"
}

# -----------------------------------------------------------------------------
# descript: find kernel
#   input :     $1     : target directory
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
function fnFind_kernel() {
	declare -r    __TGET_DIRS="${1:?}"	# target directory
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	           __VLNZ="$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'vmlinuz-*'    -o -name 'linux-*'         \) -print -quit)"
	__VLNZ="${__VLNZ:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'vmlinuz'      -o -name 'linux'           \) -print -quit)"}"
	           __IRAM="$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*.img' -o -name 'initramfs-*.img' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd.img-*' -o -name 'initramfs.img-*' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd.img'   -o -name 'initramfs.img'   \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd'       -o -name 'initramfs'       \) -print -quit)"}"
	__VLNZ="${__VLNZ#"${__TGET_DIRS}"/}"
	__IRAM="${__IRAM#"${__TGET_DIRS}"/}"
	printf "%s %s" "${__VLNZ:-"-"}" "${__IRAM:-"-"}"
}

# -----------------------------------------------------------------------------
# descript: make mkosi files
#   input :     $@     : parameter
#   output:   stdout   : message
#   return:            : unused
# memo    :
#   https://github.com/systemd/mkosi

function fnMk_mkosi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __OPTN=("${@:-}")
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "create mkosi file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	if ! nice -n 19 mkosi "${__OPTN[@]}"; then
		__RTCD="$?"
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [mkosi]" "mkosi ${__OPTN[*]}" 1>&2
		printf "%s\n" "mkosi: ${__RTCD:-}"
		exit "${__RTCD:-}"
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
# descript: execute qemu
#   input :     $@     : parameter
#   output:   stdout   : message
#   return:            : unused
function fnMk_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __OPTN=("${@:-}")
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __COMD=""				# command
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "execute qemu ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	  if command -v qemu-system-x86_64 > /dev/null 2>&1; then __COMD="qemu-system-x86_64"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	if ! nice -n 19 "${__COMD:?}" "${__OPTN[@]}"; then
		__RTCD="$?"
#		echo -e "\x12\x1bc"
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [qemu]" "${__COMD} ${__OPTN[*]}" 1>&2
		printf "%s\n" "${__COMD}: ${__RTCD:-}"
		exit "${__RTCD:-}"
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
		-xattrs
		-e /.autorelabel /.cache /.viminfo
	)

	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "create squashfs file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	mkdir -p "${__FILE_SQFS%/*}"
	if ! nice -n 19 mksquashfs "${__OPTN[@]}"; then
		__RTCD="$?"
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [mksquashfs]" "mksquashfs ${__OPTN[*]}" 1>&2
		printf "%s\n" "mksquashfs: ${__RTCD:-}"
		exit "${__RTCD:-}"
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
# descript: grub conf install
#   input :     $1     : target path
#   input :     $2     : main menu
#   input :     $3     : theme file
#   input :     $4     : timeout (sec)
#   input :     $5     : resolution (widht x hight)
#   input :     $6     : colors
#   output:   stdout   : message
#   return:            : unused
function fnGrub_conf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_MAIN="${2:?}"	# main menu
	declare -r    __MENU_THME="${3:-}"	# theme file
	declare -r    __MENU_TOUT="${4:-}"	# timeout (sec)
	declare -r    __MENU_RESO="${5:-}"	# resolution (widht x hight)
	declare -r    __MENU_DPTH="${6:-}"	# colors

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		set default="0"
		set timeout="${__MENU_TOUT:-5}"

		if [ "x\${font}" = "x" ] ; then
		  if [ "x\${feature_default_font_path}" = "xy" ] ; then
		    font="unicode"
		  else
		    font="\${prefix}/fonts/font.pf2"
		  fi
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=${__MENU_RESO:+"${__MENU_RESO}${__MENU_RESO:+"x${__MENU_DPTH}"},"}auto
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

		set timeout_style=menu
		set color_normal=light-gray/black
		set color_highlight=white/dark-gray
		export color_normal
		export color_highlight

		set theme=${__MENU_THME:-}
		export theme

		#insmod play
		#play 960 440 1 0 4 440 1

		source ${__MENU_MAIN:?}

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
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: grub theme install
#   input :     $1     : target path
#   input :     $2     : menu title
#   input :     $3     : splash.png
#   output:   stdout   : message
#   return:            : unused
function fnGrub_theme() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_TITL="${2:?}"	# menu title
	declare -r    __TGET_SPLS="${3:-}"	# splash.png

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		${__TGET_SPLS:+"desktop-image: \"${__TGET_SPLS}\""}
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		${__MENU_TITL:+"title-text: \"Boot Menu: ${__MENU_TITL}\""}
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
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: isolinux conf install
#   input :     $1     : target path
#   input :     $2     : main menu
#   input :     $3     : theme file
#   input :     $4     : timeout (sec)
#   input :     $5     : resolution (widht x hight)
#   input :     $6     : colors
#   output:   stdout   : message
#   return:            : unused
function fnIlnx_conf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_MAIN="${2:?}"	# main menu
	declare -r    __MENU_THME="${3:-}"	# theme file
	declare -r    __MENU_TOUT="${4:-}"	# timeout (sec)

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		path ./
		prompt 0
		#timeout 0
		default vesamenu.c32

		include ${__MENU_THME:?}

		timeout ${__MENU_TOUT:-5}0
		#default auto-install

		include ${__MENU_MAIN:?}
_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: isolinux theme install
#   input :     $1     : target path
#   input :     $2     : menu title
#   input :     $3     : splash.png
#   output:   stdout   : message
#   return:            : unused
function fnIlnx_theme() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_TITL="${2:?}"	# menu title
	declare -r    __TGET_SPLS="${3:-}"	# splash.png

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		menu clear
		${__TGET_SPLS:+"menu background ${__TGET_SPLS}"}
		${__MENU_TITL:+"menu title Boot Menu: ${__MENU_TITL}"}

		# MENU COLOR <Item>  <ANSI Seq.> <foreground> <background> <shadow type>
		menu color   screen       *       #80ffffff    #00000000         *       # background colour not covered by the splash image
		menu color   border       *       #ffffffff    #ee000000         *       # The wire-frame border
		menu color   title        *       #ffff3f7f    #ee000000         *       # Menu title text
		menu color   sel          *       #ff00dfdf    #ee000000         *       # Selected menu option
		menu color   hotsel       *       #ff7f7fff    #ee000000         *       # The selected hotkey (set with ^ in MENU LABEL)
		menu color   unsel        *       #ffffffff    #ee000000         *       # Unselected menu options
		menu color   hotkey       *       #ff7f7fff    #ee000000         *       # Unselected hotkeys (set with ^ in MENU LABEL)
		menu color   tabmsg       *       #c07f7fff    #00000000         *       # Tab text
		menu color   timeout_msg  *       #8000dfdf    #00000000         *       # Timout text
		menu color   timeout      *       #c0ff3f7f    #00000000         *       # Timout counter
		menu color   disabled     *       #807f7f7f    #ee000000         *       # Disabled menu options, including SEPARATORs
		menu color   cmdmark      *       #c000ffff    #ee000000         *       # Command line marker - The '> ' on the left when editing an option
		menu color   cmdline      *       #c0ffffff    #ee000000         *       # Command line - The text being edited
		menu color   scrollbar    *       #40000000    #00000000         *       # Scroll bar
		menu color   pwdborder    *       #80ffffff    #20ffffff         *       # Password box wire-frame border
		menu color   pwdheader    *       #80ff8080    #20ffffff         *       # Password box header
		menu color   pwdentry     *       #80ffffff    #20ffffff         *       # Password entry field
		menu color   help         *       #c0ffffff    #00000000         *       # Help text, if set via 'TEXT HELP ... ENDTEXT'

		menu margin               2
		menu vshift               3
		menu rows                12
		menu tabmsgrow           28
		menu cmdlinerow          20
		menu timeoutrow          26
		menu helpmsgrow          22
		menu hekomsgendrow       38

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make preconfiguration files
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_preconf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __CONF=""
	declare       __CODE=""
	declare       __VERS=""
	declare       __DIST=""
	declare       __EDTN=""
	declare       __PATH=""
	declare       __SRVR=""
	declare       __DTOP=""

	for __CONF in "${_DIRS_MKOS:?}"/_template/mkosi.*.conf
	do
		sed -ne '/^\[Match\]/,/^#*\[.\+\]/ {' -e '/^#*Distribution=/{' -e 's/^.*[^[:alnum:]]//p}}' "${__CONF}" | while read -r __DIST
		do
			sed -ne '/^\[Match\]/,/^#*\[.\+\]/ {' -e '/^#Release=/{' -e 's/^.*[^[:alnum:].]//p}}' "${__CONF}" | while read -r __CODE
			do
				case "${__CODE}" in
					bullseye    ) __VERS="11.0.${__CODE}";;		# debian
					bookworm    ) __VERS="12.0.${__CODE}";;
					trixie      ) __VERS="13.0.${__CODE}";;
					forky       ) __VERS="14.0.${__CODE}";;
					duke        ) __VERS="15.0.${__CODE}";;
					testing     ) __VERS="xx.x.${__CODE}";;
					sid         ) __VERS="xx.x.${__CODE}";;
					experimental) __VERS="xx.x.${__CODE}";;
					xenial      ) __VERS="16.04.${__CODE}";;	# ubuntu
					bionic      ) __VERS="18.04.${__CODE}";;
					focal       ) __VERS="20.04.${__CODE}";;
					jammy       ) __VERS="22.04.${__CODE}";;
					noble       ) __VERS="24.04.${__CODE}";;
					plucky      ) __VERS="25.04.${__CODE}";;
					questing    ) __VERS="25.10.${__CODE}";;
					resolute    ) __VERS="26.04.${__CODE}";;
					F*          ) if [[ "${__DIST}" != "fedora" ]]; then continue; fi; __VERS="${__CODE#F}";;	# fedora
					*           ) if [[ "${__DIST}" =  "fedora" ]]; then continue; fi; __VERS="${__CODE}"  ;;	# rhel, opensuse
				esac
				__EDTN=":__EDITION__:"
				__PATH="${_DIRS_MKOS:?}/mkosi.conf.d/mkosi.${__DIST:?}.${__VERS:?}.${__EDTN:?}.conf"
				__SRVR="${__PATH//${__EDTN}/server}"
				__DTOP="${__PATH//${__EDTN}/desktop}"
				# --- server ------------------------------------------------------
				echo "create: ${__SRVR}"
				sed -e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
					-e '/^Distribution=/                           s/^/#/' \
					-e '/^#*Distribution=|*'"${__DIST}"'/          s/^#//' \
					-e '/^Release=/                                s/^/#/' \
					-e '/^#*Release=|*'"${__CODE}"'/               s/^#//' \
					-e '/^Environment=/                                 {' \
					-e 's/!\(EDITION=desktop\)/\1/                       ' \
					-e 's/\(EDITION=desktop\)/!\1/                       ' \
					-e '}}'                                                \
				"${__CONF}"                                                \
				> "${__SRVR}"
				case "${__DIST:?}.${__VERS:?}" in
					debian.11.0.*)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Distribution\]/,/^#*\[.\+\]/                {' \
							-e '/^Repositories=/ s/,*non-free-firmware//         ' \
							-e '}'                                                 \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *dhcpcd-base */                        s/^ /#/' \
							-e '/^ *systemd-boot */                       s/^ /#/' \
							-e '/^ *systemd-boot-efi */                   s/^ /#/' \
							-e '/^ *systemd-resolved */                   s/^ /#/' \
							-e '/^ *ubuntu-keyring */                     s/^ /#/' \
							-e '/^ *util-linux-extra */                   s/^ /#/' \
							-e '}}'
						;;
					ubuntu.22.04.*)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *dhcpcd-base */                        s/^ /#/' \
							-e '/^ *systemd-boot */                       s/^ /#/' \
							-e '/^ *systemd-boot-efi */                   s/^ /#/' \
							-e '/^ *systemd-resolved */                   s/^ /#/' \
							-e '/^ *ubuntu-keyring */                     s/^ /#/' \
							-e '/^ *util-linux-extra */                   s/^ /#/' \
							-e '}}'
						;;
					fedora.*)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
							-e '/^Release=/ s/[^=]\+$/'"${__CODE#F}"'/           ' \
							-e '}'                                                 \
							-e '/^\[Distribution\]/,/^#*\[.\+\]/                {' \
							-e '/^Repositories=epel$/                      s/^/#/' \
							-e '}'                                                 \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *epel-release */                       s/^ /#/' \
							-e '/^ *kpatch */                             s/^ /#/' \
							-e '/^ *kpatch-dnf */                         s/^ /#/' \
							-e '/^ *systemd-timesyncd */                  s/^ /#/' \
							-e '}}'
						;;
					centos.9 | \
					alma.9   | \
					rocky.9)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *amd-ucode-firmware */                 s/^ /#/' \
							-e '/^ *google-noto-sans-cjk-vf-fonts */      s/^ /#/' \
							-e '/^ *google-noto-sans-mono-cjk-vf-fonts */ s/^ /#/' \
							-e '/^ *google-noto-serif-cjk-vf-fonts */     s/^ /#/' \
							-e '/^ *iwlwifi-dvm-firmware */               s/^ /#/' \
							-e '/^ *iwlwifi-mvm-firmware */               s/^ /#/' \
							-e '/^ *plocate */                            s/^ /#/' \
							-e '/^ *realtek-firmware */                   s/^ /#/' \
							-e '/^ *vim-data */                           s/^ /#/' \
							-e '/^ *xxd */                                s/^ /#/' \
							-e '}}'
						;;
					opensuse.15.6)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *selinux-policy */                     s/^ /#/' \
							-e '/^ *policycoreutils */                    s/^ /#/' \
							-e '/^ *libsemanage2 */                       s/^ /#/' \
							-e '/^ *dbus-1-daemon */                      s/^ /#/' \
							-e '}}'
						;;
					opensuse.*)
						sed -i "${__SRVR}"                                         \
							-e '/^\[Distribution\]/,/^#*\[.\+\]/                {' \
							-e '/^Repositories=.*$/                        s/^/#/' \
							-e '}'                                                 \
							-e '/^\[Build\]/,/^#*\[.\+\]/                       {' \
							-e '/^SandboxTrees=.*$/                        s/^/#/' \
							-e '}'
						;;
					*) ;;
				esac
				# --- desktop -----------------------------------------------------
				echo "create: ${__DTOP}"
				sed -e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
					-e '/^Environment=/                                 {' \
					-e 's/!\(EDITION=desktop\)/\1/                       ' \
					-e '}}'                                                \
					-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					-e '/^# \+-\+ desktop .*$/,/^# \+-\+.*$/            {' \
					-e '/^# \+[@[:alnum:]]\+/                    s/^#/ /g' \
					-e '}}}'                                               \
				"${__SRVR}"                                                \
				> "${__DTOP}"
				case "${__DIST:?}.${__VERS:?}" in
					debian.11.0.*)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *adwaita-icon-theme-legacy */          s/^ /#/' \
							-e '/^ *gnome-classic */                      s/^ /#/' \
							-e '/^ *gnome-classic-xsession */             s/^ /#/' \
							-e '/^ *fcitx5-anthy */                       s/^ /#/' \
							-e '/^ *gnome-shell-extension-manager */      s/^ /#/' \
							-e '/^ *vlc-plugin-pipewire */                s/^ /#/' \
							-e '}}'
						;;
					debian.12.0.*)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *adwaita-icon-theme-legacy */          s/^ /#/' \
							-e '/^ *gnome-classic */                      s/^ /#/' \
							-e '/^ *gnome-classic-xsession */             s/^ /#/' \
							-e '}}'
						;;
					debian.13.0.*)
						;;
					debian.14.0.* | \
					debian.15.0.* | \
					debian.xx.x.*)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *gnome-classic-xsession */             s/^ /#/' \
							-e '/^ *fcitx5-mozc */                        s/^ /#/' \
							-e '/^ *mozc-utils-gui */                     s/^ /#/' \
							-e '}}'
						;;
					ubuntu.22.04.*)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *vlc-plugin-pipewire */                s/^ /#/' \
							-e '}}'
						;;
					ubuntu.26.04.*)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *fcitx5-mozc */                        s/^ /#/' \
							-e '/^ *mozc-utils-gui */                     s/^ /#/' \
							-e '}}'
						;;
					centos.9 | \
					alma.9   | \
					rocky.9)
						sed -i "${__DTOP}"                                         \
							-e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
							-e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
							-e '/^ *google-noto-sans-cjk-vf-fonts */      s/^ /#/' \
							-e '/^ *google-noto-sans-mono-cjk-vf-fonts */ s/^ /#/' \
							-e '/^ *google-noto-serif-cjk-vf-fonts */     s/^ /#/' \
							-e '/^ *realtek-firmware */                   s/^ /#/' \
							-e '/^ *gnome-initial-setup */                s/^ /#/' \
							-e '}}'
						;;
					*) ;;
				esac
			done
		done
	done
	chown sambauser "${_DIRS_MKOS:?}"/mkosi.conf.d/*.conf
	chmod g+w "${_DIRS_MKOS:?}"/mkosi.conf.d/*.conf
	unset __DTOP __SRVR __PATH __EDTN __DIST __VERS __CODE __CONF

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: mkosi build live media
#   input :     $1     : operation
#   input :     $2     : distribution
#   input :     $3     : version
#   input :     $4     : edition
#   input :     $5     : workspace directory
#   input :     $6     : output directory
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_mkosi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OPRT="${1:-}"	# operation
	declare -r    __TGET_DIST="${2:-}"	# distribution
	declare -r    __TGET_VERS="${3:-}"	# version
	declare -r    __TGET_EDTN="${4:-}"	# edition
	declare -r    __TGET_WRKD="${5:-}"	# --workspace-directory=
	declare -r    __TGET_OUTD="${6:-}"	# --output-directory=
	declare       __HOST=""				# --hostname=
	declare -a    __OPTN=()				# command
	declare -r    __BOOT="${_MKOS_BOOT:-}"
	declare -r    __OUTP="${_MKOS_OUTP:-}"
	declare -r    __FMAT="${_MKOS_FMAT:-}"
	declare -r    __NWRK="${_MKOS_NWRK:-}"
	declare -r    __RECM="${_MKOS_RECM:-}"
	declare -r    __ARCH="${_MKOS_ARCH:-}"
	declare -r    __MKOS="${_DIRS_MKOS:-}"
	declare -r    __DIST="${__TGET_DIST:-}"
	declare -r    __VERS="${__TGET_VERS:-}"
	declare -r    __EDTN="${__TGET_EDTN:-}"
	declare -r    __WRKD="${__TGET_WRKD:-}"
	declare -r    __OUTD="${__TGET_OUTD:-}"
	declare -r    __CACH=""
	# --- --hostname= ---------------------------------------------------------
	__HOST="$(fnFind_distribution "${__DIST}")"
	__HOST="${__HOST:+"sv-${__HOST}.workgroup"}"
	__HOST="${__HOST,,}"
	# --- command -------------------------------------------------------------
	__OPTN=(
		${__BOOT:+--bootable="${__BOOT}"}
		${__OUTP:+--output="${__OUTP}"}
		${__FMAT:+--format="${__FMAT}"}
		${__NWRK:+--with-network="${__NWRK}"}
		${__RECM:+--with-recommends="${__RECM}"}
		${__DIST:+--distribution="${__DIST}"}
		${__VERS:+--release="${__VERS}"}
		${__ARCH:+--architecture="${__ARCH//_/-}"}
		${__MKOS:+--directory="${__MKOS}"}
		${__WRKD:+--workspace-directory="${__WRKD}"}
		${__CACH:+--package-cache-dir="${__CACH}"}
		${__OUTD:+--output-directory="${__OUTD}"}
		${__EDTN:+--environment=EDITION="${__EDTN}"}
		${__HOST:+--hostname="${__HOST}"}
	)
	case "${__OPRT:-}" in
#		init         ) __OPTN=("${__OPRT}");;
		summary      ) __OPTN+=(--no-pager summary);;
#		cat-config   ) __OPTN=("${__OPRT}");;
		build        ) __OPTN+=(--force --wipe-build-dir build);;
#		shell        ) __OPTN=("${__OPRT}");;
#		boot         ) __OPTN=("${__OPRT}");;
#		vm           ) __OPTN=("${__OPRT}");;
#		ssh          ) __OPTN=("${__OPRT}");;
#		journalctl   ) __OPTN=("${__OPRT}");;
#		coredumpctl  ) __OPTN=("${__OPRT}");;
#		sysupdate    ) __OPTN=("${__OPRT}");;
#		box          ) __OPTN=("${__OPRT}");;
#		dependencies ) __OPTN=("${__OPRT}");;
#		clean        ) __OPTN=("${__OPRT}");;
#		serve        ) __OPTN=("${__OPRT}");;
#		burn         ) __OPTN=("${__OPRT}");;
#		bump         ) __OPTN=("${__OPRT}");;
#		genkey       ) __OPTN=("${__OPRT}");;
#		documentation) __OPTN=("${__OPRT}");;
#		completion   ) __OPTN=("${__OPRT}");;
#		help         ) __OPTN=("${__OPRT}");;
		*            ) __OPTN=("help");;
	esac
#	__OPTN=("--debug" "${__OPTN[@]:-}")
	fnMk_mkosi "${__OPTN[@]}"

	unset __OPTN __HOST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live vm-image partition1
#   input :     $1     : device name
#   input :     $2     : partition
#   input :     $3     : output directory
#   input :     $4     : uuid
#   input :     $5     : distribution
#   input :     $6     : menu entry
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_vmimg_p1() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PART="${2:?}"	# partition
	declare -r    __TGET_OUTD="${3:?}"	# output directory
	declare -r    __TGET_UUID="${4:?}"	# uuid
	declare -r    __TGET_DIST="${5:?}"	# distribution
	declare -r    __TGET_ENTR="${6:?}"	# menu entry
	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/strg"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt1"			# mount point
#	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
#	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
#	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __SPLS="${__TGET_OUTD:?}/${_MENU_SPLS:?}"	# splash.png
	declare -r    __MBRF="${__OUTD:?}/${_FILE_MBRF:?}"		# mbr image
	declare -r    __UEFI="${__OUTD:?}/${_FILE_UEFI:?}"		# uefi image
	declare -r    __VLNZ="${_PATH_VLNZ:?}"					# kernel
	declare -r    __IRAM="${_PATH_IRAM:?}"					# initramfs
	declare -r    __TITL="Live system"						# title
	declare       __COMD=""									# command
	declare       __PSEC=""									# physical sector size
	declare       __STRT=""									# partition start offset (in 512-byte sectors)
	declare       __SIZE=""									# size of the device (bytes)
	declare       __CONT=""									# partition sector size (in 512-byte sectors)
	declare       __PATH=""									# work
	declare       __WORK=""									# work
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	mkdir -p "${__MNTP:?}"
	# --- install grub module -------------------------------------------------
	  if command -v grub-install  > /dev/null 2>&1; then __COMD="grub-install"
	elif command -v grub2-install > /dev/null 2>&1; then __COMD="grub2-install"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	"${__COMD:?}" \
		--target=x86_64-efi \
		--efi-directory="${__MNTP}" \
		--boot-directory="${__MNTP}/boot" \
		--bootloader-id="${__TGET_DIST,,}" \
		--removable
	"${__COMD:?}" \
		--target=i386-pc \
		--boot-directory="${__MNTP}/boot" \
		"${__TGET_DEVS}"
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# --- create uefi/bios image ----------------------------------------------
	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__TGET_DEVS:?}${__TGET_PART:?}")"
	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK:?}")
	__CONT="$(("${__SIZE:?}" / "${__PSEC:?}"))"
	dd if="${__TGET_DEVS:?}" of="${__UEFI:?}" bs="${__PSEC:?}" skip="${__STRT:?}" count="${__CONT:?}"
	dd if="${__TGET_DEVS:?}" of="${__MBRF:?}" bs=1 count=440
	# --- create grub.cfg -----------------------------------------------------
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	fnGrub_conf  "${__GCFG:?}" "${__INPD}/${_FILE_MENU:?}" "${__INPD}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "${__INPD}/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_ENTR}" {
		  set gfxpayload="keep"
		  set background_color="black"
		  set uuid="${__TGET_UUID:?}"
		  search --no-floppy --fs-uuid --set=root \${uuid}
		  echo root=\${root}
		  set devs=/dev/sda2
		  set ttys=console=ttyS0
		  set options="\${ttys} root=\${devs}${_SECU_OPTN:+" ${_SECU_OPTN}"}"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__VLNZ:?} \${options} ---
		  echo 'Loading initramfs ...'
		  initrd ${__IRAM:?}
		}
_EOT_
#	[[ -e "${__EGRU:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__MNTP:?}/EFI/BOOT/${_FILE_GCFG##*/}"
	[[ -e "${__GCFG:?}" ]] && cp --preserve=timestamps "${__GCFG:?}" "${__MNTP:?}/${__INPD:?}"
#	[[ -e "${__ICFG:?}" ]] && cp --preserve=timestamps "${__ICFG:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__SPLS:?}" ]] && cp --preserve=timestamps "${__SPLS:?}" "${__MNTP:?}/${__INPD:?}"
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# -------------------------------------------------------------------------
	unset __WORK __PATH __COMD
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live vm-image partition2
#   input :     $1     : device name
#   input :     $2     : partition
#   input :     $3     : output directory
#   input :     $4     : root image mount point
#   input :     $5     : uuid
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_vmimg_p2() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PART="${2:?}"	# partition
	declare -r    __TGET_OUTD="${3:?}"	# output directory
	declare -r    __TGET_RTFS="${4:?}"	# root image mount point
	declare -r    __TGET_UUID="${5:?}"	# uuid
#	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/strg"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt2"			# mount point
#	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
#	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
#	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
#	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
#	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
#	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
#	declare -r    __SPLS="${__OUTD:?}/${_MENU_SPLS:?}"		# splash.png
#	declare -r    __TITL="Live system"						# title
#	declare       __COMD=""									# command
	declare       __FSTB=""									# work
	declare       __SRCS=""									# work
	declare       __DEST=""									# work
	declare       __SRVC=""									# work
	declare       __TGET=""									# work
#	declare       __WORK=""									# work
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	mkdir -p "${__MNTP:?}"
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	# --- root files ----------------------------------------------------------
#	cp --preserve=mode,ownership,timestamps,links,xattr --no-preserve --recursive "${__TGET_RTFS}"/. "${__MNTP}"
	cp --no-dereference --recursive --preserve=all --no-preserve=context "${__TGET_RTFS}"/. "${__MNTP}"
	# --- /etc/fstab ----------------------------------------------------------
	__FSTB="/etc/fstab"
	__SRCS="${__OUTD:?}/${__FSTB##*/}"
	__DEST="${__MNTP:?}/${__FSTB#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	{
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "# <file system>"  "<mount point>" "<type>"           "<options>"                   "<dump>" "<pass>"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "UUID=${__UUID:?}" "/"             "ext4"             "defaults"                    "0"      "0"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "#.host:/"         "/srv/hgfs"     "fuse.vmhgfs-fuse" "nofail,allow_other,defaults" "0"      "0"
	} > "${__SRCS:?}"
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	# --- run-once.sh ---------------------------------------------------------
	__SRVC="/etc/systemd/system/run-once.service"
	__ADMN="/var/admin/autoinst"
	__TGET="${__ADMN:?}/run-once.sh"
	__SRCS="${__OUTD:?}/${__TGET##*/}"
	__DEST="${__MNTP:?}/${__TGET#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		#!/bin/bash
		set -eu
		declare -r    _PROG_PATH="\$0"
		declare -r    _PROG_NAME="\${_PROG_PATH##*/}"
		declare -r    __ADMN="${__ADMN:?}"
		declare -r    __STAT="\${__ADMN:?}/\${_PROG_NAME}.success"
		declare -r    __SRVC="${__SRVC:?}"
		declare -r    __FSTB="${__FSTB:?}"
		declare -r -a __LIST=(
		 	"/usr/bin/thunderbird       thunderbird"
		 	"/usr/bin/firefox           firefox"
		 	"/usr/bin/chromium-browser  chromium"
		)
		declare       __PATH=""
		declare       __PACK=""
		declare -i    I=0
		{
		 	printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "\$(date +"%Y/%m/%d %H:%M:%S" || true)"
		#	touch /.autorelabel
		 	if command -v /usr/bin/snap > /dev/null 2>&1; then
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "snap install"
		 		for I in "\${!__LIST[@]}"
		 		do
		 			read -r __PATH __PACK < <(echo "\${__LIST[I]}")
		 			[[ ! -e "\${__PATH}" ]] && continue
		 			echo "snap install \\"\${__PACK}\\""
		 			snap install "\${__PACK}"
		 		done
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "snap install"
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "snap capabilities"
		 		getcap /usr/lib/snapd/snap-confine
		 		getfattr --dump --match="^security\\." /usr/lib/snapd/snap-confine
		#		setcap -q - /usr/lib/snapd/snap-confine < /usr/lib/snapd/snap-confine.caps
		#		getcap /usr/lib/snapd/snap-confine
		#		getfattr --dump --match="^security\\." /usr/lib/snapd/snap-confine
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "snap capabilities"
		 	fi
		 	[[ -e "\${__FSTB:?}" ]] &&sed -i "\${__FSTB:?}" -e '/^UUID=/d'
		 	ls -lahZ /
		 	[[ -e "\${__SRVC:?}" ]] && systemctl disable "\${__SRVC##*/}"
		 	mkdir -p "\${__ADMN:?}"
		 	[[ -e "\${__SRVC:?}"     ]] && mv "\${__SRVC:?}" "\${__ADMN:?}"
		#	[[ -e "\${_PROG_PATH:?}" ]] && mv "\${_PROG_PATH:?}" "\${__ADMN:?}"
		 	touch "\${__STAT}"
		 	shutdown -h now
		 	printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "\$(date +"%Y/%m/%d %H:%M:%S" || true)"
		} > /dev/console 2>&1
		exit 0
_EOT_
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	[[ -e "${__DEST:?}" ]] && chmod +x "${__DEST}"
	# --- /etc/systemd/system/run-once.service --------------------------------
	__SRCS="${__OUTD:?}/${__SRVC##*/}"
	__DEST="${__MNTP:?}/${__SRVC#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		[Unit]
		Description=Run the script once after all services have started.
		After=network.target multi-user.target
		Requires=multi-user.target

		[Service]
		Type=oneshot
		ExecStart=${__TGET:?}
		RemainAfterExit=yes

		[Install]
		WantedBy=multi-user.target
_EOT_
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
#	[[ -e "${__DEST:?}" ]] && chmod +x "${__DEST}"
	# --- setup ---------------------------------------------------------------
	chroot "${__MNTP:?}" bash -c "systemctl enable ${__SRVC##*/}"
	# -------------------------------------------------------------------------
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __TGET __SRVC __DEST __SRCS __FSTB
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live vm-image
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : menu entry
#   input :     $4     : storage
#   input :     $5     : distribution
#   input :     $6     : version
#   input :     $7     : edition
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_vmimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:-}"	# output directory
	declare -r    __TGET_VLID="${2:-}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __TGET_STRG="${4:-}"	# storage
	declare -r    __TGET_DIST="${5:-}"	# distribution
	declare -r    __TGET_VERS="${6:-}"	# version
	declare -r    __TGET_EDTN="${7:-}"	# edition
	declare       __LOOP=""				# loop device name
	declare       __UUID=""				# loopXp2 uuid device name
	declare       __RTIM=""				# root image
	declare       __RTFS=""				# root image mount point
	declare       __RTLP=""				# root image loop
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __PATH=""				# work
	declare       __PSEC=""				# work
	declare       __STRT=""				# work
	declare       __SIZE=""				# work
	declare       __CONT=""				# work
	declare       __WORK=""				# work
	# --- create dummy storage ------------------------------------------------
	truncate --size=20G "${__TGET_STRG:?}"
	__LOOP="$(losetup --find --show "${__TGET_STRG}")" && _LIST_RMOV+=("${__LOOP}")
	partprobe "${__LOOP:?}"
	sfdisk --force --wipe always "${__LOOP}" <<- _EOT_
		,100MiB,U
		,,L
_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1
	mkfs.ext4 -F "${__LOOP}"p2
	partprobe "${__LOOP:?}"
	sleep 1
	__UUID="$(lsblk --noheadings --output=UUID "${__LOOP}"p2)"
	# --- file copy -----------------------------------------------------------
	__RTIM="${__TGET_OUTD:?}/${_FILE_RTIM:?}"
	__RTFS="${__TGET_OUTD:?}/${_DIRS_RTFS:?}"
	__RTLP="$(losetup --find --show "${__RTIM}")" && _LIST_RMOV+=("${__RTLP}")
	partprobe "${__RTLP:?}"
	mkdir -p "${__RTFS:?}"
	mount -r "${__RTLP}"p1 "${__RTFS}" && _LIST_RMOV+=("${__RTFS}")
	# --- kernel --------------------------------------------------------------
	__WORK="$(fnFind_kernel "${__RTFS}")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	__VLNZ="${__VLNZ##-}"
	__IRAM="${__IRAM##-}"
	_PATH_VLNZ="${__VLNZ:+"/${__VLNZ}"}"
	_PATH_IRAM="${__IRAM:+"/${__IRAM}"}"
	# --- security option -----------------------------------------------------
	[[ -e "${__RTFS:?}"/usr/bin/aa-enabled  ]] && _SECU_OPTN="${_SECU_APPA:-}"
	[[ -e "${__RTFS:?}"/usr/bin/getenforce  ]] && _SECU_OPTN="${_SECU_SLNX:-}"
	[[ -e "${__RTFS:?}"/usr/sbin/getenforce ]] && _SECU_OPTN="${_SECU_SLNX:-}"
	fnMsgout "${_PROG_NAME:-}" "info" "security: [${_SECU_OPTN:-}]"
	# --- create vm-image -----------------------------------------------------
	fnMake_live_vmimg_p1 "${__LOOP:?}" "p1" "${__TGET_OUTD:?}" "${__UUID:?}" "${__TGET_DIST:?}" "${__TGET_ENTR:?}"
	fnMake_live_vmimg_p2 "${__LOOP:?}" "p2" "${__TGET_OUTD:?}" "${__RTFS:?}" "${__UUID:?}"
	# --- security option -----------------------------------------------------
	[[ -e "${__RTFS:?}"/usr/sbin/getenforce ]] && _SECU_OPTN="${_SECU_SLNX:-}"
	[[ -e "${__RTFS:?}"/usr/bin/getenforce  ]] && _SECU_OPTN="${_SECU_SLNX:-}"
	[[ -e "${__RTFS:?}"/usr/bin/aa-enabled  ]] && _SECU_OPTN="${_SECU_APPA:-}"
	fnMsgout "${_PROG_NAME:-}" "info" "security: [${_SECU_OPTN:-}]"
	umount "${__RTFS}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# --- create uefi/bios image ----------------------------------------------
	__MBRF="${__TGET_OUTD:?}/${_FILE_MBRF:?}"
	__UEFI="${__TGET_OUTD:?}/${_FILE_UEFI:?}"
	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__LOOP}"p1)"
	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK:-}")
	__CONT="$(("${__SIZE}" / "${__PSEC}"))"
	dd if="${__LOOP}" of="${__UEFI}" bs="${__PSEC}" skip="${__STRT}" count="${__CONT}"
	dd if="${__LOOP}" of="${__MBRF}" bs=1 count=440
	# -------------------------------------------------------------------------
	losetup --detach "${__RTLP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	losetup --detach "${__LOOP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")

	unset __WORK __CONT __SIZE __STRT __PSEC __PATH __UEFI __MBRF __IRAM __VLNZ __RTFS __RTLP __RTIM __UUID __LOOP
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: make live vm-image on qemu
#   input :     $1     : storage
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_STRG="${1:-}"	# storage
	# --- command -------------------------------------------------------------
	# /usr/share/novnc/utils/novnc_proxy --listen [::]:6080
	# http://sv-developer:6080/vnc.html
	__OPTN=(
		-cpu "host"
		-machine "q35"
		-enable-kvm
		-device "intel-iommu"
		-m "size=4G"
		-boot "order=c"
		-nic "bridge"
		-vga "std"
		-full-screen
		-display "curses,charset=CP932"
		-k "ja"
		-device "ich9-intel-hda"
		-vnc ":0"
		-nographic
		-drive "file=${__TGET_STRG:?},format=raw"
	)
	fnMk_qemu "${__OPTN[@]}"

	unset __OPTN

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live cd-image (create cdfs)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : storage
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_cdimg_cdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_STRG="${3:-}"	# storage
	declare -r    __OUTD="${__TGET_OUTD:?}/grub"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt2"			# mount point
	declare -r    __STRG="${__TGET_OUTD:?}/strg"			# storage work
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __SQFS="${__TGET_OUTD:?}/${_FILE_SQFS:?}"	# squashfs
	declare -r    __SPLS="${__TGET_OUTD:?}/${_MENU_SPLS:?}"	# splash.png
#	declare -r    __MBRF="${__STRG:?}/${_FILE_MBRF:?}"		# mbr image
	declare -r    __UEFI="${__STRG:?}/${_FILE_UEFI:?}"		# uefi image
	declare -r    __TITL="Live system"						# title
	declare -r    __VLNZ="${_PATH_VLNZ:?}"					# kernel
	declare -r    __IRAM="${_PATH_IRAM:?}"					# initramfs
	declare       __LOOP=""									# loop device name
	# --- mount root image ----------------------------------------------------
	mkdir -p "${__MNTP:?}"
	__LOOP="$(losetup --find --show "${__TGET_STRG:?}")" && _LIST_RMOV+=("${__LOOP}")
	partprobe "${__LOOP:?}"
	mount -r "${__LOOP}"p2 "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	# --- create squashfs -----------------------------------------------------
	fnMk_squashfs "${__MNTP:?}" "${__SQFS:?}"
	# --- create cdfs image ---------------------------------------------------
	mkdir -p "${__CDFS:?}"/{.disk,EFI/BOOT,boot/grub/{live-theme,x86_64-efi,i386-pc},isolinux,"${_DIRS_LIVE:?}"}
	touch "${__CDFS}/.disk/info"
	[[ -e "${__UEFI:?}"                                 ]] && cp --preserve=timestamps             "${__UEFI:?}"                                 "${__CDFS:?}"/boot/grub
	[[ -e "${__SPLS:?}"                                 ]] && cp --preserve=timestamps             "${__SPLS:?}"                                 "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__SQFS:?}"                                 ]] && cp --preserve=timestamps             "${__SQFS:?}"                                 "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__IRAM#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__IRAM#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__VLNZ#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__VLNZ#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__IRAM#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__IRAM#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"/initrd.img
	[[ -e "${__MNTP:?}/${__VLNZ#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__VLNZ#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"/vmlinuz
	[[ -e "${__MNTP:?}"/usr/lib/ISOLINUX/isolinux.bin   ]] && cp --preserve=timestamps             "${__MNTP:?}"/usr/lib/ISOLINUX/isolinux.bin   "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/syslinux/mbr/gptmbr.bin ]] && cp --preserve=timestamps             "${__MNTP:?}"/usr/lib/syslinux/mbr/gptmbr.bin "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/syslinux/modules/bios/. ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/syslinux/modules/bios/. "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/grub/x86_64-efi/.       ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/grub/x86_64-efi/.       "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__MNTP:?}"/usr/lib/grub/i386-pc/.          ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/grub/i386-pc/.          "${__CDFS:?}"/boot/grub/i386-pc
	[[ -e "${__MNTP:?}"/usr/share/syslinux/.            ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/syslinux/.            "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/share/grub2/x86_64-efi/.    ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/grub2/x86_64-efi/.    "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__MNTP:?}"/usr/share/grub2/i386-pc/.       ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/grub2/i386-pc/.       "${__CDFS:?}"/boot/grub/i386-pc
	# --- umount root image ---------------------------------------------------
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	losetup --detach "${__LOOP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __LOOP
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live cd-image (create grub)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : menu entry
function fnMake_live_cdimg_grub() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/grub"			# output directory
	declare -r    __STRG="${__TGET_OUTD:?}/strg"			# storage work
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __TITL="Live system"						# title
	declare -r    __VLNZ="${_PATH_VLNZ:+"${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_PATH_VLNZ##*/}"}"		# kernel
	declare -r    __IRAM="${_PATH_IRAM:+"${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_PATH_IRAM##*/}"}"		# initramfs
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	# --- /EFI/BOOT/grub.cfg --------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__EGRU:?}"
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	# --- create grub.cfg -----------------------------------------------------
	fnGrub_conf  "${__GCFG:?}" "${__INPD:-}/${_FILE_MENU:?}" "${__INPD:-}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_ENTR}" {
		  set gfxpayload="keep"
		  set background_color="black"
		  set options="root=live:CDLABEL=${__TGET_VLID} rd.live.image rd.live.overlay.overlayfs=1${_SECU_OPTN:+" ${_SECU_OPTN}"}"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__VLNZ:?} \${options} --- quiet
		  echo 'Loading initramfs ...'
		  initrd ${__IRAM:?}
		}
_EOT_
	[[ -e "${__EGRU:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__CDFS:?}/EFI/BOOT/${_FILE_GCFG##*/}"
	[[ -e "${__GCFG:?}" ]] && cp --preserve=timestamps "${__GCFG:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}/${__INPD:?}"
#	unset 
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live cd-image (create isolinux)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : menu entry
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_cdimg_ilnx() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __INPD="/isolinux"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/isolinux"		# output directory
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __TITL="Live system"						# title
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	# --- create isolinux.cfg -------------------------------------------------
	fnIlnx_conf  "${__ICFG:?}" "${__INPD:-}/${_FILE_MENU:?}" "${__INPD:-}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnIlnx_theme "${__THME:?}" "${__TITL:?}" "/LiveOS/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		label ${__TGET_ENTR// /-}
		  menu label ^${__TGET_ENTR}
		  menu default
		  linux  /LiveOS/vmlinuz
		  initrd /LiveOS/initrd.img
		  append root=live:CDLABEL=${__TGET_VLID} rd.live.image rd.live.overlay.overlayfs=1${_SECU_OPTN:+" ${_SECU_OPTN}"} --- quiet
_EOT_
	[[ -e "${__ICFG:?}" ]] && cp --preserve=timestamps "${__ICFG:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}/${__INPD:?}"
#	unset 
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: make live cd-image
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : storage
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_cdimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __TGET_STRG="${4:?}"	# storage
	declare -r    __TGET_ISOS="${5:?}"	# output file name
	declare       __CDFS=""				# cdfs image mount point
	declare       __VLID=""				# volume id
	declare       __ISOS=""				# output file name
	declare       __HBRD=""				# iso hybrid mbr file name
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __BCAT=""				# boot catalog
	declare       __ETRI=""				# eltorito
	declare       __BIOS=""				# bios or uefi imga file path
	declare       __PATH=""				# work
	# --- create cd-image image -----------------------------------------------
	fnMake_live_cdimg_cdfs "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_STRG:?}"
	fnMake_live_cdimg_grub "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_ENTR:?}"
	fnMake_live_cdimg_ilnx "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_ENTR:?}"
	# --- create iso image ----------------------------------------------------
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	__VLID="${__TGET_VLID:?}"
	__ISOS="${__TGET_ISOS:?}"
#	__HBRD="/usr/lib/ISOLINUX/isohdpfx.bin"
	__MBRF="${__TGET_OUTD:?}/${_FILE_MBRF:?}"				# bios.img
	__UEFI="${__CDFS}/boot/grub/${_FILE_UEFI:?}"			# uefi.img
	__BCAT="${_FILE_BCAT:?}"								# boot.cat
	           __ETRI="$(find "${__CDFS:?}"/isolinux -name 'eltorito.img' -print -quit)"
	__ETRI="${__ETRI:-"$(find "${__CDFS:?}"/isolinux -name 'isolinux.bin' -print -quit)"}"
	           __BIOS="$(find "${__CDFS:?}"/isolinux -name 'gptmbr.bin'   -print -quit)"
	if [[ -n "${__HBRD:-}" ]] && [[ -e "${__HBRD:-}" ]]; then cp --preserve=timestamps "${__HBRD}" "${__TGET_OUTD}"; __HBRD="${__TGET_OUTD:?}/${__HBRD##*/}"; else __HBRD=""; fi
#	if [[ -n "${__MBRF:-}" ]] && [[ -e "${__MBRF:-}" ]]; then cp --preserve=timestamps "${__MBRF}" "${__TGET_OUTD}"; __MBRF="${__TGET_OUTD:?}/${__MBRF##*/}"; else __MBRF=""; fi
	if [[ -n "${__UEFI:-}" ]] && [[ -e "${__UEFI:-}" ]]; then cp --preserve=timestamps "${__UEFI}" "${__TGET_OUTD}"; __UEFI="${__TGET_OUTD:?}/${__UEFI##*/}"; else __UEFI=""; fi
#	if [[ -n "${__BCAT:-}" ]] && [[ -e "${__BCAT:-}" ]]; then cp --preserve=timestamps "${__BCAT}" "${__TGET_OUTD}"; __BCAT="${__TGET_OUTD:?}/${__BCAT##*/}"; else __BCAT=""; fi
#	if [[ -n "${__ETRI:-}" ]] && [[ -e "${__ETRI:-}" ]]; then cp --preserve=timestamps "${__ETRI}" "${__TGET_OUTD}"; __ETRI="${__TGET_OUTD:?}/${__ETRI##*/}"; else __ETRI=""; fi
#	if [[ -n "${__BIOS:-}" ]] && [[ -e "${__BIOS:-}" ]]; then cp --preserve=timestamps "${__BIOS}" "${__TGET_OUTD}"; __BIOS="${__TGET_OUTD:?}/${__BIOS##*/}"; else __BIOS=""; fi
#	__BIOS="${__BIOS:-"${__MBRF}"}"
	__ETRI="${__ETRI#"${__CDFS:-}/"}"
#	__BIOS="${__BIOS#"${__CDFS:?}/"}"
	fnMk_xorrisofs "${__CDFS:?}" "${__ISOS:?}" "${__VLID:-}" "${__HBRD:-}" "${__BIOS:-}" "${__UEFI:-}" "${__BCAT:-}" "${__ETRI:-}"
	unset __BIOS __ETRI __BCAT __UEFI __MBRF __HBRD __ISOS __VLID __CDFS
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: exec live build
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
function fnMake_live_build() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __OPRT=""				# operation
	declare -r    __BOOT="${_MKOS_BOOT:-}"	# --bootable=
	declare -r    __OUTP="${_MKOS_OUTP:-}"	# --output=
	declare -r    __FMAT="${_MKOS_FMAT:-}"	# --format=
	declare -r    __NWRK="${_MKOS_NWRK:-}"	# --with-network=
	declare -r    __RECM="${_MKOS_RECM:-}"	# --with-recommends
	declare       __DIST=""					# --distribution=
	declare       __VERS=""					# --release=
	declare -r    __ARCH="${_MKOS_ARCH:-}"	# --architecture=
	declare -r    __MKOS="${_DIRS_MKOS:-}"	# --directory=
	declare       __WRKD="" 			# --workspace-directory=
#	declare       __CACH=""				# --package-cache-dir=
	declare       __OUTD="" 			# --output-directory=
	declare       __EDTN=""				# --environment=EDITION=
	declare       __HOST=""				# --hostname=
#	declare -a    __COMD=()				# command
	declare       __CODE=""				# code name
#	declare       __ARCH=""				# architecture
	declare       __VLID=""				# volume id
	declare       __ENTR=""				# menu entry
	declare       __ISOS=""				# output file name
	declare       __SUBD=""				# sub directory
	declare -r    __TEMP="${_DIRS_TEMP:?}"	# local
	declare -r    __RTMP="${_DIRS_RTMP:?}"	# remote
	declare -a    __TGET=()				# target list
	declare       __STRG=""				# storage
	declare       __SPLS=""				# splash.png
	declare       __WORK=""				# work
	declare -a    __ARRY=()				# work
	declare -i    I=0					# work
	# --- get options ---------------------------------------------------------
	set -f -- "${@:-}"
	set +f
	__TGET=()
	while [[ -n "${1:-}" ]]
	do
		IFS=':' read -r -a __ARRY < <(echo "${1:-}")
		__OPRT="${__ARRY[0]:?}"								# operation
		__DIST="${__ARRY[1]:?}"								# distribution
		__VERS="${__ARRY[2]:-}"								# version
		__EDTN="${__ARRY[3]:-}"								# edition
		case "${__DIST,,}" in
			-*      ) break;;
			debian  ) __TGET+=("${1:-}");;
			ubuntu  ) __TGET+=("${1:-}");;
			fedora  ) __TGET+=("${1:-}");;
			centos  ) __TGET+=("${1:-}");;
			alma    ) __TGET+=("${1:-}");;
			rocky   ) __TGET+=("${1:-}");;
			opensuse) __TGET+=("${1:-}");;
#			miracle ) __TGET+=("${1:-}");;
			*       ) ;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	# --- main ----------------------------------------------------------------
	# -m build:debian:13.0:server build:ubuntu:26.04:desktop ...
	for I in "${!__TGET[@]}"
	do
		IFS=':' read -r -a __ARRY < <(echo "${__TGET[I]:-}")
		__OPRT="${__ARRY[0]:?}"								# operation
		__DIST="${__ARRY[1]:?}"								# distribution
		__VERS="${__ARRY[2]:-}"								# version
		__EDTN="${__ARRY[3]:-}"								# edition
		__OPRT="${__OPRT,,}"								# operation
		__DIST="${__DIST,,}"								# --distribution=
		__VERS="${__VERS,,}"								# --release=
		__EDTN="${__EDTN,,}"								# --environment=EDITION=
		__CODE="$(fnFind_codename "${__DIST}" "${__VERS}")"	# code name
#		__ARCH="${_MKOS_ARCH//_/-}"							# architecture
		__VLID="$(fnFind_distribution "${__DIST}")"			# volume id (<=16) Debian13.0x64s / AlmaLinux10x64s / openSUSE16.0x64s
		__ENTR="${__VLID}${__VERS:+" ${__VERS^}"}${__ARCH:+" ${__ARCH//-/_}"}${__EDTN:+" ${__EDTN^}"}"
		__ISOS="${__ENTR// /-}"
		__ISOS="${_DIRS_RMAK:?}/live-${__ISOS,,}.iso"
#		__VLID="${__VLID}${__VERS:+" ${__VERS^}"}${__ARCH:+" ${__ARCH}"}${__EDTN:+" ${__EDTN^}"}"
		__VLID="${__VLID%%-*}"
		__VLID="${__VLID}${__VERS::$((6+6-${#__VLID}))}${__ARCH//[0-9]*[_-]}${__EDTN::1}"
		__VLID="${__VLID// /-}"
		__VLID="${__VLID// /\x20}"
		__VLID="${__VLID^^}"
		__VLID="${__VLID::16}"
		__SUBD="${__DIST}-${__CODE:-"${__VERS}"}${__ARCH:+-"${__ARCH//_/-}"}${__EDTN+-"${__EDTN}"}"
		__WRKD="${__TEMP:?}/${__SUBD:?}" # --workspace-directory=
		__OUTD="${__RTMP:?}/${__SUBD:?}" # --output-directory=
		# --- build -----------------------------------------------------------
		fnMake_live_mkosi "${__OPRT:-}" "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}" "${__WRKD:-}" "${__WRKD:-}"
		case "${__OPRT:-}" in
			build        )
				__STRG="${__OUTD:?}/vm_uefi_${__VLID,,}.raw"
				__SPLS="${__OUTD:?}/${_MENU_SPLS:?}"
				# --- copy output ---------------------------------------------
				mkdir -p "${__OUTD:?}"
				cp --archive "${__WRKD:?}/${_FILE_RTIM:?}" "${__OUTD:?}"/
				# --- splash.png ----------------------------------------------
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -p -r | gzip -d -k > "${__SPLS:?}"
					1f8b0808462b8d69000373706c6173682e706e6700eb0cf073e7e592e262
					6060e0f5f47009626060566060608ae060028a888a88aa3330b0767bba38
					8654dc7a7b909117287868c177ff5c3ef3050ca360148c8251300ae8051a
					c299ff4c6660bcb6edd00b10d7d3d5cf659d53421300e6198186c4050000
_EOT_
				# --- create iso image file -----------------------------------
				fnMake_live_vmimg "${__OUTD:-}" "${__VLID:-}" "${__ENTR:-}" "${__STRG:-}" "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}"
				fnMake_live_qemu  "${__STRG:-}"
				fnMake_live_cdimg "${__OUTD:-}" "${__VLID:-}" "${__ENTR:-}" "${__STRG:-}" "${__ISOS:-}"
				;;
			*            ) __OPTN=("help");;
		esac
sleep 600
		rm -rf "${__WRKD:?}" \
		       "${__OUTD:?}"
	done

	unset I __ARRY __WORK __STRG __TGET __SUBD __ISOS __VLID __CODE __HOST __EDTN __OUTD __WRKD __VERS __DIST
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
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
		    -c|--conf   : making preconfiguration files
		    -m|--make   : making iso files
		      -m operation:distribution:version:edition
		      ex: -m summary:ubuntu:26.04:desktop
		      ex: -m build:debian:13.0:server
		      ex: -m build:ubuntu:26.04:desktop
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
			-c|--conf) fnMake_live_preconf;;
			-m|--make) fnMake_live_build "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
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
