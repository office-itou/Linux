# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create cdfs)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : storage
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_RMOV : read
#   g-var : _DIRS_CDFS : read
#   g-var : _FILE_SQFS : read
#   g-var : _MENU_SPLS : read
#   g-var : _FILE_MBRF : read
#   g-var : _FILE_UEFI : read
#   g-var : _PATH_VLNZ : read
#   g-var : _PATH_IRAM : read
function fnMake_live_cdimg_cdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_STRG="${3:-}"	# storage
	declare -r    __OUTD="${__TGET_OUTD:?}/grub"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt2"			# mount point
	declare -r    __STRG="${__TGET_OUTD:?}/strg"			# storage work
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __SQFS="${__TGET_OUTD:?}/${_FILE_SQFS:?}"	# squashfs
	declare -r    __SPLS="${__TGET_OUTD:?}/${_MENU_SPLS:?}"	# splash.png
#	declare -r    __MBRF="${__STRG:?}/${_FILE_MBRF:?}"		# mbr image
	declare -r    __UEFI="${__STRG:?}/${_FILE_UEFI:?}"		# uefi image
	declare -r    __TITL="Live system"						# title
	declare -r    __VLNZ="${_PATH_VLNZ:?}"					# kernel
	declare -r    __IRAM="${_PATH_IRAM:?}"					# initramfs
	declare       __LOOP=""									# loop device name
	# --- mount root image ----------------------------------------------------
	mkdir -p "${__MNTP:?}"
	__LOOP="$(losetup --find --show "${__TGET_STRG:?}")" && _LIST_RMOV+=("${__LOOP}")
	partprobe "${__LOOP:?}"
	mount -r "${__LOOP}"p2 "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	# --- create squashfs -----------------------------------------------------
	fnMk_squashfs "${__MNTP:?}" "${__SQFS:?}"
	# --- create cdfs image ---------------------------------------------------
	mkdir -p "${__CDFS:?}"/{.disk,EFI/BOOT,boot/grub/{live-theme,x86_64-efi,i386-pc},isolinux,"${_DIRS_LIVE:?}"}
	touch "${__CDFS}/.disk/info"
	[[ -e "${__UEFI:?}"                                 ]] && cp --preserve=timestamps             "${__UEFI:?}"                                 "${__CDFS:?}"/boot/grub
	[[ -e "${__SPLS:?}"                                 ]] && cp --preserve=timestamps             "${__SPLS:?}"                                 "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__SQFS:?}"                                 ]] && cp --preserve=timestamps             "${__SQFS:?}"                                 "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__IRAM#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__IRAM#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__VLNZ#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__VLNZ#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"
	[[ -e "${__MNTP:?}/${__IRAM#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__IRAM#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"/initrd.img
	[[ -e "${__MNTP:?}/${__VLNZ#/}"                     ]] && cp --preserve=timestamps             "${__MNTP:?}/${__VLNZ#/}"                     "${__CDFS:?}${_DIRS_LIVE:+"/${_DIRS_LIVE}"}"/vmlinuz
	[[ -e "${__MNTP:?}"/usr/lib/ISOLINUX/isolinux.bin   ]] && cp --preserve=timestamps             "${__MNTP:?}"/usr/lib/ISOLINUX/isolinux.bin   "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/syslinux/mbr/gptmbr.bin ]] && cp --preserve=timestamps             "${__MNTP:?}"/usr/lib/syslinux/mbr/gptmbr.bin "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/syslinux/modules/bios/. ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/syslinux/modules/bios/. "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/lib/grub/x86_64-efi/.       ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/grub/x86_64-efi/.       "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__MNTP:?}"/usr/lib/grub/i386-pc/.          ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/lib/grub/i386-pc/.          "${__CDFS:?}"/boot/grub/i386-pc
	[[ -e "${__MNTP:?}"/usr/share/syslinux/.            ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/syslinux/.            "${__CDFS:?}"/isolinux
	[[ -e "${__MNTP:?}"/usr/share/grub2/x86_64-efi/.    ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/grub2/x86_64-efi/.    "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__MNTP:?}"/usr/share/grub2/i386-pc/.       ]] && cp --preserve=timestamps --recursive "${__MNTP:?}"/usr/share/grub2/i386-pc/.       "${__CDFS:?}"/boot/grub/i386-pc
	# --- umount root image ---------------------------------------------------
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	losetup --detach "${__LOOP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __LOOP
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
