# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: package updates
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_BACK : read
# shellcheck disable=SC2148,SC2317,SC2329
fnPackage_update() {
	__FUNC_NAME="fnPackage_update"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	  if command -v apt-get > /dev/null 2>&1; then
		__PATH="${_DIRS_TGET:-}/etc/apt/sources.list"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -i "${__PATH}"                         \
			-e '/^[ \t]*deb[ \t]\+cdrom:/ s/^/#/g'
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		if ! apt-get --quiet              update      ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get update";       return; fi
		if ! apt-get --quiet --assume-yes upgrade     ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get upgrade";      return; fi
		if ! apt-get --quiet --assume-yes dist-upgrade; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get dist-upgrade"; return; fi
		if ! apt-get --quiet --assume-yes autoremove  ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoremove";   return; fi
		if ! apt-get --quiet --assume-yes autoclean   ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoclean";    return; fi
		if ! apt-get --quiet --assume-yes clean       ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get clean";        return; fi
	elif command -v dnf     > /dev/null 2>&1; then
		if ! dnf --quiet --assumeyes update; then fnMsgout "${_PROG_NAME:-}" "failed" "dnf update"; return; fi
	elif command -v yum     > /dev/null 2>&1; then
		if ! yum --quiet --assumeyes update; then fnMsgout "${_PROG_NAME:-}" "failed" "yum update"; return; fi
	elif command -v zypper  > /dev/null 2>&1; then
		_WORK_TEXT="$(LANG=C zypper lr | awk -F '|' '$1==1&&$2~/http/ {gsub(/^[ \t]+/,"",$2); gsub(/[ \t]+$/,"",$2); print $2;}')"
		if [ -n "${_WORK_TEXT:-}" ]; then
			if ! zypper modifyrepo --disable "${_WORK_TEXT}"; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper repository disable"; return; fi
		fi
		if ! zypper                           refresh; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper refresh"; return; fi
		if ! zypper --quiet --non-interactive update ; then fnMsgout "${_PROG_NAME:-}" "failed" "zypper update";  return; fi
	else
		fnMsgout "${_PROG_NAME:-}" "failed" "package update failure (command not found)"
		return
	fi
	unset __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset __FUNC_NAME
}
