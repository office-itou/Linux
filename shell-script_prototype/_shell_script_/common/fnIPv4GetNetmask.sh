# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion (netmask and cidr conversion)
#   input :     $1     : input vale
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnIPv4GetNetmask() {
	declare -a    __OCTS=()				# octets
	declare -i    __LOOP=0				# work variables
	declare -i    __CALC=0				# "
	case "${1:-}" in
		[0-9].[0-9].[0-9].[0-9])		# netmask -> cidr
			IFS= mapfile -d '.' -t __OCTS < <(echo -n "${1:?}.")
			__CALC=0
			while read -r __LOOP
			do
				case "${__LOOP}" in
					0  ) ((__CALC+=0));;
					128) ((__CALC+=1));;
					192) ((__CALC+=2));;
					224) ((__CALC+=3));;
					240) ((__CALC+=4));;
					248) ((__CALC+=5));;
					252) ((__CALC+=6));;
					254) ((__CALC+=7));;
					255) ((__CALC+=8));;
					*  )              ;;
				esac
			done < <(printf "%s\n" "${__OCTS[@]}")
			printf '%d' "${__CALC}"
			;;
		*)								# cidr -> netmask
			__LOOP=$((32-${1:?}))
			__CALC=1
			while [[ "${__LOOP}" -gt 0 ]]
			do
				__LOOP=$((__LOOP-1))
				__CALC=$((__CALC*2))
			done
			__CALC="$((0xFFFFFFFF ^ (__CALC-1)))"
			printf '%d.%d.%d.%d'           \
				$(( __CALC >> 24        )) \
				$(((__CALC >> 16) & 0xFF)) \
				$(((__CALC >>  8) & 0xFF)) \
				$(( __CALC        & 0xFF))
			;;
	esac
}
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
