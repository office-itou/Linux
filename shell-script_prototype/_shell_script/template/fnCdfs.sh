# -----------------------------------------------------------------------------
# descript: cdfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
# shellcheck disable=SC2148
function fnCdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare -r    __CDFS=""				#
	declare -r    __ISOS=""				# 
	declare       __TEMP=""				# 
	              __TEMP="$(mktemp -q -p "${_DIRS_TEMP}" "${__ISOS##*/}.XXXXXX")"
	readonly      __TEMP
#	declare -r    __VLID="${__TGET_NAME^}-Live-Media"
	declare -r -a __HBRD=(\
		-quiet -rational-rock \
		${__VLID:+-volid "${__VLID}"} \
		-joliet -joliet-long \
		-cache-inodes \
		${__FHBR:+-isohybrid-mbr "${__FHBR}"} \
		${__FBIN:+-eltorito-boot "${__FBIN}"} \
		${__FCAT:+-eltorito-catalog "${__FCAT}"} \
		-boot-load-size 4 -boot-info-table \
		-no-emul-boot \
		-eltorito-alt-boot ${__FEFI:+-e "${__FEFI}"} \
		-no-emul-boot \
		-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
	)
	declare -r -a __GRUB=(\
		-quiet -rational-rock \
		${__VLID:+-volid "${__VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		${__FMBR:+--grub2-mbr "${__FMBR}"} \
		--mbr-force-bootable \
		${__FEFI:+-append_partition 2 0xEF "${__FEFI}"} \
		-appended_part_as_gpt \
		${__FCAT:+-eltorito-catalog "${__FCAT}"} \
		${__FBIN:+-eltorito-boot "${__FBIN}"} \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot
	)

	declare -r -a __OPTN=(\
		-rational-rock \
		${__VLID:+-volid "${__VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		--grub2-mbr ../bios.img \
		--mbr-force-bootable \
		-append_partition 2 0xEF boot/grub/efi.img \
		-appended_part_as_gpt \
		-eltorito-catalog isolinux/boot.catalog \
		-eltorito-boot isolinux/isolinux.bin \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot \
		-output "${__TEMP:?}" \
		"${__CDFS:-.}"


	)
	# --- create --------------------------------------------------------------
	fnExec_xorrisofs "${__OPTN[@]:-}"
	fnExec_copy "${__TEMP:?}" "${__ISOS:?}"
	fnMsgout "success" "${__ISOS##*/}"
	ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${__ISOS}" || true
	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}
