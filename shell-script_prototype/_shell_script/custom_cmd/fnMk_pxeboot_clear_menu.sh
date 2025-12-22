# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: clear pxeboot menu
#   input :     $@     : file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
function fnMk_pxeboot_clear_menu() {
	declare       __DIRS=""
	__DIRS="$(fnDirname "${1:?}")"
	if [[ -z "${__DIRS:-}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "invalid value: [${1:-}]"
		return
	fi
	mkdir -p "${__DIRS:?}"
	: > "${1:?}"
}
