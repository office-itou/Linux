# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var : _TGET_VIRT : write
# shellcheck disable=SC2148,SC2317,SC2329
fnStrmsg() {
	___TXT1="$(echo "${1:-}" | cut -c -3)"
	___TXT2="$(echo "${1:-}" | cut -c "$((${#___TXT1}+2+${#2}+1))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
}
