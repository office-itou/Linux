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
	readonly WORK_DIRS="${0%/*}"
	readonly SEED_FILE="${WORK_DIRS}/preseed.cfg"
	readonly TGET_DIRS="/target"
	readonly LOGS_DIRS="${TGET_DIRS}/var/log/installer"
	# shellcheck disable=SC2155
	readonly DIST_NAME="$(uname -v | sed -ne 's/.*\(debian\|ubuntu\).*/\1/ip' | tr '[:upper:]' '[:lower:]')"
	# shellcheck disable=SC2155
	readonly COMD_LINE="$(cat /proc/cmdline)"
	#--------------------------------------------------------------------------
	echo "${PROG_NAME}: === Start ==="
	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
	echo "${PROG_NAME}: WORK_DIRS=${WORK_DIRS}"
	echo "${PROG_NAME}: SEED_FILE=${SEED_FILE}"
	echo "${PROG_NAME}: TGET_DIRS=${TGET_DIRS}"
	echo "${PROG_NAME}: LOGS_DIRS=${LOGS_DIRS}"
	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
	echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"

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

### subroutine ################################################################
# --- packages ----------------------------------------------------------------
funcInstallPackages() {
	readonly SRCS_LIST="/etc/apt/sources.list"
	echo "${PROG_NAME}: funcInstallPackages"
	#--------------------------------------------------------------------------
	if [ ! -f "${SRCS_LIST}" ]; then
		echo "${PROG_NAME}: file does not exist ${SRCS_LIST}"
	else
		sed -i "${SRCS_LIST}"                \
		    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
#		echo "${PROG_NAME}: --- sources.list ---"
#		cat "${SRCS_LIST}"
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
	if [ -n "${LIST_TASK:-}" ] && [ -n "$(command -v tasksel 2> /dev/null || true)" ]; then
		# shellcheck disable=SC2086
		tasksel install ${LIST_TASK}
	fi
	echo "${PROG_NAME}: Installation completed"
}

# --- network -----------------------------------------------------------------
funcSetupNetwork() {
	echo "${PROG_NAME}: funcSetupNetwork"
	#--- preseed.cfg parameter ------------------------------------------------
	FIX_IPV4="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/\(disable_dhcp\|disable_autoconfig\)[ \t]\+/ s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_IPV4="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_ipaddress[ \t]\+/                        s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_MASK="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_netmask[ \t]\+/                          s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_GATE="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_gateway[ \t]\+/                          s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_DNS4="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_nameservers[ \t]\+/                      s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_WGRP="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_domain[ \t]\+/                           s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_HOST="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_hostname[ \t]\+/                         s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_WGRP="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/get_domain[ \t]\+/                           s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_NAME="$(sed -ne '/^[ \t]*d-i[ \t]\+netcfg\/choose_interface[ \t]\+/                     s/^.*[ \t]//p' "${SEED_FILE}")"
	NIC_FQDN="${NIC_HOST}"
	if [ -n "${NIC_WGRP}" ]; then
		NIC_FQDN="${NIC_HOST}.${NIC_WGRP}"
	fi
	NIC_BIT4=""
	NIC_MADR=""
	CON_NAME=""
	NMN_FLAG=""		# nm_config, ifupdown, loopback
	#--- /proc/cmdline parameter  ---------------------------------------------
	for LINE in ${COMD_LINE}
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
			ip=dhcp                        ) FIX_IPV4="false"; break                         ;;
			ip=*                           ) FIX_IPV4="true"
			                                 OLD_IFS=${IFS}
			                                 IFS=':'
			                                 set -f
			                                 # shellcheck disable=SC2086
			                                 set -- ${LINE#ip=}
			                                 set +f
			                                 NIC_IPV4="${1}"
			                                 NIC_GATE="${3}"
			                                 NIC_MASK="${4}"
			                                 NIC_FQDN="${5}"
			                                 NIC_NAME="${6}"
			                                 NIC_DNS4="${8}"
			                                 IFS=${OLD_IFS}
			                                 break
			                                 ;;
			*) ;;
		esac
	done
	#--- network parameter ----------------------------------------------------
	NIC_HOST="${NIC_FQDN%.*}"
	NIC_WGRP="${NIC_FQDN#*.}"
	if [ -z "${NIC_WGRP}" ]; then
		NIC_WGRP="$(sed -ne 's/^search[ \t]\+\([[:alnum:]]\+\)[ \t]*/\1/p' "${TGET_DIRS}/etc/resolv.conf")"
	fi
	if [ -n "${NIC_MASK}" ]; then
		NIC_BIT4="$(funcIPv4GetNetCIDR "${NIC_MASK}")"
	fi
	if [ -n "${NIC_IPV4#*/}" ] && [ "${NIC_IPV4#*/}" != "${NIC_IPV4}" ]; then
		FIX_IPV4="true"
		NIC_BIT4="${NIC_IPV4#*/}"
		NIC_IPV4="${NIC_IPV4%/*}"
		NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
	fi
	#--- nic parameter --------------------------------------------------------
	if [ -z "${NIC_NAME}" ] || [ "${NIC_NAME}" = "auto" ]; then
		IP4_INFO="$(ip -4 -oneline address show | sed -ne '/^2:[ \t]\+/p')"
		NIC_NAME="$(echo "${IP4_INFO}" | sed -ne 's/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\)[ \t]\+inet.*$/\1/p')"
	fi
	IP4_INFO="$(ip -4 -oneline link show "${NIC_NAME}" 2> /dev/null)"
	NIC_MADR="$(echo "${IP4_INFO}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
	#--- hostname / hosts -----------------------------------------------------
	OLD_FQDN="$(cat "${TGET_DIRS}/etc/hostname")"
	OLD_HOST="${OLD_FQDN%.*}"
#	OLD_WGRP="${OLD_FQDN#*.}"
	echo "${NIC_FQDN}" > "${TGET_DIRS}/etc/hostname"
	sed -i "${TGET_DIRS}/etc/hosts"                                \
	    -e '/^127\.0\.1\.1/d'                                      \
	    -e "/^${NIC_IPV4}/d"                                       \
	    -e 's/^\([0-9.]\+\)[ \t]\+/\1\t/g'                         \
	    -e 's/^\([0-9a-zA-Z:]\+\)[ \t]\+/\1\t\t/g'                 \
	    -e "/^127\.0\.0\.1/a ${NIC_IPV4}\t${NIC_FQDN} ${NIC_HOST}" \
	    -e "s/${OLD_HOST}/${NIC_HOST}/g"                           \
	    -e "s/${OLD_FQDN}/${NIC_FQDN}/g"
#	sed -i "${TGET_DIRS}/etc/hosts"                                            \
#	    -e 's/\([ \t]\+\)'${OLD_HOST}'\([ \t]*\)$/\1'${NIC_HOST}'\2/'          \
#	    -e 's/\([ \t]\+\)'${OLD_FQDN}'\([ \t]*$\|[ \t]\+\)/\1'${NIC_FQDN}'\2/'
	#--- debug print ----------------------------------------------------------
	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
	echo "${PROG_NAME}: NIC_FQDN=${NIC_FQDN}"
	echo "${PROG_NAME}: NIC_HOST=${NIC_HOST}"
	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
	echo "${PROG_NAME}: CON_MADR=${CON_MADR}"
	echo "${PROG_NAME}: NMN_FLAG=${NMN_FLAG}"
	echo "${PROG_NAME}: --- hostname ---"
	cat "${TGET_DIRS}/etc/hostname"
	echo "${PROG_NAME}: --- hosts ---"
	cat "${TGET_DIRS}/etc/hosts"
	echo "${PROG_NAME}: --- resolv.conf ---"
	cat "${TGET_DIRS}/etc/resolv.conf"
	# --- firewalld -----------------------------------------------------------
	if [ -f "${TGET_DIRS}/etc/firewalld/firewalld.conf" ]; then
		echo "${PROG_NAME}: funcSetupNetwork: firewalld"
#		echo "${PROG_NAME}: --- add-interface=\"${NIC_NAME}\" ---"
#		firewall-cmd --zone=home --add-interface="${NIC_NAME}" --permanent
#		echo "${PROG_NAME}: --- reload ---"
#		firewall-cmd --reload
#		echo "${PROG_NAME}: --- list-all ---"
#		firewall-cmd --zone=home --list-all
		sed -e '/<\/zone>/i \  <interface name="'"${NIC_NAME}"'"\/>' \
		    "${TGET_DIRS}/usr/lib/firewalld/zones/home.xml"          \
		>   "${TGET_DIRS}/etc/firewalld/zones/home.xml"
	fi
	# --- avahi ---------------------------------------------------------------
	if [ -f "${TGET_DIRS}/etc/avahi/avahi-daemon.conf" ]; then
		echo "${PROG_NAME}: funcSetupNetwork: avahi"
		in-target --pass-stdout sh -c "LANG=C systemctl mask avahi-daemon.service avahi-daemon.socket"
		in-target --pass-stdout sh -c "LANG=C systemctl disable avahi-daemon.service avahi-daemon.socket"
#		sed -i "${TGET_DIRS}/etc/avahi/avahi-daemon.conf" \
#			-e '/allow-interfaces=/ {'                    \
#			-e 's/^#//'                                   \
#			-e "s/=.*/=${NIC_NAME}/ }"
#		echo "${PROG_NAME}: --- avahi-daemon.conf ---"
#		cat "${TGET_DIRS}/etc/avahi/avahi-daemon.conf"
	fi
	#--- exit for DHCP --------------------------------------------------------
	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		return
	fi
	# --- connman -------------------------------------------------------------
	if [ -d "${TGET_DIRS}/etc/connman" ]; then
		echo "${PROG_NAME}: funcSetupNetwork: connman"
#		CNF_FILE="${TGET_DIRS}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
#		mkdir -p "${CNF_FILE%/*}"
#		# shellcheck disable=SC2312
#		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${CNF_FILE}"
#			[Service]
#			ExecStart=
#			ExecStart=$(command -v connmand 2> /dev/null) -n --nodnsproxy
#_EOT_
		SET_FILE="${TGET_DIRS}/var/lib/connman/settings"
		mkdir -p "${SET_FILE%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${SET_FILE}"
			[global]
			OfflineMode=false
			
			[Wired]
			Enable=true
			Tethering=false
_EOT_
		for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		do
			MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
			CON_ADDR="$(echo "${MAC_ADDR}" | sed -ne 's/://gp')"
			CON_NAME="ethernet_${CON_ADDR}_cable"
			CON_DIRS="${TGET_DIRS}/var/lib/connman/${CON_NAME}"
			CON_FILE="${CON_DIRS}/settings"
			mkdir -p "${CON_DIRS}"
			chmod 700 "${CON_DIRS}"
			if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
				cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${CON_FILE}"
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
					Nameservers=127.0.0.1;::1;${NIC_DNS4};
					Timeservers=ntp.nict.jp;
					Domains=${NIC_WGRP};
					mDNS=true
					IPv6.DHCP.DUID=
_EOT_
			else
				cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${CON_FILE}"
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
			echo "${PROG_NAME}: --- ${CON_NAME}/settings ---"
			cat "${CON_FILE}"
		done
	fi
	# --- NetworkManager ------------------------------------------------------
	if [ -d "${TGET_DIRS}/etc/NetworkManager/." ]; then
		echo "${PROG_NAME}: funcSetupNetwork: NetworkManager"
		# --- netplan ---------------------------------------------------------
		echo "${PROG_NAME}: moving the netplan file"
		CONF_DIRS="${TGET_DIRS}/etc/netplan"
		for FILE_PATH in "${CONF_DIRS}"/*
		do
			# shellcheck disable=SC2312
			if [ ! -f "${FILE_PATH}" ] \
			|| [ -z "$(sed -ne '/^[ \t]\+ethernets:[ \t]*$/p' "${FILE_PATH}")" ]; then
				continue
			fi
			echo "${PROG_NAME}: moving the netplan file ${FILE_PATH}"
			BACK_DIRS="${LOGS_DIRS}/netplan"
			if [ ! -d "${BACK_DIRS}/." ]; then
				mkdir -p "${BACK_DIRS}"
			fi
			mv "${FILE_PATH}" "${BACK_DIRS}"
		done
		# --- none-dns.conf ---------------------------------------------------
		CONF_DIRS="${TGET_DIRS}/etc/NetworkManager/conf.d"
		mkdir -p "${CONF_DIRS}"
		cat <<- _EOT_ > "${CONF_DIRS}/none-dns.conf"
			[main]
			dns=none
_EOT_
		# --- network manager -------------------------------------------------
		I=1
		for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		do
			MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
			NMAN_DIRS="/etc/NetworkManager/system-connections"
			FILE_DIRS="${TGET_DIRS}${NMAN_DIRS}"
			FILE_NAME="Wired connection ${I}"
			FILE_PATH="${FILE_DIRS}/${FILE_NAME}"
			if [ ! -d "${FILE_DIRS}/." ]; then
				mkdir -p "${FILE_DIRS}"
			fi
			if [ -f "${FILE_PATH}" ]; then
				echo "${PROG_NAME}: moving the network manager file ${FILE_NAME}"
				BACK_DIRS="${LOGS_DIRS}/NetworkManager"
				if [ ! -d "${BACK_DIRS}/." ]; then
					mkdir -p "${BACK_DIRS}"
				fi
				mv "${FILE_PATH}" "${BACK_DIRS}"
			fi
			echo "${PROG_NAME}: create file ${FILE_NAME}"
			if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
				cat <<- _EOT_ > "${FILE_PATH}"
					[connection]
					id=${FILE_NAME}
					type=ethernet
					interface-name=${NICS_NAME}
					autoconnect=true
					zone=home
					
					[ethernet]
					mac-address=${MAC_ADDR}
					mac-address-blacklist=
					
					[ipv4]
					method=manual
					address1=${NIC_IPV4}/${NIC_BIT4},${NIC_GATE}
					dns=${NIC_DNS4};
					dns-search=${NIC_WGRP};
					
					[ipv6]
					method=auto
_EOT_
			else
				cat <<- _EOT_ > "${FILE_PATH}"
					[connection]
					id=${FILE_NAME}
					type=ethernet
					interface-name=${NICS_NAME}
					autoconnect=false
					
					[ethernet]
					mac-address=${MAC_ADDR}
					mac-address-blacklist=
					
					[ipv4]
					method=auto
					
					[ipv6]
					method=auto
_EOT_
			fi
			chmod 600 "${FILE_PATH}"
			cp --archive "${FILE_PATH}" "${NMAN_DIRS#}"
			echo "${PROG_NAME}: --- ${FILE_NAME} ---"
			cat "${FILE_PATH}"
			I=$((I+1))
		done
	fi
	# --- netplan -------------------------------------------------------------
	if [ -d "${TGET_DIRS}/etc/netplan/." ]; then
		echo "${PROG_NAME}: funcSetupNetwork: netplan"
		CONF_DIRS="${TGET_DIRS}/etc/netplan"
		for FILE_LINE in "${CONF_DIRS}"/*
		do
			if [ ! -f "${FILE_LINE}" ]; then
				continue
			fi
			# shellcheck disable=SC2312
			if [ -z "$(sed -n "/${NIC_NAME}/p" "${FILE_LINE}")" ]; then
				echo "${PROG_NAME}: funcSetupNetwork: skip editing files [${FILE_LINE}]"
				cat "${FILE_LINE}"
				continue
			fi
			echo "${PROG_NAME}: funcSetupNetwork: edit the file [${FILE_LINE}]"
			for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
			do
				echo "${PROG_NAME}: funcSetupNetwork: add nic information [${NICS_NAME}]"
				if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
					if [ -z "${NIC_IPV4}" ]; then
						DHCP_FLAG="true"
					else
						DHCP_FLAG="false"
					fi
					cat <<- _EOT_ >> "${FILE_LINE}"
						      dhcp4: ${DHCP_FLAG}
						      dhcp6: true
_EOT_
				else
					cat <<- _EOT_ >> "${FILE_LINE}"
						    ${NICS_NAME}:
						      dhcp4: true
						      dhcp6: true
_EOT_
				fi
			done
			echo "${PROG_NAME}: --- ${FILE_LINE} ---"
			cat "${FILE_LINE}"
		done
	fi
}

# --- gdm3 --------------------------------------------------------------------
#funcChange_gdm3_configure() {
#	echo "${PROG_NAME}: funcChange_gdm3_configure"
#	if [ -f "${TGET_DIRS}/etc/gdm3/custom.conf" ]; then
#		sed -i.orig "${TGET_DIRS}/etc/gdm3/custom.conf" \
#		    -e '/WaylandEnable=false/ s/^#//'
#	fi
#}

### Main ######################################################################
funcMain() {
	echo "${PROG_NAME}: funcMain"
	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
	if [ -n "${PROG_PRAM}" ]; then
		funcInstallPackages
		exit 0
	fi
	# -------------------------------------------------------------------------
	cp --archive "${PROG_PATH}" "${TGET_DIRS}/tmp/"
	cp --archive "${SEED_FILE}" "${TGET_DIRS}/tmp/"
	echo "${PROG_NAME}: --- in-target ---"
	echo "${PROG_NAME}: ${PROG_NAME}"
	echo "${PROG_NAME}: --- in-target start ---"
	in-target --pass-stdout sh -c "LANG=C /tmp/${PROG_NAME} /tmp/${SEED_FILE##*/}"
	echo "${PROG_NAME}: --- in-target end ---"
	funcSetupNetwork
#	funcChange_gdm3_configure
}

	funcMain

### Termination ###############################################################
	echo "${PROG_NAME}: === End ==="
	exit 0
### EOF #######################################################################
