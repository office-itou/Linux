# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test dns port
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_dns_port() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("ss" "-tulpn")
	declare -r -a __COM2=("grep" "-E" ":53(|[ \t].*)$")

	# --- test dns port -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__COMD[*]} | ${__COM2[0]} ${__COM2[1]} '${__COM2[2]}'"
		if "${__COMD[@]:?}" | "${__COM2[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
			fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__COMD[*]}"
		else
			fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__COMD[*]}"
		fi
	fi
#	unset __COMD

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
