# -----------------------------------------------------------------------------
# descript: print out of list data
#   input :     $@     : input value
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _DBGS_WRAP : read
#   g-var : _SIZE_COLS : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout_list() {
	[[ -z "${_DBGS_FLAG:-}" ]] && return
	if [[ -z "${_DBGS_WRAP:-}" ]]; then
		printf "[%-.$((_SIZE_COLS-2))s]\n" "${@:-}" 1>&2
	else
		printf "[%s]\n" "${@:-}" 1>&2
	fi
}
