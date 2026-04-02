# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: grub conf install
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
function fnGrub_conf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_MAIN="${2:?}"	# main menu
	declare -r    __MENU_THME="${3:-}"	# theme file
	declare -r    __MENU_TOUT="${4:-}"	# timeout (sec)
	declare -r    __MENU_RESO="${5:-}"	# resolution (widht x hight)
	declare -r    __MENU_DPTH="${6:-}"	# colors

	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}"
		set default="0"
		set timeout="${_MENU_TOUT:-5}"

		if [ "x\${font}" = "x" ] ; then
		  if [ "x\${feature_default_font_path}" = "xy" ] ; then
		    font="unicode"
		  else
		    font="\${prefix}/fonts/font.pf2"
		  fi
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}${_MENU_DPTH:+"x${_MENU_DPTH}"},"}auto
		  set gfxpayload="keep"
		  export gfxmode
		  export gfxpayload
		  if [ "\${grub_platform}" = "efi" ]; then
		    insmod efi_gop
		    insmod efi_uga
		  else
		    insmod vbe
		    insmod vga
		  fi
		  insmod video_bochs
		  insmod video_cirrus
		  insmod gfxterm
		  insmod gettext
		  insmod png
		  terminal_output gfxterm
		fi

		set timeout_style=menu
		set color_normal=light-gray/black
		set color_highlight=white/dark-gray
		export color_normal
		export color_highlight

		set theme=${__MENU_THME:-}
		export theme

		#insmod play
		#play 960 440 1 0 4 440 1

		source ${__MENU_MAIN:?}

		menuentry '[ System command ]' {
		  true
		}

		menuentry '- System shutdown' {
		  echo "System shutting down ..."
		  halt
		}

		menuentry '- System restart' {
		  echo "System rebooting ..."
		  reboot
		}

		if [ "\${grub_platform}" = "efi" ]; then
		  menuentry '- Boot from next volume' {
		    exit 1
		  }

		  menuentry '- UEFI Firmware Settings' {
		    fwsetup
		  }
		fi

_EOT_
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
