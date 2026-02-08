#!/bin/bash

###############################################################################
#
#	post-installation test shell
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
# descript: IPv6 full address
#   input :     $1     : value
#   input :     $2     : format (not empty: zero padding)
#   output:   stdout   : output
#   return:            : unused
# https://www.gnu.org/software/gawk/manual/html_node/Strtonum-Function.html
function fnIPv6FullAddr() {
	declare       ___ADDR="${1:?}"
	declare       ___FMAT="${2:+"%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"}"
	echo "${___ADDR}" |
		awk -F '/' '{
			str=$1
			gsub("[^:]","",str)
			sep=""
			for (i=1;i<=7-length(str)+2;i++) {
				sep=sep":"
			}
			str=$1
			gsub("::",sep,str)
			split(str,arr,":")
			for (i=0;i<length(arr);i++) {
				str="0x"arr[i]
				str=substr(str,3)
				n=length(str)
				ret=0
				for (j=1;j<=n;j++){
					c=substr(str,j,1)
					c=tolower(c)
					k=index("123456789abcdef",c)
					ret=ret*16+k
				}
				num[i]=ret
			}
			printf "'"${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}"'",
				num[1],num[2],num[3],num[4],num[5],num[6],num[7],num[8]
		}'
	unset ___ADDR ___FMAT
}

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
function fnIPv6RevAddr() {
	echo "${1:?}" |
	    awk 'gsub(":","") {
	        for(i=length();i>1;i--)
	            printf("%c.", substr($0,i,1))
	            printf("%c" , substr($0,1,1))
			}'
}

# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
function fnIPv4Netmask() {
	echo "${1:?}" |
		awk -F '.' '{
			if (NF==1) {
				n=lshift(0xFFFFFFFF,32-$1)
				printf "%d.%d.%d.%d",
					and(rshift(n,24),0xFF),
					and(rshift(n,16),0xFF),
					and(rshift(n,8),0xFF),
					and(n,0xFF)
			} else {
				n=xor(0xFFFFFFFF,lshift($1,24)+lshift($2,16)+lshift($3,8)+$4)
				c=0
				while (n>0) {
					if (n%2==1) {
						c++
					}
					n=int(n/2)
				}
				printf "%d",(32-c)
			}
		}'
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
# descript: find service
#   input :     $1     : service name
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
function fnFind_serivce() {
	find "${_DIRS_TGET:-}"/lib/systemd/ "${_DIRS_TGET:-}"/usr/lib/systemd/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
}

# -----------------------------------------------------------------------------
# descript: get system parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnSystem_param() {
	declare       ___PATH=""
	if [[ -e "${_DIRS_TGET:-}"/etc/os-release ]]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
		_DIST_NAME="$(sed -ne '/^ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne '/^VERSION=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne '/^VERSION=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="${_DIST_CODE:-"$(sed -ne '/^VERSION_CODENAME=/ s/^[^=]\+="*\([^ ]\+\).*"*/\1/p'  "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"}"
#		_DIST_NAME="$(sed -ne 's/^ID=//p'                                       "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p'        "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                         "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_CODE="${_DIST_CODE:-"$(sed -ne 's/^VERSION=\".*(\(.\+\))\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"}"
	elif [[ -e "${_DIRS_TGET:-}"/etc/lsb-release ]]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
		_DIST_NAME="$(sed -ne '/^DISTRIB_ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_NAME="$(sed -ne 's/DISTRIB_ID=//p'                                     "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_VERS="$(sed -ne 's/DISTRIB_RELEASE=\"\([[:graph:]]\+\)[ \t].*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_CODE="$(sed -ne 's/^VERSION=\".*(\([[:graph:]]\+\)).*\"$/\1/p'         "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
#		_DIST_CODE="${_DIST_CODE:-"$(sed -ne 's/^VERSION=\".*(\(.\+\))\"$/\1/p'      "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"}"
	fi
#	_DIST_NAME="${_DIST_NAME#\"}"
#	_DIST_NAME="${_DIST_NAME%\"}"
	readonly _DIST_NAME
	readonly _DIST_CODE
	readonly _DIST_VERS
	unset ___PATH
}

# -----------------------------------------------------------------------------
# descript: get network parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnNetwork_param() {
	declare       ___PATH=""			# full path
	declare       ___DIRS=""			# directory
	declare       ___WORK=""			# work
	_NICS_NAME="${_NICS_NAME:-"ens160"}"
	___DIRS="${_DIRS_TGET:-}/sys/devices"
	if [[ ! -e "${___DIRS}"/. ]]; then
		fnMsgout "caution" "not exist: [${___DIRS}]"
	else
		if [[ -z "${_NICS_NAME#*"*"}" ]]; then
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | sort -V | head -n 1)"
			_NICS_NAME="${_NICS_NAME##*/}"
		fi
		_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME:-}" | sort -V | head -n 1)"
		_NICS_NAME="${_NICS_NAME##*/}"
		if [[ -z "${_NICS_NAME:-}" ]]; then
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name 'e*' | sort -V | head -n 1)"
			_NICS_NAME="${_NICS_NAME##*/}"
		fi
		if ! find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | grep -q "${_NICS_NAME}"; then
			fnMsgout "failed" "not exist: [${_NICS_NAME}]"
		else
			_NICS_MADR="${_NICS_MADR:-"$(ip -0 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			_NICS_IPV4="${_NICS_IPV4:-"$(ip -4 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			if ip -4 -oneline address show dev "${_NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
				_NICS_AUTO="dhcp"
			fi
			if [[ -z "${_NICS_DNS4:-}" ]] || [[ -z "${_NICS_WGRP:-}" ]]; then
				__PATH="$(fnFind_command 'resolvectl' | sort -V | head -n 1)"
				if [[ -n "${__PATH:-}" ]]; then
					if resolvectl status > /dev/null 2>&1; then
						_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
					fi
				fi
				___PATH="${_DIRS_TGET:-}/etc/resolv.conf"
				if [[ -e "${___PATH}" ]]; then
					_NICS_DNS4="${_NICS_DNS4:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' "${___PATH}")"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(sed -ne '/^search/     s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p'                      "${___PATH}")"}"
				fi
			fi
			_IPV6_ADDR="$(ip -6 -brief address show primary dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}')"
			_LINK_ADDR="$(ip -6 -brief address show primary dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $4;}')"
		fi
	fi
	___WORK="$(echo "${_NICS_IPV4:-}" | sed 's/[^0-9./]\+//g')"
	_NICS_IPV4="$(echo "${___WORK}/" | cut -d '/' -f 1)"
	_NICS_BIT4="$(echo "${___WORK}/" | cut -d '/' -f 2)"
	if [[ -z "${_NICS_BIT4}" ]]; then
		_NICS_BIT4="$(fnIPv4Netmask "${_NICS_MASK:-"255.255.255.0"}")"
	else
		_NICS_MASK="$(fnIPv4Netmask "${_NICS_BIT4:-"24"}")"
	fi
	_NICS_GATE="${_NICS_GATE:-"$(ip -4 -brief route list match default | awk '{print $3;}' | uniq)"}"
	if [[ -e "${_DIRS_TGET:-}/etc/hostname" ]]; then
		_NICS_FQDN="${_NICS_FQDN:-"$(cat "${_DIRS_TGET:-}/etc/hostname" || true)"}"
	fi
	__PATH="$(fnFind_command 'hostnamectl' | sort -V | head -n 1)"
	if [[ -n "${__PATH:-}" ]]; then
		_NICS_FQDN="${_NICS_FQDN:-"$(hostnamectl hostname || true)"}"
	fi
	if [[ "${_NICS_FQDN:-}" = "localhost" ]]; then
		_NICS_HOST="$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"
		_NICS_WGRP="$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"
	fi
	_NICS_FQDN="${_NICS_FQDN:-"${_DIST_NAME:+"sv-${_DIST_NAME}.workgroup"}"}"
	_NICS_FQDN="${_NICS_FQDN:-"localhost.local"}"
	_NICS_HOST="${_NICS_HOST:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"}"
	_NICS_WGRP="${_NICS_WGRP:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"}"
	_NICS_HOST="$(echo "${_NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
	_NICS_WGRP="$(echo "${_NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
	if [[ "${_NICS_FQDN}" = "${_NICS_HOST}" ]] && [[ -n "${_NICS_HOST}" ]] && [[ -n "${_NICS_WGRP}" ]]; then
		_NICS_FQDN="${_NICS_HOST}.${_NICS_WGRP}"
	fi
	_IPV6_ADDR="${_IPV6_ADDR:-"2000::0/3"}"
	_LINK_ADDR="${_LINK_ADDR:-"fe80::0/10"}"
	_IPV4_UADR="${_NICS_IPV4%.*}"
	_IPV4_LADR="${_NICS_IPV4#"${_IPV4_UADR:-"*"}."}"
	_IPV6_CIDR="${_IPV6_ADDR##*/}"
	_IPV6_ADDR="${_IPV6_ADDR%/"${_IPV6_CIDR:-"*"}"}"
	_IPV6_FADR="$(fnIPv6FullAddr "${_IPV6_ADDR:-}" "true")"
	_IPV6_UADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_IPV6_LADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_IPV6_RADR="$(fnIPv6RevAddr "${_IPV6_FADR:-}")"
	_LINK_CIDR="${_LINK_ADDR##*/}"
	_LINK_ADDR="${_LINK_ADDR%/"${_LINK_CIDR:-"*"}"}"
	_LINK_FADR="$(fnIPv6FullAddr "${_LINK_ADDR:-}" "true")"
	_LINK_UADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_LINK_LADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_LINK_RADR="$(fnIPv6RevAddr "${_LINK_FADR:-}")"
	unset ___DIRS ___PATH ___WORK
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
#	fnDbgout "system parameter" \
#		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
#		"info,_TGET_CHRT=[${_TGET_CHRT:-}]" \
#		"info,_TGET_CNTR=[${_TGET_CNTR:-}]"

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

	unset __PATH __DIRS __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}



# -----------------------------------------------------------------------------
# descript: test cmdline
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_cmdline() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __BOPT=""
	declare       __LINE=""
	# --- boot parameter selection --------------------------------------------
	__BOPT="$(cat /proc/cmdline)"
	for __LINE in ${__BOPT:-}
	do
		fnMsgout "\033[36m${_PROG_NAME:-}" "info" "${__LINE}"
	done
	unset __BOPT __LINE

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test parameter
#   input :            : unused
#   output:   stdout   : debug out
#   return:            : unused
function fnTest_param() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- system parameter ----------------------------------------------------
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_TGET_CHRT=[${_TGET_CHRT:-}]" \
		"info,_DIRS_TGET=[${_DIRS_TGET:-}]" \
		"info,_DIST_NAME=[${_DIST_NAME:-}]" \
		"info,_DIST_VERS=[${_DIST_VERS:-}]" \
		"info,_DIST_CODE=[${_DIST_CODE:-}]"

	# --- network parameter ---------------------------------------------------
	fnDbgout "network info" \
		"info,_NMAN_NAME=[${_NMAN_NAME:-}]" \
		"info,_NICS_NAME=[${_NICS_NAME:-}]" \
		"debug,_NICS_MADR=[${_NICS_MADR:-}]" \
		"info,_NICS_AUTO=[${_NICS_AUTO:-}]" \
		"info,_NICS_IPV4=[${_NICS_IPV4:-}]" \
		"info,_NICS_MASK=[${_NICS_MASK:-}]" \
		"info,_NICS_BIT4=[${_NICS_BIT4:-}]" \
		"info,_NICS_DNS4=[${_NICS_DNS4:-}]" \
		"info,_NICS_GATE=[${_NICS_GATE:-}]" \
		"info,_NICS_FQDN=[${_NICS_FQDN:-}]" \
		"debug,_NICS_HOST=[${_NICS_HOST:-}]" \
		"debug,_NICS_WGRP=[${_NICS_WGRP:-}]" \
		"debug,_NMAN_FLAG=[${_NMAN_FLAG:-}]" \
		"info,_NTPS_ADDR=[${_NTPS_ADDR:-}]" \
		"debug,_NTPS_IPV4=[${_NTPS_IPV4:-}]" \
		"debug,_NTPS_FBAK=[${_NTPS_FBAK:-}]" \
		"debug,_IPV6_LHST=[${_IPV6_LHST:-}]" \
		"debug,_IPV4_LHST=[${_IPV4_LHST:-}]" \
		"debug,_IPV4_DUMY=[${_IPV4_DUMY:-}]" \
		"debug,_IPV4_UADR=[${_IPV4_UADR:-}]" \
		"debug,_IPV4_LADR=[${_IPV4_LADR:-}]" \
		"debug,_IPV6_ADDR=[${_IPV6_ADDR:-}]" \
		"debug,_IPV6_CIDR=[${_IPV6_CIDR:-}]" \
		"debug,_IPV6_FADR=[${_IPV6_FADR:-}]" \
		"debug,_IPV6_UADR=[${_IPV6_UADR:-}]" \
		"debug,_IPV6_LADR=[${_IPV6_LADR:-}]" \
		"debug,_IPV6_RADR=[${_IPV6_RADR:-}]" \
		"debug,_LINK_ADDR=[${_LINK_ADDR:-}]" \
		"debug,_LINK_CIDR=[${_LINK_CIDR:-}]" \
		"debug,_LINK_FADR=[${_LINK_FADR:-}]" \
		"debug,_LINK_UADR=[${_LINK_UADR:-}]" \
		"debug,_LINK_LADR=[${_LINK_LADR:-}]" \
		"debug,_LINK_RADR=[${_LINK_RADR:-}]"

	# --- firewalld parameter -------------------------------------------------
	fnDbgout "firewalld info" \
		"info,_FWAL_ZONE=[${_FWAL_ZONE:-}]" \
		"debug,_FWAL_NAME=[${_FWAL_NAME:-}]" \
		"debug,_FWAL_PORT=[${_FWAL_PORT:-}]"

	# --- shared directory parameter ------------------------------------------
	fnDbgout "shared directory" \
		"info,_DIRS_TOPS=[${_DIRS_TOPS:-}]" \
		"debug,_DIRS_HGFS=[${_DIRS_HGFS:-}]" \
		"debug,_DIRS_HTML=[${_DIRS_HTML:-}]" \
		"debug,_DIRS_SAMB=[${_DIRS_SAMB:-}]" \
		"debug,_DIRS_TFTP=[${_DIRS_TFTP:-}]" \
		"debug,_DIRS_USER=[${_DIRS_USER:-}]" \
		"debug,_DIRS_PVAT=[${_DIRS_PVAT:-}]" \
		"debug,_DIRS_SHAR=[${_DIRS_SHAR:-}]" \
		"debug,_DIRS_CONF=[${_DIRS_CONF:-}]" \
		"debug,_DIRS_DATA=[${_DIRS_DATA:-}]" \
		"debug,_DIRS_KEYS=[${_DIRS_KEYS:-}]" \
		"debug,_DIRS_MKOS=[${_DIRS_MKOS:-}]" \
		"debug,_DIRS_TMPL=[${_DIRS_TMPL:-}]" \
		"debug,_DIRS_SHEL=[${_DIRS_SHEL:-}]" \
		"debug,_DIRS_IMGS=[${_DIRS_IMGS:-}]" \
		"debug,_DIRS_ISOS=[${_DIRS_ISOS:-}]" \
		"debug,_DIRS_LOAD=[${_DIRS_LOAD:-}]" \
		"debug,_DIRS_RMAK=[${_DIRS_RMAK:-}]" \
		"debug,_DIRS_CACH=[${_DIRS_CACH:-}]" \
		"debug,_DIRS_CTNR=[${_DIRS_CTNR:-}]" \
		"debug,_DIRS_CHRT=[${_DIRS_CHRT:-}]"

	# --- working directory parameter -----------------------------------------
	fnDbgout "working directory" \
		"debug,_DIRS_VADM=[${_DIRS_VADM:-}]" \
		"debug,_DIRS_INST=[${_DIRS_INST:-}]" \
		"debug,_DIRS_BACK=[${_DIRS_BACK:-}]" \
		"debug,_DIRS_ORIG=[${_DIRS_ORIG:-}]" \
		"debug,_DIRS_INIT=[${_DIRS_INIT:-}]" \
		"debug,_DIRS_SAMP=[${_DIRS_SAMP:-}]" \
		"debug,_DIRS_LOGS=[${_DIRS_LOGS:-}]" \

	# --- samba ---------------------------------------------------------------
	fnDbgout "samba info" \
		"debug,_SAMB_USER=[${_SAMB_USER:-}]" \
		"debug,_SAMB_GRUP=[${_SAMB_GRUP:-}]" \
		"debug,_SAMB_GADM=[${_SAMB_GADM:-}]" \
		"debug,_SAMB_NSSW=[${_SAMB_NSSW:-}]" \
		"debug,_SHEL_NLIN=[${_SHEL_NLIN:-}]"

	# --- auto install --------------------------------------------------------
	fnDbgout "shell info" \
		"debug,_FILE_ERLY=[${_FILE_ERLY:-}]" \
		"debug,_FILE_LATE=[${_FILE_LATE:-}]" \
		"debug,_FILE_PART=[${_FILE_PART:-}]" \
		"debug,_FILE_RUNS=[${_FILE_RUNS:-}]"

	# --- common data file (prefer non-empty current file) --------------------
	fnDbgout "common data file info" \
		"debug,_FILE_CONF=[${_FILE_CONF:-}]" \
		"debug,_FILE_DIST=[${_FILE_DIST:-}]" \
		"debug,_FILE_MDIA=[${_FILE_MDIA:-}]" \
		"debug,_FILE_DSTP=[${_FILE_DSTP:-}]"

	# --- pre-configuration file templates ------------------------------------
	fnDbgout "pre-configuration file info" \
		"debug,_FILE_KICK=[${_FILE_KICK:-}]" \
		"debug,_FILE_CLUD=[${_FILE_CLUD:-}]" \
		"debug,_FILE_SEDD=[${_FILE_SEDD:-}]" \
		"debug,_FILE_SEDU=[${_FILE_SEDU:-}]" \
		"debug,_FILE_YAST=[${_FILE_YAST:-}]" \
		"debug,_FILE_AGMA=[${_FILE_AGMA:-}]"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_service() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("wget")
	declare       __SRVC=""
	declare       __RELT=""
	declare -a    __STAT=()

	# --- test service --------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __SRVC in \
			apparmor.service auditd.service \
			firewalld.service \
			clamav-freshclam.service \
			NetworkManager.service connman.service io.netplan.Netplan.service wicked.service \
			systemd-resolved.service dnsmasq.service \
			systemd-timesyncd.service chronyd.service \
			open-vm-tools.service vmtoolsd.service \
			ssh.service sshd.service \
			apache2.service httpd.service \
			smb.service smbd.service \
			nmb.service nmbd.service \
			winbind.service \
			avahi-daemon.service
		do
			__RELT="$(systemctl is-active "${__SRVC}" || true)"
			__WORK="$(systemctl list-unit-files --type=service "${__SRVC}" | grep "${__SRVC}" || true)"
			read -r -a __STAT < <(echo "${__WORK:-"-------- -------- --------"}")
			__WORK="$(printf "%-30s:%-8s:%s" "${__SRVC:-}" "${__STAT[1]:-}" "${__STAT[2]:-}")"
			fnMsgout "\033[36m${_PROG_NAME:-}" "${__RELT}" "${__WORK:-}"
		done
	fi
	unset __SRVC __RELT __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test apparmor
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_apparmor() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("apparmor")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test apparmor -------------------------------------------------------
	if ! command -v aa-enabled > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		if ! aa-enabled > /dev/null 2>&1; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "inactive" "${__COMD[0]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "active" "${__COMD[0]}"
			if aa-status > /dev/null 2>&1; then
				if aa-status --show=processes > /dev/null 2>&1; then
					aa-status --show=processes
				else
					aa-status --verbose
				fi
			fi
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test selinux
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_selinux() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("selinux")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test selinux --------------------------------------------------------
	if ! command -v getenforce > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		if ! selinuxenabled > /dev/null 2>&1; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "inactive" "${__COMD[0]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "active" "${__COMD[0]}"
			sestatus
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test vmware
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_vmware() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("vmware")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test vmware ---------------------------------------------------------
	if ! command -v vmware-checkvm > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		if ! vmware-checkvm > /dev/null 2>&1; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "inactive" "${__COMD[0]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "active" "${__COMD[0]}"
			df -h /srv/hgfs/
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test network manager
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_netman() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- test network manager ------------------------------------------------
	  if command -v connmanctl > /dev/null 2>&1; then LANG=C connmanctl services
	elif command -v nmcli      > /dev/null 2>&1; then LANG=C nmcli --fields DEVICE,TYPE,ACTIVE,NAME,STATE,UUID,FILENAME connection show | cut -c -"${_COLS_SIZE:-80}"
	elif command -v netplan    > /dev/null 2>&1; then LANG=C netplan get all
	elif command -v networkctl > /dev/null 2>&1; then LANG=C networkctl list
	else                                              fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test port dns
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_port_dns() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("ss" "-tulpn")
	declare -r -a __COM2=("grep" "-E" ":(53)(|[ \t].*)$")

	# --- test dns port -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__COMD[*]} | ${__COM2[0]} ${__COM2[1]} '${__COM2[2]}'"
		if "${__COMD[@]:?}" | "${__COM2[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__COMD[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__COMD[*]}"
		fi
	fi
#	unset __COMD

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test port smb
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_port_smb() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("ss" "-tulpn")
	declare -r -a __COM2=("grep" "-E" ":(13[789]|445)(|[ \t].*)$")

	# --- test samba port -----------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__COMD[*]} | ${__COM2[0]} ${__COM2[1]} '${__COM2[2]}'"
		if "${__COMD[@]:?}" | "${__COM2[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__COMD[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__COMD[*]}"
		fi
	fi

#	unset __COMD __COM2

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test nslookup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_nslookup() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("nslookup")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test nslookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"${_NICS_FQDN%.*}."      \
			"${_NICS_FQDN}"          \
			"${_NICS_FQDN%.*}.local" \
			"${_NICS_IPV4}"          \
			"${_IPV6_ADDR}"          \
			"${_LINK_ADDR}"          \
			"www.google.com"
		do
			__ARRY=("${__COMD[@]}" "${__PARM}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test dig
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_dig() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("dig")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test nslookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"A,${_NICS_FQDN%.*}."         \
			"AAAA,${_NICS_FQDN%.*}."      \
			"A,${_NICS_FQDN}"             \
			"AAAA,${_NICS_FQDN}"          \
			"A,${_NICS_FQDN%.*}.local"    \
			"AAAA,${_NICS_FQDN%.*}.local" \
			"A,www.google.com"            \
			"AAAA,www.google.com"
		do
			__ARRY=("${__COMD[@]}" "${__PARM%%,*}" "${__PARM#*,}" "+nostats" "+nocomments")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
		for __PARM in \
			"${_NICS_IPV4}"               \
			"${_IPV6_ADDR}"               \
			"${_LINK_ADDR}"
		do
			__ARRY=("${__COMD[@]}" "-x" "${__PARM}" "+nostats" "+nocomments")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test getent
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_getent() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("getent")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test nslookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"${_NICS_FQDN%.*}."           \
			"${_NICS_FQDN}"               \
			"${_NICS_FQDN%.*}.local"      \
			"${_NICS_IPV4}"               \
			"${_IPV6_ADDR}"               \
			"${_LINK_ADDR}"               \
			"www.google.com"
		do
			__ARRY=("${__COMD[@]}" "hosts" "${__PARM}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test ping
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_ping() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("ping")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test ping -----------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"-4,${_NICS_FQDN}."              \
			"-6,${_NICS_FQDN}."              \
			"-4,${_NICS_HOST}."              \
			"-6,${_NICS_HOST}."              \
			"-4,${_NICS_IPV4}"               \
			"-6,${_IPV6_ADDR}"               \
			"-6,${_LINK_ADDR}%${_NICS_NAME}" \
			"-4,www.google.com"              \
			"-6,www.google.com"
		do
			__ARRY=("${__COMD[@]}" "${__PARM%%,*}" "-c" "1" "${__PARM#*,}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test timedatectl
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_timedatectl() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("timedatectl")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test timedatectl ----------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__ARRY=("${__COMD[@]}" "status")
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
		if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test chronyc
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_chronyc() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("chronyc")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test chronyc --------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__SRVC="chronyd.service"
		if ! systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "warn" "${__SRVC} not active"
		else
			__ARRY=("${__COMD[@]}" "sources")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test nmblookup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_nmblookup() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("nmblookup")
	declare       __PARM=""
	declare -a    __ARRY=()
	declare       __ADDR=""
	declare       __NAME=""
	declare       __WGRP=""

	# --- test nmblookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__NMBD="$(fnFind_serivce 'nmbd.service' 'nmb.service' | sort -V | head -n 1)"
		__SRVC="${__NMBD##*/}"
		if ! systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "warn" "${__SRVC} not active"
		else
			if ! __ADDR="$("${__COMD[0]}" -M -- - | awk '{print $1;}')"; then
				fnMsgout "${_PROG_NAME:-}" "warn" "no __MSBROWSE__"
				__ADDR="${_NICS_IPV4:-"${__ADDR:-"${_IPV4_LHST:-"127.0.0.1"}"}"}"
			else
				fnMsgout "${_PROG_NAME:-}" "info" "__MSBROWSE__: ${__ADDR}"
			fi
			if [[ -z "${__ADDR:-}" ]]; then
				fnMsgout "${_PROG_NAME:-}" "skip" "no ip address"
			else
				fnMsgout "${_PROG_NAME:-}" "info" "search: ${__ADDR}"
				__NAME="$("${__COMD[0]}" -A "${__ADDR}" | awk '$2=="<00>"&&$4!="<GROUP>" {print $1;}' || true)"
				__WGRP="$("${__COMD[0]}" -A "${__ADDR}" | awk '$2=="<00>"&&$4=="<GROUP>" {print $1;}' || true)"
				if [[ -z "${__NAME:-}" ]]; then
					fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__COMD[0]} -A ${__ADDR}"
				else
					if command -v getent > /dev/null 2>&1; then
						__ARRY=("getent" "hosts" "${__NAME,,}")
						fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
						if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
							fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
						else
							fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
						fi
					fi
					if command -v traceroute > /dev/null 2>&1; then
						__ARRY=("traceroute" "-4" "-w" "1" "-m" "1" "${__NAME,,}")
						fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
						if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
							fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
						else
							fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
						fi
						__ARRY=("traceroute" "-6" "-w" "1" "-m" "1" "${__NAME,,}")
						fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
						if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
							fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
						else
							fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
						fi
					fi
				fi
			fi
		fi
	fi
	unset __PARM __ARRY __ADDR __NAME __WGRP

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test smbclient
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_smbclient() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("smbclient")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test smbclient -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"${_NICS_FQDN%.*}."             \
			"${_NICS_FQDN}"                 \
			"${_NICS_FQDN%.*}.local"
		do
			__ARRY=("${__COMD[@]}" "-N" "-L" "${__PARM}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
		for __PARM in \
			"${_NICS_IPV4}"               \
			"${_IPV6_ADDR}"               \
			"${_LINK_ADDR}%${_NICS_NAME}"
		do
			__ARRY=("${__COMD[@]}" "-N" "-L" "${_NICS_FQDN%.*}." -I "${__PARM}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test pdbedit
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_pdbedit() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("pdbedit")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test pdbedit --------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__ARRY=("${__COMD[@]}" "-L")
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
		if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: test httpd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnTest_httpd() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("wget")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test httpd --------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__ARRY=("${__COMD[@]}" "-4" "-q" "-O" "/dev/null" "${_SRVR_HTTP:-"http"}://${_NICS_FQDN}/")
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
		if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
		fi
	fi
	unset __PARM __ARRY

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
	fnSystem_param						# get system parameter
	fnNetwork_param						# get network parameter

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
			-P|--DBGP) fnDbgparameters_all; break;;
			-T|--TREE) tree --charset C -x -a --filesfirst "${_DIRS_TOPS:-}"; break;;
			*        )
				echo "${_TEXT_GAP2:-}"
				fnTest_cmdline			# test cmdline
				echo "${_TEXT_GAP2:-}"
				fnTest_param			# test parameter
				echo "${_TEXT_GAP2:-}"
				fnTest_service			# test service
				echo "${_TEXT_GAP2:-}"
				fnTest_apparmor			# test apparmor
				echo "${_TEXT_GAP2:-}"
				fnTest_selinux			# test selinux
				echo "${_TEXT_GAP2:-}"
				fnTest_vmware			# test vmware
				echo "${_TEXT_GAP2:-}"
				fnTest_netman			# test network manager
				echo "${_TEXT_GAP2:-}"
				fnTest_port_dns			# test port dns
				echo "${_TEXT_GAP2:-}"
				fnTest_port_smb			# test port smb
				echo "${_TEXT_GAP2:-}"
				fnTest_nslookup			# test nslookup
				echo "${_TEXT_GAP2:-}"
				fnTest_dig				# test dig
				echo "${_TEXT_GAP2:-}"
				fnTest_getent			# test getent
				echo "${_TEXT_GAP2:-}"
				fnTest_ping				# test ping
				echo "${_TEXT_GAP2:-}"
				fnTest_timedatectl		# test timedatectl
				echo "${_TEXT_GAP2:-}"
				fnTest_chronyc			# test chronyc
				echo "${_TEXT_GAP2:-}"
				fnTest_nmblookup		# test nmblookup
				echo "${_TEXT_GAP2:-}"
				fnTest_smbclient		# test smbclient
				echo "${_TEXT_GAP2:-}"
				fnTest_pdbedit			# test pdbedit
				echo "${_TEXT_GAP2:-}"
				fnTest_httpd			# test httpd
				echo "${_TEXT_GAP2:-}"
				;;
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
