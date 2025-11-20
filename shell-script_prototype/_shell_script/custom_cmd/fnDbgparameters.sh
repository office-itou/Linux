# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: print out of internal variables
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_PARM : read
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDbgparameters() {
	[[ -z "${_DBGS_PARM:-}" ]] && return
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
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
