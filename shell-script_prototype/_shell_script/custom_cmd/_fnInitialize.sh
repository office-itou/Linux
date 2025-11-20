# -----------------------------------------------------------------------------
# descript: initialize
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
function fnInitialize() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare       __RSLT=""				# result
	declare -a    __LIST=()				# work variable

	# === get data file =======================================================
	__RSLT="$(fnFind_config)"
	read -r -a __LIST < <(echo "${__RSLT:-}")
	__LIST=("${__LIST[@]##-}")
	# --- common configuration file -------------------------------------------
	if [[ -n "${__LIST[0]:-}" ]]; then
		fnGet_conf_data "${__LIST[0]}"	# get common configuration data
		fnSet_conf_data					# set common configuration data
	fi
	# --- distribution data file -----------------------------------------------
	if [[ -n "${__LIST[1]:-}" ]]; then
		fnGet_dist_data "${__LIST[1]}"	# get distribution data
	fi
	# --- media data file -----------------------------------------------------
	if [[ -n "${__LIST[2]:-}" ]]; then
		fnGet_media_data "${__LIST[2]}"	# get media data
		fnSet_media_data				# set common media data
	fi
	# --- debstrap data file --------------------------------------------------
	if [[ -n "${__LIST[3]:-}" ]]; then
		:
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
