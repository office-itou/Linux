# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create grub)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : menu entry
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_CDFS : read
#   g-var : _FILE_GCFG : read
#   g-var : _FILE_MENU : read
#   g-var : _FILE_THME : read
#   g-var : _PATH_VLNZ : read
#   g-var : _PATH_IRAM : read
#   g-var : _MENU_SPLS : read
#   g-var : _MENU_TOUT : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
#   g-var : _SECU_OPTN : read
function fnMake_live_cdimg_grub() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/grub"			# output directory
	declare -r    __STRG="${__TGET_OUTD:?}/strg"			# storage work
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __TITL="Live system"						# title
	declare -r    __VLNZ="${_PATH_VLNZ:+"${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_PATH_VLNZ##*/}"}"		# kernel
	declare -r    __IRAM="${_PATH_IRAM:+"${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_PATH_IRAM##*/}"}"		# initramfs
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	# --- /EFI/BOOT/grub.cfg --------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__EGRU:?}"
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	# --- create grub.cfg -----------------------------------------------------
	fnGrub_conf  "${__GCFG:?}" "${__INPD:-}/${_FILE_MENU:?}" "${__INPD:-}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "${_DIRS_LIVE:+"/${_DIRS_LIVE}"}/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_ENTR}" {
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
	[[ -e "${__GCFG:?}" ]] && cp --preserve=timestamps "${__GCFG:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}/${__INPD:?}"
#	unset 
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
