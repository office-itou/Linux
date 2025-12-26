# shellcheck disable=SC2148

# descript: make customize iso files
#   input :     $1     : target directory
#   input :     $2     : output file name
#   input :     $3     : volume id
#   input :     $4     : grub mbr file name
#   input :     $5     : uefi file name
#   input :     $6     : eltorito catalog file name
#   input :     $7     : eltorito boot file name
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnMk_isofile_rebuild() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_ISOS="${2:?}"	# output file name
	declare -r    __FILE_VLID="${3:?}"	# volume id
	declare -r    __FILE_BIOS="${4:?}"	# grub mbr file name
	declare -r    __FILE_UEFI="${5:?}"	# uefi file name
	declare -r    __FILE_BCAT="${6:?}"	# eltorito catalog file name
	declare -r    __FILE_ETRI="${7:?}"	# eltorito boot file name
	declare -r -a __OPTN=(\
		-quiet -rational-rock \
		${__FILE_VLID:+-volid "${__FILE_VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		${__FILE_BIOS:+--grub2-mbr "${__FILE_BIOS}"} \
		--mbr-force-bootable \
		${__FILE_UEFI:+-append_partition 2 0xEF "${__FILE_UEFI}"} \
		-appended_part_as_gpt \
		${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"} \
		${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}"} \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot
	)

	echo "create iso image file ..."
	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! nice -n 19 xorrisofs "${__OPTN[@]}" -output "${__FILE_WORK}" .; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${__FILE_ISOS##*/}" 1>&2
		else
			if ! cp --preserve=timestamps "${__FILE_WORK}" "${__FILE_ISOS}"; then
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${__FILE_ISOS##*/}" 1>&2
			else
				ls -lh "${__FILE_ISOS}"
				printf "\033[m\033[42m%20.20s: %s\033[m\n" "complete" "${__FILE_ISOS}" 1>&2
			fi
		fi
		rm -f "${__FILE_WORK:?}"
	popd > /dev/null || exit

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}