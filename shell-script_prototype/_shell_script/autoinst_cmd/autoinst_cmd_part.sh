#!/bin/sh

###############################################################################
#
#	autoinstall (part) shell script
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

	export LANG=C
#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	_DBGS_FLAG=""						# debug flag (empty: normal, else: debug)

	# --- working directory ---------------------------------------------------
	readonly _PROG_PATH="$0"
	readonly _PROG_PARM="${*:-}"
	readonly _PROG_DIRS="${_PROG_PATH%/*}"
	readonly _PROG_NAME="${_PROG_PATH##*/}"
#	readonly _PROG_PROC="${_PROG_NAME}.$$"

	# --- command line parameter ----------------------------------------------
									  	# command line parameter
	_COMD_LINE="$(cat /proc/cmdline || true)"
	readonly _COMD_LINE
	_NICS_NAME=""						# nic if name   (ex. ens160)
	_NICS_MADR=""						# nic if mac    (ex. 00:00:00:00:00:00)
	_NICS_AUTO=""						# ipv4 dhcp     (ex. empty or dhcp)
	_NICS_IPV4=""						# ipv4 address  (ex. 192.168.1.1)
	_NICS_MASK=""						# ipv4 netmask  (ex. 255.255.255.0)
	_NICS_BIT4=""						# ipv4 cidr     (ex. 24)
	_NICS_DNS4=""						# ipv4 dns      (ex. 192.168.1.254)
	_NICS_GATE=""						# ipv4 gateway  (ex. 192.168.1.254)
	_NICS_FQDN=""						# hostname fqdn (ex. sv-server.workgroup)
	_NICS_HOST=""						# hostname      (ex. sv-server)
	_NICS_WGRP=""						# domain        (ex. workgroup)
	_NMAN_FLAG=""						# nm_config, ifupdown, loopback
	_DIRS_TGET=""						# target directory
	_FILE_ISOS=""						# iso file name
	_FILE_SEED=""						# preseed file name
	# --- target --------------------------------------------------------------
	_TGET_VIRT=""						# virtualization (ex. vmware)
	_TGET_CNTR=""						# is container   (empty: none, else: container)
	# --- set system parameter ------------------------------------------------
	_DIST_NAME=""						# distribution name (ex. debian)
	_DIST_VERS=""						# release version   (ex. 13)
	_DIST_CODE=""						# code name         (ex. trixie)
	_ROWS_SIZE="25"						# screen size: rows
	_COLS_SIZE="80"						# screen size: columns
	_TEXT_GAP1=""						# gap1
	_TEXT_GAP2=""						# gap2
	_COMD_BBOX=""						# busybox (empty: inactive, else: active )
	_OPTN_COPY="--preserve=timestamps"	# copy option
	# --- network parameter ---------------------------------------------------
	readonly _NTPS_ADDR="ntp.nict.jp"	# ntp server address
	readonly _NTPS_IPV4="61.205.120.130" # ntp server ipv4 address
	readonly _NTPS_FBAK="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	readonly _IPV6_LHST="::1"			# ipv6 local host address
	readonly _IPV4_LHST="127.0.0.1"		# ipv4 local host address
	readonly _IPV4_DUMY="127.0.1.1"		# ipv4 dummy address
	_IPV4_UADR=""						# IPv4 address up   (ex. 192.168.1)
	_IPV4_LADR=""						# IPv4 address low  (ex. 1)
	_IPV6_ADDR=""						# IPv6 address      (ex. ::1)
	_IPV6_CIDR=""						# IPv6 cidr         (ex. 64)
	_IPV6_FADR=""						# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	_IPV6_UADR=""						# IPv6 address up   (ex. 0000:0000:0000:0000)
	_IPV6_LADR=""						# IPv6 address low  (ex. 0000:0000:0000:0001)
	_IPV6_RADR=""						# IPv6 reverse addr (ex. ...)
	_LINK_ADDR=""						# LINK address      (ex. fe80::1)
	_LINK_CIDR=""						# LINK cidr         (ex. 64)
	_LINK_FADR=""						# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	_LINK_UADR=""						# LINK address up   (ex. fe80:0000:0000:0000)
	_LINK_LADR=""						# LINK address low  (ex. 0000:0000:0000:0001)
	_LINK_RADR=""						# LINK reverse addr (ex. ...)
	# --- firewalld -----------------------------------------------------------
	readonly _FWAL_ZONE="home_use"		# firewalld default zone
										# firewalld service name
	readonly _FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
										# firewalld port
	readonly _FWAL_PORT="0-65535/tcp 0-65535/udp"
	# --- samba parameter -----------------------------------------------------
	readonly _SAMB_USER="sambauser"		# force user
	readonly _SAMB_GRUP="sambashare"	# force group
	readonly _SAMB_GADM="sambaadmin"	# admin group
										# nsswitch.conf
	readonly _SAMB_NSSW="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
	_SHEL_NLIN=""						# login shell (disallow system login to samba user)
	# --- shared directory parameter ------------------------------------------
	_DIRS_TOPS=""						# top of shared directory
	_DIRS_HGFS=""						# vmware shared
	_DIRS_HTML=""						# html contents#
	_DIRS_SAMB=""						# samba shared
	_DIRS_TFTP=""						# tftp contents
	_DIRS_USER=""						# user file
	# --- shared of user file -------------------------------------------------
	_DIRS_PVAT=""						# private contents directory
	_DIRS_SHAR=""						# shared contents directory
	_DIRS_CONF=""						# configuration file
	_DIRS_DATA=""						# data file
	_DIRS_KEYS=""						# keyring file
	_DIRS_MKOS=""						# mkosi configuration files
	_DIRS_TMPL=""						# templates for various configuration files
	_DIRS_SHEL=""						# shell script file
	_DIRS_IMGS=""						# iso file extraction destination
	_DIRS_ISOS=""						# iso file
	_DIRS_LOAD=""						# load module
	_DIRS_RMAK=""						# remake file
	_DIRS_CACH=""						# cache file
	_DIRS_CTNR=""						# container file
	_DIRS_CHRT=""						# container file (chroot)
	# --- working directory parameter -----------------------------------------
	readonly _DIRS_VADM="/var/admin"	# top of admin working directory
	_DIRS_INST=""						# auto-install working directory
	_DIRS_BACK=""						# top of backup directory
	_DIRS_ORIG=""						# original file directory
	_DIRS_INIT=""						# initial file directory
	_DIRS_SAMP=""						# sample file directory
	_DIRS_LOGS=""						# log file directory
	# --- auto install --------------------------------------------------------
	readonly _FILE_ERLY="autoinst_cmd_early.sh"	# shell commands to run early
	readonly _FILE_LATE="autoinst_cmd_late.sh"	# "              to run late
	readonly _FILE_PART="autoinst_cmd_part.sh"	# "              to run after partition
	readonly _FILE_RUNS="autoinst_cmd_run.sh"	# "              to run preseed/run
	# --- common data file (prefer non-empty current file) --------------------
#	readonly _FILE_CONF="common.cfg"			# common configuration file
#	readonly _FILE_DIST="distribution.dat"		# distribution data file
#	readonly _FILE_MDIA="media.dat"				# media data file
#	readonly _FILE_DSTP="debstrap.dat"			# debstrap data file
	# --- pre-configuration file templates ------------------------------------
#	readonly _FILE_KICK="kickstart_rhel.cfg"	# for rhel
#	readonly _FILE_CLUD="user-data_ubuntu"		# for ubuntu cloud-init
#	readonly _FILE_SEDD="preseed_debian.cfg"	# for debian
#	readonly _FILE_SEDU="preseed_ubuntu.cfg"	# for ubuntu
#	readonly _FILE_YAST="yast_opensuse.xml"		# for opensuse
#	readonly _FILE_AGMA="agama_opensuse.json"	# for opensuse

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : title (program name, etc)
#   input :     $2     : section (start, complete, remove, umount, failed, ...)
#   input :     $3     : message
#   output:   stdout   : message
#   return:            : unused
fnMsgout() {
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
fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
fnStrmsg() {
	___TXT1="$(echo "${1:-}" | cut -c -3)"
	___TXT2="$(echo "${1:-}" | cut -c "$((${#___TXT1}+2+${#2}+1))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TXT1
	unset ___TXT2
}

# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
fnTargetsys() {
	___VIRT=""
	___CNTR=""
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
fnIPv6FullAddr() {
	___ADDR="${1:?}"
	___FMAT="${2:+"%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"}"
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
}

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
fnIPv6RevAddr() {
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
fnIPv4Netmask() {
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
fnDbgout() {
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	shift
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
	while [ -n "${1:-}" ]
	do
		if [ "${1%%,*}" != "debug" ] || [ -n "${_DBGS_FLAG:-}" ]; then
			fnMsgout "${_PROG_NAME:-}" "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
}

# -----------------------------------------------------------------------------
# descript: parameter debug output
#   input :            : unused
#   output:   stdout   : debug out
#   return:            : unused
fnDbgparam() {
	[ -z "${_DBGS_PARM:-}" ] && return

	__FUNC_NAME="fnDbgout"
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
}

# -----------------------------------------------------------------------------
# descript: find command
#   input :     $1     : command name
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
fnFind_command() {
	find "${_DIRS_TGET:-}"/bin/ "${_DIRS_TGET:-}"/sbin/ "${_DIRS_TGET:-}"/usr/bin/ "${_DIRS_TGET:-}"/usr/sbin/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
}

# -----------------------------------------------------------------------------
# descript: get system parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSystem_param() {
	if [ -e "${_DIRS_TGET:-}"/etc/os-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
		_DIST_NAME="$(sed -ne 's/^ID=//p'                                "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                  "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
	elif [ -e "${_DIRS_TGET:-}"/etc/lsb-release ]; then
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
}

# -----------------------------------------------------------------------------
# descript: get network parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnNetwork_param() {
	___DIRS="${_DIRS_TGET:-}/sys/devices"
	_NICS_NAME="${_NICS_NAME:-"ens160"}"
	if [ ! -e "${___DIRS}"/. ]; then
		fnMsgout "${_PROG_NAME:-}" "caution" "not exist: [${___DIRS}]"
	else
		if [ -z "${_NICS_NAME#*"*"}" ]; then
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | sort -V | head -n 1)"
			_NICS_NAME="${_NICS_NAME##*/}"
		fi
		if ! find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | grep -q "${_NICS_NAME}"; then
			fnMsgout "${_PROG_NAME:-}" "failed" "not exist: [${_NICS_NAME}]"
		else
			_NICS_MADR="${_NICS_MADR:-"$(ip -0 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			_NICS_IPV4="${_NICS_IPV4:-"$(ip -4 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			if ip -4 -oneline address show dev "${_NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
				_NICS_AUTO="dhcp"
			fi
			if [ -z "${_NICS_DNS4:-}" ] || [ -z "${_NICS_WGRP:-}" ]; then
				__PATH="$(fnFind_command 'resolvectl' | sort -V | head -n 1)"
				if [ -n "${__PATH:-}" ]; then
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/^Global:/            s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/^Global:/            s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
				fi
				___PATH="${_DIRS_TGET:-}/etc/resolv.conf"
				if [ -e "${___PATH}" ]; then
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
	if [ -z "${_NICS_BIT4}" ]; then
		_NICS_BIT4="$(fnIPv4Netmask "${_NICS_MASK:-"255.255.255.0"}")"
	else
		_NICS_MASK="$(fnIPv4Netmask "${_NICS_BIT4:-"24"}")"
	fi
	_NICS_GATE="${_NICS_GATE:-"$(ip -4 -brief route list match default | awk '{print $3;}' | uniq)"}"
	if [ -e "${_DIRS_TGET:-}/etc/hostname" ]; then
		_NICS_FQDN="${_NICS_FQDN:-"$(cat "${_DIRS_TGET:-}/etc/hostname" || true)"}"
	fi
	_NICS_FQDN="${_NICS_FQDN:-"${_DIST_NAME:+"sv-${_DIST_NAME}.workgroup"}"}"
	_NICS_FQDN="${_NICS_FQDN:-"localhost.local"}"
	_NICS_HOST="${_NICS_HOST:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"}"
	_NICS_WGRP="${_NICS_WGRP:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"}"
	_NICS_HOST="$(echo "${_NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
	_NICS_WGRP="$(echo "${_NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
	if [ "${_NICS_FQDN}" = "${_NICS_HOST}" ] && [ -n "${_NICS_HOST}" ] && [ -n "${_NICS_WGRP}" ]; then
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
	readonly _NICS_NAME
	readonly _NICS_MADR
	readonly _NICS_IPV4
	readonly _NICS_MASK
	readonly _NICS_BIT4
	readonly _NICS_DNS4
	readonly _NICS_GATE
	readonly _NICS_FQDN
	readonly _NICS_HOST
	readonly _NICS_WGRP
	readonly _NMAN_FLAG
	readonly _NTPS_ADDR
	readonly _NTPS_IPV4
	readonly _IPV6_LHST
	readonly _IPV4_LHST
	readonly _IPV4_DUMY
	readonly _IPV4_UADR
	readonly _IPV4_LADR
	readonly _IPV6_ADDR
	readonly _IPV6_CIDR
	readonly _IPV6_FADR
	readonly _IPV6_UADR
	readonly _IPV6_LADR
	readonly _IPV6_RADR
	readonly _LINK_ADDR
	readonly _LINK_CIDR
	readonly _LINK_FADR
	readonly _LINK_UADR
	readonly _LINK_LADR
	readonly _LINK_RADR
}

# -----------------------------------------------------------------------------
# descript: file backup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
# --- file backup -------------------------------------------------------------
fnFile_backup() {
	___PATH="${1:?}"
	___MODE="${2:-}"
	# --- check ---------------------------------------------------------------
	if [ ! -e "${___PATH}" ]; then
		fnMsgout "${_PROG_NAME:-}" "caution" "not exist: [${___PATH}]"
		mkdir -p "${___PATH%/*}"
		___REAL="$(realpath --canonicalize-missing "${___PATH}")"
		if [ ! -e "${___REAL}" ]; then
			mkdir -p "${___REAL%/*}"
		fi
		: > "${___PATH}"
	fi
	# --- backup --------------------------------------------------------------
	case "${___MODE:-}" in
		samp) ___DIRS="${_DIRS_SAMP:-}";;
		init) ___DIRS="${_DIRS_INIT:-}";;
		*   ) ___DIRS="${_DIRS_ORIG:-}";;
	esac
	___DIRS="${_DIRS_TGET:-}${___DIRS}"
	___BACK="${___PATH#"${_DIRS_TGET:-}/"}"
	___BACK="${___DIRS}/${___BACK#/}"
	mkdir -p "${___BACK%/*}"
	chmod 600 "${___DIRS%/*}"
	if [ -e "${___BACK}" ] || [ -h "${___BACK}" ]; then
		___BACK="${___BACK}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	fi
	fnMsgout "${_PROG_NAME:-}" "backup" "[${___PATH}]${_DBGS_FLAG:+" -> [${___BACK}]"}"
	cp --archive "${___PATH}" "${___BACK}"
}

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnInitialize() {
	__FUNC_NAME="fnInitialize"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- set system parameter ------------------------------------------------
	if [ -n "${TERM:-}" ] \
	&& command -v tput > /dev/null 2>&1; then
		_ROWS_SIZE=$(tput lines || true)
		_COLS_SIZE=$(tput cols  || true)
	fi
	[ "${_ROWS_SIZE:-"0"}" -lt 25 ] && _ROWS_SIZE=25
	[ "${_COLS_SIZE:-"0"}" -lt 80 ] && _COLS_SIZE=80
	readonly _ROWS_SIZE
	readonly _COLS_SIZE

	__COLS="${_COLS_SIZE}"
	[ -n "${_PROG_NAME:-}" ] && __COLS=$((_COLS_SIZE-${#_PROG_NAME}-16))
	_TEXT_GAP1="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '-')"
	_TEXT_GAP2="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '=')"
	unset __COLS
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		fnMsgout "${_PROG_NAME:-}" "info" "busybox"
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi

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
		[ ! -e "${__DIRS}"/root/. ] && continue
		_DIRS_TGET="${__DIRS}"
		break
	done
	readonly _DIRS_TGET

	# --- system parameter ----------------------------------------------------
	fnSystem_param
	# --- network parameter ---------------------------------------------------
	fnNetwork_param
	# --- firewalld parameter -------------------------------------------------
	# --- shared directory parameter ------------------------------------------
	readonly _DIRS_TOPS="${_DIRS_TGET:-}/srv"			# top of shared directory
	readonly _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
	readonly _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
	readonly _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
	readonly _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	readonly _DIRS_USER="${_DIRS_TOPS}/user"			# user file
	readonly _DIRS_PVAT="${_DIRS_USER}/private"			# private contents directory
	readonly _DIRS_SHAR="${_DIRS_USER}/share"			# shared contents directory
	readonly _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
	readonly _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
	readonly _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
	readonly _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
	readonly _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
	readonly _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
	readonly _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
	readonly _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
	readonly _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
	readonly _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
	readonly _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file
	readonly _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
	readonly _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file (chroot)
	# --- working directory parameter -----------------------------------------
										# top of working directory
	_DIRS_INST="${_DIRS_VADM:?}/${_PROG_NAME%%_*}.$(date ${__time_start:+-d "@${__time_start}"} +"%Y%m%d%H%M%S")"
	readonly _DIRS_INST							# auto-install working directory
	readonly _DIRS_BACK="${_DIRS_INST}"			# top of backup directory
	readonly _DIRS_ORIG="${_DIRS_BACK}/orig"	# original file directory
	readonly _DIRS_INIT="${_DIRS_BACK}/init"	# initial file directory
	readonly _DIRS_SAMP="${_DIRS_BACK}/samp"	# sample file directory
	readonly _DIRS_LOGS="${_DIRS_BACK}/logs"	# log file directory
	mkdir -p "${_DIRS_TGET:-}${_DIRS_INST%.*}/"
	chmod 600 "${_DIRS_TGET:-}${_DIRS_VADM:?}"
	find "${_DIRS_TGET:-}${_DIRS_VADM:?}" -name "${_PROG_NAME%%_*}.[0-9]*" -type d | sort -rV | tail -n +3 | \
	while read -r __TGET
	do
		__PATH="${__TGET}.tgz"
		fnMsgout "${_PROG_NAME:-}" "archive" "[${__TGET}] -> [${__PATH}]"
		if tar -C "${__TGET}" -cf "${__PATH}" .; then
			chmod 600 "${__PATH}"
			fnMsgout "${_PROG_NAME:-}" "remove"  "${__TGET}"
			rm -rf "${__TGET:?}"
		fi
	done
	mkdir -p "${_DIRS_TGET:-}${_DIRS_INST:?}"
	chmod 600 "${_DIRS_TGET:-}${_DIRS_INST:?}"
	# --- samba ---------------------------------------------------------------
	_SHEL_NLIN="$(fnFind_command 'nologin' | sort -rV | head -n 1)"
	_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [ -e /usr/sbin/nologin ]; then echo "/usr/sbin/nologin"; fi)"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [ -e /sbin/nologin     ]; then echo "/sbin/nologin"; fi)"}"
	readonly _SHEL_NLIN
	# --- auto install --------------------------------------------------------
	# --- debug backup---------------------------------------------------------
	fnFile_backup "/proc/cmdline"
	fnFile_backup "/proc/mounts"
	fnFile_backup "/proc/self/mounts"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_BACK : read
fnMain() {
	_FUNC_NAME="fnMain"
	fnMsgout "${_PROG_NAME:-}" "start" "[${_FUNC_NAME}]"

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize
	fnDbgparam							# parameter debug output

	# --- main processing -----------------------------------------------------

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		tree --charset C -n --filesfirst "${_DIRS_BACK:-}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${_FUNC_NAME}]"
}

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- boot parameter selection --------------------------------------------
	for __LINE in ${_COMD_LINE:-} ${_PROG_PARM:-}
	do
		case "${__LINE}" in
			debug    | dbg                ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout             ) _DBGS_FLAG="true";;
			target=*                      ) _DIRS_TGET="${__LINE#*target=}";;
			iso-url=*.iso  | url=*.iso    ) _FILE_ISOS="${__LINE#*url=}";;
			preseed/url=*  | url=*        ) _FILE_SEED="${__LINE#*url=}";;
			preseed/file=* | file=*       ) _FILE_SEED="${__LINE#*file=}";;
			ds=nocloud*                   ) _FILE_SEED="${__LINE#*ds=nocloud*=}";_FILE_SEED="${_FILE_SEED%%/}/user-data";;
			inst.ks=*                     ) _FILE_SEED="${__LINE#*inst.ks=}";;
			autoyast=*                    ) _FILE_SEED="${__LINE#*autoyast=}";;
			inst.auto=*                   ) _FILE_SEED="${__LINE#*inst.auto=}";;
			netcfg/target_network_config=*) _NMAN_FLAG="${__LINE#*target_network_config=}";;
			netcfg/choose_interface=*     ) _NICS_NAME="${__LINE#*choose_interface=}";;
			netcfg/disable_dhcp=*         ) _IPV4_DHCP="$([ "${__LINE#*disable_dhcp=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/disable_autoconfig=*   ) _IPV4_DHCP="$([ "${__LINE#*disable_autoconfig=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/get_ipaddress=*        ) _NICS_IPV4="${__LINE#*get_ipaddress=}";;
			netcfg/get_netmask=*          ) _NICS_MASK="${__LINE#*get_netmask=}";;
			netcfg/get_gateway=*          ) _NICS_GATE="${__LINE#*get_gateway=}";;
			netcfg/get_nameservers=*      ) _NICS_DNS4="${__LINE#*get_nameservers=}";;
			netcfg/get_hostname=*         ) _NICS_FQDN="${__LINE#*get_hostname=}";;
			netcfg/get_domain=*           ) _NICS_WGRP="${__LINE#*get_domain=}";;
			interface=*                   ) _NICS_NAME="${__LINE#*interface=}";;
			hostname=*                    ) _NICS_FQDN="${__LINE#*hostname=}";;
			domain=*                      ) _NICS_WGRP="${__LINE#*domain=}";;
			nameserver=*                  ) _NICS_DNS4="${__LINE#*nameserver=}";;
			ip=dhcp | ip4=dhcp | ipv4=dhcp) _IPV4_DHCP="true";;
			ip=* | ip4=* | ipv4=*         ) _IPV4_DHCP="false"
			                                _NICS_IPV4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 1)"
			                                _NICS_GATE="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 3)"
			                                _NICS_MASK="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 4)"
			                                _NICS_FQDN="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 5)"
			                                _NICS_NAME="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 6)"
			                                _NICS_DNS4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 8)"
			                                ;;
			ifcfg=*                       ) _NICS_NAME="$(echo "${__LINE#*ifcfg*=}" | cut -d '=' -f 1)"
			                                _NICS_IPV4="$(echo "${__LINE#*=*=}" | cut -d ',' -f 1)"
			                                case "${_NICS_IPV4:-}" in
			                                     dhcp6)
			                                        _IPV4_DHCP=""
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     dhcp|dhcp4)
			                                        _IPV4_DHCP="true"
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     *)
			                                        _IPV4_DHCP="false"
			                                        _NICS_IPV4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 1)"
			                                        _NICS_GATE="$(echo "${__LINE#*=*=}," | cut -d ',' -f 2)"
			                                        _NICS_DNS4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 3)"
			                                        _NICS_WGRP="$(echo "${__LINE#*=*=}," | cut -d ',' -f 4)"
			                                        ;;
			                                esac
			                                ;;
			*) ;;
		esac
	done

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
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
