# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: find service
#   input :     $1     : service name
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
fnFind_serivce() {
	find "${_DIRS_TGET:-}"/lib/systemd/ "${_DIRS_TGET:-}"/usr/lib/systemd/ \( -name "${1:?}" ${2:+-o -name "$2"} ${3:+-o -name "$3"} \) 2> /dev/null || true
}
