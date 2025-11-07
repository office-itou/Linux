# -----------------------------------------------------------------------------
# descript: executing the copy
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_copy() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	declare -r    __TGET="${__TGET_OPTN[${#__TGET_OPTN[@]}-1]:-noname}"
	# --- executing command ---------------------------------------------------
	cp "${__TGET_OPTN[@]}" || \
	{
		__RTCD="$?"
		fnMsgout "failed" "cp (${__RTCD})"       "${_DBGS_OUTS//:_COMMAND_:/cp}"
		fnMsgout "failed" "cp ${__TGET_OPTN[*]}" "${_DBGS_OUTS//:_COMMAND_:/cp}"
	}
	"${__RTCD:-}" -eq 0 && \
	{
		fnMsgout "success" "${__TGET##*/}"
		ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${__TGET}" || true
	}
	return "${__RTCD}"
}
