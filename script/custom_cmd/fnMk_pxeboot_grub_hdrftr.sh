# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make header and footer for grub.cfg in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
#   g-var : _MENU_RESO : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
function fnMk_pxeboot_grub_hdrftr() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		set default="0"
		set timeout="-1"

		if [ "x\${feature_default_font_path}" = "xy" ] ; then
		  font="unicode"
		else
		  font="\${prefix}/fonts/font.pf2"
		fi

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
		  set gfxpayload="keep"
		  if [ "\${grub_platform}" = "efi" ]; then
		    insmod efi_gop
		    insmod efi_uga
		  else
		    insmod vbe
		    insmod vga
		  fi
		  insmod gfxterm
		  insmod gettext
		  terminal_output gfxterm
		fi

		set menu_color_normal="cyan/blue"
		set menu_color_highlight="white/blue"

		#export lang
		export gfxmode
		export gfxpayload
		export menu_color_normal
		export menu_color_highlight

		insmod play
		play 960 440 1 0 4 440 1

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
}
