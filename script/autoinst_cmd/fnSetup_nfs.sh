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
	# --- fstab ---------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/fstab"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "# <file system>" "<mount point>"                     "<type>" "<options>" "<dump>" "<pass>")
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_SHEL:?}" "${_DIRS_MKOS:?}/${_DIRS_SHEL##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_IMGS:?}" "${_DIRS_XNFS:?}/${_DIRS_IMGS##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_CONF:?}" "${_DIRS_XNFS:?}/${_DIRS_CONF##*/}" "none"   "bind,ro"   "0"      "0"     )
_EOT_
	# --- check mount ---------------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		systemctl --quiet daemon-reload
		for __MNTP in \
			"${_DIRS_MKOS:?}/${_DIRS_SHEL##*/}" \
			"${_DIRS_XNFS:?}/${_DIRS_IMGS##*/}" \
			"${_DIRS_XNFS:?}/${_DIRS_CONF##*/}"
		do
			if mount "${__MNTP:?}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "mounted: ${__MNTP}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "not mounted: ${__MNTP}"
			fi
		done
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- exports /srv --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/exports.d/srv.exports"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# exports file: "${__PATH#*"${_DIRS_TGET:-}"}"

		# --- ipv4 --------------------------------------------------------------------
		${_DIRS_EXPO:?} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		${_DIRS_XNFS:?}/${_DIRS_CONF##*/} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(ro,sync,no_subtree_check,no_root_squash)
		${_DIRS_XNFS:?}/${_DIRS_IMGS##*/} ${_IPV4_UADR:?}.0/${_NICS_BIT4:?}(ro,sync,no_subtree_check,no_root_squash)

		# --- ipv6 --------------------------------------------------------------------
		#${_DIRS_EXPO:?} ${_IPV6_UADR:?}::/${_IPV6_CIDR:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		#${_DIRS_XNFS:?}/${_DIRS_CONF##*/} ${_IPV6_UADR:?}::/${_IPV6_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)
		#${_DIRS_XNFS:?}/${_DIRS_IMGS##*/} ${_IPV6_UADR:?}::/${_IPV6_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)

		# --- link local --------------------------------------------------------------
		${_DIRS_EXPO:?} ${_LINK_UADR:?}/${_LINK_CIDR:?}(rw,sync,no_subtree_check,no_root_squash,fsid=0,crossmnt)
		${_DIRS_XNFS:?}/${_DIRS_CONF##*/} ${_LINK_UADR:?}/${_LINK_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)
		${_DIRS_XNFS:?}/${_DIRS_IMGS##*/} ${_LINK_UADR:?}/${_LINK_CIDR:?}(ro,sync,no_subtree_check,no_root_squash)

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
		showmount -e || true
	fi
	unset __SRVC __PATH __MNTP

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
