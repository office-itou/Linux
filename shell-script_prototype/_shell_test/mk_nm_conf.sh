#!/bin/dash

set -eu

_NICS_NAME="ens160"
_NICS_MADR="00:00:00:00:00:00"
_NICS_IPV4="dhcp"
_NICS_IPV4="192.168.1.1"
_NICS_BIT4="24"
_NICS_GATE="192.168.1.254"
_NICS_DNS4="192.168.1.254 127.0.0.1"
_FWAL_ZONE="home_use"

fnSetup_netman() {
	__PATH="${_DIRS_TGET:-}/etc/NetworkManager/system-connections/${_NICS_NAME}.nmconnection"
	__CNID="${__PATH##*/}"
	__CNID="${__CNID%.*}"
	__CNID="Wired connection 1"
	set -f
	set -- \
		type ethernet \
		${__CNID:+connection.id "${__CNID}"} \
		${_NICS_NAME:+connection.interface-name "${_NICS_NAME}"} \
		connection.autoconnect true \
		${_FWAL_ZONE:+connection.zone "${_FWAL_ZONE}"} \
		ethernet.wake-on-lan 0 \
		${_NICS_MADR:+ethernet.mac-address "${_NICS_MADR}"}
	if [ "${_NICS_IPV4}" = "dhcp" ]; then
		set -- "$@" \
			ipv4.method auto \
			ipv6.method auto \
			ipv6.addr-gen-mode default
	else
		set -- "$@" \
			ipv4.method manual \
			${_NICS_IPV4:+ipv4.address "${_NICS_IPV4}"/"${_NICS_BIT4}"} \
			${_NICS_GATE:+ipv4.gateway "${_NICS_GATE}"} \
			${_NICS_DNS4:+ipv4.dns "${_NICS_DNS4}"} \
			ipv6.method auto \
			ipv6.addr-gen-mode default
	fi
	set +f
	nmcli --offline connection add "${@}"
}

fnSetup_netman
