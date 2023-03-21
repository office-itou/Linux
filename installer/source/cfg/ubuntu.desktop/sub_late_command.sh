#!/bin/bash

# --- Initialization ----------------------------------------------------------
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# Ends with status other than 0
	set -u								# End with undefined variable reference

	trap 'exit 1' 1 2 3 15

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

# --- Get network interface information ---------------------------------------
	NIC_INF4="`sed -n '/^iface.*static$/,/^iface/ s/^[ \t]*//gp' /etc/network/interfaces`"
	NIC_NAME="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"iface\" {print $2;}'`"
	NIC_IPV4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"address\" {print $2;}'`"
	NIC_BIT4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"address\" {print $3;}'`"
	NIC_GATE="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"gateway\" {print $2;}'`"
	NIC_DNS4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"dns-nameservers\" {print $2;}'`"
	NIC_WGRP="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"dns-search\" {print $2;}'`"
	NIC_MASK="`fncIPv4GetNetmask "${NIC_BIT4}"`"
	NIC_MADR="`LANG=C ip address show dev "${NIC_NAME}" | sed -n '/link\/ether/ s/^[ \t]*//gp' | awk '{gsub(":","",$2); print $2;}'`"
	CON_NAME="ethernet_${NIC_MADR}_cable"
#	NIC_DNS4="`LANG=C ip -4 rule show dev "${NIC_NAME}" default | awk '{print $3;}'`"
#	NIC_INF6="`LANG=C ip -6 address show dev "${NIC_NAME}" | sed -n '/scope global/p'`"
#	NIC_IPV6="`echo "${NIC_INF6[@]}" | sed -n '/scope global/p' | sed -n 's/^[ \t]*//gp' | awk -F '[ /]' '{print $2;}'`"
#	NIC_BIT6="`echo "${NIC_INF6[@]}" | sed -n '/scope global/p' | sed -n 's/^[ \t]*//gp' | awk -F '[ /]' '{print $3;}'`"
#	NIC_DNS6="`LANG=C ip -6 rule show dev "${NIC_NAME}" default | awk '{print $3;}'`"

# --- Set up IPv4/IPv6 --------------------------------------------------------
	if [ -d /etc/connman ]; then
		mkdir -p /var/lib/connman/${CON_NAME}
		cat <<- _EOT_ | sed 's/^ *//g' > /var/lib/connman/settings
			[global]
			OfflineMode=false
			
			[Wired]
			Enable=true
			Tethering=false
_EOT_
		cat <<- _EOT_ | sed 's/^ *//g' > /var/lib/connman/${CON_NAME}/settings
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
	if [ -d /etc/netplan ]; then
		cat <<- _EOT_ > /etc/netplan/99-network-manager-static.yaml
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

# --- Termination -------------------------------------------------------------
	exit 0
# --- EOF ---------------------------------------------------------------------
