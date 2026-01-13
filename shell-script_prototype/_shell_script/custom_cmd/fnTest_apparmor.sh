# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test apparmor
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_apparmor() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("apparmor")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test apparmor -------------------------------------------------------
	if ! command -v aa-enabled > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		if ! aa-enabled > /dev/null 2>&1; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "inactive" "${__COMD[0]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "active" "${__COMD[0]}"
			if aa-status --show=processes > /dev/null 2>&1; then
				aa-status --show=processes
			else
				aa-status --verbose
			fi
		fi
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
