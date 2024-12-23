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
	readonly      PROG_PATH="$0"
	readonly      PROG_PRAM="$*"
	readonly      PROG_DIRS="${PROG_PATH%/*}"
	readonly      PROG_NAME="${PROG_PATH##*/}"
	readonly      PROG_PROC="${PROG_NAME}.$$"
	readonly      DIRS_WORK="${PWD%/}/${PROG_NAME%.*}"
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
	if [ -d /target/. ]; then
		DIRS_TGET="/target"
	fi
	ROWS_SIZE="25"						# screen size: rows
	COLS_SIZE="80"						# screen size: columns
	TEXT_GAP1=""						# gap1
	TEXT_GAP2=""						# gap2

	# --- set command line parameter ------------------------------------------
	for LINE in ${COMD_LINE:-} ${PROG_PRAM:-}
	do
		case "${LINE}" in
			debug | debugout | dbg         ) DBGS_FLAG="true"      ;;
			target=*                       ) DIRS_TGET="${LINE#*=}";;
			iso-url=*.iso  | url=*.iso     ) ISOS_FILE="${LINE#*=}";;
			preseed/url=*  | url=*         ) SEED_FILE="${LINE#*=}";;
			preseed/file=* | file=*        ) SEED_FILE="${LINE#*=}";;
			ds=nocloud*                    ) SEED_FILE="${LINE#*=}";;
			netcfg/target_network_config=* ) NMAN_FLAG="${LINE#*=}";;
			netcfg/choose_interface=*      ) NICS_NAME="${LINE#*=}";;
			netcfg/disable_dhcp=*          ) IPV4_DHCP="$([ "${LINE#*=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/disable_autoconfig=*    ) IPV4_DHCP="$([ "${LINE#*=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/get_ipaddress=*         ) NICS_IPV4="${LINE#*=}";;
			netcfg/get_netmask=*           ) NICS_MASK="${LINE#*=}";;
			netcfg/get_gateway=*           ) NICS_GATE="${LINE#*=}";;
			netcfg/get_nameservers=*       ) NICS_DNS4="${LINE#*=}";;
			netcfg/get_hostname=*          ) NICS_FQDN="${LINE#*=}";;
			netcfg/get_domain=*            ) NICS_WGRP="${LINE#*=}";;
			interface=*                    ) NICS_NAME="${LINE#*=}";;
			hostname=*                     ) NICS_FQDN="${LINE#*=}";;
			domain=*                       ) NICS_WGRP="${LINE#*=}";;
			ip=dhcp | ip4=dhcp | ipv4=dhcp ) IPV4_DHCP="true"      ;;
			ip=* | ip4=* | ipv4=*          ) IPV4_DHCP="false"
			                                 NICS_IPV4="$(echo "${LINE#*=}" | cut -d ':' -f 1)"
			                                 NICS_GATE="$(echo "${LINE#*=}" | cut -d ':' -f 3)"
			                                 NICS_MASK="$(echo "${LINE#*=}" | cut -d ':' -f 4)"
			                                 NICS_FQDN="$(echo "${LINE#*=}" | cut -d ':' -f 5)"
			                                 NICS_NAME="$(echo "${LINE#*=}" | cut -d ':' -f 6)"
			                                 NICS_DNS4="$(echo "${LINE#*=}" | cut -d ':' -f 8)"
			                                 ;;
			*)  ;;
		esac
	done

	# --- working directory name ----------------------------------------------
	readonly      DIRS_ORIG="${DIRS_TGET:-}/var/log/installer/${PROG_NAME}/orig"
	readonly      DIRS_LOGS="${DIRS_TGET:-}/var/log/installer/${PROG_NAME}/logs"

	# --- log out -------------------------------------------------------------
	if [ -n "${DBGS_FLAG:-}" ] \
	&& command -v mkfifo; then
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
LANG=C apt list "$@" 2> /dev/null | sed -ne '/^[ \t]*$\|WARNING\|Listing\|installed/! s%/.*%%gp' | sed -z 's/[\r\n]\+/ /g'
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
	# --- working directory name ----------------------------------------------
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PATH" "${PROG_PATH:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PRAM" "${PROG_PRAM:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_DIRS" "${PROG_DIRS:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_NAME" "${PROG_NAME:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PROC" "${PROG_PROC:-}"
	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_WORK" "${DIRS_WORK:-}"
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

	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out start: --- [$1] ---"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	cat "$1"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out end: --- [$1] ---"
	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
}

# --- initialize --------------------------------------------------------------
funcInitialize() {
	__FUNC_NAME="funcInitialize"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- set system parameter ------------------------------------------------
	if command -v tput > /dev/null 2>&1; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [ "${ROWS_SIZE}" -lt 25 ]; then
		ROWS_SIZE=25
	fi
	if [ "${COLS_SIZE}" -lt 80 ]; then
		COLS_SIZE=80
	fi

	readonly      ROWS_SIZE
	readonly      COLS_SIZE

	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"
	TEXT_GAP1="$(funcString "${TEXT_GAPS}" '-')"
	TEXT_GAP2="$(funcString "${TEXT_GAPS}" '=')"

	readonly      TEXT_GAP1
	readonly      TEXT_GAP2

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
	if [ "${NICS_FQDN}" = "${NICS_HOST}" ] && [ -n "${NICS_WGRP}" ]; then
		NICS_FQDN="${NICS_HOST}.${NICS_WGRP}"
	fi

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
		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist: [$1]"
		return
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
	cp -a "$1" "${_BACK_PATH}"

	# --- complete ------------------------------------------------------------
	if [ -n "${DBGS_FLAG:-}" ]; then
		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${____FUNC_NAME}] ---"
	fi
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

	# --- disable_dns_proxy.conf ----------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	_WORK_TEXT="$(command -v connmand 2> /dev/null)"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[Service]
		ExecStart=
		ExecStart=${_WORK_TEXT} -n --nodnsproxy
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- settings ------------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/settings"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[global]
		OfflineMode=false
		
		[Wired]
		Enable=true
		Tethering=false
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- configures ----------------------------------------------------------
	_WORK_TEXT="$(echo "${NICS_MADR}" | sed -e 's/://g')"
	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/ethernet_${_WORK_TEXT}_cable/settings"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
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
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "enabled" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl daemon-reload
		systemctl restart "${_SRVC_NAME}"
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[connection]
		id=${_FILE_PATH##*/}
		type=ethernet
		uuid=
		interface-name=${NICS_NAME}
		
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[main]
		dns=dnsmasq
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="NetworkManager.service"
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "enabled" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl daemon-reload
		systemctl restart "${_SRVC_NAME}"
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
	_FILE_PATH="${DIRS_TGET:-}/etc/firewalld/zones/home.xml"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	sed -e '/<\/zone>/i\  <interface name="'"${NICS_NAME}"'"/>' \
	    -e '/samba-client/i\  <service name="samba"/>'          \
	    "${DIRS_TGET:-}/usr/lib/firewalld/zones/home.xml"       \
	> "${_FILE_PATH}"

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="firewalld.service"
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "enabled" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl daemon-reload
		systemctl restart "${_SRVC_NAME}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

# --- network setup resolv.conf -----------------------------------------------
funcSetupNetwork_resolv() {
	__FUNC_NAME="funcSetupNetwork_resolv"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	# --- check command -------------------------------------------------------
	if command -v resolvectl > /dev/null 2>&1; then
		# --- resolved.conf ---------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		if ! grep -qE '^DNS=' "${_FILE_PATH}"; then
			sed -i "${_FILE_PATH}"                       \
			    -e '/^\[Resolve\]$/a DNS='"${IPV4_LHST}"
		fi

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"

		# --- systemctl -------------------------------------------------------
		_SRVC_NAME="systemd-resolved.service"
		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		if [ "${_SRVC_STAT}" = "enabled" ]; then
			printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
			systemctl daemon-reload
			systemctl restart "${_SRVC_NAME}"
		fi
	else
		# --- resolv.conf -----------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		if [ -h "${_FILE_PATH}" ]; then
			printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
			return
		fi

		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			# Generated by user script
			search ${NICS_WGRP}
			nameserver ${IPV6_LHST}
			nameserver ${IPV4_LHST}
			nameserver ${NICS_DNS4}
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
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

	# --- default.conf --------------------------------------------------------
	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
	funcFile_backup "${_FILE_PATH}"
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		# --- log ---------------------------------------------------------------------
		#log-queries												# dns query log output
		#log-dhcp													# dhcp transaction log output
		#log-facility=												# log output file name
		
		# --- dns ---------------------------------------------------------------------
		#port=5353													# listening port
		bogus-priv													# do not perform reverse lookup of private ip address on upstream server
		domain-needed												# do not forward plain names
		domain=${NICS_WGRP}											# local domain name
		expand-hosts												# add domain name to host
		filterwin2k													# filter for windows
		interface=lo,${NICS_NAME}											# listen to interface
		listen-address=${IPV6_LHST},${IPV4_LHST},${NICS_IPV4}					# listen to ip address
		#server=8.8.8.8												# directly specify upstream server
		#server=8.8.4.4												# directly specify upstream server
		#no-hosts													# don't read the hostnames in /etc/hosts
		#no-poll													# don't poll /etc/resolv.conf for changes
		#no-resolv													# don't read /etc/resolv.conf
		strict-order												# try in the registration order of /etc/resolv.conf
		bind-dynamic												# enable bind-interfaces and the default hybrid network mode
		
		# --- dhcp --------------------------------------------------------------------
		dhcp-range=${NICS_IPV4%.*}.0,proxy,24								# proxy dhcp
		#dhcp-range=${NICS_IPV4%.*}.64,${NICS_IPV4%.*}.79,12h					# dhcp range
		#dhcp-option=option:netmask,255.255.255.0					#  1 netmask
		dhcp-option=option:router,${NICS_GATE}						#  3 router
		dhcp-option=option:dns-server,${NICS_IPV4},${NICS_GATE}		#  6 dns-server
		dhcp-option=option:domain-name,${NICS_WGRP}					# 15 domain-name
		#dhcp-option=option:28,${NICS_IPV4%.*}.255						# 28 broadcast
		#dhcp-option=option:ntp-server,${NTPS_IPV4}				# 42 ntp-server
		#dhcp-option=option:tftp-server,${NICS_IPV4}					# 66 tftp-server
		#dhcp-option=option:bootfile-name,							# 67 bootfile-name
		dhcp-no-override											# disable re-use of the dhcp servername and filename fields as extra option space
		
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		# --- tftp --------------------------------------------------------------------
		#enable-tftp=${NICS_NAME}                                         # enable tftp server
		#tftp-root=/var/lib/tftpboot                                # tftp root directory
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

	# --- dns.conf ------------------------------------------------------------
	if command -v nmcli > /dev/null 2>&1; then
		_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[main]
			dns=dnsmasq
_EOT_

		# --- debug out -------------------------------------------------------
		funcDebugout_file "${_FILE_PATH}"
	fi

	# --- systemctl -----------------------------------------------------------
	_SRVC_NAME="dnsmasq.service"
	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
	if [ "${_SRVC_STAT}" = "enabled" ]; then
		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		systemctl daemon-reload
		systemctl restart "${_SRVC_NAME}"
	fi

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
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- .bash_history -------------------------------------------------------
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bash_history"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- .vimrc --------------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "vim")"
	if [ -z "${_WORK_TEXT}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.vimrc"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
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
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- .curlrc -------------------------------------------------------------
	_WORK_TEXT="$(funcInstallPackage "curl")"
	if [ -z "${_WORK_TEXT}" ]; then
		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.curlrc"
		funcFile_backup "${_FILE_PATH}"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
	fi

	# --- debug out -----------------------------------------------------------
	funcDebugout_file "${_FILE_PATH}"

	# --- distribute to existing users ----------------------------------------
	for _DIRS_USER in "${DIRS_TGET:-}"/root \
	                  "${DIRS_TGET:-}"/home/*
	do
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

# --- main --------------------------------------------------------------------
funcMain() {
	_FUNC_NAME="funcMain"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${_FUNC_NAME}] ---"

	# --- initialize ----------------------------------------------------------
	funcInitialize						# initialize

	# --- debug out -----------------------------------------------------------
	funcDebugout_parameter

	# --- network manager -----------------------------------------------------
	funcSetupNetwork_connman			# network setup connman
	funcSetupNetwork_netplan			# network setup netplan
	funcSetupNetwork_nmanagr			# network setup network manager

	# --- network settings ----------------------------------------------------
	funcSetupNetwork_hostname			# network setup hostname
	funcSetupNetwork_hosts				# network setup hosts
	funcSetupNetwork_firewalld			# network setup firewalld
	funcSetupNetwork_resolv				# network setup resolv.conf
	funcSetupNetwork_dnsmasq			# network setup dnsmasq

	# --- skeleton settings ---------------------------------------------------
	funcSetupConfig_skel

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
