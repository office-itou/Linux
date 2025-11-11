# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: message output (debug out)
#   input :     $1     : title
#   input :     $@     : list
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
fnDbgout() {
	___STRT="$(fnString_msg "${_TEXT_GAP1}" "start: ${1:-}")"
	___ENDS="$(fnString_msg "${_TEXT_GAP1}" "end  : ${1:-}")"
	shift
	fnMsgout "-debugout" "${___STRT}"
	while [ -n "${1:-}" ]
	do
		if [ "${1%%,*}" != "debug" ] || [ -n "${_DBGS_FLAG:-}" ]; then
			fnMsgout "${1%%,*}" "${1#*,}"
		fi
		shift
	done
	fnMsgout "-debugout" "${___ENDS}"
}
