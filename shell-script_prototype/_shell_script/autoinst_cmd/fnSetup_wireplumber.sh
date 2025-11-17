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
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'chronyd.service' | sort | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- alsa ----------------------------------------------------------------
	__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/main.lua.d/50-alsa-config.lua"
	if [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		# --- 50-alsa-config.lua ----------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/main.lua.d/${__CONF##*/}"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		sed -i "${__PATH}"                                                                    \
		    -e '/^alsa_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                                 {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*}/                         {' \
		    -e '/\["api.alsa.period-size"\]/a \        \["api.alsa.period-size"\]   = 1024,'  \
		    -e '/\["api.alsa.headroom"\]/a    \        \["api.alsa.headroom"\]      = 16384,' \
		    -e '}}'
	else
		__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/wireplumber.conf.d/alsa-vm.conf"
		if [ -e "${__CONF}" ]; then
			fnFile_backup "${__CONF}"			# backup original file
			# --- alsa-vm.conf ------------------------------------------------
			__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/${__CONF##*/}"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${__CONF}" "${__PATH}"
			sed -i "${__PATH}"                                                      \
			    -e '/^monitor.alsa.rules[ \t]*=[ \t]*\[$/,/^\]$/                 {' \
			    -e '/^[ \t]*actions[ \t]*=[ \t]*{$/,/^[ \t]*}$/                  {' \
			    -e '/^[ \t]*update-props[ \t]*=[ \t]*{$/,/^[ \t]*}$/             {' \
			    -e '/^[ \t]*api.alsa.period-size[ \t]*/ s/=\([ \t]*\).*$/=\11024/'  \
			    -e '/^[ \t]*api.alsa.headroom[ \t]*/    s/=\([ \t]*\).*$/=\116384/' \
			    -e '}}}'
		else
			# --- 50-alsa-config.conf -----------------------------------------
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
				        session.suspend-timeout-seconds = 0
				      }
				    }
				  }
				]
_EOT_
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- bluetooth -----------------------------------------------------------
	__CONF="${_DIRS_TGET:-}/usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua"
	if [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		# --- 50-bluez-config.lua ---------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/bluetooth.lua.d/${__CONF##*/}"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		sed -i "${__PATH}"                                                                 \
		    -e '/^bluez_monitor.properties[ \t]*=[ \t]*{$/,/^}$/                        {' \
		    -e '/\["bluez5.headset-roles"\]/a  \    \["bluez5.headset-roles"\] = "[ ]",'   \
		    -e '/\["bluez5.hfphsp-backend"\]/a \    \["bluez5.hfphsp-backend"\] = "none",' \
		    -e '                                                                        }' \
		    -e '/^bluez_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                             {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*},/                     {' \
		    -e '/\["bluez5.media-source-role"\]/,/^[ \t]*},/                            {' \
		    -e '/^[ \t]*},/i \        \["bluez5.auto-connect"\] = "\[ a2dp_sink \]",'      \
		    -e '/^[ \t]*},/i \        \["bluez5.hw-volume"\]    = "\[ a2dp_sink \]",'      \
		    -e '}}}'
	else
		# --- bluez.conf ------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/bluez.conf"
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
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CNTR:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet  is-active "${__SRVC}"; then
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
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
