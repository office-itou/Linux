# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: apparmor
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_apparmor() {
	__FUNC_NAME="fnSetup_apparmor"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v aa-enabled > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- debug out -----------------------------------------------------------
#	aa-enabled
	aa-status || true

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
