# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: nbd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_nbd() {
	__FUNC_NAME="fnSetup_nbd"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v nbdkit > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- create socket -------------------------------------------------------
	__SOCK="${_DIRS_TGET:-}/etc/systemd/system/nbdkit.socket"
	fnFile_backup "${__SOCK}"			# backup original file
	mkdir -p "${__SOCK%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SOCK#*"${_DIRS_TGET:-}/"}" "${__SOCK}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SOCK}"
		[Unit]
		Description=NBDKit Network Block Device server
		[Socket]
		ListenStream=10809
		# Optional settings to detect dead clients:
		#KeepAlive=true
		#KeepAliveTimeSec=60
		#KeepAliveIntervalSec=10
		#KeepAliveProbes=5
		[Install]
		WantedBy=sockets.target
_EOT_
	fnDbgdump "${__SOCK}"				# debugout
	fnFile_backup "${__SOCK}" "init"	# backup initial file
	# --- create service ------------------------------------------------------
	__COMD="$(command -v nbdkit)"
	__SRVC="${_DIRS_TGET:-}/etc/systemd/system/nbdkit.service"
	fnFile_backup "${__SRVC}"			# backup original file
	mkdir -p "${__SRVC%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SRVC#*"${_DIRS_TGET:-}/"}" "${__SRVC}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRVC}"
		[Service]
		ExecStart=${__COMD:?} --exit-with-parent --readonly file cache=default fadvise=normal dir=${_DIRS_EXPO:?}/nbd
		# Optional settings to run as non-root:
		#User=nbd
		#Group=nbd
_EOT_
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		__SOCK="${__SOCK##*/}"
		systemctl enable --now "${__SOCK}"
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
	unset __SRVC __SOCK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
