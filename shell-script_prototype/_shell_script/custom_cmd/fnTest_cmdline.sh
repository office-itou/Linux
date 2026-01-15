# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test cmdline
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_cmdline() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __BOPT=""
	declare       __LINE=""
	# --- boot parameter selection --------------------------------------------
	__BOPT="$(cat /proc/cmdline)"
	for __LINE in ${__BOPT:-}
	do
		fnMsgout "\033[36m${_PROG_NAME:-}" "info" "${__LINE}"
	done
	unset __BOPT __LINE

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
