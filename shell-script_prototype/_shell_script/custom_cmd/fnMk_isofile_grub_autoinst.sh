# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make autoinst.cfg files for grub.cfg
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : host name
#   input :     $7     : ipv4 cidr
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
function fnMk_isofile_ilnx_autoinst() {
	declare -r    __FILE_NAME="${1:?}"
	declare -r    __TIME_STMP="${2:?}"
	declare -r    __PATH_FKNL="${3:?}"
	declare -r    __PATH_FIRD="${4:?}"
	declare -r    __NWRK_HOST="${5:?}"
	declare -r    __IPV4_CIDR="${6:?}"
	declare -a    __OPTN_BOOT=("${@:6}")
	declare       __DIRS=""
	declare       __TITL=""
	__TITL="$(printf "%s%19.19s" "${__FILE_NAME:-}" "${__TIME_STMP:-}")"
	# --- common settings -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		set default="0"
		set timeout="${_MENU_TOUT:-5}"

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

		if background_image /isolinux/${_MENU_SPLS:-} 2> /dev/null; then
		  set color_normal=light-gray/black
		  set color_highlight=white/black
		elif background_image /${_MENU_SPLS:-} 2> /dev/null; then
		  set color_normal=light-gray/black
		  set color_highlight=white/black
		else
		  set menu_color_normal=cyan/blue
		  set menu_color_highlight=white/blue
		fi

		set timeout_style=menu
		set theme=${__FTHM#"${__DIRS_TGET}"}
		export theme

		#export lang
		export gfxmode
		export gfxpayload
		export menu_color_normal
		export menu_color_highlight

		insmod play
		play 960 440 1 0 4 440 1
_EOT_
	# --- default--------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

		menuentry 'Automatic installation' {
		  echo 'Loading ${__TITL:+"${__TITL} "}...'
		  set hostname=${_NWRK_HOST/:_DISTRO_:/${__NWRK_HOST:-}}
		  set ethrname=${_NICS_NAME:-ens160}
		  set ipv4addr=${_IPV4_ADDR:-}${__IPV4_CIDR:-}
		  set ipv4mask=${_IPV4_MASK:-}
		  set ipv4gway=${_IPV4_GWAY:-}
		  set ipv4nsvr=${_IPV4_NSVR:-}
		  set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		  set autoinst=${__OPTN_BOOT[0]:-} ${__OPTN_BOOT[1]:-}
		  set language=${__OPTN_BOOT[2]:-}
		  set networks=${__OPTN_BOOT[3]:-}
		  set otheropt=${__OPTN_BOOT[@]:4}
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  insmod net
		  insmod http
		  insmod progress
		  echo Loading boot files ...
		  linux  ${__PATH_FKNL:-}
		  initrd ${__PATH_FIRD:-}
		}
_EOT_
	# --- gui -----------------------------------------------------------------
	__DIRS="$(fnDirname  "${__PATH_FIRD}")"
	if [[ -e "${__DIRS:-}"/gtk/${__PATH_FKNL##*/} ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

			menuentry 'Automatic installation gui' {
			  echo 'Loading ${__TITL:+"${__TITL} "}...'
			  set hostname=${_NWRK_HOST/:_DISTRO_:/${__NWRK_HOST:-}}
			  set ethrname=${_NICS_NAME:-ens160}
			  set ipv4addr=${_IPV4_ADDR:-}${__IPV4_CIDR:-}
			  set ipv4mask=${_IPV4_MASK:-}
			  set ipv4gway=${_IPV4_GWAY:-}
			  set ipv4nsvr=${_IPV4_NSVR:-}
			  set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
			  set autoinst=${__OPTN_BOOT[0]:-} ${__OPTN_BOOT[1]:-}
			  set language=${__OPTN_BOOT[2]:-}
			  set networks=${__OPTN_BOOT[3]:-}
			  set otheropt=${__OPTN_BOOT[@]:4}
			  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			  insmod net
			  insmod http
			  insmod progress
			  echo Loading boot files ...
			  linux  ${__PATH_FKNL:-}
			  initrd ${__DIRS:-}/gtk/${__PATH_FKNL##*/}
			}
_EOT_
	fi
	# --- system command ------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

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
	unset __DIRS
}
