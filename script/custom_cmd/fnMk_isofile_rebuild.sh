# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
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
	declare -r    __FILE_VLID="${3:-}"	# volume id
	declare -r    __FILE_HBRD="${4:-}"	# iso hybrid mbr file name
	declare -r    __FILE_BIOS="${5:-}"	# grub mbr file name
	declare -r    __FILE_UEFI="${6:-}"	# uefi file name
	declare -r    __FILE_BCAT="${7:-}"	# eltorito catalog file name
	declare -r    __FILE_ETRI="${8:-}"	# eltorito boot file name
	if [[ -n "${__FILE_HBRD:-}" ]]; then
		declare -r -a __OPTN=(\
			-quiet -rational-rock \
			${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"} \
			-joliet -joliet-long \
			-cache-inodes \
			-isohybrid-mbr "${__FILE_HBRD}" \
			${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}"} \
			${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"} \
			-no-emul-boot -boot-load-size 4 -boot-info-table \
			-eltorito-alt-boot -e "${__FILE_UEFI}" -no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
		)
	else
		declare -r -a __OPTN=(\
			-quiet -rational-rock \
			${__FILE_VLID:+-volid "${__FILE_VLID// /$'\x20'}"} \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			--grub2-mbr "${__FILE_BIOS}" \
			--mbr-force-bootable \
			-append_partition 2 0xEF "${__FILE_UEFI}" \
			-appended_part_as_gpt \
			${__FILE_BCAT:+-eltorito-catalog "${__FILE_BCAT}"} \
			${__FILE_ETRI:+-eltorito-boot "${__FILE_ETRI}"} \
			-no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' -no-emul-boot
		)
	fi
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	echo "create iso image file ..."
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
	[[ -n "${__FILE_HBRD:-}" ]] && echo "hybrid mode"
	[[ -n "${__FILE_BIOS:-}" ]] && echo "eltorito mode"
	pushd "${__DIRS_TGET:?}" > /dev/null || exit
		if ! nice -n 19 xorrisofs "${__OPTN[@]}" -output "${__TEMP}" .; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${__FILE_ISOS##*/}" 1>&2
			printf "%s\n" "xorrisofs ${__OPTN[*]} -output ${__TEMP} ."
		else
			if ! cp --preserve=timestamps "${__TEMP}" "${__FILE_ISOS}"; then
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${__FILE_ISOS##*/}" 1>&2
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
	popd > /dev/null || exit
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
