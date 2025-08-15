#!/bin/bash

set -eu

	declare -r    NICS_NAME="ens160"
#	declare       NICS_MADR=""
	declare       NICS_IPV4=""
	declare       NICS_BIT4=""
	declare       NICS_IPV4=""
	declare       NICS_GATE=""
	declare -r    BRDG_NAME="br0"
	declare       BRDG_ADDR=""
	declare       BRDG_GWAY=""
	declare       CONN_NAME=""

	if ip -oneline link | grep -q "${BRDG_NAME}"; then
		echo "device name [${BRDG_NAME}] is exist"
		exit 1
	fi

	if ! ip -oneline link | grep -q "${NICS_NAME}"; then
		echo "device name [${NICS_NAME}] not exist"
		exit 1
	fi

#	NICS_MADR="$(ip -0 -brief address show dev "${NICS_NAME}" | awk '$1!="lo" {print $3;}')"
	NICS_IPV4="$(ip -4 -brief address show dev "${NICS_NAME}" | awk '$1!="lo" {print $3;}')"
	NICS_BIT4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 2)"
	NICS_IPV4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 1)"
	NICS_GATE="$(ip -4 -brief route list match default | awk '{print $3;}')"

	BRDG_ADDR="${NICS_IPV4}/${NICS_BIT4}"
	BRDG_GWAY="${NICS_GATE}"

	CONN_NAME="$(nmcli device show "${NICS_NAME}" | sed -ne '/GENERAL.CONNECTION:/ s/^[[:graph:]]\+[ \t]\+//p')"

# --- setup bridge ------------------------------------------------------------
	nmcli connection add type bridge ifname "${BRDG_NAME}" \
		connection.id "${BRDG_NAME}" \
		connection.interface-name "${BRDG_NAME}" \
		ipv4.method manual \
		ipv4.address "${BRDG_ADDR}" \
		ipv4.gateway "${BRDG_GWAY}"

	nmcli connection modify "${BRDG_NAME}" bridge.stp no

	nmcli connection modify "${CONN_NAME}" master "${BRDG_NAME}" slave-type bridge

#	nmcli connection up "${NICS_NAME}"

# --- setup -------------------------------------------------------------------
	find /etc/dnsmasq.d/ /etc/samba/ /etc/firewalld/zones/ -type f | while read -r _PATH
	do
		sed -i "${_PATH}"                              \
		    -e 's/'"${NICS_NAME}"'/'"${BRDG_NAME}"'/g'
	done

# --- service restart ---------------------------------------------------------
	systemctl daemon-reload
	systemctl restart dnsmasq.service
	systemctl restart smb.service nmb.service
	systemctl restart firewalld.service

# --- exit --------------------------------------------------------------------
	echo "please systen reboot"
	exit 0