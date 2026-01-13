# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test dig
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_dig() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("dig")
	declare       __PARM=""
	declare -a    __ARRY=()

	# --- test nslookup -------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __PARM in \
			"A,${_NICS_FQDN%.*}."         \
			"AAAA,${_NICS_FQDN%.*}."      \
			"A,${_NICS_FQDN}"             \
			"AAAA,${_NICS_FQDN}"          \
			"A,${_NICS_FQDN%.*}.local"    \
			"AAAA,${_NICS_FQDN%.*}.local" \
			"A,www.google.com"            \
			"AAAA,www.google.com"
		do
			__ARRY=("${__COMD[@]}" "${__PARM%%,*}" "${__PARM#*,}" "+nostats" "+nocomments")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
				fnMsgout "\033[36m${_PROG_NAME:-}" "success" "${__ARRY[*]}"
			else
				fnMsgout "\033[36m${_PROG_NAME:-}" "failed" "${__ARRY[*]}"
			fi
		done
		for __PARM in \
			"${_NICS_IPV4}"               \
			"${_IPV6_ADDR}"               \
			"${_LINK_ADDR}"               \
			"${_LINK_ADDR}%${_NICS_NAME}"
		do
			__ARRY=("${__COMD[@]}" "-x" "${__PARM}" "+nostats" "+nocomments")
			fnMsgout "\033[36m${_PROG_NAME:-}" "start" "${__ARRY[*]}"
			if "${__ARRY[@]:?}" | cut -c -"${_COLS_SIZE:-"80"}"; then
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
