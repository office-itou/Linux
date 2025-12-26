# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: rsync
#   input :     $1     : target iso file
#   input :     $2     : destination directory
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TEMP : read
#   g-var : _OPTN_RSYC : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnRsync() {
	declare -r    __TGET_ISOS="${1:?}"	# target iso file
	declare -r    __TGET_DEST="${2:?}"	# destination directory
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP

	case "${__TGET_ISOS}" in
		*.iso) ;;
		*    ) return;;
	esac
	if [[ ! -s "${__TGET_ISOS}" ]]; then
		return
	fi
	printf "\033[mrsync   : %s\033[m\n" "${__TGET_ISOS##*/}"
	rm -rf "${__TEMP:?}"
	mkdir -p "${__TEMP}" "${__TGET_DEST}"
	mount -o ro,loop "${__TGET_ISOS}" "${__TEMP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_OPTN_RSYC[@]}" "${__TEMP}/." "${__TGET_DEST}/" 2>/dev/null || true
	umount "${__TEMP}"
	chmod -R +r "${__TGET_DEST}/" 2>/dev/null || true
	rm -rf "${__TEMP:?}"
}
