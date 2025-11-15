#!/bin/sh

###############################################################################
#
#	autoinstall (run) shell script
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
	# --- set system parameter ------------------------------------------------
	_DIST_NAME=""						# distribution name (ex. debian)
	_DIST_VERS=""						# release version   (ex. 13)
	_DIST_CODE=""						# code name         (ex. trixie)
	_ROWS_SIZE="25"						# screen size: rows
	_COLS_SIZE="80"						# screen size: columns
	_TEXT_GAP1=""						# gap1
	_TEXT_GAP2=""						# gap2
	# --- network parameter ---------------------------------------------------
	readonly _NTPS_ADDR="ntp.nict.jp"	# ntp server address
	readonly _NTPS_IPV4="61.205.120.130" # ntp server ipv4 address
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
										# login shell (disallow system login to samba user)
	_SHEL_NLIN="$(command -v nologin || true)"
	_SHEL_NLIN="${_SHEL_NLIN:-"$([ -e /usr/sbin/nologin ] && echo "/usr/sbin/nologin")"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$([ -e /sbin/nologin     ] && echo "/sbin/nologin")"}"
	readonly _SHEL_NLIN
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
	readonly _DIRS_VADM="/var/adm"		# top of admin working directory
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

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: message output (debug out)
#   input :     $1     : title
#   input :     $@     : list
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _TEXT_GAP1 : read
fnDbgout() {
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	shift
	fnMsgout "-debugout" "${___STRT}"
	while [ -n "${1:-}" ]
	do
		if [ "${1%%,*}" != "debug" ] || [ -n "${_DBGS_FLAG:-}" ]; then
			fnMsgout "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "-debugout" "${___ENDS}"
}

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : section (start, complete, remove, umount, failed, ...)
#   input :     $2     : message
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
fnMsgout() {
	case "${1:-}" in
		start    | complete)
			case "${2:-}" in
				*/*/*) printf "\033[m${_PROG_NAME:-}: \033[45m--- %-8.8s: %s ---\033[m\n" "${1:-}" "${2:-}";; # date
				*    ) printf "\033[m${_PROG_NAME:-}: \033[92m--- %-8.8s: %s ---\033[m\n" "${1:-}" "${2:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${_PROG_NAME:-}: \033[92m--- %-8.8s: %s ---\033[m\n"    "${1:-}" "${2:-}";; # info
		remove   | umount  ) printf "\033[m${_PROG_NAME:-}:     \033[93m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # warn
		archive            ) printf "\033[m${_PROG_NAME:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${1:-}" "${2:-}";; # warn
		success            ) printf "\033[m${_PROG_NAME:-}:     \033[92m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # info
		failed             ) printf "\033[m${_PROG_NAME:-}:     \033[41m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # alert
		caution            ) printf "\033[m${_PROG_NAME:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${1:-}" "${2:-}";; # warn
		-*                 ) printf "\033[m${_PROG_NAME:-}:     \033[36m%-8.8s: %s\033[m\n"        "${1#-}" "${2:-}";; # gap
		info               ) printf "\033[m${_PROG_NAME:-}: \033[92m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # info
		warn               ) printf "\033[m${_PROG_NAME:-}: \033[93m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # warn
		alert              ) printf "\033[m${_PROG_NAME:-}: \033[91m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # alert
		*                  ) printf "\033[m${_PROG_NAME:-}: \033[37m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # normal
	esac
}

# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
#   g-var : _TGET_VIRT : write
fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var : _TGET_VIRT : write
fnStrmsg() {
	___TXT1="$(echo "${1:-}" | cut -c -3)"
	___TXT2="$(echo "${1:-}" | cut -c "$((${#___TXT1}+2+${#2}+1))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
}

# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :     $1     : value
#   input :     $2     : format (not empty: zero padding)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
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
				num[i]=strtonum("0x"arr[i])
			}
			printf "'"${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}"'",
			num[1],num[2],num[3],num[4],num[5],num[6],num[7],num[8]
		}'
#	___SPRT="$(echo "${___ADDR}" | sed -e 's/[^:]//g')"
#	___LENG=$((7-${#___SPRT}))
#	if [ "${___LENG}" -gt 0 ]; then
#		___SPRT="$(printf ':%.s' $(seq 1 $((___LENG+2))) || true)"
#		___ADDR="$(echo "${___ADDR}" | sed -e "s/::/${___SPRT}/")"
#	fi
#	___OCT1="$(echo "${___ADDR}" | cut -d ':' -f 1)"
#	___OCT2="$(echo "${___ADDR}" | cut -d ':' -f 2)"
#	___OCT3="$(echo "${___ADDR}" | cut -d ':' -f 3)"
#	___OCT4="$(echo "${___ADDR}" | cut -d ':' -f 4)"
#	___OCT5="$(echo "${___ADDR}" | cut -d ':' -f 5)"
#	___OCT6="$(echo "${___ADDR}" | cut -d ':' -f 6)"
#	___OCT7="$(echo "${___ADDR}" | cut -d ':' -f 7)"
#	___OCT8="$(echo "${___ADDR}" | cut -d ':' -f 8)"
#	printf "${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}" \
#	    "0x${___OCT1:-"0"}" \
#	    "0x${___OCT2:-"0"}" \
#	    "0x${___OCT3:-"0"}" \
#	    "0x${___OCT4:-"0"}" \
#	    "0x${___OCT5:-"0"}" \
#	    "0x${___OCT6:-"0"}" \
#	    "0x${___OCT7:-"0"}" \
#	    "0x${___OCT8:-"0"}"
}

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
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
#   g-var :            : unused
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
				h=xor(0xFFFFFFFF,lshift($1,24)+lshift($2,16)+lshift($3,8)+$4)
				n=32
				if (h>0) {
					n-=int(log(h)/log(2)+1)
				}
				printf "%d",n
			}
		}'
}

# -----------------------------------------------------------------------------
# descript: detecting target virtualization
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _TGET_VIRT : write
fnDetect_virt() {
	if ! command -v systemd-detect-virt > /dev/null 2>&1; then
		return
	fi
	_TGET_VIRT="$(systemd-detect-virt || true)"
	readonly _TGET_VIRT
}

# -----------------------------------------------------------------------------
# descript: get system parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIST_NAME : write
#   g-var : _DIST_VERS : write
#   g-var : _DIST_CODE : write
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
#   g-var : _DIRS_TGET : read
#   g-var : _NICS_NAME : write
#   g-var : _DIST_VERS : write
#   g-var : _DIST_CODE : write
fnNetwork_param() {
	___DIRS="${_DIRS_TGET:-}/sys/devices"
	_NICS_NAME="${_NICS_NAME:-"ens160"}"
	if [ ! -e "${___DIRS}"/. ]; then
		fnMsgout "caution" "not exist: [${___DIRS}]"
	else
		if [ -z "${_NICS_NAME#*"*"}" ]; then
#			_NICS_NAME="$(find "${___DIRS}" -name 'net' -not -path '*/virtual/*' -exec ls '{}' \; | grep -E "${_NICS_NAME}" | sort | head -n 1)"
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' -not -path '*/virtual/*' -prune -name "${_NICS_NAME}" -printf "%f" | sort | head -n 1)"
		fi
#		if ! find "${___DIRS}" -name 'net' -not -path '*/virtual/*' -exec ls '{}' \; | grep -qE '^'"${_NICS_NAME}"'$'; then
		if ! find "${___DIRS}" -path '*/net/*' -not -path '*/virtual/*' -prune -name "${_NICS_NAME}" -printf "%f" | grep -qE '^'"${_NICS_NAME}"'$'; then
			fnMsgout "failed" "not exist: [${_NICS_NAME}]"
		else
			_NICS_MADR="${_NICS_MADR:-"$(ip -0 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			_NICS_IPV4="${_NICS_IPV4:-"$(ip -4 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			if ip -4 -oneline address show dev "${_NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
				_NICS_AUTO="dhcp"
			fi
			if [ -z "${_NICS_DNS4:-}" ] || [ -z "${_NICS_WGRP:-}" ]; then
				if command -v resolvectl > /dev/null 2>&1; then
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
	__WORK="$(echo "${_NICS_IPV4:-}" | sed 's/[^0-9./]\+//g')"
	_NICS_IPV4="$(echo "${__WORK}/" | cut -d '/' -f 1)"
	_NICS_BIT4="$(echo "${__WORK}/" | cut -d '/' -f 2)"
	if [ -z "${_NICS_BIT4}" ]; then
		_NICS_BIT4="$(fnIPv4Netmask "${_NICS_MASK:-"255.255.255.0"}")"
	else
		_NICS_MASK="$(fnIPv4Netmask "${_NICS_BIT4:-"24"}")"
	fi
	_NICS_GATE="${_NICS_GATE:-"$(ip -4 -brief route list match default | awk '{print $3;}' | uniq)"}"
	_NICS_FQDN="${_NICS_FQDN:-"$(cat "${_DIRS_TGET:-}/etc/hostname" || true)"}"
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
#   g-var : _DIRS_TGET : read
#   g-var : _DIRS_SAMP : read
#   g-var : _DIRS_INIT : read
#   g-var : _DIRS_ORIG : read
# --- file backup -------------------------------------------------------------
fnFile_backup() {
	___PATH="${1:?}"
	___MODE="${2:-}"
	# --- check ---------------------------------------------------------------
	if [ ! -e "${___PATH}" ]; then
		fnMsgout "caution" "not exist: [${___PATH}]"
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
	if [ -e "${___BACK}" ] || [ -L "${___BACK}" ]; then
		___BACK="${___BACK}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	fi
	fnMsgout "backup" "[${___PATH}]${_DBGS_FLAG:+" -> [${___BACK}]"}"
	cp -a "${___PATH}" "${___BACK}"
}

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : TERM       : read
#   g-var : _ROWS_SIZE : write
#   g-var : _COLS_SIZE : write
#   g-var : _TEXT_GAP1 : write
#   g-var : _TEXT_GAP2 : write
#   g-var : _TGET_VIRT : read
#   g-var : _DIST_NAME : read
#   g-var : _DIST_VERS : read
#   g-var : _DIST_CODE : read
#   g-var : _NICS_NAME : read
#   g-var : _NICS_MADR : read
#   g-var : _NICS_IPV4 : read
#   g-var : _NICS_MASK : read
#   g-var : _NICS_BIT4 : read
#   g-var : _NICS_DNS4 : read
#   g-var : _NICS_GATE : read
#   g-var : _NICS_FQDN : read
#   g-var : _NICS_HOST : read
#   g-var : _NICS_WGRP : read
#   g-var : _NMAN_FLAG : read
#   g-var : _NTPS_ADDR : read
#   g-var : _NTPS_IPV4 : read
#   g-var : _IPV6_LHST : read
#   g-var : _IPV4_LHST : read
#   g-var : _IPV4_DUMY : read
#   g-var : _IPV4_UADR : read
#   g-var : _IPV4_LADR : read
#   g-var : _IPV6_ADDR : read
#   g-var : _IPV6_CIDR : read
#   g-var : _IPV6_FADR : read
#   g-var : _IPV6_UADR : read
#   g-var : _IPV6_LADR : read
#   g-var : _IPV6_RADR : read
#   g-var : _LINK_ADDR : read
#   g-var : _LINK_CIDR : read
#   g-var : _LINK_FADR : read
#   g-var : _LINK_UADR : read
#   g-var : _LINK_LADR : read
#   g-var : _LINK_RADR : read
#   g-var : _FWAL_ZONE : read
#   g-var : _FWAL_NAME : read
#   g-var : _FWAL_PORT : read
#   g-var : _DIRS_TOPS : write
#   g-var : _DIRS_HGFS : write
#   g-var : _DIRS_HTML : write
#   g-var : _DIRS_SAMB : write
#   g-var : _DIRS_TFTP : write
#   g-var : _DIRS_USER : write
#   g-var : _DIRS_PVAT : write
#   g-var : _DIRS_SHAR : write
#   g-var : _DIRS_CONF : write
#   g-var : _DIRS_DATA : write
#   g-var : _DIRS_KEYS : write
#   g-var : _DIRS_MKOS : write
#   g-var : _DIRS_TMPL : write
#   g-var : _DIRS_SHEL : write
#   g-var : _DIRS_IMGS : write
#   g-var : _DIRS_ISOS : write
#   g-var : _DIRS_LOAD : write
#   g-var : _DIRS_RMAK : write
#   g-var : _DIRS_CACH : write
#   g-var : _DIRS_CTNR : write
#   g-var : _DIRS_CHRT : write
#   g-var : _DIRS_ORIG : read
#   g-var : _DIRS_INIT : read
#   g-var : _DIRS_SAMP : read
#   g-var : _DIRS_LOGS : read
#   g-var : _SAMB_USER : read
#   g-var : _SAMB_GRUP : read
#   g-var : _SAMB_GADM : read
#   g-var : _SHEL_NLIN : read
fnInitialize() {
	__FUNC_NAME="fnInitialize"
	fnMsgout "start" "[${__FUNC_NAME}]"

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

	# --- target virtualization -----------------------------------------------
	fnDetect_virt

	_DIRS_TGET=""
	for __DIRS in \
		/target \
		/mnt/sysimage/root \
		/mnt/root
	do
		[ ! -e "${__DIRS}"/. ] && continue
		_DIRS_TGET="${__DIRS}"
	done

	# --- system parameter ----------------------------------------------------
	fnSystem_param
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_DIRS_TGET=[${_DIRS_TGET:-}]" \
		"info,_DIST_NAME=[${_DIST_NAME:-}]" \
		"info,_DIST_VERS=[${_DIST_VERS:-}]" \
		"info,_DIST_CODE=[${_DIST_CODE:-}]"

	# --- network parameter ---------------------------------------------------
	fnNetwork_param
	fnDbgout "network info" \
		"info,_NICS_NAME=[${_NICS_NAME:-}]" \
		"debug,_NICS_MADR=[${_NICS_MADR:-}]" \
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
										# top of working directory
	_DIRS_INST="${_DIRS_VADM:?}/${_PROG_NAME%%_*}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	readonly _DIRS_INST							# auto-install working directory
	readonly _DIRS_BACK="${_DIRS_INST}"			# top of backup directory
	readonly _DIRS_ORIG="${_DIRS_BACK}/orig"	# original file directory
	readonly _DIRS_INIT="${_DIRS_BACK}/init"	# initial file directory
	readonly _DIRS_SAMP="${_DIRS_BACK}/samp"	# sample file directory
	readonly _DIRS_LOGS="${_DIRS_BACK}/logs"	# log file directory
	fnDbgout "working directory" \
		"debug,_DIRS_VADM=[${_DIRS_VADM:-}]" \
		"debug,_DIRS_INST=[${_DIRS_INST:-}]" \
		"debug,_DIRS_BACK=[${_DIRS_BACK:-}]" \
		"debug,_DIRS_ORIG=[${_DIRS_ORIG:-}]" \
		"debug,_DIRS_INIT=[${_DIRS_INIT:-}]" \
		"debug,_DIRS_SAMP=[${_DIRS_SAMP:-}]" \
		"debug,_DIRS_LOGS=[${_DIRS_LOGS:-}]" \

	find "${_DIRS_TGET:-}${_DIRS_VADM:?}" -name "${_PROG_NAME%%_*}.[0-9]*" -type d | sort -r | tail -n +3 | \
	while read -r __TGET
	do
		__PATH="${__TGET}.tgz"
		fnMsgout "archive" "[${__TGET}] -> [${__PATH}]"
		if tar -C "${__TGET}" -czf "${__PATH}" .; then
			chmod 600 "${__PATH}"
			fnMsgout "remove"  "${__TGET}"
			rm -rf "${__TGET:?}"
		fi
	done
	mkdir -p "${_DIRS_TGET:-}${_DIRS_INST:?}"
	chmod 600 "${_DIRS_TGET:-}${_DIRS_INST:?}"

	# --- samba ---------------------------------------------------------------
	fnDbgout "samba info" \
		"debug,_SAMB_USER=[${_SAMB_USER:-}]" \
		"debug,_SAMB_GRUP=[${_SAMB_GRUP:-}]" \
		"debug,_SAMB_GADM=[${_SAMB_GADM:-}]" \
		"debug,_SHEL_NLIN=[${_SHEL_NLIN:-}]"

	# --- debug backup---------------------------------------------------------
	fnFile_backup "/proc/cmdline"
	fnFile_backup "/proc/mounts"
	fnFile_backup "/proc/self/mounts"

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
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
	fnMsgout "start" "[${_FUNC_NAME}]"

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize

	# --- main processing -----------------------------------------------------
	/bin/kill-all-dhcp
	/bin/netcfg

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		tree --charset C -n --filesfirst "${_DIRS_BACK:-}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${_FUNC_NAME}]"
}

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

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
	fnMsgout "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################
