# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: wireplumber (alsa) settings
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_wireplumber() {
	__FUNC_NAME="fnSetup_wireplumber"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'wireplumber.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- memo ----------------------------------------------------------------
	# https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Troubleshooting
	__PATH="${_DIRS_TGET:-}/usr/share/wireplumber/main.lua.d/50-alsa-config.lua"
	if [ -e "${__PATH}" ]; then
		# --- memo ------------------------------------------------------------
		# debian-12
		#   wireplumber: 0.4.13
		#   pipewire   : 0.3.65
		# --- alsa: 51-alsa-config.lua ----------------------------------------
		# stuttering audio (in virtual machine)
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/main.lua.d/51-alsa-config.lua"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			alsa_monitor.properties = {
			  ["vm.node.defaults"] = {
			    ["api.alsa.period-size"] = 1024,
			    ["api.alsa.headroom"] = 16384,
			  },
			}
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- bluetooth: 51-bluez-config.lua ----------------------------------
		# headset disabled
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/bluetooth.lua.d/51-bluez-config.lua"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			bluez_monitor.properties = {
			  ["bluez5.headset-roles"] = "[ ]",
			  ["bluez5.hfphsp-backend"] = "none"
			}

			bluez_monitor.rules = {
			  {
			    matches = {
			      {
			        -- Matches all sources.
			        { "node.name", "matches", "bluez_input.*" },
			      },
			      {
			        -- Matches all sinks.
			        { "node.name", "matches", "bluez_output.*" },
			      },
			    },
			    apply_properties = {
			      ["bluez5.auto-connect"] = "[ a2dp_sink ]",
			      ["bluez5.hw-volume"]    = "[ a2dp_sink ]",
			    },
			  },
			}
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	else
		# --- memo ------------------------------------------------------------
		# debian-13
		#   wireplumber: 0.5.8
		#   pipewire   : 1.4.2
		# --- alsa: 50-alsa-suspend.conf --------------------------------------
		# loud pops when starting a sound
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-suspend.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			monitor.alsa.rules = [
			  {
			    matches = [
			      # This matches the value of the 'node.name' property of the node.
			      {
			        node.name = "~alsa_output.*"
			      }
			    ]
			    actions = {
			      update-props = {
			        session.suspend-timeout-seconds = 0
			      }
			    }
			  }
			]
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- alsa: 50-alsa-config.conf ---------------------------------------
		# stuttering audio (in virtual machine)
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			monitor.alsa.rules = [
			  {
			    matches = [
			      # This matches the value of the 'node.name' property of the node.
			      {
			        node.name = "~alsa_output.*"
			      }
			    ]
			    actions = {
			      # Apply all the desired node specific settings here.
			      update-props = {
			        api.alsa.period-size   = 1024
			        api.alsa.headroom      = 16384
			      }
			    }
			  }
			]
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- bluetooth: 50-bluez.conf ----------------------------------------
		# headset disabled
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-bluez.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			monitor.bluez.properties = {
			  bluez5.headset-roles  = "[ ]"
			  bluez5.hfphsp-backend = "none"
			}

			monitor.bluez.rules = [
			  {
			    matches = [
			      {
			        node.name = "~bluez_input.*"
			      }
			      {
			        node.name = "~bluez_output.*"
			      }
			    ]
			    actions = {
			      update-props = {
			        bluez5.auto-connect = "[ a2dp_sink ]"
			        bluez5.hw-volume    = "[ a2dp_sink ]"
			      }
			    }
			  }
			]
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet  is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			for __USER in $(ps --no-headers -C "${__SRVC%.*}" -o user)
			do
				if systemctl --quiet --user --machine="${__USER}"@ restart "${__SRVC}"; then
					fnMsgout "${_PROG_NAME:-}" "success" "${__USER}@ ${__SRVC}"
				else
					fnMsgout "${_PROG_NAME:-}" "failed" "${__USER}@ ${__SRVC}"
				fi
			done
		fi
	fi
	unset __SRVC __CONF __PATH __USER

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
