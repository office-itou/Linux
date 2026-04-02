# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: file backup
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIRS_SAMP : read
#   g-var : _DIRS_INIT : read
#   g-var : _DIRS_ORIG : read
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
function fnFile_backup() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __BKUP_MODE="${2:-}"
	declare       ___REAL=""
	declare       ___DIRS=""
	declare       ___BACK=""
	# --- check ---------------------------------------------------------------
	if [[ ! -e "${__TGET_PATH}" ]]; then
		fnMsgout "caution" "not exist: [${__TGET_PATH}]"
		mkdir -p "${__TGET_PATH%/*}"
		___REAL="$(realpath --canonicalize-missing "${__TGET_PATH}")"
		if [[ ! -e "${___REAL}" ]]; then
			mkdir -p "${___REAL%/*}"
		fi
		: > "${__TGET_PATH}"
	fi
	# --- backup --------------------------------------------------------------
	case "${__BKUP_MODE:-}" in
		samp) ___DIRS="${_DIRS_SAMP:-}";;
		init) ___DIRS="${_DIRS_INIT:-}";;
		*   ) ___DIRS="${_DIRS_ORIG:-}";;
	esac
	___DIRS="${_DIRS_TGET:-}${___DIRS}"
	___BACK="${__TGET_PATH#"${_DIRS_TGET:-}/"}"
	___BACK="${___DIRS}/${___BACK#/}"
	mkdir -p "${___BACK%/*}"
	chmod 600 "${___DIRS%/*}"
	if [[ -e "${___BACK}" ]] || [[ -h "${___BACK}" ]]; then
		___BACK="${___BACK}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	fi
	fnMsgout "backup" "[${__TGET_PATH}]${_DBGS_FLAG:+" -> [${___BACK}]"}"
	cp --archive "${__TGET_PATH}" "${___BACK}"
	unset ___REAL ___DIRS ___BACK
}
