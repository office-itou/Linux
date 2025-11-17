# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :     $1     : value
#   input :     $2     : format (not empty: zero padding)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv6FullAddr() {
	___ADDR="${1:?}"
	___FMAT="${2:+"%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"}"
	echo "${___ADDR}" |
		awk -F '/' '{
			str=$1
			gsub("[^:]","",str)
			sep=""
			for (i=1;i<=7-length(str)+2;i++) {
				sep=sep":"
			}
			str=$1
			gsub("::",sep,str)
			split(str,arr,":")
			for (i=0;i<length(arr);i++) {
				num[i]="0x"arr[i]
			}
			printf "'"${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}"'",
			num[1],num[2],num[3],num[4],num[5],num[6],num[7],num[8]
		}'
#	___SPRT="$(echo "${___ADDR}" | sed -e 's/[^:]//g')"
#	___LENG=$((7-${#___SPRT}))
#	if [ "${___LENG}" -gt 0 ]; then
#		___SPRT="$(printf ':%.s' $(seq 1 $((___LENG+2))) || true)"
#		___ADDR="$(echo "${___ADDR}" | sed -e "s/::/${___SPRT}/")"
#	fi
#	___OCT1="$(echo "${___ADDR}" | cut -d ':' -f 1)"
#	___OCT2="$(echo "${___ADDR}" | cut -d ':' -f 2)"
#	___OCT3="$(echo "${___ADDR}" | cut -d ':' -f 3)"
#	___OCT4="$(echo "${___ADDR}" | cut -d ':' -f 4)"
#	___OCT5="$(echo "${___ADDR}" | cut -d ':' -f 5)"
#	___OCT6="$(echo "${___ADDR}" | cut -d ':' -f 6)"
#	___OCT7="$(echo "${___ADDR}" | cut -d ':' -f 7)"
#	___OCT8="$(echo "${___ADDR}" | cut -d ':' -f 8)"
#	# shellcheck disable=SC2059
#	printf "${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}" \
#	    "0x${___OCT1:-"0"}" \
#	    "0x${___OCT2:-"0"}" \
#	    "0x${___OCT3:-"0"}" \
#	    "0x${___OCT4:-"0"}" \
#	    "0x${___OCT5:-"0"}" \
#	    "0x${___OCT6:-"0"}" \
#	    "0x${___OCT7:-"0"}" \
#	    "0x${___OCT8:-"0"}"
}
