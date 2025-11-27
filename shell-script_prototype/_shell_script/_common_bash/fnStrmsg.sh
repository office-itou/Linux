# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnStrmsg() {
	declare      ___TXT1=""
	declare      ___TXT2=""
	___TXT1="$(echo "${1:-}" | cut -c -3)"
	___TXT2="$(echo "${1:-}" | cut -c "$((${#___TXT1}+2+${#2}+1))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TXT1
	unset ___TXT2
}
