# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: finalize locale
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMkosi_finalize_locale() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- user environment ----------------------------------------------------
	declare -r    __SHEL="/bin/bash"	# login shell
	declare -r    __LANG="ja_JP.UTF-8"
	declare -r    __TIME="Asia/Tokyo"
	declare       __PATH=""
	if [[ -n "${__LANG:-}" ]]; then
		sed -i /etc/locale.gen \
		    -e '/^#[^A-Za-z]*\(C.UTF-8\|'"${__LANG:?}"'\)/ s/^#[^A-Za-z]*//g'
		if ! locale-gen; then
			__RTCD="$?"
			fnMsgout "${_PROG_NAME:-}" "failed" "locale-gen ${__LANG:?}"
			fnMsgout "${_PROG_NAME:-}" "start" "${__SHEL}"
			"${__SHEL:?}"
			fnMsgout "${_PROG_NAME:-}" "complete" "${__SHEL}"
			exit "${__RTCD}"
		fi
		if ! update-locale LANG="${__LANG:?}"; then
			__RTCD="$?"
			fnMsgout "${_PROG_NAME:-}" "failed" "update-locale ${__LANG:?}"
			fnMsgout "${_PROG_NAME:-}" "start" "${__SHEL}"
			"${__SHEL:?}"
			fnMsgout "${_PROG_NAME:-}" "complete" "${__SHEL}"
			exit "${__RTCD}"
		fi
		__PATH="/etc/localtime"
		rm -f "${__PATH:?}"
		ln -s /usr/share/zoneinfo/"${__TIME:?}" "${__PATH}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
