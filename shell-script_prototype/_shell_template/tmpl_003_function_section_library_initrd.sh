# === <initrd> ================================================================

# --- Extract a compressed cpio _TGET_FILE ------------------------------------
# shellcheck disable=SC2317
funcXcpio() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination directory
	shift 2

	# shellcheck disable=SC2312
	  if gzip -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${_TGET_FILE}"
	elif zstd -q -c -t "${_TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${_TGET_FILE}"
	elif xzcat -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${_TGET_FILE}"
	elif lz4cat -t <   "${_TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${_TGET_FILE}"
	elif bzip2 -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${_TGET_FILE}"
	elif lzop -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${_TGET_FILE}"
	fi | (
		if [[ -n "${_DIRS_DEST}" ]]; then
			mkdir -p -- "${_DIRS_DEST}"
			# shellcheck disable=SC2312
			cd -- "${_DIRS_DEST}" || exit
		fi
		cpio "$@"
	)
}

# --- Read bytes out of a file, checking that they are valid hex digits -------
# shellcheck disable=SC2317
funcReadhex() {
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# --- Check for a zero byte in a file -----------------------------------------
# shellcheck disable=SC2317
funcCheckzero() {
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# --- Split an initramfs into _TGET_FILEs and call funcXcpio on each ----------
# shellcheck disable=SC2317
funcSplit_initramfs() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination directory
	declare -r -a _OPTS=("--preserve-modification-time" "--no-absolute-filenames" "--quiet")
	declare -i    _CONT=0				# count
	declare -i    _PSTR=0				# start point
	declare -i    _PEND=0				# end point
	declare       _MGIC=""				# magic word
	declare       _DSUB=""				# sub directory
	declare       _SARC=""				# sub archive

	while true
	do
		_PEND="${_PSTR}"
		while true
		do
			# shellcheck disable=SC2310
			if funcCheckzero "${_TGET_FILE}" "${_PEND}"; then
				_PEND=$((_PEND + 4))
				# shellcheck disable=SC2310
				while funcCheckzero "${_TGET_FILE}" "${_PEND}"
				do
					_PEND=$((_PEND + 4))
				done
				break
			fi
			# shellcheck disable=SC2310
			_MGIC="$(funcReadhex "${_TGET_FILE}" "${_PEND}" "6")" || break
			test "${_MGIC}" = "070701" || test "${_MGIC}" = "070702" || break
			_NSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 94))" "8")
			_FSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 54))" "8")
			_PEND=$((_PEND + 110))
			_PEND=$(((_PEND + _NSIZ + 3) & ~3))
			_PEND=$(((_PEND + _FSIZ + 3) & ~3))
		done
		if [[ "${_PEND}" -eq "${_PSTR}" ]]; then
			break
		fi
		_CONT=$((_CONT + 1))
		if [[ "${_CONT}" -eq 1 ]]; then
			_DSUB="early"
		else
			_DSUB="early${_CONT}"
		fi
		# shellcheck disable=SC2312
		dd if="${_TGET_FILE}" skip="${_PSTR}" count="$((_PEND - _PSTR))" iflag=skip_bytes 2> /dev/null |
		(
			if [[ -n "${_DIRS_DEST}" ]]; then
				mkdir -p -- "${_DIRS_DEST}/${_DSUB}"
				# shellcheck disable=SC2312
				cd -- "${_DIRS_DEST}/${_DSUB}" || exit
			fi
			cpio -i "${_OPTS[@]}"
		)
		_PSTR="${_PEND}"
	done
	if [[ "${_PEND}" -gt 0 ]]; then
		_SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${_SARC%/*}"
		dd if="${_TGET_FILE}" skip="${_PEND}" iflag=skip_bytes 2> /dev/null > "${_SARC}"
		funcXcpio "${_SARC}" "${_DIRS_DEST:+${_DIRS_DEST}/main}" -i "${_OPTS[@]}"
		rm -f "${_SARC:?}"
	else
		funcXcpio "${_TGET_FILE}" "${_DIRS_DEST}" -i "${_OPTS[@]}"
	fi
}
