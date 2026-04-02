# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: grub theme install
#   input :     $1     : target path
#   input :     $2     : menu title
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnGrub_theme() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_TITL="${2:?}"	# menu title

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		desktop-image: ":_DTPIMG_:"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		${__TITL:+"title-text: \"Boot Menu: ${__TITL}"\"}
		message-font: "Unifont Regular 16"
		terminal-font: "Unifont Regular 16"
		terminal-border: "0"

		#help bar at the bottom
		+ label {
		  top = 100%-50
		  left = 0
		  width = 100%
		  height = 20
		  text = "@KEYMAP_SHORT@"
		  align = "center"
		  color = "#ffffff"
		  font = "Unifont Regular 16"
		}

		#boot menu
		+ boot_menu {
		  left = 10%
		  width = 80%
		  top = 20%
		  height = 50%-80
		  item_color = "#a8a8a8"
		  item_font = "Unifont Regular 16"
		  selected_item_color= "#ffffff"
		  selected_item_font = "Unifont Regular 16"
		  item_height = 16
		  item_padding = 0
		  item_spacing = 4
		  icon_width = 0
		  icon_heigh = 0
		  item_icon_space = 0
		}

		#progress bar
		+ progress_bar {
		  id = "__timeout__"
		  left = 15%
		  top = 100%-80
		  height = 16
		  width = 70%
		  font = "Unifont Regular 16"
		  text_color = "#000000"
		  fg_color = "#ffffff"
		  bg_color = "#a8a8a8"
		  border_color = "#ffffff"
		  text = "@TIMEOUT_NOTIFICATION_LONG@"
		}
_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
