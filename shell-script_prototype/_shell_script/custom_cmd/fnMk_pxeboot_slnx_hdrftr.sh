# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make header and footer for syslinux in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
#   g-var : _MENU_RESO : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
function fnMk_pxeboot_slnx_hdrftr() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		path ./
		prompt 0
		timeout 0
		default vesamenu.c32

		menu resolution ${_MENU_RESO/x/ }

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

		menu title - Boot Menu -
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		label System-command
		  menu label ^[ System command ... ]

		label Hardware-info
		  menu label ^- Hardware info
		  com32 hdt.c32

		label System-shutdown
		  menu label ^- System shutdown
		  com32 poweroff.c32

		label System-restart
		  menu label ^- System restart
		  com32 reboot.c32
_EOT_
}
