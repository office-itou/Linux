# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : storage
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _MKOS_OUTP : read
function fnMake_live_cdimg() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __TGET_STRG="${4:?}"	# storage
	declare -r    __TGET_ISOS="${5:?}"	# output file name
	declare       __CDFS=""				# cdfs image mount point
	declare       __VLID=""				# volume id
	declare       __ISOS=""				# output file name
	declare       __HBRD=""				# iso hybrid mbr file name
	declare       __MBRF=""				# mbr image
	declare       __UEFI=""				# uefi image
	declare       __BCAT=""				# boot catalog
	declare       __ETRI=""				# eltorito
	declare       __BIOS=""				# bios or uefi imga file path
	declare       __PATH=""				# work
	# --- create cd-image image -----------------------------------------------
	fnMake_live_cdimg_cdfs "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_STRG:?}"
	fnMake_live_cdimg_grub "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_ENTR:?}"
	fnMake_live_cdimg_ilnx "${__TGET_OUTD:?}" "${__TGET_VLID:?}" "${__TGET_ENTR:?}"
	# --- create iso image ----------------------------------------------------
	__CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"
	__VLID="${__TGET_VLID:?}"
	__ISOS="${__TGET_ISOS:?}"
#	__HBRD="/usr/lib/ISOLINUX/isohdpfx.bin"
	__MBRF="${__TGET_OUTD:?}/${_FILE_MBRF:?}"				# bios.img
	__UEFI="${__CDFS}/boot/grub/${_FILE_UEFI:?}"			# uefi.img
	__BCAT="${_FILE_BCAT:?}"								# boot.cat
	           __ETRI="$(find "${__CDFS:?}"/isolinux -name 'eltorito.img' -print -quit)"
	__ETRI="${__ETRI:-"$(find "${__CDFS:?}"/isolinux -name 'isolinux.bin' -print -quit)"}"
	           __BIOS="$(find "${__CDFS:?}"/isolinux -name 'gptmbr.bin'   -print -quit)"
	if [[ -n "${__HBRD:-}" ]] && [[ -e "${__HBRD:-}" ]]; then cp --preserve=timestamps "${__HBRD}" "${__TGET_OUTD}"; __HBRD="${__TGET_OUTD:?}/${__HBRD##*/}"; else __HBRD=""; fi
#	if [[ -n "${__MBRF:-}" ]] && [[ -e "${__MBRF:-}" ]]; then cp --preserve=timestamps "${__MBRF}" "${__TGET_OUTD}"; __MBRF="${__TGET_OUTD:?}/${__MBRF##*/}"; else __MBRF=""; fi
	if [[ -n "${__UEFI:-}" ]] && [[ -e "${__UEFI:-}" ]]; then cp --preserve=timestamps "${__UEFI}" "${__TGET_OUTD}"; __UEFI="${__TGET_OUTD:?}/${__UEFI##*/}"; else __UEFI=""; fi
#	if [[ -n "${__BCAT:-}" ]] && [[ -e "${__BCAT:-}" ]]; then cp --preserve=timestamps "${__BCAT}" "${__TGET_OUTD}"; __BCAT="${__TGET_OUTD:?}/${__BCAT##*/}"; else __BCAT=""; fi
#	if [[ -n "${__ETRI:-}" ]] && [[ -e "${__ETRI:-}" ]]; then cp --preserve=timestamps "${__ETRI}" "${__TGET_OUTD}"; __ETRI="${__TGET_OUTD:?}/${__ETRI##*/}"; else __ETRI=""; fi
#	if [[ -n "${__BIOS:-}" ]] && [[ -e "${__BIOS:-}" ]]; then cp --preserve=timestamps "${__BIOS}" "${__TGET_OUTD}"; __BIOS="${__TGET_OUTD:?}/${__BIOS##*/}"; else __BIOS=""; fi
#	__BIOS="${__BIOS:-"${__MBRF}"}"
	__ETRI="${__ETRI#"${__CDFS:-}/"}"
#	__BIOS="${__BIOS#"${__CDFS:?}/"}"
	find "${__CDFS:?}" -type d -exec chmod +rx,-w {} \;		# directory: r-x
	find "${__CDFS:?}" -type f -exec chmod +r,-w {} \;		# file     : r-?
	fnMk_xorrisofs "${__CDFS:?}" "${__ISOS:?}" "${__VLID:-}" "${__HBRD:-}" "${__BIOS:-}" "${__UEFI:-}" "${__BCAT:-}" "${__ETRI:-}"
	unset __BIOS __ETRI __BCAT __UEFI __MBRF __HBRD __ISOS __VLID __CDFS
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
