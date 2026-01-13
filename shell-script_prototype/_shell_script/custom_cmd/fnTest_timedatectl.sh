# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test timedatectl
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_timedatectl() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("timedatectl")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test timedatectl ----------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__ARRY=("${__COMD[@]}" "status")
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
		if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
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
