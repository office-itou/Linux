# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create grub)
#   input :     $1     : output directory
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_CDFS : read
#   g-var : _FILE_GCFG : read
#   g-var : _FILE_MENU : read
#   g-var : _FILE_THME : read
#   g-var : _SECU_APPA : read
#   g-var : _SECU_SLNX : read
#   g-var : _MENU_TOUT : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
#   g-var : _MENU_SPLS : read
function fnMake_live_cdimg_grub() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare       __INPD=""				# input directory
	declare       __OUTD=""				# output directory
	declare       __CDFS=""				# cdfs image mount point
	declare       __EGRU=""				# grub.cfg (/EFI/BOOT)
	declare       __GRUB=""				# grub.cfg (/boot/grub)
#	declare       __ICFG=""				# isolinux.cfg
	declare       __MENU=""				# menu.cfg
	declare       __THME=""				# theme.cfg
	declare       __TITL=""				# title
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __WORK=""				# work
	# --- local ---------------------------------------------------------------
	__INPD="/boot/grub"
	__OUTD="${__TGET_OUTD:?}/grub"
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	mkdir -p "${__OUTD:?}"
	__EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"
	__GRUB="${__OUTD:?}/${_FILE_GCFG:?}"
#	__ICFG="${__OUTD:?}/${_FILE_ICFG:?}"
	__MENU="${__OUTD:?}/${_FILE_MENU:?}"
	__THME="${__OUTD:?}/${_FILE_THME:?}"
	__TITL="Live system"
	__WORK="$(fnFind_kernel "${__CDFS}/LiveOS")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	__VLNZ="/LiveOS/${__VLNZ:?}"
	__IRAM="/LiveOS/${__IRAM:?}"
	# --- /EFI/BOOT/grub.cfg --------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__EGRU:?}"
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	# --- create grub.cfg -----------------------------------------------------
	fnGrub_conf  "${__GRUB:?}" "${__INPD:-}/${_FILE_MENU:?}" "${__INPD:-}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "/LiveOS/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_VLID}" {
		  set gfxpayload="keep"
		  set background_color="black"
		  set options="root=live:CDLABEL=${__TGET_VLID} rd.live.image rd.live.overlay.overlayfs=1${_SECU_OPTN:+" ${_SECU_OPTN}"}"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__VLNZ:?} \${options} --- quiet
		  echo 'Loading initramfs ...'
		  initrd ${__IRAM:?}
		}
_EOT_
	[[ -e "${__EGRU:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__CDFS:?}/EFI/BOOT/${_FILE_GCFG##*/}"
	[[ -e "${__GRUB:?}" ]] && cp --preserve=timestamps "${__GRUB:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}/${__INPD:?}"

	unset __WORK __IRAM __VLNZ __TITL __THME __MENU __ICFG __GRUB __EGRU __CDFS __OUTD __INPD
}
