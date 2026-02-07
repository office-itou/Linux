# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv4Netmask() {
	if command -v gawk > /dev/null 2>&1; then
		fnIPv4Netmask_gawk "${@:-}"
	elif command -v mawk > /dev/null 2>&1; then
		fnIPv4Netmask_mawk "${@:-}"
	fi
}
