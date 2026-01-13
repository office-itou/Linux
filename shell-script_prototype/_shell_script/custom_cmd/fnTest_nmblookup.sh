# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test nmblookup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_nmblookup() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("nmblookup")
	declare       __PARM=""
	declare -a    __ARRY=()
	declare       __ADDR=""
	declare       __NAME=""
	declare       __WGRP=""

	# --- test nmblookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		__ADDR="$("${__COMD[0]}" -M -- - | awk '{print $1;}')"
		__NAME="$("${__COMD[0]}" -A "${__ADDR}" | awk '$2=="<00>"&&$4!="<GROUP>" {print $1;}')"
		__WGRP="$("${__COMD[0]}" -A "${__ADDR}" | awk '$2=="<00>"&&$4=="<GROUP>" {print $1;}')"
		if command -v getent > /dev/null 2>&1; then
			__ARRY=("getent" "hosts" "${__NAME,,}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		fi
		if command -v traceroute > /dev/null 2>&1; then
			__ARRY=("traceroute" "-4" "-w" "1" "-m" "1" "${__NAME,,}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
			__ARRY=("traceroute" "-6" "-w" "1" "-m" "1" "${__NAME,,}")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" > /dev/null 2>&1 | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		fi
	fi
	unset __PARM __ARRY __ADDR __NAME __WGRP

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
