# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: wget / curl file download
#   input :     $1     : target url
#   input :     $2     : target path
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TEMP : read
#   g-var : _OPTN_CURL : read
#   g-var : _OPTN_WGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnDownload() {
	declare -r    __TGET_URLS="${1:?}"
	declare -r    __TGET_PATH="${2:?}"
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q -p "${_DIRS_TEMP:-/tmp}" "${__TGET_PATH##*/}.XXXXXX")"
	readonly      __TEMP
	declare       __REAL=""
	declare       __OWNR=""
	declare       __PATH=""
	declare       __DIRS=""
	declare       __FNAM=""
#	declare -a    __OPTN=()

	printf "\033[mstart   : %s\033[m\n" "${__TGET_PATH##*/}"
	__DIRS="$(fnDirname  "${__TEMP}")"
	__FNAM="$(fnBasename "${__TEMP}")"
	case "${_COMD_WGET:-}" in
		curl)
			if ! LANG=C curl "${_OPTN_CURL[@]}" --progress-bar --continue-at - --create-dirs --output-dir "${__DIRS}" --output "${__FNAM}" "${__TGET_URLS}" 2>&1; then
				printf "\033[m\033[41mfailed  : %s [%s]\033[m\n" "curl" "${__TGET_URLS}"
				return
			fi
			;;
		*)
			if ! LANG=C wget "${_OPTN_WGET[@]}" --continue --show-progress --progress=bar --output-document="${__TEMP}" "${__TGET_URLS}" 2>&1; then
				printf "\033[m\033[41mfailed  : %s [%s]\033[m\n" "wget" "${__TGET_URLS}"
				return
			fi
			;;
	esac
	if ! cp --preserve=timestamps "${__TEMP}" "${__TGET_PATH}"; then
		printf "\033[m\033[41mfailed  : %s\033[m\n" "${__TGET_PATH}"
		return
	fi
	__REAL="$(realpath "${__TGET_PATH}")"
#	if [[ -z "${__REAL%"${_DIRS_SAMB:-}"*}" ]]; then
		__DIRS="$(fnDirname "${__TGET_PATH}")"
		__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
		chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
		chmod g+rw,o+r "${__TGET_PATH}"
#	fi
	rm -rf "${__TEMP:?}"
	printf "\033[m\033[92mcomplete: %s\033[m\n" "${__TGET_PATH##*/}"
}
