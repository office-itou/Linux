# -----------------------------------------------------------------------------
# descript: debug print
#   input :     $@     : input value
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	printf "${FUNCNAME[1]}: %q\n" "${@:-}" 1>&2
}
