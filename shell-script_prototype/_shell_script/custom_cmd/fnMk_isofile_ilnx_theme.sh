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

		# MENU COLOR <Item>  <ANSI Seq.> <foreground> <background> <shadow type>
		menu color   screen       0       #80ffffff    #00000000        std      # background colour not covered by the splash image
		menu color   border       0       #ffffffff    #ee000000        std      # The wire-frame border
		menu color   title        0       #ffff3f7f    #ee000000        std      # Menu title text
		menu color   sel          0       #ff00dfdf    #ee000000        std      # Selected menu option
		menu color   hotsel       0       #ff7f7fff    #ee000000        std      # The selected hotkey (set with ^ in MENU LABEL)
		menu color   unsel        0       #ffffffff    #ee000000        std      # Unselected menu options
		menu color   hotkey       0       #ff7f7fff    #ee000000        std      # Unselected hotkeys (set with ^ in MENU LABEL)
		menu color   tabmsg       0       #c07f7fff    #00000000        std      # Tab text
		menu color   timeout_msg  0       #8000dfdf    #00000000        std      # Timout text
		menu color   timeout      0       #c0ff3f7f    #00000000        std      # Timout counter
		menu color   disabled     0       #807f7f7f    #ee000000        std      # Disabled menu options, including SEPARATORs
		menu color   cmdmark      0       #c000ffff    #ee000000        std      # Command line marker - The '> ' on the left when editing an option
		menu color   cmdline      0       #c0ffffff    #ee000000        std      # Command line - The text being edited
		menu color   scrollbar    0       #40000000    #00000000        std      # Scroll bar
		menu color   pwdborder    0       #80ffffff    #20ffffff        std      # Password box wire-frame border
		menu color   pwdheader    0       #80ff8080    #20ffffff        std      # Password box header
		menu color   pwdentry     0       #80ffffff    #20ffffff        std      # Password entry field
		menu color   help         0       #c0ffffff    #00000000        std      # Help text, if set via 'TEXT HELP ... ENDTEXT'

		menu margin               2
		menu vshift               3
		menu rows                12
		menu tabmsgrow           28
		menu cmdlinerow          26
		menu timeoutrow          26
		menu helpmsgrow          24
		#menu hekomsgendrow      38

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		${_MENU_TOUT:+"timeout ${_MENU_TOUT}0"}
		default auto-install
_EOT_
	unset __TITL
}
