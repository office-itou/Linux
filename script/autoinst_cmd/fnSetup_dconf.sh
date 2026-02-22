# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: dconf
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_dconf() {
	__FUNC_NAME="fnSetup_dconf"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if command -v dconf > /dev/null 2>&1; then
		__PATH="${_DIRS_TGET:-}/etc/dconf/profile/user"
		if [ ! -f "${__PATH}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				user-db:user
_EOT_
		fi
		if ! grep -qE '^system-db:local$' /etc/dconf/profile/user; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				system-db:local
_EOT_
		fi
		__OUTP="${_DIRS_TGET:-}/etc/dconf/db/local"
		# --- desktop/session -------------------------------------------------
		__PATH="${__OUTP}.d/00-user-desktop-session"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			[org/gnome/desktop/session]
			idle-delay=uint32 0
_EOT_
		# --- terminal --------------------------------------------------------
		__UUID="$(gsettings get org.gnome.Terminal.ProfilesList default | sed -e 's/'\''//g')"
		if [ -n "${__UUID}" ]; then
			__PATH="${__OUTP}.d/00-user-terminal"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				[org/gnome/terminal/legacy/profiles:/:${__UUID}]
				default-size-columns=120
				default-size-rows=30
				font='Monospace 9'
				palette=['rgb(46,52,54)', 'rgb(204,0,0)', 'rgb(78,154,6)', 'rgb(196,160,0)', 'rgb(52,101,164)', 'rgb(117,80,123)', 'rgb(6,152,154)', 'rgb(211,215,207)', 'rgb(85,87,83)', 'rgb(239,41,41)', 'rgb(138,226,52)', 'rgb(252,233,79)', 'rgb(114,159,207)', 'rgb(173,127,168)', 'rgb(52,226,226)', 'rgb(238,238,236)']
				use-system-font=false
_EOT_
		fi
		# --- compile ---------------------------------------------------------
		dconf compile "${__OUTP}" "${__PATH%/*}" || true
	fi
	unset __SRCS __OUTP __UUID

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
