# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :            : unused
#   output:   stderr   : output
#   return:            : unused
#   g-var : _DBGS_PARM : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout_parameters() {
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
	[[ -z "${_DBGS_PARM:-}" ]] && return
	for __NAME in "${!__@}"
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME}" in
			''     | \
			__NAME | \
			__VALU ) continue;;
			*) ;;
		esac
		__VALU="${!__NAME:-}"
		printf "${FUNCNAME[1]}: %s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
	done
}
