# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: dump output (debug out)
#   input :     $1     : path
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_FLAG : read
#   g-var : _TEXT_GAP1 : read
# shellcheck disable=SC2148,SC2317,SC2329
fnDbgdump() {
	[ -z "${_DBGS_FLAG:-}" ] && return
	if [ ! -e "${1:?}" ]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "not exist: [${1:-}]"
		return
	fi
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${1:-}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${1:-}")"
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___STRT}"
	cat "${1:-}"
	fnMsgout "${_PROG_NAME:-}" "-debugout" "${___ENDS}"
}
