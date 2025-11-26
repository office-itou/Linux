# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: Print all global variables (_[A..Z]*)
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_PARM : read
#   memo  : https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
# shellcheck disable=SC2148,SC2317,SC2329
function fnDbgparameters_all() {
#	[[ -z "${_DBGS_PARM:-}" ]] && return

	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	eval printf "%q\\\n" "\${!_"{{A..Z},{a..z}}"@}" | while read -r __NAME
	do
		[[ -n "${__NAME:-}" ]] && declare -p "${__NAME}"
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
