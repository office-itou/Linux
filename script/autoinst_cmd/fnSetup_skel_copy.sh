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
		sudo -u "${__DIRS##*/}" cp --preserve=timestamps --recursive --verbose "${__SKEL:?}"/. "${__DIRS:?}"/
		fnFile_backup "${__DIRS:?}"/. "init"	# backup initial file
#		for __FILE in "${_DIRS_TGET:-}/etc/skel/.bashrc"       \
#		              "${_DIRS_TGET:-}/etc/skel/.bash_history" \
#		              "${_DIRS_TGET:-}/etc/skel/.vimrc"        \
#		              "${_DIRS_TGET:-}/etc/skel/.curlrc"
#		do
#			if [ ! -e "${__FILE}" ]; then
#				continue
#			fi
#			__PATH="${__DIRS}/${__FILE#*/etc/skel/}"
#			mkdir -p "${__PATH%/*}"
#			cp --preserve=timestamps "${__FILE}" "${__PATH}"
#			chown "${__DIRS##*/}": "${__PATH}"
#			fnDbgdump "${__PATH}"				# debugout
#			fnFile_backup "${__PATH}" "init"	# backup initial file
#		done
	done
	unset __PATH __CONF __DIRS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
