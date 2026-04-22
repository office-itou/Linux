# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image on qemu
#   input :     $1     : storage
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_STRG="${1:-}"	# storage
	# --- command -------------------------------------------------------------
	# /usr/share/novnc/utils/novnc_proxy --listen [::]:6080
	# http://sv-developer:6080/vnc.html
	__OPTN=(
		-cpu "host"
		-machine "q35"
		-enable-kvm
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
		-drive "id=disk,file=${__TGET_STRG:?},format=raw,if=none"
		-device "ich9-ahci,id=ahci"
		-device "ide-hd,drive=disk,bus=ahci.0"
	)
	fnMk_qemu "${__OPTN[@]}"

	unset __OPTN

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
