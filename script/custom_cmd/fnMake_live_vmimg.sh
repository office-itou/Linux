# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image
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
function fnMake_live_vmimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DIST="${1:-}"	# distribution
	declare -r    __TGET_VERS="${2:-}"	# version
	declare -r    __TGET_EDTN="${3:-}"	# edition
	declare -r    __TGET_VLID="${4:-}"	# volume id
	declare -r    __TGET_OUTD="${5:-}"	# output directory
	declare       __STRG=""				# storage
	declare       __LOOP=""				# loop device name
	declare       __UUID=""				# loopXp2 uuid device name
	declare       __RTFS=""				# root image
	declare       __RTLP=""				# root image loop
	declare       __RTMP=""				# root image mount point
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __WORK=""				# work
	# --- create dummy storage ------------------------------------------------
	__STRG="${__TGET_OUTD:?}/vm_uefi_${__TGET_VLID,,}.raw"
	truncate --size=20G "${__STRG:?}"
	__LOOP="$(losetup --find --show "${__STRG}")"
	partprobe "${__LOOP:?}"
	sfdisk --force --wipe always "${__LOOP}" <<- _EOT_
		,100MiB,U
		,,L
_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1
	mkfs.ext4 -F "${__LOOP}"p2
	__UUID="$(lsblk --noheadings --output=UUID "${__LOOP}"p2)"
	# --- file copy -----------------------------------------------------------
	__RTFS="${__TGET_OUTD:?}/${_FILE_RTFS:?}"
	__RTMP="${__TGET_OUTD:?}/${_DIRS_RTMP:?}"
	__RTLP="$(losetup --find --show "${__RTFS}")"
	partprobe "${__RTLP:?}"
	mkdir -p "${__RTMP:?}"
	mount -r "${__RTLP}"p1 "${__RTMP}"
	__WORK="$(fnFind_kernel "${__RTMP}")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	fnMake_live_vmimg_p1 "${__LOOP:?}" "p1" "${__UUID:?}" "${__TGET_DIST:?}" "${__TGET_VLID:?}" "${__TGET_OUTD:?}" "${__RTMP:?}" "${__VLNZ}" "${__IRAM}"
	fnMake_live_vmimg_p2 "${__LOOP:?}" "p2" "${__UUID:?}" "${__TGET_DIST:?}" "${__TGET_VLID:?}" "${__TGET_OUTD:?}" "${__RTMP:?}" "${__VLNZ}" "${__IRAM}"
	umount "${__RTMP}"
	losetup --detach "${__RTLP}"
	losetup --detach "${__LOOP}"

	unset __WORK __IRAM __VLNZ __RTMP __RTLP __RTFS __UUID __LOOP __STRG
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
