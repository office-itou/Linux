# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: isolinux conf install
#   input :     $1     : target path
#   input :     $2     : main menu
#   input :     $3     : theme file
#   input :     $4     : timeout (sec)
#   input :     $5     : resolution (widht x hight)
#   input :     $6     : colors
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnIlnx_conf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_MAIN="${2:?}"	# main menu
	declare -r    __MENU_THME="${3:-}"	# theme file
	declare -r    __MENU_TOUT="${4:-}"	# timeout (sec)

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		path ./
		prompt 0
		#timeout 0
		default vesamenu.c32

		include ${__MENU_THME:?}

		timeout ${__MENU_TOUT:-5}0
		#default auto-install

		include ${__MENU_MAIN:?}
_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
