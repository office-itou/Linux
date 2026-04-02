# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: mount raw file
#   input :     $1     : device name
#   input :     $2     : raw file
#   input :     $3     : mount point
#   input :     $4     : partition (p1...)
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMount_raw() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PATH="${2:?}"	# raw file
	declare -r    __TGET_MNTP="${3:?}"	# mount point
	declare -r    __TGET_PART="${4:?}"	# partition

	mkdir -p "${__TGET_MNTP}"
	__TGET_DEVS="$(losetup --find --show "${__TGET_PATH}")"
	partprobe "${__TGET_DEVS}"
	mount -r "${__TGET_DEVS}${__TGET_PART}" "${__TGET_MNTP}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# -----------------------------------------------------------------------------
# descript: umount raw file
#   input :     $1     : device name
#   input :     $2     : mount point
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnUmount_raw() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_MNTP="${2:?}"	# mount point

	umount "${__TGET_MNTP}"
	losetup --detach "${__TGET_DEVS}"
	__TGET_DEVS=""
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
