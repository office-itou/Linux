# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create isolinux)
#   input :     $1     : output directory
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_CDFS : read
#   g-var : _FILE_SQFS : read
#   g-var : _FILE_MBRF : read
#   g-var : _FILE_UEFI : read
#   g-var : _MENU_SPLS : read
#   g-var : _FILE_RTFS : read
#   g-var : _DIRS_RTMP : read
function fnMake_live_cdimg_ilnx() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare       __RTFS=""				# root image
	declare       __RTLP=""				# root image loop
	declare       __RTMP=""				# root image mount point
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __CDFS=""				# cdfs image mount point
	declare       __EGRU=""				# grub.cfg (/EFI/BOOT)
	declare       __GRUB=""				# grub.cfg (/boot/grub)
	declare       __MENU=""				# menu.cfg
	declare       __THME=""				# theme.cfg
#	declare       __SPLS=""				# splash.png
	declare       __TITL=""				# title
	declare       __SECU=""				# security
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __WORK=""				# work
	# --- local ---------------------------------------------------------------
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	__EGRU="${__TGET_OUTD:?}/${_FILE_GRUB:?}.efi"
	__GRUB="${__TGET_OUTD:?}/${_FILE_GRUB:?}"
	__MENU="${__TGET_OUTD:?}/${_FILE_MENU:?}"
	__THME="${__TGET_OUTD:?}/${_FILE_THME:?}"
#	__SPLS="/LiveOS/${_MENU_SPLS:?}"
	__TITL="Live system"
	[[ -e "${__TGET_RTMP:?}"/usr/bin/aa-enabled  ]] && __SECU="${_SECU_APPA:-}"
	[[ -e "${__TGET_RTMP:?}"/usr/sbin/getenforce ]] && __SECU="${_SECU_SLNX:-}"
	__WORK="$(fnFind_kernel "${__CDFS}")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	__VLNZ="${__VLNZ##*/}"
	__IRAM="${__IRAM##*/}"
	# --- /EFI/BOOT/grub.cfg --------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__EGRU:?}"
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	# --- create grub.cfg -----------------------------------------------------
	fnIlnx_conf  "${__GRUB:?}" "/boot/grub/${_FILE_MENU:?}" "/boot/grub/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnIlnx_theme "${__THME:?}" "${__TITL:?}" "/LiveOS/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		label live-amd64
		  menu label ^Live system (amd64)
		  menu default
		  linux  /LiveOS/${__VLNZ:?}
		  initrd /LiveOS/${__IRAM:?}
		  append root=live:CDLABEL=${__TGET_VLID:?} rd.live.image rd.live.overlay.overlayfs=1${__SECU:+" ${__SECU}"} --- quiet
_EOT_
	[[ -e "${__EGRU:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__CDFS:?}/EFI/BOOT/${_FILE_GRUB:?}"
	[[ -e "${__GRUB:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__CDFS:?}"/boot/grub
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}"/boot/grub
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}"/boot/grub

	unset __WORK __IRAM __VLNZ __SECU __TITL __THME __MENU __GRUB __EGRU __CDFS __IRAM __VLNZ __RTMP __RTLP __RTFS

	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
