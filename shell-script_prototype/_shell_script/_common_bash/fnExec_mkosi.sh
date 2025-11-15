# -----------------------------------------------------------------------------
# descript: executing the mkosi
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_mkosi() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	mkosi "${__TGET_OPTN[@]}" || \
	{
		__RTCD="$?"
		fnMsgout "failed" "mkosi (${__RTCD})"       "${_DBGS_OUTS//:_COMMAND_:/mkosi}"
		fnMsgout "failed" "mkosi ${__TGET_OPTN[*]}" "${_DBGS_OUTS//:_COMMAND_:/mkosi}"
	}
	return "${__RTCD}"
}
