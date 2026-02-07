# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}
