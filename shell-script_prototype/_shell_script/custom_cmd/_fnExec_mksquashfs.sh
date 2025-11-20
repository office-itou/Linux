# -----------------------------------------------------------------------------
# descript: executing the mksquashfs
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_mksquashfs() {
	declare -r -a __TGET_OPTN=("$@")	# option parameter
	declare -i    __RTCD=0				# return code
	# --- executing command ---------------------------------------------------
	mksquashfs "${__TGET_OPTN[@]}" || \
	{
		__RTCD="$?"
		fnMsgout "failed" "mksquashfs (${__RTCD})"       "${_DBGS_OUTS//:_COMMAND_:/mksquashfs}"
		fnMsgout "failed" "mksquashfs ${__TGET_OPTN[*]}" "${_DBGS_OUTS//:_COMMAND_:/mksquashfs}"
	}
	return "${__RTCD}"
}
