# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: timesyncd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_timesyncd() {
	__FUNC_NAME="fnSetup_timesyncd"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'systemd-timesyncd.service' | sort | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- timesyncd.conf ------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/systemd/timesyncd.conf.d/local.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- user settings ---
		[Time]
		NTP=${_NTPS_ADDR}
		FallbackNTP=${_NTPS_FBAK}
		PollIntervalMinSec=1h
		PollIntervalMaxSec=1d
		SaveIntervalSec=infinity
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CNTR:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "success" "${__SRVC}"
			else
				fnMsgout "failed" "${__SRVC}"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
