# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
#   g-var : _TGET_VIRT : write
# shellcheck disable=SC2148,SC2317,SC2329
fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}
