# shellcheck disable=SC2148
# === <initrd> ================================================================

# -----------------------------------------------------------------------------
# descript: extract a compressed cpio
#   input :   $1   : target file
#   input :   $2   : destination directory
#   input :   $@   : cpio options
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnXcpio() {
	fnDebugout ""
	declare -r    __TGET_FILE="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:-}"	# destination directory
	shift 2

	# shellcheck disable=SC2312
	  if gzip -t       "${__TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${__TGET_FILE}"
	elif zstd -q -c -t "${__TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${__TGET_FILE}"
	elif xzcat -t      "${__TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${__TGET_FILE}"
	elif lz4cat -t <   "${__TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${__TGET_FILE}"
	elif bzip2 -t      "${__TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${__TGET_FILE}"
	elif lzop -t       "${__TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${__TGET_FILE}"
	fi | (
		if [[ -n "${__DIRS_DEST}" ]]; then
			mkdir -p -- "${__DIRS_DEST}"
			# shellcheck disable=SC2312
			cd -- "${__DIRS_DEST}" || exit
		fi
		cpio "$@"
	)
}

# -----------------------------------------------------------------------------
# descript: read bytes out of a file, checking that they are valid hex digits
#   input :   $1   : target file
#   input :   $2   : skip bytes
#   input :   $3   : count bytes
#   output: stdout : result
#   return:        : unused
# shellcheck disable=SC2317
function fnReadhex() {
	fnDebugout ""
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# -----------------------------------------------------------------------------
# descript: check for a zero byte in a file
#   input :   $1   : target file
#   input :   $2   : skip bytes
#   output: stdout : unused
#   return:        : status
# shellcheck disable=SC2317
function fnCheckzero() {
	fnDebugout ""
	# shellcheck disable=SC2312
	dd if="${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# -----------------------------------------------------------------------------
# descript: split an initramfs into target files and call funcxcpio on each
#   input :   $1   : target file
#   input :   $2   : destination directory
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnSplit_initramfs() {
	fnDebugout ""
	declare -r    __TGET_FILE="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:-}"	# destination directory
	declare -r -a __OPTS=("--preserve-modification-time" "--no-absolute-filenames" "--quiet")
	declare -i    __CONT=0				# count
	declare -i    __PSTR=0				# start point
	declare -i    __PEND=0				# end point
	declare       __MGIC=""				# magic word
	declare -i    __NSIZ=0				# name size
	declare -i    __FSIZ=0				# file size
	declare       __DSUB=""				# sub directory
	declare       __SARC=""				# sub archive

	while true
	do
		__PEND="${__PSTR}"
		while true
		do
			# shellcheck disable=SC2310
			if fnCheckzero "${__TGET_FILE}" "${__PEND}"; then
				__PEND=$((__PEND + 4))
				# shellcheck disable=SC2310
				while fnCheckzero "${__TGET_FILE}" "${__PEND}"
				do
					__PEND=$((__PEND + 4))
				done
				break
			fi
			# shellcheck disable=SC2310
			__MGIC="$(fnReadhex "${__TGET_FILE}" "${__PEND}" "6")" || break
			test "${__MGIC}" = "070701" || test "${__MGIC}" = "070702" || break
			__NSIZ=0x$(fnReadhex "${__TGET_FILE}" "$((__PEND + 94))" "8")
			__FSIZ=0x$(fnReadhex "${__TGET_FILE}" "$((__PEND + 54))" "8")
			__PEND=$((__PEND + 110))
			__PEND=$(((__PEND + __NSIZ + 3) & ~3))
			__PEND=$(((__PEND + __FSIZ + 3) & ~3))
		done
		if [[ "${__PEND}" -eq "${__PSTR}" ]]; then
			break
		fi
		((__CONT+=1))
		if [[ "${__CONT}" -eq 1 ]]; then
			__DSUB="early"
		else
			__DSUB="early${__CONT}"
		fi
		# shellcheck disable=SC2312
		dd if="${__TGET_FILE}" skip="${__PSTR}" count="$((__PEND - __PSTR))" iflag=skip_bytes 2> /dev/null |
		(
			if [[ -n "${__DIRS_DEST}" ]]; then
				mkdir -p -- "${__DIRS_DEST}/${__DSUB}"
				# shellcheck disable=SC2312
				cd -- "${__DIRS_DEST}/${__DSUB}" || exit
			fi
			cpio -i "${__OPTS[@]}"
		)
		__PSTR="${__PEND}"
	done
	if [[ "${__PEND}" -gt 0 ]]; then
		__SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${__SARC%/*}"
		dd if="${__TGET_FILE}" skip="${__PEND}" iflag=skip_bytes 2> /dev/null > "${__SARC}"
		fnXcpio "${__SARC}" "${__DIRS_DEST:+${__DIRS_DEST}/main}" -i "${__OPTS[@]}"
		rm -f "${__SARC:?}"
	else
		fnXcpio "${__TGET_FILE}" "${__DIRS_DEST}" -i "${__OPTS[@]}"
	fi
}
