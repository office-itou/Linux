# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: input method skeleton for ibus
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_skel_im_ibus() {
	___FUNC_NAME="fnSetup_skel_im_ibus"
	fnMsgout "${_PROG_NAME:-}" "start" "[${___FUNC_NAME}]"

	# --- ibus ----------------------------------------------------------------
	if command -v ibus > /dev/null 2>&1; then
		__SRCS="('xkb', 'jp')"
		if [ -d "${_DIRS_TGET:-}"/usr/share/ibus-mozc/. ]; then
			fnMsgout "${_PROG_NAME:-}" "info" "ibus-mozc"
			__SRCS="${__SRCS:+"${__SRCS}, "}('ibus', 'mozc-jp')"
		fi
		if [ -d "${_DIRS_TGET:-}"/usr/share/ibus-anthy/. ]; then
			fnMsgout "${_PROG_NAME:-}" "info" "ibus-anthy"
			__SRCS="${__SRCS:+"${__SRCS}, "}('ibus', 'anthy')"
		fi
		if [ -n "${__SRCS:-}" ]; then
			fnMsgout "${_PROG_NAME:-}" "info" "${__SRCS}"
#			dconf write /org/gnome/desktop/input-sources/sources "[${__SRCS}]"
#			gsettings set org.gnome.desktop.input-sources sources "[${__SRCS}]"
			__OUTP="${_DIRS_TGET:-}/etc/dconf/db/local"
			__PATH="${__OUTP}.d/00-user-desktop-input-sources"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
				[org/gnome/desktop/input-sources]
				sources=[${__SRCS}]
_EOT_
			dconf compile "${__OUTP}" "${__PATH%/*}" || true
		fi
	fi
	unset __SRCS __OUTP

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${___FUNC_NAME}]" 
	unset ___FUNC_NAME
}
