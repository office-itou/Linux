# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get media information data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_mdia_Get() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if [[ -e "${1:?}" ]]; then
		_LIST_MDIA=()
		IFS= mapfile -d $'\n' -t _LIST_MDIA < <(expand -t 4 "$1" || true)
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
