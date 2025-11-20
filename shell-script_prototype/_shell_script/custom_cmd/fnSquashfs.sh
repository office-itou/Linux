# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: squashfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
# shellcheck disable=SC2148
function fnSquashfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"
	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
