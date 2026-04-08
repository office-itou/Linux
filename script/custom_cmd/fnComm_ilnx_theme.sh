# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: isolinux theme install
#   input :     $1     : target path
#   input :     $2     : menu title
#   input :     $3     : splash.png
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnIlnx_theme() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_TITL="${2:?}"	# menu title
	declare -r    __TGET_SPLS="${3:-}"	# splash.png

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		menu clear
		${__TGET_SPLS:+"menu background ${__TGET_SPLS}"}
		${__MENU_TITL:+"menu title Boot Menu: ${__MENU_TITL}"}

		# MENU COLOR <Item>  <ANSI Seq.> <foreground> <background> <shadow type>
		menu color   screen       *       #80ffffff    #00000000         *       # background colour not covered by the splash image
		menu color   border       *       #ffffffff    #ee000000         *       # The wire-frame border
		menu color   title        *       #ffff3f7f    #ee000000         *       # Menu title text
		menu color   sel          *       #ff00dfdf    #ee000000         *       # Selected menu option
		menu color   hotsel       *       #ff7f7fff    #ee000000         *       # The selected hotkey (set with ^ in MENU LABEL)
		menu color   unsel        *       #ffffffff    #ee000000         *       # Unselected menu options
		menu color   hotkey       *       #ff7f7fff    #ee000000         *       # Unselected hotkeys (set with ^ in MENU LABEL)
		menu color   tabmsg       *       #c07f7fff    #00000000         *       # Tab text
		menu color   timeout_msg  *       #8000dfdf    #00000000         *       # Timout text
		menu color   timeout      *       #c0ff3f7f    #00000000         *       # Timout counter
		menu color   disabled     *       #807f7f7f    #ee000000         *       # Disabled menu options, including SEPARATORs
		menu color   cmdmark      *       #c000ffff    #ee000000         *       # Command line marker - The '> ' on the left when editing an option
		menu color   cmdline      *       #c0ffffff    #ee000000         *       # Command line - The text being edited
		menu color   scrollbar    *       #40000000    #00000000         *       # Scroll bar
		menu color   pwdborder    *       #80ffffff    #20ffffff         *       # Password box wire-frame border
		menu color   pwdheader    *       #80ff8080    #20ffffff         *       # Password box header
		menu color   pwdentry     *       #80ffffff    #20ffffff         *       # Password entry field
		menu color   help         *       #c0ffffff    #00000000         *       # Help text, if set via 'TEXT HELP ... ENDTEXT'

		menu margin               2
		menu vshift               3
		menu rows                12
		menu tabmsgrow           28
		menu cmdlinerow          20
		menu timeoutrow          26
		menu helpmsgrow          22
		menu hekomsgendrow       38

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
