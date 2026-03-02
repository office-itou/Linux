# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnStrmsg() {
	declare      ___TEXT="${1:-}"
	declare      ___TXT1=""
	declare      ___TXT2=""
	___TXT1="$(echo "${___TEXT:-}" | cut -c -3)"
	___TXT2="$(echo "${___TEXT:-}" | cut -c "$((${#___TXT1}+2+${#2}+1+${#_PROG_NAME}+16))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TEXT
	unset ___TXT1
	unset ___TXT2
}
