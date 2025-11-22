# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: sudoers
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_sudo() {
	__FUNC_NAME="fnSetup_sudo"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	__PATH="$(fnFind_command 'sudo' | sort -V | head -n 1)"
	if [ -z "${__PATH:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- sudoers -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}"/etc/sudoers
	__CONF="${_DIRS_TGET:-}"/usr/etc/sudoers
	if [ ! -e "${__PATH}" ] && [ -e "${__CONF}" ]; then
		fnFile_backup "${__CONF}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		if ! grep -qE '^@includedir /etc/sudoers.d$' "${__PATH}" 2> /dev/null; then
			echo "@includedir /etc/sudoers.d" >> "${__PATH}"
		fi
	fi
	fnFile_backup "${__PATH}"			# backup original file
	__CONF="${_DIRS_TGET:-}"/tmp/sudoers-local.work
	__WORK="$(sed -ne 's/^.*\(sudo\|wheel\).*$/\1/p' "${_DIRS_TGET:-}"/etc/group)"
	__WORK="${__WORK:+"$(printf "%-6s %-13s %s" "%${__WORK}" "ALL=(ALL:ALL)" "ALL")"}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CONF}"
		Defaults !targetpw
		#Defaults authenticate
		root   ALL=(ALL:ALL) ALL
		${__WORK:-}
_EOT_
	# --- sudoers-local -------------------------------------------------------
	if visudo -q -c -f "${__CONF}"; then
		__PATH="${_DIRS_TGET:-}/etc/sudoers.d/sudoers-local"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
		chown -c root:root "${__PATH}"
		chmod -c 0440 "${__PATH}"
		fnMsgout "${_PROG_NAME:-}" "success" "[${__PATH}]"
		# --- sudoers ---------------------------------------------------------
		__PATH="${_DIRS_TGET:-}/etc/sudoers"
		__CONF="${_DIRS_TGET:-}/tmp/sudoers.work"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		sed "${__PATH}"                                                  \
		    -e '/^Defaults[ \t]\+targetpw[ \t]*/ s/^/#/'                 \
		    -e '/^ALL[ \t]\+ALL=(ALL\(\|:ALL\))[ \t]\+ALL[ \t]*/ s/^/#/' \
		> "${__CONF}"
		if visudo -q -c -f "${__CONF}"; then
			cp --preserve=timestamps "${__CONF}" "${__PATH}"
			chown -c root:root "${__PATH}"
			chmod -c 0440 "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
			fnMsgout "${_PROG_NAME:-}" "success" "[${__PATH}]"
			fnMsgout "${_PROG_NAME:-}" "info" "show user permissions: sudo -ll"
		else
			fnMsgout "${_PROG_NAME:-}" "failed" "[${__CONF}]"
			visudo -c -f "${__CONF}" || true
		fi
	else
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__CONF}]"
		visudo -c -f "${__CONF}" || true
	fi
	fnDbgdump "${__CONF}"				# debugout
	fnFile_backup "${__CONF}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
