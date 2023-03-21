#!/bin/bash

# --- Initialization ----------------------------------------------------------
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# Ends with status other than 0
	set -u								# End with undefined variable reference

	trap 'exit 1' 1 2 3 15

	readonly PGM_NAME=`basename $0 | sed -e 's/\..*$//'`
	readonly LOG_NAME="/var/log/installer/${PGM_NAME}.log"

# --- IPv4 netmask conversion -------------------------------------------------
fncIPv4GetNetmask () {
	local INP_ADDR="$@"
	local DEC_ADDR

	DEC_ADDR=$((0xFFFFFFFF ^ ((2 ** (32-$((${INP_ADDR}))))-1)))
	printf '%d.%d.%d.%d' \
	    $((${DEC_ADDR} >> 24)) \
	    $(((${DEC_ADDR} >> 16) & 0xFF)) \
	    $(((${DEC_ADDR} >> 8) & 0xFF)) \
	    $((${DEC_ADDR} & 0xFF))
}

# --- IPv4 netmask bit conversion ---------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR="$@"

	echo ${INP_ADDR} | \
	    awk -F '.' '{
	        split($0, octets);
	        for (i in octets) {
	            mask += 8 - log(2^8 - octets[i])/log(2);
	        }
	        print mask
	    }'
}

# --- packages ----------------------------------------------------------------
fncInstallPackages () {
	echo "fncInstallPackages" 2>&1 | tee -a /target/${LOG_NAME}
	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg  | \
	           sed -z 's/\n//g'                                                                 | \
	           sed -e 's/.* multiselect *//'                                                      \
	               -e 's/[,|\\\\]//g'                                                             \
	               -e 's/\t/ /g'                                                                  \
	               -e 's/  */ /g'                                                                 \
	               -e 's/^ *//'`
	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg | \
	           sed -z 's/\n//g'                                                                 | \
	           sed -e 's/.* string *//'                                                           \
	               -e 's/[,|\\\\]//g'                                                             \
	               -e 's/\t/ /g'                                                                  \
	               -e 's/  */ /g'                                                                 \
	               -e 's/^ *//'`
	# -------------------------------------------------------------------------
	sed -i /target/etc/apt/sources.list \
	    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
	set +e
	in-target --pass-stdout bash -c "
		apt-get -qq    update               2>&1 | tee -a ${LOG_NAME}
		apt-get -qq -y upgrade              2>&1 | tee -a ${LOG_NAME}
		apt-get -qq -y dist-upgrade         2>&1 | tee -a ${LOG_NAME}
		apt-get -qq -y install ${LIST_PACK} 2>&1 | tee -a ${LOG_NAME}
		if [ \"`which tasksel 2> /dev/null`\" != \"\" ]; then
			tasksel install ${LIST_TASK}    2>&1 | tee -a ${LOG_NAME}
		fi
	# -------------------------------------------------------------------------
#	if [ -f /etc/bind/named.conf.options ]; then
#		cp -p /etc/bind/named.conf.options /etc/bind/named.conf.options.original
#		sed -i /etc/bind/named.conf.options            \
#		    -e 's/\(dnssec-validation\) auto;/\1 no;/'
#	fi
	# -------------------------------------------------------------------------
#		if [ -f /usr/lib/systemd/system/connman.service ]; then
#			systemctl disable connman.service 2>&1 | tee -a ${LOG_NAME}
#			systemctl stop connman.service    2>&1 | tee -a ${LOG_NAME}
#		fi
#		if [ -f /usr/lib/systemd/system/NetworkManager.service ]; then
#			systemctl enable NetworkManager.service  2>&1 | tee -a ${LOG_NAME}
#			systemctl restart NetworkManager.service 2>&1 | tee -a ${LOG_NAME}
#		fi
	"
	set -e
}

# --- network -----------------------------------------------------------------
fncSetupNetwork () {
	echo "fncSetupNetwork" 2>&1 | tee -a /target/${LOG_NAME}
	IPV4_DHCP=`awk 'BEGIN {result="true";}
	                !/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {if ($4=="true") result="false";}
	                END {print result;}' /cdrom/preseed/preseed.cfg`
	if [ "${IPV4_DHCP}" != "true" ]; then
		NIC_NAME="ens160"
		NIC_IPV4="`awk '!/#/&&/netcfg\/get_ipaddress/    {print $4;}' /cdrom/preseed/preseed.cfg`"
		NIC_MASK="`awk '!/#/&&/netcfg\/get_netmask/      {print $4;}' /cdrom/preseed/preseed.cfg`"
		NIC_GATE="`awk '!/#/&&/netcfg\/get_gateway/      {print $4;}' /cdrom/preseed/preseed.cfg`"
		NIC_DNS4="`awk '!/#/&&/netcfg\/get_nameservers/  {print $4;}' /cdrom/preseed/preseed.cfg`"
		NIC_WGRP="`awk '!/#/&&/netcfg\/get_domain/       {print $4;}' /cdrom/preseed/preseed.cfg`"
		NIC_BIT4="`fncIPv4GetNetmaskBits "${NIC_MASK}"`"
		# --- connman ---------------------------------------------------------
		if [ -d /target/etc/connman ]; then
			set +e
			NIC_MADR="`LANG=C ip address show dev "${NIC_NAME}" 2> /dev/null | sed -n '/link\/ether/ s/^[ \t]*//gp' | awk '{gsub(":","",$2); print $2;}'`"
			CON_NAME="ethernet_${NIC_MADR}_cable"
			set -e
			mkdir -p /target/var/lib/connman/${CON_NAME}
			cat <<- _EOT_ | sed 's/^ *//g' > /target/var/lib/connman/settings
				[global]
				OfflineMode=false
				
				[Wired]
				Enable=true
				Tethering=false
_EOT_
			if [ "${CON_NAME}" != ""]; then
				cat <<- _EOT_ | sed 's/^ *//g' > /target/var/lib/connman/${CON_NAME}/settings
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
		# --- netplan ---------------------------------------------------------
		if [ -d /target/etc/netplan ]; then
			cat <<- _EOT_ > /target/etc/netplan/99-network-manager-static.yaml
				network:
				  version: 2
				  ethernets:
				    ${NIC_NAME}:
				      dhcp4: false
				      addresses: [ ${NIC_IPV4}/${NIC_BIT4} ]
				      gateway4: ${NIC_GATE}
				      nameservers:
				          search: [ ${NIC_WGRP} ]
				          addresses: [ ${NIC_DNS4} ]
				      dhcp6: true
				      ipv6-privacy: true
_EOT_
		fi
	fi
}

# --- gdm3 --------------------------------------------------------------------
fncChange_gdm3_configure () {
	echo "fncChange_gdm3_configure" 2>&1 | tee -a /target/${LOG_NAME}
	if [ -f /target/etc/gdm3/custom.conf ]; then
		sed -i.orig /target/etc/gdm3/custom.conf \
		    -e '/WaylandEnable=false/ s/^#//'
	fi
}

# --- Main --------------------------------------------------------------------
	fncInstallPackages
	fncSetupNetwork
#	fncChange_gdm3_configure

# --- Termination -------------------------------------------------------------
	cp -p /var/log/syslog /target/var/log/installer/syslog.source
	exit 0
# --- EOF ---------------------------------------------------------------------
