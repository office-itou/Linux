# shellcheck disable=SC2148
set -o pipefail		# debug: End with in pipe error

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
#   g-var : _ROWS_SIZE : write
#   g-var : _COLS_SIZE : write
#   g-var : _TEXT_GAP1 : write
#   g-var : _TEXT_GAP2 : write
#   g-var : _COMD_BBOX : write
#   g-var : _OPTN_COPY : write
#   g-var : _TGET_CHRT : write
#   g-var : _TGET_VIRT : write
#   g-var : _DIRS_TGET : write
#   g-var : _SHEL_NLIN : write
#   g-var : _PATH_CONF : write
# shellcheck disable=SC2148
function fnInitialize() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __WORK=""				# work

	# --- set system parameter ------------------------------------------------
	if [[ -n "${TERM:-}" ]] \
	&& command -v tput > /dev/null 2>&1; then
		_ROWS_SIZE=$(tput lines || true)
		_COLS_SIZE=$(tput cols  || true)
	fi
	[[ "${_ROWS_SIZE:-"0"}" -lt 25 ]] && _ROWS_SIZE=25
	[[ "${_COLS_SIZE:-"0"}" -lt 80 ]] && _COLS_SIZE=80
	readonly _ROWS_SIZE
	readonly _COLS_SIZE

	_TEXT_SPCE="$(fnString "${_COLS_SIZE}" ' ')"
	_TEXT_GAP1="$(fnString "${_COLS_SIZE}" '-')"
	_TEXT_GAP2="$(fnString "${_COLS_SIZE}" '=')"
	readonly _TEXT_SPCE
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		fnMsgout "${_PROG_NAME:-}" "info" "busybox"
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi
	readonly _COMD_BBOX
	readonly _OPTN_COPY

	# --- target virtualization -----------------------------------------------
	_TGET_VIRT=""						# virtualization (ex. vmware)
	_TGET_CHRT=""						# is chgroot     (empty: none, else: chroot)
	_TGET_CNTR=""						# is container   (empty: none, else: container)
	if command -v systemd-detect-virt > /dev/null 2>&1; then
		_TGET_VIRT="$(systemd-detect-virt --vm || true)"
		systemd-detect-virt --quiet --chroot    && _TGET_CHRT="true"
		systemd-detect-virt --quiet --container && _TGET_CNTR="true"
	fi
	if command -v ischroot > /dev/null 2>&1; then
		ischroot --default-true && _TGET_CHRT="true"
	fi
	readonly _TGET_VIRT
	readonly _TGET_CHRT
	readonly _TGET_CNTR
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_TGET_CHRT=[${_TGET_CHRT:-}]" \
		"info,_TGET_CNTR=[${_TGET_CNTR:-}]"

	_DIRS_TGET=""
	for __DIRS in \
		/target \
		/mnt/sysimage \
		/mnt/
	do
		[[ ! -e "${__DIRS}"/root/. ]] && continue
		_DIRS_TGET="${__DIRS}"
		break
	done
	readonly _DIRS_TGET

	unset __PATH __DIRS __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
