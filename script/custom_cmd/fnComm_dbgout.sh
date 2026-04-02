# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: message output (debug out)
#   input :     $1     : title
#   input :     $@     : list
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _PROG_NAME : read
#   g-var : _TEXT_GAP1 : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDbgout() {
	declare       ___STRT=""
	declare       ___ENDS=""
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	shift
	fnMsgout "\033[36m${_PROG_NAME:-}" "-debugout" "${___STRT}"
	while [[ -n "${1:-}" ]]
	do
		if [[ "${1%%,*}" != "debug" ]] || [[ -n "${_DBGS_FLAG:-}" ]]; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "\033[36m${_PROG_NAME:-}" "-debugout" "${___ENDS}"
	unset ___STRT
	unset ___ENDS
}
