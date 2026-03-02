# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: finalize user environment
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMkosi_finalize_userenv() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- user environment ----------------------------------------------------
	declare -a    __OPTN=()
	declare -r    __SHEL="/bin/bash"	# login shell
	declare -r    __USER="user"			# user name
	declare -r    __PAWD="live"			# password
	declare       __CRYP=""				# encrypted password
	declare       __SUDO=""				# sudo group name
	__SUDO="$(awk -F ':' '$1~/sudo|wheel/ {print $1;}' /etc/group)"
	__CRYP="$(openssl passwd -6 "${__PAWD}")"
	__OPTN=(
		--create-home
		--user-group
		${__CRYP:+--password "${__CRYP}"}
		${__SUDO:+--groups "${__SUDO}"}
		${__SHEL:+--shell "${__SHEL}"}
		"${__USER:?}"
	)
	if ! useradd "${__OPTN[@]}"; then
		__RTCD="$?"
		fnMsgout "${_PROG_NAME:-}" "failed" "useradd ${__OPTN[*]}"
		fnMsgout "${_PROG_NAME:-}" "start" "${__SHEL}"
		"${__SHEL:?}"
		fnMsgout "${_PROG_NAME:-}" "complete" "${__SHEL}"
		exit "${__RTCD}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
