# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: copy iso files
#   n-ref :     $1     : target path
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_TEMP : read
function fnCopy_iso() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target file
	declare -r    __DEST_DIRS="${2:?}"	# destination directory
	declare       __TEMP=""				# Temporary Directory
	declare       __MNTP=""				# mount point
	declare -r -a __OPTN=(\
		--recursive \
		--links \
		--perms \
		--times \
		--group \
		--owner \
		--devices \
		--specials \
		--hard-links \
		--acls \
		--xattrs \
		--human-readable \
		--update \
		--delete \
	)

	__TEMP="$(mktemp -qd -p "${_DIRS_TEMP:-/tmp}" "${__FUNC_NAME}.XXXXXX")"
	_LIST_RMOV+=("${__TEMP}")
	if [[ -s "${__TGET_PATH}" ]]; then
		__MNTP="${__TEMP}/mnt"
		mkdir -p "${__MNTP}" "${__DEST_DIRS}"
		mount -o ro,loop "${__TGET_PATH}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
		rsync "${__OPTN[@]}" "${__MNTP:?}/." "${__DEST_DIRS:?}/"
		umount "${__MNTP}" && { unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]'; _LIST_RMOV=("${_LIST_RMOV[@]}"); }
		chmod -R +r "${__DEST_DIRS}/" 2>/dev/null || true
	fi
	rm -rf "${__TEMP:?}"
	unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]'
	_LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __TEMP __MNTP __OPTN

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
