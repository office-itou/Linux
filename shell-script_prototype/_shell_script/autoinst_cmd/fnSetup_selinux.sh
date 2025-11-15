# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_selinux() {
	__FUNC_NAME="fnSetup_selinux"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v getenforce > /dev/null 2>&1; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- backup original file ------------------------------------------------
	find "${_DIRS_TGET:-}/etc/selinux/" \( -name targeted -o -name default \) | while read -r __DIRS
	do
		find "${__DIRS}/contexts/files/" -type f | while read -r __PATH
		do
			fnFile_backup "${__PATH}"
		done
	done
	# --- application ---------------------------------------------------------
	semanage fcontext -a -t var_t                "${_DIRS_SHAR}(/.*)?" || true	# root of shared directory
	semanage fcontext -a -t fusefs_t             "${_DIRS_HGFS}(/.*)?" || true	# root of hgfs shared directory
	semanage fcontext -a -t httpd_user_content_t "${_DIRS_HTML}(/.*)?" || true	# root of html shared directory
	semanage fcontext -a -t samba_share_t        "${_DIRS_SAMB}(/.*)?" || true	# root of samba shared directory
	semanage fcontext -a -t tftpdir_t            "${_DIRS_TFTP}(/.*)?" || true	# root of tftp shared directory
	semanage fcontext -a -t var_t                "${_DIRS_USER}(/.*)?" || true	# root of user shared directory
	# --- user share ----------------------------------------------------------
	semanage fcontext -a -t var_t                "${_DIRS_PVAT}(/.*)?" || true	# root of private contents directory
	semanage fcontext -a -t public_content_t     "${_DIRS_SHAR}(/.*)?" || true	# root of public contents directory
	# --- container -----------------------------------------------------------
	semanage fcontext -a -t public_content_t     "${_DIRS_SHAR}/cache(/.*)?"      || true
	semanage fcontext -a -t container_file_t     "${_DIRS_SHAR}/containers(/.*)?" || true
	# --- flag ----------------------------------------------------------------
	setsebool -P samba_export_all_rw=on   || true			# Determine whether samba can share any content readable and writable.
	setsebool -P httpd_enable_homedirs=on || true			# Determine whether httpd can traverse user home directories.
#	setsebool -P global_ssp=on            || true			# Enable reading of urandom for all domains.
	# --- backup initial file ------------------------------------------------
	find "${_DIRS_TGET:-}/etc/selinux/" \( -name targeted -o -name default \) | while read -r __DIRS
	do
		find "${__DIRS}/contexts/files/" -type f | while read -r __PATH
		do
			fnFile_backup "${__PATH}" "init"
		done
	done
	# --- restore context labels ----------------------------------------------
	fnMsgout "restore" "context labels"
	fixfiles onboot || true
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: status")"
		___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : status")"
		fnMsgout "-debugout" "${___STRT}"
		getenforce || true
		if command -v sestatus > /dev/null 2>&1; then
			sestatus || true
		fi
		fnMsgout "-debugout" "${___ENDS}"
		___STRT="$(fnStrmsg "${_TEXT_GAP1:-}" "start: fcontext")"
		___ENDS="$(fnStrmsg "${_TEXT_GAP1:-}" "end  : fcontext")"
		fnMsgout "-debugout" "${___STRT}"
		semanage fcontext -l | grep -E '^/srv' || true
		fnMsgout "-debugout" "${___ENDS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
