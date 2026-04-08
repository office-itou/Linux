# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : distribution
#   input :     $4     : version
#   input :     $5     : edition
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _MKOS_OUTP : read
function fnMake_live_vmimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:-}"	# output directory
	declare -r    __TGET_VLID="${2:-}"	# volume id
	declare -r    __TGET_DIST="${3:-}"	# distribution
	declare -r    __TGET_VERS="${4:-}"	# version
	declare -r    __TGET_EDTN="${5:-}"	# edition
	declare       __STRG=""				# storage
	declare       __LOOP=""				# loop device name
	declare       __UUID=""				# loopXp2 uuid device name
	declare       __RTIM=""				# root image
	declare       __RTFS=""				# root image mount point
	declare       __RTLP=""				# root image loop
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __PATH=""				# work
	declare       __PSEC=""				# work
	declare       __STRT=""				# work
	declare       __SIZE=""				# work
	declare       __CONT=""				# work
	declare       __WORK=""				# work
	# --- create dummy storage ------------------------------------------------
	__STRG="${__TGET_OUTD:?}/vm_uefi_${__TGET_VLID,,}.raw"
	truncate --size=20G "${__STRG:?}"
	__LOOP="$(losetup --find --show "${__STRG}")" && _LIST_RMOV+=("${__LOOP}")
	partprobe "${__LOOP:?}"
	sfdisk --force --wipe always "${__LOOP}" <<- _EOT_
		,100MiB,U
		,,L
_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1
	mkfs.ext4 -F "${__LOOP}"p2
	partprobe "${__LOOP:?}"
	sleep 1
	__UUID="$(lsblk --noheadings --output=UUID "${__LOOP}"p2)"
	# --- file copy -----------------------------------------------------------
	__RTIM="${__TGET_OUTD:?}/${_FILE_RTIM:?}"
	__RTFS="${__TGET_OUTD:?}/${_DIRS_RTFS:?}"
	__RTLP="$(losetup --find --show "${__RTIM}")" && _LIST_RMOV+=("${__RTLP}")
	partprobe "${__RTLP:?}"
	mkdir -p "${__RTFS:?}"
	mount -r "${__RTLP}"p1 "${__RTFS}" && _LIST_RMOV+=("${__RTFS}")
	__WORK="$(fnFind_kernel "${__RTFS}")"
	read -r __VLNZ __IRAM < <(echo "${__WORK:-}")
	__VLNZ="/${__VLNZ:?}"
	__IRAM="/${__IRAM:?}"
	fnMake_live_vmimg_p1 "${__LOOP:?}" "p1" "${__UUID:?}" "${__TGET_DIST:?}" "${__TGET_VLID:?}" "${__TGET_OUTD:?}" "${__RTFS:?}" "${__VLNZ}" "${__IRAM}"
	fnMake_live_vmimg_p2 "${__LOOP:?}" "p2" "${__UUID:?}" "${__TGET_DIST:?}" "${__TGET_VLID:?}" "${__TGET_OUTD:?}" "${__RTFS:?}" "${__VLNZ}" "${__IRAM}"
	umount "${__RTFS}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# --- create uefi/bios image ----------------------------------------------
	__MBRF="${__TGET_OUTD:?}/${_FILE_MBRF:?}"
	__UEFI="${__TGET_OUTD:?}/${_FILE_UEFI:?}"
	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__LOOP}"p1)"
	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK:-}")
	__CONT="$(("${__SIZE}" / "${__PSEC}"))"
	dd if="${__LOOP}" of="${__UEFI}" bs="${__PSEC}" skip="${__STRT}" count="${__CONT}"
	dd if="${__LOOP}" of="${__MBRF}" bs=1 count=440
	# -------------------------------------------------------------------------
	losetup --detach "${__RTLP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	losetup --detach "${__LOOP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")

	unset __WORK __CONT __SIZE __STRT __PSEC __PATH __UEFI __MBRF __IRAM __VLNZ __RTFS __RTLP __RTIM __UUID __LOOP __STRG
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
