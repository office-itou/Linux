# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: grub module install
#   input :     $1     : device name
#   input :     $2     : mount point
#   input :     $3     : distribution
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnGrub_module() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_MNTP="${2:?}"	# mount point
	declare -r    __TGET_DIST="${3:?}"	# distribution
	declare       __COMD=""

	# --- install grub module -------------------------------------------------
	  if command -v grub-install  > /dev/null 2>&1; then __COMD="grub-install"
	elif command -v grub2-install > /dev/null 2>&1; then __COMD="grub2-install"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	"${__COMD}" \
		--target=x86_64-efi \
		--efi-directory="${__TGET_MNTP}" \
		--boot-directory="${__TGET_MNTP}/boot" \
		--bootloader-id="${__TGET_DIST}" \
		--removable
	"${__COMD}" \
		--target=i386-pc \
		--boot-directory="${__TGET_MNTP}/boot" \
		"${__TGET_DEVS}"
	unset __COMD
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
