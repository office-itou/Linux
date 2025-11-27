# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: decoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_mdia_Dec() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __WNAM=""				# work: variable name
	declare       __WVAL=""				# work: setting value
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare -i    I=0					# work

	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]:-}"
		read -r -a __LIST < <(echo "${__LINE:-}")
		__WVAL="${__LIST[*]:-}"
		while true
		do
			__WNAM="${__WVAL#"${__WVAL%%:_[[:alnum:]]*_[[:alnum:]]*_:*}"}"
			__WNAM="${__WNAM%"${__WNAM##*:_[[:alnum:]]*_[[:alnum:]]*_:}"}"
			__WNAM="${__WNAM%%[!:_[:alnum:]]*}"
			__WNAM="${__WNAM#:_}"
			__WNAM="${__WNAM%_:}"
			[[ -z "${__WNAM:-}" ]] && break
			__WORK="_${__WNAM}"
			__WVAL="${__WVAL/":_${__WNAM}_:"/"${!__WORK}"}"
		done
		_LIST_MDIA[I]="${__WVAL}"
	done
	unset __WNAM __WVAL __WORK __LINE I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
