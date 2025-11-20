# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: openssh-server
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_ssh() {
	__FUNC_NAME="fnSetup_ssh"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'ssh.service' 'sshd.service' | sort | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- default.conf --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/ssh/sshd_config.d/default.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- user settings ---

		# port number to listen to ssh
		#Port 22

		# ip address to accept connections
		#ListenAddress 0.0.0.0
		#ListenAddress ::

		# ssh protocol
		Protocol 2

		# whether to allow root login
		PermitRootLogin no

		# configuring public key authentication
		#PubkeyAuthentication no

		# public key file location
		#AuthorizedKeysFile

		# setting password authentication
		PasswordAuthentication yes

		# configuring challenge-response authentication
		#ChallengeResponseAuthentication no

		# sshd log is output to /var/log/secure
		#SyslogFacility AUTHPRIV

		# specify log output level
		#LogLevel INFO
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CNTR:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
