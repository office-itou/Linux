# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test network manager
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_netman() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- test network manager ------------------------------------------------
	  if command -v connmanctl > /dev/null 2>&1; then LANG=C connmanctl services
	elif command -v nmcli      > /dev/null 2>&1; then LANG=C nmcli --fields DEVICE,TYPE,ACTIVE,NAME,STATE,UUID,FILENAME connection show | cut -c -"${_COLS_SIZE:-80}"
	elif command -v netplan    > /dev/null 2>&1; then LANG=C netplan get all
	elif command -v networkctl > /dev/null 2>&1; then LANG=C networkctl list
	else                                              fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
