#!/bin/bash
###############################################################################
#
#	creating ipxe menu script files
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2026/07/26
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/07/26 000.0000 J.Itou         first release
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
#	              _DIRS_RTMP="$(mktemp -qd "${_DIRS_PVAT:?}/wrk/${_PROG_NAME}.XXXXXX")"
#	readonly      _DIRS_RTMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary (local)
#	              _LIST_RMOV+=("${_DIRS_RTMP:?}")			# temporary (remote)

	# --- command line parameter ----------------------------------------------
	declare       _COMD_LINE=""								# command line parameter
	              _COMD_LINE="$(cat /proc/cmdline || true)"
	readonly      _COMD_LINE
	declare       _NICS_NAME=""								# nic if name   (ex. ens160)
	declare       _NICS_MADR=""								# nic if mac    (ex. 00:00:00:00:00:00)
	declare       _NICS_AUTO=""								# ipv4 dhcp     (ex. empty or dhcp)
	declare       _NICS_IPV4=""								# ipv4 address  (ex. 192.168.1.1)
	declare       _NICS_MASK=""								# ipv4 netmask  (ex. 255.255.255.0)
	declare       _NICS_BIT4=""								# ipv4 cidr     (ex. 24)
	declare       _NICS_DNS4=""								# ipv4 dns      (ex. 192.168.1.254)
	declare       _NICS_GATE=""								# ipv4 gateway  (ex. 192.168.1.254)
	declare       _NICS_FQDN=""								# hostname fqdn (ex. sv-server.workgroup)
	declare       _NICS_HOST=""								# hostname      (ex. sv-server)
	declare       _NICS_WGRP=""								# domain        (ex. workgroup)
	declare       _NMAN_FLAG=""								# nm_config, ifupdown, loopback
	declare       _DIRS_TGET=""								# target directory
	declare       _FILE_ISOS=""								# iso file name
	declare       _FILE_SEED=""								# preseed file name

	# --- target --------------------------------------------------------------
	declare       _TGET_VIRT=""								# virtualization (ex. vmware)
	declare       _TGET_CHRT=""								# is chgroot     (empty: none, else: chroot)
	declare       _TGET_CNTR=""								# is container   (empty: none, else: container)

	# --- set system parameter ------------------------------------------------
	declare       _DIST_NAME=""								# distribution name (ex. debian)
	declare       _DIST_VERS=""								# release version   (ex. 13)
	declare       _DIST_CODE=""								# code name         (ex. trixie)
	declare       _ROWS_SIZE="25"							# screen size: rows
	declare       _COLS_SIZE="80"							# screen size: columns
	declare       _TEXT_SPCE=""								# space
	declare       _TEXT_GAP1=""								# gap1
	declare       _TEXT_GAP2=""								# gap2
	declare       _COMD_BBOX=""								# busybox (empty: inactive, else: active )
	declare       _OPTN_COPY="--preserve=timestamps"		# copy option

	# --- network parameter ---------------------------------------------------
	declare       _NTPS_ADDR="ntp.nict.jp"					# ntp server address
	declare       _NTPS_IPV4="61.205.120.130"				# ntp server ipv4 address
	declare -r    _NTPS_FBAK="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	declare -r    _IPV6_LHST="::1"							# ipv6 local host address
	declare -r    _IPV4_LHST="127.0.0.1"					# ipv4 local host address
	declare -r    _IPV4_DUMY="127.0.1.1"					# ipv4 dummy address
	declare       _IPV4_UADR=""								# IPv4 address up   (ex. 192.168.1)
	declare       _IPV4_LADR=""								# IPv4 address low  (ex. 1)
	declare       _IPV6_ADDR=""								# IPv6 address      (ex. ::1)
	declare       _IPV6_CIDR=""								# IPv6 cidr         (ex. 64)
	declare       _IPV6_FADR=""								# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	declare       _IPV6_UADR=""								# IPv6 address up   (ex. 0000:0000:0000:0000)
	declare       _IPV6_LADR=""								# IPv6 address low  (ex. 0000:0000:0000:0001)
	declare       _IPV6_RADR=""								# IPv6 reverse addr (ex. ...)
	declare       _LINK_ADDR=""								# LINK address      (ex. fe80::1)
	declare       _LINK_CIDR=""								# LINK cidr         (ex. 64)
	declare       _LINK_FADR=""								# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	declare       _LINK_UADR=""								# LINK address up   (ex. fe80:0000:0000:0000)
	declare       _LINK_LADR=""								# LINK address low  (ex. 0000:0000:0000:0001)
	declare       _LINK_RADR=""								# LINK reverse addr (ex. ...)

	# --- firewalld -----------------------------------------------------------
	declare -r    _FWAL_ZONE="home_use"						# firewalld default zone
															# firewalld service name
	declare -r    _FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
	declare -r    _FWAL_PORT="0-65535/tcp 0-65535/udp"		# firewalld port

	# --- samba parameter -----------------------------------------------------
	declare -r    _SAMB_USER="sambauser"					# force user
	declare -r    _SAMB_GRUP="sambashare"					# force group
	declare -r    _SAMB_GADM="sambaadmin"					# admin group
															# nsswitch.conf
	declare -r    _SAMB_NSSW="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
	declare       _SHEL_NLIN=""								# login shell (disallow system login to samba user)

	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_VADM="/var/admin"					# top of admin working directory
	declare       _DIRS_INST=""								# auto-install working directory
	declare       _DIRS_BACK=""								# top of backup directory
	declare       _DIRS_ORIG=""								# original file directory
	declare       _DIRS_INIT=""								# initial file directory
	declare       _DIRS_SAMP=""								# sample file directory
	declare       _DIRS_LOGS=""								# log file directory

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
	declare -r -a _OPTN_WGET=("--retry-on-http-error" "--tries=3" "--dns-timeout=60" "--connect-timeout=120" "--read-timeout=120" "--quiet")
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

	# === for server environments =================================================

	# --- shared directory parameter ----------------------------------------------
	declare       _DIRS_TOPS="./_srv"						# top of shared directory
	declare       _DIRS_EXPO=":_DIRS_TOPS_:/exports"		# exports
	declare       _DIRS_HGFS=":_DIRS_TOPS_:/hgfs"			# vmware shared
	declare       _DIRS_HTML=":_DIRS_TOPS_:/http/html"		# html contents
	declare       _DIRS_SAMB=":_DIRS_TOPS_:/samba"			# samba shared
	declare       _DIRS_TFTP=":_DIRS_TOPS_:/tftp"			# tftp contents
	declare       _DIRS_USER=":_DIRS_TOPS_:/user"			# user file

	# --- shared of user file -----------------------------------------------------
	declare       _DIRS_PVAT=":_DIRS_USER_:/private"		# private contents directory
	declare       _DIRS_SHAR=":_DIRS_USER_:/share"			# shared of user file
	declare       _DIRS_CONF=":_DIRS_SHAR_:/conf"			# configuration file
	declare       _DIRS_DATA=":_DIRS_CONF_:/_data"			# data file
	declare       _DIRS_KEYS=":_DIRS_CONF_:/_keyring"		# keyring file
	declare       _DIRS_MKOS=":_DIRS_CONF_:/_mkosi"			# mkosi configuration files
	declare       _DIRS_TMPL=":_DIRS_CONF_:/_template"		# templates for various configuration files
	declare       _DIRS_SHEL=":_DIRS_CONF_:/script"			# shell script file
	declare       _DIRS_IMGS=":_DIRS_SHAR_:/imgs"			# iso file extraction destination
	declare       _DIRS_ISOS=":_DIRS_SHAR_:/isos"			# iso file
	declare       _DIRS_LOAD=":_DIRS_SHAR_:/load"			# load module
	declare       _DIRS_RMAK=":_DIRS_SHAR_:/rmak"			# remake file
	declare       _DIRS_CACH=":_DIRS_SHAR_:/cache"			# cache file
	declare       _DIRS_CTNR=":_DIRS_SHAR_:/containers"		# container file
	declare       _DIRS_CHRT=":_DIRS_SHAR_:/chroot"			# container file (chroot)
	declare       _DIRS_XNBD=":_DIRS_EXPO_:/nbd"			# exports (network block device)
	declare       _DIRS_XNFS=":_DIRS_EXPO_:/nfs"			# exports (network file system)
	declare       _DIRS_XSMB=":_DIRS_EXPO_:/smb"			# exports (samba)

	# --- common data file (prefer non-empty current file) ------------------------
	declare       _FILE_CONF="common.cfg"					# common configuration file
	declare       _FILE_DIST="distribution.dat"				# distribution data file
	declare       _FILE_MDIA="media.dat"					# media data file
	declare       _FILE_DSTP="debstrap.dat"					# debstrap data file
	declare       _PATH_CONF=":_DIRS_DATA_:/:_FILE_CONF_:"	# common configuration file
	declare       _PATH_DIST=":_DIRS_DATA_:/:_FILE_DIST_:"	# distribution data file
	declare       _PATH_MDIA=":_DIRS_DATA_:/:_FILE_MDIA_:"	# media data file
	declare       _PATH_DSTP=":_DIRS_DATA_:/:_FILE_DSTP_:"	# debstrap data file

	# --- pre-configuration file templates ----------------------------------------
	declare       _FILE_KICK="kickstart_rhel.cfg"			# for rhel
	declare       _FILE_CLUD="user-data_ubuntu"				# for ubuntu cloud-init
	declare       _FILE_SEDD="preseed_debian.cfg"			# for debian
	declare       _FILE_SEDU="preseed_ubuntu.cfg"			# for ubuntu
	declare       _FILE_YAST="yast_opensuse.xml"			# for opensuse
	declare       _FILE_AGMA="agama_opensuse.json"			# for opensuse
	declare       _PATH_KICK=":_DIRS_TMPL_:/:_FILE_KICK_:"	# for rhel
	declare       _PATH_CLUD=":_DIRS_TMPL_:/:_FILE_CLUD_:"	# for ubuntu cloud-init
	declare       _PATH_SEDD=":_DIRS_TMPL_:/:_FILE_SEDD_:"	# for debian
	declare       _PATH_SEDU=":_DIRS_TMPL_:/:_FILE_SEDU_:"	# for ubuntu
	declare       _PATH_YAST=":_DIRS_TMPL_:/:_FILE_YAST_:"	# for opensuse
	declare       _PATH_AGMA=":_DIRS_TMPL_:/:_FILE_AGMA_:"	# for opensuse

	# --- shell script ------------------------------------------------------------
	declare       _FILE_ERLY="autoinst_cmd_early.sh"		# shell commands to run early
	declare       _FILE_LATE="autoinst_cmd_late.sh"			# "              to run late
	declare       _FILE_PART="autoinst_cmd_part.sh"			# "              to run after partition
	declare       _FILE_RUNS="autoinst_cmd_run.sh"			# "              to run preseed/run
	declare       _PATH_ERLY=":_DIRS_SHEL_:/:_FILE_ERLY_:"	# shell commands to run early
	declare       _PATH_LATE=":_DIRS_SHEL_:/:_FILE_LATE_:"	# "              to run late
	declare       _PATH_PART=":_DIRS_SHEL_:/:_FILE_PART_:"	# "              to run after partition
	declare       _PATH_RUNS=":_DIRS_SHEL_:/:_FILE_RUNS_:"	# "              to run preseed/run

	# --- tftp menu ---------------------------------------------------------------
	declare       _FILE_IPXE="ipxe/autoexec.ipxe"			# ipxe
	declare       _FILE_GRUB="boot/grub/grub.cfg"			# grub
	declare       _FILE_SLNX="menu-bios/syslinux.cfg"		# syslinux (bios)
	declare       _FILE_EF64="menu-efi64/syslinux.cfg"		# syslinux (efi64)
	declare       _PATH_IPXE=":_DIRS_TFTP_:/:_FILE_IPXE_:"	# ipxe
	declare       _PATH_GRUB=":_DIRS_TFTP_:/:_FILE_GRUB_:"	# grub
	declare       _PATH_SLNX=":_DIRS_TFTP_:/:_FILE_SLNX_:"	# syslinux (bios)
	declare       _PATH_EF64=":_DIRS_TFTP_:/:_FILE_EF64_:"	# syslinux (efi64)

	# --- tftp / nbd --------------------------------------------------------------
	declare       _FILE_NBDS="exports.conf"					# nbd exports
	declare       _DIRS_NBDS="/etc/nbd-server/conf.d"		# nbd exports
	declare       _PATH_NBDS=":_DIRS_TFTP_:/:_FILE_NBDS_:"	# nbd exports

	# --- tftp / web server network parameter -------------------------------------
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

	# === for creations ===========================================================

	# --- network parameter -------------------------------------------------------
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

	# --- menu parameter ----------------------------------------------------------
	declare       _MENU_TOUT="5"							# timeout (sec)
	declare       _MENU_RESO="800x600"						# resolution (widht x hight)
	declare       _MENU_DPTH="16"							# colors
	declare       _MENU_MODE="788"							# screen mode (vga=nnn)
	declare       _MENU_SPLS="splash.png"					# splash file
#	declare       _MENU_RESO="854x480"						# resolution (widht x hight): 16:9
#	declare       _MENU_RESO="854x480"						# "                         : 16:9 (for vmware)
#	declare       _MENU_RESO="854x480"						# "                         :  4:3
#	declare       _MENU_DPTH="16"							# colors
#	declare       _MENU_MODE="864"							# screen mode (vga=nnn)

	# --- auto install --------------------------------------------------------
	declare       _AUTO_INST="autoinst.cfg"					# autoinstall configuration file
	declare       _MINI_IRAM="initps.gz"					# initial ram disk of mini.iso including preseed

	# === for mkosi ===============================================================

	# --- mkosi output image format type ------------------------------------------
#	declare       _MKOS_BOOT="yes"							# --bootable= (yes, no)
	declare       _MKOS_OUTP="root_img"						# --output=
	declare       _MKOS_FMAT="directory"					# --format= (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)
#	declare       _MKOS_NWRK="yes"							# --with-network= (yes, no)
	declare       _MKOS_RECM="yes"							# --with-recommends (yes, no)
#	declare       _MKOS_DIST=""								# --distribution= (fedora, debian, kali, ubuntu, arch, opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure, custom)
#	declare       _MKOS_VERS=""								# --release=
	declare       _MKOS_ARCH="x86-64"						# --architecture= (alpha, arc, arm, arm64, ia64, loongarch64, mips64-le, mips-le, parisc, ppc, ppc64, ppc64-le, riscv32, riscv64, s390, s390x, tilegx, x86, x86-64)

	# --- live media parameter ----------------------------------------------------
	declare       _FILE_RTIM=":_MKOS_OUTP_:.raw"			# root image
	declare       _FILE_SQFS="squashfs.img"					# squashfs / filesystem.squashfs
	declare       _FILE_MBRF="bios.img"						# mbr image
	declare       _FILE_UEFI="uefi.img"						# uefi image
	declare       _FILE_BCAT="boot.cat"						# eltorito catalog
#	declare       _FILE_ETRI=""								# 
#	declare       _FILE_BIOS=""								# 
	declare       _FILE_ICFG="isolinux.cfg"					# isolinux.cfg
	declare       _FILE_GCFG="grub.cfg"						# grub.cfg
	declare       _FILE_MENU="menu.cfg"						# menu.cfg
	declare       _FILE_THME="theme.cfg"					# theme.cfg
	declare       _DIRS_LIVE="LiveOS"						# LiveOS / live
	declare       _DIRS_MNTP="mntp"							# mount point
	declare       _DIRS_RTFS="rtfs"							# root image
	declare       _DIRS_CDFS="cdfs"							# cdfs image
	declare       _PATH_VLNZ=""								# kernel
	declare       _PATH_IRAM=""								# initramfs
	declare       _PATH_SPLS="/boot/grub/:_MENU_SPLS_:"		# splash.png
	declare       _SECU_OPTN=""								# security option
	declare       _SECU_APPA="security=apparmor apparmor=1"
	declare       _SECU_SLNX="security=selinux selinux=1 enforcing=0"

# *** function section (common functions) *************************************
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
# descript: find command
#   input :     $1     : command name
#   output:   stdout   : output
#   return:            : unused
function fnFind_command() {
	find "${_DIRS_TGET:-}"/bin/ "${_DIRS_TGET:-}"/sbin/ "${_DIRS_TGET:-}"/usr/bin/ "${_DIRS_TGET:-}"/usr/sbin/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
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
			/tmp/*            | \
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

function fnMk_hostname() {
	declare -r    __TGET_DIST="${1:?}"		# distribution
	declare       __HOST=""				# host name
	# --- hostname ------------------------------------------------------------
	__HOST="${__TGET_DIST:+"${_NWRK_HOST/:_DISTRO_:/"${__TGET_DIST}${_NWRK_WGRP:+".${_NWRK_WGRP}"}"}"}"
	__HOST="${__HOST:-"localhost.localdomain"}"
	echo "${__HOST:?}"
}

function fnMk_nic_name() {
	declare -r    __TGET_DIST="${1:?}"		# distribution
	declare       __NICS=""				# network interface card name
	# --- ethrname ------------------------------------------------------------
	case "${__TGET_DIST:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) __NICS="${_NICS_NAME:-"ens160"}";;
	esac
	echo "${__NICS:?}"
}

function fnMk_ipxe_autoexec() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Configure graphical console ---------------------------------------------

		console --x 1024 --y 768 ||
		# --- Define colour pair ------------------------------------------------------
		# Reset the default colour pair
		cpair 0 ||
		# Redefine the editable text pair as black on white
		cpair --foreground 7 --background 0 4 ||

		# --- Check x86 CPU feature ---------------------------------------------------
		# Check if CPU supports 64-bit operation ("long mode")
		clear arch
		cpuid --ext 29 && set arch x86_64 || set arch i386

		# --- Automatically configure interfaces --------------------------------------
		# Automatically configure the first available interface using DHCP
		ifconf --configurator dhcp ||
		# Automatically configure the first available interface using IPv6
		ifconf --configurator ipv6 ||

		# --- Set the IP address of the PXE boot server -------------------------------
		clear srvraddr
		isset \${66} && set srvraddr \${66} || set srvraddr ${_SRVR_ADDR:?}

		# --- Set the parameters. -----------------------------------------------------
		set srvrhttp http://\${srvraddr}
		set ipxebase \${srvrhttp}/tftp/ipxe
		set optn-timeout 1000
		set menu-timeout 0
		set esc:hex 1b

		# --- Preventing multiple instances -------------------------------------------
		isset \${menu-default} || set menu-default exit

		# --- chain -------------------------------------------------------------------
		chain \${ipxebase}/menu/menu.ipxe
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_menu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Distribution for automatic installation ]")
		$(printf "%-47s %s" "item -- debian"                                "- Debian")
		$(printf "%-47s %s" "item -- ubuntu"                                "- Ubuntu")
		$(printf "%-47s %s" "item -- fedora"                                "- Fedora")
		$(printf "%-47s %s" "item -- centos"                                "- CentOS Stream")
		$(printf "%-47s %s" "item -- almalinux"                             "- AlmaLinux")
		$(printf "%-47s %s" "item -- rockylinux"                            "- Rocky Linux")
		$(printf "%-47s %s" "item -- miraclelinux"                          "- MIRACLE LINUX")
		$(printf "%-47s %s" "item -- opensuse"                              "- openSUSE")
		$(printf "%-47s %s" "item -- windows"                               "- Windows")
		$(printf "%-47s %s" "item --gap --"                                 "[ Other ]")
		$(printf "%-47s %s" "item -- live"                                  "- Live Media")
		$(printf "%-47s %s" "item -- custom-live"                           "- Custom Live Media")
		$(printf "%-47s %s" "item --gap --"                                 "[ System command ]")
		$(printf "%-47s %s" "item -- shell"                                 "- iPXE shell")
		$(printf "%-47s %s" "item -- shutdown"                              "- System shutdown")
		$(printf "%-47s %s" "item -- restart"                               "- System reboot")
		choose --timeout \${menu-timeout} --default \${menu-default} selected && goto \${selected}
		goto menu

		# --- Interactive form block --------------------------------------------------
		:debian
		:ubuntu
		:fedora
		:centos
		:almalinux
		:rockylinux
		:miraclelinux
		:opensuse
		:windows
		:live
		:custom-live
		set distribution \${selected}
		echo "Loading menu/\${selected}.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/\${selected}.ipxe && exit ||
		goto menu

		:shell
		echo "Booting iPXE shell ..."
		shell
		goto menu

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_booting() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Interactive form block --------------------------------------------------
		:menu
		clear openmenu
		#prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && goto reset ||
		goto input
		:setting
		set openmenu 1
		# --- Interactive form block (network parameters) -----------------------------
		:input
		set hostname \${hnameopt}
		set ethrname \${enameopt}
		set ipv4addr ${_IPV4_ADDR:-}
		set ipv4mask ${_IPV4_MASK:-}
		set ipv4gway ${_IPV4_GWAY:-}
		set ipv4nsvr ${_IPV4_NSVR:-}
		$(printf "%-47s %s" "form"                                          "Configure Network Options")
		$(printf "%-47s %s" "item hostname"                                 "Hostname")
		$(printf "%-47s %s" "item ethrname"                                 "Interface")
		$(printf "%-47s %s" "item ipv4addr"                                 "IPv4 address")
		$(printf "%-47s %s" "item ipv4mask"                                 "IPv4 netmask (example: 24 or 255.255.255.0)")
		$(printf "%-47s %s" "item ipv4gway"                                 "IPv4 gateway")
		$(printf "%-47s %s" "item ipv4nsvr"                                 "Name servers")
		isset \${openmenu} && present ||
		# --- cidr -> netmask ---------------------------------------------------------
		isset \${ipv4mask} || goto reset
		#iseq \${ipv4mask}  0 && set ipv4mask 0.0.0.0 ||
		#iseq \${ipv4mask}  1 && set ipv4mask 128.0.0.0 ||
		#iseq \${ipv4mask}  2 && set ipv4mask 192.0.0.0 ||
		#iseq \${ipv4mask}  3 && set ipv4mask 224.0.0.0 ||
		#iseq \${ipv4mask}  4 && set ipv4mask 240.0.0.0 ||
		#iseq \${ipv4mask}  5 && set ipv4mask 248.0.0.0 ||
		#iseq \${ipv4mask}  6 && set ipv4mask 252.0.0.0 ||
		#iseq \${ipv4mask}  7 && set ipv4mask 254.0.0.0 ||
		iseq  \${ipv4mask}  8 && set ipv4mask 255.0.0.0 ||
		iseq  \${ipv4mask}  9 && set ipv4mask 255.128.0.0 ||
		iseq  \${ipv4mask} 10 && set ipv4mask 255.192.0.0 ||
		iseq  \${ipv4mask} 11 && set ipv4mask 255.224.0.0 ||
		iseq  \${ipv4mask} 12 && set ipv4mask 255.240.0.0 ||
		iseq  \${ipv4mask} 13 && set ipv4mask 255.248.0.0 ||
		iseq  \${ipv4mask} 14 && set ipv4mask 255.252.0.0 ||
		iseq  \${ipv4mask} 15 && set ipv4mask 255.254.0.0 ||
		iseq  \${ipv4mask} 16 && set ipv4mask 255.255.0.0 ||
		iseq  \${ipv4mask} 17 && set ipv4mask 255.255.128.0 ||
		iseq  \${ipv4mask} 18 && set ipv4mask 255.255.192.0 ||
		iseq  \${ipv4mask} 19 && set ipv4mask 255.255.224.0 ||
		iseq  \${ipv4mask} 20 && set ipv4mask 255.255.240.0 ||
		iseq  \${ipv4mask} 21 && set ipv4mask 255.255.248.0 ||
		iseq  \${ipv4mask} 22 && set ipv4mask 255.255.252.0 ||
		iseq  \${ipv4mask} 23 && set ipv4mask 255.255.254.0 ||
		iseq  \${ipv4mask} 24 && set ipv4mask 255.255.255.0 ||
		iseq  \${ipv4mask} 25 && set ipv4mask 255.255.255.128 ||
		iseq  \${ipv4mask} 26 && set ipv4mask 255.255.255.192 ||
		iseq  \${ipv4mask} 27 && set ipv4mask 255.255.255.224 ||
		iseq  \${ipv4mask} 28 && set ipv4mask 255.255.255.240 ||
		iseq  \${ipv4mask} 29 && set ipv4mask 255.255.255.248 ||
		iseq  \${ipv4mask} 30 && set ipv4mask 255.255.255.252 ||
		iseq  \${ipv4mask} 31 && set ipv4mask 255.255.255.254 ||
		iseq  \${ipv4mask} 32 && set ipv4mask 255.255.255.255 ||
		# --- netmask -> cidr ---------------------------------------------------------
		clear ipv4cidr
		iseq  \${ipv4mask}   0.0.0.0       && set ipv4cidr  0 ||
		iseq  \${ipv4mask} 128.0.0.0       && set ipv4cidr  1 ||
		iseq  \${ipv4mask} 192.0.0.0       && set ipv4cidr  2 ||
		iseq  \${ipv4mask} 224.0.0.0       && set ipv4cidr  3 ||
		iseq  \${ipv4mask} 240.0.0.0       && set ipv4cidr  4 ||
		iseq  \${ipv4mask} 248.0.0.0       && set ipv4cidr  5 ||
		iseq  \${ipv4mask} 252.0.0.0       && set ipv4cidr  6 ||
		iseq  \${ipv4mask} 254.0.0.0       && set ipv4cidr  7 ||
		iseq  \${ipv4mask} 255.0.0.0       && set ipv4cidr  8 ||
		iseq  \${ipv4mask} 255.128.0.0     && set ipv4cidr  9 ||
		iseq  \${ipv4mask} 255.192.0.0     && set ipv4cidr 10 ||
		iseq  \${ipv4mask} 255.224.0.0     && set ipv4cidr 11 ||
		iseq  \${ipv4mask} 255.240.0.0     && set ipv4cidr 12 ||
		iseq  \${ipv4mask} 255.248.0.0     && set ipv4cidr 13 ||
		iseq  \${ipv4mask} 255.252.0.0     && set ipv4cidr 14 ||
		iseq  \${ipv4mask} 255.254.0.0     && set ipv4cidr 15 ||
		iseq  \${ipv4mask} 255.255.0.0     && set ipv4cidr 16 ||
		iseq  \${ipv4mask} 255.255.128.0   && set ipv4cidr 17 ||
		iseq  \${ipv4mask} 255.255.192.0   && set ipv4cidr 18 ||
		iseq  \${ipv4mask} 255.255.224.0   && set ipv4cidr 19 ||
		iseq  \${ipv4mask} 255.255.240.0   && set ipv4cidr 20 ||
		iseq  \${ipv4mask} 255.255.248.0   && set ipv4cidr 21 ||
		iseq  \${ipv4mask} 255.255.252.0   && set ipv4cidr 22 ||
		iseq  \${ipv4mask} 255.255.254.0   && set ipv4cidr 23 ||
		iseq  \${ipv4mask} 255.255.255.0   && set ipv4cidr 24 ||
		iseq  \${ipv4mask} 255.255.255.128 && set ipv4cidr 25 ||
		iseq  \${ipv4mask} 255.255.255.192 && set ipv4cidr 26 ||
		iseq  \${ipv4mask} 255.255.255.224 && set ipv4cidr 27 ||
		iseq  \${ipv4mask} 255.255.255.240 && set ipv4cidr 28 ||
		iseq  \${ipv4mask} 255.255.255.248 && set ipv4cidr 29 ||
		iseq  \${ipv4mask} 255.255.255.252 && set ipv4cidr 30 ||
		iseq  \${ipv4mask} 255.255.255.254 && set ipv4cidr 31 ||
		iseq  \${ipv4mask} 255.255.255.255 && set ipv4cidr 32 ||
		isset \${ipv4cidr} || goto reset
		# --- network parameters ------------------------------------------------------
		iseq \${distribution} debian       && set nworkopt netcfg/disable_autoconfig=true netcfg/choose_interface=\${ethrname} netcfg/get_hostname=\${hostname} netcfg/get_ipaddress=\${ipv4addr}/\${ipv4cidr} netcfg/get_netmask=\${ipv4mask} netcfg/get_gateway=\${ipv4gway} netcfg/get_nameservers=\${ipv4nsvr} ||
		iseq \${distribution} ubuntu       && set nworkopt ip=\${ipv4addr}:\${rootserv}:\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:static:\${ipv4nsvr} ||
		iseq \${distribution} fedora       && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} centos       && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} almalinux    && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} rockylinux   && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} miraclelinux && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} opensuse     && set nworkopt netsetup=dhcp hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr}/\${ipv4cidr},\${ipv4gway},\${ipv4nsvr},workgroup ||
		# --- Interactive form block (other parameters) -------------------------------
		set autoinst \${parmauto}
		set language \${languopt}
		set otherprm \${otheropt}
		set networks \${nworkopt}
		set debugprm \${debugopt}
		$(printf "%-47s %s" "form"                                          "Configure Autoinstall Options")
		$(printf "%-47s %s" "item autoinst"                                 "Auto install")
		$(printf "%-47s %s" "item language"                                 "Language")
		$(printf "%-47s %s" "item networks"                                 "Network")
		$(printf "%-47s %s" "item otherprm"                                 "Other options")
		$(printf "%-47s %s" "item debugprm"                                 "Debug options")
		isset \${openmenu} && present ||
		isset \${autoinst} && clear debugprm ||
		# --- check block -------------------------------------------------------------
		:check
		menu Select the next action
		$(printf "%-47s %s" "item --gap --"                                 "Hostname: ------> \${hostname}")
		$(printf "%-47s %s" "item --gap --"                                 "Interface: -----> \${ethrname}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 address: --> \${ipv4addr}/\${ipv4cidr}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 netmask: --> \${ipv4mask}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 gateway: --> \${ipv4gway}")
		$(printf "%-47s %s" "item --gap --"                                 "Names ervers: --> \${ipv4nsvr}")
		$(printf "%-47s %s" "item --gap --"                                 "Auto instal: ---> \${autoinst}")
		$(printf "%-47s %s" "item --gap --"                                 "Language: ------> \${language}")
		$(printf "%-47s %s" "item --gap --"                                 "Network: -------> \${networks}")
		$(printf "%-47s %s" "item --gap --"                                 "Other options: -> \${otherprm}")
		$(printf "%-47s %s" "item --gap --"                                 "Debug options: -> \${debugprm}")
		item --gap --
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Action ]")
		$(printf "%-47s %s" "item -- booting"                               "- OS booting")
		$(printf "%-47s %s" "item -- setting"                               "- Set parameters")
		choose --timeout \${menu-timeout} --default \${menu-default} selected && goto \${selected}
		goto check
		# --- booting block -----------------------------------------------------------
		:booting
		set options \${autoinst} \${language} \${networks} \${otherprm} \${debugprm}
		echo \${messages}
		echo Loading boot files ...
		kernel \${kernlopt} \${options} || goto error
		initrd \${inirdopt} || goto error
		boot || goto error
		exit

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_debian() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://wiki.debian.org/DebianReleases/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- sid"                                   "- Debian \${edition} sid (unstable)")
		$(printf "%-47s %s" "item -- testing"                               "- Debian \${edition} testing (testing)")
		$(printf "%-47s %s" "item -- duke"                                  "- Debian \${edition} 15.0 duke (unreleased)")
		$(printf "%-47s %s" "item -- forky"                                 "- Debian \${edition} 14.0 forky (unreleased)")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- trixie"                                "- Debian \${edition} 13.0 trixie (stable)")
		$(printf "%-47s %s" "item -- bookworm"                              "- Debian \${edition} 12.0 bookworm (oldstable)")
		$(printf "%-47s %s" "item -- bullseye"                              "- Debian \${edition} 11.0 bullseye (oldoldstable)")
		$(printf "%-47s %s" "#item --gap --"                                "[ Extended LTS support ]")
		$(printf "%-47s %s" "#item -- buster"                               "- Debian \${edition} 10.0 buster")
		$(printf "%-47s %s" "#item -- stretch"                              "- Debian \${edition} 9.0 stretch")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "#item -- jessie"                               "- Debian \${edition} 8.0 jessie")
		$(printf "%-47s %s" "#item -- wheezy"                               "- Debian \${edition} 7.0 wheezy")
		$(printf "%-47s %s" "#item -- squeeze"                              "- Debian \${edition} 6.0 squeeze")
		$(printf "%-47s %s" "#item -- lenny"                                "- Debian \${edition} 5.0 lenny")
		$(printf "%-47s %s" "#item -- etch"                                 "- Debian \${edition} 4.0 etch")
		$(printf "%-47s %s" "#item -- sarge"                                "- Debian \${edition} 3.1 sarge")
		$(printf "%-47s %s" "#item -- woody"                                "- Debian \${edition} 3.0 woody")
		$(printf "%-47s %s" "#item -- potato"                               "- Debian \${edition} 2.2 potato")
		$(printf "%-47s %s" "#item -- slink"                                "- Debian \${edition} 2.1 slink")
		$(printf "%-47s %s" "#item -- hamm"                                 "- Debian \${edition} 2.0 hamm")
		$(printf "%-47s %s" "#item -- bo"                                   "- Debian \${edition} 1.3 bo")
		$(printf "%-47s %s" "#item -- rex"                                  "- Debian \${edition} 1.2 rex")
		$(printf "%-47s %s" "#item -- buzz"                                 "- Debian \${edition} 1.1 buzz")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto \${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:sid
		:testing
		:duke
		:forky
		:trixie
		:bookworm
		:bullseye
		#:buster
		#:stretch
		#:jessie
		#:wheezy
		#:squeeze
		#:lenny
		#:etch
		#:sarge
		#:woody
		#:potato
		#:slink
		#:hamm
		#:bo
		#:rex
		#:buzz
		clear vers
		iseq \${selected} sid      && set vers unstable ||
		iseq \${selected} testing  && set vers testing  ||
		iseq \${selected} duke     && set vers 15       ||
		iseq \${selected} forky    && set vers 14       ||
		iseq \${selected} trixie   && set vers 13       ||
		iseq \${selected} bookworm && set vers 12       ||
		iseq \${selected} bullseye && set vers 11       ||
		isset \${vers} || goto menu
		iseq \${edition} server  && goto debian-server ||
		iseq \${edition} desktop && goto debian-desktop ||
		goto menu

		:debian-server
		set messages Loading Debian \${vers} Server ...
		set parmauto auto=true preseed/url=\${srvrhttp}/conf/preseed/ps_debian_server.cfg
		set imgsdirs \${srvrhttp}/imgs/debian-mini-\${vers}
		#set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/debian-mini-\${vers}
		goto debian-common

		:debian-desktop
		set messages Loading Debian \${vers} Desktop ...
		set parmauto auto=true preseed/url=\${srvrhttp}/conf/preseed/ps_debian_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/debian-mini-\${vers}
		#set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/debian-mini-\${vers}
		goto debian-common

		:debian-common
		set kernlopt \${imgsdirs}/linux
		set inirdopt \${imgsdirs}/initrd.gz
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
		set otheropt --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_ubuntu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://ubuntu.com/project/docs/release-team/list-of-releases/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- stonking"                              "- Ubuntu \${edition} 26.10 Stonking Stingray")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- resolute"                              "- Ubuntu \${edition} 26.04 LTS Resolute Raccoon")
		$(printf "%-47s %s" "item -- noble"                                 "- Ubuntu \${edition} 24.04 LTS Noble Numbat")
		$(printf "%-47s %s" "#item -- jammy"                                "- Ubuntu \${edition} 22.04 LTS Jammy Jellyfish")
		$(printf "%-47s %s" "#item -- focal"                                "- Ubuntu \${edition} 20.04 LTS Focal Fossa")
		$(printf "%-47s %s" "#item -- bionic"                               "- Ubuntu \${edition} 18.04 LTS Bionic Beaver")
		$(printf "%-47s %s" "#item -- xenial"                               "- Ubuntu \${edition} 16.04 LTS Xenial Xerus")
		$(printf "%-47s %s" "#item -- trusty"                               "- Ubuntu \${edition} 14.04 LTS Trusty Tahr")
		$(printf "%-47s %s" "#item --gap --"                                "[ Expanded Security Maintenance ]")
		$(printf "%-47s %s" "#item -- focal"                                "- Ubuntu \${edition} 20.04 ESM Focal Fossa")
		$(printf "%-47s %s" "#item -- bionic"                               "- Ubuntu \${edition} 18.04 ESM Bionic Beaver")
		$(printf "%-47s %s" "#item -- xenial"                               "- Ubuntu \${edition} 16.04 ESM Xenial Xerus")
		$(printf "%-47s %s" "#item -- trusty"                               "- Ubuntu \${edition} 14.04 ESM Trusty Tahr")
		$(printf "%-47s %s" "#item -- precise"                              "- Ubuntu \${edition} 12.04 ESM Precise Pangolin")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")")
		$(printf "%-47s %s" "#item -- questing"                             "- Ubuntu \${edition} 25.10 Questing Quokka")
		$(printf "%-47s %s" "#item -- plucky"                               "- Ubuntu \${edition} 25.04 Plucky Puffin")
		$(printf "%-47s %s" "#item -- oracular"                             "- Ubuntu \${edition} 24.10 Oracular Oriole")
		$(printf "%-47s %s" "#item -- mantic"                               "- Ubuntu \${edition} 23.10 Mantic Minotaur")
		$(printf "%-47s %s" "#item -- lunar"                                "- Ubuntu \${edition} 23.04 Lunar Lobster")
		$(printf "%-47s %s" "#item -- kinetic"                              "- Ubuntu \${edition} 22.10 Kinetic Kudu")
		$(printf "%-47s %s" "#item -- impish"                               "- Ubuntu \${edition} 21.10 Impish Indri")
		$(printf "%-47s %s" "#item -- hirsute"                              "- Ubuntu \${edition} 21.04 Hirsute Hippo")
		$(printf "%-47s %s" "#item -- groovy"                               "- Ubuntu \${edition} 20.10 Groovy Gorilla")
		$(printf "%-47s %s" "#item -- eoan"                                 "- Ubuntu \${edition} 19.10 Eoan Ermine")
		$(printf "%-47s %s" "#item -- disco"                                "- Ubuntu \${edition} 19.04 Disco Dingo")
		$(printf "%-47s %s" "#item -- cosmic"                               "- Ubuntu \${edition} 18.10 Cosmic Cuttlefish")
		$(printf "%-47s %s" "#item -- artful"                               "- Ubuntu \${edition} 17.10 Artful Aardvark")
		$(printf "%-47s %s" "#item -- zesty"                                "- Ubuntu \${edition} 17.04 Zesty Zapus")
		$(printf "%-47s %s" "#item -- yakkety"                              "- Ubuntu \${edition} 16.10 Yakkety Yak")
		$(printf "%-47s %s" "#item -- wily"                                 "- Ubuntu \${edition} 15.10 Wily Werewolf")
		$(printf "%-47s %s" "#item -- vivid"                                "- Ubuntu \${edition} 15.04 Vivid Vervet")
		$(printf "%-47s %s" "#item -- utopic"                               "- Ubuntu \${edition} 14.10 Utopic Unicorn")
		$(printf "%-47s %s" "#item -- saucy"                                "- Ubuntu \${edition} 13.10 Saucy Salamander")
		$(printf "%-47s %s" "#item -- raring"                               "- Ubuntu \${edition} 13.04 Raring Ringtail")
		$(printf "%-47s %s" "#item -- quantal"                              "- Ubuntu \${edition} 12.10 Quantal Quetzal")
		$(printf "%-47s %s" "#item -- precise"                              "- Ubuntu \${edition} 12.04 LTS Precise Pangolin")
		$(printf "%-47s %s" "#item -- oneiric"                              "- Ubuntu \${edition} 11.10 Oneiric Ocelot")
		$(printf "%-47s %s" "#item -- natty"                                "- Ubuntu \${edition} 11.04 Natty Narwhal")
		$(printf "%-47s %s" "#item -- maverick"                             "- Ubuntu \${edition} 10.10 Maverick Meerkat")
		$(printf "%-47s %s" "#item -- lucid"                                "- Ubuntu \${edition} 10.04 LTS Lucid Lynx")
		$(printf "%-47s %s" "#item -- karmic"                               "- Ubuntu \${edition} 9.10 Karmic Koala")
		$(printf "%-47s %s" "#item -- jaunty"                               "- Ubuntu \${edition} 9.04 Jaunty Jackalope")
		$(printf "%-47s %s" "#item -- intrepid"                             "- Ubuntu \${edition} 8.10 Intrepid Ibex")
		$(printf "%-47s %s" "#item -- hardy"                                "- Ubuntu \${edition} 8.04 LTS Hardy Heron")
		$(printf "%-47s %s" "#item -- gutsy"                                "- Ubuntu \${edition} 7.10 Gutsy Gibbon")
		$(printf "%-47s %s" "#item -- feisty"                               "- Ubuntu \${edition} 7.04 Feisty Fawn")
		$(printf "%-47s %s" "#item -- edgy"                                 "- Ubuntu \${edition} 6.10 Edgy Eft")
		$(printf "%-47s %s" "#item -- dapper"                               "- Ubuntu \${edition} 6.06 LTS Dapper Drake")
		$(printf "%-47s %s" "#item -- breezy"                               "- Ubuntu \${edition} 5.10 Breezy Badger")
		$(printf "%-47s %s" "#item -- hoary"                                "- Ubuntu \${edition} 5.04 Hoary Hedgehog")
		$(printf "%-47s %s" "#item -- warty"                                "- Ubuntu \${edition} 4.10 Warty Warthog")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto \${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:stonking
		:resolute
		#:questing
		#:plucky
		#:oracular
		:noble
		#:mantic
		#:lunar
		#:kinetic
		#:jammy
		#:impish
		#:hirsute
		#:groovy
		#:focal
		#:eoan
		#:disco
		#:cosmic
		#:bionic
		#:artful
		#:zesty
		#:yakkety
		#:xenial
		#:wily
		#:vivid
		#:utopic
		#:trusty
		#:saucy
		#:raring
		#:quantal
		#:precise
		#:precise
		#:oneiric
		#:natty
		#:maverick
		#:lucid
		#:karmic
		#:jaunty
		#:intrepid
		#:hardy
		#:gutsy
		#:feisty
		#:edgy
		#:dapper
		#:breezy
		#:hoary
		#:warty
		clear vers
		iseq \${selected} stonking && set vers 26.10 ||
		iseq \${selected} resolute && set vers 26.04 ||
		iseq \${selected} noble    && set vers 24.04 ||
		isset \${vers} || goto menu
		iseq \${edition} server  && goto ubuntu-server ||
		iseq \${edition} desktop && goto ubuntu-desktop ||
		goto menu

		:ubuntu-server
		set messages Loading Ubuntu \${vers} Server ...
		set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=\${srvrhttp}/conf/nocloud/ubuntu_server
		set imgsdirs \${srvrhttp}/imgs/ubuntu-live-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/ubuntu-live-\${vers}
		goto ubuntu-common

		:ubuntu-desktop
		set messages Loading Ubuntu \${vers} Desktop ...
		set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=\${srvrhttp}/conf/nocloud/ubuntu_desktop
		set imgsdirs \${srvrhttp}/imgs/ubuntu-desktop-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/ubuntu-desktop-\${vers}
		goto ubuntu-common

		:ubuntu-common
		set kernlopt \${imgsdirs}/casper/vmlinuz
		set inirdopt \${imgsdirs}/casper/initrd
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
		set otheropt netboot=nfs nfsroot=\${exptdirs} network-config=disabled --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_fedora() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://en.wikipedia.org/wiki/Fedora_Linux_release_history
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- 46"                                    "- Fedora \${edition} 46")
		$(printf "%-47s %s" "item -- 45"                                    "- Fedora \${edition} 45")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 44"                                    "- Fedora \${edition} 44")
		$(printf "%-47s %s" "item -- 43"                                    "- Fedora \${edition} 43")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "#item -- 42"                                   "- Fedora Linux \${edition} 42 (Adams)")
		$(printf "%-47s %s" "#item -- 41"                                   "- Fedora Linux \${edition} 41")
		$(printf "%-47s %s" "#item -- 40"                                   "- Fedora Linux \${edition} 40")
		$(printf "%-47s %s" "#item -- 39"                                   "- Fedora Linux \${edition} 39")
		$(printf "%-47s %s" "#item -- 38"                                   "- Fedora Linux \${edition} 38")
		$(printf "%-47s %s" "#item -- 37"                                   "- Fedora Linux \${edition} 37")
		$(printf "%-47s %s" "#item -- 36"                                   "- Fedora Linux \${edition} 36")
		$(printf "%-47s %s" "#item -- 35"                                   "- Fedora Linux \${edition} 35")
		$(printf "%-47s %s" "#item -- 34"                                   "- Fedora Linux \${edition} 34")
		$(printf "%-47s %s" "#item -- 33"                                   "- Fedora Linux \${edition} 33")
		$(printf "%-47s %s" "#item -- 32"                                   "- Fedora Linux \${edition} 32")
		$(printf "%-47s %s" "#item -- 31"                                   "- Fedora Linux \${edition} 31")
		$(printf "%-47s %s" "#item -- 30"                                   "- Fedora Linux \${edition} 30")
		$(printf "%-47s %s" "#item -- 29"                                   "- Fedora Linux \${edition} 29")
		$(printf "%-47s %s" "#item -- 28"                                   "- Fedora Linux \${edition} 28")
		$(printf "%-47s %s" "#item -- 27"                                   "- Fedora Linux \${edition} 27")
		$(printf "%-47s %s" "#item -- 26"                                   "- Fedora Linux \${edition} 26")
		$(printf "%-47s %s" "#item -- 25"                                   "- Fedora Linux \${edition} 25")
		$(printf "%-47s %s" "#item -- 24"                                   "- Fedora Linux \${edition} 24")
		$(printf "%-47s %s" "#item -- 23"                                   "- Fedora Linux \${edition} 23")
		$(printf "%-47s %s" "#item -- 22"                                   "- Fedora Linux \${edition} 22")
		$(printf "%-47s %s" "#item -- 21"                                   "- Fedora Linux \${edition} 21 (Twenty One)")
		$(printf "%-47s %s" "#item -- 20"                                   "- Fedora Linux \${edition} 20 (Heisenbug)")
		$(printf "%-47s %s" "#item -- 19"                                   "- Fedora Linux \${edition} 19 (Schrödinger’s Cat)")
		$(printf "%-47s %s" "#item -- 18"                                   "- Fedora Linux \${edition} 18 (Spherical Cow)")
		$(printf "%-47s %s" "#item -- 17"                                   "- Fedora Linux \${edition} 17 (Beefy Miracle)")
		$(printf "%-47s %s" "#item -- 16"                                   "- Fedora Linux \${edition} 16 (Verne)")
		$(printf "%-47s %s" "#item -- 15"                                   "- Fedora Linux \${edition} 15 (Lovelock)")
		$(printf "%-47s %s" "#item -- 14"                                   "- Fedora Linux \${edition} 14 (Laughlin)")
		$(printf "%-47s %s" "#item -- 13"                                   "- Fedora Linux \${edition} 13 (Goddard)")
		$(printf "%-47s %s" "#item -- 12"                                   "- Fedora Linux \${edition} 12 (Constantine)")
		$(printf "%-47s %s" "#item -- 11"                                   "- Fedora Linux \${edition} 11 (Leonidas)")
		$(printf "%-47s %s" "#item -- 10"                                   "- Fedora Linux \${edition} 10 (Cambridge)")
		$(printf "%-47s %s" "#item --  9"                                   "- Fedora Linux \${edition} 9 (Sulphur)")
		$(printf "%-47s %s" "#item --  8"                                   "- Fedora Linux \${edition} 8 (Werewolf)")
		$(printf "%-47s %s" "#item --  7"                                   "- Fedora Linux \${edition} 7 (Moonshine)")
		$(printf "%-47s %s" "#item --  6"                                   "- Fedora Core \${edition} 6 (Zod)")
		$(printf "%-47s %s" "#item --  5"                                   "- Fedora Core \${edition} 5 (Bordeaux)")
		$(printf "%-47s %s" "#item --  4"                                   "- Fedora Core \${edition} 4 (Stentz)")
		$(printf "%-47s %s" "#item --  3"                                   "- Fedora Core \${edition} 3 (Heidelberg)")
		$(printf "%-47s %s" "#item --  2"                                   "- Fedora Core \${edition} 2 (Tettnang)")
		$(printf "%-47s %s" "#item --  1"                                   "- Fedora Core \${edition} 1 (Yarrow)")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto fedora-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:fedora-46
		:fedora-45
		:fedora-44
		:fedora-43
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto fedora-server ||
		iseq \${edition} desktop && goto fedora-desktop ||
		goto menu

		:fedora-server
		set messages Loading Fedora \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_fedora-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/fedora-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-\${vers}
		goto fedora-common

		:fedora-desktop
		set messages Loading Fedora \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_fedora-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/fedora-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-\${vers}
		goto fedora-common

		:fedora-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_centos() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://en.wikipedia.org/wiki/CentOS_Stream
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 10"                                    "- CentOS Stream \${edition} 10")
		$(printf "%-47s %s" "item --  9"                                    "- CentOS Stream \${edition} 9")
		$(printf "%-47s %s" "item --  8"                                    "- CentOS Stream \${edition} 8")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto centos-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:centos-10
		:centos-9
		:centos-8
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto centos-server ||
		iseq \${edition} desktop && goto centos-desktop ||
		goto menu

		:centos-server
		set messages Loading CentOS Stream \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_centos-stream-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/centos-stream-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/centos-stream-netinst-\${vers}
		goto centos-common

		:centos-desktop
		set messages Loading CentOS Stream \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_centos-stream-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/centos-stream-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/centos-stream-netinst-\${vers}
		goto centos-common

		:centos-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_almalinux() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://wiki.almalinux.org/release-notes/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 10"                                    "- AlmaLinux \${edition} 10")
		$(printf "%-47s %s" "item --  9"                                    "- AlmaLinux \${edition} 9")
		$(printf "%-47s %s" "item --  8"                                    "- AlmaLinux \${edition} 8")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto almalinux-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:almalinux-10
		:almalinux-9
		:almalinux-8
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto almalinux-server ||
		iseq \${edition} desktop && goto almalinux-desktop ||
		goto menu

		:almalinux-server
		set messages Loading AlmaLinux \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_almalinux-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/almalinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/almalinux-netinst-\${vers}
		goto almalinux-common

		:almalinux-desktop
		set messages Loading AlmaLinux \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_almalinux-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/almalinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/almalinux-netinst-\${vers}
		goto almalinux-common

		:almalinux-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_rockylinux() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://wiki.rockylinux.org/rocky/version/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 10"                                    "- Rocky Linux \${edition} 10")
		$(printf "%-47s %s" "item --  9"                                    "- Rocky Linux \${edition} 9")
		$(printf "%-47s %s" "item --  8"                                    "- Rocky Linux \${edition} 8")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto rockylinux-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:rockylinux-10
		:rockylinux-9
		:rockylinux-8
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto rockylinux-server ||
		iseq \${edition} desktop && goto rockylinux-desktop ||
		goto menu

		:rockylinux-server
		set messages Loading Rocky Linux \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_rockylinux-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/rockylinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/rockylinux-netinst-\${vers}
		goto rockylinux-common

		:rockylinux-desktop
		set messages Loading Rocky Linux \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_rockylinux-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/rockylinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/rockylinux-netinst-\${vers}
		goto rockylinux-common

		:rockylinux-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_miraclelinux() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://www.miraclelinux.com/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "#item -- 10"                                   "- MIRACLE LINUX \${edition} 10")
		$(printf "%-47s %s" "item --  9"                                    "- MIRACLE LINUX \${edition} 9")
		$(printf "%-47s %s" "item --  8"                                    "- MIRACLE LINUX \${edition} 8")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto miraclelinux-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:miraclelinux-10
		:miraclelinux-9
		:miraclelinux-8
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto miraclelinux-server ||
		iseq \${edition} desktop && goto miraclelinux-desktop ||
		goto menu

		:miraclelinux-server
		set messages Loading MIRACLE LINUX \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_miraclelinux-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/miraclelinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/miraclelinux-netinst-\${vers}
		goto miraclelinux-common

		:miraclelinux-desktop
		set messages Loading MIRACLE LINUX \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_miraclelinux-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/miraclelinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/miraclelinux-netinst-\${vers}
		goto miraclelinux-common

		:miraclelinux-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_opensuse() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://en.opensuse.org/openSUSE:Roadmap
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- 16.1"                                  "- openSUSE \${edition} 16.1")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 16.0"                                  "- openSUSE \${edition} 16.0")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto opensuse-leap-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:opensuse-leap-16.1
		:opensuse-leap-16.0
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto opensuse-leap-server ||
		iseq \${edition} desktop && goto opensuse-leap-desktop ||
		goto menu

		:opensuse-leap-server
		set messages Loading openSUSE \${vers} Server ...
		set parmauto live.password=install inst.auto=\${srvrhttp}/conf/agama/autoinst_leap-\${vers}.json
		set imgsdirs \${srvrhttp}/imgs/opensuse-leap-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/opensuse-leap-netinst-\${vers}
		goto opensuse-leap-common

		:opensuse-leap-desktop
		set messages Loading openSUSE \${vers} Desktop ...
		set parmauto live.password=install inst.auto=\${srvrhttp}/conf/agama/autoinst_leap-\${vers}_desktop.json
		set imgsdirs \${srvrhttp}/imgs/opensuse-leap-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/opensuse-leap-netinst-\${vers}
		goto opensuse-leap-common

		:opensuse-leap-common
		set kernlopt \${imgsdirs}/boot/x86_64/loader/linux
		set inirdopt \${imgsdirs}/boot/x86_64/loader/initrd
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja_JP
		set otheropt root=live:\${srvrhttp}/isos/linux/opensuse/Leap-\${vers}-online-installer-x86_64.install.iso --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe_windows() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST
	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# 
		#set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "#item --gap --"                                "[ Edition ]")
		$(printf "%-47s %s" "#item -- server"                               "- Server")
		$(printf "%-47s %s" "#item -- desktop"                              "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- windows-10"                            "- Windows 10")
		$(printf "%-47s %s" "item -- windows-11"                            "- Windows 11")
		$(printf "%-47s %s" "#item --gap --"                                "[ Extended LTS support ]")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ System tools ]")
		$(printf "%-47s %s" "item -- memtest86plus"                         "- Memtest86+ 8.10")
		$(printf "%-47s %s" "item -- winpe-x64"                             "- WinPE x64")
		$(printf "%-47s %s" "item -- ati2020x86"                            "- Acronis True Image 2020x86")
		$(printf "%-47s %s" "item -- ati2020x64"                            "- Acronis True Image 2020x64")
		$(printf "%-47s %s" "item -- aomei-backupper"                       "- AOMEI Backupper Standard")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		#iseq \${selected} server  && goto edition ||
		#iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto \${selected} ||
		goto menu

		#:edition
		#iseq \${selected} server  && set edition server ||
		#iseq \${selected} desktop && set edition desktop ||
		#goto menu

		:windows-10
		echo Loading Windows 10 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/windows-10
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w10.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:windows-11
		echo Loading Windows 11 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/windows-11
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w11.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:memtest86plus
		echo Loading Memtest86+ 8.10 ...
		set knladdr \${srvrhttp}/imgs/memtest86plus
		iseq \${platform} efi && set knlfile \${knladdr}/EFI/BOOT/memtest || set knlfile \${knladdr}/boot/memtest
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit

		:winpe-x64
		echo Loading WinPE x64 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/winpe-x64
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:ati2020x86
		echo Loading Acronis True Image 2020x86 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/ati2020x86
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:ati2020x64
		echo Loading Acronis True Image 2020x64 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/ati2020x64
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:aomei-backupper
		echo Loading AOMEI Backupper Standard ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/aomei-backupper
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

function fnMk_ipxe() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	# --- create --------------------------------------------------------------
	# https://www.salstar.sk/boot/
#	IFS= mapfile -d $'\n' -t _LIST_DIST < <(cat /srv/user/share/conf/_data/distribution.dat)
	declare       __LINE=""
	declare -a    __LIST=()
	declare       __DIST=""
	declare -a    __ARRY=()
	declare -a    __SORT=()
#	for I in "${!_LIST_DIST[@]}"
#	do
#		__LINE="${_LIST_DIST[I]:-}"
	while read -r __LINE
	do
		read -r -a __LIST < <(echo "${__LINE:-}")
		if [[ "${__DIST:-"${__LIST[0]%%-*}"}" != "${__LIST[0]%%-*}" ]]; then
			__SORT+=("$(printf "%s\n" "${__ARRY[@]:-}" | sort -ruV -k 14 -k 1)")
			__ARRY=()
			case "${__DIST:-}" in
				version      ) fnMk_ipxe_autoexec      "${_PATH_IPXE:?}"
							   fnMk_ipxe_menu          "${_PATH_IPXE%/*}/menu/menu.ipxe"
							   fnMk_ipxe_booting       "${_PATH_IPXE%/*}/menu/booting.ipxe";;
#							   fnMk_ipxe_live          "${_PATH_IPXE%/*}/menu/live.ipxe"
#							   fnMk_ipxe_custom_live   "${_PATH_IPXE%/*}/menu/custom-live.ipxe";;
				debian       ) fnMk_ipxe_debian        "${_PATH_IPXE%/*}/menu/debian.ipxe";;
				ubuntu       ) fnMk_ipxe_ubuntu        "${_PATH_IPXE%/*}/menu/ubuntu.ipxe";;
				fedora       ) fnMk_ipxe_fedora        "${_PATH_IPXE%/*}/menu/fedora.ipxe";;
				centos       ) fnMk_ipxe_centos        "${_PATH_IPXE%/*}/menu/centos.ipxe";;
				almalinux    ) fnMk_ipxe_almalinux     "${_PATH_IPXE%/*}/menu/almalinux.ipxe";;
				rockylinux   ) fnMk_ipxe_rockylinux    "${_PATH_IPXE%/*}/menu/rockylinux.ipxe";;
				miraclelinux ) fnMk_ipxe_miraclelinux  "${_PATH_IPXE%/*}/menu/miraclelinux.ipxe";;
				opensuse     ) fnMk_ipxe_opensuse      "${_PATH_IPXE%/*}/menu/opensuse.ipxe";;
				windows      ) fnMk_ipxe_windows       "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				memtest86plus) fnMk_ipxe_memtest86plus "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				winpe        ) fnMk_ipxe_winpe         "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				ati2020x86   ) fnMk_ipxe_ati2020x86    "${_PATH_IPXE%/*}/menu/windows.ipxe";;
				*            ) ;;
			esac
		fi
		__DIST="${__LIST[0]%%-*}"
		__ARRY+=("${__LINE:-}")
	done < "${_PATH_DIST:?}"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# *** main section ************************************************************
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

	# --- create temporary directory ------------------------------------------
#	declare       _DIRS_RTMP=""			# remote
	              _DIRS_RTMP="$(mktemp -qd "${_DIRS_PVAT:?}/wrk/${_PROG_NAME}.XXXXXX")"
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
			-p|--pxe ) fnMk_ipxe "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
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
