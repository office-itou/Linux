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
fnFile_backup() {
	___PATH="${1:?}"
	___MODE="${2:-}"
	# --- check ---------------------------------------------------------------
	if [ ! -e "${___PATH}" ]; then
		fnMsgout "caution" "not exist: [${___PATH}]"
		mkdir -p "${___PATH%/*}"
		___REAL="$(realpath --canonicalize-missing "${___PATH}")"
		if [ ! -e "${___REAL}" ]; then
			mkdir -p "${___REAL%/*}"
		fi
		: > "${___PATH}"
	fi
	# --- backup --------------------------------------------------------------
	case "${___MODE:-}" in
		samp) ___DIRS="${_DIRS_SAMP:-}";;
		init) ___DIRS="${_DIRS_INIT:-}";;
		*   ) ___DIRS="${_DIRS_ORIG:-}";;
	esac
	___DIRS="${_DIRS_TGET:-}${___DIRS}"
	___BACK="${___PATH#"${_DIRS_TGET:-}/"}"
	___BACK="${___DIRS}/${___BACK#/}"
	mkdir -p "${___BACK%/*}"
	chmod 600 "${___DIRS%/*}"
	if [ -e "${___BACK}" ] || [ -L "${___BACK}" ]; then
		___BACK="${___BACK}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	fi
	fnMsgout "backup" "[${___PATH}]${_DBGS_FLAG:+" -> [${___BACK}]"}"
	cp --archive "${___PATH}" "${___BACK}"
}
