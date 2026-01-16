#!/bin/sh

###############################################################################
#
#	autoinstall (late) shell script
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
	_DBGS_PARM="true"					# debug flag (empty: normal, else: debug out parameter)
	if [ -n "${debug:-}" ] || [ -n "${debugout:-}" ]; then
		_DBGS_FLAG="true"
		[ -n "${debug:-}" ] && set -x
		export -p
	fi

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
	_TGET_CHRT=""						# is chgroot     (empty: none, else: chroot)
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
	___TEXT="${1:-}"
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
	unset ___ADDR ___FMAT
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
	unset ___STRT
	unset ___ENDS
}

# -----------------------------------------------------------------------------
# descript: dump output (debug out)
#   input :     $1     : path
#   output:   stdout   : message
#   return:            : unused
fnDbgdump() {
	[ -z "${_DBGS_FLAG:-}" ] && return
	if [ ! -e "${1:?}" ]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "not exist: [${1:-}]"
		return
	fi
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
fnDbgparam() {
	[ -z "${_DBGS_PARM:-}" ] && return

	__FUNC_NAME="fnDbgout"
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
	unset __FUNC_NAME
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
# descript: find service
#   input :     $1     : service name
#   output:   stdout   : output
#   return:            : unused
# --- file backup -------------------------------------------------------------
fnFind_serivce() {
	find "${_DIRS_TGET:-}"/lib/systemd/system/ "${_DIRS_TGET:-}"/usr/lib/systemd/system/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
}

# -----------------------------------------------------------------------------
# descript: get system parameter (includes dash support)
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSystem_param() {
	if [ -e "${_DIRS_TGET:-}"/etc/os-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
		_DIST_NAME="$(sed -ne '/^ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_VERS="$(sed -ne '/^VERSION=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_CODE="$(sed -ne '/^VERSION=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
	elif [ -e "${_DIRS_TGET:-}"/etc/lsb-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
		_DIST_NAME="$(sed -ne '/^DISTRIB_ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_VERS="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_CODE="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
	fi
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
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
					_NICS_WGRP="${_NICS_WGRP%.}"
				fi
				___PATH="${_DIRS_TGET:-}/etc/resolv.conf"
				if [ -e "${___PATH}" ]; then
					_NICS_DNS4="${_NICS_DNS4:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' "${___PATH}")"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(sed -ne '/^search/     s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p'                      "${___PATH}")"}"
					_NICS_WGRP="${_NICS_WGRP%.}"
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
	unset ___DIRS ___PATH ___WORK
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
	unset ___PATH ___MODE ___REAL ___DIRS ___BACK
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

	_TEXT_GAP1="$(fnString "${_COLS_SIZE}" '-')"
	_TEXT_GAP2="$(fnString "${_COLS_SIZE}" '=')"
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		fnMsgout "${_PROG_NAME:-}" "info" "busybox"
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi

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
	unset __COLS __WORK __DIRS __PATH __TGET

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: package updates
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnPackage_update() {
	__FUNC_NAME="fnPackage_update"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	  if command -v apt-get > /dev/null 2>&1; then
		if ! apt-get --quiet              update      ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get update";       return; fi
		if ! apt-get --quiet --assume-yes upgrade     ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get upgrade";      return; fi
		if ! apt-get --quiet --assume-yes dist-upgrade; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get dist-upgrade"; return; fi
		if ! apt-get --quiet --assume-yes autoremove  ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoremove";   return; fi
		if ! apt-get --quiet --assume-yes autoclean   ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoclean";    return; fi
		if ! apt-get --quiet --assume-yes clean       ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get clean";        return; fi
	elif command -v dnf     > /dev/null 2>&1; then
		if ! dnf --quiet --assumeyes update; then fnMsgout "${_PROG_NAME:-}" "failed" "dnf update"; return; fi
	elif command -v yum     > /dev/null 2>&1; then
		if ! yum --quiet --assumeyes update; then fnMsgout "${_PROG_NAME:-}" "failed" "yum update"; return; fi
	elif command -v zypper  > /dev/null 2>&1; then
		_WORK_TEXT="$(LANG=C zypper lr | awk -F '|' '$1==1&&$2~/http/ {gsub(/^[ \t]+/,"",$2); gsub(/[ \t]+$/,"",$2); print $2;}')"
		if [ -n "${_WORK_TEXT:-}" ]; then
			if ! zypper modifyrepo --disable "${_WORK_TEXT}"; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper repository disable"; return; fi
		fi
		if ! zypper                           refresh; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper refresh"; return; fi
		if ! zypper --quiet --non-interactive update ; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper update";  return; fi
	else
		fnMsgout "${_PROG_NAME:-}" "failed" "package update failure (command not found)"
		return
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: creating a shared directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnMkdir_share(){
	__FUNC_NAME="fnMkdir_share"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create system user id -----------------------------------------------
	if ! id "${_SAMB_USER}" > /dev/null 2>&1; then
		if ! grep -qE '^'"${_SAMB_GADM}"':' /etc/group; then groupadd --system "${_SAMB_GADM}"; fi
		if ! grep -qE '^'"${_SAMB_GRUP}"':' /etc/group; then groupadd --system "${_SAMB_GRUP}"; fi
		useradd --system --shell "${_SHEL_NLIN}" --groups "${_SAMB_GRUP}" "${_SAMB_USER}"
	fi
	# --- create directory ----------------------------------------------------
	mkdir -p "${_DIRS_TOPS:?}"
	mkdir -p "${_DIRS_HGFS:?}"
	mkdir -p "${_DIRS_HTML:?}"
	mkdir -p "${_DIRS_SAMB:?}"/adm/commands
	mkdir -p "${_DIRS_SAMB:?}"/adm/profiles
	mkdir -p "${_DIRS_SAMB:?}"/pub/_license
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/disc
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/movies
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/others
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/photos
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/sounds
	mkdir -p "${_DIRS_SAMB:?}"/pub/hardware
	mkdir -p "${_DIRS_SAMB:?}"/pub/software
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/git
	mkdir -p "${_DIRS_SAMB:?}"/usr
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/fonts
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/locale
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-pc
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-efi
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/x86_64-efi
	mkdir -p "${_DIRS_TFTP:?}"/ipxe
	mkdir -p "${_DIRS_TFTP:?}"/menu-bios/pxelinux.cfg
	mkdir -p "${_DIRS_TFTP:?}"/menu-efi64/pxelinux.cfg
	mkdir -p "${_DIRS_USER:?}"/private
	mkdir -p "${_DIRS_SHAR:?}"
	mkdir -p "${_DIRS_CONF:?}"/_data
	mkdir -p "${_DIRS_CONF:?}"/_keyring
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.build.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.clean.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.conf.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.extra
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.finalize.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postinst.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postoutput.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.prepare.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.repart
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.sync.d
	mkdir -p "${_DIRS_CONF:?}"/_repository/opensuse
	mkdir -p "${_DIRS_CONF:?}"/_template
	mkdir -p "${_DIRS_CONF:?}"/agama
	mkdir -p "${_DIRS_CONF:?}"/autoyast
	mkdir -p "${_DIRS_CONF:?}"/kickstart
	mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_desktop
	mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_server
	mkdir -p "${_DIRS_CONF:?}"/preseed
	mkdir -p "${_DIRS_CONF:?}"/script
	mkdir -p "${_DIRS_CONF:?}"/windows
	mkdir -p "${_DIRS_IMGS:?}"
	mkdir -p "${_DIRS_ISOS:?}"/linux
	mkdir -p "${_DIRS_ISOS:?}"/linux/debian
	mkdir -p "${_DIRS_ISOS:?}"/linux/ubuntu
	mkdir -p "${_DIRS_ISOS:?}"/linux/fedora
	mkdir -p "${_DIRS_ISOS:?}"/linux/centos
	mkdir -p "${_DIRS_ISOS:?}"/linux/almalinux
	mkdir -p "${_DIRS_ISOS:?}"/linux/rockylinux
	mkdir -p "${_DIRS_ISOS:?}"/linux/miraclelinux
	mkdir -p "${_DIRS_ISOS:?}"/linux/opensuse
	mkdir -p "${_DIRS_ISOS:?}"/linux/memtest86plus
	mkdir -p "${_DIRS_ISOS:?}"/windows
	mkdir -p "${_DIRS_ISOS:?}"/windows/windows-10
	mkdir -p "${_DIRS_ISOS:?}"/windows/windows-11
	mkdir -p "${_DIRS_ISOS:?}"/windows/winpe
	mkdir -p "${_DIRS_ISOS:?}"/windows/ati
	mkdir -p "${_DIRS_ISOS:?}"/windows/aomei
	mkdir -p "${_DIRS_LOAD:?}"
	mkdir -p "${_DIRS_RMAK:?}"
	mkdir -p "${_DIRS_CACH:?}"
	mkdir -p "${_DIRS_CTNR:?}"
	mkdir -p "${_DIRS_CHRT:?}"

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
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_TFTP##*/}"               ] && ln -s "${_DIRS_TFTP#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_CONF##*/}"    ] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_IMGS##*/}"    ] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_ISOS##*/}"    ] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_LOAD##*/}"    ] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_RMAK##*/}"    ] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" ] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"

	# --- create index.html ---------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_HTML}/index.html"
		"Hello, world!" from ${_NICS_HOST}
_EOT_

	# --- create autoexec.ipxe ------------------------------------------------
	touch "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"
	touch "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg"
	fnFile_backup "${_DIRS_TFTP:-}/menu-bios/syslinux.cfg"  "init"
	fnFile_backup "${_DIRS_TFTP:-}/menu-efi64/syslinux.cfg" "init"

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
	fnFile_backup "${_DIRS_TFTP:-}/autoexec.ipxe" "init"

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_TOPS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: connman
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_connman() {
	__FUNC_NAME="fnSetup_connman"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'connman.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- main.conf -----------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/connman/main.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"

		# Generated by user script
		AllowHostnameUpdates = false
		AllowDomainnameUpdates = false
		PreferredTechnologies = ethernet,wifi
		SingleConnectedTechnology = true
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- disable_dns_proxy.conf ----------------------------------------------
	__WORK="$(command -v connmand 2> /dev/null)"
	__PATH="${_DIRS_TGET:-}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		[Service]
		ExecStart=
		ExecStart=${__WORK} -n --nodnsproxy
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- settings ------------------------------------------------------------
	__MADR="$(echo "${_NICS_MADR}" | sed -e 's/://g')"
	__PATH="${_DIRS_TGET:-}/var/lib/connman/ethernet_${__MADR}_cable/settings"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[ethernet_${__MADR}_cable]
			Name=Wired
			AutoConnect=true
			Modified=
_EOT_
	if [ -n "${_NICS_AUTO##-}" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			IPv4.method=dhcp
			IPv4.DHCP.LastAddress=
			IPv6.method=auto
			IPv6.privacy=prefered
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			IPv4.method=manual
			IPv4.netmask_prefixlen=${_NICS_BIT4}
			IPv4.local_address=${_NICS_IPV4}
			IPv4.gateway=${_NICS_GATE}
			IPv6.method=auto
			IPv6.privacy=prefered
			Nameservers=${_NICS_DNS4};
			Domains=${_NICS_WGRP};
			IPv6.DHCP.DUID=
_EOT_
	fi
	chmod 600 "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SRVC __PATH __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: netplan
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_netplan() {
	__FUNC_NAME="fnSetup_netplan"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v netplan > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- configures ----------------------------------------------------------
	if command -v nmcli > /dev/null 2>&1; then
		# --- 99-network-config-all.yaml --------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/netplan/99-network-manager-all.yaml"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			network:
			  version: 2
			  renderer: NetworkManager
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- 99-disable-network-config.cfg -----------------------------------
		__PATH="${_DIRS_TGET:-}/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
		if [ -e "${__PATH%/*}/." ]; then
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
				network: {config: disabled}
_EOT_
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		fi
	else
		__PATH="${_DIRS_TGET:-}/etc/netplan/99-network-config-${_NICS_NAME}.yaml"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			network:
				version: 2
				renderer: networkd
				ethernets:
				${_NICS_NAME}:
_EOT_
		if [ -n "${_NICS_AUTO##-}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				dhcp4: true
				dhcp6: true
				ipv6-privacy: true
_EOT_
		else
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				addresses:
				- ${_NICS_IPV4}/${_NICS_BIT4}
				routes:
				- to: default
				via: ${_NICS_GATE}
				nameservers:
				search:
				- ${_NICS_WGRP}
				addresses:
				- ${_NICS_DNS4}
				dhcp4: false
				dhcp6: true
				ipv6-privacy: true
_EOT_
		fi
		chmod 600 "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- netplan -------------------------------------------------------------
	if netplan status 2> /dev/null; then
		if netplan apply; then
			fnMsgout "${_PROG_NAME:-}" "success" "netplan apply"
		else
			fnMsgout "${_PROG_NAME:-}" "failed" "netplan apply"
		fi
	fi
	unset __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: network manager
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_netman() {
	__FUNC_NAME="fnSetup_netman"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'NetworkManager.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- configures ----------------------------------------------------------
	if [ -z "${_NICS_NAME##-}" ]; then
		for __CONF in zz-all-en zz-all-eth
		do
			__PATH="${_DIRS_TGET:-}/etc/NetworkManager/system-connections/${__CONF}.nmconnection"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			nmcli --offline connection add \
				type ethernet \
				match.interface-name "${__CONF##*-}*" \
				connection.id "${__CONF}" \
				connection.autoconnect true \
				connection.autoconnect-priority 999 \
				${_FWAL_ZONE:+connection.zone "${_FWAL_ZONE}"} \
				ethernet.wake-on-lan 0 \
				ipv4.method auto \
				ipv6.method auto \
				ipv6.addr-gen-mode default \
			> "${__PATH}"
			chown root:root "${__PATH}"
			chmod 600 "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		done
	else
		__PATH="${_DIRS_TGET:-}/etc/NetworkManager/system-connections/${_NICS_NAME}.nmconnection"
		__SRVC="NetworkManager.service"
		__UUID=""
		if [ -z "${_TGET_CHRT:-}" ]; then
			if systemctl --quiet is-active "${__SRVC}"; then
				__UUID="$(nmcli --fields DEVICE,UUID connection show | awk '$1=="'"${_NICS_NAME}"'" {print $2;}')"
				for __FIND in "${_DIRS_TGET:-}/etc/NetworkManager/system-connections/"* "${_DIRS_TGET:-}/run/NetworkManager/system-connections/"*
				do
					if grep -Hqs "uuid=${__UUID}" "${__FIND}"; then
						__PATH="${__FIND}"
						break
					fi
				done
			fi
		fi
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
#		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		__CNID="${__PATH##*/}"
		__CNID="${__CNID%.*}"
		set -f
		set -- \
			type ethernet \
			${__CNID:+connection.id "${__CNID}"} \
			${_NICS_NAME:+connection.interface-name "${_NICS_NAME}"} \
			connection.autoconnect true \
			${_FWAL_ZONE:+connection.zone "${_FWAL_ZONE}"} \
			ethernet.wake-on-lan 0 \
			${_NICS_MADR:+ethernet.mac-address "${_NICS_MADR}"}
		if [ -n "${_NICS_AUTO##-}" ]; then
			set -- "$@" \
				ipv4.method auto \
				ipv6.method auto \
				ipv6.addr-gen-mode default
		else
			set -- "$@" \
				ipv4.method manual \
				${_NICS_IPV4:+ipv4.address "${_NICS_IPV4}"/"${_NICS_BIT4}"} \
				${_NICS_GATE:+ipv4.gateway "${_NICS_GATE}"} \
				${_NICS_DNS4:+ipv4.dns "${_NICS_DNS4}"} \
				ipv6.method auto \
				ipv6.addr-gen-mode default
		fi
		set +f
		if [ -z "${__UUID:-}" ]; then
			nmcli --offline connection add "$@" > "${__PATH}"
		else
			nmcli connection modify uuid "${__UUID}" "$@"
		fi
		chown root:root "${__PATH}"
		chmod 600 "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- dns.conf ------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if command -v resolvectl > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[main]
			dns=systemd-resolved
_EOT_
	elif command -v dnsmasq > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[main]
			dns=dnsmasq
_EOT_
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- mdns.conf -----------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/NetworkManager/conf.d/mdns.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if command -v resolvectl > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[connection]
			connection.mdns=2
_EOT_
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	__SRVC="${__SRVC##*/}"
	if systemctl --quiet is-enabled "${__SRVC}"; then
		__SVEX="systemd-networkd.service"
		if systemctl --quiet is-enabled "${__SVEX}"; then
			fnMsgout "${_PROG_NAME:-}" "mask" "${__SVEX}"
			systemctl --quiet mask "${__SVEX}"
			systemctl --quiet mask "${__SVEX%.*}.socket"
		fi
	fi
	if [ -z "${_TGET_CHRT:-}" ]; then
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
			if nmcli connection reload; then
				fnMsgout "${_PROG_NAME:-}" "success" "nmcli connection reload"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "nmcli connection reload"
			fi
		fi
	fi
	unset __SRVC __CONF __PATH __UUID __CNID

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: hostname
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_hostname() {
	__FUNC_NAME="fnSetup_hostname"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check fqdn ----------------------------------------------------------
	if [ -z "${_NICS_FQDN:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- hostname ------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/hostname"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	echo "${_NICS_FQDN:-}" > "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: hosts
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_hosts() {
	__FUNC_NAME="fnSetup_hosts"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check fqdn ----------------------------------------------------------
	if [ -z "${_NICS_FQDN:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- hosts ---------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/hosts"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if [ "${_NICS_IPV4##*.}" -eq 0 ]; then
		__WORK="#${_IPV4_DUMY:-"127.0.1.1"}"
	else
		__WORK="${_NICS_IPV4}"
	fi
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		$(printf "%-16s %s" "${_IPV4_LHST:-"127.0.0.1"}" "localhost")
		$(printf "%-16s %s %s" "${__WORK}" "${_NICS_FQDN}" "${_NICS_HOST}")

		# The following lines are desirable for IPv6 capable hosts
		$(printf "%-16s %s %s %s" "${_IPV6_LHST:-"::1"}" "localhost" "ip6-localhost" "ip6-loopback")
		$(printf "%-16s %s" "fe00::0" "ip6-localnet")
		$(printf "%-16s %s" "ff00::0" "ip6-mcastprefix")
		$(printf "%-16s %s" "ff02::1" "ip6-allnodes")
		$(printf "%-16s %s" "ff02::2" "ip6-allrouters")
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __PATH __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: firewalld
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_firewalld() {
	__FUNC_NAME="fnSetup_firewalld"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v firewall-cmd > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- firewalld.service ---------------------------------------------------
	__SRVC="$(fnFind_serivce 'firewalld.service' | sort -V | head -n 1)"
	fnFile_backup "${__SRVC}"			# backup original file
	mkdir -p "${__SRVC%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SRVC#*"${_DIRS_TGET:-}/"}" "${__SRVC}"
	sed -i "${__SRVC}" \
	    -e '/\[Unit\]/,/\[.*\]/                {' \
	    -e '/^Before=network-pre.target$/ s/^/#/' \
	    -e '/^Wants=network-pre.target$/  s/^/#/' \
	    -e '                                   }'
	fnDbgdump "${__SRVC}"				# debugout
	fnFile_backup "${__SRVC}" "init"	# backup initial file
	# --- firewalld -----------------------------------------------------------
	__ORIG="$(find "${_DIRS_TGET:-}"/lib/firewalld/zones/ "${_DIRS_TGET:-}"/usr/lib/firewalld/zones/ -name 'drop.xml' | sort -V | head -n 1)"
	__PATH="${_DIRS_TGET:-}/etc/firewalld/zones/${_FWAL_ZONE}.xml"
	cp --preserve=timestamps "${__ORIG}" "${__PATH}"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	__IPV4="${_IPV4_UADR}.0/${_NICS_BIT4}"
	__IPV6="${_IPV6_UADR%%::}::/${_IPV6_CIDR}"
	__LINK="${_LINK_UADR%%::}::/10"
	__SRVC="${__SRVC##*/}"
	if [ -z "${_TGET_CHRT:-}" ] && systemctl --quiet is-active "${__SRVC}"; then
		fnMsgout "${_PROG_NAME:-}" "active" "${__SRVC}"
		firewall-cmd --quiet --permanent --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		firewall-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	else
		fnMsgout "${_PROG_NAME:-}" "inactive" "${__SRVC}"
		firewall-offline-cmd --quiet --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
#		firewall-offline-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-offline-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-offline-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __SRVC __ORIG __PATH __IPV4 __IPV6 __LINK __NAME __PORT

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: dnsmasq
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_dnsmasq() {
	__FUNC_NAME="fnSetup_dnsmasq"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v dnsmasq > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- dnsmasq.service -----------------------------------------------------
	__SRVC="$(fnFind_serivce 'dnsmasq.service' | sort -V | head -n 1)"
	fnFile_backup "${__SRVC}"			# backup original file
	mkdir -p "${__SRVC%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SRVC#*"${_DIRS_TGET:-}/"}" "${__SRVC}"
	sed -i "${__SRVC}" \
	    -e '/^\[Unit\]$/,/^\[.\+\]/                       {' \
	    -e '/^Requires=/                            s/^/#/g' \
	    -e '/^After=/                               s/^/#/g' \
	    -e '/^Description=/a Requires=network-online.target' \
	    -e '/^Description=/a After=network-online.target'    \
	    -e '                                              }'
	fnDbgdump "${__SRVC}"				# debugout
	fnFile_backup "${__SRVC}" "init"	# backup initial file
	# --- dnsmasq -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/default/dnsmasq"
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -i "${__PATH}" \
		    -e 's/^#\(IGNORE_RESOLVCONF\)=.*$/\1=yes/' \
		    -e 's/^#\(DNSMASQ_EXCEPT\)=.*$/\1="lo"/'
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- default.conf --------------------------------------------------------
	__CONF="$(find "${_DIRS_TGET:-}"/etc/dnsmasq.d "${_DIRS_TGET:-}/usr/share" -name 'trust-anchors.conf' -type f)"
	__CONF="${__CONF#"${_DIRS_TGET:-}"}"
	__PATH="${_DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- log ---------------------------------------------------------------------
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name

		# --- dns ---------------------------------------------------------------------
		#port=0                                                     # listening port
		#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
		#domain-needed                                              # do not forward plain names
		$(printf "%-60s" "#domain=${_NICS_WGRP:-}")# local domain name
		#expand-hosts                                               # add domain name to host
		#filterwin2k                                                # filter for windows
		$(printf "%-60s" "#interface=${_NICS_NAME##-:-}")# listen to interface
		$(printf "%-60s" "#listen-address=${_IPV4_LHST:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_IPV6_LHST:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_NICS_IPV4:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_LINK_ADDR:-}")# listen to ip address
		$(printf "%-60s" "#server=${_NICS_DNS4:-}")# directly specify upstream server
		#server=8.8.8.8                                             # directly specify upstream server
		#server=8.8.4.4                                             # directly specify upstream server
		#no-hosts                                                   # don't read the hostnames in /etc/hosts
		#no-poll                                                    # don't poll /etc/resolv.conf for changes
		#no-resolv                                                  # don't read /etc/resolv.conf
		#strict-order                                               # try in the registration order of /etc/resolv.conf
		#bind-dynamic                                               # enable bind-interfaces and the default hybrid network mode
		bind-interfaces                                             # enable multiple instances of dnsmasq
		$(printf "%-60s" "#conf-file=${_CONF:-}")# enable dnssec validation and caching
		#dnssec                                                     # "

		# --- dhcp --------------------------------------------------------------------
		$(printf "%-60s" "dhcp-range=${_IPV4_UADR:-}.0,proxy,24")# proxy dhcp
		$(printf "%-60s" "#dhcp-range=${_IPV4_UADR:-}.64,${_IPV4_UADR:-}.79,12h")# dhcp range
		#dhcp-option=option:netmask,255.255.255.0                   #  1 netmask
		$(printf "%-60s" "#dhcp-option=option:router,${_NICS_GATE:-}")#  3 router
		$(printf "%-60s" "#dhcp-option=option:dns-server,${_NICS_IPV4:-},${_NICS_GATE:-}")#  6 dns-server
		$(printf "%-60s" "#dhcp-option=option:domain-name,${_NICS_WGRP:-}")# 15 domain-name
		$(printf "%-60s" "#dhcp-option=option:28,${_IPV4_UADR:-}.255")# 28 broadcast
		$(printf "%-60s" "#dhcp-option=option:ntp-server,${_NTPS_IPV4:-}")# 42 ntp-server
		$(printf "%-60s" "#dhcp-option=option:tftp-server,${_NICS_IPV4:-}")# 66 tftp-server
		#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
		dhcp-no-override                                            # disable re-use of the dhcp servername and filename fields as extra option space
		dhcp-reply-delay=1                                          # 

		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

		# --- eof ---------------------------------------------------------------------
_EOT_
	if [ -n "${_NICS_AUTO##-}" ]; then
		sed -i "${__PATH}" \
		    -e '/^interface=/ s/^/#/g'
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- pxeboot.conf --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name

		# --- tftp --------------------------------------------------------------------
		$(printf "%-60s" "#enable-tftp=${_NICS_NAME:-}")# enable tftp server
		$(printf "%-60s" "#tftp-root=${_DIRS_TFTP:-}")# tftp root directory
		#tftp-lowercase                                             # convert tftp request path to all lowercase
		#tftp-no-blocksize                                          # stop negotiating "block size" option
		#tftp-no-fail                                               # do not abort startup even if tftp directory is not accessible
		#tftp-secure                                                # enable tftp secure mode

		# --- syslinux block ----------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , menu-bios/lpxelinux.0       #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , menu-efi64/syslinux.efi     #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , menu-efi64/syslinux.efi     #  9 EFI x86-64

		# --- grub block --------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux.0        #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootnetx64.efi    #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootnetx64.efi    #  9 EFI x86-64

		# --- ipxe block --------------------------------------------------------------
		#dhcp-match=set:iPXE,175                                                                 #
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=tag:iPXE ,x86PC  , "PXEBoot-x86PC"            , /autoexec.ipxe              #  0 Intel x86PC (iPXE)
		#pxe-service=tag:!iPXE,x86PC  , "PXEBoot-x86PC"            , ipxe/undionly.kpxe          #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , ipxe/ipxe.efi               #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , ipxe/ipxe.efi               #  9 EFI x86-64

		# --- pxe boot ----------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            ,                             #  0 Intel x86PC
		#pxe-service=PC98             , "PXEBoot-PC98"             ,                             #  1 NEC/PC98
		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,                             #  2 EFI Itanium
		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,                             #  3 DEC Alpha
		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,                             #  4 Arc x86
		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",                             #  5 Intel Lean Client
		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,                             #  6 EFI IA32
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           ,                             #  7 EFI BC
		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,                             #  8 EFI Xscale
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       ,                             #  9 EFI x86-64
		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,                             # 10 ARM 32bit
		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,                             # 11 ARM 64bit

		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

		# --- eof ---------------------------------------------------------------------
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- create sample file --------------------------------------------------
	for __WORK in "syslinux block" "grub block" "ipxe block"
	do
		__PATH="${_DIRS_TGET:+"${_DIRS_TGET}/"}${_DIRS_SAMP}/etc/dnsmasq.d/pxeboot_${__WORK%% *}.conf"
		mkdir -p "${__PATH%/*}"
		sed -ne '/^# --- tftp ---/,/^$/               {' \
		    -ne '/^# ---/p'                              \
		    -ne '/enable-tftp=/               s/^#//p'   \
		    -ne '/tftp-root=/                 s/^#//p }' \
		    -ne '/^# --- '"${__WORK}"' ---/,/^$/      {' \
		    -ne '/^# ---/p'                              \
		    -ne '/^# ---/!                    s/^#//gp}' \
		    "${_DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf" \
		> "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
	done
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SRVC __PATH __CONF __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: resolv.conf
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_resolv() {
	__FUNC_NAME="fnSetup_resolv"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/resolv.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	if ! command -v resolvectl > /dev/null 2>&1; then
		if [ ! -h "${__PATH}" ]; then
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				# Generated by user script
				search ${_NICS_WGRP}
				nameserver ${_IPV6_LHST}
				nameserver ${_IPV4_LHST}
_EOT_
		fi
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	else
		__CONF="${_DIRS_TGET:-}/run/systemd/resolve/stub-resolv.conf"
		fnFile_backup "${__CONF}"			# backup original file
#		if grep -qi 'Do not edit.' "${__PATH}"; then
#			fnMsgout "${_PROG_NAME:-}" "skip" "resolv.conf setup for chroot"
#		else
#			mkdir -p "${__CONF%/*}"
#			cp --preserve=timestamps "${_DIRS_ORIG}/${__CONF#*"${_DIRS_TGET:-}/"}" "${__CONF}"
			if [ ! -h "${__PATH}" ]; then
				rm -f "${__PATH}"
				ln -s "../${__CONF#"${_DIRS_TGET:-}/"}" "${__PATH}"
			fi
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
			fnFile_backup "${__CONF}" "init"	# backup initial file
#		fi
		# --- default.conf ----------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/systemd/resolved.conf.d/default.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			[Resolve]
			MulticastDNS=yes
			DNS=${_NICS_DNS4}
			Domains=${_NICS_WGRP}
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- service restart -------------------------------------------------
		__SRVC="systemd-resolved.service"
		if systemctl --quiet is-enabled "${__SRVC}"; then
			__SVEX="avahi-daemon.service"
			if systemctl --quiet is-enabled "${__SVEX}"; then
				fnMsgout "${_PROG_NAME:-}" "mask" "${__SVEX}"
				systemctl --quiet mask "${__SVEX}"
				systemctl --quiet mask "${__SVEX%.*}.socket"
			fi
		fi
		if [ -z "${_TGET_CHRT:-}" ]; then
			if systemctl --quiet is-active "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
				systemctl --quiet daemon-reload
				if systemctl --quiet restart "${__SRVC}"; then
					fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
				else
					fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
				fi
			fi
		fi
	fi
	unset __PATH __CONF __SRVC __SVEX

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: apache
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_apache() {
	__FUNC_NAME="fnSetup_apache"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'apache2.service' 'httpd.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- apache2.conf / httpd.conf -------------------------------------------
	__FILE="${__SRVC##*/}"
	__PATH="${_DIRS_TGET:-}/etc/${__FILE%%.*}/sites-available/999-site.conf"
	if [ -e "${__PATH%/*}/." ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -e 's%^\([ \t]\+DocumentRoot[ \t]\+\).*$%\1'"${_DIRS_HTML}"'%' \
		    "${__PATH%/*}/000-default.conf" \
		> "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			<Directory ${_DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- registration ----------------------------------------------------
		a2dissite 000-default
		a2ensite "${__PATH##*/}"
	else
		__PATH="${_DIRS_TGET:-}/etc/${__FILE%%.*}/conf.d/site.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			<VirtualHost *:80>
			 	ServerAdmin webmaster@localhost
			 	DocumentRoot ${_DIRS_HTML}
			#	ErrorLog \${APACHE_LOG_DIR}/error.log
			#	CustomLog \${APACHE_LOG_DIR}/access.log combined
			</VirtualHost>

			<Directory ${_DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}

# -----------------------------------------------------------------------------
# descript: samba
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_samba() {
	__FUNC_NAME="fnSetup_samba"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v pdbedit > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- check service -------------------------------------------------------
	__SMBD="$(fnFind_serivce 'smbd.service' 'smb.service' | sort -V | head -n 1)"
	__NMBD="$(fnFind_serivce 'nmbd.service' 'nmb.service' | sort -V | head -n 1)"
	if [ -z "${__SMBD:-}" ] || [ -z "${__NMBD:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- create passdb.tdb ---------------------------------------------------
	pdbedit -L > /dev/null 2>&1 || true
	# --- nsswitch.conf -------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/nsswitch.conf"
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		if [ ! -h "${__PATH}" ]; then
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		fi
		sed -i "${__PATH}"                \
		    -e '/^hosts:[ \t]\+/       {' \
		    -e 's/\(files\).*$/\1/'       \
		    -e 's/$/ '"${_SAMB_NSSW}"'/}' \
			-e '/^\(passwd\|group\|shadow\|gshadow\):[ \t]\+/ s/[ \t]\+winbind//'
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- smb.conf ------------------------------------------------------------
	# https://www.samba.gr.jp/project/translation/current/htmldocs/manpages/smb.conf.5.html
	__PATH="${_DIRS_TGET:-}/etc/samba/smb.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	__CONF="${_DIRS_TGET:-}/tmp/${__PATH##*/}.work"
	# <-- global settings section -------------------------------------------->
	# allow insecure wide links = Yes
	testparm -s -v                                                                   | \
	sed -ne '/^\[global\]$/,/^[ \t]*$/                                              {' \
	    -e  '/^[ \t]*acl check permissions[ \t]*=/        s/^/#/'                      \
	    -e  '/^[ \t]*allocation roundup size[ \t]*=/      s/^/#/'                      \
	    -e  '/^[ \t]*allow nt4 crypto[ \t]*=/             s/^/#/'                      \
	    -e  '/^[ \t]*blocking locks[ \t]*=/               s/^/#/'                      \
	    -e  '/^[ \t]*client NTLMv2 auth[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*client lanman auth[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*client plaintext auth[ \t]*=/        s/^/#/'                      \
	    -e  '/^[ \t]*client schannel[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*client use spnego principal[ \t]*=/  s/^/#/'                      \
	    -e  '/^[ \t]*client use spnego[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*copy[ \t]*=/                         s/^/#/'                      \
	    -e  '/^[ \t]*domain logons[ \t]*=/                s/^/#/'                      \
	    -e  '/^[ \t]*enable privileges[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*encrypt passwords[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*idmap backend[ \t]*=/                s/^/#/'                      \
	    -e  '/^[ \t]*idmap gid[ \t]*=/                    s/^/#/'                      \
	    -e  '/^[ \t]*idmap uid[ \t]*=/                    s/^/#/'                      \
	    -e  '/^[ \t]*lanman auth[ \t]*=/                  s/^/#/'                      \
	    -e  '/^[ \t]*lsa over netlogon[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*nbt client socket address[ \t]*=/    s/^/#/'                      \
	    -e  '/^[ \t]*null passwords[ \t]*=/               s/^/#/'                      \
	    -e  '/^[ \t]*raw NTLMv2 auth[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*reject md5 clients[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*server schannel require seal[ \t]*=/ s/^/#/'                      \
	    -e  '/^[ \t]*server schannel[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*syslog only[ \t]*=/                  s/^/#/'                      \
	    -e  '/^[ \t]*syslog[ \t]*=/                       s/^/#/'                      \
	    -e  '/^[ \t]*unicode[ \t]*=/                      s/^/#/'                      \
	    -e  '/^[ \t]*winbind separator[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*allow insecure wide links[ \t]*=/    s/=.*$/= Yes/'               \
	    -e  '/^[ \t]*dos charset[ \t]*=/                  s/=.*$/= CP932/'             \
	    -e  '/^[ \t]*unix password sync[ \t]*=/           s/=.*$/= No/'                \
	    -e  '/^[ \t]*netbios name[ \t]*=/                 s/=.*$/= '"${_NICS_HOST}"'/' \
	    -e  '/^[ \t]*workgroup[ \t]*=/                    s/=.*$/= '"${_NICS_WGRP}"'/' \
	    -e  '/^[ \t]*interfaces[ \t]*=/                   s/=.*$/= '"${_NICS_NAME}"'/' \
	    -e  'p                                                                      }' \
	> "${__CONF}" 2> /dev/null
	[ -z "${_NICS_HOST##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*netbios name[ \t]*=/d'
	[ -z "${_NICS_WGRP##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*workgroup[ \t]*=/d'
	[ -z "${_NICS_NAME##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*interfaces[ \t]*=/d'
	# <-- shared settings section -------------------------------------------->
	# wide links = Yes
	# tree
	#	/srv/samba/
	#	|-- adm
	#	|   |-- commands
	#	|   `-- profiles
	#	|-- pub
	#	|   |-- _license
	#	|   |-- contents
	#	|   |   |-- disc
	#	|   |   `-- dlna
	#	|   |       |-- movies
	#	|   |       |-- others
	#	|   |       |-- photos
	#	|   |       `-- sounds
	#	|   |-- hardware
	#	|   |-- resource
	#	|   |   |-- image
	#	|   |   |   |-- linux
	#	|   |   |   `-- windows
	#	|   |   `-- source
	#	|   |       `-- git
	#	|   `-- software
	#	`-- usr
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__CONF}"
			[homes]
		        browseable = No
		        comment = Home Directories
		        create mask = 0700
		        directory mask = 2700
		        valid users = %S
		        write list = @${_SAMB_GRUP}
		[printers]
		        browseable = No
		        comment = All Printers
		        create mask = 0700
		        path = /var/tmp
		        printable = Yes
		[print$]
		        comment = Printer Drivers
		        path = /var/lib/samba/printers
		[adm]
		        browseable = No
		        comment = Administrator directories
		        create mask = 0660
		        directory mask = 2770
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_SAMB}/adm
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
		[pub]
		        browseable = Yes
		        comment = Public directories
		        create mask = 0660
		        directory mask = 2770
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_SAMB}/pub
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
		[usr]
		        browseable = No
		        comment = User directories
		        create mask = 0660
		        directory mask = 2770
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_SAMB}/usr
		        valid users = @${_SAMB_GADM}
		        write list = @${_SAMB_GADM}
		[share]
		        browseable = No
		        comment = Shared directories
		        create mask = 0660
		        directory mask = 2770
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_SAMB}
		        valid users = @${_SAMB_GADM}
		        write list = @${_SAMB_GADM}
		[dlna]
		        browseable = No
		        comment = DLNA directories
		        create mask = 0660
		        directory mask = 2770
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_SAMB}/pub/contents/dlna
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
		[share-html]
		        browseable = No
		        comment = Shared directory for HTML
		        guest ok = Yes
		        path = ${_DIRS_HTML}
		        wide links = Yes
		[share-tftp]
		        browseable = No
		        comment = Shared directory for TFTP
		        guest ok = Yes
		        path = ${_DIRS_TFTP}
		        wide links = Yes
		[share-conf]
		        browseable = No
		        comment = Shared directory for configuration files
		        create mask = 0664
		        directory mask = 2775
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_CONF}
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
		[share-isos]
		        browseable = No
		        comment = Shared directory for iso image files
		        create mask = 0664
		        directory mask = 2775
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_ISOS}
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
		[share-rmak]
		        browseable = No
		        comment = Shared directory for remake files
		        create mask = 0664
		        directory mask = 2775
		        force group = ${_SAMB_GRUP}
		        force user = ${_SAMB_USER}
		        path = ${_DIRS_RMAK}
		        valid users = @${_SAMB_GRUP}
		        write list = @${_SAMB_GADM}
_EOT_
	# --- output --------------------------------------------------------------
	testparm -s "${__CONF}" > "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SMBD##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
		__SRVC="${__NMBD##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SMBD __NMBD __PATH __CONF __SRVC

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: timesyncd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_timesyncd() {
	__FUNC_NAME="fnSetup_timesyncd"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'systemd-timesyncd.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- timesyncd.conf ------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/systemd/timesyncd.conf.d/local.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- user settings ---
		[Time]
		NTP=${_NTPS_ADDR}
		FallbackNTP=${_NTPS_FBAK}
		PollIntervalMinSec=1h
		PollIntervalMaxSec=1d
		SaveIntervalSec=infinity
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: chronyd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_chronyd() {
	__FUNC_NAME="fnSetup_chronyd"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'chronyd.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- chrony.conf ---------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/chrony.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
			hwclock --systohc
			hwclock --test
		fi
	fi
	unset __SRVC __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: openssh-server
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_ssh() {
	__FUNC_NAME="fnSetup_ssh"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'ssh.service' 'sshd.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- default.conf --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/ssh/sshd_config.d/default.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- user settings ---

		# port number to listen to ssh
		#Port 22

		# ip address to accept connections
		#ListenAddress 0.0.0.0
		#ListenAddress ::

		# ssh protocol
		Protocol 2

		# whether to allow root login
		PermitRootLogin no

		# configuring public key authentication
		#PubkeyAuthentication no

		# public key file location
		#AuthorizedKeysFile

		# setting password authentication
		PasswordAuthentication yes

		# configuring challenge-response authentication
		#ChallengeResponseAuthentication no

		# sshd log is output to /var/log/secure
		#SyslogFacility AUTHPRIV

		# specify log output level
		#LogLevel INFO
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SRVC __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: vmware shared directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_vmware() {
	__FUNC_NAME="fnSetup_vmware"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v vmware-hgfsclient > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- GNOME3 rendering issues ---------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/environment.d/99vmware.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		CLUTTER_PAINT=disable-clipped-redraws:disable-culling
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- check file system ---------------------------------------------------
	if command -v vmhgfs-fuse > /dev/null 2>&1; then
		__FSYS="fuse.vmhgfs-fuse"
	else
		__FSYS="vmhgfs"
	fi
	# --- fstab ---------------------------------------------------------------
	__FSTB="$(printf "%-15s %-15s %-7s %-15s %-7s %s" ".host:/" "${_DIRS_HGFS:?}" "${__FSYS}" "nofail,allow_other,defaults" "0" "0")"
	if ! vmware-hgfsclient > /dev/null 2>&1; then
		__FSTB="#${__FSTB}"
	fi
	__PATH="${_DIRS_TGET:-}/etc/fstab"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		${__FSTB}
_EOT_
	# --- check mount ---------------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		systemctl --quiet daemon-reload
		if mount "${_DIRS_HGFS}"; then
			fnMsgout "${_PROG_NAME:-}" "success" "VMware shared directory mounted"
			LANG=C df -h "${_DIRS_HGFS}"
		else
			fnMsgout "${_PROG_NAME:-}" "failed" "VMware shared directory not mounted"
			sed -i "${__PATH}" \
			    -e "\%${__FSTB}% s/^/#/g"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __PATH __FSYS __FSTB

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: wireplumber (alsa) settings
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_wireplumber() {
	__FUNC_NAME="fnSetup_wireplumber"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'wireplumber.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- alsa ----------------------------------------------------------------
	__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/main.lua.d/50-alsa-config.lua"
	if [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		# --- 50-alsa-config.lua ----------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/main.lua.d/${__CONF##*/}"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		sed -i "${__PATH}"                                                                    \
		    -e '/^alsa_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                                 {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*}/                         {' \
		    -e '/\["api.alsa.period-size"\]/a \        \["api.alsa.period-size"\]   = 1024,'  \
		    -e '/\["api.alsa.headroom"\]/a    \        \["api.alsa.headroom"\]      = 16384,' \
		    -e '}}'
	else
		__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/wireplumber.conf.d/alsa-vm.conf"
		if [ -e "${__CONF}" ]; then
			fnFile_backup "${__CONF}"			# backup original file
			# --- alsa-vm.conf ------------------------------------------------
			__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/${__CONF##*/}"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${__CONF}" "${__PATH}"
			sed -i "${__PATH}"                                                      \
			    -e '/^monitor.alsa.rules[ \t]*=[ \t]*\[$/,/^\]$/                 {' \
			    -e '/^[ \t]*actions[ \t]*=[ \t]*{$/,/^[ \t]*}$/                  {' \
			    -e '/^[ \t]*update-props[ \t]*=[ \t]*{$/,/^[ \t]*}$/             {' \
			    -e '/^[ \t]*api.alsa.period-size[ \t]*/ s/=\([ \t]*\).*$/=\11024/'  \
			    -e '/^[ \t]*api.alsa.headroom[ \t]*/    s/=\([ \t]*\).*$/=\116384/' \
			    -e '}}}'
		else
			# --- 50-alsa-config.conf -----------------------------------------
			__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				monitor.alsa.rules = [
				  {
				    matches = [
				      # This matches the value of the 'node.name' property of the node.
				      {
				        node.name = "~alsa_output.*"
				      }
				    ]
				    actions = {
				      # Apply all the desired node specific settings here.
				      update-props = {
				        api.alsa.period-size   = 1024
				        api.alsa.headroom      = 16384
				        session.suspend-timeout-seconds = 0
				      }
				    }
				  }
				]
_EOT_
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- bluetooth -----------------------------------------------------------
	__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua"
	if [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		# --- 50-bluez-config.lua ---------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/bluetooth.lua.d/${__CONF##*/}"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		sed -i "${__PATH}"                                                                 \
		    -e '/^bluez_monitor.properties[ \t]*=[ \t]*{$/,/^}$/                        {' \
		    -e '/\["bluez5.headset-roles"\]/a  \    \["bluez5.headset-roles"\] = "[ ]",'   \
		    -e '/\["bluez5.hfphsp-backend"\]/a \    \["bluez5.hfphsp-backend"\] = "none",' \
		    -e '                                                                        }' \
		    -e '/^bluez_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                             {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*},/                     {' \
		    -e '/\["bluez5.media-source-role"\]/,/^[ \t]*},/                            {' \
		    -e '/^[ \t]*},/i \        \["bluez5.auto-connect"\] = "\[ a2dp_sink \]",'      \
		    -e '/^[ \t]*},/i \        \["bluez5.hw-volume"\]    = "\[ a2dp_sink \]",'      \
		    -e '}}}'
	else
		# --- bluez.conf ------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/bluez.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			monitor.bluez.properties = {
			  bluez5.headset-roles  = "[ ]"
			  bluez5.hfphsp-backend = "none"
			}

			monitor.bluez.rules = [
			  {
			    matches = [
			      {
			        node.name = "~bluez_input.*"
			      }
			      {
			        node.name = "~bluez_output.*"
			      }
			    ]
			    actions = {
			      update-props = {
			        bluez5.auto-connect = "[ a2dp_sink ]"
			        bluez5.hw-volume    = "[ a2dp_sink ]"
			      }
			    }
			  }
			]
_EOT_
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet  is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			for __USER in $(ps --no-headers -C "${__SRVC%.*}" -o user)
			do
				if systemctl --quiet --user --machine="${__USER}"@ restart "${__SRVC}"; then
					fnMsgout "${_PROG_NAME:-}" "success" "${__USER}@ ${__SRVC}"
				else
					fnMsgout "${_PROG_NAME:-}" "failed" "${__USER}@ ${__SRVC}"
				fi
			done
		fi
	fi
	unset __SRVC __CONF __PATH __USER

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: skeleton
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_skel() {
	__FUNC_NAME="fnSetup_skel"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- .bashrc -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/skel/.bashrc"
	__CONF="${_DIRS_TGET:-}/usr/etc/skel/.bashrc"
	if [ ! -e "${__PATH}" ] && [ -e "${__CONF}" ]; then
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
	fi
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			# --- measures against garbled characters ---
			case "${TERM}" in
			    linux ) export LANG=C;;
			    *     )              ;;
			esac
			# --- user custom ---
			alias vi='vim'
			alias view='vim'
			alias diff='diff --color=auto'
			alias ip='ip -color=auto'
			alias ls='ls --color=auto'
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .bash_history -------------------------------------------------------
	__PATH="$(fnFind_command 'apt-get' | sort -V | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.bash_history"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .vimrc --------------------------------------------------------------
	__PATH="$(fnFind_command 'vim' | sort -V | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.vimrc"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			set number              " Print the line number in front of each line.
			set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
			set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
			set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
			set nowrap              " This option changes how text is displayed.
			set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
			set laststatus=2        " The value of this option influences when the last window will have a status line always.
			set mouse-=a            " Disable mouse usage
			syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .curlrc -------------------------------------------------------------
	__PATH="$(fnFind_command 'curl' | sort -V | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.curlrc"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- distribute to existing users ----------------------------------------
	for __DIRS in "${_DIRS_TGET:-}"/root \
	              "${_DIRS_TGET:-}"/home/*
	do
		if [ ! -e "${__DIRS}/." ]; then
			continue
		fi
		for __FILE in "${_DIRS_TGET:-}/etc/skel/.bashrc"       \
		              "${_DIRS_TGET:-}/etc/skel/.bash_history" \
		              "${_DIRS_TGET:-}/etc/skel/.vimrc"        \
		              "${_DIRS_TGET:-}/etc/skel/.curlrc"
		do
			if [ ! -e "${__FILE}" ]; then
				continue
			fi
			__PATH="${__DIRS}/${__FILE#*/etc/skel/}"
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${__FILE}" "${__PATH}"
			chown "${__DIRS##*/}": "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		done
	done
	unset __PATH __CONF __DIRS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: sudoers
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_sudo() {
	__FUNC_NAME="fnSetup_sudo"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	__PATH="$(fnFind_command 'sudo' | sort -V | head -n 1)"
	if [ -z "${__PATH:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- sudoers -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}"/etc/sudoers
	__CONF="${_DIRS_TGET:-}"/usr/etc/sudoers
	if [ ! -e "${__PATH}" ] && [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		if ! grep -qE '^@includedir /etc/sudoers.d$' "${__PATH}" 2> /dev/null; then
			echo "@includedir /etc/sudoers.d" >> "${__PATH}"
		fi
	fi
	fnFile_backup "${__PATH}"			# backup original file
	__CONF="${_DIRS_TGET:-}"/tmp/sudoers-local.work
	__WORK="$(sed -ne 's/^.*\(sudo\|wheel\).*$/\1/p' "${_DIRS_TGET:-}"/etc/group)"
	__WORK="${__WORK:+"$(printf "%-6s %-13s %s" "%${__WORK}" "ALL=(ALL:ALL)" "ALL")"}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CONF}"
		Defaults !targetpw
		#Defaults authenticate
		root   ALL=(ALL:ALL) ALL
		${__WORK:-}
_EOT_
	# --- sudoers-local -------------------------------------------------------
	if visudo -q -c -f "${__CONF}"; then
		__PATH="${_DIRS_TGET:-}/etc/sudoers.d/sudoers-local"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		chown -c root:root "${__PATH}"
		chmod -c 0440 "${__PATH}"
		fnMsgout "${_PROG_NAME:-}" "success" "[${__PATH}]"
		# --- sudoers ---------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/sudoers"
		__CONF="${_DIRS_TGET:-}/tmp/sudoers.work"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		sed "${__PATH}"                                                  \
		    -e '/^Defaults[ \t]\+targetpw[ \t]*/ s/^/#/'                 \
		    -e '/^ALL[ \t]\+ALL=(ALL\(\|:ALL\))[ \t]\+ALL[ \t]*/ s/^/#/' \
		> "${__CONF}"
		if visudo -q -c -f "${__CONF}"; then
			cp --preserve=timestamps "${__CONF}" "${__PATH}"
			chown -c root:root "${__PATH}"
			chmod -c 0440 "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
			fnMsgout "${_PROG_NAME:-}" "success" "[${__PATH}]"
			fnMsgout "${_PROG_NAME:-}" "info" "show user permissions: sudo -ll"
		else
			fnMsgout "${_PROG_NAME:-}" "failed" "[${__CONF}]"
			visudo -c -f "${__CONF}" || true
		fi
	else
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__CONF}]"
		visudo -c -f "${__CONF}" || true
	fi
	fnDbgdump "${__CONF}"				# debugout
	fnFile_backup "${__CONF}" "init"	# backup initial file
	unset __PATH __CONF __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_blacklist() {
	:
}

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetupModule_ipxe() {
	:
}

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_apparmor() {
	__FUNC_NAME="fnSetup_apparmor"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v aa-enabled > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- debug out -----------------------------------------------------------
#	aa-enabled
	aa-status || true

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_selinux() {
	__FUNC_NAME="fnSetup_selinux"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v getenforce > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- backup original file ------------------------------------------------
	find "${_DIRS_TGET:-}/etc/selinux/" \( -name targeted -o -name default \) | while read -r __DIRS
	do
		find "${__DIRS}/contexts/files/" -type f | while read -r __PATH
		do
			fnFile_backup "${__PATH}"
		done
	done
	# --- application ---------------------------------------------------------
	semanage fcontext -a -t var_t                "${_DIRS_SHAR}(/.*)?" || true	# root of shared directory
	semanage fcontext -a -t fusefs_t             "${_DIRS_HGFS}(/.*)?" || true	# root of hgfs shared directory
	semanage fcontext -a -t httpd_user_content_t "${_DIRS_HTML}(/.*)?" || true	# root of html shared directory
	semanage fcontext -a -t samba_share_t        "${_DIRS_SAMB}(/.*)?" || true	# root of samba shared directory
	semanage fcontext -a -t tftpdir_t            "${_DIRS_TFTP}(/.*)?" || true	# root of tftp shared directory
	semanage fcontext -a -t var_t                "${_DIRS_USER}(/.*)?" || true	# root of user shared directory
	# --- user share ----------------------------------------------------------
	semanage fcontext -a -t var_t                "${_DIRS_PVAT}(/.*)?" || true	# root of private contents directory
	semanage fcontext -a -t public_content_t     "${_DIRS_SHAR}(/.*)?" || true	# root of public contents directory
	# --- container -----------------------------------------------------------
	semanage fcontext -a -t public_content_t     "${_DIRS_SHAR}/cache(/.*)?"      || true
	semanage fcontext -a -t container_file_t     "${_DIRS_SHAR}/containers(/.*)?" || true
	# --- flag ----------------------------------------------------------------
	setsebool -P samba_export_all_rw=on   || true			# Determine whether samba can share any content readable and writable.
	setsebool -P httpd_enable_homedirs=on || true			# Determine whether httpd can traverse user home directories.
#	setsebool -P global_ssp=on            || true			# Enable reading of urandom for all domains.
	# --- backup initial file ------------------------------------------------
	find "${_DIRS_TGET:-}/etc/selinux/" \( -name targeted -o -name default \) | while read -r __DIRS
	do
		find "${__DIRS}/contexts/files/" -type f | while read -r __PATH
		do
			fnFile_backup "${__PATH}" "init"
		done
	done
	# --- restore context labels ----------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "restore" "context labels"
	fixfiles onboot || true
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: status")"
		___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : status")"
		fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
		getenforce || true
		if command -v sestatus > /dev/null 2>&1; then
			sestatus || true
		fi
		fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
		___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: fcontext")"
		___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : fcontext")"
		fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
		semanage fcontext -l | grep -E '^/srv' || true
		fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
	fi
	unset __DIRS __PATH ___STRT ___ENDS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: ipfilter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_ipfilter() {
	__FUNC_NAME="fnSetup_ipfilte"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- ipfilter.conf -------------------------------------------------------
#	__PATH="${_DIRS_TGET:-}/usr/lib/systemd/system/systemd-logind.service.d/ipfilter.conf"
#	fnFile_backup "${__PATH}"			# backup original file
#	mkdir -p "${__PATH%/*}"
#	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
#		[Service]
#		IPAddressDeny=any           # 0.0.0.0/0      ::/0
#		IPAddressAllow=localhost    # 127.0.0.0/8    ::1/128
#		IPAddressAllow=link-local   # 169.254.0.0/16 fe80::/64
#		IPAddressAllow=multicast    # 224.0.0.0/4    ff00::/8
#		IPAddressAllow=${NICS_IPV4%.*}.0/${NICS_BIT4}
#_EOT_
#	fnDbgdump "${__PATH}"				# debugout
#	fnFile_backup "${__PATH}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_service() {
	__FUNC_NAME="fnSetup_skel"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	set -f
	set --
	for __LIST in \
		apparmor.service \
		auditd.service \
		firewalld.service \
		clamav-freshclam.service \
		NetworkManager.service \
		systemd-resolved.service \
		dnsmasq.service \
		systemd-timesyncd.service \
		chronyd.service\
		open-vm-tools.service \
		vmtoolsd.service \
		ssh.service \
		sshd.service \
		apache2.service \
		httpd.service \
		smb.service \
		smbd.service \
		nmb.service \
		nmbd.service \
		avahi-daemon.service
	do
		if [ ! -e "${_DIRS_TGET:-}/lib/systemd/system/${__LIST}"     ] \
		&& [ ! -e "${_DIRS_TGET:-}/usr/lib/systemd/system/${__LIST}" ]; then
			continue
		fi
		fnMsgout "${_PROG_NAME:-}" "enable" "${__LIST}"
		set -- "$@" "${__LIST}"
	done 
	set +f
	if [ $# -gt 0 ]; then
		systemctl enable "$@"
		# --- service restart -------------------------------------------------
		if [ -z "${_TGET_CHRT:-}" ]; then
			for __SRVC in "$@"
			do
				if systemctl --quiet is-active "${__SRVC}"; then
					fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
					systemctl --quiet daemon-reload
					if systemctl --quiet restart "${__SRVC}"; then
						fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
					else
						fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
					fi
				fi
			done
		fi
	fi
	unset __LIST __SRVC

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}

#!/bin/sh
# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
fnSetup_grub_menu() {
	__FUNC_NAME="fnSetup_grub_menu"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	# --- /etc/default/grub ---------------------------------------------------
#	__NAME="${_DIST_NAME%"${_DIST_NAME#"${_DIST_NAME%%-*}"}"}"
#	__VERS="${_DIST_VERS%"${_DIST_VERS#"${_DIST_VERS%%.*}"}"}"
	__SLNX="$(fnFind_command "semanage")"
	__APAR="$(fnFind_command "aa-enabled")"
	__PATH="${_DIRS_TGET:-}/etc/default/grub"
	__BOPT="$( \
		sed -ne '/^GRUB_CMDLINE_LINUX_DEFAULT=/ {' \
		    -e  's/^[^=]\+="//'                    \
		    -e  's/[ "]*$//'                       \
		    -e  's/ *security=[^ "]* *//'          \
		    -e  's/ *apparmor=[^ "]* *//'          \
		    -e  's/ *selinux=[^ "]* *//'           \
		    -e  's/ *linux *//'                    \
		    -e  'p}'                               \
		    "${__PATH}"
		)"
	case "${_DIST_NAME:-}" in
		debian|ubuntu)
			  if [ -n "${__APAR:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=apparmor apparmor=1"
			elif [ -n "${__SLNX:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=selinux selinux=1"
			fi
			;;
		fedora|centos|almalinux|rocky|miraclelinux)
			  if [ -n "${__SLNX:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=apparmor apparmor=1"
			fi
			;;
		opensuse-leap)
			if [ "${_DIST_VERS%%.*}" -lt 16 ]; then
				  if [ -n "${__APAR:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=apparmor apparmor=1"
				elif [ -n "${__SLNX:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=selinux selinux=1"
				fi
			else
				  if [ -n "${__SLNX:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=selinux selinux=1"
				elif [ -n "${__APAR:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=apparmor apparmor=1"
				fi
			fi
			;;
		opensuse-tumbleweed)
			  if [ -n "${__SLNX:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __BOPT="${__BOPT:+"${__BOPT} "}security=apparmor apparmor=1"
			fi
			;;
		*) ;;
	esac
	__ENTR='
'
	fnMsgout "${_PROG_NAME:-}" "info" "_DIST_NAME=[${_DIST_NAME:-}]"
	fnMsgout "${_PROG_NAME:-}" "info" "    __BOPT=[${__BOPT:-}]"
#	fnMsgout "${_PROG_NAME:-}" "info" "    __SLNX=[${__SLNX:-}]"
#	fnMsgout "${_PROG_NAME:-}" "info" "    __APAR=[${__APAR:-}]"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if ! grep -q 'GRUB_CMDLINE_LINUX_DEFAULT' "${__PATH}"; then
		sed -i "${__PATH}"                                                \
		    -e '/^GRUB_CMDLINE_LINUX=.*$/i GRUB_CMDLINE_LINUX_DEFAULT=""'
	fi
	sed -i "${__PATH}"                                       \
	    -e '/^GRUB_RECORDFAIL_TIMEOUT=.*$/                {' \
	    -e 'h; s/^/#/; p; g; s/[0-9]\+$/10/                ' \
	    -e '}                                              ' \
	    -e '/^GRUB_TIMEOUT=.*$/                           {' \
	    -e 'h; s/^/#/; p; g; s/[0-9]\+$/3/                 ' \
	    -e '}                                              ' \
	    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=.*$/             {' \
	    -e 'h; s/^/#/; p; g; s/=.*$/="'"${__BOPT:-}"'"/    ' \
	    -e '}'
	diff --suppress-common-lines --expand-tabs --side-by-side "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}" || true
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- grub.cfg ------------------------------------------------------------
	__PATH="$(find "${_DIRS_TGET:-}"/boot/ -ipath '/*/efi' -prune -o -name 'grub.cfg' -print)"
	fnMsgout "${_PROG_NAME:-}" "create" "[${__PATH}]"
	  if command -v grub-mkconfig > /dev/null 2>&1; then
		grub-mkconfig --output "${__PATH:?}"
	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		grub2-mkconfig --output "${__PATH:?}"
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __NAME __VERS __BOPT __SLNX __APAR __LINE __ENTR __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
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
	fnPackage_update					# package updates
	fnMkdir_share						# creating a shared directory

	# --- network manager -----------------------------------------------------
	fnSetup_connman						# connman
	fnSetup_netplan						# netplan
	fnSetup_netman						# network manager

	# --- application setup ---------------------------------------------------
	fnSetup_hostname					# hostname
	fnSetup_hosts						# hosts
#	fnSetup_hosts_access				# hosts.allow/hosts.deny
	fnSetup_firewalld					# firewalld
	fnSetup_dnsmasq						# dnsmasq
	fnSetup_resolv						# resolv.conf
	fnSetup_apache						# apache
	fnSetup_samba						# samba
	fnSetup_timesyncd					# timesyncd
	fnSetup_chronyd						# chronyd
	fnSetup_ssh							# openssh-server
	fnSetup_vmware						# vmware shared directory
	fnSetup_wireplumber					# wireplumber
	fnSetup_skel						# skeleton
	fnSetup_sudo						# sudoers
	fnSetup_blacklist					# blacklist
	fnSetupModule_ipxe					# ipxe module
	fnSetup_apparmor					# apparmor
	fnSetup_selinux						# selinux
	fnSetup_ipfilter					# ipfilter
	fnSetup_service						# service

	# --- booting setup -------------------------------------------------------
	fnSetup_grub_menu					# grub menu settings

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_BACK:-}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${_FUNC_NAME}]"
	unset _FUNC_NAME
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
	unset __time_start __time_end __time_elapsed

	mkdir -p "${_PROG_PATH:?}.success"

	exit 0

# ### eof #####################################################################
