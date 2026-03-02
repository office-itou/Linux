# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: finalize setup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMkosi_finalize_setup() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- setup ---------------------------------------------------------------
	declare -r    __SHEL="/bin/bash"
	declare -r    __FNAM="autoinst_cmd_late.sh"
	declare -r    __SRCS="/work/src/script/${__FNAM:?}"
	declare -r    __DEST="${_DIRS_TEMP:?}/${__FNAM:?}"
	declare -r -a __OPTN=("ip=192.168.1.0/24" "ip=dhcp")
	if [[ ! -e "${__SRCS}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "caution" "not exist: [${__SRCS}]"
	else
		mkdir -p "${__DEST%/*}"
		cp --preserve=timestamps "${__SRCS}" "${__DEST}"
		chmod +x "${__DEST}"
		if ! "${__DEST:?}" "${__OPTN[@]}"; then
			__RTCD="$?"
			fnMsgout "${_PROG_NAME:-}" "failed" "${__DEST} ${__OPTN[*]}"
			fnMsgout "${_PROG_NAME:-}" "start" "${__SHEL}"
			"${__SHEL:?}"
			fnMsgout "${_PROG_NAME:-}" "complete" "${__SHEL}"
			exit "${__RTCD}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
