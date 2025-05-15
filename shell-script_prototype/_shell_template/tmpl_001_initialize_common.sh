# *** initialization **********************************************************
	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# === data section ========================================================

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"$(whoami || true)"}"

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare       _DIRS_TEMP=""
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
	declare -r    TMPDIR="${_DIRS_TEMP:-?}"

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# shellcheck disable=SC2317
function funcTrap() {
	declare       __PATH=""				# full path
	declare -i    I=0
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ -e "${__PATH}" ]] && mountpoint --quiet "${__PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		fi
	done
	if [[ -e "${_DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${_DIRS_TEMP}" 1>&2
		while read -r __PATH
		do
			printf "[%s]: umount \"%s\"\n" "-" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		done < <(grep "${_DIRS_TEMP:?}" /proc/mounts | cut -d ' ' -f 2 | sort -rV || true)
		rm -rf "${_DIRS_TEMP:?}"
	fi
}

	trap funcTrap EXIT
