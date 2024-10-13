#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

#	readonly    PROG_PATH="$0"
	readonly    PROG_PATH="9999-user-conf-setup.sh"
#	readonly    PROG_DIRS="${PROG_PATH%/*}"
	readonly    PROG_NAME="${PROG_PATH##*/}"

	# --- start -------------------------------------------------------------------
	if [ -f "/var/lib/live/config/${PROG_NAME%.*}" ]; then
		# shellcheck disable=SC2028
		printf "\033[m\033[41malready runned: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1
		return
	fi

	printf "\033[m\033[45mstart: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1
	_DISTRIBUTION="$(lsb_release -is | tr '[:upper:]' '[:lower:]' | sed -e 's| |-|g')"
	_RELEASE="$(lsb_release -rs | tr '[:upper:]' '[:lower:]')"
	_CODENAME="$(lsb_release -cs | tr '[:upper:]' '[:lower:]')"
	printf "\033[m\033[93m%s\033[m\n" "setup: ${_DISTRIBUTION:-} ${_RELEASE:-} ${_CODENAME:-}" | tee /dev/console 2>&1

	# --- function systemctl ------------------------------------------------------
#	funcSystemctl () {
#		_OPTIONS="$1"
#		_COMMAND="$2"
#		_UNITS="$3"
#		_PARM="$(echo "${_UNITS}" | sed -e 's/ /|/g')"
#		# shellcheck disable=SC2086
#		_RETURN_VALUE="$(systemctl ${_OPTIONS} list-unit-files ${_UNITS} | awk '$0~/'"${_PARM}"'/ {print $1;}')"
#		if [ -n "${_RETURN_VALUE:-}" ]; then
#			# shellcheck disable=SC2086
#			systemctl ${_OPTIONS} "${_COMMAND}" ${_RETURN_VALUE}
#		fi
#	}

	# --- function is package -----------------------------------------------------
	funcIsPackage () {
		LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
	}

	# --- set hostname parameter ----------------------------------------------
	if [ -n "${LIVE_HOSTNAME:-}" ]; then
		echo "set hostname parameter: ${LIVE_HOSTNAME}" | tee /dev/console 2>&1
#		hostnamectl hostname "${LIVE_HOSTNAME}"
		_FILE_PATH="/etc/hostname"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			${LIVE_HOSTNAME}
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
	fi

	# --- set ssh parameter ---------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'openssh-server'); then
		echo "set ssh parameter" | tee /dev/console 2>&1
		_CONF_FLAG="no"
		if [ -z "${LIVE_USERNAME:-}" ]; then
			_CONF_FLAG="yes"
			if [ -z "${LIVE_PASSWORD:-}" ]; then
				passwd --delete root
			else
				_RETURN_VALUE="$(echo "${LIVE_PASSWORD}" | openssl passwd -6 -stdin)"
				usermod --password "${_RETURN_VALUE}" root
			fi
		fi
		_FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
		echo "set ssh parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			PasswordAuthentication yes
			PermitRootLogin ${_CONF_FLAG}
		
_EOT_
		chmod 600 "${_FILE_PATH}"
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
	fi

	# --- set auto login parameter [ lightdm ] --------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'lightdm'); then
		echo "set auto login parameter: lightdm" | tee /dev/console 2>&1
		_PROG_PATH="/etc/lightdm/lightdm_display.sh"
		_FILE_PATH="/etc/lightdm/lightdm.conf.d/autologin.conf"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[Seat:*]
			autologin-user=${LIVE_USERNAME:-root}
			autologin-user-timeout=0
_EOT_
	fi

	# --- set auto login parameter [ gdm3 ] -----------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'gdm3'); then
		echo "set auto login parameter: gdm3" | tee /dev/console 2>&1
		_GDM3_OPTIONS="$(
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
				AutomaticLoginEnable=true
				AutomaticLogin=${LIVE_USERNAME:-root}
				#TimedLoginEnable=true
				#TimedLogin=${LIVE_USERNAME:-root}
				#TimedLoginDelay=5
				
_EOT_
		)"
		_CONF_FLAG=""
		grep -l 'AutomaticLoginEnable[ \t]*=[ \t]*true' /etc/gdm3/*.conf | while IFS= read -r _FILE_PATH
		do
			sed -i "${_FILE_PATH}"             \
			    -e '/^\[daemon\]/,/^\[.*\]/ {' \
			    -e '/^[^#\[]\+/ s/^/#/}'
			if [ -z "${_CONF_FLAG:-}" ]; then
				sed -i "${_FILE_PATH}"                               \
				    -e "s%^\(\[daemon\].*\)$%\1\n${_GDM3_OPTIONS}%"
				_CONF_FLAG="true"
			fi
			# --- debug out -----------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
		done
	fi

	# --- set vmware parameter ------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if [ -n "${LIVE_HGFS}" ] \
	&& $(funcIsPackage 'open-vm-tools'); then
		echo "set vmware parameter" | tee /dev/console 2>&1
		mkdir -p "${LIVE_HGFS}"
		chmod a+w "${LIVE_HGFS}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> /etc/fstab
			.host:/ ${LIVE_HGFS} fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,users 0 0
_EOT_
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> /etc/fuse.conf
			user_allow_other
_EOT_
		systemctl daemon-reload
		mount "${LIVE_HGFS}"
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< /etc/fstab     tee /dev/console 2>&1
			< /etc/fuse.conf tee /dev/console 2>&1
		fi
	fi

	# --- set gnome parameter -------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'dconf-cli'); then
		echo "set gnome parameter" | tee /dev/console 2>&1
		# --- create dconf db -------------------------------------------------
		_FILE_PATH="/etc/dconf/db/local.d/00-user-settings"
		mkdir -p "${_FILE_PATH%/*}"
		: > "${_FILE_PATH}"
		# --- session ---------------------------------------------------------
		echo "set gnome parameter: session" | tee /dev/console 2>&1
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			[org/gnome/desktop/session]
			idle-delay=uint32 0
			
_EOT_
		# --- gnome terminal --------------------------------------------------
		# shellcheck disable=SC2091,SC2310
		if $(funcIsPackage 'gnome-terminal') \
		&& command -v gsettings > /dev/null 2>&1; then
			echo "set gnome parameter: terminal" | tee /dev/console 2>&1
			_UUID="$(gsettings get org.gnome.Terminal.ProfilesList default | sed -e 's/'\''//g')"
			if [ -n "${_UUID:-}" ]; then
				echo "set gnome parameter: terminal: ${_UUID}" | tee /dev/console 2>&1
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
					[org/gnome/terminal/legacy/profiles:/:${_UUID}]
					default-size-columns=120
					default-size-rows=30
					use-system-font=false
					font='Monospace 9'
					
_EOT_
			fi
		fi
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
		# --- create dconf profile --------------------------------------------
		_PROF_PATH="/etc/dconf/profile/user"
		mkdir -p "${_PROF_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PROF_PATH}"
			user-db:user
			system-db:local
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_PROF_PATH}" tee /dev/console 2>&1
		fi
		# --- dconf update ----------------------------------------------------
		echo "set gnome parameter: dconf compile" | tee /dev/console 2>&1
		dconf compile "${_FILE_PATH%.*}" "${_FILE_PATH%/*}"
	fi

	# --- skeleton directory --------------------------------------------------
	echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
	_DIRS_SKEL="/etc/skel"
	_DIRS_XDGS="/etc/xdg"

	# --- set lxde panel ------------------------------------------------------
	_FILE_PATH="lxpanel/LXDE/panels/panel"
	_XDGS_PATH="${_DIRS_XDGS}/${_FILE_PATH}"
	_CONF_PATH="${_DIRS_SKEL}/.config/${_FILE_PATH}"
	if [ -f "${_XDGS_PATH}" ]; then
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_CONF_PATH%/*}"
		sed -e '/^Global {$/,/^}$/ {'              \
		    -e '/^# *widthtype=/ s/=.*$/=request/' \
		    -e '}'                                 \
		       "${_XDGS_PATH}"                     \
		>      "${_CONF_PATH}"
	fi

	# --- set lxde desktop.conf -----------------------------------------------
	_FILE_PATH="lxsession/LXDE/desktop.conf"
	_XDGS_PATH="${_DIRS_XDGS}/${_FILE_PATH}"
	_CONF_PATH="${_DIRS_SKEL}/.config/${_FILE_PATH}"
	if [ -f "${_XDGS_PATH}" ]; then
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_CONF_PATH%/*}"
		sed -e '/^\[GTK\]$/,/^\[.*\]$/{'                         \
		    -e ':l;'                                             \
		    -e '/^#* *sNet\/ThemeName/     s/=.*$/=Raleigh/'     \
		    -e '/^#* *sNet\/IconThemeName/ s/=.*$/=gnome-brave/' \
		    -e '/^#* *sGtk\/FontName=/     s/=.*$/=Sans 9/'      \
		    -e 'n'                                               \
		    -e '/^\(\[.*\]\|\)$/!b l'                            \
		    -e 'i sGtk/CursorThemeName=Adwaita'                  \
		    -e '}'                                               \
		       "${_XDGS_PATH}"                                   \
		>      "${_CONF_PATH}"
	fi

	# --- set lxterminal.conf -------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'vim'); then
		_FILE_PATH="${_DIRS_SKEL}/.config/lxterminal/lxterminal.conf"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[general]
			fontname=Monospace 9
			selchars=-A-Za-z0-9,./?%&#:_
			scrollback=1000
			bgcolor=rgb(0,0,0)
			fgcolor=rgb(211,215,207)
			palette_color_0=rgb(0,0,0)
			palette_color_1=rgb(205,0,0)
			palette_color_2=rgb(78,154,6)
			palette_color_3=rgb(196,160,0)
			palette_color_4=rgb(52,101,164)
			palette_color_5=rgb(117,80,123)
			palette_color_6=rgb(6,152,154)
			palette_color_7=rgb(211,215,207)
			palette_color_8=rgb(85,87,83)
			palette_color_9=rgb(239,41,41)
			palette_color_10=rgb(138,226,52)
			palette_color_11=rgb(252,233,79)
			palette_color_12=rgb(114,159,207)
			palette_color_13=rgb(173,127,168)
			palette_color_14=rgb(52,226,226)
			palette_color_15=rgb(238,238,236)
			color_preset=Tango
			disallowbold=false
			boldbright=false
			cursorblinks=false
			cursorunderline=false
			audiblebell=false
			visualbell=false
			tabpos=top
			geometry_columns=120
			geometry_rows=30
			hidescrollbar=false
			hidemenubar=false
			hideclosebutton=false
			hidepointer=false
			disablef10=false
			disablealt=false
			disableconfirm=false
			
			[shortcut]
			new_window_accel=<Primary><Shift>n
			new_tab_accel=<Primary><Shift>t
			close_tab_accel=<Primary><Shift>w
			close_window_accel=<Primary><Shift>q
			copy_accel=<Primary><Shift>c
			paste_accel=<Primary><Shift>v
			name_tab_accel=<Primary><Shift>i
			previous_tab_accel=<Primary>Page_Up
			next_tab_accel=<Primary>Page_Down
			move_tab_left_accel=<Primary><Shift>Page_Up
			move_tab_right_accel=<Primary><Shift>Page_Down
			zoom_in_accel=<Primary><Shift>plus
			zoom_out_accel=<Primary><Shift>underscore
			zoom_reset_accel=<Primary><Shift>parenright
_EOT_
	fi

	# --- set libfm.conf ------------------------------------------------------
	_FILE_PATH="libfm/libfm.conf"
	_XDGS_PATH="${_DIRS_XDGS}/${_FILE_PATH}"
	_CONF_PATH="${_DIRS_SKEL}/.config/${_FILE_PATH}"
	if [ -f "${_XDGS_PATH}" ]; then
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_CONF_PATH%/*}"
		sed -e '/^\[GTK\]$/,/^\[.*\]$/{'                         \
		    -e '/^#* *sNet\/ThemeName/     s/=.*$/=Raleigh/'     \
		    -e '/^#* *sNet\/IconThemeName/ s/=.*$/=gnome-brave/' \
		    -e '/^#* *sGtk\/FontName=/     s/=.*$/=Sans 9/'      \
		    -e '}'                                               \
		       "${_XDGS_PATH}"                                   \
		>      "${_CONF_PATH}"
	fi

	# --- set lxde-rc.xml -----------------------------------------------------
	_FILE_PATH="openbox/lxde-rc.xml"
	_XDGS_PATH="${_DIRS_XDGS}/openbox/LXDE/rc.xml"
	_CONF_PATH="${_DIRS_SKEL}/.config/${_FILE_PATH}"
	if [ -f "${_XDGS_PATH}" ]; then
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_CONF_PATH%/*}"
		cp "${_XDGS_PATH}" "${_CONF_PATH}"
		# --- edit xml file ---------------------------------------------------
		_NAME_SPCE="http://openbox.org/3.4/rc"
		_XMLS_PATH="//N:openbox_config/N:theme"
		# --- update ------------------------------------------------------------------
		COUNT="$(xmlstarlet sel -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}" -v "count(N:font)" "${_CONF_PATH}")"
		: $((I=1))
		while [ $((I<=COUNT)) -ne 0 ]
		do
			_NAME="$(xmlstarlet sel   -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}/N:font[${I}]"        -v "N:name"  "${_CONF_PATH}" |  sed -e 's/^\(.\)\(.*\)$/\U\1\L\2/g' || true)"
		#	_SIZE="$(xmlstarlet sel   -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}/N:font[${I}]"        -v "N:size"  "${_CONF_PATH}" || true)"
			         xmlstarlet ed -L -N N="${_NAME_SPCE}"    -u "${_XMLS_PATH}/N:font[${I}]/N:name" -v "${_NAME}"                        \
			                                                  -u "${_XMLS_PATH}/N:font[${I}]/N:size" -v "9"       "${_CONF_PATH}" || true
			I=$((I+1))
		done
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -u "${_XMLS_PATH}/N:name" -v "Clearlooks-3.4" "${_CONF_PATH}" || true
		# --- append ------------------------------------------------------------------
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}"                -t "elem" -n "font"                                "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "ActiveOnScreenDisplay"   \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}"                -t "elem" -n "font"                                "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "InactiveOnScreenDisplay" \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${_CONF_PATH}" || true
	fi

	# --- set gtk-2.0 ---------------------------------------------------------
	if [ -d /etc/gtk-2.0/. ]; then
		_FILE_PATH="${_DIRS_SKEL}/.gtkrc-2.0"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			# DO NOT EDIT! This file will be overwritten by LXAppearance.
			# Any customization should be done in ~/.gtkrc-2.0.mine instead.
			
			include "${HOME}/.gtkrc-2.0.mine"
			gtk-theme-name="Raleigh"
			gtk-icon-theme-name="gnome-brave"
			gtk-font-name="Sans 9"
			gtk-cursor-theme-name="Adwaita"
			gtk-cursor-theme-size=18
			gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
			gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
			gtk-button-images=1
			gtk-menu-images=1
			gtk-enable-event-sounds=1
			gtk-enable-input-feedback-sounds=1
			gtk-xft-antialias=1
			gtk-xft-hinting=1
			gtk-xft-hintstyle="hintslight"
			gtk-xft-rgba="rgb"
_EOT_
	fi

	# --- set gtk-3.0 ---------------------------------------------------------
	if [ -d /etc/gtk-3.0/. ]; then
		_FILE_PATH="${_DIRS_SKEL}/.config/gtk-3.0/settings.ini"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			[Settings]
			gtk-theme-name=Raleigh
			gtk-icon-theme-name=gnome-brave
			gtk-font-name=Sans 9
			gtk-cursor-theme-size=18
			gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
			gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
			gtk-button-images=1
			gtk-menu-images=1
			gtk-enable-event-sounds=1
			gtk-enable-input-feedback-sounds=1
			gtk-xft-antialias=1
			gtk-xft-hinting=1
			gtk-xft-hintstyle=hintslight
			gtk-xft-rgba=rgb
			gtk-cursor-theme-name=Adwaita
_EOT_
	fi

	# --- set .bashrc ---------------------------------------------------------
	_FILE_PATH="${_DIRS_SKEL}/.bashrc"
	echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		# --- user custom ---
		alias vi='vim'
		alias view='vim'
		alias diff='diff --color=auto'
		alias ip='ip -color=auto'
		alias ls='ls --color=auto'
		# --- measures against garbled characters ---
		case "${TERM}" in
		    linux ) export LANG=C;;
		    *     )              ;;
		esac
_EOT_

	# --- set .vimrc ----------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'vim'); then
		_FILE_PATH="${_DIRS_SKEL}/.vimrc"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			set number              " Print the line number in front of each line.
			set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
			set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
			set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
			set nowrap              " This option changes how text is displayed.
			set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
			set laststatus=2        " The value of this option influences when the last window will have a status line always.
			set mouse-=a            " Disable mouse usage
			syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
	fi

	# --- set .curlrc ---------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		_FILE_PATH="${_DIRS_SKEL}/.curlrc"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
	fi

	# --- set .xscreensaver ---------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'xscreensaver'); then
		_FILE_PATH="${_DIRS_SKEL}/.xscreensaver"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			mode:		off
			selected:	-1
_EOT_
	fi

	# --- set fcitx5 ----------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'fcitx5'); then
		_FILE_PATH="${_DIRS_SKEL}/.config/fcitx5/profile"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[Groups/0]
			# Group Name
			Name=デフォルト
			# Layout
			Default Layout=${LIVE_KEYBOARD_LAYOUTS:-us}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
			# Default Input Method
			DefaultIM=mozc
			
			[Groups/0/Items/0]
			# Name
			Name=keyboard-${LIVE_KEYBOARD_LAYOUTS:-us}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
			# Layout
			Layout=
			
			[Groups/0/Items/1]
			# Name
			Name=mozc
			# Layout
			Layout=
			
			[GroupOrder]
			0=デフォルト
			
_EOT_
	fi

	# --- set monitors.xml ----------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if [ -n "${LIVE_XORG_RESOLUTION:-}" ]   \
	&& $(funcIsPackage 'open-vm-tools')     \
	&& $(funcIsPackage 'gdm3');              then
#	&& $(funcIsPackage 'x11-xserver-utils') \
#	&& $(funcIsPackage 'edid-decode')       \
		_FILE_PATH="${_DIRS_SKEL}/.config/monitors.xml"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		_WIDTH="${LIVE_XORG_RESOLUTION%%x*}"
		_HEIGHT="${LIVE_XORG_RESOLUTION#*x}"
		_CONNECTOR="$(grep -HE '^connected$' /sys/class/drm/*Virtual*/status | sed -ne 's/^.*\(Virtual[0-9-]\+\).*$/\1/gp')"
#		_RATE="$(edid-decode --list-dmts 2> /dev/null | awk '$3=='\""${_WIDTH:?}"x"${_HEIGHT:?}"\"' {printf("%.3f", $4); exit;}' || true)"
		_RATE="$(
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | awk '$3=='\""${_WIDTH}"'x'"${_HEIGHT}"\"'&&$0!~/RB/ {printf("%.3f",$4); exit;}'
				DMT 0x01:   640x350    85.079948 Hz  64:35    37.861 kHz     31.500000 MHz
				DMT 0x02:   640x400    85.079948 Hz  16:10    37.861 kHz     31.500000 MHz (STD: 0x31 0x19)
				DMT 0x03:   720x400    85.038902 Hz   9:5     37.927 kHz     35.500000 MHz
				DMT 0x04:   640x480    59.940476 Hz   4:3     31.469 kHz     25.175000 MHz (STD: 0x31 0x40)
				DMT 0x05:   640x480    72.808802 Hz   4:3     37.861 kHz     31.500000 MHz (STD: 0x31 0x4c)
				DMT 0x06:   640x480    75.000000 Hz   4:3     37.500 kHz     31.500000 MHz (STD: 0x31 0x4f)
				DMT 0x07:   640x480    85.008312 Hz   4:3     43.269 kHz     36.000000 MHz (STD: 0x31 0x59)
				DMT 0x08:   800x600    56.250000 Hz   4:3     35.156 kHz     36.000000 MHz
				DMT 0x09:   800x600    60.316541 Hz   4:3     37.879 kHz     40.000000 MHz (STD: 0x45 0x40)
				DMT 0x0a:   800x600    72.187572 Hz   4:3     48.077 kHz     50.000000 MHz (STD: 0x45 0x4c)
				DMT 0x0b:   800x600    75.000000 Hz   4:3     46.875 kHz     49.500000 MHz (STD: 0x45 0x4f)
				DMT 0x0c:   800x600    85.061274 Hz   4:3     53.674 kHz     56.250000 MHz (STD: 0x45 0x59)
				DMT 0x0d:   800x600   119.971829 Hz   4:3     76.302 kHz     73.250000 MHz (RB)
				DMT 0x0e:   848x480    60.000427 Hz  16:9     31.020 kHz     33.750000 MHz
				DMT 0x0f:  1024x768i   86.957532 Hz   4:3     35.522 kHz     44.900000 MHz
				DMT 0x10:  1024x768    60.003840 Hz   4:3     48.363 kHz     65.000000 MHz (STD: 0x61 0x40)
				DMT 0x11:  1024x768    70.069359 Hz   4:3     56.476 kHz     75.000000 MHz (STD: 0x61 0x4c)
				DMT 0x12:  1024x768    75.028582 Hz   4:3     60.023 kHz     78.750000 MHz (STD: 0x61 0x4f)
				DMT 0x13:  1024x768    84.996690 Hz   4:3     68.677 kHz     94.500000 MHz (STD: 0x61 0x59)
				DMT 0x14:  1024x768   119.988531 Hz   4:3     97.551 kHz    115.500000 MHz (RB)
				DMT 0x15:  1152x864    75.000000 Hz   4:3     67.500 kHz    108.000000 MHz (STD: 0x71 0x4f)
				DMT 0x55:  1280x720    60.000000 Hz  16:9     45.000 kHz     74.250000 MHz (STD: 0x81 0xc0)
				DMT 0x16:  1280x768    59.994726 Hz   5:3     47.396 kHz     68.250000 MHz (RB, CVT: 0x7f 0x1c 0x21)
				DMT 0x17:  1280x768    59.870228 Hz   5:3     47.776 kHz     79.500000 MHz (CVT: 0x7f 0x1c 0x28)
				DMT 0x18:  1280x768    74.893062 Hz   5:3     60.289 kHz    102.250000 MHz (CVT: 0x7f 0x1c 0x44)
				DMT 0x19:  1280x768    84.837055 Hz   5:3     68.633 kHz    117.500000 MHz (CVT: 0x7f 0x1c 0x62)
				DMT 0x1a:  1280x768   119.798073 Hz   5:3     97.396 kHz    140.250000 MHz
				DMT 0x1b:  1280x800    59.909545 Hz  16:10    49.306 kHz     71.000000 MHz (RB, CVT: 0x8f 0x18 0x21)
				DMT 0x1c:  1280x800    59.810326 Hz  16:10    49.702 kHz     83.500000 MHz (STD: 0x81 0x00, CVT: 0x8f 0x18 0x28)
				DMT 0x1d:  1280x800    74.934142 Hz  16:10    62.795 kHz    106.500000 MHz (STD: 0x81 0x0f, CVT: 0x8f 0x18 0x44)
				DMT 0x1e:  1280x800    84.879879 Hz  16:10    71.554 kHz    122.500000 MHz (STD: 0x81 0x19, CVT: 0x8f 0x18 0x62)
				DMT 0x1f:  1280x800   119.908501 Hz  16:10   101.562 kHz    146.250000 MHz (RB)
				DMT 0x20:  1280x960    60.000000 Hz   4:3     60.000 kHz    108.000000 MHz (STD: 0x81 0x40)
				DMT 0x21:  1280x960    85.002473 Hz   4:3     85.938 kHz    148.500000 MHz (STD: 0x81 0x59)
				DMT 0x22:  1280x960   119.837758 Hz   4:3    121.875 kHz    175.500000 MHz (RB)
				DMT 0x23:  1280x1024   60.019740 Hz   5:4     63.981 kHz    108.000000 MHz (STD: 0x81 0x80)
				DMT 0x24:  1280x1024   75.024675 Hz   5:4     79.976 kHz    135.000000 MHz (STD: 0x81 0x8f)
				DMT 0x25:  1280x1024   85.024098 Hz   5:4     91.146 kHz    157.500000 MHz (STD: 0x81 0x99)
				DMT 0x26:  1280x1024  119.958231 Hz   5:4    130.035 kHz    187.250000 MHz (RB)
				DMT 0x27:  1360x768    60.015162 Hz  85:48    47.712 kHz     85.500000 MHz
				DMT 0x28:  1360x768   119.966660 Hz  85:48    97.533 kHz    148.250000 MHz (RB)
				DMT 0x51:  1366x768    59.789541 Hz  85:48    47.712 kHz     85.500000 MHz
				DMT 0x56:  1366x768    60.000000 Hz  85:48    48.000 kHz     72.000000 MHz (RB)
				DMT 0x29:  1400x1050   59.947768 Hz   4:3     64.744 kHz    101.000000 MHz (RB, CVT: 0x0c 0x20 0x21)
				DMT 0x2a:  1400x1050   59.978442 Hz   4:3     65.317 kHz    121.750000 MHz (STD: 0x90 0x40, CVT: 0x0c 0x20 0x28)
				DMT 0x2b:  1400x1050   74.866680 Hz   4:3     82.278 kHz    156.000000 MHz (STD: 0x90 0x4f, CVT: 0x0c 0x20 0x44)
				DMT 0x2c:  1400x1050   84.959958 Hz   4:3     93.881 kHz    179.500000 MHz (STD: 0x90 0x59, CVT: 0x0c 0x20 0x62)
				DMT 0x2d:  1400x1050  119.904077 Hz   4:3    133.333 kHz    208.000000 MHz (RB)
				DMT 0x2e:  1440x900    59.901458 Hz  16:10    55.469 kHz     88.750000 MHz (RB, CVT: 0xc1 0x18 0x21)
				DMT 0x2f:  1440x900    59.887445 Hz  16:10    55.935 kHz    106.500000 MHz (STD: 0x95 0x00, CVT: 0xc1 0x18 0x28)
				DMT 0x30:  1440x900    74.984427 Hz  16:10    70.635 kHz    136.750000 MHz (STD: 0x95 0x0f, CVT: 0xc1 0x18 0x44)
				DMT 0x31:  1440x900    84.842118 Hz  16:10    80.430 kHz    157.000000 MHz (STD: 0x95 0x19, CVT: 0xc1 0x18 0x68)
				DMT 0x32:  1440x900   119.851784 Hz  16:10   114.219 kHz    182.750000 MHz (RB)
				DMT 0x53:  1600x900    60.000000 Hz  16:9     60.000 kHz    108.000000 MHz (RB, STD: 0xa9 0xc0)
				DMT 0x33:  1600x1200   60.000000 Hz   4:3     75.000 kHz    162.000000 MHz (STD: 0xa9 0x40)
				DMT 0x34:  1600x1200   65.000000 Hz   4:3     81.250 kHz    175.500000 MHz (STD: 0xa9 0x45)
				DMT 0x35:  1600x1200   70.000000 Hz   4:3     87.500 kHz    189.000000 MHz (STD: 0xa9 0x4a)
				DMT 0x36:  1600x1200   75.000000 Hz   4:3     93.750 kHz    202.500000 MHz (STD: 0xa9 0x4f)
				DMT 0x37:  1600x1200   85.000000 Hz   4:3    106.250 kHz    229.500000 MHz (STD: 0xa9 0x59)
				DMT 0x38:  1600x1200  119.917209 Hz   4:3    152.415 kHz    268.250000 MHz (RB)
				DMT 0x39:  1680x1050   59.883253 Hz  16:10    64.674 kHz    119.000000 MHz (RB, CVT: 0x0c 0x28 0x21)
				DMT 0x3a:  1680x1050   59.954250 Hz  16:10    65.290 kHz    146.250000 MHz (STD: 0xb3 0x00, CVT: 0x0c 0x28 0x28)
				DMT 0x3b:  1680x1050   74.892027 Hz  16:10    82.306 kHz    187.000000 MHz (STD: 0xb3 0x0f, CVT: 0x0c 0x28 0x44)
				DMT 0x3c:  1680x1050   84.940512 Hz  16:10    93.859 kHz    214.750000 MHz (STD: 0xb3 0x19, CVT: 0x0c 0x28 0x68)
				DMT 0x3d:  1680x1050  119.985533 Hz  16:10   133.424 kHz    245.500000 MHz (RB)
				DMT 0x3e:  1792x1344   59.999789 Hz   4:3     83.640 kHz    204.750000 MHz (STD: 0xc1 0x40)
				DMT 0x3f:  1792x1344   74.996724 Hz   4:3    106.270 kHz    261.000000 MHz (STD: 0xc1 0x4f)
				DMT 0x40:  1792x1344  119.973532 Hz   4:3    170.722 kHz    333.250000 MHz (RB)
				DMT 0x41:  1856x1392   59.995184 Hz   4:3     86.333 kHz    218.250000 MHz (STD: 0xc9 0x40)
				DMT 0x42:  1856x1392   75.000000 Hz   4:3    112.500 kHz    288.000000 MHz (STD: 0xc9 0x4f)
				DMT 0x43:  1856x1392  120.051132 Hz   4:3    176.835 kHz    356.500000 MHz (RB)
				DMT 0x52:  1920x1080   60.000000 Hz  16:9     67.500 kHz    148.500000 MHz (STD: 0xd1 0xc0)
				DMT 0x44:  1920x1200   59.950171 Hz  16:10    74.038 kHz    154.000000 MHz (RB, CVT: 0x57 0x28 0x21)
				DMT 0x45:  1920x1200   59.884600 Hz  16:10    74.556 kHz    193.250000 MHz (STD: 0xd1 0x00, CVT: 0x57 0x28 0x28)
				DMT 0x46:  1920x1200   74.930340 Hz  16:10    94.038 kHz    245.250000 MHz (STD: 0xd1 0x0f, CVT: 0x57 0x28 0x44)
				DMT 0x47:  1920x1200   84.931608 Hz  16:10   107.184 kHz    281.250000 MHz (STD: 0xd1 0x19, CVT: 0x57 0x28 0x62)
				DMT 0x48:  1920x1200  119.908612 Hz  16:10   152.404 kHz    317.000000 MHz (RB)
				DMT 0x49:  1920x1440   60.000000 Hz   4:3     90.000 kHz    234.000000 MHz (STD: 0xd1 0x40)
				DMT 0x4a:  1920x1440   75.000000 Hz   4:3    112.500 kHz    297.000000 MHz (STD: 0xd1 0x4f)
				DMT 0x4b:  1920x1440  120.113390 Hz   4:3    182.933 kHz    380.500000 MHz (RB)
				DMT 0x54:  2048x1152   60.000000 Hz  16:9     72.000 kHz    162.000000 MHz (RB, STD: 0xe1 0xc0)
				DMT 0x4c:  2560x1600   59.971589 Hz  16:10    98.713 kHz    268.500000 MHz (RB, CVT: 0x1f 0x38 0x21)
				DMT 0x4d:  2560x1600   59.986588 Hz  16:10    99.458 kHz    348.500000 MHz (CVT: 0x1f 0x38 0x28)
				DMT 0x4e:  2560x1600   74.972193 Hz  16:10   125.354 kHz    443.250000 MHz (CVT: 0x1f 0x38 0x44)
				DMT 0x4f:  2560x1600   84.950918 Hz  16:10   142.887 kHz    505.250000 MHz (CVT: 0x1f 0x38 0x62)
				DMT 0x50:  2560x1600  119.962758 Hz  16:10   203.217 kHz    552.750000 MHz (RB)
				DMT 0x57:  4096x2160   59.999966 Hz 256:135  133.320 kHz    556.744000 MHz (RB)
				DMT 0x58:  4096x2160   59.940046 Hz 256:135  133.187 kHz    556.188000 MHz (RB)
_EOT_
		)"
		if [ -n "${_CONNECTOR:-}" ] && [ -n "${_RATE:-}" ]; then
			if $(funcIsPackage 'xserver-xorg-video-vmware'); then
				_CONNECTOR="$(echo "${_CONNECTOR}" | sed -e 's/-//')"
			fi
			mkdir -p "${_FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				<monitors version="2">
				  <configuration>
				    <logicalmonitor>
				      <x>0</x>
				      <y>0</y>
				      <scale>1</scale>
				      <primary>yes</primary>
				      <monitor>
				        <monitorspec>
				          <connector>${_CONNECTOR:?}</connector>
				          <vendor>unknown</vendor>
				          <product>unknown</product>
				          <serial>unknown</serial>
				        </monitorspec>
				        <mode>
				          <width>${_WIDTH:?}</width>
				          <height>${_HEIGHT:?}</height>
				          <rate>${_RATE:?}</rate>
				        </mode>
				      </monitor>
				    </logicalmonitor>
				  </configuration>
				</monitors>
_EOT_
			if grep -q 'gdm' /etc/passwd; then
				_FILE_CONF="/var/lib/gdm3/.config/${_FILE_PATH##*/}"
				sudo --user=gdm mkdir -p "${_FILE_CONF%/*}"
				cp -p "${_FILE_PATH}" "${_FILE_CONF}"
				chown gdm: "${_FILE_CONF}" 2> /dev/null || /bin/true
			fi
		fi
	fi

	# --- add user ------------------------------------------------------------
	if [ -n "${LIVE_USERNAME:-}" ]; then
		echo "add user: ${LIVE_USERNAME}" | tee /dev/console 2>&1
		_RETURN_VALUE="$(id "${LIVE_USERNAME}" 2> /dev/null)"
		if [ -z "${_RETURN_VALUE:-}" ]; then
			useradd --create-home --shell /bin/bash "${LIVE_USERNAME}"
		fi
		if [ -z "${LIVE_PASSWORD:-}" ]; then
			passwd --delete "${LIVE_USERNAME}"
		else
			_RETURN_VALUE="$(echo "${LIVE_PASSWORD}" | openssl passwd -6 -stdin)"
			usermod --password "${_RETURN_VALUE}" "${LIVE_USERNAME}"
		fi
		# shellcheck disable=SC2091,SC2310
		if $(funcIsPackage 'samba-common-bin'); then
			smbpasswd -a "${LIVE_USERNAME}" -n
			if [ -n "${LIVE_PASSWORD:-}" ]; then
				# shellcheck disable=SC2028
				echo "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | smbpasswd "${LIVE_USERNAME}"
			fi
		fi
		if [ -n "${LIVE_USER_FULLNAME}" ]; then
			usermod --comment "${LIVE_USER_FULLNAME}" "${LIVE_USERNAME}"
		fi
		if [ -n "${LIVE_USER_DEFAULT_GROUPS}" ]; then
			_GROUPS="$(echo "${LIVE_USER_DEFAULT_GROUPS}" | sed -e 's/ /|/g')"
			_GROUPS="$(awk -F ':' '$1~/'"${_GROUPS}"'/ {print $1;}' /etc/group | sed -e ':l; N; s/\n/,/; b l;')"
			if [ -n "${_GROUPS}" ]; then
				usermod --append --groups "${_GROUPS}" "${LIVE_USERNAME}"
			fi
		fi
		passwd --delete root
		# --- set auto login parameter [ console ] ----------------------------
		echo "set auto login parameter: console" | tee /dev/console 2>&1
		_SYSTEMD_DIR="/etc/systemd/system"
		for _NUMBER in $(seq 1 6)
		do
			_FILE_PATH="/etc/systemd/system/getty@tty${_NUMBER}.service.d/live-config_autologin.conf"
			mkdir -p "${_FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				[Service]
				Type=idle
				ExecStart=
				ExecStart=-/sbin/agetty --autologin ${LIVE_USERNAME} --noclear %I \$TERM
_EOT_
		done
		# --- set smb.conf parameter ------------------------------------------
		_FILE_PATH="/etc/samba/smb.conf"
		if [ -f "${_FILE_PATH:-}" ]; then
			echo "set smb.conf parameter" | tee /dev/console 2>&1
			_GROUP="$(id "${LIVE_USERNAME:-}" 2> /dev/null | awk '{print substr($2,index($2,"(")+1,index($2,")")-index($2,"(")-1);}' || true)"
			_GROUP="${_GROUP+"@${_GROUP}"}"
			sed -i "${_FILE_PATH}"                                     \
			    -e '/^;*\[homes\]$/                                 {' \
			    -e ':l;                                             {' \
			    -e 's/^;//;                   s/^ \t/\t/'              \
			    -e '/^[ \t]*read only[ \t]*=/ s/^/;/'                  \
			    -e '/^;*[ \t]*valid users[ \t]*=/a\   write list = %S' \
			    -e '                                                }' \
			    -e 'n; /^;*\[.*\]$/!b l;                            }'
			if [ -n "${LIVE_HGFS:-}" ] && [ -d "${LIVE_HGFS}/." ]; then
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
					[hgfs]
					;  browseable = No
					   comment = VMware shared directories
					   path = ${LIVE_HGFS}
					${_GROUP+"   valid users = ${_GROUP}"}
					${_GROUP+"   write list = ${_GROUP}"}
					
_EOT_
			fi
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
		fi
	fi

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	printf "\033[m\033[45mcomplete: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1

### eof #######################################################################
