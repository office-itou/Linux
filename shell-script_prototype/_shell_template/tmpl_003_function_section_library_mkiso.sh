# === <mkiso> =================================================================

# --- create iso image --------------------------------------------------------
# shellcheck disable=SC2317
function funcCreate_iso() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_OUTP="${2:?}"	# output path
	declare -r -a __OPTN_XORR=("$@:2")	# xorrisofs options
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path
	              __PATH="$(mktemp -q "${TMPDIR:-/tmp}/${__PATH_OUTP##*/}.XXXXXX")"
	readonly      __PATH

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- create iso image ----------------------------------------------------
	pushd "${__DIRS_TGET}" > /dev/null || exit
		if ! nice -n "${_NICE_VALU:-19}" xorrisofs "${__OPTN_XORR[@]}" -output "${__PATH}" . > /dev/null 2>&1; then
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [xorriso]" "${__PATH_OUTP##*/}" 1>&2
		else
			if ! cp --preserve=timestamps "${__PATH}" "${__PATH_OUTP}"; then
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [cp]" "${__PATH_OUTP##*/}" 1>&2
			else
				IFS= mapfile -d ' ' -t __LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${__PATH_OUTP}" || true)
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "complete" "${__PATH_OUTP##*/} (${__LIST[4]})" 1>&2
			fi
		fi
		rm -f "${__PATH:?}"
	popd > /dev/null || exit
}
