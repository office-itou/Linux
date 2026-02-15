# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: desktop
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_desktop() {
	__FUNC_NAME="fnSetup_desktop"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check directory -----------------------------------------------------
	for __FILE in \
		blueman-manager.desktop \
		vim.desktop
	do
		__PATH="${_DIRS_TGET:-}/usr/share/gnome/applications/${__FILE:?}"
		if [ ! -e "${__PATH}" ]; then
			continue
		fi
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -i "${__PATH}"              \
		    -e '/^NoDisplay=.*/ s/^/#/'
		fnFile_backup "${__PATH}" "init"	# backup initial file
	done
	unset __FILE __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
