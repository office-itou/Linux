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

	# shellcheck disable=SC2028
	echo "\033[m\033[45mstart: ${PROG_PATH}\033[m" | tee /dev/console

	# --- set hostname parameter ----------------------------------------------
	if [ -n "${LIVE_HOSTNAME:-}" ]; then
		echo "set hostname parameter: ${LIVE_HOSTNAME}" | tee /dev/console
#		hostnamectl hostname "${LIVE_HOSTNAME}"
		_FILE_PATH="/etc/hostname"
		cat <<- _EOT_ > "${_FILE_PATH}"
			${LIVE_HOSTNAME}
_EOT_
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
	fi

	# --- set user parameter --------------------------------------------------
	if [ -n "${LIVE_USERNAME:-}" ]; then
		echo "set user parameter: ${LIVE_USERNAME}" | tee /dev/console
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
	fi
	for DIRS_NAME in /root /home/*
	do
		USER_NAME="${DIRS_NAME##*/}"
		# --- .bashrc ---------------------------------------------------------
		_FILE_PATH="${DIRS_NAME}/.bashrc"
		cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' >> "${_FILE_PATH}"
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
		# --- .vimrc ----------------------------------------------------------
		# shellcheck disable=SC2312
		if [ -n "$(command -v vim 2> /dev/null)" ]; then
			_FILE_PATH="${DIRS_NAME}/.vimrc"
			cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' > "${_FILE_PATH}"
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
		# --- curl ------------------------------------------------------------
		# shellcheck disable=SC2312
		if [ -n "$(command -v curl 2> /dev/null)" ]; then
			_FILE_PATH="${DIRS_NAME}/.curlrc"
			cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' > "${_FILE_PATH}"
				location
				progress-bar
				remote-time
				show-error
_EOT_
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- xinput.d --------------------------------------------------------
		if [ "${USER_NAME}" != "skel" ]; then
			_FILE_PATH="${DIRS_NAME}/.xinput"
			mkdir -p "${_FILE_PATH}"
			ln -s /etc/X11/xinit/xinput.d/ja_JP "${_FILE_PATH}"
			chown "${USER_NAME}": "${_FILE_PATH}"
		fi
		# --- libfm.conf ------------------------------------------------------
		_FILE_PATH="${DIRS_NAME}/.config/libfm/libfm.conf"
		if [ -f "${_FILE_PATH}" ]; then
			sed -i "${_FILE_PATH}"                \
			    -e '/^single_click=/ s/=.*$/=0/'
		fi
	done

	# --- set ssh parameter ---------------------------------------------------
	if [ -d /etc/ssh/sshd_config.d/. ]; then
		echo "set ssh parameter" | tee /dev/console
		_CONF_FLAG="no"
		if [ -z "${LIVE_USERNAME:-}" ]; then
			_CONF_FLAG="yes"
		fi
		_FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${_FILE_PATH}"
			PasswordAuthentication yes
			PermitRootLogin ${_CONF_FLAG}
		
_EOT_
		chmod 600 "${_FILE_PATH}"
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
	fi

	# --- set auto login parameter --------------------------------------------
	_GDM3_OPTIONS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
			AutomaticLoginEnable=true
			AutomaticLogin=${LIVE_USERNAME:-root}
			TimedLoginEnable=true
			TimedLogin=${LIVE_USERNAME:-root}
			TimedLoginDelay=5
			
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
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
	done

	# --- set network parameter -----------------------------------------------
	_RETURN_VALUE="$(command -v nmcli 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set network parameter: nmcli" | tee /dev/console
		DIRS_NAME="/etc/netplan"
		if [ -d "${DIRS_NAME}/." ]; then
			echo "set network parameter: nmcli with netplan" | tee /dev/console
			_FILE_PATH="${DIRS_NAME}/99-network-manager-all.yaml"
			cat <<- _EOT_ > "${_FILE_PATH}"
				network:
				  version: 2
				  renderer: NetworkManager
_EOT_
			chmod 600 "${_FILE_PATH}"
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
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			update-alternatives --get-selections | grep x-session-manager | tee /dev/console
		fi
	fi

	# --- set gnome parameter -------------------------------------------------
	_RETURN_VALUE="$(command -v dconf 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set gnome parameter" | tee /dev/console
		if [ ! -d /etc/dconf/db/local.d/. ]; then 
			mkdir -p /etc/dconf/db/local.d
		fi
		if [ ! -d /etc/dconf/profile/. ]; then 
			mkdir -p /etc/dconf/profile
		fi
		_FILE_PATH="/etc/dconf/profile/user"
		cat <<- _EOT_ > "${_FILE_PATH}"
			user-db:user
			system-db:local
_EOT_
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
		_FILE_PATH="/etc/dconf/db/local.d/01-userkeyfile"
		: > "${_FILE_PATH}"
		_RETURN_VALUE="$(dcon read /org/gnome/desktop/session)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			cat <<- _EOT_ >> "${_FILE_PATH}"
				[org/gnome/desktop/session]
				idle-delay="uint32 0"
				
_EOT_
		fi
		_RETURN_VALUE="$(dcon read /org/gnome/desktop/interface)"
		if [ -n "${_RETURN_VALUE:-}" ]; then
			cat <<- _EOT_ >> "${_FILE_PATH}"
				[org/gnome/desktop/interface]
				cursor-theme=\"Adwaita\"
				icon-theme=\"Adwaita\"
				gtk-theme=\"Adwaita\"
				
_EOT_
		fi
		dconf compile /etc/dconf/db/local /etc/dconf/db/local.d
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< "${_FILE_PATH}" tee /dev/console
		fi
		rm -f "${_FILE_PATH:?}"
	fi

	# --- set vmware parameter ------------------------------------------------
	_RETURN_VALUE="$(command -v vmware-checkvm 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ] && [ -n "${LIVE_HGFS}" ]; then
		echo "set vmware parameter" | tee /dev/console
		mkdir -p "${LIVE_HGFS}"
		chmod a+w "${LIVE_HGFS}"
		cat <<- _EOT_ >> /etc/fstab
			.host:/ ${LIVE_HGFS} fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,users 0 0
_EOT_
		cat <<- _EOT_ >> /etc/fuse.conf
			user_allow_other
_EOT_
		systemctl daemon-reload
		mount "${LIVE_HGFS}"
		if [ -n "${LIVE_DEBUGOUT:-}" ]; then
			< /etc/fstab     tee /dev/console
			< /etc/fuse.conf tee /dev/console
		fi
	fi

#	# --- restart pulseaudio --------------------------------------------------
#	_RETURN_VALUE="$(command -v pulseaudio 2> /dev/null)"
#	if [ -n "${_RETURN_VALUE:-}" ]; then
#		echo "restart pulseaudio" | tee /dev/console
#		pulseaudio -k
#	fi
#
	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console

### eof #######################################################################
