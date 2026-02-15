# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: input method
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_input_method() {
	__FUNC_NAME="fnSetup_input_method"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- fcitx5 --------------------------------------------------------------
	if command -v fcitx5 > /dev/null 2>&1; then
		# https://extensions.gnome.org/extension/261/kimpanel/
		fnMsgout "${_PROG_NAME:-}" "start" "fcitx5"
		# --- im-config -------------------------------------------------------
#		if command -v im-config > /dev/null 2>&1; then
#			im-config -n fcitx5
#		fi
		# --- fcitx.desktop ---------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/xdg/autostart/org.fcitx.Fcitx5.desktop"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[Desktop Entry]
			Name=Fcitx 5
			GenericName=Input Method
			Comment=Start Input Method
			Exec=/usr/bin/fcitx5 -d 2> /dev/null
			Icon=fcitx
			Terminal=false
			Type=Application
			Categories=System;Utility;
			StartupNotify=false
			X-GNOME-AutoRestart=false
			X-GNOME-Autostart-Notify=false
			X-KDE-autostart-after=panel
			X-KDE-StartupNotify=false
			X-KDE-Wayland-VirtualKeyboard=true
			X-KDE-Wayland-Interfaces=org_kde_plasma_window_management
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- complete --------------------------------------------------------
		fnMsgout "${_PROG_NAME:-}" "complete" "fcitx5"
	fi
	unset __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
