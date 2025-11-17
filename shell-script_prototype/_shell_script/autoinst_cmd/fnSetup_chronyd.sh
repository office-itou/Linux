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
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'chronyd.service' | sort | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
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
			fnMsgout "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "success" "${__SRVC}"
			else
				fnMsgout "failed" "${__SRVC}"
			fi
			hwclock --systohc
			hwclock --test
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
