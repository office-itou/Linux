# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image
#   input :     $1     : distribution
#   input :     $2     : version
#   input :     $3     : edition
#   input :     $4     : volume id
#   input :     $5     : output directory
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _MKOS_OUTP : read
function fnMake_live_cdimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DIST="${1:?}"	# distribution
	declare -r    __TGET_VERS="${2:?}"	# version
	declare -r    __TGET_EDTN="${3:?}"	# edition
	declare -r    __TGET_VLID="${4:?}"	# volume id
	declare -r    __TGET_OUTD="${5:?}"	# output directory
	declare       __RTFS=""				# root image
	declare       __RTLP=""				# root image loop
	declare       __RTMP=""				# root image mount point
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __SQFS=""				# squashfs
	declare       __CDFS=""				# cdfs image mount point
	declare       __ISOS=""				# output file name
	declare       __VLID=""				# volume id
	declare       __HBRD=""				# iso hybrid mbr file name
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __BCAT=""				# boot catalog
	declare       __ETRI=""				# eltorito
	declare       __BIOS=""				# bios or uefi imga file path
	declare       __SECU=""				# security
	declare       __SPLS=""				# splash.png
	declare       __SRCS=""				# work
	declare       __DEST=""				# work
	declare       __WORK=""				# work
	# --- create cd-image image -----------------------------------------------
	fnMake_live_cdimg_cdfs "${__TGET_OUTD:?}"
	fnMake_live_cdimg_grub "${__TGET_OUTD:?}" "${__TGET_VLID:?}"
	fnMake_live_cdimg_ilnx "${__TGET_OUTD:?}" "${__TGET_VLID:?}"
	# --- create iso image ----------------------------------------------------
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	__VLID="${__TGET_VLID^^}"
	__ISOS="${_DIRS_RMAK:?}/live-${__VLID,,}.iso"
#	__HBRD="/usr/lib/ISOLINUX/isohdpfx.bin"
	__UEFI="boot/grub/${_FILE_UEFI:?}"
	__BCAT="isolinux/${_FILE_BCAT:?}"
	           __ETRI="$(find "${__CDFS:?}"/isolinux -name 'eltorito.sys' -print -quit)"
	__ETRI="${__ETRI:-"$(find "${__CDFS:?}"/isolinux -name 'isolinux.bin' -print -quit)"}"
	           __BIOS="$(find "${__CDFS:?}"/isolinux -name 'gptmbr.bin'   -print -quit)"
	__BIOS="${__BIOS:-"${__MBRF}"}"
	__ETRI="${__ETRI#"${__CDFS:-}/"}"
	__BIOS="${__BIOS#"${__CDFS:?}/"}"
	fnMk_xorrisofs "${__CDFS:?}" "${__ISOS:?}" "${__VLID:-}" "${__HBRD:-}" "${__BIOS:-}" "${__UEFI:-}" "${__BCAT:-}" "${__ETRI:-}"
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
