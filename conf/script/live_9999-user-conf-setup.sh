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

	if [ -f "/var/lib/live/config/${PROG_NAME%.*}" ]; then
		# shellcheck disable=SC2028
		echo "\033[m\033[41malready runned: ${PROG_PATH}\033[m" | tee /dev/console
		return
	fi

	# shellcheck disable=SC2028
	echo "\033[m\033[45mstart: ${PROG_PATH}\033[m" | tee /dev/console

	# --- set hostname parameter ----------------------------------------------
	if [ -n "${LIVE_HOSTNAME:-}" ]; then
		echo "set hostname parameter: ${LIVE_HOSTNAME}" | tee /dev/console
#		hostnamectl hostname "${LIVE_HOSTNAME}"
		_FILE_PATH="/etc/hostname"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			${LIVE_HOSTNAME}
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
	fi

	# --- set ssh parameter ---------------------------------------------------
	if [ -d /etc/ssh/sshd_config.d/. ]; then
		echo "set ssh parameter" | tee /dev/console
		_CONF_FLAG="no"
		if [ -z "${LIVE_USERNAME:-}" ]; then
			_CONF_FLAG="yes"
		fi
		_FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
		echo "set ssh parameter: ${_FILE_PATH}" | tee /dev/console
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			PasswordAuthentication yes
			PermitRootLogin ${_CONF_FLAG}
		
_EOT_
		chmod 600 "${_FILE_PATH}"
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
	fi

	# --- set network parameter -----------------------------------------------
	_RETURN_VALUE="$(command -v nmcli 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set network parameter: nmcli" | tee /dev/console
		DIRS_NAME="/etc/netplan"
		if [ -d "${DIRS_NAME}/." ]; then
			echo "set network parameter: nmcli with netplan" | tee /dev/console
			_FILE_PATH="${DIRS_NAME}/99-network-manager-all.yaml"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				network:
				  version: 2
				  renderer: NetworkManager
_EOT_
			chmod 600 "${_FILE_PATH}"
			# --- debug out ---------------------------------------------------
			if [ -n "${LIVE_DEBUGOUT:-}" ]; then
				< "${_FILE_PATH}" tee /dev/console
			fi
		fi
	fi

	# --- set lxde parameter --------------------------------------------------
	_RETURN_VALUE="$(command -v startlxde 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set lxde parameter" | tee /dev/console
		update-alternatives --set "x-session-manager" "/usr/bin/startlxde"
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			update-alternatives --get-selections | grep x-session-manager | tee /dev/console
		fi
	fi

	# --- set vmware parameter ------------------------------------------------
	_RETURN_VALUE="$(command -v vmware-checkvm 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ] && [ -n "${LIVE_HGFS}" ]; then
		echo "set vmware parameter" | tee /dev/console
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
			< /etc/fstab     tee /dev/console
			< /etc/fuse.conf tee /dev/console
		fi
	fi

	# --- set auto login parameter --------------------------------------------
	if [ -d /etc/gdm3/. ]; then
		echo "set auto login parameter: gdm3" | tee /dev/console
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
				< "${_FILE_PATH}" tee /dev/console
			fi
		done
	fi

	# --- set smb.conf parameter ----------------------------------------------
	_FILE_PATH="/etc/samba/smb.conf"
	if [ -f "${_FILE_PATH:-}" ]; then
		echo "set smb.conf parameter" | tee /dev/console
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
			< "${_FILE_PATH}" tee /dev/console
		fi
#		systemctl restart smbd.service nmbd.service
	fi

	# --- set gnome parameter -------------------------------------------------
	_RETURN_VALUE="$(command -v dconf 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set gnome parameter" | tee /dev/console
		# --- create dconf profile --------------------------------------------
		_FILE_PATH="/etc/dconf/profile/user"
		mkdir -p "${_FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
			user-db:user
			system-db:local
_EOT_
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
		# --- create dconf db -------------------------------------------------
		_FILE_PATH="/etc/dconf/db/local.d/00-user-settings"
		mkdir -p "${_FILE_PATH%/*}"
		: > "${_FILE_PATH}"
#		# --- xsettings -------------------------------------------------------
#		_RETURN_VALUE="$(command -v fcitx5 2> /dev/null)"
#		if [ -n "${_RETURN_VALUE:-}" ]; then
#			echo "set gnome parameter: xsettings" | tee /dev/console
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				[org/gnome/settings-daemon/plugins/xsettings]
#				overrides={'Gtk/IMModule': <'fcitx'>}
#				
#_EOT_
#		fi
#		# --- input-sources ---------------------------------------------------
#		_RETURN_VALUE="$(echo "${LIVE_LOCALES:-}" | sed -e 's/\(.*\)/\L\1/')"
#		if [ "${_RETURN_VALUE:-}" = "ja_jp.utf-8" ]; then
#			echo "set gnome parameter: input-sources [${LIVE_LOCALES}]" | tee /dev/console
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				[org/gnome/desktop/input-sources]
#				sources=[('xkb', 'jp')]
#				xkb-options=@as []
#				
#_EOT_
#		fi
#		# --- screensaver -----------------------------------------------------
#		echo "set gnome parameter: screensaver" | tee /dev/console
#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#			[org/gnome/desktop/screensaver]
#			idle-activation-enabled=false
#			lock-enabled=false
#			
#_EOT_
		# --- session ---------------------------------------------------------
		echo "set gnome parameter: session" | tee /dev/console
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
			[org/gnome/desktop/session]
			idle-delay=uint32 0
			
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
		# --- dconf update ----------------------------------------------------
		dconf update
	fi

	# --- add user ------------------------------------------------------------
	if [ -n "${LIVE_USERNAME:-}" ]; then
		echo "add user: ${LIVE_USERNAME}" | tee /dev/console
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
	echo "set user parameter" | tee /dev/console
	for DIRS_NAME in /root /home/*
	do
		USER_NAME="${DIRS_NAME##*/}"
		echo "set user parameter: ${USER_NAME}" | tee /dev/console
		# --- .bashrc ---------------------------------------------------------
		_FILE_PATH="${DIRS_NAME}/.bashrc"
		echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
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
		_RETURN_VALUE="$(command -v xrandr 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			case "${LIVE_XORG_RESOLUTION}" in				# resolution
#				 640x480 ) _RATE="60.000";;					# VGA    (4:3)
				 800x600 ) _RATE="60.317";;					# SVGA   (4:3)
				1024x768 ) _RATE="60.004";;					# XGA    (4:3)
#				1152x864 ) _RATE="60.000";;					#        (4:3)
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
#				2560x1440) _RATE="60.000";;					# WQHD   (16:9)
#				2560x1600) _RATE="60.000";;					#        (16:10)
#				2880x1800) _RATE="60.000";;					#        (16:10)
#				3840x2160) _RATE="60.000";;					# 4K UHD (16:9)
#				3840x2400) _RATE="60.000";;					#        (16:10)
#				7680x4320) _RATE="60.000";;					# 8K UHD (16:9)
				*        ) _RATE="60.000";;					# 
			esac
			_DIRS_GDM3="var/lib/gdm/.config"
			_FILE_PATH="${DIRS_NAME}/.config/monitors.xml"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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
		# --- fcitx5 ----------------------------------------------------------
		_RETURN_VALUE="$(command -v fcitx5 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.config/fcitx5/profile"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
				[Groups/0]
				# Group Name
				Name=デフォルト
				# Layout
				Default Layout=${LIVE_KEYBOARD_LAYOUTS}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
				# Default Input Method
				DefaultIM=mozc
				
				[Groups/0/Items/0]
				# Name
				Name=keyboard-${LIVE_KEYBOARD_LAYOUTS}${LIVE_KEYBOARD_VARIANTS+"-${LIVE_KEYBOARD_VARIANTS}"}
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
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				export XMODIFIERS=@im=fcitx
#				export GTK_IM_MODULE=fcitx
#				export QT_IM_MODULE=fcitx
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#			# --- .config/gtk-3.0/settings.ini --------------------------------
#			_FILE_PATH="${DIRS_NAME}/.config/gtk-3.0/settings.ini"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
#				[Settings]
#				gtk-im-module=fcitx
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
#			# --- xcb.conf --------------------------------------------------------
#			_FILE_PATH="${DIRS_NAME}/.config/fcitx5/conf/xcb.conf"
#			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
#			sudo --user="${USER_NAME}" mkdir -p "${_FILE_PATH%/*}"
#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
#				# システム XKB 設定のオーバーライドを許可する
#				Allow Overriding System XKB Settings=False
#				# 常にレイアウトをグループレイアウトのみにする
#				AlwaysSetToGroupLayout=False
#_EOT_
#			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- .vimrc ----------------------------------------------------------
		_RETURN_VALUE="$(command -v vim 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			_FILE_PATH="${DIRS_NAME}/.vimrc"
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
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
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
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
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
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
			echo "set user parameter: ${_FILE_PATH}" | tee /dev/console
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
		# --- reset gnome parameter -------------------------------------------
		_RETURN_VALUE="$(command -v dconf 2> /dev/null)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			echo "reset gnome parameter" | tee /dev/console
			sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/mru-sources
			sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/sources
			sudo --user="${USER_NAME}" dconf reset /org/gnome/desktop/input-sources/xkb-options
		fi
	done

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console

### eof #######################################################################
