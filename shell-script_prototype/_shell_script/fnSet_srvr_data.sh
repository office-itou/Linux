# -----------------------------------------------------------------------------
# descript: set server data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _SRVR_NICS : write
#   g-var : _SRVR_MADR : write
#   g-var : _SRVR_ADDR : write
#   g-var : _SRVR_CIDR : write
#   g-var : _SRVR_MASK : write
#   g-var : _SRVR_GWAY : write
#   g-var : _SRVR_NSVR : write
#   g-var : _SRVR_UADR : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnSet_srvr_data() {
	declare       __VALU=""				# value
	declare       __DEVS=""				# device name

	if [[ -z "${_SRVR_NICS:-}" ]]; then
		_SRVR_NICS=""					# network device name   (ex. ens160)
		_SRVR_MADR=""					#                mac    (ex. 00:00:00:00:00:00)
		_SRVR_ADDR=""					# IPv4 address          (ex. 192.168.1.11)
		_SRVR_CIDR=""					# IPv4 cidr             (ex. 24)
		_SRVR_MASK=""					# IPv4 subnetmask       (ex. 255.255.255.0)
		_SRVR_GWAY=""					# IPv4 gateway          (ex. 192.168.1.254)
		_SRVR_NSVR=""					# IPv4 nameserver       (ex. 192.168.1.254)
		_SRVR_UADR=""					# IPv4 address up       (ex. 192.168.1)
		for __DEVS in /sys/class/net/{b*,e*,w}
		do
			[[ ! -e "${__DEVS}" ]] && continue
			__VALU="$(LANG=C ip -4 -brief address show dev "${__DEVS##*/}" | awk '{print $3;}' || true)"
			[[ -z "${__VALU:-}" ]] && continue
			_SRVR_NICS="${__DEVS##*/}"
			_SRVR_MADR="$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '{print $3;}' || true)"
			_SRVR_ADDR="${__VALU%/*}"
			_SRVR_CIDR="${__VALU##*/}"
			_SRVR_MASK="$(fnIPv4GetNetmask "${_SRVR_CIDR}")"
			_SRVR_GWAY="$(LANG=C ip -4 -brief route list match default | awk '{print $3;}' || true)"
			break
		done
	fi
	if command -v resolvectl > /dev/null 2>&1; then
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns | sed -ne '/^Global:/             s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns | sed -ne '/('"${_SRVR_NICS}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
	fi
	_SRVR_NSVR="${_SRVR_NSVR:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /etc/resolv.conf)"}"
	if [[ "${_SRVR_NSVR:-}" = "127.0.0.53" ]]; then
		_SRVR_NSVR="$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /run/systemd/resolve/resolv.conf)"
	fi
	_SRVR_UADR="${_SRVR_ADDR%.*}"
}
