# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: hostname
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_hostname() {
	__FUNC_NAME="fnSetup_hostname"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check fqdn ----------------------------------------------------------
	if [ -z "${_NICS_FQDN:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- hostname ------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/hostname"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	echo "${_NICS_FQDN:-}" > "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
