# -----------------------------------------------------------------------------
# descript: create initial files
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
#   g-var : _PATH_CONF : write
#   g-var : _PATH_DIST : write
#   g-var : _PATH_MDIA : write
#   g-var : _PATH_DSTP : write
# shellcheck disable=SC2148
function fnMKinitialfile() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare       __RSLT=""				# result
	declare -a    __LIST=()				# work variable

	fnInitialize						# descript: initialize
	fnMKdirectory						# create directory

	# === get data file =======================================================
	__RSLT="$(fnFind_config)"
	read -r -a __LIST < <(echo "${__RSLT:-}")
	__LIST=("${__LIST[@]##-}")
	# --- create initial file -------------------------------------------------
	if [[ -z "${__LIST[0]:-}" ]]; then
		__LIST[0]="${_DIRS_TEMP:-"/tmp"}/${_FILE_CONF:-"common.cfg"}"
		fnMsgout "create" "conf file: [${__LIST[0]:-}]"
		fnPut_conf_data "${__LIST[0]}"	# put common configuration data
	fi

	# === copy default files ==================================================
	# --- common configuration file -------------------------------------------
	if [[ -n "${__LIST[0]:-}" ]] && [[ -n "${_PATH_CONF:-}" ]] && [[ ! -e "${_PATH_CONF}" ]]; then
		fnMsgout "copy" "     file: ${_FLAG_WIDE:+"[${__LIST[0]}] -> "}[${_PATH_CONF}]"
		cp --preserve=timestamps "${__LIST[0]}" "${_PATH_CONF}"
	fi
	# --- distribution data file ----------------------------------------------
	if [[ -n "${__LIST[1]:-}" ]] && [[ -n "${_PATH_DIST:-}" ]] && [[ ! -e "${_PATH_DIST}" ]]; then
		fnMsgout "copy" "     file: ${_FLAG_WIDE:+"[${__LIST[1]}] -> "}[${_PATH_DIST}]"
		cp --preserve=timestamps "${__LIST[1]}" "${_PATH_DIST}"
	fi
	# --- media data file -----------------------------------------------------
	if [[ -n "${__LIST[2]:-}" ]] && [[ -n "${_PATH_MDIA:-}" ]] && [[ ! -e "${_PATH_MDIA}" ]]; then
		fnMsgout "copy" "     file: ${_FLAG_WIDE:+"[${__LIST[2]}] -> "}[${_PATH_MDIA}]"
		cp --preserve=timestamps "${__LIST[2]}" "${_PATH_MDIA}"
	fi
	# --- debstrap data file --------------------------------------------------
	if [[ -n "${__LIST[3]:-}" ]] && [[ -n "${_PATH_DSTP:-}" ]] && [[ ! -e "${_PATH_DSTP}" ]]; then
		fnMsgout "copy" "     file: ${_FLAG_WIDE:+"[${__LIST[3]}] -> "}[${_PATH_DSTP}]"
		cp --preserve=timestamps "${__LIST[3]}" "${_PATH_DSTP}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}
