# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get network parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _NICS_NAME : write
#   g-var : _DIST_VERS : write
#   g-var : _DIST_CODE : write
# shellcheck disable=SC2148,SC2317,SC2329
fnNetwork_param() {
	_NICS_STAT=""
	_NICS_NAME="${_NICS_NAME:-"ens160"}"
	___DIRS="${_DIRS_TGET:-}/sys/devices"
	if [ ! -e "${___DIRS}"/. ]; then
		fnMsgout "${_PROG_NAME:-}" "caution" "not exist: [${___DIRS}]"
	else
		if [ -z "${_NICS_NAME#*"*"}" ]; then
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | sort -V | head -n 1)"
			_NICS_NAME="${_NICS_NAME##*/}"
		fi
		_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME:-}" | sort -V | head -n 1)"
		_NICS_NAME="${_NICS_NAME##*/}"
		if [ -z "${_NICS_NAME:-}" ]; then
			_NICS_NAME="$(find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name 'e*' | sort -V | head -n 1)"
			_NICS_NAME="${_NICS_NAME##*/}"
		fi
		if ! find "${___DIRS}" -path '*/net/*' ! -path '*/virtual/*' -prune -name "${_NICS_NAME}" | grep -q "${_NICS_NAME}"; then
			fnMsgout "${_PROG_NAME:-}" "failed" "not exist: [${_NICS_NAME}]"
		else
			if ip address show dev "${_NICS_NAME}" > /dev/null 2>&1; then
				_NICS_STAT="true"
			fi
			_NICS_MADR="${_NICS_MADR:-"$(ip -0 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			_NICS_IPV4="${_NICS_IPV4:-"$(ip -4 -brief address show dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}' || true)"}"
			if ip -4 -oneline address show dev "${_NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
				_NICS_AUTO="dhcp"
			fi
			if [ -z "${_NICS_DNS4:-}" ] || [ -z "${_NICS_WGRP:-}" ]; then
				if command -v resolvectl > /dev/null 2>&1; then
					if resolvectl status > /dev/null 2>&1; then
						_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_DNS4="${_NICS_DNS4:-"$(resolvectl dns    2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/^Global:/             s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_WGRP="${_NICS_WGRP:-"$(resolvectl domain 2> /dev/null | sed -ne '/('"${_NICS_NAME}"'):/ s/^.*:[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p')"}"
						_NICS_WGRP="${_NICS_WGRP%.}"
					fi
				fi
				___PATH="${_DIRS_TGET:-}/etc/resolv.conf"
				if [ -e "${___PATH}" ]; then
					_NICS_DNS4="${_NICS_DNS4:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' "${___PATH}")"}"
					_NICS_WGRP="${_NICS_WGRP:-"$(sed -ne '/^search/     s/^.*[ \t]\([[:graph:]]\+\)[ \t]*.*$/\1/p'                      "${___PATH}")"}"
					_NICS_WGRP="${_NICS_WGRP%.}"
				fi
			fi
			_IPV6_ADDR="$(ip -6 -brief address show primary dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $3;}')"
			_LINK_ADDR="$(ip -6 -brief address show primary dev "${_NICS_NAME}" 2> /dev/null | awk '$1!="lo" {print $4;}')"
		fi
	fi
	# --- ipv4 ----------------------------------------------------------------
	if [ -z "${_NICS_IPV4:-}" ]; then
		_NICS_AUTO="dhcp"
	else
		___WORK="$(echo "${_NICS_IPV4:-}" | sed 's/[^0-9./]\+//g')"
		_NICS_IPV4="$(echo "${___WORK}/" | cut -d '/' -f 1)"
		_NICS_BIT4="$(echo "${___WORK}/" | cut -d '/' -f 2)"
		if [ -z "${_NICS_BIT4}" ]; then
			_NICS_BIT4="$(fnIPv4Netmask "${_NICS_MASK:-"255.255.255.0"}")"
		else
			_NICS_MASK="$(fnIPv4Netmask "${_NICS_BIT4:-"24"}")"
		fi
		[ -n "${_NICS_STAT:-}" ] && _NICS_GATE="${_NICS_GATE:-"$(ip -4 -brief route list match default | awk '{print $3;}' | uniq)"}"
	fi
	if [ "${_NICS_IPV4##*.}" = "0" ] || [ "${_NICS_IPV4##*.}" = "255" ]; then
		_NICS_AUTO="dhcp"
	fi
	# --- ipv6 ----------------------------------------------------------------
	_IPV6_ADDR="${_IPV6_ADDR:-"2000::0/3"}"
	_LINK_ADDR="${_LINK_ADDR:-"fe80::0/10"}"
	_IPV4_UADR="${_NICS_IPV4%.*}"
	_IPV4_LADR="${_NICS_IPV4#"${_IPV4_UADR:-"*"}."}"
	_IPV6_CIDR="${_IPV6_ADDR##*/}"
	_IPV6_ADDR="${_IPV6_ADDR%/"${_IPV6_CIDR:-"*"}"}"
	_IPV6_FADR="$(fnIPv6FullAddr "${_IPV6_ADDR:-}" "true")"
	_IPV6_UADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_IPV6_LADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_IPV6_RADR="$(fnIPv6RevAddr "${_IPV6_FADR:-}")"
	_LINK_CIDR="${_LINK_ADDR##*/}"
	_LINK_ADDR="${_LINK_ADDR%/"${_LINK_CIDR:-"*"}"}"
	_LINK_FADR="$(fnIPv6FullAddr "${_LINK_ADDR:-}" "true")"
	_LINK_UADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_LINK_LADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
	_LINK_RADR="$(fnIPv6RevAddr "${_LINK_FADR:-}")"
	# --- fqdn ----------------------------------------------------------------
	if [ -e "${_DIRS_TGET:-}/etc/hostname" ]; then
		_NICS_FQDN="${_NICS_FQDN:-"$(cat "${_DIRS_TGET:-}/etc/hostname" || true)"}"
	fi
	if command -v hostnamectl > /dev/null 2>&1 && [ -n "${_NICS_STAT:-}" ]; then
		_NICS_FQDN="${_NICS_FQDN:-"$(hostnamectl hostname || true)"}"
	fi
	if [ "${_NICS_FQDN:-}" = "localhost" ]; then
		_NICS_HOST="$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"
		_NICS_WGRP="$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"
	fi
	_NICS_FQDN="${_NICS_FQDN:-"${_DIST_NAME:+"sv-${_DIST_NAME}.workgroup"}"}"
	_NICS_FQDN="${_NICS_FQDN:-"localhost.local"}"
	_NICS_HOST="${_NICS_HOST:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"}"
	_NICS_WGRP="${_NICS_WGRP:-"$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"}"
	_NICS_HOST="$(echo "${_NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
	_NICS_WGRP="$(echo "${_NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
	if [ "${_NICS_FQDN}" = "${_NICS_HOST}" ] && [ -n "${_NICS_HOST}" ] && [ -n "${_NICS_WGRP}" ]; then
		_NICS_FQDN="${_NICS_HOST}.${_NICS_WGRP}"
	fi
	readonly _NICS_NAME
	readonly _NICS_MADR
	readonly _NICS_IPV4
	readonly _NICS_MASK
	readonly _NICS_BIT4
	readonly _NICS_DNS4
	readonly _NICS_GATE
	readonly _NICS_FQDN
	readonly _NICS_HOST
	readonly _NICS_WGRP
	readonly _NMAN_FLAG
	readonly _NTPS_ADDR
	readonly _NTPS_IPV4
	readonly _IPV6_LHST
	readonly _IPV4_LHST
	readonly _IPV4_DUMY
	readonly _IPV4_UADR
	readonly _IPV4_LADR
	readonly _IPV6_ADDR
	readonly _IPV6_CIDR
	readonly _IPV6_FADR
	readonly _IPV6_UADR
	readonly _IPV6_LADR
	readonly _IPV6_RADR
	readonly _LINK_ADDR
	readonly _LINK_CIDR
	readonly _LINK_FADR
	readonly _LINK_UADR
	readonly _LINK_LADR
	readonly _LINK_RADR
	unset ___DIRS ___PATH ___WORK
}
