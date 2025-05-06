# === <mkiso> =================================================================

# --- create iso image --------------------------------------------------------
# shellcheck disable=SC2317
function funcCreate_iso() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_OUTP="${2:?}"	# output path
	shift 2
	declare -r -a _OPTN_XORR=("$@")		# xorrisofs options
	declare -a    _LIST=()				# data list
	declare       _PATH=""				# file name
	              _PATH="$(mktemp -q "${TMPDIR:-/tmp}/${_PATH_OUTP##*/}.XXXXXX")"
	readonly      _PATH

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- create iso image ----------------------------------------------------
	pushd "${_DIRS_TGET}" > /dev/null || exit
	if ! nice -n "${_NICE_VALU:-19}" xorrisofs "${_OPTN_XORR[@]}" -output "${_PATH}" . > /dev/null 2>&1; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [xorriso]" "${_PATH_OUTP##*/}" 1>&2
	else
		if ! cp --preserve=timestamps "${_PATH}" "${_PATH_OUTP}"; then
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [cp]" "${_PATH_OUTP##*/}" 1>&2
		else
			IFS= mapfile -d ' ' -t _LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${_PATH_OUTP}" || true)
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "complete" "${_PATH_OUTP##*/} (${_LIST[4]})" 1>&2
		fi
	fi
	rm -f "${_PATH:?}"
	popd > /dev/null || exit
}
