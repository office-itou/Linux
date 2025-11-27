# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: firewalld
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_firewalld() {
	__FUNC_NAME="fnSetup_firewalld"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v firewall-cmd > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- firewalld.service ---------------------------------------------------
	__SRVC="$(fnFind_serivce 'firewalld.service' | sort -V | head -n 1)"
	fnFile_backup "${__SRVC}"			# backup original file
	mkdir -p "${__SRVC%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SRVC#*"${_DIRS_TGET:-}/"}" "${__SRVC}"
	sed -i "${__SRVC}" \
	    -e '/\[Unit\]/,/\[.*\]/                {' \
	    -e '/^Before=network-pre.target$/ s/^/#/' \
	    -e '/^Wants=network-pre.target$/  s/^/#/' \
	    -e '                                   }'
	fnDbgdump "${__SRVC}"				# debugout
	fnFile_backup "${__SRVC}" "init"	# backup initial file
	# --- firewalld -----------------------------------------------------------
	__ORIG="$(find "${_DIRS_TGET:-}"/lib/firewalld/zones/ "${_DIRS_TGET:-}"/usr/lib/firewalld/zones/ -name 'drop.xml' | sort -V | head -n 1)"
	__PATH="${_DIRS_TGET:-}/etc/firewalld/zones/${_FWAL_ZONE}.xml"
	cp --preserve=timestamps "${__ORIG}" "${__PATH}"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	__IPV4="${_IPV4_UADR}.0/${_NICS_BIT4}"
	__IPV6="${_IPV6_UADR%%::}::/${_IPV6_CIDR}"
	__LINK="${_LINK_UADR%%::}::/10"
	__SRVC="${__SRVC##*/}"
	if [ -z "${_TGET_CNTR:-}" ] && systemctl --quiet is-active "${__SRVC}"; then
		fnMsgout "${_PROG_NAME:-}" "active" "${__SRVC}"
		firewall-cmd --quiet --permanent --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		firewall-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	else
		fnMsgout "${_PROG_NAME:-}" "inactive" "${__SRVC}"
		firewall-offline-cmd --quiet --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
#		firewall-offline-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-offline-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-offline-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __SRVC __ORIG __PATH __IPV4 __IPV6 __LINK __NAME __PORT

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
