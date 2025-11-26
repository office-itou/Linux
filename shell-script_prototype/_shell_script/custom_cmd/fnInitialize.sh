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
#   g-var : _TGET_CNTR : write
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

	__COLS="${_COLS_SIZE}"
	[[ -n "${_PROG_NAME:-}" ]] && __COLS=$((_COLS_SIZE-${#_PROG_NAME}-16))
	_TEXT_GAP1="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '-')"
	_TEXT_GAP2="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '=')"
	unset __COLS
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi
	readonly _COMD_BBOX
	readonly _OPTN_COPY

	# --- target virtualization -----------------------------------------------
	__WORK="$(fnTargetsys)"
	case "${__WORK##*,}" in
		offline) _TGET_CNTR="true";;
		*      ) _TGET_CNTR="";;
	esac
	readonly _TGET_CNTR
	readonly _TGET_VIRT="${__WORK%,*}"

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

	# --- samba ---------------------------------------------------------------
	_SHEL_NLIN="$(fnFind_command 'nologin' | sort -r | head -n 1)"
	_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /usr/sbin/nologin ]]; then echo "/usr/sbin/nologin"; fi)"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /sbin/nologin     ]]; then echo "/sbin/nologin"; fi)"}"
	readonly _SHEL_NLIN

	# --- common configuration data -------------------------------------------
	fnList_conf_Set						# set default common configuration data
	_PATH_CONF="${_PATH_CONF:-"/srv/user/share/conf/_data/${_FILE_CONF:?}"}"
	for __PATH in \
		"${PWD:+"${PWD}/${_FILE_CONF}"}" \
		"${_PATH_CONF}"
	do
		[[ ! -e "${__PATH}" ]] && continue
		_PATH_CONF="${__PATH}"
		break
	done
	if [[ -e "${_PATH_CONF}" ]]; then
		fnList_conf_Get "${_PATH_CONF}"	# get common configuration data
	else
		mkdir -p "${_PATH_CONF%"${_FILE_CONF:?}"}"
		fnList_conf_Put "${_PATH_CONF}"	# put common configuration data
	fi
	fnList_conf_Dec						# decoding common configuration data

	# --- media information data ----------------------------------------------
	if [[ -e "${_PATH_MDIA:?}" ]]; then
		fnList_mdia_Get "${_PATH_MDIA}"	# get media information data
	fi
	fnList_mdia_Dec						# decoding media information data

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
