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
	DIRS_TGET=""
	if command -v systemd-detect-virt > /dev/null 2>&1 \
	&& systemd-detect-virt --chroot; then
		CHGE_ROOT="true"
	fi
	if [ -d /target/. ]; then
		DIRS_TGET="/target"
	elif [ -d /mnt/sysimage/. ]; then
		DIRS_TGET="/mnt/sysimage"
	fi
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
	readonly DIRS_HGFS="${DIRS_TGET:-}/srv/hgfs"			# root of hgfs shared directory
	readonly DIRS_HTML="${DIRS_TGET:-}/srv/http"			# root of html shared directory
	readonly DIRS_TFTP="${DIRS_TGET:-}/srv/tftp"			# root of tftp shared directory
	readonly DIRS_SAMB="${DIRS_TGET:-}/srv/samba"			# root of samba shared directory
	readonly DIRS_USER="${DIRS_TGET:-}/srv/user"			# root of user shared directory

	# --- set command line parameter ------------------------------------------
	for LINE in ${COMD_LINE:-} ${PROG_PRAM:-}
	do
		case "${LINE}" in
			debug | debugout | dbg         ) DBGS_FLAG="true";;
			target=*                       ) DIRS_TGET="${LINE#*target=}";;
			iso-url=*.iso  | url=*.iso     ) ISOS_FILE="${LINE#*url=}";;
			preseed/url=*  | url=*         ) SEED_FILE="${LINE#*url=}";;
			preseed/file=* | file=*        ) SEED_FILE="${LINE#*file=}";;
			ds=nocloud*                    ) SEED_FILE="${LINE#*ds=nocloud*=}";;
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
			*)  ;;
		esac
	done

	# --- working directory name ----------------------------------------------
	readonly DIRS_ORIG="${PROG_DIRS}/orig"
	readonly DIRS_LOGS="${PROG_DIRS}/logs"

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
funcInstallPackage() {
	if command -v apt > /dev/null 2>&1; then
		LANG=C apt list "${1:?}" 2> /dev/null | sed -ne '\%^'"$1"'/.*\[installed\]%p' || true
	elif command -v yum > /dev/null 2>&1; then
		LANG=C yum list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
	elif command -v dnf > /dev/null 2>&1; then
		LANG=C dnf list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
	elif command -v zypper > /dev/null 2>&1; then
		LANG=C zypper se -i "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
	fi
}

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

	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"
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
		_WORK_TEXT="$(sed -ne '/iface[ \t]\+ens160[ \t]\+inet[ \t]\+/ s/^.*\(static\|dhcp\).*$/\1/p' /etc/network/interfaces)"
		case "${_WORK_TEXT}" in
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
	if [ "${IPV4_DHCP}" = "true" ]; then
		NICS_IPV4=""
	fi
	NICS_IPV4="${NICS_IPV4:-"${IPV4_DUMY}"}"
	NICS_DNS4="${NICS_DNS4:-"$(sed -ne 's/^nameserver[ \]\+\([[:alnum:]:.]\+\)[ \t]*$/\1/p' /etc/resolv.conf | sed -e ':l; N; s/\n/,/; b l;')"}"
	NICS_GATE="${NICS_GATE:-"$(ip -4 -oneline route list match default | cut -d ' ' -f 3)"}"
	NICS_FQDN="${NICS_FQDN:-"$(cat "${DIRS_TGET:-}/etc/hostname")"}"
	NICS_HOST="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 1)"}"
	NICS_WGRP="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 2)"}"
	NICS_WGRP="${NICS_WGRP:-"$(sed -ne 's/^search[ \t]\+\([[:alnum:]]\+\)[ \t]*/\1/p' "${DIRS_TGET:-}/etc/resolv.conf")"}"
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
		touch "$1"
#		return
	fi
	# --- backup --------------------------------------------------------------
	_FILE_PATH="${1}"
	_BACK_PATH="${1#*"${DIRS_TGET:-}"}"
	_BACK_PATH="${DIRS_ORIG}/${_BACK_PATH#/}"
	mkdir -p "${_BACK_PATH%/*}"
	if [ -e "${_BACK_PATH}" ]; then
		_BACK_PATH="${_BACK_PATH}.$(date +"%Y%m%d%H%M%S")"
	fi
	if [ -n "${DBGS_FLAG:-}" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "backup: ${_FILE_PATH} -> ${_BACK_PATH}"
	fi
	if [ -f "$1" ]; then
		cp -a "$1" "${_BACK_PATH}"
	else
		mv "$1" "${_BACK_PATH}"
	fi

	# --- complete ------------------------------------------------------------
	if [ -n "${DBGS_FLAG:-}" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${____FUNC_NAME}] ---"
	fi
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
	ln -s ../conf         "${DIRS_TFTP}"/menu-bios/
	ln -s ../imgs         "${DIRS_TFTP}"/menu-bios/
	ln -s ../isos         "${DIRS_TFTP}"/menu-bios/
	ln -s ../load         "${DIRS_TFTP}"/menu-bios/
	ln -s ../rmak         "${DIRS_TFTP}"/menu-bios/
	ln -s ../syslinux.cfg "${DIRS_TFTP}"/menu-bios/pxelinux.cfg/default
	ln -s ../conf         "${DIRS_TFTP}"/menu-efi64/
	ln -s ../imgs         "${DIRS_TFTP}"/menu-efi64/
	ln -s ../isos         "${DIRS_TFTP}"/menu-efi64/
	ln -s ../load         "${DIRS_TFTP}"/menu-efi64/
	ln -s ../rmak         "${DIRS_TFTP}"/menu-efi64/
	ln -s ../syslinux.cfg "${DIRS_TFTP}"/menu-efi64/pxelinux.cfg/default

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

	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_HTML}"/html/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_HTML}"/html/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_HTML}"/html/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_HTML}"/html/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_HTML}"/html/

	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_TFTP}"/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_TFTP}"/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_TFTP}"/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_TFTP}"/
	ln -s "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_TFTP}"/

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

	if command -v setsebool > /dev/null 2>&1; then
		setsebool -P httpd_use_fusefs 1
		setsebool -P samba_enable_home_dirs 1
		setsebool -P samba_export_all_ro 1
		setsebool -P samba_export_all_rw 1
	fi

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
#	ln -s "${DIRS_HTML#${DIRS_TGET:-}}" "${_WORK_PATH}"

	# --- symlink for tftp ----------------------------------------------------
#	_WORK_PATH="${DIRS_TGET:-}/var/lib/tftpboot"
#	funcFile_backup "${_WORK_PATH}"
#	ln -s "${DIRS_TFTP#${DIRS_TGET:-}}" "${_WORK_PATH}"

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
#	funcDebugout_file "${_FILE_PATH}"

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
	_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/Wired connection 1"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[connection]
		id=${_FILE_PATH##*/}
		type=ethernet
		interface-name=${NICS_NAME}
		autoconnect=true
		zone=home
		
		[ethernet]
		wake-on-lan=0
		mac-address=${NICS_MADR}
		
_EOT_
	if [ "${IPV4_DHCP}" = "true" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			[ipv4]
			method=auto
			
			[ipv6]
			method=auto
			addr-gen-mode=default
			
			[proxy]
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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
	chmod 600 "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

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

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="NetworkManager.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
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

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup hosts.allow/hosts.deny ------------------------------------
funcSetupNetwork_hosts_access() {
	__FUNC_NAME="funcSetupNetwork_hosts_access"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- hosts ---------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.allow"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		ALL : ${IPV4_LHST}
		ALL : [${IPV6_LHST}]
		ALL : ${IPV4_UADR}.0/${NICS_BIT4}
		ALL : [${LINK_UADR%%::}::%${NICS_NAME}]/10
		#ALL : [${IPV6_UADR%%::}::]/${IPV6_CIDR}
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- hosts ---------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.deny"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		ALL : ALL
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup firewalld -------------------------------------------------
funcSetupNetwork_firewalld() {
	__FUNC_NAME="funcSetupNetwork_firewalld"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if ! command -v firewall-cmd > /dev/null 2>&1; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		return
	fi

	# --- firewalld -----------------------------------------------------------
	_FWAL_ZONE="home"
	_FWAL_PORT="$(printf -- "--add-port=%s " 30000-60000/udp)"
	_FWAL_NAME="$(printf -- "--add-service=%s " dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp)"
	_SRVC_NAME="firewalld.service"
	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "active" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service active: ${_SRVC_NAME}"
		# shellcheck disable=SC2086
		firewall-cmd --quiet --zone="${_FWAL_ZONE}" ${_FWAL_NAME} --permanent
		# shellcheck disable=SC2086
		firewall-cmd --quiet --zone="${_FWAL_ZONE}" ${_FWAL_PORT} --permanent
		firewall-cmd --quiet --zone="${_FWAL_ZONE}" --change-interface="${NICS_NAME}" --permanent || true
		firewall-cmd --set-default-zone="${_FWAL_ZONE}" || true
		# --- systemctl -------------------------------------------------------
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl --quiet daemon-reload
		systemctl --quiet restart "${_SRVC_NAME}"
		firewall-cmd --quiet --reload
		firewall-cmd --get-zone-of-interface="${NICS_NAME}"
		firewall-cmd --list-all --zone="${_FWAL_ZONE}"
	else
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service inactive: ${_SRVC_NAME}"
		# shellcheck disable=SC2086
		firewall-offline-cmd --zone="${_FWAL_ZONE}" ${_FWAL_NAME}
		# shellcheck disable=SC2086
		firewall-offline-cmd --zone="${_FWAL_ZONE}" ${_FWAL_PORT}
		firewall-offline-cmd --zone="${_FWAL_ZONE}" --change-interface="${NICS_NAME}" || true
		firewall-offline-cmd --set-default-zone="${_FWAL_ZONE}" || true
		firewall-offline-cmd --get-zone-of-interface="${NICS_NAME}"
		firewall-offline-cmd --list-all --zone="${_FWAL_ZONE}"
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
	else
		# --- resolv.conf -> /run/systemd/resolve/stub-resolv.conf ------------
		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		funcFile_backup "${_FILE_PATH}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		rm -f "${_FILE_PATH}"
#		if [ -e "${DIRS_TGET:-}/run/systemd/resolve/stub-resolv.conf" ]; then
			ln -sr /run/systemd/resolve/stub-resolv.conf "${_FILE_PATH}"
#		else
#			ln -sr /run/systemd/resolve/resolv.conf "${_FILE_PATH}"
#		fi

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"

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

		# --- systemctl -------------------------------------------------------
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
			resolvectl status
		fi
	fi

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
	fi

	# --- default.conf --------------------------------------------------------
	_CONF_FILE="$(find "${DIRS_TGET:-}/usr/share" -name 'trust-anchors.conf' -type f)"
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
		port=0                                                      # listening port
		#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
		#domain-needed                                              # do not forward plain names
		#domain=${NICS_WGRP}                                           # local domain name
		#expand-hosts                                               # add domain name to host
		#filterwin2k                                                # filter for windows
		#interface=${NICS_NAME}                                           # listen to interface
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
		#bind-interfaces                                            # enable multiple instances of dnsmasq
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

	# --- pxeboot.conf --------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		# --- tftp --------------------------------------------------------------------
		#enable-tftp=${NICS_NAME}                                         # enable tftp server
		#tftp-root=${DIRS_TFTP}                                        # tftp root directory
		#tftp-lowercase                                             # convert tftp request path to all lowercase
		#tftp-no-blocksize                                          # stop negotiating "block size" option
		#tftp-no-fail                                               # do not abort startup even if tftp directory is not accessible
		#tftp-secure                                                # enable tftp secure mode
		
		# --- pxe boot ----------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                             # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux     #  0 Intel x86PC
		#pxe-service=PC98             , "PXEBoot-PC98"             ,                        #  1 NEC/PC98
		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,                        #  2 EFI Itanium
		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,                        #  3 DEC Alpha
		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,                        #  4 Arc x86
		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",                        #  5 Intel Lean Client
		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,                        #  6 EFI IA32
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootx64.efi  #  7 EFI BC
		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,                        #  8 EFI Xscale
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootx64.efi  #  9 EFI x86-64
		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,                        # 10 ARM 32bit
		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,                        # 11 ARM 64bit
		
		# --- ipxe block --------------------------------------------------------------
		#dhcp-match=set:iPXE,175                                                            #
		#pxe-prompt="Press F8 for boot menu", 0                                             # pxe boot prompt
		#pxe-service=tag:iPXE ,x86PC     , "PXEBoot-x86PC"     , /autoexec.ipxe             #  0 Intel x86PC (iPXE)
		#pxe-service=tag:!iPXE,x86PC     , "PXEBoot-x86PC"     , ipxe/undionly.kpxe         #  0 Intel x86PC
		#pxe-service=tag:!iPXE,BC_EFI    , "PXEBoot-BC_EFI"    , ipxe/ipxe.efi              #  7 EFI BC
		#pxe-service=tag:!iPXE,x86-64_EFI, "PXEBoot-x86-64_EFI", ipxe/ipxe.efi              #  9 EFI x86-64
		
		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		
		# --- eof ---------------------------------------------------------------------
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

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

# --- network setup apache ----------------------------------------------------
funcSetupNetwork_apache() {
	__FUNC_NAME="funcSetupNetwork_apache"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	if [ -e "${DIRS_TGET:-}/lib/systemd/system/apache2.service" ]; then
		_SRVC_NAME="apache2.service"
	else
		_SRVC_NAME="httpd.service"
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
	if [ -e "${DIRS_TGET:-}/lib/systemd/system/smbd.service" ]; then
		_SRVC_SMBD="smbd.service"
		_SRVC_NMBD="nmbd.service"
	else
		_SRVC_SMBD="smb.service"
		_SRVC_NMBD="nmb.service"
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
	fi

	# --- smb.conf ------------------------------------------------------------
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_WORK_PATH}"
		[homes]
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
		[tftp-share]
		        comment = TFTP shared directories
		        guest ok = Yes
		        path = ${DIRS_TFTP}
_EOT_

	# --- output --------------------------------------------------------------
	testparm -s "${_WORK_PATH}" > "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- systemctl -----------------------------------------------------------
	if [ -e "${DIRS_TGET:-}/lib/systemd/system/smbd.service" ]; then
		_SRVC_SMBD="smbd.service"
		_SRVC_NMBD="nmbd.service"
	else
		_SRVC_SMBD="smb.service"
		_SRVC_NMBD="nmb.service"
	fi
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

# --- openssh-server settings -------------------------------------------------
funcSetupConfig_ssh() {
	__FUNC_NAME="funcSetupConfig_ssh"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check service -------------------------------------------------------
	if [ -e "${DIRS_TGET:-}/lib/systemd/system/ssh.service" ]; then
		_SRVC_NAME="ssh.service"
	else
		_SRVC_NAME="sshd.service"
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
	if mount "${DIRS_HGFS}"; then
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "vmware shared directory was mounted successfully"
		LANG=C df -h "${DIRS_HGFS}"
	else
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "error while mounting vmware shared directory"
		sed -i "${_FILE_PATH}"      \
		    -e '\%^.host:/% s%^%#%'
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

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
	fi

	# --- .bash_history -------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "apt")"
	if [ -n "${_WORK_TEXT}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bash_history"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
	fi

	# --- .vimrc --------------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "vim-common")"
	if [ -n "${_WORK_TEXT}" ]; then
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
	fi

	# --- .curlrc -------------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "curl")"
	if [ -n "${_WORK_TEXT}" ]; then
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
		done
	done

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- sudoers settings --------------------------------------------------------
funcSetupConfig_sudo() {
	__FUNC_NAME="funcSetupConfig_sudo"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- sudoers -------------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "sudo")"
	if [ -n "${_WORK_TEXT}" ]; then
		_WORK_TEXT="$(printf '\t')"
		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers"
		if ! grep -qE '^root[ '"${_WORK_TEXT}"']+ALL=\(ALL\)[ '"${_WORK_TEXT}"']+ALL$' "${_FILE_PATH}"; then
			_FILE_PATH="${DIRS_TGET:-}/etc/sudoers.d/default.conf"
			funcFile_backup "${_FILE_PATH}"
			mkdir -p "${_FILE_PATH%/*}"
			printf "root\tALL=(ALL)\tALL" >> "${_FILE_PATH}"
			chmod 0440 "${_FILE_PATH}"
		fi
		_WORK_TEXT="$(printf '\t')"
		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers"
		if ! grep -qE '^%(sudo|wheel)[ '"${_WORK_TEXT}"']+ALL=\(ALL\)[ '"${_WORK_TEXT}"']+ALL$' "${_FILE_PATH}"; then
			_FILE_PATH="${DIRS_TGET:-}/etc/sudoers.d/00-local"
			funcFile_backup "${_FILE_PATH}"
			mkdir -p "${_FILE_PATH%/*}"
			_WORK_TEXT="$(groups |  sed -ne 's/^.*\(sudo\|wheel\).*$/\1/p')"
			case "${_WORK_TEXT:-}" in
				sudo|wheel)
					printf "%${_WORK_TEXT}\tALL=(ALL)\tALL" >> "${_FILE_PATH}"
					chmod 0440 "${_FILE_PATH}"
					;;
				*) ;;
			esac
		fi

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
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
	echo 'blacklist floppy' > "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- update initramfs ----------------------------------------------------
	if [ -z "${DIRS_TGET:-}" ]; then
		rmmod floppy || true
	fi
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
		fi
	fi

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

	# --- creating a shared environment ---------------------------------------
	funcCreate_shared_env

	# --- network manager -----------------------------------------------------
	funcSetupNetwork_connman			# network setup connman
	funcSetupNetwork_netplan			# network setup netplan
	funcSetupNetwork_nmanagr			# network setup network manager

	# --- network settings ----------------------------------------------------
	funcSetupNetwork_hostname			# network setup hostname
	funcSetupNetwork_hosts				# network setup hosts
	funcSetupNetwork_hosts_access		# network setup hosts.allow/hosts.deny
	funcSetupNetwork_firewalld			# network setup firewalld
	funcSetupNetwork_resolv				# network setup resolv.conf
	funcSetupNetwork_dnsmasq			# network setup dnsmasq
	funcSetupNetwork_apache				# network setup apache
	funcSetupNetwork_samba				# network setup samba

	# --- openssh-server settings ---------------------------------------------
	funcSetupConfig_ssh

	# --- vmware shared directory settings ------------------------------------
	funcSetupConfig_vmware

	# --- skeleton settings ---------------------------------------------------
	funcSetupConfig_skel

	# --- sudoers settings ----------------------------------------------------
	funcSetupConfig_sudo

	# --- blacklist settings --------------------------------------------------
	funcSetupConfig_blacklist

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
