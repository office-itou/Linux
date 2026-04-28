# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: clamav
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_clamav() {
	__FUNC_NAME="fnSetup_clamav"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v freshclam > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi

	# --- setup ---------------------------------------------------------------
	freshclam || true
#	chown --recursive clamav:clamav /var/log/clamav/              || true
#	chown             clamav:adm    /var/log/clamav/freshclam.log || true

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
