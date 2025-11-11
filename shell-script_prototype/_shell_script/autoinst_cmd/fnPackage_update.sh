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
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	  if command -v apt-get > /dev/null 2>&1; then
		if ! apt-get --quiet              update      ; then fnMsgout "failed" "apt-get update";       return; fi
		if ! apt-get --quiet --assume-yes upgrade     ; then fnMsgout "failed" "apt-get upgrade";      return; fi
		if ! apt-get --quiet --assume-yes dist-upgrade; then fnMsgout "failed" "apt-get dist-upgrade"; return; fi
		if ! apt-get --quiet --assume-yes autoremove  ; then fnMsgout "failed" "apt-get autoremove";   return; fi
		if ! apt-get --quiet --assume-yes autoclean   ; then fnMsgout "failed" "apt-get autoclean";    return; fi
		if ! apt-get --quiet --assume-yes clean       ; then fnMsgout "failed" "apt-get clean";        return; fi
	elif command -v dnf     > /dev/null 2>&1; then
		if ! dnf --quiet --assumeyes update; then fnMsgout "failed" "dnf update"; return; fi
	elif command -v yum     > /dev/null 2>&1; then
		if ! yum --quiet --assumeyes update; then fnMsgout "failed" "yum update"; return; fi
	elif command -v zypper  > /dev/null 2>&1; then
		_WORK_TEXT="$(LANG=C zypper lr | awk -F '|' '$1==1&&$2~/http/ {gsub(/^[ \t]+/,"",$2); gsub(/[ \t]+$/,"",$2); print $2;}')"
		if [ -n "${_WORK_TEXT:-}" ]; then
			if ! zypper modifyrepo --disable "${_WORK_TEXT}"; then fnMsgout "failed" "zypper repository disable"; return; fi
		fi
		if ! zypper                           refresh; then fnMsgout "failed" "zypper refresh"; return; fi
		if ! zypper --quiet --non-interactive update ; then fnMsgout "failed" "zypper update";  return; fi
	else
		fnMsgout "failed" "package update failure (command not found)"
		return
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
}
