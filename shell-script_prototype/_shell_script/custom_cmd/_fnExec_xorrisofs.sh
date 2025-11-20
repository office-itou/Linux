# -----------------------------------------------------------------------------
# descript: executing the xorrisofs
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_xorrisofs() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	xorrisofs "${__TGET_OPTN[@]}" || \
	{
		__RTCD="$?"
		fnMsgout "failed" "xorrisofs (${__RTCD})"       "${_DBGS_OUTS//:_COMMAND_:/xorrisofs}"
		fnMsgout "failed" "xorrisofs ${__TGET_OPTN[*]}" "${_DBGS_OUTS//:_COMMAND_:/xorrisofs}"
	}
	return "${__RTCD}"
}
