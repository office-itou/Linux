# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: execute qemu
#   input :     $@     : parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnMk_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __OPTN=("${@:-}")
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __COMD=""				# command
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "execute qemu ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	  if command -v qemu-system-x86_64 > /dev/null 2>&1; then __COMD="qemu-system-x86_64"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	if ! nice -n 19 "${__COMD:?}" "${__OPTN[@]}"; then
		__RTCD="$?"
#		echo -e "\x12\x1bc"
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [qemu]" "${__COMD} ${__OPTN[*]}" 1>&2
		printf "%s\n" "${__COMD}: ${__RTCD:-}"
		exit "${__RTCD:-}"
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
