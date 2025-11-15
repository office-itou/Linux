# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: hosts
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_hosts() {
	__FUNC_NAME="fnSetup_hosts"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check fqdn ----------------------------------------------------------
	if [ -z "${_NICS_FQDN:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- hosts ---------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/hosts"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestampsa "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if [ "${_NICS_IPV4##*.}" -eq 0 ]; then
		__WORK="#${_IPV4_DUMY:-"127.0.1.1"}"
	else
		__WORK="${_NICS_IPV4}"
	fi
	__WORK="$(printf "%-16s %s %s" "${__WORK}" "${_NICS_FQDN}" "${_NICS_HOST}")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		${IPV4_LHST:-"127.0.0.1"}       localhost
		${__WORK}

		# The following lines are desirable for IPv6 capable hosts
		${IPV6_LHST:-"::1"}             localhost ip6-localhost ip6-loopback
		fe00::0         ip6-localnet
		ff00::0         ip6-mcastprefix
		ff02::1         ip6-allnodes
		ff02::2         ip6-allrouters
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
