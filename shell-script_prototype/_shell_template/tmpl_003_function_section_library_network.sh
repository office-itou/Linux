# === <network> ===============================================================

# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)

# --- IPv4 netmask conversion -------------------------------------------------
# shellcheck disable=SC2317
function funcIPv4GetNetmask() {
	declare       _OCT1=""				# octets
	declare       _OCT2=""				# "
	declare       _OCT3=""				# "
	declare       _OCT4=""				# "
	declare -i    _LOOP=0				# work variables
	declare -i    _CALC=0				# "
	# -------------------------------------------------------------------------
	_OCT1="$(echo "${1:?}." | cut -d '.' -f 1)"
	_OCT2="$(echo "${1}."   | cut -d '.' -f 2)"
	_OCT3="$(echo "${1}."   | cut -d '.' -f 3)"
	_OCT4="$(echo "${1}."   | cut -d '.' -f 4)"
	# -------------------------------------------------------------------------
	if [[ -n "${_OCT1}" ]] && [[ -n "${_OCT2}" ]] && [[ -n "${_OCT3}" ]] && [[ -n "${_OCT4}" ]]; then
		# --- netmask -> cidr -------------------------------------------------
		_CALC=0
		for _LOOP in "${_OCT1}" "${_OCT2}" "${_OCT3}" "${_OCT4}"
		do
			case "${_LOOP}" in
				  0) _CALC=$((_CALC+0));;
				128) _CALC=$((_CALC+1));;
				192) _CALC=$((_CALC+2));;
				224) _CALC=$((_CALC+3));;
				240) _CALC=$((_CALC+4));;
				248) _CALC=$((_CALC+5));;
				252) _CALC=$((_CALC+6));;
				254) _CALC=$((_CALC+7));;
				255) _CALC=$((_CALC+8));;
				*  )                 ;;
			esac
		done
		printf '%d' "${_CALC}"
	else
		# --- cidr -> netmask -------------------------------------------------
		_LOOP=$((32-${1:?}))
		_CALC=1
		while [[ "${_LOOP}" -gt 0 ]]
		do
			_LOOP=$((_LOOP-1))
			_CALC=$((_CALC*2))
		done
		_CALC="$((0xFFFFFFFF ^ (_CALC-1)))"
		printf '%d.%d.%d.%d'              \
		    $(( _CALC >> 24        )) \
		    $(((_CALC >> 16) & 0xFF)) \
		    $(((_CALC >>  8) & 0xFF)) \
		    $(( _CALC        & 0xFF))
	fi
}

# --- IPv6 full address -------------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetFullAddr() {
	declare -r    _FSEP="${1//[^:]/}"
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	# -------------------------------------------------------------------------
	_WORK="$(printf "%$((7-${#_FSEP}))s" "")"
	_WORK="${1/::/::${_WORK// /:}}"
	IFS= mapfile -d ':' -t _ARRY < <(echo -n "${_WORK/%:/::}")
	printf ':%04x' "${_ARRY[@]/#/0x0}" | cut -c 2-
}

# --- IPv6 reverse address ----------------------------------------------------
# shellcheck disable=SC2317
function funcIPv6GetRevAddr() {
	echo "${1//:/}" | \
	    awk '{
	        for(i=length();i>1;i--)              \
	            printf("%c.", substr($0,i,1));   \
	            printf("%c" , substr($0,1,1));}'
}
