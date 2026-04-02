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
		#timeout 0
		default :_VESA32_:

		menu clear
		#menu background splash.png
		menu background :_DTPIMG_:
		${_MENU_RESO:+"menu resolution ${_MENU_RESO/x/ }"}
		${__TITL:+"menu title Boot Menu: ${__TITL}"}

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
		menu cmdlinerow          26
		menu timeoutrow          26
		menu helpmsgrow          24
		menu hekomsgendrow       38

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		${_MENU_TOUT:+"timeout ${_MENU_TOUT}0"}
		#default auto-install
_EOT_
	unset __TITL
}
