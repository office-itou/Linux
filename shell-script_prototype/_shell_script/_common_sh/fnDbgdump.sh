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
	___PATH="${1:?}"
	if [ ! -e "${___PATH}" ]; then
		fnMsgout "failed" "not exist: [${___PATH}]"
		return
	fi
	___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: ${___PATH}")"
	___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : ${___PATH}")"
	fnMsgout "-debugout" "${___STRT}"
	cat "${___PATH}"
	fnMsgout "-debugout" "${___ENDS}"
}
