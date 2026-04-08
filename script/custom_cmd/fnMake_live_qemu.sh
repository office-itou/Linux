# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image on qemu
#   input :     $1     : output directory
#   input :     $2     : volume id
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:-}"	# output directory
	declare -r    __TGET_VLID="${2:-}"	# volume id
	declare       __STRG=""				# storage
	# --- command -------------------------------------------------------------
	__STRG="${__TGET_OUTD:?}/vm_uefi_${__TGET_VLID,,}.raw"
	__OPTN=(
		-cpu "host"
		-machine "q35"
		-enable-kvm
		-device "intel-iommu"
		-m "size=4G"
		-boot "order=c"
		-nic "bridge"
		-vga "std"
		-full-screen
		-display "curses,charset=CP932"
		-k "ja"
		-device "ich9-intel-hda"
		-vnc ":0"
		-nographic
		-drive "file=${__STRG},format=raw"
	)
	fnMk_qemu "${__OPTN[@]}"

	unset __OPTN __HOST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
