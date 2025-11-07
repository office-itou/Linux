# -----------------------------------------------------------------------------
# descript: executing the convert
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_convert() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	convert "${__TGET_OPTN[@]}" || \
	{
		__RTCD="$?"
		fnMsgout "failed" "convert (${__RTCD})"       "${_DBGS_OUTS//:_COMMAND_:/convert}"
		fnMsgout "failed" "convert ${__TGET_OPTN[*]}" "${_DBGS_OUTS//:_COMMAND_:/convert}"
	}
	return "${__RTCD}"
}
