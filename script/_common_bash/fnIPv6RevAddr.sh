# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnIPv6RevAddr() {
	echo "${1:?}" |
	    awk 'gsub(":","") {
	        for(i=length();i>1;i--)
	            printf("%c.", substr($0,i,1))
	        printf("%c" , substr($0,1,1))
		}'
}
