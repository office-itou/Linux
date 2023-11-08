#!/bin/sh

### initialization ############################################################
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# Ends with status other than 0
	set -u								# End with undefined variable reference

	trap 'exit 1' 1 2 3 15

	readonly PROG_PRAM="$@"
	readonly PROG_NAME="${0##*/}"
	readonly WORK_DIRS="${0%/*}"
	readonly DIST_NAME="$(uname -v | tr '[A-Z]' '[a-z]' | sed -n -e 's/.*\(debian\|ubuntu\).*/\1/p')"
	echo "${PROG_NAME}: === Start ==="
	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
	echo "${PROG_NAME}: WORK_DIRS=${WORK_DIRS}"
	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
	#--------------------------------------------------------------------------
	if [ -z "${PROG_PRAM}" ]; then
		ROOT_DIRS="/target"
		COMD_LINE=""
		CONF_FILE=""
		TEMP_FILE=""
		PROG_PATH="$0"
		for COMD_LINE in $(cat /proc/cmdline)
		do
			case "${COMD_LINE}" in
				preseed/file=* ) CONF_FILE="${COMD_LINE#preseed/file=}"; break;;
				file=*         ) CONF_FILE="${COMD_LINE#file=}"        ; break;;
			esac
		done
		if [ -z "${CONF_FILE}" ]; then
			CONF_FILE="${WORK_DIRS}/preseed.cfg"
		else
			case "${DIST_NAME}" in
				debian )                                 ;;
				ubuntu ) CONF_FILE="/preseed/preseed.cfg";;
			esac
		fi
		if [ -z "${CONF_FILE}" ] || [ ! -f "${CONF_FILE}" ]; then
			echo "${PROG_NAME}: not found preseed file [${CONF_FILE}]"
			exit 1
		fi
		echo "${PROG_NAME}: now found preseed file [${CONF_FILE}]"
		cp -a "${PROG_PATH}" "${ROOT_DIRS}/tmp/"
		cp -a "${CONF_FILE}" "${ROOT_DIRS}/tmp/"
		TEMP_FILE="/tmp/${CONF_FILE##*/}"
		echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
		echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"
		echo "${PROG_NAME}: CONF_FILE=${CONF_FILE}"
		echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"
		in-target --pass-stdout bash -c "LANG=C /tmp/${PROG_NAME} ${TEMP_FILE}"
		exit 0
	fi
	ROOT_DIRS=""
	TEMP_FILE="${PROG_PRAM}"
	echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
	echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"

### common ###########################################################
# --- IPv4 netmask conversion -------------------------------------------------
funcIPv4GetNetmask () {
	readonly INP_ADDR="$1"
	readonly DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-INP_ADDR)-1)))"
	printf '%d.%d.%d.%d' \
	    $(( DEC_ADDR >> 24        )) \
	    $(((DEC_ADDR >> 16) & 0xFF)) \
	    $(((DEC_ADDR >>  8) & 0xFF)) \
	    $(( DEC_ADDR        & 0xFF))
}

# --- IPv4 netmask bit conversion ---------------------------------------------
funcIPv4GetNetmaskBits () {
	readonly INP_ADDR="$1"
	echo "${INP_ADDR}" | \
	    awk -F '.' '{
	        split($0, octets);
	        for (i in octets) {
	            mask += 8 - log(2^8 - octets[i])/log(2);
	        }
	        print mask
	    }'
}

### subroutine ################################################################
# --- packages ----------------------------------------------------------------
funcInstallPackages () {
	echo "${PROG_NAME}: funcInstallPackages"
	#--------------------------------------------------------------------------
	LIST_TASK="$(sed -n -e '/^[[:blank:]]*tasksel[[:blank:]]\+tasksel\/first[[:blank:]]\+/,/[^\\]$/p' "${TEMP_FILE}" | \
	             sed -z -e 's/\\\n//g'                                                                               | \
	             sed -e 's/^.*[[:blank:]]\+multiselect[[:blank:]]\+//'                                                 \
	                 -e 's/[[:blank:]]\+/ /g')"
	LIST_PACK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+pkgsel\/include[[:blank:]]\+/,/[^\\]$/p'    "${TEMP_FILE}" | \
	             sed -z -e 's/\\\n//g'                                                                               | \
	             sed -e 's/^.*[[:blank:]]\+string[[:blank:]]\+//'                                                      \
	                 -e 's/[[:blank:]]\+/ /g')"
	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK}"
	echo "${PROG_NAME}: LIST_PACK=${LIST_PACK}"
	#--------------------------------------------------------------------------
	LIST_DPKG="$(LANG=C dpkg-query --list ${LIST_PACK} 2>&1 | grep -E -v '^ii|^\+|^\||^Desired' || true)"
	if [ -z "${LIST_DPKG}" ]; then
		echo "${PROG_NAME}: Finish the installation"
		return
	fi
	echo "${PROG_NAME}: Run the installation"
	echo "${PROG_NAME}: LIST_DPKG="
	echo "${PROG_NAME}: <<<"
	echo "${LIST_DPKG}"
	echo "${PROG_NAME}: >>>"
	#--------------------------------------------------------------------------
	sed -i "${ROOT_DIRS}/etc/apt/sources.list" \
	    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
	apt-get -qq    update
	apt-get -qq -y upgrade
	apt-get -qq -y dist-upgrade
	apt-get -qq -y install ${LIST_PACK}
	if [ -n "$(command -v tasksel 2> /dev/null)" ]; then
		tasksel install ${LIST_TASK}
	fi
}

# --- network -----------------------------------------------------------------
funcSetupNetwork () {
	echo "${PROG_NAME}: funcSetupNetwork"
	#--------------------------------------------------------------------------
	FIX_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+\(netcfg\/disable_dhcp\|netcfg\/disable_autoconfig\)[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_ipaddress[[:blank:]]\+/   s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_MASK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_netmask[[:blank:]]\+/     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_GATE="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_gateway[[:blank:]]\+/     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_DNS4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_nameservers[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_WGRP="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/      s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
	NIC_BIT4="$(funcIPv4GetNetmaskBits "${NIC_MASK}")"
	NIC_NAME="ens160"
	NIC_MADR="$(LANG=C ip address show dev "${NIC_NAME}" 2> /dev/null | sed -n -e '/link\/ether/ s%.*link/ether \([[:graph:]]\+\) .*$%\1%p')"
	CON_NAME="ethernet_$(echo "${NIC_MADR}" | sed -n -e 's/://gp')_cable"
	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
	echo "${PROG_NAME}: CON_NAME=${CON_NAME}"

	#--------------------------------------------------------------------------
	if [ "${FIX_IPV4}" != "true" ]; then
		return
	fi
	# --- connman -------------------------------------------------------------
	if [ -d "${ROOT_DIRS}/etc/connman" ]; then
		echo "${PROG_NAME}: funcSetupNetwork: connman"
		mkdir -p "${ROOT_DIRS}/var/lib/connman/${CON_NAME}"
		cat <<- _EOT_ | sed 's/^ *//g' > "${ROOT_DIRS}/var/lib/connman/settings"
			[global]
			OfflineMode=false
			
			[Wired]
			Enable=true
			Tethering=false
_EOT_
		if [ -n "${CON_NAME}" ]; then
			cat <<- _EOT_ | sed 's/^ *//g' > "${ROOT_DIRS}/var/lib/connman/${CON_NAME}/settings"
				[${CON_NAME}]
				Name=Wired
				AutoConnect=true
				Modified=
				IPv6.method=auto
				IPv6.privacy=preferred
				IPv6.DHCP.DUID=
				IPv4.method=manual
				IPv4.DHCP.LastAddress=
				IPv4.netmask_prefixlen=${NIC_BIT4}
				IPv4.local_address=${NIC_IPV4}
				IPv4.gateway=${NIC_GATE}
				Nameservers=${NIC_DNS4};127.0.0.1;::1;
				Domains=${NIC_WGRP};
				Timeservers=ntp.nict.jp;
				mDNS=true
_EOT_
		fi
	fi
	# --- netplan -------------------------------------------------------------
	if [ -d "${ROOT_DIRS}/etc/netplan" ]; then
		echo "${PROG_NAME}: funcSetupNetwork: netplan"
		cat <<- _EOT_ > "${ROOT_DIRS}/etc/netplan/99-network-manager-static.yaml"
			network:
			  version: 2
			  ethernets:
			    "${NIC_NAME}":
			      dhcp4: false
			      addresses: [ "${NIC_IPV4}/${NIC_BIT4}" ]
			      gateway4: "${NIC_GATE}"
			      nameservers:
			          search: [ "${NIC_WGRP}" ]
			          addresses: [ "${NIC_DNS4}" ]
			      dhcp6: true
			      ipv6-privacy: true
_EOT_
	fi
}

# --- gdm3 --------------------------------------------------------------------
funcChange_gdm3_configure () {
	echo "${PROG_NAME}: funcChange_gdm3_configure"
	if [ -f "${ROOT_DIRS}/etc/gdm3/custom.conf" ]; then
		sed -i.orig "${ROOT_DIRS}/etc/gdm3/custom.conf" \
		    -e '/WaylandEnable=false/ s/^#//'
	fi
}

# --- Main --------------------------------------------------------------------
funcMain () {
	echo "${PROG_NAME}: funcMain"
	case "${DIST_NAME}" in
		debian )
			funcInstallPackages
			funcSetupNetwork
#			funcChange_gdm3_configure
			;;
		ubuntu )
			funcInstallPackages
			funcSetupNetwork
#			funcChange_gdm3_configure
			;;
	esac
}

	funcMain
# --- Termination -------------------------------------------------------------
	echo "${PROG_NAME}: === End ==="
	exit 0
# --- EOF ---------------------------------------------------------------------
