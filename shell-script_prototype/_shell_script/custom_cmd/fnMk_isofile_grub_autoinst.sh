# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make autoinst.cfg files for grub.cfg
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : theme.txt file name
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : initrd path (gui)
#   input :     $7     : nic name
#   input :     $8     : host name
#   input :     $9     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var : _OSET_MDIA : read
#   g-var : _NWRK_HOST : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NICS_NAME : read
#   g-var : _IPV4_ADDR : read
#   g-var : _IPV4_MASK : read
#   g-var : _IPV4_GWAY : read
#   g-var : _IPV4_NSVR : read
function fnMk_isofile_grub_autoinst() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare -r    __PATH_THME="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __PATH_GUIS="${6:-}"
	declare -r    __NICS_NAME="${7:?}"
	declare -r    __NWRK_HOST="${8:?}"
	declare -r    __IPV4_CIDR="${9:-}"
	declare -r -a __OPTN_BOOT=("${@:10}")
	declare       __DIRS=""
	declare       __TITL=""
	__TITL="$(printf "%s%s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	# --- common settings -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		set default="0"
		set timeout="${_MENU_TOUT:-5}"

		if [ "x\${feature_default_font_path}" = "xy" ] ; then
		  font="unicode"
		else
		  font="\${prefix}/fonts/font.pf2"
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
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

		#set timeout_style=menu
		#set color_normal=light-gray/black
		#set color_highlight=white/dark-gray
		#export color_normal
		#export color_highlight

		set theme=${__PATH_THME:-}
		export theme

		#insmod play
		#play 960 440 1 0 4 440 1
_EOT_
	# --- default--------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

		menuentry 'Automatic installation' {
		  echo 'Loading ${__TITL:+"${__TITL} "}...'
		  set gfxpayload="keep"
		  set background_color="black"
		  set hostname="${__NWRK_HOST}"
		  set ethrname="${__NICS_NAME}"
		  set ipv4addr="${_IPV4_ADDR:-}${__IPV4_CIDR:-}"
		  set ipv4mask="${_IPV4_MASK:-}"
		  set ipv4gway="${_IPV4_GWAY:-}"
		  set ipv4nsvr="${_IPV4_NSVR:-}"
		  set srvraddr="${_SRVR_PROT:?}://${_SRVR_ADDR:?}"
		  set autoinst="${__OPTN_BOOT[0]:-}"
		  set language="${__OPTN_BOOT[1]:-}"
		  set networks="${__OPTN_BOOT[2]:-}"
		  set otheropt="${__OPTN_BOOT[@]:3}"
		  set options="\${autoinst} \${language} \${networks} \${otheropt}"
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  linux  ${__PATH_FKNL:-} \${options} --- quiet
		  initrd ${__PATH_FIRD:-}
		}
_EOT_
	# --- gui -----------------------------------------------------------------
	if [[ -n "${__PATH_GUIS:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

			menuentry 'Graphical automatic installation' {
			  echo 'Loading ${__TITL:+"${__TITL} "}...'
			  set gfxpayload="keep"
			  set background_color="black"
			  set hostname="${__NWRK_HOST}"
			  set ethrname="${__NICS_NAME}"
			  set ipv4addr="${_IPV4_ADDR:-}${__IPV4_CIDR:-}"
			  set ipv4mask="${_IPV4_MASK:-}"
			  set ipv4gway="${_IPV4_GWAY:-}"
			  set ipv4nsvr="${_IPV4_NSVR:-}"
			  set srvraddr="${_SRVR_PROT:?}://${_SRVR_ADDR:?}"
			  set autoinst="${__OPTN_BOOT[0]:-}"
			  set language="${__OPTN_BOOT[1]:-}"
			  set networks="${__OPTN_BOOT[2]:-}"
			  set otheropt="${__OPTN_BOOT[@]:3}"
			  set options="\${autoinst} \${language} \${networks} \${otheropt}"
			  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			  echo 'Loading boot files ...'
			  linux  ${__PATH_FKNL:-} \${options} --- quiet
			  initrd ${__PATH_GUIS:-}
			}
_EOT_
	fi
	# --- system command ------------------------------------------------------
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
#
#		menuentry '[ System command ]' {
#		  true
#		}
#
#		menuentry '- System shutdown' {
#		  echo "System shutting down ..."
#		  halt
#		}
#
#		menuentry '- System restart' {
#		  echo "System rebooting ..."
#		  reboot
#		}
#
#		if [ "\${grub_platform}" = "efi" ]; then
#		  menuentry '- Boot from next volume' {
#		    exit 1
#		  }
#
#		  menuentry '- UEFI Firmware Settings' {
#		    fwsetup
#		  }
#		fi
#_EOT_
	unset __DIRS __TITL
}
