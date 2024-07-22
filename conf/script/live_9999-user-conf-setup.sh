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
		hostnamectl hostname "${LIVE_HOSTNAME}"
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
	fi
	for DIRS_NAME in /root /home/*
	do
		USER_NAME="${DIRS_NAME##*/}"
		# --- .bashrc ---------------------------------------------------------
		FILE_PATH="${DIRS_NAME}/.bashrc"
		cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' >> "${FILE_PATH}"
			# --- measures against garbled characters ---
			case "${TERM}" in
			    linux ) export LANG=C;;
			    *     )              ;;
			esac
			# --- alias for vim ---
			alias vi='vim'
			alias view='vim'
_EOT_
		chown "${USER_NAME}": "${FILE_PATH}"
		# --- .vimrc ----------------------------------------------------------
		# shellcheck disable=SC2312
		if [ -n "$(command -v vim 2> /dev/null)" ]; then
			FILE_PATH="${DIRS_NAME}/.vimrc"
			cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' > "${FILE_PATH}"
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
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
		# --- curl ------------------------------------------------------------
		# shellcheck disable=SC2312
		if [ -n "$(command -v curl 2> /dev/null)" ]; then
			FILE_PATH="${DIRS_NAME}/.curlrc"
			cat <<- '_EOT_' | sed -e '/^ [^ ]*/ s/^ *//g' > "${FILE_PATH}"
				location
				progress-bar
				remote-time
				show-error
_EOT_
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
		# --- xinput.d --------------------------------------------------------
		if [ "${USER_NAME}" != "skel" ]; then
			FILE_PATH="${DIRS_NAME}/.xinput"
			mkdir -p "${FILE_PATH}"
			ln -s /etc/X11/xinit/xinput.d/ja_JP "${FILE_PATH}"
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
		# --- libfm.conf ------------------------------------------------------
		FILE_PATH="${DIRS_NAME}/.config/libfm/libfm.conf"
		if [ -f "${FILE_PATH}" ]; then
			sed -i "${FILE_PATH}"                \
			    -e '/^single_click=/ s/=.*$/=0/'
		fi
	done

	# --- set auto login parameter --------------------------------------------
	_GDM3_OPTIONS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
			AutomaticLoginEnable=true
			AutomaticLogin=${LIVE_USERNAME}
			TimedLoginEnable=true
			TimedLogin=${LIVE_USERNAME}
			TimedLoginDelay=5
			
_EOT_
	)"
	_CONF_FLAG=""
	grep -l 'AutomaticLoginEnable[ \t]*=[ \t]*true' /etc/gdm3/*.conf | while IFS= read -r FILE_PATH
	do
		sed -i "${FILE_PATH}"              \
		    -e '/^\[daemon\]/,/^\[.*\]/ {' \
		    -e '/^[^#\[]\+/ s/^/#/}' 
		if [ -z "${_CONF_FLAG:-}" ]; then
			sed -i "${FILE_PATH}"                               \
			    -e "s%^\(\[daemon\].*\)$%\1\n${_GDM3_OPTIONS}%"
			_CONF_FLAG="true"
		fi
	done

	# --- set network parameter -----------------------------------------------
	_RETURN_VALUE="$(command -v nmcli 2> /dev/null)"
	if [ -n "${_RETURN_VALUE:-}" ]; then
		echo "set network parameter: nmcli" | tee /dev/console
		DIRS_NAME="/etc/netplan"
		if [ -d "${DIRS_NAME}/." ]; then
			echo "set network parameter: nmcli with netplan" | tee /dev/console
			FILE_PATH="${DIRS_NAME}/99-network-manager-all.yaml"
			cat <<- _EOT_ > "${FILE_PATH}"
				network:
				  version: 2
				  renderer: NetworkManager
_EOT_
			chmod 600 "${FILE_PATH}"
		fi
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
	fi

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console

### eof #######################################################################
