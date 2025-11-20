# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: chronyd
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_chronyd() {
	__FUNC_NAME="fnSetup_chronyd"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'chronyd.service' | sort | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- chrony.conf ---------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/chrony.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
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
			hwclock --systohc
			hwclock --test
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
