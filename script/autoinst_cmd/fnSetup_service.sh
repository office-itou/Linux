# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_service() {
	__FUNC_NAME="fnSetup_service"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- mask ----------------------------------------------------------------
	set -f
	set --
	for __LIST in \
		chronyd.service \
		avahi-daemon.service \
		nmb.service \
		nmbd.service \
		winbind.service \
		wicked.service
	do
		if [ ! -e "${_DIRS_TGET:-}/lib/systemd/system/${__LIST}"     ] \
		&& [ ! -e "${_DIRS_TGET:-}/usr/lib/systemd/system/${__LIST}" ]; then
			continue
		fi
		fnMsgout "${_PROG_NAME:-}" "mask" "${__LIST}"
		set -- "$@" "${__LIST}"
	done 
	set +f
	[ $# -gt 0 ] && systemctl mask "$@"
	[ -z "${_TGET_CHRT:-}" ] && systemctl --quiet daemon-reload
	# --- enable --------------------------------------------------------------
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
		open-vm-tools.service \
		vmtoolsd.service \
		ssh.service \
		sshd.service \
		apache2.service \
		httpd.service \
		smb.service \
		smbd.service
	do
		if [ ! -e "${_DIRS_TGET:-}/lib/systemd/system/${__LIST}"     ] \
		&& [ ! -e "${_DIRS_TGET:-}/usr/lib/systemd/system/${__LIST}" ]; then
			continue
		fi
		fnMsgout "${_PROG_NAME:-}" "enable" "${__LIST}"
		set -- "$@" "${__LIST}"
	done 
	set +f
	[ $# -gt 0 ] && systemctl enable "$@"
	[ -z "${_TGET_CHRT:-}" ] && systemctl --quiet daemon-reload
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ] && [ $# -gt 0 ]; then
		for __SRVC in "$@"
		do
#			systemctl --quiet is-active "${__SRVC}" || continue
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		done
	fi
	unset __LIST __SRVC

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
