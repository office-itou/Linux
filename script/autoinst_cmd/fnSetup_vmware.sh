# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: vmware shared directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_vmware() {
	__FUNC_NAME="fnSetup_vmware"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v vmware-hgfsclient > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- GNOME3 rendering issues ---------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/environment.d/99vmware.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		CLUTTER_PAINT=disable-clipped-redraws:disable-culling
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- check file system ---------------------------------------------------
	if command -v vmhgfs-fuse > /dev/null 2>&1; then
		__FSYS="fuse.vmhgfs-fuse"
	else
		__FSYS="vmhgfs"
	fi
	# --- fstab ---------------------------------------------------------------
	__FSTB="$(printf "%-15s %-15s %-7s %-15s %-7s %s" ".host:/" "${_DIRS_HGFS:?}" "${__FSYS}" "nofail,allow_other,defaults" "0" "0")"
	if ! vmware-hgfsclient > /dev/null 2>&1; then
		__FSTB="#${__FSTB}"
	fi
	__PATH="${_DIRS_TGET:-}/etc/fstab"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		${__FSTB}
_EOT_
	# --- check mount ---------------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		systemctl --quiet daemon-reload
		if mount "${_DIRS_HGFS}"; then
			fnMsgout "${_PROG_NAME:-}" "success" "VMware shared directory mounted"
			LANG=C df -h "${_DIRS_HGFS}"
		else
			fnMsgout "${_PROG_NAME:-}" "failed" "VMware shared directory not mounted"
			sed -i "${__PATH}" \
			    -e "\%${__FSTB}% s/^/#/g"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __PATH __FSYS __FSTB

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
