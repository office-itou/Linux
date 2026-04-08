# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create cdfs)
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
#   g-var : _DIRS_RTFS : read
function fnMake_live_cdimg_cdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare       __STRG=""				# storage
	declare       __RTIM=""				# root image
	declare       __RTLP=""				# root image loop
	declare       __RTFS=""				# root image mount point
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __CDFS=""				# cdfs image mount point
	declare       __SQFS=""				# squashfs
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __SPLS=""				# splash.png
	declare       __PATH=""				# work
	declare       __PSEC=""				# work
	declare       __STRT=""				# work
	declare       __SIZE=""				# work
	declare       __CONT=""				# work
	declare       __WORK=""				# work
	# --- local ---------------------------------------------------------------
	__STRG="${__TGET_OUTD:?}/vm_uefi_${__TGET_VLID,,}.raw"
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	__SQFS="${__TGET_OUTD:?}/${_FILE_SQFS:?}"
	__MBRF="${__TGET_OUTD:?}/${_FILE_MBRF:?}"
	__UEFI="${__TGET_OUTD:?}/${_FILE_UEFI:?}"
	__SPLS="${__TGET_OUTD:?}/${_MENU_SPLS:?}"
	__RTIM="${__TGET_OUTD:?}/${_FILE_RTIM:?}"
	__RTFS="${__TGET_OUTD:?}/${_DIRS_RTFS:?}"
	# --- create uefi/bios image ----------------------------------------------
	__RTLP="$(losetup --find --show "${__RTIM}")" && _LIST_RMOV+=("${__RTLP}")
	partprobe "${__RTLP:?}"
#	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__RTLP}"p1)"
#	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK:-}")
#	__CONT="$(("${__SIZE}" / "${__PSEC}"))"
#	dd if="${__RTIM}" of="${__UEFI}" bs="${__PSEC}" skip="${__STRT}" count="${__CONT}"
#	dd if="${__RTIM}" of="${__MBRF}" bs=1 count=440
	# --- mount root image ----------------------------------------------------
	mkdir -p "${__RTFS:?}"
	mount -r "${__RTLP}"p1 "${__RTFS}"
	__WORK="$(fnFind_kernel "${__RTFS}")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	# --- create splash.png ---------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -p -r | gzip -d -k > "${__SPLS:?}"
		1f8b0808462b8d69000373706c6173682e706e6700eb0cf073e7e592e262
		6060e0f5f47009626060566060608ae060028a888a88aa3330b0767bba38
		8654dc7a7b909117287868c177ff5c3ef3050ca360148c8251300ae8051a
		c299ff4c6660bcb6edd00b10d7d3d5cf659d53421300e6198186c4050000
_EOT_
	# --- create squashfs -----------------------------------------------------
	fnMk_squashfs "${__RTFS:?}" "${__SQFS:?}"
	# --- create cdfs image ---------------------------------------------------
	mkdir -p "${__CDFS:?}"/{.disk,EFI/BOOT,boot/grub/{live-theme,x86_64-efi,i386-pc},isolinux,LiveOS}
	touch "${__CDFS}/.disk/info"
	[[ -e "${__UEFI:?}"                                 ]] && cp --preserve=timestamps             "${__UEFI:?}"                                 "${__CDFS:?}"/boot/grub
	[[ -e "${__SQFS:?}"                                 ]] && cp --preserve=timestamps             "${__SQFS:?}"                                 "${__CDFS:?}"/LiveOS
	[[ -e "${__SPLS:?}"                                 ]] && cp --preserve=timestamps             "${__SPLS:?}"                                 "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__IRAM:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__IRAM:?}"                     "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__VLNZ:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__VLNZ:?}"                     "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__IRAM:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__IRAM:?}"                     "${__CDFS:?}"/LiveOS/initrd.img
	[[ -e "${__RTFS:?}/${__VLNZ:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__VLNZ:?}"                     "${__CDFS:?}"/LiveOS/vmlinuz
	[[ -e "${__RTFS:?}"/usr/lib/ISOLINUX/isolinux.bin   ]] && cp --preserve=timestamps             "${__RTFS:?}"/usr/lib/ISOLINUX/isolinux.bin   "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/syslinux/mbr/gptmbr.bin ]] && cp --preserve=timestamps             "${__RTFS:?}"/usr/lib/syslinux/mbr/gptmbr.bin "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/syslinux/modules/bios/. ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/syslinux/modules/bios/. "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/grub/x86_64-efi/.       ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/grub/x86_64-efi/.       "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__RTFS:?}"/usr/lib/grub/i386-pc/.          ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/grub/i386-pc/.          "${__CDFS:?}"/boot/grub/i386-pc
	[[ -e "${__RTFS:?}"/usr/share/syslinux/.            ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/syslinux/.            "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/share/grub2/x86_64-efi/.    ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/grub2/x86_64-efi/.    "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__RTFS:?}"/usr/share/grub2/i386-pc/.       ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/grub2/i386-pc/.       "${__CDFS:?}"/boot/grub/i386-pc
	# --- security option -----------------------------------------------------
	[[ -e "${__RTFS:?}"/usr/sbin/getenforce ]] && _SECU_OPTN="${_SECU_SLNX:-}"
	[[ -e "${__RTFS:?}"/usr/bin/aa-enabled  ]] && _SECU_OPTN="${_SECU_APPA:-}"
	readonly _SECU_OPTN
	# --- umount root image ---------------------------------------------------
	umount "${__RTFS}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	losetup --detach "${__RTLP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")

	unset __WORK __CONT __SIZE __STRT __PSEC __PATH __UEFI __MBRF __SQFS __CDFS __IRAM __VLNZ __RTFS __RTLP __RTIM

	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
