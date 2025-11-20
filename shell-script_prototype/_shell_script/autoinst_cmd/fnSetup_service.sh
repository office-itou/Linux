# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_service() {
	__FUNC_NAME="fnSetup_skel"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	set -f
	set --
	for __LIST in \
		apparmor.service \
		auditd.service \
		firewalld.service \
		clamav-freshclam.service \
		NetworkManager.service \
		systemd-resolved.service \
		dnsmasq.service \
		systemd-timesyncd.service \
		chronyd.service\
		open-vm-tools.service \
		vmtoolsd.service \
		ssh.service \
		sshd.service \
		apache2.service \
		httpd.service \
		smb.service \
		smbd.service \
		nmb.service \
		nmbd.service \
		avahi-daemon.service
	do
		if [ ! -e "${_DIRS_TGET:-}/lib/systemd/system/${__LIST}"     ] \
		&& [ ! -e "${_DIRS_TGET:-}/usr/lib/systemd/system/${__LIST}" ]; then
			continue
		fi
		fnMsgout "${_PROG_NAME:-}" "enable" "${__LIST}"
		set -- "$@" "${__LIST}"
	done 
	set +f
	if [ $# -gt 0 ]; then
		systemctl enable "$@"
		# --- service restart -------------------------------------------------
		if [ -z "${_TGET_CNTR:-}" ]; then
			for __SRVC in "$@"
			do
				if systemctl --quiet is-active "${__SRVC}"; then
					fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
					systemctl --quiet daemon-reload
					if systemctl --quiet restart "${__SRVC}"; then
						fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
					else
						fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
					fi
				fi
			done
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
