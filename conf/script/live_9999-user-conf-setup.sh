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
		for _SESSION in        \
			LXDE               \
			gnome              \
			gnome-xorg         \
			gnome-classic      \
			gnome-classic-xorg \
			lightdm-xsession   \
			openbox
		do
			if [ -f "/usr/share/xsessions/${_SESSION}" ]; then
				_PROG_PATH="/etc/lightdm/lightdm_display.sh"
				_FILE_PATH="/etc/lightdm/lightdm.conf.d/autologin.conf"
				mkdir -p "${_FILE_PATH%/*}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					[Seat:*]
					autologin-user=${LIVE_USERNAME:-root}
					autologin-user-timeout=0
_EOT_
				break
			fi
		done
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
		# --- create dconf profile --------------------------------------------
		_FILE_PATH="/etc/dconf/profile/user"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			user-db:user
			system-db:local
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
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
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
		# --- dconf update ----------------------------------------------------
		echo "set gnome parameter: dconf compile" | tee /dev/console 2>&1
		dconf compile "${_FILE_PATH%.*}" "${_FILE_PATH%/*}"
	fi

#	# --- set 99x11-custom_setup ----------------------------------------------
#	# shellcheck disable=SC2091,SC2310
#	if $(funcIsPackage 'x11-xserver-utils') \
#	&& $(funcIsPackage 'edid-decode')       \
#	&& $(funcIsPackage 'open-vm-tools')     \
#	&& [ -n "${LIVE_XORG_RESOLUTION:-}" ]; then
#		echo "set 99x11-custom_setup" | tee /dev/console 2>&1
#		_FILE_PATH="/etc/X11/Xsession.d/99x11-custom_setup"
#		_LOGS_PATH="/var/log/gdm3/${_FILE_PATH##*/}.log"
#		mkdir -p "${_FILE_PATH%/*}"
#		mkdir -p "${_LOGS_PATH%/*}"
#		{
#			cat <<- _EOT_
#				echo "<info> ${_FILE_PATH##*/}: start" > "${_LOGS_PATH}"
#				_WIDTH="${LIVE_XORG_RESOLUTION%%x*}"
#				_HEIGHT="${LIVE_XORG_RESOLUTION#*x}"
#				_DISTRIBUTION="$(lsb_release -is | tr '[:upper:]' '[:lower:]' | sed -e 's| |-|g')"
#				case "\${_DISTRIBUTION:?}" in
#					debian) _CONNECTOR="Virtual1";;
#					ubuntu) _CONNECTOR="Virtual-1";;
#					*)      return;;
#				esac
#_EOT_
#			cat <<- '_EOT_'
#				_RATE="$(edid-decode --list-dmts | awk '$3=='\""${_WIDTH:?}"x"${_HEIGHT:?}"\"' {printf("%.3f", $4); exit;}')"
#				#_CONNECTOR="$(xrandr | awk '$2=="connected"&&$3=="primary" {print $1;}')"
#				_DIRS_GDM3="/var/lib/gdm3"
#				_FILE_PATH="${_DIRS_GDM3}/.config/monitors.xml"
#_EOT_
#			cat <<- _EOT_
#				{
#				 	echo "<info> ${_FILE_PATH##*/}: connector=\${_CONNECTOR:-}"
#				 	echo "<info> ${_FILE_PATH##*/}: width=\${_WIDTH:-}"
#				 	echo "<info> ${_FILE_PATH##*/}: height=\${_HEIGHT:-}"
#				 	echo "<info> ${_FILE_PATH##*/}: rate=\${_RATE:-} Hz"
#				 	echo "<info> ${_FILE_PATH##*/}: file=\${_FILE_PATH:-}"
#				} | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_LOGS_PATH}"
#_EOT_
#			cat <<- '_EOT_'
#				mkdir -p "${_FILE_PATH%/*}"
#				cat <<- _EOT_MONITORS_XML_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				 	<monitors version="2">
#				 	  <configuration>
#				 	    <logicalmonitor>
#				 	      <x>0</x>
#				 	      <y>0</y>
#				 	      <scale>1</scale>
#				 	      <primary>yes</primary>
#				 	      <monitor>
#				 	        <monitorspec>
#				 	          <connector>${_CONNECTOR:?}</connector>
#				 	          <vendor>unknown</vendor>
#				 	          <product>unknown</product>
#				 	          <serial>unknown</serial>
#				 	        </monitorspec>
#				 	        <mode>
#				 	          <width>${_WIDTH:?}</width>
#				 	          <height>${_HEIGHT:?}</height>
#				 	          <rate>${_RATE:?}</rate>
#				 	        </mode>
#				 	      </monitor>
#				 	    </logicalmonitor>
#				 	  </configuration>
#				 	</monitors>
#				_EOT_MONITORS_XML_
#				chown gdm: -R "${_DIRS_GDM3:?}" 2> /dev/null || /bin/true
#				cp "${_FILE_PATH}" "${HOME}/.config"
#_EOT_
#			cat <<- _EOT_
#				echo "<info> ${_FILE_PATH##*/}: complete" >> "${_LOGS_PATH}"
#_EOT_
#		} | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#	fi

	# --- skeleton directory --------------------------------------------------
	echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
	DIRS_SKEL="/etc/skel"

	# --- set monitors.xml ----------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'x11-xserver-utils') \
	&& $(funcIsPackage 'edid-decode')       \
	&& $(funcIsPackage 'open-vm-tools')     \
	&& [ -n "${LIVE_XORG_RESOLUTION:-}" ]; then
		_FILE_PATH="${DIRS_SKEL}/.config/monitors.xml"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		_WIDTH="${LIVE_XORG_RESOLUTION%%x*}"
		_HEIGHT="${LIVE_XORG_RESOLUTION#*x}"
		_RATE="$(edid-decode --list-dmts | awk '$3=='\""${_WIDTH:?}"x"${_HEIGHT:?}"\"' {printf("%.3f", $4); exit;}')"
#		_CONNECTOR="$(xrandr | awk '$2=="connected"&&$3=="primary" {print $1;}')"
		case "${_DISTRIBUTION:?}" in
			debian) _CONNECTOR="Virtual1";;
			ubuntu) _CONNECTOR="Virtual-1";;
			*)      _CONNECTOR="";;
		esac
		if [ -n "${_CONNECTOR:-}" ]; then
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

	# --- .bashrc -------------------------------------------------------------
	_FILE_PATH="${DIRS_SKEL}/.bashrc"
	echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		# --- measures against garbled characters ---
		case "${TERM}" in
		    linux ) export LANG=C;;
		    *     )              ;;
		esac
_EOT_
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'vim'); then
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			# --- alias for vim ---
			alias vi='vim'
			alias view='vim'
_EOT_
	fi

	# --- .vimrc --------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'vim'); then
		_FILE_PATH="${DIRS_SKEL}/.vimrc"
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

	# --- .curlrc -------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		_FILE_PATH="${DIRS_SKEL}/.curlrc"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
	fi

	# --- .xscreensaver -------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'xscreensaver'); then
		_FILE_PATH="${DIRS_SKEL}/.xscreensaver"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			mode:		off
			selected:	-1
_EOT_
	fi

	# --- fcitx5 --------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'fcitx5'); then
		_FILE_PATH="${DIRS_SKEL}/.config/fcitx5/profile"
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

	# --- libfm.conf ------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'pcmanfm'); then
		_FILE_PATH="${DIRS_SKEL}/.config/libfm/libfm.conf"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			[config]
			single_click=0
			
			[places]
			places_home=1
			places_desktop=1
			places_root=0
			places_computer=1
			places_trash=1
			places_applications=0
			places_network=0
			places_unmounted=1
_EOT_
	fi

	# --- gtkrc-2.0 -----------------------------------------------------------
#	if [ -d /etc/gtk-2.0/. ]; then
#		_FILE_PATH="${DIRS_SKEL}/.gtkrc-2.0"
#		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
#		mkdir -p "${_FILE_PATH%/*}"
#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#			# DO NOT EDIT! This file will be overwritten by LXAppearance.
#			# Any customization should be done in ~/.gtkrc-2.0.mine instead.
#
#			include "${HOME}/.gtkrc-2.0.mine"
#			gtk-theme-name="Raleigh"
#			gtk-icon-theme-name="nuoveXT2"
#			gtk-font-name="Sans 9"
#			gtk-cursor-theme-size=18
#			gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
#			gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
#			gtk-button-images=1
#			gtk-menu-images=1
#			gtk-enable-event-sounds=1
#			gtk-enable-input-feedback-sounds=1
#			gtk-xft-antialias=1
#			gtk-xft-hinting=1
#			gtk-xft-hintstyle="hintslight"
#			gtk-xft-rgba="rgb"
#_EOT_
#	fi

	# --- gtkrc-3.0 -----------------------------------------------------------
	if [ -d /etc/gtk-3.0/. ]; then
		_FILE_PATH="${DIRS_SKEL}/.config/gtk-3.0/settings.ini"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			[Settings]
			gtk-theme-name=Clearlooks
			gtk-icon-theme-name=nuoveXT2
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
_EOT_
	fi

	# --- lxterminal.conf -----------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'lxterminal'); then
		_FILE_PATH="${DIRS_SKEL}/.config/lxterminal/lxterminal.conf"
		echo "set skeleton directory: ${_FILE_PATH}" | tee /dev/console 2>&1
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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

#	# --- set user parameter --------------------------------------------------
#	echo "set user parameter" | tee /dev/console 2>&1
#	for DIRS_NAME in /root /home/*
#	do
#		USER_NAME="${DIRS_NAME##*/}"
#		echo "set user parameter: ${USER_NAME}" | tee /dev/console 2>&1
#		# --- .bashrc ---------------------------------------------------------
#		_FILE_PATH="${DIRS_NAME}/.bashrc"
#		echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#			# --- measures against garbled characters ---
#			case "${TERM}" in
#			    linux ) export LANG=C;;
#			    *     )              ;;
#			esac
#			# --- alias for vim ---
#			alias vi='vim'
#			alias view='vim'
#_EOT_
#		chown "${USER_NAME}": "${_FILE_PATH}"
#		# --- monitors.xml ----------------------------------------------------
#		_FILE_PATH="/var/lib/gdm3/.config/monitors.xml"
#		if [ -f "${_FILE_PATH:-}" ]; then
#			echo "set monitors.xml parameter" | tee /dev/console 2>&1
#			_DIRS_CONF="${DIRS_NAME}/.config"
#			mkdir -p "${_DIRS_CONF:?}" \
#			&& chown "${USER_NAME}": "${_DIRS_CONF:?}"
#			cp -a "${_FILE_PATH}" "${_DIRS_CONF:?}" \
#			&& chown "${USER_NAME}": "${_DIRS_CONF:?}/${_FILE_PATH##*/}"
#		fi
#		# --- fcitx5 ----------------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'fcitx5'); then
#			_FILE_PATH="${DIRS_NAME}/.config/fcitx5/profile"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				[Groups/0]
#				# Group Name
#				Name=デフォルト
#				# Layout
#				Default Layout=${LIVE_KEYBOARD_LAYOUTS:-us}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
#				# Default Input Method
#				DefaultIM=mozc
#				
#				[Groups/0/Items/0]
#				# Name
#				Name=keyboard-${LIVE_KEYBOARD_LAYOUTS:-us}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
#				# Layout
#				Layout=
#				
#				[Groups/0/Items/1]
#				# Name
#				Name=mozc
#				# Layout
#				Layout=
#				
#				[GroupOrder]
#				0=デフォルト
#				
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		# --- gtkrc-2.0 -------------------------------------------------------
#		if [ -d /etc/gtk-2.0/. ]; then
#			_FILE_PATH="${DIRS_NAME}/.gtkrc-2.0.mine"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				#gtk-theme-name="Raleigh"
#				#gtk-icon-theme-name="nuoveXT2"
#				gtk-font-name="Sans 9"
#				#gtk-cursor-theme-size=18
#				#gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
#				#gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
#				#gtk-button-images=1
#				#gtk-menu-images=1
#				#gtk-enable-event-sounds=1
#				#gtk-enable-input-feedback-sounds=1
#				#gtk-xft-antialias=1
#				#gtk-xft-hinting=1
#				#gtk-xft-hintstyle="hintslight"
#				#gtk-xft-rgba="rgb"
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		# --- lxterminal.conf -------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'lxterminal'); then
#			_FILE_PATH="${DIRS_NAME}/.config/lxterminal/lxterminal.conf"
#			_ORIG_CONF="/usr/share/lxterminal/lxterminal.conf"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cp "${_ORIG_CONF}" "${_FILE_PATH}"
#			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				[general]
#				fontname=Monospace 9
#				selchars=-A-Za-z0-9,./?%&#:_
#				scrollback=1000
#				bgcolor=rgb(0,0,0)
#				fgcolor=rgb(211,215,207)
#				palette_color_0=rgb(0,0,0)
#				palette_color_1=rgb(205,0,0)
#				palette_color_2=rgb(78,154,6)
#				palette_color_3=rgb(196,160,0)
#				palette_color_4=rgb(52,101,164)
#				palette_color_5=rgb(117,80,123)
#				palette_color_6=rgb(6,152,154)
#				palette_color_7=rgb(211,215,207)
#				palette_color_8=rgb(85,87,83)
#				palette_color_9=rgb(239,41,41)
#				palette_color_10=rgb(138,226,52)
#				palette_color_11=rgb(252,233,79)
#				palette_color_12=rgb(114,159,207)
#				palette_color_13=rgb(173,127,168)
#				palette_color_14=rgb(52,226,226)
#				palette_color_15=rgb(238,238,236)
#				color_preset=Tango
#				disallowbold=false
#				boldbright=false
#				cursorblinks=false
#				cursorunderline=false
#				audiblebell=false
#				visualbell=false
#				tabpos=top
#				geometry_columns=120
#				geometry_rows=30
#				hidescrollbar=false
#				hidemenubar=false
#				hideclosebutton=false
#				hidepointer=false
#				disablef10=false
#				disablealt=false
#				disableconfirm=false
#				
#				[shortcut]
#				new_window_accel=<Primary><Shift>n
#				new_tab_accel=<Primary><Shift>t
#				close_tab_accel=<Primary><Shift>w
#				close_window_accel=<Primary><Shift>q
#				copy_accel=<Primary><Shift>c
#				paste_accel=<Primary><Shift>v
#				name_tab_accel=<Primary><Shift>i
#				previous_tab_accel=<Primary>Page_Up
#				next_tab_accel=<Primary>Page_Down
#				move_tab_left_accel=<Primary><Shift>Page_Up
#				move_tab_right_accel=<Primary><Shift>Page_Down
#				zoom_in_accel=<Primary><Shift>plus
#				zoom_out_accel=<Primary><Shift>underscore
#				zoom_reset_accel=<Primary><Shift>parenright
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		
#		# --- .vimrc ----------------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'vim'); then
#			_FILE_PATH="${DIRS_NAME}/.vimrc"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				set number              " Print the line number in front of each line.
#				set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
#				set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
#				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
#				set nowrap              " This option changes how text is displayed.
#				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
#				set laststatus=2        " The value of this option influences when the last window will have a status line always.
#				set mouse-=a            " Disable mouse usage
#				syntax on               " Vim5 and later versions support syntax highlighting.
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		# --- .xscreensaver ---------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'xscreensaver'); then
#			_FILE_PATH="${DIRS_NAME}/.xscreensaver"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				mode:		off
#				selected:	-1
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		# --- curl ------------------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'curl'); then
#			_FILE_PATH="${DIRS_NAME}/.curlrc"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				location
#				progress-bar
#				remote-time
#				show-error
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#		# --- libfm.conf ------------------------------------------------------
#		# shellcheck disable=SC2091,SC2310
#		if $(funcIsPackage 'pcmanfm'); then
#			_FILE_PATH="${DIRS_NAME}/.config/libfm/libfm.conf"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				[config]
#				single_click=0
#				
#				[places]
#				places_home=1
#				places_desktop=1
#				places_root=0
#				places_computer=1
#				places_trash=1
#				places_applications=0
#				places_network=0
#				places_unmounted=1
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#		fi
#	done

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	printf "\033[m\033[45mcomplete: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1

### eof #######################################################################
