#!/bin/sh

# *** initialization **********************************************************

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
	trap 'exit 1' 1 2 3 15
	export LANG=C

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- working directory name ----------------------------------------------
	readonly PROG_PATH="$0"
	readonly PROG_PRAM="$*"
	readonly PROG_DIRS="${PROG_PATH%/*}"
	readonly PROG_NAME="${PROG_PATH##*/}"
	readonly PROG_PROC="${PROG_NAME}.$$"
	#--- initial settings  ----------------------------------------------------
	NTPS_ADDR="ntp.nict.jp"				# ntp server address
	NTPS_IPV4="61.205.120.130"			# ntp server ipv4 address
	IPV6_LHST="::1"						# ipv6 local host address
	IPV4_LHST="127.0.0.1"				# ipv4 local host address
	IPV4_DUMY="127.0.1.1"				# ipv4 dummy address
	OLDS_FQDN="$(cat /etc/hostname)"	# old hostname (fqdn)
	OLDS_HOST="$(echo "${OLDS_FQDN}." | cut -d '.' -f 1)"	# old hostname (host name)
	OLDS_WGRP="$(echo "${OLDS_FQDN}." | cut -d '.' -f 2)"	# old hostname (domain)
	# --- firewalld -----------------------------------------------------------
	FWAL_ZONE="home_use"				# firewalld zone
										# firewalld service name
	FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
	FWAL_PORT="0-65535/tcp 0-65535/udp"	# firewalld port
	# --- command line parameter ----------------------------------------------
	COMD_LINE="$(cat /proc/cmdline)"	# command line parameter
	IPV4_DHCP=""						# true: dhcp, else: fixed address
	NICS_NAME=""						# nic if name   (ex. ens160)
	NICS_MADR=""						# nic if mac    (ex. 00:00:00:00:00:00)
	NICS_IPV4=""						# ipv4 address  (ex. 192.168.1.1)
	NICS_MASK=""						# ipv4 netmask  (ex. 255.255.255.0)
	NICS_BIT4=""						# ipv4 cidr     (ex. 24)
	NICS_DNS4=""						# ipv4 dns      (ex. 192.168.1.254)
	NICS_GATE=""						# ipv4 gateway  (ex. 192.168.1.254)
	NICS_FQDN=""						# hostname fqdn (ex. sv-server.workgroup)
	NICS_HOST=""						# hostname      (ex. sv-server)
	NICS_WGRP=""						# domain        (ex. workgroup)
	NMAN_FLAG=""						# nm_config, ifupdown, loopback
	ISOS_FILE=""						# iso file name
	SEED_FILE=""						# preseed file name
	# --- set system parameter ------------------------------------------------
	DBGS_FLAG="${_DBGOUT:-}"			# debug flag (true: debug, else: normal)
	DIST_NAME=""						# distribution name (ex. debian)
	DIST_VERS=""						# release version   (ex. 12)
	DIST_CODE=""						# code name         (ex. bookworm)
	DIRS_TGET=""						# target directory
	if command -v systemd-detect-virt > /dev/null 2>&1 \
	&& systemd-detect-virt --chroot; then
		CHGE_ROOT="true"
	fi
	if [ -d /target/. ]; then
		DIRS_TGET="/target"
	elif [ -d /mnt/sysimage/. ]; then
		DIRS_TGET="/mnt/sysimage"
	fi
	readonly DIRS_TGET
	if [ -n "${DIRS_TGET:-}" ] \
	&& [ "${CHGE_ROOT:-}" = "true" ]; then
		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "chroot start"
		mount --rbind /dev  "${DIRS_TGET:-}"/dev
		mount --rbind /proc "${DIRS_TGET:-}"/proc
		mount --rbind /run  "${DIRS_TGET:-}"/run
		mount --rbind /sys  "${DIRS_TGET:-}"/sys
		mount --rbind /tmp  "${DIRS_TGET:-}"/tmp
		mount --make-rslave "${DIRS_TGET:-}"/dev
		mount --make-rslave "${DIRS_TGET:-}"/sys
		systemctl daemon-reload
		mkdir -p "${DIRS_TGET:?}${PROG_DIRS}"
		cp -a "${PROG_PATH:?}" "${DIRS_TGET:?}${PROG_DIRS}"
		chroot "${DIRS_TGET:-}"/ sh -c "${PROG_DIRS}/${PROG_NAME}"
		# shellcheck disable=SC2046
		umount $(awk '{print $2;}' /proc/mounts | grep "${DIRS_TGET:-}" | sort -r || true)
		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "chroot complete"
	fi
	ROWS_SIZE="25"						# screen size: rows
	COLS_SIZE="80"						# screen size: columns
	TEXT_GAP1=""						# gap1
	TEXT_GAP2=""						# gap2
	# --- network parameter ---------------------------------------------------
	IPV4_UADR=""						# IPv4 address up   (ex. 192.168.1)
	IPV4_LADR=""						# IPv4 address low  (ex. 1)
	IPV6_ADDR=""						# IPv6 address      (ex. ::1)
	IPV6_CIDR=""						# IPv6 cidr         (ex. 64)
	IPV6_FADR=""						# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	IPV6_UADR=""						# IPv6 address up   (ex. 0000:0000:0000:0000)
	IPV6_LADR=""						# IPv6 address low  (ex. 0000:0000:0000:0001)
	IPV6_RADR=""						# IPv6 reverse addr (ex. ...)
	LINK_ADDR=""						# LINK address      (ex. fe80::1)
	LINK_CIDR=""						# LINK cidr         (ex. 64)
	LINK_FADR=""						# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	LINK_UADR=""						# LINK address up   (ex. fe80:0000:0000:0000)
	LINK_LADR=""						# LINK address low  (ex. 0000:0000:0000:0001)
	LINK_RADR=""						# LINK reverse addr (ex. ...)
	# --- samba parameter -----------------------------------------------------
	readonly SAMB_USER="sambauser"							# force user
	readonly SAMB_GRUP="sambashare"							# force group
	readonly SAMB_GADM="sambaadmin"							# admin group
	LGIN_SHEL="$(command -v nologin)"						# login shell (disallow system login to samba user)
	readonly LGIN_SHEL
	# --- directory parameter -------------------------------------------------
	readonly DIRS_SRVR="${DIRS_TGET:-}/srv"					# root of shared directory
	readonly DIRS_HGFS="${DIRS_TGET:-}${DIRS_SRVR}/hgfs"	# root of hgfs shared directory
	readonly DIRS_HTML="${DIRS_TGET:-}${DIRS_SRVR}/http"	# root of html shared directory
	readonly DIRS_TFTP="${DIRS_TGET:-}${DIRS_SRVR}/tftp"	# root of tftp shared directory
	readonly DIRS_SAMB="${DIRS_TGET:-}${DIRS_SRVR}/samba"	# root of samba shared directory
	readonly DIRS_USER="${DIRS_TGET:-}${DIRS_SRVR}/user"	# root of user shared directory

	# --- set command line parameter ------------------------------------------
	for LINE in ${COMD_LINE:-} ${PROG_PRAM:-}
	do
		case "${LINE}" in
			debug | debugout | dbg         ) DBGS_FLAG="true";;
			target=*                       ) DIRS_TGET="${LINE#*target=}";;
			iso-url=*.iso  | url=*.iso     ) ISOS_FILE="${LINE#*url=}";;
			preseed/url=*  | url=*         ) SEED_FILE="${LINE#*url=}";;
			preseed/file=* | file=*        ) SEED_FILE="${LINE#*file=}";;
			ds=nocloud*                    ) SEED_FILE="${LINE#*ds=nocloud*=}";SEED_FILE="${SEED_FILE%%/}/user-data";;
			inst.ks=*                      ) SEED_FILE="${LINE#*inst.ks=}";;
			autoyast=*                     ) SEED_FILE="${LINE#*autoyast=}";;
			netcfg/target_network_config=* ) NMAN_FLAG="${LINE#*target_network_config=}";;
			netcfg/choose_interface=*      ) NICS_NAME="${LINE#*choose_interface=}";;
			netcfg/disable_dhcp=*          ) IPV4_DHCP="$([ "${LINE#*disable_dhcp=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/disable_autoconfig=*    ) IPV4_DHCP="$([ "${LINE#*disable_autoconfig=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/get_ipaddress=*         ) NICS_IPV4="${LINE#*get_ipaddress=}";;
			netcfg/get_netmask=*           ) NICS_MASK="${LINE#*get_netmask=}";;
			netcfg/get_gateway=*           ) NICS_GATE="${LINE#*get_gateway=}";;
			netcfg/get_nameservers=*       ) NICS_DNS4="${LINE#*get_nameservers=}";;
			netcfg/get_hostname=*          ) NICS_FQDN="${LINE#*get_hostname=}";;
			netcfg/get_domain=*            ) NICS_WGRP="${LINE#*get_domain=}";;
			interface=*                    ) NICS_NAME="${LINE#*interface=}";;
			hostname=*                     ) NICS_FQDN="${LINE#*hostname=}";;
			domain=*                       ) NICS_WGRP="${LINE#*domain=}";;
			nameserver=*                   ) NICS_DNS4="${LINE#*nameserver=}";;
			ip=dhcp | ip4=dhcp | ipv4=dhcp ) IPV4_DHCP="true";;
			ip=* | ip4=* | ipv4=*          ) IPV4_DHCP="false"
			                                 NICS_IPV4="$(echo "${LINE#*ip*=}" | cut -d ':' -f 1)"
			                                 NICS_GATE="$(echo "${LINE#*ip*=}" | cut -d ':' -f 3)"
			                                 NICS_MASK="$(echo "${LINE#*ip*=}" | cut -d ':' -f 4)"
			                                 NICS_FQDN="$(echo "${LINE#*ip*=}" | cut -d ':' -f 5)"
			                                 NICS_NAME="$(echo "${LINE#*ip*=}" | cut -d ':' -f 6)"
			                                 NICS_DNS4="$(echo "${LINE#*ip*=}" | cut -d ':' -f 8)"
			                                 ;;
			ifcfg=*                        ) NICS_NAME="$(echo "${LINE#*ifcfg*=}"         | cut -d '=' -f 1)"
			                                 NICS_IPV4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 1)"
			                                 case "${NICS_IPV4}" in
			                                     dhcp)
			                                         IPV4_DHCP="true"
			                                         NICS_IPV4=""
			                                         NICS_GATE=""
			                                         NICS_DNS4=""
			                                         NICS_WGRP=""
			                                         ;;
			                                     *)
			                                         IPV4_DHCP="false"
			                                         NICS_IPV4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 1)"
			                                         NICS_GATE="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 2)"
			                                         NICS_DNS4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 3)"
			                                         NICS_WGRP="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 4)"
			                                         ;;
			                                 esac
			                                 ;;
			*)  ;;
		esac
	done

	# --- working directory name ----------------------------------------------
	readonly DIRS_ORIG="${PROG_DIRS}/orig"			# original file directory
	readonly DIRS_INIT="${PROG_DIRS}/init"			# initial file directory
	readonly DIRS_LOGS="${PROG_DIRS}/logs"			# log file directory

	# --- log out -------------------------------------------------------------
	if [ -n "${DBGS_FLAG:-}" ] \
	&& command -v mkfifo > /dev/null 2>&1; then
		LOGS_NAME="${DIRS_LOGS}/${PROG_NAME%.*}.$(date +"%Y%m%d%H%M%S").log"
		mkdir -p "${LOGS_NAME%/*}"
		SOUT_PIPE="/tmp/${PROG_PROC}.stdout_pipe"
		SERR_PIPE="/tmp/${PROG_PROC}.stderr_pipe"
		trap 'rm -f '"${SOUT_PIPE}"' '"${SERR_PIPE}"'' EXIT
		mkfifo "${SOUT_PIPE}" "${SERR_PIPE}"
		: > "${LOGS_NAME}"
		tee -a "${LOGS_NAME}" < "${SOUT_PIPE}" &
		tee -a "${LOGS_NAME}" < "${SERR_PIPE}" >&2 &
		exec > "${SOUT_PIPE}" 2> "${SERR_PIPE}"
	fi

### common ####################################################################

# --- IPv6 full address -------------------------------------------------------
funcIPv6GetFullAddr() {
	_ADDRESS="${1:?}"
	if [ -z "${2:-}" ]; then
		_FORMAT="%x:%x:%x:%x:%x:%x:%x:%x"
	else
		_FORMAT="%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"
	fi
	_SEPARATOR="$(echo "${_ADDRESS}" | sed -e 's/[^:]//g')"
	_LENGTH=$((7-${#_SEPARATOR}))
	if [ "${_LENGTH}" -gt 0 ]; then
		_SEPARATOR="$(printf ':%.s' $(seq 1 $((_LENGTH+2))) || true)"
		_ADDRESS="$(echo "${_ADDRESS}" | sed -e "s/::/${_SEPARATOR}/")"
	fi
	_OCTETS1="$(echo "${_ADDRESS}" | cut -d ':' -f 1)"
	_OCTETS2="$(echo "${_ADDRESS}" | cut -d ':' -f 2)"
	_OCTETS3="$(echo "${_ADDRESS}" | cut -d ':' -f 3)"
	_OCTETS4="$(echo "${_ADDRESS}" | cut -d ':' -f 4)"
	_OCTETS5="$(echo "${_ADDRESS}" | cut -d ':' -f 5)"
	_OCTETS6="$(echo "${_ADDRESS}" | cut -d ':' -f 6)"
	_OCTETS7="$(echo "${_ADDRESS}" | cut -d ':' -f 7)"
	_OCTETS8="$(echo "${_ADDRESS}" | cut -d ':' -f 8)"
	# shellcheck disable=SC2059
	printf "${_FORMAT}" \
	    "0x${_OCTETS1:-"0"}" \
	    "0x${_OCTETS2:-"0"}" \
	    "0x${_OCTETS3:-"0"}" \
	    "0x${_OCTETS4:-"0"}" \
	    "0x${_OCTETS5:-"0"}" \
	    "0x${_OCTETS6:-"0"}" \
	    "0x${_OCTETS7:-"0"}" \
	    "0x${_OCTETS8:-"0"}"
}

# --- ipv4 netmask conversion -------------------------------------------------
funcIPv4GetNetmask() {
	_OCTETS1="$(echo "${1:?}." | cut -d '.' -f 1)"
	_OCTETS2="$(echo "${1:?}." | cut -d '.' -f 2)"
	_OCTETS3="$(echo "${1:?}." | cut -d '.' -f 3)"
	_OCTETS4="$(echo "${1:?}." | cut -d '.' -f 4)"
	if [ -n "${_OCTETS1:-}" ] && [ -n "${_OCTETS2:-}" ] && [ -n "${_OCTETS3:-}" ] && [ -n "${_OCTETS4:-}" ]; then
		# --- netmask -> cidr -------------------------------------------------
		_MASK=0
		for _OCTETS in "${_OCTETS1}" "${_OCTETS2}" "${_OCTETS3}" "${_OCTETS4}"
		do
			case "${_OCTETS}" in
				  0) _MASK=$((_MASK+0));;
				128) _MASK=$((_MASK+1));;
				192) _MASK=$((_MASK+2));;
				224) _MASK=$((_MASK+3));;
				240) _MASK=$((_MASK+4));;
				248) _MASK=$((_MASK+5));;
				252) _MASK=$((_MASK+6));;
				254) _MASK=$((_MASK+7));;
				255) _MASK=$((_MASK+8));;
				*  )                 ;;
			esac
		done
		printf '%d' "${_MASK}"
	else
		# --- cidr -> netmask -------------------------------------------------
		_LOOP=$((32-${1:?}))
		_WORK=1
		_DEC_ADDR=""
		while [ "${_LOOP}" -gt 0 ]
		do
			_LOOP=$((_LOOP-1))
			_WORK=$((_WORK*2))
		done
		_DEC_ADDR="$((0xFFFFFFFF ^ (_WORK-1)))"
		printf '%d.%d.%d.%d'              \
		    $(( _DEC_ADDR >> 24        )) \
		    $(((_DEC_ADDR >> 16) & 0xFF)) \
		    $(((_DEC_ADDR >>  8) & 0xFF)) \
		    $(( _DEC_ADDR        & 0xFF))
	fi
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
}

# --- string output -----------------------------------------------------------
funcString() {
	echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
}

# --- service status ----------------------------------------------------------
funcServiceStatus() {
	_SRVC_STAT="$(systemctl "$@" 2> /dev/null || true)"
	case "$?" in
		4) _SRVC_STAT="not-found";;		# no such unit
		*) _SRVC_STAT="${_SRVC_STAT%-*}";;
	esac
	echo "${_SRVC_STAT:-"undefined"}"

# systemctl return codes
#-------+--------------------------------------------------+-------------------------------------#
# Value | Description in LSB                               | Use in systemd                      #
#    0  | "program is running or service is OK"            | unit is active                      #
#    1  | "program is dead and /var/run pid file exists"   | unit not failed (used by is-failed) #
#    2  | "program is dead and /var/lock lock file exists" | unused                              #
#    3  | "program is not running"                         | unit is not active                  #
#    4  | "program or service status is unknown"           | no such unit                        #
#-------+--------------------------------------------------+-------------------------------------#
}

# --- install package ---------------------------------------------------------
#funcInstallPackage() {
#	if command -v apt > /dev/null 2>&1; then
#		LANG=C apt list "${1:?}" 2> /dev/null | sed -ne '\%^'"$1"'/.*\[installed.*\]%p' || true
#	elif command -v yum > /dev/null 2>&1; then
#		LANG=C yum list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
#	elif command -v dnf > /dev/null 2>&1; then
#		LANG=C dnf list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
#	elif command -v zypper > /dev/null 2>&1; then
#		LANG=C zypper se -i "${1:?}" 2> /dev/null | sed -ne '/^[ \t]'"$1"'[ \t]/p' || true
#	fi
#}

### subroutine ################################################################

# --- debug out parameter -----------------------------------------------------
funcDebugout_parameter() {
	if [ -z "${DBGS_FLAG:-}" ]; then
		return
	fi

	__FUNC_NAME="funcDebugout_parameter"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
	printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "--- debut out start ---"
	# --- change root ---------------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "CHGE_ROOT" "${CHGE_ROOT:-}"
	# --- screen parameter ----------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "TERM"      "${TERM:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "ROWS_SIZE" "${ROWS_SIZE:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "COLS_SIZE" "${COLS_SIZE:-}"
	# --- working directory name ----------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PATH" "${PROG_PATH:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PRAM" "${PROG_PRAM:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_DIRS" "${PROG_DIRS:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_NAME" "${PROG_NAME:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PROC" "${PROG_PROC:-}"
	# -------------------------------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_TGET" "${DIRS_TGET:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_ORIG" "${DIRS_ORIG:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_INIT" "${DIRS_INIT:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_LOGS" "${DIRS_LOGS:-}"
	#--- initial settings  ----------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NTPS_ADDR" "${NTPS_ADDR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NTPS_IPV4" "${NTPS_IPV4:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_LHST" "${IPV6_LHST:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_LHST" "${IPV4_LHST:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_DUMY" "${IPV4_DUMY:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_FQDN" "${OLDS_FQDN:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_HOST" "${OLDS_HOST:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_WGRP" "${OLDS_WGRP:-}"
	# --- command line parameter ----------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "COMD_LINE" "${COMD_LINE:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_DHCP" "${IPV4_DHCP:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_NAME" "${NICS_NAME:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_MADR" "${NICS_MADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_IPV4" "${NICS_IPV4:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_BIT4" "${NICS_BIT4:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_MASK" "${NICS_MASK:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_DNS4" "${NICS_DNS4:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_GATE" "${NICS_GATE:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_FQDN" "${NICS_FQDN:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_HOST" "${NICS_HOST:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_WGRP" "${NICS_WGRP:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NMAN_FLAG" "${NMAN_FLAG:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "ISOS_FILE" "${ISOS_FILE:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SEED_FILE" "${SEED_FILE:-}"
	# --- firewalld -----------------------------------------------------------
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_ZONE" "${FWAL_ZONE:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_NAME" "${FWAL_NAME:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_PORT" "${FWAL_PORT:-}"
	# --- set system parameter ------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DBGS_FLAG" "${DBGS_FLAG:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_NAME" "${DIST_NAME:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_VERS" "${DIST_VERS:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_CODE" "${DIST_CODE:-}"
	# --- network parameter ---------------------------------------------------
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_UADR" "${IPV4_UADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_LADR" "${IPV4_LADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_ADDR" "${IPV6_ADDR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_CIDR" "${IPV6_CIDR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_FADR" "${IPV6_FADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_UADR" "${IPV6_UADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_LADR" "${IPV6_LADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_RADR" "${IPV6_RADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_ADDR" "${LINK_ADDR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_CIDR" "${LINK_CIDR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_FADR" "${LINK_FADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_UADR" "${LINK_UADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_LADR" "${LINK_LADR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_RADR" "${LINK_RADR:-}"
	# --- samba parameter -----------------------------------------------------
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_USER" "${SAMB_USER:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_GRUP" "${SAMB_GRUP:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_GADM" "${SAMB_GADM:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LGIN_SHEL" "${LGIN_SHEL:-}"
	# --- directory parameter -------------------------------------------------
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_SRVR" "${DIRS_SRVR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_HTML" "${DIRS_HTML:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_TFTP" "${DIRS_TFTP:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_SHAR" "${DIRS_SHAR:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_USER" "${DIRS_USER:-}"
	# -------------------------------------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "--- debut out complete ---"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- debug out file ----------------------------------------------------------
funcDebugout_file() {
	if [ -z "${DBGS_FLAG:-}" ]; then
		return
	fi
	if [ ! -e "${1:-}" ]; then
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist: [${1:-}]"
		return
	fi

	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out start: --- [${1:-}] ---"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	cat "${1:-}"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out end: --- [${1:-}] ---"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
}

# --- initialize --------------------------------------------------------------
funcInitialize() {
	__FUNC_NAME="funcInitialize"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- set system parameter ------------------------------------------------
	if [ -n "${TERM:-}" ] \
	&& command -v tput > /dev/null 2>&1; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [ "${ROWS_SIZE}" -lt 25 ]; then
		ROWS_SIZE=25
	fi
	if [ "${COLS_SIZE}" -lt 80 ]; then
		COLS_SIZE=80
	fi

	readonly ROWS_SIZE
	readonly COLS_SIZE

	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"		# work
	TEXT_GAP1="$(funcString "${TEXT_GAPS}" '-')"
	TEXT_GAP2="$(funcString "${TEXT_GAPS}" '=')"

	readonly TEXT_GAP1
	readonly TEXT_GAP2

	# --- distribution information --------------------------------------------
	if [ -e "${DIRS_TGET:-}/etc/os-release" ]; then
		DIST_NAME="$(sed -ne 's/^ID=//p'                                "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
		DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                  "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
		DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p' "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
	elif [ -e "${DIRS_TGET:-}/etc/lsb-release" ]; then
		DIST_NAME="$(sed -ne 's/DISTRIB_ID=//p'                                     "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
		DIST_CODE="$(sed -ne 's/^VERSION=\".*(\([[:graph:]]\+\)).*\"$/\1/p'         "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
		DIST_VERS="$(sed -ne 's/DISTRIB_RELEASE=\"\([[:graph:]]\+\)[ \t].*\"$/\1/p' "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
	fi

	# --- ntp server ipv4 address ---------------------------------------------
	NTPS_IPV4="${NTPS_IPV4:-"$(dig "${NTPS_ADDR}" | awk '/^ntp.nict.jp./ {print $5;}' | sort -V | head -n 1)"}"

	# --- network information -------------------------------------------------
	NICS_NAME="${NICS_NAME:-"$(ip -4 -oneline address show primary | grep -E '^2:' | cut -d ' ' -f 2)"}"
	NICS_NAME="${NICS_NAME:-"ens160"}"
	if [ -z "${IPV4_DHCP:-}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/network/interfaces"
		_WORK_TEXT=""
		if [ -e "${_FILE_PATH}" ]; then
			_WORK_TEXT="$(sed -ne '/iface[ \t]\+ens160[ \t]\+inet[ \t]\+/ s/^.*\(static\|dhcp\).*$/\1/p' "${_FILE_PATH}")"
		fi
		case "${_WORK_TEXT:-}" in
			static) IPV4_DHCP="false";;
			dhcp  ) IPV4_DHCP="true" ;;
			*     )
				if ip -4 -oneline address show dev "${NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
					IPV4_DHCP="true"
				else
					IPV4_DHCP="false"
				fi
				;;
		esac
	fi
	NICS_MADR="${NICS_MADR:-"$(ip -4 -oneline link show dev "${NICS_NAME}" 2> /dev/null | sed -ne 's%^.*[ \t]link/ether[ \t]\+\([[:alnum:]:]\+\)[ \t].*$%\1%p')"}"
	NICS_IPV4="${NICS_IPV4:-"$(ip -4 -oneline address show dev "${NICS_NAME}"  2> /dev/null | sed -ne 's%^.*[ \t]inet[ \t]\+\([0-9/.]\+\)\+[ \t].*$%\1%p')"}"
	NICS_BIT4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 2)"
	NICS_IPV4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 1)"
	if [ -z "${NICS_BIT4}" ]; then
		NICS_BIT4="$(funcIPv4GetNetmask "${NICS_MASK:-"255.255.255.0"}")"
	else
		NICS_MASK="$(funcIPv4GetNetmask "${NICS_BIT4:-"24"}")"
	fi
#	if [ "${IPV4_DHCP}" = "true" ]; then
#		NICS_IPV4=""
#	fi
	NICS_IPV4="${NICS_IPV4:-"${IPV4_DUMY}"}"
	NICS_DNS4="${NICS_DNS4:-"$(sed -ne 's/^nameserver[ \]\+\([[:alnum:]:.]\+\)[ \t]*$/\1/p' /etc/resolv.conf | sed -e ':l; N; s/\n/,/; b l;')"}"
	NICS_GATE="${NICS_GATE:-"$(ip -4 -oneline route list match default | cut -d ' ' -f 3)"}"
	NICS_FQDN="${NICS_FQDN:-"$(cat "${DIRS_TGET:-}/etc/hostname")"}"
	NICS_HOST="${NICS_HOST:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 1)"}"
	NICS_WGRP="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 2)"}"
	NICS_WGRP="${NICS_WGRP:-"$(awk '$1=="search" {print $2;}' "${DIRS_TGET:-}/etc/resolv.conf")"}"
	NICS_HOST="$(echo "${NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
	NICS_WGRP="$(echo "${NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
	if [ "${NICS_FQDN}" = "${NICS_HOST}" ] && [ -n "${NICS_WGRP}" ]; then
		NICS_FQDN="${NICS_HOST}.${NICS_WGRP}"
	fi

	IPV4_UADR="${NICS_IPV4%.*}"
	IPV4_LADR="${NICS_IPV4##*.}"
	IPV6_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/! s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
	IPV6_CIDR="${IPV6_ADDR#*/}"
	IPV6_ADDR="${IPV6_ADDR%%/*}"
	IPV6_FADR="$(funcIPv6GetFullAddr "${IPV6_ADDR}")"
	IPV6_UADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	IPV6_LADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	IPV6_RADR=""
	LINK_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/ s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
	LINK_CIDR="${LINK_ADDR#*/}"
	LINK_ADDR="${LINK_ADDR%%/*}"
	LINK_FADR="$(funcIPv6GetFullAddr "${LINK_ADDR}")"
	LINK_UADR="$(echo "${LINK_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	LINK_LADR="$(echo "${LINK_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	LINK_RADR=""

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- file backup -------------------------------------------------------------
funcFile_backup() {
	if [ -n "${DBGS_FLAG:-}" ]; then
		____FUNC_NAME="funcFile_backup"
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${____FUNC_NAME}] ---"
	fi

	# --- check ---------------------------------------------------------------
	if [ ! -e "${1:?}" ]; then
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "** not exist: [$1] **"
		mkdir -p "${1%/*}"
		_REAL_PATH="$(realpath "${1}")"
		if [ ! -e "${_REAL_PATH}" ]; then
			mkdir -p "${_REAL_PATH%/*}"
		fi
		touch "$1"
#		return
	fi
	# --- backup --------------------------------------------------------------
	___FILE_PATH="${1}"
	___BACK_PATH="${1#*"${DIRS_TGET:-}"}"
	case "${2:-}" in
		init) ___BACK_PATH="${DIRS_INIT}/${___BACK_PATH#/}";;
		*   ) ___BACK_PATH="${DIRS_ORIG}/${___BACK_PATH#/}";;
	esac
	mkdir -p "${___BACK_PATH%/*}"
	if [ -e "${___BACK_PATH}" ]; then
		___BACK_PATH="${___BACK_PATH}.$(date +"%Y%m%d%H%M%S")"
	fi
	if [ -n "${DBGS_FLAG:-}" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "backup: ${___FILE_PATH} -> ${___BACK_PATH}"
	fi
#	if [ -f "$1" ]; then
		cp -a "$1" "${___BACK_PATH}"
#	else
#		mv "$1" "${___BACK_PATH}"
#	fi

	# --- complete ------------------------------------------------------------
	if [ -n "${DBGS_FLAG:-}" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${____FUNC_NAME}] ---"
	fi
}

# --- installing missing packages ---------------------------------------------
# only runs on debian and ubuntu on amd64
funcInstall_package() {
	__FUNC_NAME="funcInstall_package"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v dpkg > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- sources.list --------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/apt/sources.list"
	if grep -q '^[ \t]*deb[ \t]\+cdrom:' "${_FILE_PATH}"; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		sed -i "${_FILE_PATH}"                     \
		    -e '/^[ \t]*deb[ \t]\+cdrom:/ s/^/#/g'

		# --- debug out -----------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- get architecture ----------------------------------------------------
	_MAIN_ARHC="$(dpkg --print-architecture)"
	_OTHR_ARCH="$(dpkg --print-foreign-architectures)"

	# --- preseed or cloud-init -----------------------------------------------
	_PAKG_LIST=""
	if [ -n "${SEED_FILE:-}" ]; then
		case "${SEED_FILE##*/}" in
			auto*.xml)		;;	# autoyast
			ks*.cfg) 		;;	# kickstart
			user-data)			# nocloud
				_FILE_PATH="${PROG_DIRS}/user-data"
				if [ -e "${_FILE_PATH}" ]; then
					_PAKG_LIST="$( \
						sed -ne '/^[ \t]*packages:$/,/^[ #]*[[:graph:]]\+:$/ {s/^[ \t]*-[ \t]\+//gp}' "${_FILE_PATH}" | \
						sed -e  ':l; N; s/[\r\n]/ /; b l;'                                                            | \
						sed -e  's/[ \t]\+/ /g')"
				fi
				;;
			ps*.cfg)			# preseed
				_FILE_PATH="${PROG_DIRS}/${SEED_FILE##*/}"
				if [ -e "${_FILE_PATH}" ]; then
					_PAKG_LIST="$( \
						sed -ne '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+.*$%,\%[^\\]$% {s/\\//gp}' "${_FILE_PATH}" | \
						sed -e  ':l; N; s/[\r\n]/ /; b l;'                                                          | \
						sed -e  's/[ \t]\+/ /g'                                                                     | \
						sed -e  's%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+[[:graph:]]\+[ \t]*%%')"
				fi
				;;
			*)	;;
		esac;
	fi

	# --- get missing packages ------------------------------------------------
	# shellcheck disable=SC2086
	_PAKG_FIND="$(LANG=C apt list ${_PAKG_LIST:-"apt"} 2> /dev/null                | \
		sed -ne '/[ \t]'"${_OTHR_ARCH:-"i386"}"'[ \t]*/!{'                           \
		    -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | \
		sed -z 's/[\r\n]\+/ /g')"

	# --- install missing packages --------------------------------------------
	apt-get -qq update
	if [ -n "${_PAKG_FIND:-}" ]; then
		# shellcheck disable=SC2086
		if ! apt-get -qq -y install ${_PAKG_FIND}; then
			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "missing packages installation failure"
			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "${_PAKG_FIND}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- creating a shared environment -------------------------------------------
funcCreate_shared_env() {
	__FUNC_NAME="funcCreate_shared_env"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- create system user id -----------------------------------------------
	if id "${SAMB_USER}" > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "user exist: [${SAMB_USER}]"
	else
		printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "user create: [${SAMB_USER}]"
		if ! grep -qE '^'"${SAMB_GADM}"':' /etc/group; then
			groupadd --system "${SAMB_GADM}"
		fi
		if ! grep -qE '^'"${SAMB_GRUP}"':' /etc/group; then
			groupadd --system "${SAMB_GRUP}"
		fi
		useradd --system --shell "${LGIN_SHEL}" --groups "${SAMB_GRUP}" "${SAMB_USER}"
	fi

	# --- create shared directory ---------------------------------------------
	mkdir -p "${DIRS_HGFS}"

	mkdir -p "${DIRS_HTML}"/html
	touch -f "${DIRS_HTML}"/html/index.html

	mkdir -p "${DIRS_TFTP}"/boot/grub
	mkdir -p "${DIRS_TFTP}"/ipxe
	mkdir -p "${DIRS_TFTP}"/menu-bios/pxelinux.cfg
	mkdir -p "${DIRS_TFTP}"/menu-efi64/pxelinux.cfg
	touch -f "${DIRS_TFTP}"/menu-bios/syslinux.cfg
	touch -f "${DIRS_TFTP}"/menu-efi64/syslinux.cfg
	ln -sf ../conf         "${DIRS_TFTP}"/menu-bios/
	ln -sf ../imgs         "${DIRS_TFTP}"/menu-bios/
	ln -sf ../isos         "${DIRS_TFTP}"/menu-bios/
	ln -sf ../load         "${DIRS_TFTP}"/menu-bios/
	ln -sf ../rmak         "${DIRS_TFTP}"/menu-bios/
	ln -sf ../syslinux.cfg "${DIRS_TFTP}"/menu-bios/pxelinux.cfg/default
	ln -sf ../conf         "${DIRS_TFTP}"/menu-efi64/
	ln -sf ../imgs         "${DIRS_TFTP}"/menu-efi64/
	ln -sf ../isos         "${DIRS_TFTP}"/menu-efi64/
	ln -sf ../load         "${DIRS_TFTP}"/menu-efi64/
	ln -sf ../rmak         "${DIRS_TFTP}"/menu-efi64/
	ln -sf ../syslinux.cfg "${DIRS_TFTP}"/menu-efi64/pxelinux.cfg/default

	mkdir -p "${DIRS_SAMB}"/cifs
	mkdir -p "${DIRS_SAMB}"/data/adm/netlogon
	mkdir -p "${DIRS_SAMB}"/data/adm/profiles
	mkdir -p "${DIRS_SAMB}"/data/arc
	mkdir -p "${DIRS_SAMB}"/data/bak
	mkdir -p "${DIRS_SAMB}"/data/pub
	mkdir -p "${DIRS_SAMB}"/data/usr
	mkdir -p "${DIRS_SAMB}"/dlna/movies
	mkdir -p "${DIRS_SAMB}"/dlna/others
	mkdir -p "${DIRS_SAMB}"/dlna/photos
	mkdir -p "${DIRS_SAMB}"/dlna/sounds

	mkdir -p "${DIRS_USER}"/private
	mkdir -p "${DIRS_USER}"/share/conf
	mkdir -p "${DIRS_USER}"/share/imgs
	mkdir -p "${DIRS_USER}"/share/isos
	mkdir -p "${DIRS_USER}"/share/load
	mkdir -p "${DIRS_USER}"/share/rmak

	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_HTML}"/html/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_HTML}"/html/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_HTML}"/html/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_HTML}"/html/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_HTML}"/html/

	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_TFTP}"/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_TFTP}"/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_TFTP}"/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_TFTP}"/
	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_TFTP}"/

	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_TFTP}/autoexec.ipxe"
		#!ipxe
		
		cpuid --ext 29 && set arch amd64 || set arch x86
		
		dhcp
		
		set optn-timeout 3000
		set menu-timeout 0
		isset \${menu-default} || set menu-default exit
		
		:start
		
		:menu
		menu Select the OS type you want to boot
		item --gap --                           --------------------------------------------------------------------------
		item --gap --                           [ System command ]
		item -- shell                           - iPXE shell
		#item -- shutdown                       - System shutdown
		item -- restart                         - System reboot
		item --gap --                           --------------------------------------------------------------------------
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

#	if command -v setsebool > /dev/null 2>&1; then
#		setsebool -P httpd_use_fusefs 1
#		setsebool -P samba_enable_home_dirs 1
#		setsebool -P samba_export_all_ro 1
#		setsebool -P samba_export_all_rw 1
#	fi

	touch -f "${DIRS_SAMB}"/data/adm/netlogon/logon.bat
	chown -R "${SAMB_USER}":"${SAMB_GRUP}" "${DIRS_SAMB}/"*
	chmod -R  770 "${DIRS_SAMB}/"*
	chmod    1777 "${DIRS_SAMB}/data/adm/profiles"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_HTML}/html/index.html"
		"Hello, world!" from ${NICS_HOST}
_EOT_

	# --- symlink for html ----------------------------------------------------
#	_WORK_PATH="${DIRS_TGET:-}/var/www/html"
#	funcFile_backup "${_WORK_PATH}"
#	ln -sf "${DIRS_HTML#${DIRS_TGET:-}}" "${_WORK_PATH}"

	# --- symlink for tftp ----------------------------------------------------
#	_WORK_PATH="${DIRS_TGET:-}/var/lib/tftpboot"
#	funcFile_backup "${_WORK_PATH}"
#	ln -sf "${DIRS_TFTP#${DIRS_TGET:-}}" "${_WORK_PATH}"

	# --- debug out -----------------------------------------------------------
	funcFile_backup "${DIRS_SRVR:?}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- apparmor settings -------------------------------------------------------
funcSetupConfig_apparmor() {
	__FUNC_NAME="funcSetupConfig_apparmor"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v aa-enabled > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="apparmor.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- debug out -----------------------------------------------------------
#	aa-enabled
	aa-status || true

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- selinux settings --------------------------------------------------------
funcSetupConfig_selinux() {
	__FUNC_NAME="funcSetupConfig_selinux"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v semanage > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- httpd ---------------------------------------------------------------
	semanage fcontext -a -t httpd_sys_content_t "${DIRS_HTML}(/.*)?"
	restorecon -R -v "${DIRS_HTML}"

	# --- tftp ----------------------------------------------------------------
	semanage fcontext -a -t tftpdir_t "${DIRS_TFTP}(/.*)?"
	restorecon -R -v "${DIRS_TFTP}"

	# --- samba ---------------------------------------------------------------
	semanage fcontext -a -t samba_share_t "${DIRS_SAMB}(/.*)?"
	restorecon -R -v "${DIRS_SAMB}"

	# --- setsebool -----------------------------------------------------------
	if command -v setsebool > /dev/null 2>&1; then
		setsebool -P httpd_use_fusefs 1
#		setsebool -P samba_enable_home_dirs 1
		setsebool -P samba_export_all_ro 1
#		setsebool -P samba_export_all_rw 1
	fi

	# --- debug out -----------------------------------------------------------
	getenforce

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup connman ---------------------------------------------------
funcSetupNetwork_connman() {
	__FUNC_NAME="funcSetupNetwork_connman"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v connmanctl > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- main.conf -----------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/connman/main.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		
		# Generated by user script
		AllowHostnameUpdates = false
		AllowDomainnameUpdates = false
		PreferredTechnologies = ethernet,wifi
		SingleConnectedTechnology = true
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- disable_dns_proxy.conf ----------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	_WORK_TEXT="$(command -v connmand 2> /dev/null)"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[Service]
		ExecStart=
		ExecStart=${_WORK_TEXT} -n --nodnsproxy
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- settings ------------------------------------------------------------
#	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/settings"
#	funcFile_backup "${_FILE_PATH}"
#	mkdir -p "${_FILE_PATH%/*}"
#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#		[global]
#		OfflineMode=false
#		
#		[Wired]
#		Enable=true
#		Tethering=false
#_EOT_

	# --- debug out -----------------------------------------------------------
#	funcDebugout_file "${_FILE_PATH}"
#	funcFile_backup   "${_FILE_PATH}" "init"

	# --- configures ----------------------------------------------------------
	_WORK_TEXT="$(echo "${NICS_MADR}" | sed -e 's/://g')"
	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/ethernet_${_WORK_TEXT}_cable/settings"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[ethernet_${_WORK_TEXT}_cable]
		Name=Wired
		AutoConnect=true
		Modified=
_EOT_
	if [ "${IPV4_DHCP}" = "true" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			IPv4.method=dhcp
			IPv4.DHCP.LastAddress=
			IPv6.method=auto
			IPv6.privacy=prefered
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			IPv4.method=manual
			IPv4.netmask_prefixlen=${NICS_BIT4}
			IPv4.local_address=${NICS_IPV4}
			IPv4.gateway=${NICS_GATE}
			IPv6.method=auto
			IPv6.privacy=prefered
			Nameservers=${IPV6_LHST};${IPV4_LHST};${NICS_DNS4};
			Timeservers=${NTPS_ADDR};
			Domains=${NICS_WGRP};
			IPv6.DHCP.DUID=
_EOT_
	fi
	chmod 600 "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="connman.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup netplan ---------------------------------------------------
funcSetupNetwork_netplan() {
	__FUNC_NAME="funcSetupNetwork_netplan"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v netplan > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- configures ----------------------------------------------------------
	if command -v nmcli > /dev/null 2>&1; then
		# --- 99-network-config-all.yaml --------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/netplan/99-network-manager-all.yaml"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			network:
			  version: 2
			  renderer: NetworkManager
_EOT_
		chmod 600 "${_FILE_PATH}"

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"

		# --- 99-disable-network-config.cfg -----------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
		if [ -d "${_FILE_PATH%/*}/." ]; then
			funcFile_backup "${_FILE_PATH}"
			mkdir -p "${_FILE_PATH%/*}"
			cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				network: {config: disabled}
_EOT_
			# --- debug out ---------------------------------------------------
			funcDebugout_file "${_FILE_PATH}"
			funcFile_backup   "${_FILE_PATH}" "init"
		fi
	else
		_FILE_PATH="${DIRS_TGET:-}/etc/netplan/99-network-config-${NICS_NAME}.yaml"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			network:
			  version: 2
			  renderer: networkd
			  ethernets:
			    ${NICS_NAME}:
_EOT_
		if [ "${IPV4_DHCP}" = "true" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
				      dhcp4: true
				      dhcp6: true
				      ipv6-privacy: true
_EOT_
		else
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
				      addresses:
				      - ${NICS_IPV4}/${NICS_BIT4}
				      routes:
				      - to: default
				        via: ${NICS_GATE}
				      nameservers:
				        search:
				        - ${NICS_WGRP}
				        addresses:
				        - ${NICS_DNS4}
				      dhcp4: false
				      dhcp6: true
				      ipv6-privacy: true
_EOT_
		fi
		chmod 600 "${_FILE_PATH}"

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- netplan -------------------------------------------------------------
	netplan apply

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup network manager -------------------------------------------
funcSetupNetwork_nmanagr() {
	__FUNC_NAME="funcSetupNetwork_nmanagr"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v nmcli > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- configures ----------------------------------------------------------
	case "${DIST_NAME:-}" in
		debian | ubuntu ) _FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/Wired connection 1";;
		*               ) _FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/${NICS_NAME}.nmconnection";;
	esac
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	if [ "${IPV4_DHCP}" = "true" ]; then
		if ! nmcli --offline connection add type ethernet \
			connection.id "${_FILE_PATH##*/}" \
			connection.interface-name "${NICS_NAME}" \
			connection.autoconnect true \
			connection.zone "${FWAL_ZONE}" \
			ethernet.wake-on-lan 0 \
			ethernet.mac-address "${NICS_MADR}" \
			ipv4.method auto \
			ipv6.method auto \
			ipv6.addr-gen-mode default \
		> "${_FILE_PATH}"; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				[connection]
				id=${_FILE_PATH##*/}
				type=ethernet
				interface-name=${NICS_NAME}
				autoconnect=true
				zone=${FWAL_ZONE}
				
				[ethernet]
				wake-on-lan=0
				mac-address=${NICS_MADR}
				
				[ipv4]
				method=auto
				
				[ipv6]
				method=auto
				addr-gen-mode=default
				
				[proxy]
_EOT_
		fi
	else
		if ! nmcli --offline connection add type ethernet \
			connection.id "${_FILE_PATH##*/}" \
			connection.interface-name "${NICS_NAME}" \
			connection.autoconnect true \
			connection.zone "${FWAL_ZONE}" \
			ethernet.wake-on-lan 0 \
			ethernet.mac-address "${NICS_MADR}" \
			ipv4.method manual \
			ipv4.address "${NICS_IPV4}/${NICS_BIT4}" \
			ipv4.gateway "${NICS_GATE}" \
			ipv4.dns "${NICS_DNS4}" \
			ipv6.method auto \
			ipv6.addr-gen-mode default \
		> "${_FILE_PATH}"; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				[connection]
				id=${_FILE_PATH##*/}
				type=ethernet
				interface-name=${NICS_NAME}
				autoconnect=true
				zone=${FWAL_ZONE}
				
				[ethernet]
				wake-on-lan=0
				mac-address=${NICS_MADR}
				
				[ipv4]
				method=manual
				address1=${NICS_IPV4}/${NICS_BIT4},${NICS_GATE}
				dns=${NICS_DNS4};
				
				[ipv6]
				method=auto
				addr-gen-mode=default
				
				[proxy]
_EOT_
		fi
	fi
	chown root:root "${_FILE_PATH}"
	chmod 600 "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- dns.conf ------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	if command -v resolvectl > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[main]
			dns=systemd-resolved
_EOT_
	elif command -v dnsmasq > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[main]
			dns=dnsmasq
_EOT_
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="NetworkManager.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
		nmcli connection reload
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup hostname --------------------------------------------------
funcSetupNetwork_hostname() {
	__FUNC_NAME="funcSetupNetwork_hostname"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- hostname ------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/hostname"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	echo "${NICS_FQDN:-}" > "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup hosts -----------------------------------------------------
funcSetupNetwork_hosts() {
	__FUNC_NAME="funcSetupNetwork_hosts"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- hosts ---------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/hosts"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	TEXT_GAPS="$(funcString "$((16-${#NICS_IPV4}))" " ")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		${IPV4_LHST:-"127.0.0.1"}       localhost
		${NICS_IPV4}${TEXT_GAPS}${NICS_FQDN} ${NICS_HOST}
		
		# The following lines are desirable for IPv6 capable hosts
		${IPV6_LHST:-"::1"}             localhost ip6-localhost ip6-loopback
		fe00::0         ip6-localnet
		ff00::0         ip6-mcastprefix
		ff02::1         ip6-allnodes
		ff02::2         ip6-allrouters
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup hosts.allow/hosts.deny ------------------------------------
#funcSetupNetwork_hosts_access() {
#	__FUNC_NAME="funcSetupNetwork_hosts_access"
#	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
#
#	# --- hosts ---------------------------------------------------------------
#	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.allow"
#	funcFile_backup "${_FILE_PATH}"
#	mkdir -p "${_FILE_PATH%/*}"
#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#		ALL : ${IPV4_LHST}
#		ALL : [${IPV6_LHST}]
#		ALL : ${IPV4_UADR}.0/${NICS_BIT4}
#		ALL : [${LINK_UADR%%::}::%${NICS_NAME}]/10
#		#ALL : [${IPV6_UADR%%::}::]/${IPV6_CIDR}
#_EOT_
#
#	# --- debug out -----------------------------------------------------------
#	funcDebugout_file "${_FILE_PATH}"
#	funcFile_backup   "${_FILE_PATH}" "init"
#
#	# --- hosts ---------------------------------------------------------------
#	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.deny"
#	funcFile_backup "${_FILE_PATH}"
#	mkdir -p "${_FILE_PATH%/*}"
#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#		ALL : ALL
#_EOT_
#
#	# --- debug out -----------------------------------------------------------
#	funcDebugout_file "${_FILE_PATH}"
#	funcFile_backup   "${_FILE_PATH}" "init"
#
#	# --- complete ------------------------------------------------------------
#	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
#}

# --- network setup firewalld -------------------------------------------------
funcSetupNetwork_firewalld() {
	__FUNC_NAME="funcSetupNetwork_firewalld"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v firewall-cmd > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- firewalld.service ---------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/lib/systemd/system/firewalld.service"
	if [ ! -e "${_FILE_PATH}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/usr/lib/systemd/system/firewalld.service"
	fi
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	sed -i "${_FILE_PATH}" \
	    -e '/\[Unit\]/,/\[.*\]/                {' \
	    -e '/^Before=network-pre.target$/ s/^/#/' \
	    -e '/^Wants=network-pre.target$/  s/^/#/' \
	    -e '                                   }'

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- firewalld -----------------------------------------------------------
	# memo: log output settings : firewall-cmd --set-log-denied=all
	#       service name output ; firewall-cmd --get-services
	#       setting value output: firewall-cmd --list-all --zone=home_use
	_FILE_PATH="${DIRS_TGET:-}/etc/firewalld/zones/${FWAL_ZONE}.xml"
	_WORK_PATH="${DIRS_TGET:-}/lib/firewalld/zones/drop.xml"
	if [ ! -e "${_WORK_PATH}" ]; then
		_WORK_PATH="${DIRS_TGET:-}/usr/lib/firewalld/zones/drop.xml"
	fi
	cp -a "${_WORK_PATH}" "${_FILE_PATH}"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	_IPV4_ADDR="${IPV4_UADR}.0/${NICS_BIT4}"
	_IPV6_ADDR="${IPV6_UADR%%::}::/${IPV6_CIDR}"
	_LINK_ADDR="${LINK_UADR%%::}::/10"
	_SRVC_NAME="firewalld.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service active: ${_SRVC_NAME}"
		firewall-cmd --quiet --set-default-zone="${FWAL_ZONE}" || true
		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --change-interface="${NICS_NAME}" || true
		for _FWAL_NAME in ${FWAL_NAME}
		do
			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		done
		for _FWAL_PORT in ${FWAL_PORT}
		do
			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		done
		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" protocol value="icmp"      accept'
#		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		firewall-cmd --quiet --reload
		firewall-cmd --get-zone-of-interface="${NICS_NAME}"
		firewall-cmd --list-all --zone="${FWAL_ZONE}"
	else
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service inactive: ${_SRVC_NAME}"
		firewall-offline-cmd --quiet --set-default-zone="${FWAL_ZONE}" || true
		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --change-interface="${NICS_NAME}" || true
		for _FWAL_NAME in ${FWAL_NAME}
		do
			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		done
		for _FWAL_PORT in ${FWAL_PORT}
		do
			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		done
		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" protocol value="icmp"      accept'
#		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
#		firewall-offline-cmd --quiet --reload
		firewall-offline-cmd --get-zone-of-interface="${NICS_NAME}"
		firewall-offline-cmd --list-all --zone="${FWAL_ZONE}"
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup dnsmasq ---------------------------------------------------
funcSetupNetwork_dnsmasq() {
	__FUNC_NAME="funcSetupNetwork_dnsmasq"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v dnsmasq > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- dnsmasq.service -----------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/lib/systemd/system/dnsmasq.service"
	if [ ! -e "${_FILE_PATH}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/usr/lib/systemd/system/dnsmasq.service"
	fi
	if [ -e "${_FILE_PATH}" ]; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		sed -i "${_FILE_PATH}"                    \
		    -e '/\[Unit\]/,/\[.\+\]/           {' \
		    -e '/^Requires=/                   {' \
		    -e 's/^/#/g'                          \
		    -e 'a Requires=network-online.target' \
		    -e '                               }' \
		    -e '/^After=/                      {' \
		    -e 's/^/#/g'                          \
		    -e 'a After=network-online.target'    \
		    -e '                               }' \
		    -e '}'

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- dnsmasq -------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/default/dnsmasq"
	if [ -e "${_FILE_PATH}" ]; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		sed -i "${_FILE_PATH}"                         \
		    -e 's/^#\(IGNORE_RESOLVCONF\)=.*$/\1=yes/' \
		    -e 's/^#\(DNSMASQ_EXCEPT\)=.*$/\1="lo"/'

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- default.conf --------------------------------------------------------
	_CONF_FILE="$(find "${DIRS_TGET:-}/etc/dnsmasq.d" "${DIRS_TGET:-}/usr/share" -name 'trust-anchors.conf' -type f)"
	_CONF_FILE="${_CONF_FILE#"${DIRS_TGET:-}"}"
	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		# --- log ---------------------------------------------------------------------
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name
		
		# --- dns ---------------------------------------------------------------------
		#port=0                                                     # listening port
		#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
		#domain-needed                                              # do not forward plain names
		#domain=${NICS_WGRP}                                           # local domain name
		#expand-hosts                                               # add domain name to host
		#filterwin2k                                                # filter for windows
		interface=${NICS_NAME}                                            # listen to interface
		#listen-address=${IPV4_LHST}                                   # listen to ip address
		#listen-address=${IPV6_LHST}                                         # listen to ip address
		#listen-address=${NICS_IPV4}                                 # listen to ip address
		#listen-address=${LINK_ADDR}                    # listen to ip address
		#server=${NICS_DNS4}                                       # directly specify upstream server
		#server=8.8.8.8                                             # directly specify upstream server
		#server=8.8.4.4                                             # directly specify upstream server
		#no-hosts                                                   # don't read the hostnames in /etc/hosts
		#no-poll                                                    # don't poll /etc/resolv.conf for changes
		#no-resolv                                                  # don't read /etc/resolv.conf
		#strict-order                                               # try in the registration order of /etc/resolv.conf
		#bind-dynamic                                               # enable bind-interfaces and the default hybrid network mode
		bind-interfaces                                             # enable multiple instances of dnsmasq
		#conf-file=${_CONF_FILE}       # enable dnssec validation and caching
		#dnssec                                                     # "
		
		# --- dhcp --------------------------------------------------------------------
		dhcp-range=${NICS_IPV4%.*}.0,proxy,24                             # proxy dhcp
		#dhcp-range=${NICS_IPV4%.*}.64,${NICS_IPV4%.*}.79,12h                   # dhcp range
		#dhcp-option=option:netmask,255.255.255.0                   #  1 netmask
		#dhcp-option=option:router,${NICS_GATE}                    #  3 router
		#dhcp-option=option:dns-server,${NICS_IPV4},${NICS_GATE}    #  6 dns-server
		#dhcp-option=option:domain-name,${NICS_WGRP}                   # 15 domain-name
		#dhcp-option=option:28,${NICS_IPV4%.*}.255                        # 28 broadcast
		#dhcp-option=option:ntp-server,${NTPS_IPV4}               # 42 ntp-server
		#dhcp-option=option:tftp-server,${NICS_IPV4}                 # 66 tftp-server
		#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
		dhcp-no-override                                            # disable re-use of the dhcp servername and filename fields as extra option space
		
		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		
		# --- eof ---------------------------------------------------------------------
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- pxeboot.conf --------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name
		
		# --- tftp --------------------------------------------------------------------
		#enable-tftp=${NICS_NAME}                                         # enable tftp server
		#tftp-root=${DIRS_TFTP}                                        # tftp root directory
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

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="dnsmasq.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup resolv.conf -----------------------------------------------
funcSetupNetwork_resolv() {
	__FUNC_NAME="funcSetupNetwork_resolv"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v resolvectl > /dev/null 2>&1; then
		# --- resolv.conf -----------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			# Generated by user script
			search ${NICS_WGRP}
			nameserver ${IPV6_LHST}
			nameserver ${IPV4_LHST}
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	else
		# --- resolv.conf -> /run/systemd/resolve/stub-resolv.conf ------------
		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		funcFile_backup "${_FILE_PATH}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		rm -f "${_FILE_PATH}"
		_WORK_PATH="${DIRS_TGET:-}/run/systemd/resolve/stub-resolv.conf"
		ln -sfr "${_WORK_PATH}" "${_FILE_PATH}"
		if [ ! -e "${_WORK_PATH}" ]; then
			mkdir -p "${_WORK_PATH%/*}"
			touch "${_WORK_PATH}"
		fi

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
		funcFile_backup   "${_WORK_PATH}" "init"

		# --- default.conf ----------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf.d/default.conf"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[Resolve]
			DNS=${NICS_DNS4}
			Domains=${NICS_WGRP}
_EOT_
#		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf"
#		if ! grep -qE '^DNS=' "${_FILE_PATH}"; then
#			sed -i "${_FILE_PATH}"                       \
#			    -e '/^\[Resolve\]$/a DNS='"${IPV4_LHST}"
#		fi

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"

		# --- systemctl avahi-daemon.service ----------------------------------
		_SRVC_NAME="avahi-daemon.service"
		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		if [ "${_SRVC_STAT}" = "enabled" ]; then
			systemctl --quiet mask "${_SRVC_NAME}"
			systemctl --quiet mask "${_SRVC_NAME%.*}.socket"
		fi

		# --- systemctl systemd-resolved.service ------------------------------
		_SRVC_NAME="systemd-resolved.service"
		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		case "${_SRVC_STAT}" in
			disabled) systemctl --quiet enable "${_SRVC_NAME}";;
#			masked  ) systemctl --quiet unmask "${_SRVC_NAME}"; systemctl --quiet enable "${_SRVC_NAME}";;
			*) ;;
		esac
		_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		if [ "${_SRVC_STAT}" = "active" ]; then
			printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
			systemctl --quiet daemon-reload
			systemctl --quiet restart "${_SRVC_NAME}"
		fi
		if [ -n "${DBGS_FLAG:-}" ]; then
			resolvectl status || true
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup apache ----------------------------------------------------
funcSetupNetwork_apache() {
	__FUNC_NAME="funcSetupNetwork_apache"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	if   [ -e "${DIRS_TGET:-}/lib/systemd/system/apache2.service"     ] \
	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/apache2.service" ]; then
		_SRVC_NAME="apache2.service"
	elif [ -e "${DIRS_TGET:-}/lib/systemd/system/httpd.service"       ] \
	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/httpd.service"   ]; then
		_SRVC_NAME="httpd.service"
	else
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- apache2.conf / httpd.conf -------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/sites-available/999-site.conf"
	if [ -d "${_FILE_PATH%/*}" ]; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		sed -e 's%^\([ \t]\+DocumentRoot[ \t]\+\).*$%\1'"${DIRS_HTML}"/html'%'      \
		    "${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/sites-available/000-default.conf" \
		> "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			<Directory ${DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"

		# --- registration ----------------------------------------------------
		a2dissite 000-default
		a2ensite "${_FILE_PATH##*/}"
	else
		_FILE_PATH="${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/conf.d/site.conf"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			<VirtualHost *:80>
			 	ServerAdmin webmaster@localhost
			 	DocumentRoot ${DIRS_HTML}/html
			#	ErrorLog \${APACHE_LOG_DIR}/error.log
			#	CustomLog \${APACHE_LOG_DIR}/access.log combined
			</VirtualHost>
			
			<Directory ${DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- systemctl -----------------------------------------------------------
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup samba -----------------------------------------------------
funcSetupNetwork_samba() {
	__FUNC_NAME="funcSetupNetwork_samba"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	if   { [ -e "${DIRS_TGET:-}/lib/systemd/system/smbd.service"     ]    \
	&&     [ -e "${DIRS_TGET:-}/lib/systemd/system/nmbd.service"     ]; } \
	||   { [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/smbd.service" ]    \
	&&     [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/nmbd.service" ]; }; then
		_SRVC_SMBD="smbd.service"
		_SRVC_NMBD="nmbd.service"
	elif { [ -e "${DIRS_TGET:-}/lib/systemd/system/smb.service"     ]    \
	&&     [ -e "${DIRS_TGET:-}/lib/systemd/system/nmb.service"     ]; } \
	||   { [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/smb.service" ]    \
	&&     [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/nmb.service" ]; }; then
		_SRVC_SMBD="smb.service"
		_SRVC_NMBD="nmb.service"
	else
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_SMBD}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NMBD}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- check command -------------------------------------------------------
	if ! command -v pdbedit > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- create passdb.tdb ---------------------------------------------------
	pdbedit -L > /dev/null
#	_SAMB_PWDB="$(find /var/lib/samba/ -name 'passdb.tdb' \( -type f -o -type l \))"

	# --- nsswitch.conf -------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/nsswitch.conf"
	if [ -e "${_FILE_PATH}" ]; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		_WORK_TEXT="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
		sed -i "${_FILE_PATH}"            \
		    -e '/^hosts:[ \t]\+/       {' \
		    -e 's/\(files\).*$/\1/'       \
		    -e 's/$/ '"${_WORK_TEXT}"'/}'

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- smb.conf ------------------------------------------------------------
	# https://www.samba.gr.jp/project/translation/current/htmldocs/manpages/smb.conf.5.html
	_WORK_PATH="${DIRS_TGET:-}/tmp/smb.conf.work"
	_FILE_PATH="${DIRS_TGET:-}/etc/samba/smb.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"

	# --- global settings section ---------------------------------------------
	testparm -s -v                                                                  | \
	sed -ne '/^\[global\]$/,/^[ \t]*$/                                             {' \
	    -e  '/^[ \t]*acl check permissions[ \t]*=/        s/^/#/'                     \
	    -e  '/^[ \t]*allocation roundup size[ \t]*=/      s/^/#/'                     \
	    -e  '/^[ \t]*allow nt4 crypto[ \t]*=/             s/^/#/'                     \
	    -e  '/^[ \t]*blocking locks[ \t]*=/               s/^/#/'                     \
	    -e  '/^[ \t]*client NTLMv2 auth[ \t]*=/           s/^/#/'                     \
	    -e  '/^[ \t]*client lanman auth[ \t]*=/           s/^/#/'                     \
	    -e  '/^[ \t]*client plaintext auth[ \t]*=/        s/^/#/'                     \
	    -e  '/^[ \t]*client schannel[ \t]*=/              s/^/#/'                     \
	    -e  '/^[ \t]*client use spnego principal[ \t]*=/  s/^/#/'                     \
	    -e  '/^[ \t]*client use spnego[ \t]*=/            s/^/#/'                     \
	    -e  '/^[ \t]*copy[ \t]*=/                         s/^/#/'                     \
	    -e  '/^[ \t]*domain logons[ \t]*=/                s/^/#/'                     \
	    -e  '/^[ \t]*enable privileges[ \t]*=/            s/^/#/'                     \
	    -e  '/^[ \t]*encrypt passwords[ \t]*=/            s/^/#/'                     \
	    -e  '/^[ \t]*idmap backend[ \t]*=/                s/^/#/'                     \
	    -e  '/^[ \t]*idmap gid[ \t]*=/                    s/^/#/'                     \
	    -e  '/^[ \t]*idmap uid[ \t]*=/                    s/^/#/'                     \
	    -e  '/^[ \t]*lanman auth[ \t]*=/                  s/^/#/'                     \
	    -e  '/^[ \t]*lsa over netlogon[ \t]*=/            s/^/#/'                     \
	    -e  '/^[ \t]*nbt client socket address[ \t]*=/    s/^/#/'                     \
	    -e  '/^[ \t]*null passwords[ \t]*=/               s/^/#/'                     \
	    -e  '/^[ \t]*raw NTLMv2 auth[ \t]*=/              s/^/#/'                     \
	    -e  '/^[ \t]*reject md5 clients[ \t]*=/           s/^/#/'                     \
	    -e  '/^[ \t]*server schannel require seal[ \t]*=/ s/^/#/'                     \
	    -e  '/^[ \t]*server schannel[ \t]*=/              s/^/#/'                     \
	    -e  '/^[ \t]*syslog only[ \t]*=/                  s/^/#/'                     \
	    -e  '/^[ \t]*syslog[ \t]*=/                       s/^/#/'                     \
	    -e  '/^[ \t]*unicode[ \t]*=/                      s/^/#/'                     \
	    -e  '/^[ \t]*winbind separator[ \t]*=/            s/^/#/'                     \
	    -e  '/^[ \t]*dos charset[ \t]*=/                  s/=.*$/= CP932/'            \
	    -e  '/^[ \t]*unix password sync[ \t]*=/           s/=.*$/= No/'               \
	    -e  '/^[ \t]*netbios name[ \t]*=/                 s/=.*$/= '"${NICS_HOST}"'/' \
	    -e  '/^[ \t]*workgroup[ \t]*=/                    s/=.*$/= '"${NICS_WGRP}"'/' \
	    -e  '/^[ \t]*interfaces[ \t]*=/                   s/=.*$/= '"${NICS_NAME}"'/' \
	    -e  'p                                                                     }' \
	> "${_WORK_PATH}"

	# --- shared settings section ---------------------------------------------
	# allow insecure wide links = Yes
	# wide links = Yes
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_WORK_PATH}"
		[homes]
		        allow insecure wide links = Yes
		        browseable = No
		        comment = Home Directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        valid users = %S
		        write list = @${SAMB_GRUP}
		[printers]
		        browseable = No
		        comment = All Printers
		        create mask = 0700
		        path = /var/tmp
		        printable = Yes
		[print$]
		        comment = Printer Drivers
		        path = /var/lib/samba/printers
		[netlogon]
		        browseable = No
		        comment = Network Logon Service
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SAMB}/data/adm/netlogon
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GADM}
		[profiles]
		        browseable = No
		        comment = User profiles
		        path = ${DIRS_SAMB}/data/adm/profiles
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GRUP}
		[share]
		        browseable = No
		        comment = Shared directories
		        path = ${DIRS_SAMB}
		        valid users = @${SAMB_GADM}
		[cifs]
		        browseable = No
		        comment = CIFS directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SAMB}/cifs
		        valid users = @${SAMB_GADM}
		        write list = @${SAMB_GADM}
		[data]
		        browseable = No
		        comment = Data directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SAMB}/data
		        valid users = @${SAMB_GADM}
		        write list = @${SAMB_GADM}
		[dlna]
		        browseable = No
		        comment = DLNA directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SAMB}/dlna
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GRUP}
		[pub]
		        comment = Public directories
		        path = ${DIRS_SAMB}/data/pub
		        valid users = @${SAMB_GRUP}
		[lhome]
		        comment = Linux /home directories
		        path = /home
		        valid users = @${SAMB_GRUP}
		[html-share]
		        comment = HTML shared directories
		        guest ok = Yes
		        path = ${DIRS_HTML}
		        wide links = Yes
		[tftp-share]
		        comment = TFTP shared directories
		        guest ok = Yes
		        path = ${DIRS_TFTP}
		        wide links = Yes
_EOT_

	# --- output --------------------------------------------------------------
	testparm -s "${_WORK_PATH}" > "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_SMBD}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_SMBD}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_SMBD}"
	fi
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NMBD}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NMBD}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NMBD}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup timesyncd -------------------------------------------------
funcSetupNetwork_timesyncd() {
	__FUNC_NAME="funcSetupNetwork_timesyncd"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	_SRVC_NAME="systemd-timesyncd.service"
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- timesyncd.conf ------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/timesyncd.conf.d/local.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		# --- user settings ---
		
		[Time]
		NTP=${NTPS_ADDR}
		FallbackNTP=ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp
		PollIntervalMinSec=1h
		PollIntervalMaxSec=1d
		SaveIntervalSec=infinity
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup chronyd ---------------------------------------------------
funcSetupNetwork_chronyd() {
	__FUNC_NAME="funcSetupNetwork_chronyd"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	_SRVC_NAME="chronyd.service"
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- check command -------------------------------------------------------
	if ! command -v hwclock > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- systemctl -----------------------------------------------------------
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
		hwclock --systohc
		hwclock --test
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- openssh-server settings -------------------------------------------------
funcSetupConfig_ssh() {
	__FUNC_NAME="funcSetupConfig_ssh"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	if   [ -e "${DIRS_TGET:-}/lib/systemd/system/ssh.service"      ] \
	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/ssh.service"  ]; then
		_SRVC_NAME="ssh.service"
	elif [ -e "${DIRS_TGET:-}/lib/systemd/system/sshd.service"     ] \
	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/sshd.service" ]; then
		_SRVC_NAME="sshd.service"
	else
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "not-found" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- default.conf --------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/ssh/sshd_config.d/default.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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
		#PasswordAuthentication yes
		
		# configuring challenge-response authentication
		#ChallengeResponseAuthentication no
		
		# sshd log is output to /var/log/secure
		#SyslogFacility AUTHPRIV
		
		# specify log output level
		#LogLevel INFO
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- systemctl -----------------------------------------------------------
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- vmware shared directory settings ----------------------------------------
funcSetupConfig_vmware() {
	__FUNC_NAME="funcSetupConfig_vmware"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v vmware-hgfsclient > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- check vmware shared directory ---------------------------------------
	if ! vmware-hgfsclient > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist vmware shared directory"
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- check file system ---------------------------------------------------
	if command -v vmhgfs-fuse > /dev/null 2>&1; then
		_HGFS_FSYS="fuse.vmhgfs-fuse"
	else
		_HGFS_FSYS="vmhgfs"
	fi

	# --- fstab ---------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/fstab"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		.host:/         ${DIRS_HGFS:?}       ${_HGFS_FSYS} allow_other,auto_unmount,defaults 0 0
_EOT_

	# --- systemctl -----------------------------------------------------------
		printf "\033[m${PROG_NAME}: %s\033[m\n" "daemon reload"
		systemctl --quiet daemon-reload

	# --- check mount ---------------------------------------------------------
	if [ "${CHGE_ROOT:-}" = "true" ]; then
		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "skip vmware mounts for chroot"
	else
		if mount "${DIRS_HGFS}"; then
			printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "vmware shared directory was mounted successfully"
			LANG=C df -h "${DIRS_HGFS}"
		else
			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "error while mounting vmware shared directory"
			sed -i "${_FILE_PATH}"      \
			    -e '\%^.host:/% s%^%#%'
		fi
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- wireplumber settings ----------------------------------------------------
funcSetupConfig_wireplumber() {
	__FUNC_NAME="funcSetupConfig_wireplumber"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v wireplumber > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- 50-alsa-config.conf -------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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
		        api.alsa.headroom      = 8192
		        session.suspend-timeout-seconds = 0
		      }
		    }
		  }
		]
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- skeleton settings -------------------------------------------------------
funcSetupConfig_skel() {
	__FUNC_NAME="funcSetupConfig_skel"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- .bashrc -------------------------------------------------------------
	if [ -e "${DIRS_TGET:-}/etc/skel/.bashrc" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bashrc"
	elif [ -e "${DIRS_TGET:-}/etc/skel/.i18n" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.i18n"
	else
		_FILE_PATH=""
	fi
	if [ -n "${_FILE_PATH}" ]; then
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- .bash_history -------------------------------------------------------
#	_WORK_TEXT="$(funcInstallPackage "apt")"
#	if [ -n "${_WORK_TEXT}" ]; then
	if command -v apt-get > /dev/null 2>&1; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bash_history"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- .vimrc --------------------------------------------------------------
#	_WORK_TEXT="$(funcInstallPackage "vim-common")"
#	if [ -z "${_WORK_TEXT}" ]; then
#		_WORK_TEXT="$(funcInstallPackage "vim")"
#	fi
#	if [ -n "${_WORK_TEXT}" ]; then
	if command -v vim > /dev/null 2>&1; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.vimrc"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- .curlrc -------------------------------------------------------------
#	_WORK_TEXT="$(funcInstallPackage "curl")"
#	if [ -n "${_WORK_TEXT}" ]; then
	if command -v curl > /dev/null 2>&1; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.curlrc"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
		funcFile_backup   "${_FILE_PATH}" "init"
	fi

	# --- distribute to existing users ----------------------------------------
	for _DIRS_USER in "${DIRS_TGET:-}"/root \
	                  "${DIRS_TGET:-}"/home/*
	do
		if [ ! -e "${_DIRS_USER}" ]; then
			continue
		fi
		for _FILE_PATH in "${DIRS_TGET:-}/etc/skel/.bashrc"       \
		                  "${DIRS_TGET:-}/etc/skel/.bash_history" \
		                  "${DIRS_TGET:-}/etc/skel/.vimrc"        \
		                  "${DIRS_TGET:-}/etc/skel/.curlrc"
		do
			if [ ! -e "${_FILE_PATH}" ]; then
				continue
			fi
			_DIRS_DEST="${_DIRS_USER}/${_FILE_PATH#*/etc/skel/}"
			_DIRS_DEST="${_DIRS_DEST%/*}"
			mkdir -p "${_DIRS_DEST}"
			cp -a "${_FILE_PATH}" "${_DIRS_DEST}"
			chown "${_DIRS_USER##*/}": "${_DIRS_DEST}/${_FILE_PATH##*/}"

			# --- debug out ---------------------------------------------------
			funcDebugout_file "${_DIRS_DEST}/${_FILE_PATH##*/}"
			funcFile_backup   "${_DIRS_DEST}/${_FILE_PATH##*/}" "init"
		done
	done

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- sudoers settings --------------------------------------------------------
funcSetupConfig_sudo() {
	__FUNC_NAME="funcSetupConfig_sudo"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v sudo > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- sudoers -------------------------------------------------------------
	_WORK_PATH="${DIRS_TGET:-}/tmp/sudoers-local.work"
	_WORK_TEXT="$(sed -ne 's/^.*\(sudo\|wheel\).*$/\1/p' "${DIRS_TGET:-}/etc/group")"
	_WORK_TEXT="${_WORK_TEXT:+"%${_WORK_TEXT}$(funcString "$((6-${#_WORK_TEXT}))" " ")ALL=(ALL:ALL) ALL"}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_WORK_PATH}"
		Defaults !targetpw
		Defaults authenticate
		root   ALL=(ALL:ALL) ALL
		${_WORK_TEXT:-}
_EOT_

	# --- sudoers-local -------------------------------------------------------
	if visudo -q -c -f "${_WORK_PATH}"; then
		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers.d/sudoers-local"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${_WORK_PATH}" "${_FILE_PATH}"
		chown -c root:root "${_FILE_PATH}"
		chmod -c 0440 "${_FILE_PATH}"
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "file creation successful"
		# --- sudoers ---------------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers"
		_WORK_PATH="${DIRS_TGET:-}/tmp/sudoers.work"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		sed "${_FILE_PATH}"                                              \
		    -e '/^Defaults[ \t]\+targetpw[ \t]*/ s/^/#/'                 \
		    -e '/^ALL[ \t]\+ALL=(ALL\(\|:ALL\))[ \t]\+ALL[ \t]*/ s/^/#/' \
		> "${_WORK_PATH}"
		if visudo -q -c -f "${_WORK_PATH}"; then
			cp -a "${_WORK_PATH}" "${_FILE_PATH}"
			chown -c root:root "${_FILE_PATH}"
			chmod -c 0440 "${_FILE_PATH}"
			printf "\033[m${PROG_NAME}: \033[93m%s\033[m\n" "sudo -ll: list user's privileges or check a specific command"

			# --- debug out ---------------------------------------------------
			funcDebugout_file "${_FILE_PATH}"
			funcFile_backup   "${_FILE_PATH}" "init"
		else
			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "file creation failure"
			visudo -c -f "${_WORK_PATH}" || true
		fi
	else
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "file creation failure"
		visudo -c -f "${_WORK_PATH}" || true
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- blacklist settings ------------------------------------------------------
funcSetupConfig_blacklist() {
	__FUNC_NAME="funcSetupConfig_blacklist"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check load module ---------------------------------------------------
	if ! lsmod | grep -q 'floppy'; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- blacklist-floppy.conf -----------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/modprobe.d/blacklist-floppy.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	echo 'blacklist floppy' > "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- update initramfs ----------------------------------------------------
#	if [ -z "${DIRS_TGET:-}" ]; then
#		rmmod floppy || true
#	fi
	if command -v update-initramfs > /dev/null 2>&1; then
		_REAL_PATH=""
		_KNEL_VERS=""
		_REAL_VLNZ=""
		_REAL_IRAM=""
		_WORK_TEXT="$(echo "${DIRS_TGET:-}" | sed -e 's%[^/]%%g')"

		# --- initramfs -------------------------------------------------------
		for _FILE_PATH in $(find "${DIRS_TGET:-}/" "${DIRS_TGET:-}/boot" -maxdepth 1 -name 'initrd*' | sort -uV -t '/' -k $((${#_WORK_TEXT}+3)) -k $((${#_WORK_TEXT}+2)))
		do
			_REAL_PATH="$(realpath "${_FILE_PATH}")"
			if [ -e "${_REAL_PATH}" ]; then
				_REAL_IRAM="${_REAL_PATH}"
				_KNEL_VERS="${_REAL_IRAM##*/}"
				_KNEL_VERS="${_KNEL_VERS#*-}"
				_KNEL_VERS="${_KNEL_VERS%.img}"
				break
			fi
		done

		# --- vmlinuz ---------------------------------------------------------
		if [ -z "${_KNEL_VERS:-}" ]; then
			for _FILE_PATH in $(find "${DIRS_TGET:-}/" "${DIRS_TGET:-}/boot" -maxdepth 1 \( -name 'vmlinuz*' -o -name 'linux*' \) | sort -uV -t '/' -k $((${#_WORK_TEXT}+3)) -k $((${#_WORK_TEXT}+2)))
			do
				_REAL_PATH="$(realpath "${_FILE_PATH}")"
				if [ -e "${_REAL_PATH}" ]; then
					_REAL_VLNZ="${_REAL_PATH}"
					_KNEL_VERS="$(file "${_REAL_VLNZ}")"
					_KNEL_VERS="${_KNEL_VERS#*version }"
					_KNEL_VERS="${_KNEL_VERS%% *}"
					break
				fi
			done
		fi

		# --- uname -r --------------------------------------------------------
		if [ -z "${_KNEL_VERS:-}" ]; then
			_KNEL_VERS="$(uname -r)"
		fi

		# --- debug out -------------------------------------------------------
		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "version" "${_KNEL_VERS:-}"
		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "vmlinuz" "${_REAL_VLNZ:-}"
		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "initrd " "${_REAL_IRAM:-}"

		# --- create initramfs ------------------------------------------------
		if [ -n "${_KNEL_VERS:-}" ]; then
			update-initramfs -c -b "${PROG_DIRS}/" -k "${_KNEL_VERS}"
			for _FILE_PATH in $(find "${PROG_DIRS:-}/" -maxdepth 1 -name 'initrd*'"${_KNEL_VERS}"'*' | sort -uV -t '/' -k $((${#PROG_DIRS}+3)) -k $((${#PROG_DIRS}+2)))
			do
				printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "create " "${_FILE_PATH:-}"
				funcFile_backup "${_REAL_IRAM}"
				cp --preserve=timestamps "${_FILE_PATH}" "${_REAL_IRAM}"
				break
			done
#			funcFile_backup   "${_REAL_VLNZ}" "init"
			funcFile_backup   "${_REAL_IRAM}" "init"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- grub menu settings ------------------------------------------------------
funcSetupConfig_grub_menu() {
	__FUNC_NAME="funcSetupConfig_grub_menu"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if command -v grub-mkconfig > /dev/null 2>&1; then
		_WORK_COMD="grub-mkconfig"
	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		_WORK_COMD="grub2-mkconfig"
	else
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- check setup ---------------------------------------------------------
	_TITL_TEXT="### User Custom ###"
	_FILE_PATH="${DIRS_TGET:-}/etc/default/grub"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	if grep -q "${_TITL_TEXT}" "${_FILE_PATH}"; then
		printf "\033[m${PROG_NAME}: \033[93m%s\033[m\n" "already setup"
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- grub ----------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		
		${_TITL_TEXT}
		GRUB_RECORDFAIL_TIMEOUT=10
		GRUB_TIMEOUT=3
		
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- create grub.cfg -----------------------------------------------------
	_FILE_PATH="$(find "${DIRS_TGET:-}"/boot/ \( -path '/*/efi' -o -path '/*/EFI' \) -prune -o -type f -name 'grub.cfg' -print)"
	if [ -n "${_FILE_PATH}" ]; then
		_WORK_PATH="${DIRS_TGET:-}/tmp/grub.cfg.work"
		if "${_WORK_COMD}" --output="${_WORK_PATH}"; then
			if cp --preserve=timestamps "${_WORK_PATH}" "${_FILE_PATH}"; then
				printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "success to create ${_FILE_PATH}"

				# --- debug out -----------------------------------------------
				funcDebugout_file "${_FILE_PATH}"
				funcFile_backup   "${_FILE_PATH}" "init"
			else
				printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to copy ${_FILE_PATH}"
			fi
		else
			printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to create grub.cfg"
		fi
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- ipxe module settings ----------------------------------------------------
funcSetupModule_ipxe() {
	__FUNC_NAME="funcSetupModule_ipxe"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check directory -----------------------------------------------------
	if [ ! -e "${DIRS_TFTP}" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- get module ----------------------------------------------------------
#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/undionly.kpxe" "https://boot.ipxe.org/undionly.kpxe" || true
#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/ipxe.efi"      "https://boot.ipxe.org/ipxe.efi" || true
#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/wimboot"       "https://github.com/ipxe/wimboot/releases/latest/download/wimboot" || true
	_FILE_PATH="${PROG_DIRS:?}/get_module_ipxe.sh"
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		#!/bin/sh
		
		# *** initialization **********************************************************
		
		 	case "${1:-}" in
		 		-dbg) set -x; shift;;
		 		-dbgout) _DBGOUT="true"; shift;;
		 		*) ;;
		 	esac
		
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# End with status other than 0
		 	set -u								# End with undefined variable reference
		#	set -o pipefail						# End with in pipe error
		
		#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
		 	trap 'exit 1' 1 2 3 15
		 	export LANG=C
		
		 	if set -o | grep "^xtrace\s*on$"; then
		 		exec 2>&1
		 	fi
		
		 	# --- working directory name ----------------------------------------------
		 	readonly PROG_PATH="$0"
		#	readonly PROG_PRAM="$*"
		#	readonly PROG_DIRS="${PROG_PATH%/*}"
		 	readonly PROG_NAME="${PROG_PATH##*/}"
		#	readonly PROG_PROC="${PROG_NAME}.$$"
		
		# *** main processing section *************************************************
		 	# --- start ---------------------------------------------------------------
		#	_start_time=$(date +%s)
		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
		 	# --- main ----------------------------------------------------------------
_EOT_
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 	_DIRS_TFTP='${DIRS_TFTP}'
_EOT_
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 	for _WEBS_ADDR in \
		 		https://boot.ipxe.org/undionly.kpxe \
		 		https://boot.ipxe.org/ipxe.efi \
		 		https://github.com/ipxe/wimboot/releases/latest/download/wimboot
		 	do
		 		if ! wget --tries=3 --timeout=10 --no-verbose --output-document="${_DIRS_TFTP}/ipxe/${_WEBS_ADDR##*/}" "${_WEBS_ADDR}"; then
		 			printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to wget: ${_WEBS_ADDR}"
		 		fi
		 	done
		 	# --- complete ------------------------------------------------------------
		#	_end_time=$(date +%s)
		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		#	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
		 	exit 0
		
		### eof #######################################################################
_EOT_
	chown -c root:root "${_FILE_PATH}"
	chmod -c 0500 "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"
	funcFile_backup   "${_FILE_PATH}" "init"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- main --------------------------------------------------------------------
funcMain() {
	_FUNC_NAME="funcMain"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- initialize ----------------------------------------------------------
	funcInitialize						# initialize

	# --- debug out -----------------------------------------------------------
	funcDebugout_parameter
	funcFile_backup "/proc/cmdline"
	funcFile_backup "/proc/mounts"
	funcFile_backup "/proc/self/mounts"

	# --- installing missing packages -----------------------------------------
	funcInstall_package

	# --- creating a shared environment ---------------------------------------
	funcCreate_shared_env

	# --- apparmor settings -------------------------------------------------------
	funcSetupConfig_apparmor

	# --- selinux settings ----------------------------------------------------
	funcSetupConfig_selinux

	# --- network manager -----------------------------------------------------
	funcSetupNetwork_connman			# network setup connman
	funcSetupNetwork_netplan			# network setup netplan
	funcSetupNetwork_nmanagr			# network setup network manager

	# --- network settings ----------------------------------------------------
	funcSetupNetwork_hostname			# network setup hostname
	funcSetupNetwork_hosts				# network setup hosts
#	funcSetupNetwork_hosts_access		# network setup hosts.allow/hosts.deny
	funcSetupNetwork_firewalld			# network setup firewalld
	funcSetupNetwork_dnsmasq			# network setup dnsmasq
	funcSetupNetwork_resolv				# network setup resolv.conf
	funcSetupNetwork_apache				# network setup apache
	funcSetupNetwork_samba				# network setup samba
	funcSetupNetwork_timesyncd			# network setup timesyncd
	funcSetupNetwork_chronyd			# network setup chronyd

	# --- openssh-server settings ---------------------------------------------
	funcSetupConfig_ssh

	# --- vmware shared directory settings ------------------------------------
	funcSetupConfig_vmware

	# --- wireplumber settings ------------------------------------------------
	funcSetupConfig_wireplumber

	# --- skeleton settings ---------------------------------------------------
	funcSetupConfig_skel

	# --- sudoers settings ----------------------------------------------------
	funcSetupConfig_sudo

	# --- blacklist settings --------------------------------------------------
	funcSetupConfig_blacklist

	# --- grub menu settings --------------------------------------------------
	funcSetupConfig_grub_menu

	# --- ipxe module settings ------------------------------------------------
	funcSetupModule_ipxe

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${_FUNC_NAME}] ---"
}

# *** main processing section *************************************************
	# --- start ---------------------------------------------------------------
	_start_time=$(date +%s)
	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
	# --- main ----------------------------------------------------------------
	funcMain
	# --- complete ------------------------------------------------------------
	_end_time=$(date +%s)
	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
	exit 0

### eof #######################################################################
