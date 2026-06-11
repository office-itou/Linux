# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: nfs
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_nfs() {
	__FUNC_NAME="fnSetup_nfs"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'nfs-server.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- exports /srv --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/exports.d/srv.exports"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# exports file: "${__PATH#*"${_DIRS_TGET:-}"}"

		# --- ipv4 --------------------------------------------------------------------
		${_DIRS_TOPS:?} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		${_DIRS_EXPO:?}/nfs/${_DIRS_CONF##*/} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(ro,sync,no_subtree_check,no_root_squash)
		${_DIRS_EXPO:?}/nfs/${_DIRS_IMGS##*/} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(ro,sync,no_subtree_check,no_root_squash)

		# --- ipv6 --------------------------------------------------------------------
		#${_DIRS_TOPS:?} ${_IPV6_UADR:?}/${_IPV6_CIDR:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		#${_DIRS_EXPO:?}/nfs/${_DIRS_CONF##*/} ${_IPV6_UADR:?}/${_IPV6_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)
		#${_DIRS_EXPO:?}/nfs/${_DIRS_IMGS##*/} ${_IPV6_UADR:?}/${_IPV6_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)

		# --- link local --------------------------------------------------------------
		${_DIRS_TOPS:?} ${_LINK_UADR:?}/${_LINK_CIDR:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		${_DIRS_EXPO:?}/nfs/${_DIRS_CONF##*/} ${_LINK_UADR:?}/${_LINK_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)
		${_DIRS_EXPO:?}/nfs/${_DIRS_IMGS##*/} ${_LINK_UADR:?}/${_LINK_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)

		# --- eof ---------------------------------------------------------------------
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
		exportfs -v || true
	fi
	unset __SRVC __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
