# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: wireplumber (alsa) settings
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_wireplumber() {
	__FUNC_NAME="fnGet_conf_file"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v wireplumber > /dev/null 2>&1; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- 50-alsa-config.conf -------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp -a "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		monitor.alsa.rules = [
		  {
		    matches = [
		      # This matches the value of the node.name property of the node.
		      {
		        node.name = "~alsa_output.*"
		      }
		    ]
		    actions = {
		      # Apply all the desired node specific settings here.
		      update-props = {
		        api.alsa.period-size   = 1024
		        api.alsa.headroom      = 8192
		        session.suspend-timeout-seconds = 0
		      }
		    }
		  }
		]
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	__SRVC="wireplumber.service"
	if systemctl --quiet  is-active "${_SRVC_NAME}"; then
		fnMsgout "restart" "${__SRVC}"
		systemctl --quiet daemon-reload
		for __USER in $(ps --no-headers -C "${__SRVC%.*}" -o user)
		do
			if systemctl --quiet --user --machine="${__USER}"@ restart "${__SRVC}"; then
				fnMsgout "success" "${__USER}@ ${__SRVC}"
			else
				fnMsgout "failed" "${__USER}@ ${__SRVC}"
			fi
		done
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
