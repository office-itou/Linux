# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: network manager
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIRS_ORIG : read
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_netman() {
	__FUNC_NAME="fnSetup_netman"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'NetworkManager.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- configures ----------------------------------------------------------
	if [ -z "${_NICS_NAME##-}" ]; then
		for __CONF in zz-all-en zz-all-eth
		do
			__PATH="${_DIRS_TGET:-}/etc/NetworkManager/system-connections/${__CONF}.nmconnection"
			fnFile_backup "${__PATH}"			# backup original file
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
			nmcli --offline connection add \
				type ethernet \
				match.interface-name "${__CONF##*-}*" \
				connection.id "${__CONF}" \
				connection.autoconnect true \
				connection.autoconnect-priority 999 \
				${_FWAL_ZONE:+connection.zone "${_FWAL_ZONE}"} \
				ethernet.wake-on-lan 0 \
				ipv4.method auto \
				ipv6.method auto \
				ipv6.addr-gen-mode default \
			> "${__PATH}"
			chown root:root "${__PATH}"
			chmod 600 "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		done
	else
		__PATH="${_DIRS_TGET:-}/etc/NetworkManager/system-connections/${_NICS_NAME}.nmconnection"
		__SRVC="NetworkManager.service"
		__UUID=""
		if [ -z "${_TGET_CNTR:-}" ]; then
			if systemctl --quiet is-active "${__SRVC}"; then
				__UUID="$(nmcli --fields DEVICE,UUID connection show | awk '$1=="'"${_NICS_NAME}"'" {print $2;}')"
				for __FIND in "${_DIRS_TGET:-}/etc/NetworkManager/system-connections/"* "${_DIRS_TGET:-}/run/NetworkManager/system-connections/"*
				do
					if grep -Hqs "uuid=${__UUID}" "${__FIND}"; then
						__PATH="${__FIND}"
						break
					fi
				done
			fi
		fi
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
#		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		__CNID="${__PATH##*/}"
		__CNID="${__CNID%.*}"
		set -f
		set -- \
			type ethernet \
			${__CNID:+connection.id "${__CNID}"} \
			${_NICS_NAME:+connection.interface-name "${_NICS_NAME}"} \
			connection.autoconnect true \
			${_FWAL_ZONE:+connection.zone "${_FWAL_ZONE}"} \
			ethernet.wake-on-lan 0 \
			${_NICS_MADR:+ethernet.mac-address "${_NICS_MADR}"}
		if [ -n "${_NICS_AUTO##-}" ]; then
			set -- "$@" \
				ipv4.method auto \
				ipv6.method auto \
				ipv6.addr-gen-mode default
		else
			set -- "$@" \
				ipv4.method manual \
				${_NICS_IPV4:+ipv4.address "${_NICS_IPV4}"/"${_NICS_BIT4}"} \
				${_NICS_GATE:+ipv4.gateway "${_NICS_GATE}"} \
				${_NICS_DNS4:+ipv4.dns "${_NICS_DNS4}"} \
				ipv6.method auto \
				ipv6.addr-gen-mode default
		fi
		set +f
		if [ -z "${__UUID:-}" ]; then
			nmcli --offline connection add "$@" > "${__PATH}"
		else
			nmcli connection modify uuid "${__UUID}" "$@"
		fi
		chown root:root "${__PATH}"
		chmod 600 "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- dns.conf ------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if command -v resolvectl > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[main]
			dns=systemd-resolved
_EOT_
	elif command -v dnsmasq > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[main]
			dns=dnsmasq
_EOT_
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- mdns.conf -----------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/NetworkManager/conf.d/mdns.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if command -v resolvectl > /dev/null 2>&1; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
			[connection]
			connection.mdns=2
_EOT_
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	__SRVC="${__SRVC##*/}"
	if systemctl --quiet is-enabled "${__SRVC}"; then
		__SVEX="systemd-networkd.service"
		if systemctl --quiet is-enabled "${__SVEX}"; then
			fnMsgout "${_PROG_NAME:-}" "mask" "${__SVEX}"
			systemctl --quiet mask "${__SVEX}"
			systemctl --quiet mask "${__SVEX%.*}.socket"
		fi
	fi
	if [ -z "${_TGET_CNTR:-}" ]; then
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
			if nmcli connection reload; then
				fnMsgout "${_PROG_NAME:-}" "success" "nmcli connection reload"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "nmcli connection reload"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
