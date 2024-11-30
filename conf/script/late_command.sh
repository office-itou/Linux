#!/bin/sh

### initialization ############################################################
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

	trap 'exit 1' 1 2 3 15
	export LANG=C

	#--------------------------------------------------------------------------
	readonly PROG_PATH="$0"
	readonly PROG_PRAM="$*"
	readonly PROG_NAME="${0##*/}"
	readonly PROG_DIRS="${0%/*}"
	readonly TGET_DIRS="/target"
	readonly ORIG_DIRS="${PROG_DIRS}/orig"
	readonly CRNT_DIRS="${PROG_DIRS}/crnt"
#	readonly LOGS_NAME="${PROG_DIRS}/${PROG_NAME%.*}.log"
	readonly COMD_PARM="${PROG_DIRS}/${PROG_NAME%.*}.prm";
	DIST_NAME="$(uname -v | sed -ne 's/.*\(debian\|ubuntu\).*/\1/ip' | tr '[:upper:]' '[:lower:]')"
	readonly DIST_NAME
	if [ -e "${COMD_PARM}" ]; then
		COMD_LINE="$(cat "${COMD_PARM}")"
	else
		COMD_LINE="$(cat /proc/cmdline)"
	fi
	readonly COMD_LINE
	SEED_FILE=""
	for LINE in ${COMD_LINE};
	do
		case "${LINE}" in
			iso-url=*.iso  | url=*.iso )                                     ;;
			preseed/file=* | file=*    ) SEED_FILE="${PROG_DIRS}/preseed.cfg";;
			preseed/url=*  | url=*     ) SEED_FILE="${PROG_DIRS}/preseed.cfg";;
			ds=nocloud*                ) SEED_FILE="${PROG_DIRS}/user-data"  ;;
			*                          )                                     ;;
		esac
	done
	readonly SEED_FILE

	#--------------------------------------------------------------------------
	echo "${PROG_NAME}: === Start ==="
	echo "${PROG_NAME}: PROG_PATH=${PROG_PATH}"
	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
	echo "${PROG_NAME}: PROG_DIRS=${PROG_DIRS}"
	echo "${PROG_NAME}: SEED_FILE=${SEED_FILE}"
	echo "${PROG_NAME}: TGET_DIRS=${TGET_DIRS}"
	echo "${PROG_NAME}: ORIG_DIRS=${ORIG_DIRS}"
	echo "${PROG_NAME}: CRNT_DIRS=${CRNT_DIRS}"
	echo "${PROG_NAME}: COMD_PARM=${COMD_PARM}"
	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
	echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"

	#--- parameter  -----------------------------------------------------------
	NTP_ADDR="ntp.nict.jp"
	IP6_LHST="::1"
	IP4_LHST="127.0.0.1"
	IP4_DUMY="127.0.1.1"
	OLD_FQDN="$(cat /etc/hostname)"
	OLD_HOST="${OLD_FQDN%.*}"
	OLD_WGRP="${OLD_FQDN#*.}"
	NIC_BIT4=""
	NIC_MADR=""
	NMN_FLAG=""					# nm_config, ifupdown, loopback
	FIX_IPV4=""
	NIC_IPV4=""
	NIC_GATE=""
	NIC_MASK=""
	NIC_FQDN=""
	NIC_NAME=""
	NIC_DNS4=""
	NIC_HOST=""
	NIC_WGRP=""

### common ####################################################################

# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)

# --- ipv4 netmask conversion -------------------------------------------------
funcIPv4GetNetmask() {
	INP_ADDR="$1"
	LOOP=$((32-INP_ADDR))
	WORK=1
	DEC_ADDR=""
	while [ "${LOOP}" -gt 0 ]
	do
		LOOP=$((LOOP-1))
		WORK=$((WORK*2))
	done
	DEC_ADDR="$((0xFFFFFFFF ^ (WORK-1)))"
	printf '%d.%d.%d.%d'             \
	    $(( DEC_ADDR >> 24        )) \
	    $(((DEC_ADDR >> 16) & 0xFF)) \
	    $(((DEC_ADDR >>  8) & 0xFF)) \
	    $(( DEC_ADDR        & 0xFF))
}

# --- IPv4 cidr conversion ----------------------------------------------------
funcIPv4GetNetCIDR() {
#	INP_ADDR="$1"
#	echo "${INP_ADDR}" | \
#	    awk -F '.' '{
#	        split($0, OCTETS)
#	        for (I in OCTETS) {
#	            MASK += 8 - log(2^8 - OCTETS[I])/log(2)
#	        }
#	        print MASK
#	    }'
	INP_ADDR="$1"

	OLD_IFS=${IFS}
	IFS='.'
	set -f
	# shellcheck disable=SC2086
	set -- ${INP_ADDR}
	set +f
	OCTETS1="${1}"
	OCTETS2="${2}"
	OCTETS3="${3}"
	OCTETS4="${4}"
	IFS=${OLD_IFS}

	MASK=0
	for OCTETS in "${OCTETS1}" "${OCTETS2}" "${OCTETS3}" "${OCTETS4}"
	do
		case "${OCTETS}" in
			  0) MASK=$((MASK+0));;
			128) MASK=$((MASK+1));;
			192) MASK=$((MASK+2));;
			224) MASK=$((MASK+3));;
			240) MASK=$((MASK+4));;
			248) MASK=$((MASK+5));;
			252) MASK=$((MASK+6));;
			254) MASK=$((MASK+7));;
			255) MASK=$((MASK+8));;
			*  )                 ;;
		esac
	done
	printf '%d' "${MASK}"
}

# --- service status ----------------------------------------------------------
funcServiceStatus() {
	SRVC_STAT="undefined"
	case "$1" in
		is-enabled )
			SRVC_STAT="$(systemctl is-enabled "$2" 2> /dev/null || true)"
			if [ -z "${SRVC_STAT}" ]; then
				SRVC_STAT="not-found"
			fi
			case "${SRVC_STAT}" in
				disabled        ) SRVC_STAT="disabled";;
				enabled         | \
				enabled-runtime ) SRVC_STAT="enabled";;
				linked          | \
				linked-runtime  ) SRVC_STAT="linked";;
				masked          | \
				masked-runtime  ) SRVC_STAT="masked";;
				alias           ) ;;
				static          ) ;;
				indirect        ) ;;
				generated       ) ;;
				transient       ) ;;
				bad             ) ;;
				not-found       ) ;;
				*               ) ;;
			esac
			;;
		is-active  )
			SRVC_STAT="$(systemctl is-active "$2" 2> /dev/null || true)"
			if [ -z "${SRVC_STAT}" ]; then
				SRVC_STAT="not-found"
			fi
			;;
		*          ) ;;
	esac
	echo "${SRVC_STAT}"
}

### subroutine ################################################################
# --- blacklist ---------------------------------------------------------------
# run on target
funcSetupBlacklist() {
	FUNC_NAME="funcSetupBlacklist"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# -------------------------------------------------------------------------
	FILE_DIRS="/etc/modprobe.d"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
	fi
	if [ ! -d "${FILE_DIRS}/." ]; then
		echo "${PROG_NAME}: mkdir ${FILE_DIRS}"
		mkdir -p "${FILE_DIRS}"
	fi
	FILE_NAME="${FILE_DIRS}/blacklist-floppy.conf"
	# shellcheck disable=SC2312
	if [ -n "$(lsmod | sed -ne '/floppy/p')" ]; then
#		echo "${PROG_NAME}: rmmod floppy"
#		rmmod floppy || true
		echo "${PROG_NAME}: create file ${FILE_DIRS}"
		echo 'blacklist floppy' > "${FILE_NAME}"
		#--- debug print ------------------------------------------------------
		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		cat "${FILE_NAME}"
		# shellcheck disable=SC2312
		if [ -n "$(command -v dpkg-reconfigure 2> /dev/null)" ]; then
			dpkg-reconfigure initramfs-tools
		fi
	fi
}

# --- packages ----------------------------------------------------------------
# run on target
funcInstallPackages() {
	FUNC_NAME="funcInstallPackages"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--------------------------------------------------------------------------
	FILE_DIRS="/etc/apt"
	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -d "${FILE_DIRS}/." ]; then
		echo "${PROG_NAME}: directory does not exist ${FILE_DIRS}"
		return
	fi
	# --- backup --------------------------------------------------------------
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
	find "${FILE_DIRS}" -name '*.list' -type f | \
	while read -r FILE_NAME
	do
		echo "${PROG_NAME}: ${FILE_NAME} moved"
		cp -a "${FILE_NAME}" "${BACK_DIRS}"
	done
	FILE_NAME="${FILE_DIRS}/sources.list"
	sed -i "${FILE_NAME}"                     \
	    -e '/^[ \t]*deb[ \t]\+cdrom/ s/^/#/g'
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	#--------------------------------------------------------------------------
	if [ ! -e "${SEED_FILE}" ]; then
		echo "${PROG_NAME}: file does not exist ${SEED_FILE}"
		return
	fi
	#--------------------------------------------------------------------------
	LIST_TASK="$(sed -ne '/^[ \t]*tasksel[ \t]\+tasksel\/first[ \t]\+/,/[^\\]$/p' "${SEED_FILE}" | \
	             sed -e  '/^[ \t]*tasksel[ \t]\+/d'                                                \
	                 -e  's/\\//g'                                                               | \
	             sed -e  's/\r\n*/\n/g'                                                            \
	                 -e  ':l; N; s/\n/ /; b l;'                                                  | \
	             sed -e  's/[ \t]\+/ /g')"
	LIST_PACK="$(sed -ne '/^[ \t]*d-i[ \t]\+pkgsel\/include[ \t]\+/,/[^\\]$/p'    "${SEED_FILE}" | \
	             sed -e  '/^[ \t]*d-i[ \t]\+/d'                                                    \
	                 -e  's/\\//g'                                                               | \
	             sed -e  's/\r\n*/\n/g'                                                            \
	                 -e  ':l; N; s/\n/ /; b l;'                                                  | \
	             sed -e  's/[ \t]\+/ /g')"
	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK:-}"
	echo "${PROG_NAME}: LIST_PACK=${LIST_PACK:-}"
	#--------------------------------------------------------------------------
	LIST_DPKG=""
	if [ -n "${LIST_PACK:-}" ]; then
		# shellcheck disable=SC2086
		LIST_DPKG="$(dpkg-query --show --showformat='${Status} ${Package}\n' ${LIST_PACK:-} 2>&1 | \
		             sed -ne '/install ok installed:/! s/^.*[ \t]\([[:graph:]]\)/\1/gp'          | \
		             sed -e  's/\r\n*/\n/g'                                                        \
		                 -e  ':l; N; s/\n/ /; b l;'                                              | \
		             sed -e  's/[ \t]\+/ /g')"
	fi
	#--------------------------------------------------------------------------
	echo "${PROG_NAME}: Run the installation"
	echo "${PROG_NAME}: LIST_DPKG=${LIST_DPKG:-}"
	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK:-}"
	#--------------------------------------------------------------------------
	apt-get -qq    update
	apt-get -qq -y upgrade
	apt-get -qq -y dist-upgrade
	if [ -n "${LIST_DPKG:-}" ]; then
		# shellcheck disable=SC2086
		apt-get -qq -y install ${LIST_DPKG}
	fi
	# shellcheck disable=SC2312
	if [ -n "${LIST_TASK:-}" ] && [ -n "$(command -v tasksel 2> /dev/null)" ]; then
		# shellcheck disable=SC2086
		tasksel install ${LIST_TASK}
	fi
	echo "${PROG_NAME}: Installation completed"
}

# --- network get parameter ---------------------------------------------------
# run on target
funcGetNetwork_parameter_sub() {
	LIST="${1}"
	for LINE in ${LIST}
	do
		case "${LINE}" in
			netcfg/target_network_config=* ) NMN_FLAG="${LINE#netcfg/target_network_config=}";;
			netcfg/choose_interface=*      ) NIC_NAME="${LINE#netcfg/choose_interface=}"     ;;
			netcfg/disable_dhcp=*          ) FIX_IPV4="${LINE#netcfg/disable_dhcp=}"         ;;
			netcfg/disable_autoconfig=*    ) FIX_IPV4="${LINE#netcfg/disable_autoconfig=}"   ;;
			netcfg/get_ipaddress=*         ) NIC_IPV4="${LINE#netcfg/get_ipaddress=}"        ;;
			netcfg/get_netmask=*           ) NIC_MASK="${LINE#netcfg/get_netmask=}"          ;;
			netcfg/get_gateway=*           ) NIC_GATE="${LINE#netcfg/get_gateway=}"          ;;
			netcfg/get_nameservers=*       ) NIC_DNS4="${LINE#netcfg/get_nameservers=}"      ;;
			netcfg/get_hostname=*          ) NIC_FQDN="${LINE#netcfg/get_hostname=}"         ;;
			netcfg/get_domain=*            ) NIC_WGRP="${LINE#netcfg/get_domain=}"           ;;
			interface=*                    ) NIC_NAME="${LINE#interface=}"                   ;;
			hostname=*                     ) NIC_FQDN="${LINE#hostname=}"                    ;;
			domain=*                       ) NIC_WGRP="${LINE#domain=}"                      ;;
			ip=dhcp | ip4=dhcp | ipv4=dhcp ) FIX_IPV4="false"; break                         ;;
			ip=* | ip4=* | ipv4=*          ) FIX_IPV4="true"
			                                 OLD_IFS=${IFS}
			                                 IFS=':,'
			                                 set -f
			                                 # shellcheck disable=SC2086
			                                 set -- ${LINE#ip*=}
			                                 set +f
			                                 NIC_IPV4="${1}"
			                                 NIC_GATE="${3}"
			                                 NIC_MASK="${4}"
			                                 NIC_FQDN="${5}"
			                                 NIC_NAME="${6}"
			                                 NIC_DNS4="${8}"
			                                 IFS=${OLD_IFS}
			                                 ;;
			*)  ;;
		esac
	done
}

# --- network get parameter ---------------------------------------------------
# run on target
funcGetNetwork_parameter() {
	FUNC_NAME="funcGetNetwork_parameter"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--- nic parameter --------------------------------------------------------
	IP4_INFO="$(ip -4 -oneline address show primary | sed -ne '/^2:[ \t]\+/p')"
	LNK_INFO="$(ip -4 -oneline link show | sed -ne '/^2:[ \t]\+/p')"
	NIC_NAME="$(echo "${IP4_INFO}" | sed -ne 's/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\)[ \t]\+inet.*$/\1/p')"
	NIC_MADR="$(echo "${LNK_INFO}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
	NIC_IPV4="$(echo "${IP4_INFO}" | sed -ne 's%^.*inet[ \t]\+\([0-9.]\+\)/*\([0-9]*\)[ \t]\+.*$%\1%p')"
	NIC_BIT4="$(echo "${IP4_INFO}" | sed -ne 's%^.*inet[ \t]\+\([0-9.]\+\)/*\([0-9]*\)[ \t]\+.*$%\2%p')"
	NIC_BIT4="$([ -n "${NIC_BIT4}" ] && echo "${NIC_BIT4}" || echo 0)"
	NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
	FIX_IPV4="$([ -n "${NIC_BIT4}" ] && echo "true" || echo "false")"
	NIC_DNS4="$(sed -ne '/nameserver/ s/^.*[ \t]\+\([0-9.:]\+\)[ \t]*/\1/p' /etc/resolv.conf | head -n 1)"
	NIC_GATE="$(ip -4 -oneline route list dev "${NIC_NAME}" default | sed -ne 's/^.*via[ \t]\+\([0-9.]\+\)[ \t]\+.*/\1/p')"
	NIC_FQDN="$(hostname -f)"
	NIC_HOST="${NIC_FQDN%.*}"
	NIC_WGRP="${NIC_FQDN##*.}"
	NMN_FLAG=""
	#--- preseed parameter ----------------------------------------------------
	if [ -e "${SEED_FILE}" ]; then
		# shellcheck disable=SC2312
		funcGetNetwork_parameter_sub "$(cat "${SEED_FILE}")"
		if [ -n "${NIC_WGRP}" ]; then
			NIC_FQDN="${NIC_HOST}.${NIC_WGRP}"
		fi
	fi
	#--- /proc/cmdline parameter ----------------------------------------------
	funcGetNetwork_parameter_sub "${COMD_LINE}"
	#--- hostname -------------------------------------------------------------
	if [ -z "${NIC_HOST}" ] && [ -n "${NIC_FQDN%.*}" ]; then
		NIC_HOST="${NIC_FQDN%.*}"
	fi
	if [ -z "${NIC_WGRP}" ] && [ -n "${NIC_FQDN##*.}" ]; then
		NIC_WGRP="${NIC_FQDN##*.}"
	fi
	if [ -z "${NIC_WGRP}" ]; then
		NIC_WGRP="$(sed -ne 's/^search[ \t]\+\([[:alnum:]]\+\)[ \t]*/\1/p' /etc/resolv.conf)"
	fi
	#--- network parameter ----------------------------------------------------
	if [ -n "${NIC_IPV4#*/}" ] && [ "${NIC_IPV4#*/}" != "${NIC_IPV4}" ]; then
		FIX_IPV4="true"
		NIC_BIT4="${NIC_IPV4#*/}"
		NIC_IPV4="${NIC_IPV4%/*}"
		NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
	else
		NIC_BIT4="$(funcIPv4GetNetCIDR "${NIC_MASK}")"
	fi
#	#--- nic parameter --------------------------------------------------------
#	if [ -z "${NIC_NAME}" ] || [ "${NIC_NAME}" = "auto" ]; then
#		IP4_INFO="$(ip -4 -oneline address show primary | sed -ne '/^2:[ \t]\+/p')"
#		NIC_NAME="$(echo "${IP4_INFO}" | sed -ne 's/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\)[ \t]\+inet.*$/\1/p')"
#	fi
#	IP4_INFO="$(ip -4 -oneline link show "${NIC_NAME}" 2> /dev/null)"
#	NIC_MADR="$(echo "${IP4_INFO}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
#	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
	echo "${PROG_NAME}: CON_MADR=${CON_MADR}"
	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
	echo "${PROG_NAME}: NIC_FQDN=${NIC_FQDN}"
	echo "${PROG_NAME}: NIC_HOST=${NIC_HOST}"
	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
	echo "${PROG_NAME}: IP6_LHST=${IP6_LHST}"
	echo "${PROG_NAME}: IP4_LHST=${IP4_LHST}"
	echo "${PROG_NAME}: IP4_DUMY=${IP4_DUMY}"
	echo "${PROG_NAME}: NTP_ADDR=${NTP_ADDR}"
	echo "${PROG_NAME}: OLD_FQDN=${OLD_FQDN}"
	echo "${PROG_NAME}: OLD_HOST=${OLD_HOST}"
	echo "${PROG_NAME}: OLD_WGRP=${OLD_WGRP}"
	echo "${PROG_NAME}: NMN_FLAG=${NMN_FLAG}"
}

# --- network setup hostname --------------------------------------------------
# run on target
funcSetupNetwork_hostname() {
	FUNC_NAME="funcSetupNetwork_hostname"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- hostname ------------------------------------------------------------
	FILE_NAME="/etc/hostname"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
	cp -a "${FILE_NAME}" "${BACK_DIRS}"
	echo "${NIC_FQDN}" > "${FILE_NAME}"
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
}

# --- network setup hosts -----------------------------------------------------
# run on target
funcSetupNetwork_hosts() {
	FUNC_NAME="funcSetupNetwork_hosts"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- hosts ---------------------------------------------------------------
	FILE_NAME="/etc/hosts"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
	cp -a "${FILE_NAME}" "${BACK_DIRS}"
	sed -i "${FILE_NAME}"                                          \
	    -e "/^${IP4_DUMY}/d"                                       \
	    -e "/^${NIC_IPV4}/d"                                       \
	    -e 's/^\([0-9.]\+\)[ \t]\+/\1\t/g'                         \
	    -e 's/^\([0-9a-zA-Z:]\+\)[ \t]\+/\1\t\t/g'                 \
	    -e "/^${IP4_LHST}/a ${NIC_IPV4}\t${NIC_FQDN} ${NIC_HOST}"  \
	    -e "s/${OLD_HOST}/${NIC_HOST}/g"                           \
	    -e "s/${OLD_FQDN}/${NIC_FQDN}/g"
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
}

# --- network setup firewalld -------------------------------------------------
# run on target
funcSetupNetwork_firewalld() {
	FUNC_NAME="funcSetupNetwork_firewalld"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- firewalld -----------------------------------------------------------
	SRVC_NAME="firewalld.service"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	FILE_NAME="/etc/firewalld/firewalld.conf"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	ULIB_NAME="/usr/lib/firewalld/zones/home.xml"
	FILE_NAME="/etc/firewalld/zones/home.xml"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		ULIB_NAME="${TGET_DIRS}${ULIB_NAME}"
	fi
	echo "${PROG_NAME}: ${FILE_NAME}"
	sed -e '/<\/zone>/i \  <interface name="'"${NIC_NAME}"'"\/>' \
	    "${ULIB_NAME}"                                           \
	>   "${FILE_NAME}"
	# shellcheck disable=SC2312
	if [ -z "$(sed -ne '/^[ \t]*<service name="samba"\/>[ \t]*$/p' "${FILE_NAME}")" ]; then
		sed -i "${FILE_NAME}"                                \
		    -e '/samba-client/i \  <service name="samba"\/>'
	fi
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	#--- systemctl ------------------------------------------------------------
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		systemctl restart "${SRVC_NAME}"
	fi
	echo "${PROG_NAME}: ${SRVC_NAME} completed"
}

# --- network setup avahi -----------------------------------------------------
# run on target
funcSetupNetwork_avahi() {
	FUNC_NAME="funcSetupNetwork_avahi"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- avahi ---------------------------------------------------------------
	SRVC_NAME="avahi-daemon.service"
	SOCK_NAME="avahi-daemon.socket"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	# --- systemctl -----------------------------------------------------------
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	for SYSD_NAME in "${SRVC_NAME}" "${SOCK_NAME}"
	do
		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SYSD_NAME}")"
		if [ "${SYSD_STAT}" != "enabled" ]; then
			continue
		fi
		echo "${PROG_NAME}: ${SRVC_NAME} stop"
		systemctl stop "${SYSD_NAME}"
		echo "${PROG_NAME}: ${SRVC_NAME} masked"
		systemctl mask "${SYSD_NAME}"
#		echo "${PROG_NAME}: ${SRVC_NAME} disabled"
#		systemctl disable --now "${SYSD_NAME}"
	done
	echo "${PROG_NAME}: ${SRVC_NAME} completed"
}

# --- network setup resolv.conf -----------------------------------------------
# run on target
funcSetupNetwork_resolv() {
	FUNC_NAME="funcSetupNetwork_resolv"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--- systemd-resolved -----------------------------------------------------
	SRVC_NAME="systemd-resolved.service"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	# --- systemctl -----------------------------------------------------------
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NAME} stop"
		systemctl stop "${SRVC_NAME}"
		echo "${PROG_NAME}: ${SRVC_NAME} masked"
		systemctl mask "${SRVC_NAME}"
#		echo "${PROG_NAME}: ${SRVC_NAME} disabled"
#		systemctl disable --now "${SRVC_NAME}"
	fi
	# --- resolv.conf ---------------------------------------------------------
	FILE_NAME="/etc/resolv.conf"
	CLUD_DIRS="/etc/cloud/cloud.cfg.d"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		CLUD_DIRS="${TGET_DIRS}${CLUD_DIRS}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	# --- backup --------------------------------------------------------------
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ -e "${FILE_NAME}" ]; then
		if [ ! -d "${BACK_DIRS}/." ]; then
			mkdir -p "${BACK_DIRS}"
		fi
		cp -a "${FILE_NAME}" "${BACK_DIRS}"
	fi
	# --- create file ---------------------------------------------------------
	CONF_FILE="${FILE_NAME}.manually-configured"
	# shellcheck disable=SC2312
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CONF_FILE}"
		# Generated by user script
		search ${NIC_WGRP}
		nameserver ${IP6_LHST}
		nameserver ${IP4_LHST}
		nameserver ${NIC_DNS4}
_EOT_
	rm -f "${FILE_NAME}"
	cp -a "${CONF_FILE}" "${FILE_NAME}"
#	ln -s "${CONF_FILE}" "${FILE_NAME}"
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ls -l ${CONF_FILE} ${FILE_NAME} ---"
	ls -l "${CONF_FILE}" "${FILE_NAME}"
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	#--- 99-disable-network-config.cfg ----------------------------------------
	if [ -d "${CLUD_DIRS}/." ] && [ -d /etc/NetworkManager/ ]; then
		CONF_FILE="${CLUD_DIRS}/99-disable-network-config.cfg"
		# shellcheck disable=SC2312
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CONF_FILE}"
			network: {config: disabled}
_EOT_
		#--- debug print ------------------------------------------------------
		echo "${PROG_NAME}: --- ${CONF_FILE} ---"
		cat "${CONF_FILE}"
	fi
	echo "${PROG_NAME}: ${FILE_NAME##*/} completed"
}

# --- network setup dnsmasq ---------------------------------------------------
# run on target
funcSetupNetwork_dnsmasq() {
	FUNC_NAME="funcSetupNetwork_dnsmasq"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- dnsmasq -------------------------------------------------------------
	SRVC_NAME="dnsmasq.service"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	# --- backup --------------------------------------------------------------
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
	cp -a "${FILE_NAME}" "${BACK_DIRS}"
	# --- dnsmasq.service -----------------------------------------------------
	sed -i "${FILE_NAME}"                           \
	    -e '/\[Unit\]/,/\[.\+\]/                 {' \
	    -e '/^Requires=/                         {' \
	    -e 's/^/#/g'                                \
	    -e 'a Requires=network-online.target'       \
	    -e '                                     }' \
	    -e '/^After=/                            {' \
	    -e 's/^/#/g'                                \
	    -e 'a After=network-online.target'          \
	    -e '                                     }' \
	    -e '                                     }' \
	    -e '/^ExecStartPost=.*-resolvconf$/ s/^/#/' \
	    -e '/^ExecStop=.*-resolvconf$/      s/^/#/'
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	#--- none-dns.conf --------------------------------------------------------
	FILE_DIRS="/etc/NetworkManager/conf.d"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
	fi
	if [ -d "${FILE_DIRS}/." ]; then
		FILE_NAME="${FILE_DIRS}/none-dns.conf"
		echo "${PROG_NAME}: ${FILE_NAME}"
		cat <<- _EOT_ > "${FILE_NAME}"
			[main]
			systemd-resolved=false
			dns=none
_EOT_
		#--- debug print ------------------------------------------------------
		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		cat "${FILE_NAME}"
	fi
	echo "${PROG_NAME}: ${FILE_NAME##*/} completed"
}

# --- network setup samba -----------------------------------------------------
# run on target
funcSetupNetwork_samba() {
	FUNC_NAME="funcSetupNetwork_samba"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# --- smb.conf ------------------------------------------------------------
	FILE_NAME="/etc/samba/smb.conf"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
	cp -a "${FILE_NAME}" "${BACK_DIRS}"
	sed -i "${FILE_NAME}"                                                   \
	    -e "/^[;#]*[ \t]*interfaces[ \t]*=/a \    interfaces = ${NIC_NAME}"
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	#--- systemctl ------------------------------------------------------------
	if [ -e /lib/systemd/system/smbd.service ]; then
		SRVC_SMBD="smbd.service"
		SRVC_NMBD="nmbd.service"
	else
		SRVC_SMBD="smb.service"
		SRVC_NMBD="nmb.service"
	fi
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_SMBD}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_SMBD} restarted"
		systemctl restart "${SRVC_SMBD}"
	fi
	echo "${PROG_NAME}: ${SRVC_NMBD} completed"
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NMBD}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NMBD} restarted"
		systemctl restart "${SRVC_NMBD}"
	fi
	echo "${PROG_NAME}: ${SRVC_NMBD} completed"
}

# --- network setup connman ---------------------------------------------------
# run on target
funcSetupNetwork_connman() {
	FUNC_NAME="funcSetupNetwork_connman"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--- exit for DHCP --------------------------------------------------------
	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		return
	fi
	# --- connman -------------------------------------------------------------
	SRVC_NAME="connman.service"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	# --- disable_dns_proxy.conf ----------------------------------------------
	FILE_DIRS="/etc/systemd/system/connman.service.d"
	FILE_NAME="${FILE_DIRS}/disable_dns_proxy.conf"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	# --- backup --------------------------------------------------------------
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ -e "${FILE_NAME}" ]; then
		if [ ! -d "${BACK_DIRS}/." ]; then
			mkdir -p "${BACK_DIRS}"
		fi
		cp -a "${FILE_NAME}" "${BACK_DIRS}"
	fi
	# --- create file ---------------------------------------------------------
	mkdir -p "${FILE_DIRS}"
	# shellcheck disable=SC2312
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
		[Service]
		ExecStart=
		ExecStart=$(command -v connmand 2> /dev/null) -n --nodnsproxy
_EOT_
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	# --- settings ------------------------------------------------------------
	FILE_DIRS="/var/lib/connman"
	FILE_NAME="${FILE_DIRS}/settings"
	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_DIRS="${TGET_DIRS}/var/lib/connman"
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	# --- backup --------------------------------------------------------------
	echo "${PROG_NAME}: ${FILE_NAME}"
	if [ -e "${FILE_NAME}" ]; then
		if [ ! -d "${BACK_DIRS}/." ]; then
			mkdir -p "${BACK_DIRS}"
		fi
		cp -a "${FILE_NAME}" "${BACK_DIRS}"
	fi
	# --- create file ---------------------------------------------------------
	mkdir -p "${FILE_NAME%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
		[global]
		OfflineMode=false
		
		[Wired]
		Enable=true
		Tethering=false
_EOT_
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	# --- create file ---------------------------------------------------------
	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
	do
		MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		CON_ADDR="$(echo "${MAC_ADDR}" | sed -ne 's/://gp')"
		CON_NAME="ethernet_${CON_ADDR}_cable"
		CON_DIRS="${FILE_DIRS}/${CON_NAME}"
		CON_FILE="${CON_DIRS}/settings"
		mkdir -p "${CON_DIRS}"
		chmod 700 "${CON_DIRS}"
		if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CON_FILE}"
				[${CON_NAME}]
				Name=Wired
				AutoConnect=true
				Modified=
				IPv4.method=manual
				IPv4.netmask_prefixlen=${NIC_BIT4}
				IPv4.local_address=${NIC_IPV4}
				IPv4.gateway=${NIC_GATE}
				IPv6.method=auto
				IPv6.privacy=preferred
				Nameservers=${IP6_LHST};${IP4_LHST};${NIC_DNS4};
				Timeservers=${NTP_ADDR};
				Domains=${NIC_WGRP};
				mDNS=false
				IPv6.DHCP.DUID=
_EOT_
		else
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CON_FILE}"
				[${CON_NAME}]
				Name=Wired
				AutoConnect=false
				Modified=
				IPv4.method=dhcp
				IPv4.DHCP.LastAddress=
				IPv6.method=auto
				IPv6.privacy=preferred
_EOT_
		fi
		chmod 600 "${CON_FILE}"
		#--- debug print ------------------------------------------------------
		echo "${PROG_NAME}: --- ${CON_FILE} ---"
		cat "${CON_FILE}"
	done
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_DIRS} ---"
	ls -lR "${FILE_DIRS}"
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	#--- systemctl ------------------------------------------------------------
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		systemctl restart "${SRVC_NAME}"
	fi
	echo "${PROG_NAME}: ${SRVC_NAME} completed"
}

# --- network setup netplan ---------------------------------------------------
# run on target
funcSetupNetwork_netplan() {
	FUNC_NAME="funcSetupNetwork_netplan"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--- exit for DHCP --------------------------------------------------------
	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		return
	fi
	# --- netplan -------------------------------------------------------------
	FILE_DIRS="/etc/netplan"
	CLUD_DIRS="/etc/cloud/cloud.cfg.d"
	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		CLUD_DIRS="${TGET_DIRS}${CLUD_DIRS}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -d "${FILE_DIRS}/." ]; then
		echo "${PROG_NAME}: directory does not exist ${FILE_DIRS}"
		return
	fi
	# --- backup --------------------------------------------------------------
	if [ ! -d "${BACK_DIRS}/." ]; then
		mkdir -p "${BACK_DIRS}"
	fi
#	for FILE_NAME in "${FILE_DIRS}"/*.yaml
#	do
#		if [ ! -e "${FILE_NAME}" ]; then
#			continue
#		fi
#		echo "${PROG_NAME}: ${FILE_NAME} moved"
#		mv "${FILE_NAME}" "${BACK_DIRS}"
#	done
	find "${FILE_DIRS}" -name '*.yaml' -type f | \
	while read -r FILE_NAME
	do
		echo "${PROG_NAME}: ${FILE_NAME} moved"
		mv "${FILE_NAME}" "${BACK_DIRS}"
	done
	# --- create --------------------------------------------------------------
	NMAN_DIRS="/etc/NetworkManager"
	if [ -d "${TGET_DIRS}/." ]; then
		NMAN_DIRS="${TGET_DIRS}${NMAN_DIRS}"
	fi
	if [ -d "${NMAN_DIRS}/." ]; then
		if [ -d "${CLUD_DIRS}/." ]; then
			FILE_NAME="${CLUD_DIRS}/99-disable-network-config.cfg"
			cat <<- _EOT_ > "${FILE_NAME}"
				network: {config: disabled}
_EOT_
			#--- debug print --------------------------------------------------
			echo "${PROG_NAME}: --- ${FILE_NAME} ---"
			cat "${FILE_NAME}"
		fi
		# --- 99-network-manager-all.yaml -------------------------------------
		FILE_NAME="${FILE_DIRS}/99-network-manager-all.yaml"
		cat <<- _EOT_ > "${FILE_NAME}"
			network:
			  version: 2
			  renderer: NetworkManager
_EOT_
		chmod 600 "${FILE_NAME}"
		# --- reload netplan --------------------------------------------------
#		echo "${PROG_NAME}: netplan apply"
#		netplan apply
		return
	fi
	# --- 99-network-config-all.yaml ------------------------------------------
	echo "${PROG_NAME}: directory does not exist ${NMAN_DIRS}"
	FILE_NAME="${FILE_DIRS}/99-network-config-all.yaml"
	cat <<- _EOT_ > "${FILE_NAME}"
		network:
		  version: 2
		  renderer: networkd
		  ethernets:
_EOT_
	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
	do
		if [ "${NICS_NAME}" = "${NIC_NAME}" ] && [ "${FIX_IPV4}" = "true" ]; then
			cat <<- _EOT_ >> "${FILE_NAME}"
				    ${NICS_NAME}:
				      addresses:
				      - ${NIC_IPV4}/${NIC_BIT4}
				      routes:
				      - to: default
				        via: ${NIC_GATE}
				      nameservers:
				        search:
				        - ${NIC_WGRP}
				        addresses:
				        - ${IP6_LHST}
				        - ${IP4_LHST}
				        - ${NIC_DNS4}
				      dhcp4: false
				      dhcp6: true
				      ipv6-privacy: true
_EOT_
		else
			cat <<- _EOT_ >> "${FILE_NAME}"
				    ${NICS_NAME}:
				      dhcp4: false
				      dhcp6: false
				      ipv6-privacy: true
_EOT_
		fi
		chmod 600 "${FILE_NAME}"
	done
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
	cat "${FILE_NAME}"
	echo "${PROG_NAME}: netplan apply"
	netplan apply
}

# --- network setup network manager -------------------------------------------
# run on target
funcSetupNetwork_nmanagr() {
	FUNC_NAME="funcSetupNetwork_nmanagr"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	#--- exit for DHCP --------------------------------------------------------
	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		return
	fi
	# --- network manager -----------------------------------------------------
	SRVC_NAME="NetworkManager.service"
	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
	FILE_DIRS="/etc/NetworkManager"
	CONF_FILE="${FILE_DIRS}/NetworkManager.conf"
	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
	if [ -d "${TGET_DIRS}/." ]; then
		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		CONF_FILE="${TGET_DIRS}${CONF_FILE}"
		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
	fi
	if [ ! -e "${FILE_NAME}" ]; then
		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		return
	fi
	# --- backup --------------------------------------------------------------
	if [ ! -d "${BACK_DIRS}/system-connections/." ]; then
		mkdir -p "${BACK_DIRS}/system-connections"
	fi
	echo "${PROG_NAME}: ${CONF_FILE}"
	if [ -e "${CONF_FILE}" ]; then
		cp -a "${CONF_FILE}" "${BACK_DIRS}"
	fi
	find "${FILE_DIRS}/system-connections" -name '*.yaml' -type f | \
	while read -r FILE_NAME
	do
		echo "${PROG_NAME}: ${FILE_NAME} moved"
		mv "${FILE_NAME}" "${BACK_DIRS}/system-connections"
	done
	# --- change --------------------------------------------------------------
#	echo "${PROG_NAME}: change file"
#	sed -e '/^\[ifupdown\]$/,/^\[.*]$/  {' \
#	    -e '/^managed=.*$/ s/=.*$/=true/}' \
#	      "${BACK_DIRS}/${CONF_FILE##*/}"  \
#	    > "${CONF_FILE}"
	#--- debug print ----------------------------------------------------------
#	echo "${PROG_NAME}: --- ${CONF_FILE} ---"
#	cat "${CONF_FILE}"
	# --- delete --------------------------------------------------------------
	SYSD_STAT="$(funcServiceStatus "is-active" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "active" ]; then
		echo "${PROG_NAME}: delete connection"
		IFS='' nmcli connection show | while read -r LINE
		do
			if [ -z "${LINE}" ]; then
				break
			fi
			case "${LINE}" in
				"NAME "*)
					TEXT_LINE="${LINE%%UUID[ \t]*}"
					TEXT_CONT="${#TEXT_LINE}"
					;;
				*)
					CON_NAME="$(echo "${LINE}" | cut -c 1-"${TEXT_CONT}" | sed -e 's/[ \t]*$//g')"
					echo "${PROG_NAME}: ${CON_NAME}"
					nmcli connection delete "${CON_NAME}" || true
					;;
			esac
		done
	fi
	# --- create --------------------------------------------------------------
	echo "${PROG_NAME}: create file"
	I=1
	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
	do
		FILE_NAME="${FILE_DIRS}/system-connections/Wired connection ${I}"
		MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		echo "${PROG_NAME}: ${FILE_NAME}"
		if [ -e "${FILE_NAME}" ]; then
			nmcli connection delete "${FILE_NAME##*/}" || true
		fi
		if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
			cat <<- _EOT_ > "${FILE_NAME}"
				[connection]
				id=${FILE_NAME##*/}
				#uuid=
				type=802-3-ethernet
				interface-name=${NICS_NAME}
				autoconnect=true
				zone=home
				
				[802-3-ethernet]
				mac=${MAC_ADDR}
				
				[ipv4]
				method=manual
				dns=${NIC_DNS4};
				address1=${NIC_IPV4}/${NIC_BIT4},${NIC_GATE}
				dns-search=${NIC_WGRP};
				
				[ipv6]
				method=auto
				ip6-privacy=2
_EOT_
		else
			cat <<- _EOT_ > "${FILE_NAME}"
				[connection]
				id=${FILE_NAME##*/}
				#uuid=
				type=802-3-ethernet
				interface-name=${NICS_NAME}
				autoconnect=false
				#zone=home
				
				[802-3-ethernet]
				mac=${MAC_ADDR}
				
				[ipv4]
				method=auto
				
				[ipv6]
				method=auto
				ip6-privacy=2
_EOT_
		fi
		chmod 600 "${FILE_NAME}"
		if [ -d "${TGET_DIRS}/." ]; then
			cp --archive "${FILE_NAME}" "${FILE_DIRS#*/}"
		fi
		#--- debug print ------------------------------------------------------
		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		cat "${FILE_NAME}"
		I=$((I+1))
	done
	#--- systemctl ------------------------------------------------------------
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	SRVC_NWKD="systemd-networkd.service"
	SOCK_NWKD="systemd-networkd.socket"
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NWKD} ${SOCK_NWKD} stop"
		systemctl stop "${SRVC_NWKD}" "${SOCK_NWKD}"
		echo "${PROG_NAME}: ${SRVC_NWKD} ${SOCK_NWKD} mask"
		systemctl mask "${SRVC_NWKD}" "${SOCK_NWKD}"
	fi
	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
	if [ "${SYSD_STAT}" = "enabled" ]; then
		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		systemctl restart "${SRVC_NAME}"
		for NICS_NAME in lo $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		do
			echo "${PROG_NAME}: nmcli device set ${NICS_NAME} managed true"
			nmcli device set "${NICS_NAME}" managed true || true
		done
		echo "${PROG_NAME}: nmcli general reload"
		nmcli general reload
		echo "${PROG_NAME}: nmcli connection up Wired connection 1"
		nmcli connection up "Wired connection 1"
		echo "${PROG_NAME}: nmcli networking off"
		nmcli networking off
		echo "${PROG_NAME}: nmcli networking on"
		nmcli networking on
		echo "${PROG_NAME}: nmcli connection show"
		nmcli connection show
		# --- reload netplan --------------------------------------------------
		# shellcheck disable=SC2312
		if [ -n "$(command -v netplan 2> /dev/null)" ]; then
			echo "${PROG_NAME}: netplan apply"
			netplan apply
		fi
		# --- restart winbind.service -----------------------------------------
#		SRVC_WBND="winbind.service"
#		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_WBND}")"
#		if [ "${SYSD_STAT}" = "enabled" ]; then
#			echo "${PROG_NAME}: ${SRVC_WBND} restarted"
#			systemctl restart smbd.service nmbd.service winbind.service
#		fi
	fi
	echo "${PROG_NAME}: ${SRVC_NAME} completed"
}

# --- network -----------------------------------------------------------------
funcSetupNetwork_software() {
	FUNC_NAME="funcSetupNetwork_software"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# -------------------------------------------------------------------------
	funcGetNetwork_parameter
	funcSetupNetwork_hostname
	funcSetupNetwork_hosts
	funcSetupNetwork_firewalld
	funcSetupNetwork_avahi
	funcSetupNetwork_resolv
	funcSetupNetwork_dnsmasq
	funcSetupNetwork_samba
}

funcSetupNetwork_hardware() {
	FUNC_NAME="funcSetupNetwork_hardware"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# -------------------------------------------------------------------------
	funcGetNetwork_parameter
	funcSetupNetwork_connman
	funcSetupNetwork_netplan
	funcSetupNetwork_nmanagr
}

# --- service -----------------------------------------------------------------
funcSetupService() {
	FUNC_NAME="funcSetupService"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	# -------------------------------------------------------------------------
	echo "${PROG_NAME}: daemon-reload"
	systemctl daemon-reload
	OLD_IFS="${IFS}"
	for SRVC_LINE in \
		"1 systemd-resolved.service"                \
		"1 connman.service"                         \
		"1 NetworkManager.service"                  \
		"1 firewalld.service"                       \
		"- ssh.service"                             \
		"1 dnsmasq.service"                         \
		"- apache2.service"                         \
		"1 smbd.service"                            \
		"1 nmbd.service"                            \
		"1 winbind.service"
	do
		IFS=' '
		set -f
		# shellcheck disable=SC2086
		set -- ${SRVC_LINE:-}
		set +f
		IFS=${OLD_IFS}
		SRVC_FLAG="${1:-}"
		SRVC_NAME="${2:-}"
		if [ "${SRVC_FLAG}" = "-" ]; then
			continue
		fi
		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		if [ "${SYSD_STAT}" != "enabled" ]; then
			continue
		fi
		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		systemctl restart "${SRVC_NAME}"
	done
}

# --- gdm3 --------------------------------------------------------------------
#funcChange_gdm3_configure() {
#	FUNC_NAME="funcChange_gdm3_configure"
#	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
#	if [ -e "${TGET_DIRS}/etc/gdm3/custom.conf" ]; then
#		sed -i.orig "${TGET_DIRS}/etc/gdm3/custom.conf" \
#		    -e '/WaylandEnable=false/ s/^#//'
#	fi
#}

### Main ######################################################################
funcMain() {
	FUNC_NAME="funcMain"
	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
	PRAM_LIST="${PROG_PRAM}"
	OLD_IFS="${IFS}"
	IFS=' =,'
	set -f
	# shellcheck disable=SC2086
	set -- ${PRAM_LIST:-}
	set +f
	IFS=${OLD_IFS}
	while [ -n "${1:-}" ]
	do
		case "${1:-}" in
			-b | --blacklist )
				shift
				funcSetupBlacklist
				;;
			-p | --packages )
				shift
				funcInstallPackages
				;;
			-n | --network  )
				shift
				case "${1:-}" in
					s | software ) shift; funcSetupNetwork_software;;
					h | hardware ) shift; funcSetupNetwork_hardware;;
					*            ) ;;
				esac
				;;
			-s | --service  )
				shift
				funcSetupService
				;;
			* )
				shift
				;;
		esac
	done
}

	funcMain

### Termination ###############################################################
	echo "${PROG_NAME}: === End ==="
	exit 0
### EOF #######################################################################
