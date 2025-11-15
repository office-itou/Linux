# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: netplan
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_netplan() {
	__FUNC_NAME="fnSetup_netplan"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v netplan > /dev/null 2>&1; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- configures ----------------------------------------------------------
	if command -v nmcli > /dev/null 2>&1; then
		# --- 99-network-config-all.yaml --------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/netplan/99-network-manager-all.yaml"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp -a "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			network:
			  version: 2
			  renderer: NetworkManager
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- 99-disable-network-config.cfg -----------------------------------
		__PATH="${_DIRS_TGET:-}/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
		if [ -e "${__PATH%/*}/." ]; then
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp -a "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
				network: {config: disabled}
_EOT_
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		fi
	else
		__PATH="${_DIRS_TGET:-}/etc/netplan/99-network-config-${_NICS_NAME}.yaml"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp -a "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			network:
				version: 2
				renderer: networkd
				ethernets:
				${_NICS_NAME}:
_EOT_
		if [ -n "${_NICS_AUTO##-}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
						dhcp4: true
						dhcp6: true
						ipv6-privacy: true
_EOT_
		else
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
						addresses:
						- ${_NICS_IPV4}/${_NICS_BIT4}
						routes:
						- to: default
						via: ${_NICS_GATE}
						nameservers:
						search:
						- ${_NICS_WGRP}
						addresses:
						- ${_NICS_DNS4}
						dhcp4: false
						dhcp6: true
						ipv6-privacy: true
_EOT_
		fi
		chmod 600 "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- netplan -------------------------------------------------------------
	if netplan status 2> /dev/null; then
		if netplan apply; then
			fnMsgout "success" "netplan apply"
		else
			fnMsgout "failed" "netplan apply"
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
