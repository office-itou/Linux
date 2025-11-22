# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: conversion common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _LIST_CONF : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnCnv_conf_data() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]}"
		__LINE="${__LINE%%#*}"
		__LINE="${__LINE//["${IFS}"]/ }"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		# --- get variable name -----------------------------------------------
		__NAME="_${__LINE%%=*}"
		[[ -z "${__NAME##_}" ]] && continue
		# --- get setting value -----------------------------------------------
		__VALU="${__LINE#*=}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		[[ -z "${__VALU:-}" ]] && continue
		# --- setting value conversion ----------------------------------------
		while true
		do
			__WORK="${__VALU}"
			# --- get variable name -------------------------------------------
			__WORK="${__WORK#"${__WORK%%:_[A-Z]*_[A-Z]*_:*}"}"
			__WNAM="${__WORK%"${__WORK#:_[A-Z]*_[A-Z]*_:*}"}"
			[[ -z "${__WNAM:-}" ]] && break
			# --- setting value conversion ------------------------------------
			__WORK="${__WNAM#:_}"
			__WORK="${__WORK%_:}"
			__WVAL="${__WORK:+"\$\{\_${__WORK}:-\}"}"
			__VALU="${__VALU/${__WNAM}/${__WVAL:-}}"
		done
		# --- store in a variable ---------------------------------------------
		read -r "${__NAME:-}" < <(eval echo "${__VALU}" || true)
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
