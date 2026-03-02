# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: locale
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_locale() {
	__FUNC_NAME="fnSetup_locale"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- /etc/default/keyboard -----------------------------------------------
	__CONF="${_DIRS_TGET:-}/etc/default/keyboard"
	fnFile_backup "${__CONF}"			# backup original file
	mkdir -p "${__CONF%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__CONF#*"${_DIRS_TGET:-}/"}" "${__CONF}"
	sed -i "${__CONF}" \
	    -e '/XKBMODEL/   s/=.*$/="pc105"/' \
	    -e '/XKBLAYOUT/  s/=.*$/="jp"/' \
	    -e '/XKBVARIANT/ s/=.*$/=""/' \
	    -e '/XKBOPTIONS/ s/=.*$/=""/' \
	    -e '/BACKSPACE/  s/=.*$/="guess"/'
	fnDbgdump "${__CONF}"				# debugout
	fnFile_backup "${__CONF}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
