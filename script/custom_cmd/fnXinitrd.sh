# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: extract the compressed cpio
#   input :   $1   : target file
#   input :   $2   : destination directory
#   input :   $@   : cpio options
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnXcpio() {
	  if gzip -t       "${1:?}" > /dev/null 2>&1 ; then gzip -c -d    "${1:?}"
	elif zstd -q -c -t "${1:?}" > /dev/null 2>&1 ; then zstd -q -c -d "${1:?}"
	elif xzcat -t      "${1:?}" > /dev/null 2>&1 ; then xzcat         "${1:?}"
	elif lz4cat -t <   "${1:?}" > /dev/null 2>&1 ; then lz4cat        "${1:?}"
	elif bzip2 -t      "${1:?}" > /dev/null 2>&1 ; then bzip2 -c -d   "${1:?}"
	elif lzop -t       "${1:?}" > /dev/null 2>&1 ; then lzop -c -d    "${1:?}"
	fi | (
		if [[ -n "${2:?}" ]]; then
			mkdir -p -- "${2:?}"
			cd -- "${2:?}" || exit
			shift
		fi
		shift
		cpio "${@:-}"
	)
}

# -----------------------------------------------------------------------------
# descript: extract the initrd
#   input :     $1     : target initrd file
#   input :     $2     : destination directory
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnXinitrd() {
	declare -r    __TGET_FILE="${1:?}"	# target initrd file
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
			if dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'; then
				__PEND=$((__PEND + 4))
				while dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
				do
					__PEND=$((__PEND + 4))
				done
				break
			fi
			__MGIC="$(dd if="${__TGET_FILE:?}" bs=1 skip="${__PEND:?}" count="6" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]6$')" || break
			case "${__MGIC}" in
				"070701" | "070702") ;;
				*                  ) break;;
			esac
			__NSIZ=0x$(dd if="${__TGET_FILE:?}" bs=1 skip="$((__PEND + 94))" count="8" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]8$')
			__FSIZ=0x$(dd if="${__TGET_FILE:?}" bs=1 skip="$((__PEND + 54))" count="8" 2> /dev/null | LANG=C grep -E '^[0-9A-Fa-f]8$')
			__PEND=$((__PEND + 110))
			__PEND=$(((__PEND + __NSIZ + 3) & ~3))
			__PEND=$(((__PEND + __FSIZ + 3) & ~3))
		done
		[[ "${__PEND}" -eq "${__PSTR}" ]] && break
		((__CONT+=1))
		__DSUB="early"
		[[ "${__CONT}" -gt 1 ]] && __DSUB+="${__CONT}"
		dd if="${__TGET_FILE}" skip="${__PSTR}" count="$((__PEND - __PSTR))" iflag=skip_bytes 2> /dev/null | (
			if [[ -n "${__DIRS_DEST}" ]]; then
				mkdir -p -- "${__DIRS_DEST}/${__DSUB}"
				cd -- "${__DIRS_DEST}/${__DSUB}" || exit
			fi
			cpio -i "${__OPTS[@]}"
		)
		__PSTR="${__PEND}"
	done
	if [[ "${__PEND}" -le 0 ]]; then
		fnXcpio "${__TGET_FILE}" "${__DIRS_DEST}" -i "${__OPTS[@]}"
	else
		__SARC="${TMPDIR:-/tmp}/${FUNCNAME[0]}"
		mkdir -p "${__SARC%/*}"
		dd if="${__TGET_FILE}" skip="${__PEND}" iflag=skip_bytes 2> /dev/null > "${__SARC}"
		fnXcpio "${__SARC}" "${__DIRS_DEST:+${__DIRS_DEST}/main}" -i "${__OPTS[@]}"
		rm -f "${__SARC:?}"
	fi
}
