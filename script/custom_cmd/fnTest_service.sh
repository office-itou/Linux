# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: test service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnTest_service() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("wget")
	declare       __SRVC=""
	declare       __RELT=""
	declare -a    __STAT=()

	# --- test service --------------------------------------------------------
	if ! command -v "${__COMD[0]}" > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "${__COMD[*]}"
	else
		for __SRVC in \
			apparmor.service auditd.service \
			firewalld.service \
			clamav-freshclam.service clamav-daemon.service \
			NetworkManager.service connman.service io.netplan.Netplan.service wicked.service \
			systemd-networkd.service \
			systemd-resolved.service dnsmasq.service \
			systemd-timesyncd.service chronyd.service \
			open-vm-tools.service vmtoolsd.service \
			ssh.service sshd.service \
			apache2.service httpd.service \
			smb.service smbd.service \
			nmb.service nmbd.service \
			winbind.service \
			avahi-daemon.service
		do
			__RELT="$(systemctl is-active "${__SRVC}" || true)"
			__WORK="$(systemctl list-unit-files --type=service "${__SRVC}" | grep "${__SRVC}" || true)"
			read -r -a __STAT < <(echo "${__WORK:-"-------- -------- --------"}")
			__WORK="$(printf "%-30s:%-8s:%s" "${__SRVC:-}" "${__STAT[1]:-}" "${__STAT[2]:-}")"
			fnMsgout "\033[36m${_PROG_NAME:-}" "${__RELT}" "${__WORK:-}"
		done
	fi
	unset __SRVC __RELT __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
