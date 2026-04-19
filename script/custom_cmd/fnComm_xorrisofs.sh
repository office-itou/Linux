# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make iso files
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
function fnMk_xorrisofs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_ISOS="${2:?}"	# output file name
	declare -r    __FILE_VLID="${3:-}"	# volume id
	declare -r    __FILE_HBRD="${4:-}"	# iso hybrid mbr file name
	declare -r    __FILE_BIOS="${5:-}"	# grub mbr file name
	declare -r    __FILE_UEFI="${6:-}"	# uefi file name
	declare -r    __FILE_BCAT="${7:-}"	# eltorito catalog file name
	declare -r    __FILE_ETRI="${8:-}"	# eltorito boot file name
	declare -a    __OPTN=()
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
#	https://man.archlinux.org/man/xorrisofs.1.en
#	-quiet								Run quietly
#	-o FILE, -output FILE				Set output file name
#	-R, -rock							Generate Rock Ridge directory information
#	-J, -joliet							Generate Joliet directory information
#	-V ID, -volid ID					Set Volume ID
#	-iso-level number					Specify the ISO 9660 version which defines the limitations of file naming and data file size
#	--grub2-mbr FILE					Set GRUB2 MBR for boot image address patching
#	-partition_offset LBA				Make image mountable by first partition, too
#	-appended_part_as_gpt				mark appended partitions in GPT instead of MBR.
#	-append_partition NUMBER TYPE FILE	Append FILE after image. TYPE is hex: 0x.. or a GUID to be used if -appended_part_as_gpt.
#	-iso_mbr_part_type					Set type byte or GUID of ISO partition in MBR or type GUID if a GPT ISO partition emerges.
#	-c FILE, -eltorito-catalog FILE		Set El Torito boot catalog name
#	--boot-catalog-hide					Hide boot catalog from ISO9660/RR and Joliet
#	-b FILE, -eltorito-boot FILE		Set El Torito boot image name
#	-no-emul-boot						Boot image is 'no emulation' image
#	-boot-load-size #					Set numbers of load sectors
#	-boot-info-table					Patch boot image with info table
#	--grub2-boot-info					Patch boot image at byte 2548
#	-eltorito-alt-boot					Start specifying alternative El Torito boot parameters
#	-e FILE								Set EFI boot image name (more rawly)
#	-graft-points						Allow to use graft points for filenames

#	-isohybrid-mbr FILE										Set SYSLINUX mbr/isohdp[fp]x*.bin for isohybrid
#	-isohybrid-gpt-basdat									Mark El Torito boot image as Basic Data in GPT
#	-isohybrid-apm-hfsplus									Mark El Torito boot image as HFS+ in APM
#	-part_like_isohybrid									Mark in MBR, GPT, APM without -isohybrid-mbr
#	-efi-boot-part DISKFILE|--efi-boot-image				Set data source for EFI System Partition
	__OPTN=()
	__OPTN+=(
		-quiet
		-rock
		-joliet
		${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"}
		-iso-level 3
	)
	if [[ -n "${__FILE_HBRD:-}" ]]; then
		__OPTN+=(
			${__FILE_HBRD:+-isohybrid-mbr "${__FILE_HBRD}"}
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
		)
	else
		__OPTN+=(
			${__FILE_BIOS:+--grub2-mbr "${__FILE_BIOS}"}
			-partition_offset 16
			-appended_part_as_gpt
			-append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "${__FILE_UEFI}"
			-iso_mbr_part_type EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
		)
	fi
	__OPTN+=(
		${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"}
		--boot-catalog-hide
		${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}" -no-emul-boot}
		-boot-load-size 4
		-boot-info-table
		-eltorito-alt-boot
	)
	if [[ -n "${__FILE_HBRD:-}" ]]; then __OPTN+=(-e "${__FILE_UEFI}" -no-emul-boot)
	else                                 __OPTN+=(-e '--interval:appended_partition_2:all::' -no-emul-boot)
	fi
	__OPTN+=(
		-output "${__TEMP}"
		"${__DIRS_TGET:?}"
	)
	readonly      __OPTN
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	declare       __RTCD=""

	__time_start=$(date +%s)
	echo "create iso image file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	[[ -n "${__FILE_HBRD:-}" ]] && echo "hybrid mode"
	[[ -n "${__FILE_BIOS:-}" ]] && echo "eltorito mode"
#	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! xorrisofs "${__OPTN[@]}"; then
			__RTCD="$?"
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorrisofs]" "${__FILE_ISOS##*/}" 1>&2
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorrisofs]" "xorrisofs ${__OPTN[*]}" 1>&2
			printf "%s\n" "xorrisofs: ${__RTCD:-}"
			exit "${__RTCD:-}"
		else
			if ! cp --preserve=timestamps "${__TEMP}" "${__FILE_ISOS}"; then
				__RTCD="$?"
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${__FILE_ISOS##*/}" 1>&2
				printf "%s\n" "cp: ${__RTCD:-}"
				exit "${__RTCD:-}"
			else
				__REAL="$(realpath "${__FILE_ISOS}")"
				__DIRS="$(fnDirname "${__FILE_ISOS}")"
				__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
				chown "${__OWNR:-"${_SAMB_USER}"}" "${__FILE_ISOS}"
				chmod ugo+r-x,ug+w "${__FILE_ISOS}"
				ls -lh "${__FILE_ISOS}"
				printf "\033[m\033[42m%20.20s: %s\033[m\n" "complete" "${__FILE_ISOS}" 1>&2
			fi
		fi
		rm -f "${__TEMP:?}"
#	popd > /dev/null || exit
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __REAL __DIRS __OWNR __time_start __time_end __time_elapsed

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
