# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: finalize preset service
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMkosi_finalize_service() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- 00-user-custom.preset -----------------------------------------------
	declare       __LINE=""
	declare -a    __LIST=()
	declare -r    __PATH="/etc/systemd/system-preset/00-user-custom.preset"
	mkdir -p "${__PATH%/*}"
	# --- mask ----------------------------------------------------------------
	: > "${__PATH:?}"
	for __LINE in \
		"disable chronyd.service" \
		"disable avahi-daemon.service" \
		"disable nmb.service" \
		"disable nmbd.service" \
		"disable winbind.service" \
		"disable wicked.service" \
		"disable systemd-networkd.service" \
		"enable  apparmor.service" \
		"enable  auditd.service" \
		"enable  firewalld.service" \
		"enable  clamav-freshclam.service" \
		"enable  clamav-daemon.service" \
		"enable  NetworkManager.service" \
		"enable  systemd-resolved.service" \
		"enable  dnsmasq.service" \
		"enable  systemd-timesyncd.service" \
		"enable  open-vm-tools.service" \
		"enable  vmtoolsd.service" \
		"enable  ssh.service" \
		"enable  sshd.service" \
		"enable  apache2.service" \
		"enable  httpd.service" \
		"enable  smb.service" \
		"enable  smbd.service"
	do
		read -r -a __LIST < <(echo "${__LINE}")
		if [[ ! -e "/lib/systemd/system/${__LIST[1]}"     ]] \
		&& [[ ! -e "/usr/lib/systemd/system/${__LIST[1]}" ]]; then
			fnMsgout "${_PROG_NAME:-}" "not found" "${__LIST[1]}"
			continue
		fi
		fnMsgout "${_PROG_NAME:-}" "${__LIST[0]}" "${__LIST[1]}"
		printf "%-8.8s%s\n" "${__LIST[0]}" "${__LIST[1]}" >> "${__PATH:?}"
	done 
	unset __LINE __LIST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
