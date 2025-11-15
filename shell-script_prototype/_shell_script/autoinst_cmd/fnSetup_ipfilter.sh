# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: ipfilter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_ipfilte() {
	__FUNC_NAME="fnSetup_ipfilte"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- ipfilter.conf -------------------------------------------------------
#	__PATH="${_DIRS_TGET:-}/usr/lib/systemd/system/systemd-logind.service.d/ipfilter.conf"
#	fnFile_backup "${__PATH}"			# backup original file
#	mkdir -p "${__PATH%/*}"
#	cp -a "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
#		[Service]
#		IPAddressDeny=any           # 0.0.0.0/0      ::/0
#		IPAddressAllow=localhost    # 127.0.0.0/8    ::1/128
#		IPAddressAllow=link-local   # 169.254.0.0/16 fe80::/64
#		IPAddressAllow=multicast    # 224.0.0.0/4    ff00::/8
#		IPAddressAllow=${NICS_IPV4%.*}.0/${NICS_BIT4}
#_EOT_
#	fnDbgdump "${__PATH}"				# debugout
#	fnFile_backup "${__PATH}" "init"	# backup initial file

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
