# shellcheck disable=SC2148
# === <network> ===============================================================

# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)

# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion (netmask and cidr conversion)
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv4GetNetmask() {
	fnDebugout ""
	declare -a    __OCTS=()				# octets
	declare -i    __LOOP=0				# work variables
	declare -i    __CALC=0				# "
	# -------------------------------------------------------------------------
	IFS= mapfile -d '.' -t __OCTS < <(echo -n "${1:?}.")
	# -------------------------------------------------------------------------
	if [[ "${#__OCTS[@]}" -gt 1 ]]; then
		# --- netmask -> cidr -------------------------------------------------
		__CALC=0
		while read -r __LOOP
		do
			case "${__LOOP}" in
				  0) ((__CALC+=0));;
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
	else
		# --- cidr -> netmask -------------------------------------------------
		__LOOP=$((32-${1:?}))
		__CALC=1
		while [[ "${__LOOP}" -gt 0 ]]
		do
			__LOOP=$((__LOOP-1))
			__CALC=$((__CALC*2))
		done
		__CALC="$((0xFFFFFFFF ^ (__CALC-1)))"
		printf '%d.%d.%d.%d'              \
		    $(( __CALC >> 24        )) \
		    $(((__CALC >> 16) & 0xFF)) \
		    $(((__CALC >>  8) & 0xFF)) \
		    $(( __CALC        & 0xFF))
	fi
}

# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv6GetFullAddr() {
	fnDebugout ""
	declare -r    __FSEP="${1//[^:]/}"
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	# -------------------------------------------------------------------------
	__WORK="$(printf "%$((7-${#__FSEP}))s" "")"
	__WORK="${1/::/::${__WORK// /:}}"
	IFS= mapfile -d ':' -t __ARRY < <(echo -n "${__WORK/%:/::}")
	printf ':%04x' "${__ARRY[@]/#/0x0}" | cut -c 2-
}

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnIPv6GetRevAddr() {
	fnDebugout ""
	echo "${1//:/}" | \
	    awk '{
	        for(i=length();i>1;i--)              \
	            printf("%c.", substr($0,i,1));   \
	            printf("%c" , substr($0,1,1));}'
}
