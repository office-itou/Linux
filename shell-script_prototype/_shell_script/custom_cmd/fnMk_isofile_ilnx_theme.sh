# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make theme.txt files for isolinux
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _MENU_RESO : read
#   g-var : _MENU_SPLS : read
#   g-var : _MENU_TOUT : read
#   g-var : _OSET_MDIA : read
function fnMk_isofile_ilnx_theme() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare       __TITL=""
	__TITL="$(printf "%s%s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		path ./
		prompt 0
		timeout 0
		default vesamenu.c32

		${_MENU_RESO:+"menu resolution ${_MENU_RESO/x/ }"}
		${__TITL:+"menu title Boot Menu: ${__TITL}"}
		${_MENU_SPLS:+"menu background ${_MENU_SPLS}"}

		menu color screen       * #ffffffff #ee000080 *
		menu color title        * #ffffffff #ee000080 *
		menu color border       * #ffffffff #ee000080 *
		menu color sel          * #ffffffff #76a1d0ff *
		menu color hotsel       * #ffffffff #76a1d0ff *
		menu color unsel        * #ffffffff #ee000080 *
		menu color hotkey       * #ffffffff #ee000080 *
		menu color tabmsg       * #ffffffff #ee000080 *
		menu color timeout_msg  * #ffffffff #ee000080 *
		menu color timeout      * #ffffffff #ee000080 *
		menu color disabled     * #ffffffff #ee000080 *
		menu color cmdmark      * #ffffffff #ee000080 *
		menu color cmdline      * #ffffffff #ee000080 *
		menu color scrollbar    * #ffffffff #ee000080 *
		menu color help         * #ffffffff #ee000080 *

		menu margin             4
		menu vshift             5
		menu rows               25
		menu tabmsgrow          31
		menu cmdlinerow         33
		menu timeoutrow         33
		menu helpmsgrow         37
		menu hekomsgendrow      39

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		${_MENU_TOUT:+"timeout ${_MENU_TOUT}0"}
		default auto-install
_EOT_
	unset __TITL
}
