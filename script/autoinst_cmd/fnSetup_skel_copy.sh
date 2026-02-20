# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: copy skeleton to user
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_skel_copy() {
	__FUNC_NAME="fnSetup_skel_copy"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check directory -----------------------------------------------------
	__SKEL="${_DIRS_TGET:-}/etc/skel"
	if [ ! -e "${__SKEL:?}"/. ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- distribute to existing users ----------------------------------------
	for __DIRS in "${_DIRS_TGET:-}"/root \
	              "${_DIRS_TGET:-}"/home/*
	do
		if [ ! -e "${__DIRS}/." ]; then
			continue
		fi
		cp --preserve=timestamps --recursive "${__SKEL:?}"/. "${__DIRS:?}"/
		chown --recursive "${__DIRS##*/}": "${__DIRS:?}"/
		fnFile_backup "${__DIRS:?}" "init"	# backup initial file
	done
	unset __PATH __CONF __DIRS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
