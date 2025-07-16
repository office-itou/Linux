#!/bin/bash

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail					# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	__WORK_PATH="/usr/share/wireplumber/main.lua.d/50-alsa-config.lua"
	if [[ -e "${__WORK_PATH}" ]]; then
		# --- 50-alsa-config.lua ----------------------------------------------
		__FILE_PATH="/etc/wireplumber/main.lua.d/${__WORK_PATH##*/}"
		mkdir -p "${__FILE_PATH%/*}"
		sed -e '/^alsa_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                                 {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*}/                         {' \
		    -e '/\["api.alsa.period-size"\]/a \        \["api.alsa.period-size"\]   = 1024,'  \
		    -e '/\["api.alsa.headroom"\]/a    \        \["api.alsa.headroom"\]      = 16384,' \
		    -e '}}'                                                                           \
		    "${__WORK_PATH}"                                                                  \
		>   "${__FILE_PATH}"
	else
		__WORK_PATH="/usr/share/wireplumber/wireplumber.conf.d/alsa-vm.conf"
		if [[ -e "${__WORK_PATH}" ]]; then
			# --- alsa-vm.conf ------------------------------------------------
			__FILE_PATH="/etc/wireplumber/wireplumber.conf.d/${__WORK_PATH##*/}"
			mkdir -p "${__FILE_PATH%/*}"
			sed -e '/^monitor.alsa.rules[ \t]*=[ \t]*\[$/,/^\]$/                 {' \
			    -e '/^[ \t]*actions[ \t]*=[ \t]*{$/,/^[ \t]*}$/                  {' \
			    -e '/^[ \t]*update-props[ \t]*=[ \t]*{$/,/^[ \t]*}$/             {' \
			    -e '/^[ \t]*api.alsa.period-size[ \t]*/ s/=\([ \t]*\).*$/=\11024/'  \
			    -e '/^[ \t]*api.alsa.headroom[ \t]*/    s/=\([ \t]*\).*$/=\116384/' \
			    -e '}}}'                                                            \
			    "${__WORK_PATH}"                                                    \
			>   "${__FILE_PATH}"
		else
			# --- 50-alsa-config.conf -----------------------------------------
			__FILE_PATH="/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
			mkdir -p "${__FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
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

	# --- bluetooth -----------------------------------------------------------
	__WORK_PATH="/usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua"
	if [[ -e "${__WORK_PATH}" ]]; then
		# --- 50-bluez-config.lua ---------------------------------------------
		__FILE_PATH="/etc/wireplumber/bluetooth.lua.d/${__WORK_PATH##*/}"
		mkdir -p "${__FILE_PATH%/*}"
		sed -e '/^bluez_monitor.properties[ \t]*=[ \t]*{$/,/^}$/                        {' \
		    -e '/\["bluez5.headset-roles"\]/a  \    \["bluez5.headset-roles"\] = "[ ]",'   \
		    -e '/\["bluez5.hfphsp-backend"\]/a \    \["bluez5.hfphsp-backend"\] = "none",' \
		    -e '                                                                        }' \
		    -e '/^bluez_monitor.rules[ \t]*=[ \t]*{$/,/^}$/                             {' \
		    -e '/^[ \t]*apply_properties[ \t]*=[ \t]*{/,/^[ \t]*},/                     {' \
		    -e '/\["bluez5.media-source-role"\]/,/^[ \t]*},/                            {' \
		    -e '/^[ \t]*},/i \        \["bluez5.auto-connect"\] = "\[ a2dp_sink \]",'      \
		    -e '/^[ \t]*},/i \        \["bluez5.hw-volume"\]    = "\[ a2dp_sink \]",'      \
		    -e '}}}'                                                                       \
		    "${__WORK_PATH}"                                                               \
		>   "${__FILE_PATH}"
	else
		# --- bluez.conf ------------------------------------------------------
		__FILE_PATH="/etc/wireplumber/wireplumber.conf.d/bluez.conf"
		mkdir -p "${__FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
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
