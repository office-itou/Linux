# --- Extract a compressed cpio _TGET_FILE ------------------------------------
funcXcpio() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination _DIRS_DESTectory
	shift 2

	  if gzip -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${_TGET_FILE}"
	elif zstd -q -c -t "${_TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${_TGET_FILE}"
	elif xzcat -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${_TGET_FILE}"
	elif lz4cat -t <   "${_TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${_TGET_FILE}"
	elif bzip2 -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${_TGET_FILE}"
	elif lzop -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${_TGET_FILE}"
	fi | (
		if [[ -n "${_DIRS_DEST}" ]]; then
			mkdir -p -- "${_DIRS_DEST}"
			cd -- "${_DIRS_DEST}"
		fi
		cpio "$@"
	)
}

# --- Read bytes out of a file, checking that they are valid hex digits -------
funcReadhex() {
	dd < "${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# --- Check for a zero byte in a file -----------------------------------------
funcCheckzero() {
	dd < "${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# --- Split an initramfs into _TGET_FILEs and call funcXcpio on each ----------
funcSplitinitramfs() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination _DIRS_DESTectory
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
			if funcCheckzero "${_TGET_FILE}" "${_PEND}"; then
				_PEND=$((_PEND + 4))
				while funcCheckzero "${_TGET_FILE}" "${_PEND}"
				do
					_PEND=$((_PEND + 4))
				done
				break
			fi
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
		dd < "${_TGET_FILE}" skip="${_PSTR}" count="$((_PEND - _PSTR))" iflag=skip_bytes 2 > /dev/null |
		(
			if [[ -n "${_DIRS_DEST}" ]]; then
				mkdir -p -- "${_DIRS_DEST}/${_DSUB}"
				cd -- "${_DIRS_DEST}/${_DSUB}"
			fi
			cpio -i "${_OPTS[@]}"
		)
		_PSTR="${_PEND}"
	done
	if [[ "${_PEND}" -gt 0 ]]; then
		_SARC="${_DIRS_TEMP}/${FUNCNAME[0]}"
		mkdir -p "${_SARC%/*}"
		dd < "${_TGET_FILE}" skip="${_PEND}" iflag=skip_bytes 2 > /dev/null > "${_SARC}"
		funcXcpio "${_SARC}" "${_DIRS_DEST:+${_DIRS_DEST}/main}" -i "${_OPTS[@]}"
		rm -f "${_SARC:?}"
	else
		funcXcpio "${_TGET_FILE}" "${_DIRS_DEST}" -i "${_OPTS[@]}"
	fi
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DIMG="${_DIRS_IMGS}/${_TGET_LIST[2]}"	# iso file extraction destination (entry)
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
	declare -r    _MNTP="${_DWRK}/mnt"						# mount point
	declare -r    _FIMG="${_DWRK}/img"						# filesystem image
	declare -r    _FRAM="${_DWRK}/ram"						# initrd filesystem image
	declare       _WORK=""									# work variables
	declare       _PATH=""									# file name
	declare       _TGET=""									# target

	# -------------------------------------------------------------------------
	if [[ "${_TGET_LINE[13]}" = "-" ]] || [[ ! -e "${_TGET_LINE[13]}" ]]; then
		funcPrintf "${_TEXT_BG_YELLOW}%20.20s: %s${_TEXT_RESET}" "not exist" "${_TGET_LINE[13]}"
		return
	fi

	# -------------------------------------------------------------------------
	_WORK="$(funcUnit_conversion "${_TGET_LINE[15]}")"
	funcPrintf "%20.20s: %s" "copy" "${_TGET_LINE[13]} ${_WORK}"

	# --- create directory ----------------------------------------------------
	rm -rf "${_DWRK:?}"
	mkdir -p "${_MNTP}" "${_FIMG}" "${_FRAM}"

	# --- copy iso -> hdd -----------------------------------------------------
	mount -o ro,loop "${_TGET_LINE[13]}" "${_MNTP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_RSYC_OPTN[@]}" "${_MNTP}/." "${_DIMG}/" 2>/dev/null || true
	umount "${_MNTP}"
	chmod -R +r "${_DIMG}/" 2>/dev/null || true

	# --- copy boot loader -> hdd ---------------------------------------------
	for _TGET in "${_TGET_LINE[21]}" "${_TGET_LINE[22]}"
	do
		if [[ "${_TGET}" = "-" ]] || [[ ! -e "${_TGET}" ]]; then
			continue
		fi
		_PATH="${_DIMG}/${_TGET}"
		mkdir -p "${_PATH%/*}"
		funcPrintf "%20.20s: %s" "copy" "${_PATH##*/}"
		nice -n "${_NICE_VALU:-19}" rsync "${_RSYC_OPTN[@]}" "${_TGET}" "${_PATH}" 2>/dev/null || true
		chmod +r "${_PATH}" 2>/dev/null || true
	done

	# --- Check the edition and extract the initrd ----------------------------
	case "${_TGET_LIST[2]}" in
		*-mini-*) ;;					# proceed to extracting the initrd
		*       ) return;;
	esac

	# --- copy initrd -> hdd --------------------------------------------------
	find "${_DIMG}" \( -type f -o -type l \) \( -name 'initrd' -o -name 'initrd.*' -o -name 'initrd-[0-9]*' \) | sort -V | \
	while read -r _PATH
	do
		_TGET="${_PATH#"${_DIMG%/}"/}"
		funcPrintf "%20.20s: %s" "copy" "/${_TGET}"
		funcSplitinitramfs "${_PATH}" "${_FRAM}/${_TGET}"
	done
}

