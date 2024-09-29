#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	PROG_PATH="9999-user-conf-setup.sh"
#	PROG_DIRS="${PROG_PATH%/*}"
	PROG_NAME="${PROG_PATH##*/}"

#	# --- function systemctl ------------------------------------------------------
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
#	

	if [ -f "/var/lib/live/config/${PROG_NAME%.*}" ]; then
		# shellcheck disable=SC2028
		echo "\033[m\033[41malready runned: ${PROG_PATH}\033[m" | tee /dev/console 2>&1
		return
	fi

	# shellcheck disable=SC2028
	echo "\033[m\033[45mstart: ${PROG_PATH}\033[m" | tee /dev/console 2>&1

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
	if [ -d /etc/ssh/sshd_config.d/. ]; then
		echo "set ssh parameter" | tee /dev/console 2>&1
		_CONF_FLAG="no"
		if [ -z "${LIVE_USERNAME:-}" ]; then
			_CONF_FLAG="yes"
		fi
		_FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
		echo "set ssh parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
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

	# --- set network parameter -----------------------------------------------
	_RETURN_VALUE="$(command -v nmcli 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set network parameter: nmcli" | tee /dev/console 2>&1
		DIRS_NAME="/etc/netplan"
		if [ -d "${DIRS_NAME}/." ]; then
			echo "set network parameter: nmcli with netplan" | tee /dev/console 2>&1
			_FILE_PATH="${DIRS_NAME}/99-network-manager-all.yaml"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				network:
				  version: 2
				  renderer: NetworkManager
_EOT_
			chmod 600 "${_FILE_PATH}"
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
		fi
	fi

	# --- set bluetooth -------------------------------------------------------
	# https://askubuntu.com/questions/1306723/bluetooth-service-fails-and-freezes-after-some-time-in-ubuntu-18-04
	_RETURN_VALUE="$(command -v rfkill 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		_RETURN_VALUE="$(command -v bluetoothctl 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			echo "set bluetooth parameter" | tee /dev/console 2>&1
			rfkill unblock bluetooth || true
			if lsmod | grep -q -E '^btusb[ \t]'; then
				rmmod btusb || true
				modprobe btusb || true
			fi
		fi
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			rfkill list | tee /dev/console 2>&1
		fi
	fi

	# --- set lxde parameter --------------------------------------------------
	_RETURN_VALUE="$(command -v startlxde 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set lxde parameter" | tee /dev/console 2>&1
		update-alternatives --set "x-session-manager" "/usr/bin/startlxde"
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			update-alternatives --get-selections | grep x-session-manager | tee /dev/console 2>&1
		fi
	fi

	# --- set vmware parameter ------------------------------------------------
	_RETURN_VALUE="$(command -v vmware-checkvm 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ] && [ -n "${LIVE_HGFS}" ]; then
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

	# --- set auto login parameter --------------------------------------------
	if [ -d /etc/gdm3/. ]; then
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
			sed -i "${_FILE_PATH}"              \
			    -e '/^\[daemon\]/,/^\[.*\]/ {' \
			    -e '/^[^#\[]\+/ s/^/#/}' 
			if [ -z "${_CONF_FLAG:-}" ]; then
				sed -i "${_FILE_PATH}"                               \
				    -e "s%^\(\[daemon\].*\)$%\1\n${_GDM3_OPTIONS}%"
				_CONF_FLAG="true"
			fi
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
		done
	fi

	# --- set smb.conf parameter ----------------------------------------------
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
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console 2>&1
		fi
		# --- service processing ----------------------------------------------
		_SERVICES="smbd.service nmbd.service"
#		echo "set smb.conf parameter: try-reload-or-restart services [${_SERVICES}]" | tee /dev/console 2>&1
		# shellcheck disable=SC2086
#		systemctl try-reload-or-restart ${_SERVICES}
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			# shellcheck disable=SC2086
			systemctl status ${_SERVICES} | tee /dev/console 2>&1
		fi
	fi

	# --- set gnome parameter -------------------------------------------------
#	if [ "${LIVE_OS_NAME:-}" = "ubuntu" ]; then
		_RETURN_VALUE="$(command -v dconf 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			echo "set gnome parameter" | tee /dev/console 2>&1
			# --- create dconf profile ----------------------------------------
			_FILE_PATH="/etc/dconf/profile/user"
			mkdir -p "${_FILE_PATH%/*}"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				user-db:user
				system-db:local
_EOT_
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
			# --- create dconf db ---------------------------------------------
			_FILE_PATH="/etc/dconf/db/local.d/00-user-settings"
			mkdir -p "${_FILE_PATH%/*}"
			: > "${_FILE_PATH}"
			# --- session -----------------------------------------------------
			echo "set gnome parameter: session" | tee /dev/console 2>&1
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
				[org/gnome/desktop/session]
				idle-delay=uint32 0
				
_EOT_
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console 2>&1
			fi
			# --- dconf update ------------------------------------------------
#			if systemctl status  dbus.service; then
#				echo "set gnome parameter: dconf update" | tee /dev/console 2>&1
#				dconf update
				echo "set gnome parameter: dconf compile" | tee /dev/console 2>&1
				dconf compile "${_FILE_PATH%.*}" "${_FILE_PATH%/*}"
#			fi
		fi
#	fi

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
			# shellcheck disable=SC2028
			echo "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | passwd "${LIVE_USERNAME}"
		fi
		_RETURN_VALUE="$(command -v smbpasswd 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
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
		# --- auto login ------------------------------------------------------
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
	fi

	# --- set user parameter --------------------------------------------------
	echo "set user parameter" | tee /dev/console 2>&1
	for DIRS_NAME in /root /home/*
	do
		USER_NAME="${DIRS_NAME##*/}"
		echo "set user parameter: ${USER_NAME}" | tee /dev/console 2>&1
		# --- .bashrc ---------------------------------------------------------
		_FILE_PATH="${DIRS_NAME}/.bashrc"
		echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			# --- measures against garbled characters ---
			case "${TERM}" in
			    linux ) export LANG=C;;
			    *     )              ;;
			esac
			# --- alias for vim ---
			alias vi='vim'
			alias view='vim'
_EOT_
		chown "${USER_NAME}": "${_FILE_PATH}"
		# --- monitors.xml ----------------------------------------------------
		if [ -d /etc/gdm3/. ]; then
			_RETURN_VALUE="$(command -v xrandr 2> /dev/null)"
			if [ -n "${_RETURN_VALUE:-}" ]; then
				case "${LIVE_XORG_RESOLUTION:-}" in				# resolution
#					 640x480 ) _RATE="60.000";;					# VGA    (4:3)
					 800x600 ) _RATE="60.317";;					# SVGA   (4:3)
					1024x768 ) _RATE="60.004";;					# XGA    (4:3)
#					1152x864 ) _RATE="60.000";;					#        (4:3)
					1280x720 ) _RATE="60.000";;					# WXGA   (16:9)
					1280x768 ) _RATE="59.995";;					#        (4:3)
					1280x800 ) _RATE="60.000";;					#        (16:10)
					1280x960 ) _RATE="60.940";;					#        (4:3)
					1280x1024) _RATE="60.020";;					# SXGA   (5:4)
					1366x768 ) _RATE="60.000";;					# HD     (16:9)
					1400x1050) _RATE="59.978";;					#        (4:3)
					1440x900 ) _RATE="59.901";;					# WXGA+  (16:10)
					1600x1200) _RATE="60.000";;					# UXGA   (4:3)
					1680x1050) _RATE="59.954";;					# WSXGA+ (16:10)
					1792x1344) _RATE="60.000";;					#        (4:3)
					1856x1392) _RATE="59.995";;					#        (4:3)
					1920x1080) _RATE="60.000";;					# FHD    (16:9)
					1920x1200) _RATE="59.950";;					# WUXGA  (16:10)
					1920x1440) _RATE="60.000";;					#        (4:3)
#					2560x1440) _RATE="60.000";;					# WQHD   (16:9)
#					2560x1600) _RATE="60.000";;					#        (16:10)
#					2880x1800) _RATE="60.000";;					#        (16:10)
#					3840x2160) _RATE="60.000";;					# 4K UHD (16:9)
#					3840x2400) _RATE="60.000";;					#        (16:10)
#					7680x4320) _RATE="60.000";;					# 8K UHD (16:9)
					*        ) _RATE="60.000";;					# 
				esac
				_DIRS_GDM3="var/lib/gdm/.config"
				_FILE_PATH="${DIRS_NAME}/.config/monitors.xml"
				echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
				sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
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
					          <connector>Virtual-1</connector>
					          <vendor>unknown</vendor>
					          <product>unknown</product>
					          <serial>unknown</serial>
					        </monitorspec>
					        <mode>
					          <width>${LIVE_XORG_RESOLUTION%%x*}</width>
					          <height>${LIVE_XORG_RESOLUTION#*x}</height>
					          <rate>${_RATE}</rate>
					        </mode>
					      </monitor>
					    </logicalmonitor>
					  </configuration>
					</monitors>
_EOT_
				chown "${USER_NAME}": "${_FILE_PATH}"
				sudo --user=gdm mkdir -p "${_DIRS_GDM3}"
				cp "${_FILE_PATH}" "${_DIRS_GDM3}"
				chown gdm: "${_DIRS_GDM3}/${_FILE_PATH##*/}"
			fi
		fi
		# --- fcitx5 ----------------------------------------------------------
		_RETURN_VALUE="$(command -v fcitx5 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.config/fcitx5/profile"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
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
			chown "${USER_NAME}": "${_FILE_PATH}"
#			# --- .bash_profile -----------------------------------------------
#			_FILE_PATH="${DIRS_NAME}/.bash_profile"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				export XMODIFIERS=@im=fcitx
#				export GTK_IM_MODULE=fcitx
#				export QT_IM_MODULE=fcitx
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#			# --- .config/gtk-3.0/settings.ini --------------------------------
#			_FILE_PATH="${DIRS_NAME}/.config/gtk-3.0/settings.ini"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				[Settings]
#				gtk-im-module=fcitx
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#			# --- xcb.conf --------------------------------------------------------
#			_FILE_PATH="${DIRS_NAME}/.config/fcitx5/conf/xcb.conf"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				# システム XKB 設定のオーバーライドを許可する
#				Allow Overriding System XKB Settings=False
#				# 常にレイアウトをグループレイアウトのみにする
#				AlwaysSetToGroupLayout=False
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- lxterminal.conf -------------------------------------------------
		_RETURN_VALUE="$(command -v lxterminal 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.config/lxterminal/lxterminal.conf"
			_ORIG_CONF="/usr/share/lxterminal/lxterminal.conf"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
			cp "${_ORIG_CONF}" "${_FILE_PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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
				geometry_columns=80
				geometry_rows=24
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
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		
		# --- .vimrc ----------------------------------------------------------
		_RETURN_VALUE="$(command -v vim 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.vimrc"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
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
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- .xscreensaver ---------------------------------------------------
		_RETURN_VALUE="$(command -v xscreensaver 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.xscreensaver"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				mode:		off
				selected:	-1
_EOT_
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- curl ------------------------------------------------------------
		_RETURN_VALUE="$(command -v curl 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.curlrc"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				location
				progress-bar
				remote-time
				show-error
_EOT_
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- libfm.conf ------------------------------------------------------
		_RETURN_VALUE="$(command -v pcmanfm 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.config/libfm/libfm.conf"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
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
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
#		# --- 50-alsa-config.conf ---------------------------------------------
#		# https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Troubleshooting
#		_RETURN_VALUE="$(command -v wireplumber 2> /dev/null)"
#		if [ -n "${_RETURN_VALUE:-}" ]; then
#			_FILE_PATH="${DIRS_NAME}/.config/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console 2>&1
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				monitor.alsa.rules = [
#				  {
#				    matches = [
#				      # This matches the value of the 'node.name' property of the node.
#				      {
#				        node.name = "~alsa_output.*"
#				      }
#				    ]
#				    actions = {
#				      # Apply all the desired node specific settings here.
#				      update-props = {
#				        api.alsa.period-size   = 1024
#				        api.alsa.headroom      = 8192
#				      }
#				    }
#				  }
#				]
#_EOT_
#		fi
#		# --- reset gnome parameter -------------------------------------------
#		if [ "${LIVE_OS_NAME:-}" = "ubuntu" ]; then
#			_RETURN_VALUE="$(command -v dconf 2> /dev/null)"
#			if [ -n "${_RETURN_VALUE:-}" ]; then
#				echo "reset gnome parameter" | tee /dev/console 2>&1
#				sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/mru-sources
#				sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/sources
#				sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/xkb-options
#			fi
#		fi
#		# --- systemctl user service ------------------------------------------
#		echo "set user parameter: systemctl user service" | tee /dev/console 2>&1
#		_DIRS_SYSD="${DIRS_NAME}/.config/systemd/user"
#		sudo --user="${USER_NAME}" mkdir -p "${_DIRS_SYSD}"
#		for _UNIT in "wireplumber.service"
#		do
#			sudo --user="${USER_NAME}" ln -s /dev/null "${_DIRS_SYSD}/${_UNIT}"
#		done
#		# --- debug out -------------------------------------------------------
#		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
#			systemctl --no-pager --user list-units | tee /dev/console 2>&1
#			find /etc/systemd/user "${_DIRS_SYSD}" -not -type d | sort | tee /dev/console 2>&1 || true
#		fi
	done

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console 2>&1

### eof #######################################################################
