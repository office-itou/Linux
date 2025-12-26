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
#	2025/11/01 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#	            : shellcheck -o all -e SC2154 *.sh
#
###############################################################################

# *** global section **********************************************************

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
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
	while [[ -n "${1:-}" ]]
	do
		if [[ "${1%%,*}" != "debug" ]] || [[ -n "${_DBGS_FLAG:-}" ]]; then
			fnMsgout "${_PROG_NAME:-}" "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
	unset ___STRT
	unset ___ENDS
}

# -----------------------------------------------------------------------------
# descript: dump output (debug out)
#   input :     $1     : path
#   output:   stdout   : message
#   return:            : unused
function fnDbgdump() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	if [[ ! -e "${1:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "not exist: [${1:-}]"
		return
	fi
	declare       ___STRT=""
	declare       ___ENDS=""
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
	cat "${1:-}"
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
	unset ___STRT
	unset ___ENDS
}

# -----------------------------------------------------------------------------
# descript: parameter debug output
#   input :            : unused
#   output:   stdout   : debug out
#   return:            : unused
function fnDbgparam() {
	[[ -z "${_DBGS_PARM:-}" ]] && return

	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- system parameter ----------------------------------------------------
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_TGET_CNTR=[${_TGET_CNTR:-}]" \
		"info,_DIRS_TGET=[${_DIRS_TGET:-}]" \
		"info,_DIST_NAME=[${_DIST_NAME:-}]" \
		"info,_DIST_VERS=[${_DIST_VERS:-}]" \
		"info,_DIST_CODE=[${_DIST_CODE:-}]"

	# --- network parameter ---------------------------------------------------
	fnDbgout "network info" \
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
	find "${_DIRS_TGET:-}"/lib/systemd/system/ "${_DIRS_TGET:-}"/usr/lib/systemd/system/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
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
		_DIST_NAME="$(sed -ne 's/^ID=//p'                                "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                  "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
	elif [[ -e "${_DIRS_TGET:-}"/etc/lsb-release ]]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
		_DIST_NAME="$(sed -ne 's/DISTRIB_ID=//p'                                     "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne 's/DISTRIB_RELEASE=\"\([[:graph:]]\+\)[ \t].*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne 's/^VERSION=\".*(\([[:graph:]]\+\)).*\"$/\1/p'         "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
	fi
	_DIST_NAME="${_DIST_NAME#\"}"
	_DIST_NAME="${_DIST_NAME%\"}"
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
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/^Global:/            s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/^Global:/            s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
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

# -----------------------------------------------------------------------------
# descript: file backup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
# --- file backup -------------------------------------------------------------
function fnFile_backup() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __BKUP_MODE="${2:-}"
	declare       ___REAL=""
	declare       ___DIRS=""
	declare       ___BACK=""
	# --- check ---------------------------------------------------------------
	if [[ ! -e "${__TGET_PATH}" ]]; then
		fnMsgout "caution" "not exist: [${__TGET_PATH}]"
		mkdir -p "${__TGET_PATH%/*}"
		___REAL="$(realpath --canonicalize-missing "${__TGET_PATH}")"
		if [[ ! -e "${___REAL}" ]]; then
			mkdir -p "${___REAL%/*}"
		fi
		: > "${__TGET_PATH}"
	fi
	# --- backup --------------------------------------------------------------
	case "${__BKUP_MODE:-}" in
		samp) ___DIRS="${_DIRS_SAMP:-}";;
		init) ___DIRS="${_DIRS_INIT:-}";;
		*   ) ___DIRS="${_DIRS_ORIG:-}";;
	esac
	___DIRS="${_DIRS_TGET:-}${___DIRS}"
	___BACK="${__TGET_PATH#"${_DIRS_TGET:-}/"}"
	___BACK="${___DIRS}/${___BACK#/}"
	mkdir -p "${___BACK%/*}"
	chmod 600 "${___DIRS%/*}"
	if [[ -e "${___BACK}" ]] || [[ -h "${___BACK}" ]]; then
		___BACK="${___BACK}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	fi
	fnMsgout "backup" "[${__TGET_PATH}]${_DBGS_FLAG:+" -> [${___BACK}]"}"
	cp --archive "${__TGET_PATH}" "${___BACK}"
	unset ___REAL ___DIRS ___BACK
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
# descript: set default common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnList_conf_Set() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __WORK=""				# work

	__WORK="$(date +"%Y/%m/%d %H:%M:%S")"
	IFS= mapfile -d $'\n' -t _LIST_CONF < <(cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		###############################################################################
		#
		#   common configuration file
		#
		#   developer   : J.Itou
		#   release     : 2025/11/01
		#
		#   history     :
		#      data    version    developer     point
		#   ---------- -------- --------------- ---------------------------------------
		#   2025/11/01 000.0000 J.Itou          first release
		#   ${__WORK:-"xxxx/xx/xx xxx.xxxx"} J.Itou          application output
		#
		###############################################################################

		# === for server environments =================================================

		# --- shared directory parameter ----------------------------------------------
		$(printf "%-39s %s" "DIRS_TOPS=\"${_DIRS_TOPS:-"/srv"}\""                    "# top of shared directory")
		$(printf "%-39s %s" "DIRS_HGFS=\"${_DIRS_HGFS:-":_DIRS_TOPS_:/hgfs"}\""      "# vmware shared"          )
		$(printf "%-39s %s" "DIRS_HTML=\"${_DIRS_HTML:-":_DIRS_TOPS_:/http/html"}\"" "# html contents"          )
		$(printf "%-39s %s" "DIRS_SAMB=\"${_DIRS_SAMB:-":_DIRS_TOPS_:/samba"}\""     "# samba shared"           )
		$(printf "%-39s %s" "DIRS_TFTP=\"${_DIRS_TFTP:-":_DIRS_TOPS_:/tftp"}\""      "# tftp contents"          )
		$(printf "%-39s %s" "DIRS_USER=\"${_DIRS_USER:-":_DIRS_TOPS_:/user"}\""      "# user file"              )

		# --- shared of user file -----------------------------------------------------
		$(printf "%-39s %s" "DIRS_SHAR=\"${_DIRS_SHAR:-":_DIRS_USER_:/share"}\""      "# shared of user file"                      )
		$(printf "%-39s %s" "DIRS_CONF=\"${_DIRS_CONF:-":_DIRS_SHAR_:/conf"}\""       "# configuration file"                       )
		$(printf "%-39s %s" "DIRS_DATA=\"${_DIRS_DATA:-":_DIRS_CONF_:/_data"}\""      "# data file"                                )
		$(printf "%-39s %s" "DIRS_KEYS=\"${_DIRS_KEYS:-":_DIRS_CONF_:/_keyring"}\""   "# keyring file"                             )
		$(printf "%-39s %s" "DIRS_MKOS=\"${_DIRS_MKOS:-":_DIRS_CONF_:/_mkosi"}\""     "# mkosi configuration files"                )
		$(printf "%-39s %s" "DIRS_TMPL=\"${_DIRS_TMPL:-":_DIRS_CONF_:/_template"}\""  "# templates for various configuration files")
		$(printf "%-39s %s" "DIRS_SHEL=\"${_DIRS_SHEL:-":_DIRS_CONF_:/script"}\""     "# shell script file"                        )
		$(printf "%-39s %s" "DIRS_IMGS=\"${_DIRS_IMGS:-":_DIRS_SHAR_:/imgs"}\""       "# iso file extraction destination"          )
		$(printf "%-39s %s" "DIRS_ISOS=\"${_DIRS_ISOS:-":_DIRS_SHAR_:/isos"}\""       "# iso file"                                 )
		$(printf "%-39s %s" "DIRS_LOAD=\"${_DIRS_LOAD:-":_DIRS_SHAR_:/load"}\""       "# load module"                              )
		$(printf "%-39s %s" "DIRS_RMAK=\"${_DIRS_RMAK:-":_DIRS_SHAR_:/rmak"}\""       "# remake file"                              )
		$(printf "%-39s %s" "DIRS_CACH=\"${_DIRS_CACH:-":_DIRS_SHAR_:/cache"}\""      "# cache file"                               )
		$(printf "%-39s %s" "DIRS_CTNR=\"${_DIRS_CTNR:-":_DIRS_SHAR_:/containers"}\"" "# container file"                           )
		$(printf "%-39s %s" "DIRS_CHRT=\"${_DIRS_CHRT:-":_DIRS_SHAR_:/chroot"}\""     "# container file (chroot)"                  )

		# --- common data file (prefer non-empty current file) ------------------------
		$(printf "%-39s %s" "FILE_CONF=\"${_FILE_CONF:-"common.cfg"}\""                  "# common configuration file")
		$(printf "%-39s %s" "FILE_DIST=\"${_FILE_DIST:-"distribution.dat"}\""            "# distribution data file"   )
		$(printf "%-39s %s" "FILE_MDIA=\"${_FILE_MDIA:-"media.dat"}\""                   "# media data file"          )
		$(printf "%-39s %s" "FILE_DSTP=\"${_FILE_DSTP:-"debstrap.dat"}\""                "# debstrap data file"       )
		$(printf "%-39s %s" "PATH_CONF=\"${_PATH_CONF:-":_DIRS_DATA_:/:_FILE_CONF_:"}\"" "# common configuration file")
		$(printf "%-39s %s" "PATH_DIST=\"${_PATH_DIST:-":_DIRS_DATA_:/:_FILE_DIST_:"}\"" "# distribution data file"   )
		$(printf "%-39s %s" "PATH_MDIA=\"${_PATH_MDIA:-":_DIRS_DATA_:/:_FILE_MDIA_:"}\"" "# media data file"          )
		$(printf "%-39s %s" "PATH_DSTP=\"${_PATH_DSTP:-":_DIRS_DATA_:/:_FILE_DSTP_:"}\"" "# debstrap data file"       )

		# --- pre-configuration file templates ----------------------------------------
		$(printf "%-39s %s" "FILE_KICK=\"${_FILE_KICK:-"kickstart_rhel.cfg"}\""          "# for rhel"             )
		$(printf "%-39s %s" "FILE_CLUD=\"${_FILE_CLUD:-"user-data_ubuntu"}\""            "# for ubuntu cloud-init")
		$(printf "%-39s %s" "FILE_SEDD=\"${_FILE_SEDD:-"preseed_debian.cfg"}\""          "# for debian"           )
		$(printf "%-39s %s" "FILE_SEDU=\"${_FILE_SEDU:-"preseed_ubuntu.cfg"}\""          "# for ubuntu"           )
		$(printf "%-39s %s" "FILE_YAST=\"${_FILE_YAST:-"yast_opensuse.xml"}\""           "# for opensuse"         )
		$(printf "%-39s %s" "FILE_AGMA=\"${_FILE_AGMA:-"agama_opensuse.json"}\""         "# for opensuse"         )
		$(printf "%-39s %s" "PATH_KICK=\"${_PATH_KICK:-":_DIRS_TMPL_:/:_FILE_KICK_:"}\"" "# for rhel"             )
		$(printf "%-39s %s" "PATH_CLUD=\"${_PATH_CLUD:-":_DIRS_TMPL_:/:_FILE_CLUD_:"}\"" "# for ubuntu cloud-init")
		$(printf "%-39s %s" "PATH_SEDD=\"${_PATH_SEDD:-":_DIRS_TMPL_:/:_FILE_SEDD_:"}\"" "# for debian"           )
		$(printf "%-39s %s" "PATH_SEDU=\"${_PATH_SEDU:-":_DIRS_TMPL_:/:_FILE_SEDU_:"}\"" "# for ubuntu"           )
		$(printf "%-39s %s" "PATH_YAST=\"${_PATH_YAST:-":_DIRS_TMPL_:/:_FILE_YAST_:"}\"" "# for opensuse"         )
		$(printf "%-39s %s" "PATH_AGMA=\"${_PATH_AGMA:-":_DIRS_TMPL_:/:_FILE_AGMA_:"}\"" "# for opensuse"         )

		# --- shell script ------------------------------------------------------------
		$(printf "%-39s %s" "FILE_ERLY=\"${_FILE_ERLY:-"autoinst_cmd_early.sh"}\""       "# shell commands to run early"           )
		$(printf "%-39s %s" "FILE_LATE=\"${_FILE_LATE:-"autoinst_cmd_late.sh"}\""        "# \"              to run late"           )
		$(printf "%-39s %s" "FILE_PART=\"${_FILE_PART:-"autoinst_cmd_part.sh"}\""        "# \"              to run after partition")
		$(printf "%-39s %s" "FILE_RUNS=\"${_FILE_RUNS:-"autoinst_cmd_run.sh"}\""         "# \"              to run preseed/run"    )
		$(printf "%-39s %s" "PATH_ERLY=\"${_PATH_ERLY:-":_DIRS_SHEL_:/:_FILE_ERLY_:"}\"" "# shell commands to run early"           )
		$(printf "%-39s %s" "PATH_LATE=\"${_PATH_LATE:-":_DIRS_SHEL_:/:_FILE_LATE_:"}\"" "# \"              to run late"           )
		$(printf "%-39s %s" "PATH_PART=\"${_PATH_PART:-":_DIRS_SHEL_:/:_FILE_PART_:"}\"" "# \"              to run after partition")
		$(printf "%-39s %s" "PATH_RUNS=\"${_PATH_RUNS:-":_DIRS_SHEL_:/:_FILE_RUNS_:"}\"" "# \"              to run preseed/run"    )

		# --- tftp / web server network parameter -------------------------------------
		$(printf "%-39s %s" "SRVR_HTTP=\"${_SRVR_HTTP:-"http"}\""              "# server connection protocol (http or https)"                                                     )
		$(printf "%-39s %s" "SRVR_PROT=\"${_SRVR_PROT:-"http"}\""              "# server connection protocol (http or tftp)"                                                      )
		$(printf "%-39s %s" "SRVR_NICS=\"${_SRVR_NICS:-"ens160"}\""            "# network device name   (ex. ens160)            (Set execution server setting to empty variable.)")
		$(printf "%-39s %s" "SRVR_MADR=\"${_SRVR_MADR:-"00:00:00:00:00:00"}\"" "#                mac    (ex. 00:00:00:00:00:00)"                                                  )
		$(printf "%-39s %s" "SRVR_ADDR=\"${_SRVR_ADDR:-"192.168.1.14"}\""      "# IPv4 address          (ex. 192.168.1.11)"                                                       )
		$(printf "%-39s %s" "SRVR_CIDR=\"${_SRVR_CIDR:-"24"}\""                "# IPv4 cidr             (ex. 24)"                                                                 )
		$(printf "%-39s %s" "SRVR_MASK=\"${_SRVR_MASK:-"255.255.255.0"}\""     "# IPv4 subnetmask       (ex. 255.255.255.0)"                                                      )
		$(printf "%-39s %s" "SRVR_GWAY=\"${_SRVR_GWAY:-"192.168.1.254"}\""     "# IPv4 gateway          (ex. 192.168.1.254)"                                                      )
		$(printf "%-39s %s" "SRVR_NSVR=\"${_SRVR_NSVR:-"192.168.1.254"}\""     "# IPv4 nameserver       (ex. 192.168.1.254)"                                                      )
		$(printf "%-39s %s" "SRVR_UADR=\"${_SRVR_UADR:-"192.168.1"}\""         "# IPv4 address up       (ex. 192.168.1)"                                                          )

		# === for creations ===========================================================

		# --- network parameter -------------------------------------------------------
		$(printf "%-39s %s" "NWRK_HOST=\"${_NWRK_HOST:-"sv-:_DISTRO_:"}\""  "# hostname              (ex. sv-server)"                                              )
		$(printf "%-39s %s" "NWRK_WGRP=\"${_NWRK_WGRP:-"workgroup"}\""      "# domain                (ex. workgroup)"                                              )
		$(printf "%-39s %s" "NICS_NAME=\"${_NICS_NAME:-"ens160"}\""         "# network device name   (ex. ens160)"                                                 )
		$(printf "%-39s %s" "NICS_MADR=\"${_NICS_MADR:-""}\""               "#                mac    (ex. 00:00:00:00:00:00)"                                      )
		$(printf "%-39s %s" "IPV4_ADDR=\"${_IPV4_ADDR:-"192.168.1.1"}\""    "# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)"                          )
		$(printf "%-39s %s" "IPV4_CIDR=\"${_IPV4_CIDR:-"24"}\""             "# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)")
		$(printf "%-39s %s" "IPV4_MASK=\"${_IPV4_MASK:-"255.255.255.0"}\""  "# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)"                     )
		$(printf "%-39s %s" "IPV4_GWAY=\"${_IPV4_GWAY:-"192.168.1.254"}\""  "# IPv4 gateway          (ex. 192.168.1.254)"                                          )
		$(printf "%-39s %s" "IPV4_NSVR=\"${_IPV4_NSVR:-"192.168.1.254"}\""  "# IPv4 nameserver       (ex. 192.168.1.254)"                                          )
		$(printf "%-39s %s" "IPV4_UADR=\"${_IPV4_UADR:-""}\""               "# IPv4 address up       (ex. 192.168.1)"                                              )
		$(printf "%-39s %s" "NMAN_NAME=\"${_NMAN_NAME:-""}\""               "# network manager name  (nm_config, ifupdown, loopback)"                              )
		$(printf "%-39s %s" "NTPS_ADDR=\"${_NTPS_ADDR:-"ntp.nict.jp"}\""    "# ntp server address    (ntp.nict.jp)"                                                )
		$(printf "%-39s %s" "NTPS_IPV4=\"${_NTPS_IPV4:-"61.205.120.130"}\"" "# ntp server ipv4 addr  (61.205.120.130)"                                             )

		# --- menu parameter ----------------------------------------------------------
		$(printf "%-39s %s" "MENU_TOUT=\"${_MENU_TOUT:-"5"}\""          "# timeout (sec)"                                 )
		$(printf "%-39s %s" "MENU_RESO=\"${_MENU_RESO:-"854x480"}\""    "# resolution (widht x hight)"                    )
		$(printf "%-39s %s" "MENU_DPTH=\"${_MENU_DPTH:-"16"}\""         "# colors"                                        )
		$(printf "%-39s %s" "MENU_MODE=\"${_MENU_MODE:-"864"}\""        "# screen mode (vga=nnn)"                         )
		$(printf "%-39s %s" "MENU_SPLS=\"${_MENU_SPLS:-"splash.png"}\"" "# splash file"                                   )
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"1280x720"}\""  "# resolution (widht x hight): 16:9"              )
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"854x480"}\""   "# \"                         : 16:9 (for vmware)")
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"1024x768"}\""  "# \"                         :  4:3"             )
		$(printf "%-39s %s" "#MENU_DPTH=\"${_MENU_DPTH:-"16"}\""        "# colors"                                        )
		$(printf "%-39s %s" "#MENU_MODE=\"${_MENU_MODE:-"864"}\""       "# screen mode (vga=nnn)"                         )

		# === for mkosi ===============================================================

		# --- mkosi output image format type ------------------------------------------
		$(printf "%-39s %s" "MKOS_TGET=\"${_MKOS_TGET:-"directory"}\"" "# format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)")

		# --- live media parameter ----------------------------------------------------
		$(printf "%-39s %s" "LIVE_DIRS=\"${_LIVE_DIRS:-"LiveOS"}\""       "# live / LiveOS"                     )
		$(printf "%-39s %s" "LIVE_SQFS=\"${_LIVE_SQFS:-"squashfs.img"}\"" "# filesystem.squashfs / squashfs.img")

		### eof #######################################################################
_EOT_
	)
	unset __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: encoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnList_conf_Enc() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	declare       __VALU=""				# setting value
	declare       __CMNT=""				# comment
	declare       __WNAM=""				# work: variable name
	declare       __WVAL=""				# work: setting value
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare -a    __LIST=()				# work
	declare -a    __ARRY=()				# work
	declare -i    I=0					# work
	declare -i    J=0					# work

	__ARRY=()
	for I in $(printf "%d\n" "${!_LIST_CONF[@]}" | sort -rV)
	do
		__LINE="${_LIST_CONF[I]:-}"
		__NAME="${__LINE%%[^_[:alnum:]]*}"
		[[ -z "${__NAME:-}" ]] && continue
		case "${__NAME}" in
			PATH_*     ) ;;
			DIRS_*     ) ;;
			FILE_*     ) ;;
			*          ) continue;;
		esac
		__ARRY+=("${__NAME}")
	done
	__LIST=()
	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]:-}"
		__LIST+=("${__LINE:-}")
		# comments with "#" do not work
		# --- get variable name -----------------------------------------------
		__NAME="${__LINE%%[^_[:alnum:]]*}"
		# --- get setting value -----------------------------------------------
		__VALU="${__LINE#"${__NAME:-}="}"
		__VALU="${__VALU%"#${__VALU##*#}"}"
		__VALU="${__VALU#"${__VALU%%[^"${IFS}"]*}"}"	# ltrim
		__VALU="${__VALU%"${__VALU##*[^"${IFS}"]}"}"	# rtrim
		# --- get comment -----------------------------------------------------
		__CMNT="${__LINE#"${__NAME:+"${__NAME}="}${__VALU:-}"}"
		__CMNT="${__CMNT#"${__CMNT%%[^"${IFS}"]*}"}"	# ltrim
		__CMNT="${__CMNT%"${__CMNT##*[^"${IFS}"]}"}"	# rtrim
		# --- store in a variable ---------------------------------------------
		case "${__CMNT:-}" in
			*"application output"*)
				__LIST+=("#   $(date +"%Y/%m/%d %H:%M:%S") J.Itou          application output")
				continue
				;;
			*) ;;
		esac
		[[ -z "${__NAME:-}" ]] && continue
		case "${__NAME}" in
			PATH_*     ) ;;
			DIRS_*     ) ;;
			FILE_*     ) ;;
			*          ) continue;;
		esac
		__WNAM="_${__NAME}"
		__VALU="${!__WNAM:-}"
		# --- setting value conversion ----------------------------------------
		for J in "${!__ARRY[@]}"
		do
			__WNAM="${__ARRY[J]}"
			case "${__WNAM}" in
				"${__NAME}") continue;;
				PATH_*     ) ;;
				DIRS_*     ) ;;
				FILE_*     ) ;;
				*          ) continue;;
			esac
			__WORK="_${__WNAM}"
			__WVAL="${!__WORK:-}"
			__WVAL="${__WVAL#\"}"
			__WVAL="${__WVAL%\"}"
			[[ -z "${__WVAL:-}" ]] && continue
			__VALU="${__VALU//"${__WVAL}"/"${__WNAM:+":_${__WNAM}_:"}"}"
		done
		__LIST[${#__LIST[@]}-1]="$(printf "%-39s %s" "${__NAME:-}=\"${__VALU:-}\"" "${__CMNT:-}")"
	done
	_LIST_CONF=("${__LIST[@]}")
	unset __NAME __VALU __CMNT __WNAM __WVAL __WORK __LINE __LIST __ARRY I J

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: decoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
function fnList_conf_Dec() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	declare       __VALU=""				# setting value
	declare       __CMNT=""				# comment
	declare       __WNAM=""				# work: variable name
	declare       __WVAL=""				# work: setting value
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare -i    I=0					# work

	_LIST_PARM=()
	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]}"
		# comments with "#" do not work
		__NAME="${__LINE%%[^_[:alnum:]]*}"
		__VALU="${__LINE#"${__NAME:-}="}"
		__CMNT="${__VALU#"${__VALU%%\#*}"}"
		__CMNT="${__CMNT#"${__CMNT%%[^"${IFS}"]*}"}"	# ltrim
		__CMNT="${__CMNT%"${__CMNT##*[^"${IFS}"]}"}"	# rtrim
		__VALU="${__VALU%"${__CMNT:-}"}"
		__VALU="${__VALU#"${__VALU%%[^"${IFS}"]*}"}"	# ltrim
		__VALU="${__VALU%"${__VALU##*[^"${IFS}"]}"}"	# rtrim
		# --- store in a variable ---------------------------------------------
		[[ -z "${__NAME:-}" ]] && continue
		__WNAM="${__NAME:-}"
		__NAME="_${__WNAM:-}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		# --- setting value conversion ----------------------------------------
		case "${__WNAM}" in
			PATH_*     | \
			DIRS_*     | \
			FILE_*     )
				while true
				do
					__WNAM="${__VALU#"${__VALU%%:_[[:alnum:]]*_[[:alnum:]]*_:*}"}"
					__WNAM="${__WNAM%"${__WNAM##*:_[[:alnum:]]*_[[:alnum:]]*_:}"}"
					__WNAM="${__WNAM%%[^:_[:alnum:]]*}"
					__WNAM="${__WNAM#:_}"
					__WNAM="${__WNAM%_:}"
					[[ -z "${__WNAM:-}" ]] && break
					__VALU="${__VALU/":_${__WNAM}_:"/"\${_${__WNAM}}"}"
				done
				;;
			*) ;;
		esac
		read -r "${__NAME:?}" < <(eval echo "${__VALU}" || true)
		_LIST_PARM+=("${__NAME}=${!__NAME}")
	done
	unset __NAME __VALU __CMNT __WNAM __WVAL __WORK __LINE I

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
	done < <(printf "%s\n" "${_LIST_CONF[@]:-}" | grep -E '^[[:alnum:]]+_[[:alnum:]]+=')

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: put common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
function fnList_conf_Put() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	printf "%s\n" "${_LIST_CONF[@]}" | awk -v list="${_LIST_PARM[*]}" '
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
					sub(/^=*/, "", _valu)
					sub(/ *$/, "", _valu)
					for (j in _parm) {
						_wnam=_parm[j]
						sub(/=.*$/, "", _wnam)
						_wval=_parm[j]
						sub(_wnam, "", _wval)
						sub(/^=/, "", _wval)
						_work=_wnam
						sub(/^_/, "", _work)
						if (_work != _name) {
							gsub(_wval, ":_"_work"_:", _valu)
						}
					}
					_line=sprintf("%-39s %s",_name"="_valu, _cmnt)
				}
				printf "%s\n", _line
			} while ((getline) > 0)
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
	chmod ugo-x "${__TGET_PATH}"
#	unset __TGET_PATH
}

# -----------------------------------------------------------------------------
# descript: make nocloud
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
function fnMk_preconf_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name

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
	chmod ugo-x "${__TGET_PATH%/*}"/*
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
	chmod ugo-x "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	unset __VERS __NUMS __NAME __SECT __ADDR __WORK
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
	chmod ugo-x "${__TGET_PATH}"
	unset __VERS __NUMS __WORK
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
	chmod ugo-x "${__TGET_PATH}" "${__WORK}"
	unset __VERS __NUMS __PDCT __PDID __WORK
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
							if [[ -n "$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")" ]]; then
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
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# data array
	declare -i    __TABS=0				# tab count
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -qd "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare -r    __DOVL="${__TEMP}/overlay"				# overlay
	declare -r    __DUPR="${__DOVL}/upper"					# upperdir
	declare -r    __DLOW="${__DOVL}/lower"					# lowerdir
	declare -r    __DWKD="${__DOVL}/work"					# workdir
	declare -r    __DMRG="${__DOVL}/merged"					# merged
	declare       __WORK=""
	declare       __FKNL=""
	declare       __FIRD=""
	declare       __HOST=""
	declare       __CIDR=""
	declare -r    __BOPT=()
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
		[[ -z "${__PTRN["${__TYPE:-}"]:-}" ]] && continue
		__TGID="${__PTRN["${__TYPE:-}"]// /|}"
		fnMk_print_list __LINE "${__TYPE:-}" "${__TGID:-}"
		IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
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
									if [[ -n "$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")" ]]; then
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
							mount -r "${__MDIA[$((_OSET_MDIA+14))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount -t overlay overlay -o lowerdir="${__DLOW}",upperdir="${__DUPR}",workdir="${__DWKD}" "${__DMRG}" && _LIST_RMOV+=("${__DMRG:?}")
							# --- create auto install configuration file ------
							__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
							IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
							__FNAM="${__MDIA[$((_OSET_MDIA+14))]##*/}"
							__TSMP="${__MDIA[$((_OSET_MDIA+15))]:+" (${__MDIA[$((_OSET_MDIA+15))]//%20/ })"}"
							__FKNL="${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}"
							__FIRD="${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}"
							case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
								*-mini-*) __FIRD="${__FIRD%/*}/${_MINI_IRAM:?}";;
								*       ) ;;
							esac
							__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
							case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
								ubuntu*) __CIDR="";;
								*      ) __CIDR="/${_IPV4_CIDR:-}";;
							esac
							fnMk_isofile_grub "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							fnMk_isofile_ilnx "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							# --- rebuild -------------------------------------
							__LABL="$(blkid -o value -s PTTYPE "${__MDIA[$((_OSET_MDIA+14))]}")"
							case "${_LABL:-}" in
								dos) ;;
								gpt)
									__FMBR="${__DWRK}/mbr.img"
									__FEFI="${__DWRK}/efi.img"
									__WORK="$(fdisk -l "${__MDIA[$((_OSET_MDIA+14))]}" 2>&1 | awk '$6~/EFI|ef/ {print $2, $4;}')"
									read -r  __SKIP __SIZE < <(echo "${__WORK:-}")
									dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=1 count=446 of="${__FMBR}" > /dev/null 2>&1
									dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${__FEFI}" > /dev/null 2>&1
									;;
								*  ) ;;
							esac
							__FCAT="$(find "${__DMRG}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \))"
							__FBIN="$(find "${__DMRG}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \))"
							fnMk_isofile_rebuild "${__DMRG}" "${__MDIA[$((_OSET_MDIA+18))]}" "${__MDIA[$((_OSET_MDIA+17))]}" "${__FMBR:-}" "${__FEFI:-}" "${__FCAT:-}" "${__FBIN:-}"
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

	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			-h|--help             ) fnHelp; break;;
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

	# --- main processing -----------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################
