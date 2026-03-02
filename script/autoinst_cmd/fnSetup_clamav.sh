# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: clamav
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_clamav() {
	__FUNC_NAME="fnSetup_clamav"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if command -v freshclam > /dev/null 2>&1; then
		__SRVC="oneshot-freshclam.service"
		__PATH="/etc/systemd/system/${__SRVC}"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[Unit]
			After=network-online.target
			Before=clamav-freshclam.service clamav-daemon.service

			[Service]
			Type=oneshot
			RemainAfterExit=yes
			ExecStart=/usr/bin/freshclam

			[Install]
			WantedBy=multi-user.target
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- service restart -------------------------------------------------
		if [ -z "${_TGET_CHRT:-}" ]; then
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
		unset __SRVC __PATH
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
