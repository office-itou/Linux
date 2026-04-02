# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make squashfs file
#   input :     $@     : parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148
function fnMk_squashfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_SQFS="${2:?}"	# output file name
	declare -r -a __OPTN=(
		"${@:-}"
		-quiet
		-progress
		-noappend
		-no-xattrs
		-ef /.autorelabel /.cache /.viminfo
	)

	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	echo "create squashfs file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	if ! nice -n 19 mksquashfs "${__OPTN[@]}"; then
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [mksquashfs]" "${__FILE_ISOS##*/}" 1>&2
		printf "%s\n" "mksquashfs ${__OPTN[*]}"
	fi
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
