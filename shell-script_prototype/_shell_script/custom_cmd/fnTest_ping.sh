# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test ping
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_ping() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("ping")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test ping -----------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"-4,${_NICS_FQDN}"               \
			"-6,${_NICS_FQDN}"               \
			"-4,${_NICS_IPV4}"               \
			"-6,${_IPV6_ADDR}"               \
			"-6,${_LINK_ADDR}%${_NICS_NAME}" \
			"-4,www.google.com"              \
			"-6,www.google.com"
		do
			__ARRY=("${__COMD[@]}" "${__PARM%%,*}" "-c" "1" "${__PARM#*,}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
	fi
	unset __PARM __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
