# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: grub install
#   input :     $1     : device name
#   input :     $2     : mount point
#   input :     $3     : partition (p1...)
#   input :     $4     : distribution
#   input :     $5     : uuid
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnGrub_install() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_MNTP="${2:?}"	# mount point
	declare -r    __TGET_PART="${3:?}"	# partition
	declare -r    __TGET_DIST="${4:?}"	# distribution
	declare -r    __TGET_UUID="${5:?}"	# uuid

	mkdir -p "${__TGET_MNTP:?}"
	mount "${__TGET_DEVS}"p1 "${__TGET_MNTP}"
	fnGrub_module "${__TGET_DEVS}" "${__TGET_MNTP}" "${__TGET_DIST}"
	fnGrub_conf 
	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_MAIN="${2:?}"	# main menu
	declare -r    __MENU_THME="${3:-}"	# theme file
	declare -r    __MENU_TOUT="${4:-}"	# timeout (sec)
	declare -r    __MENU_RESO="${5:-}"	# resolution (widht x hight)
	declare -r    __MENU_DPTH="${6:-}"	# colors
	fnGrub_theme
	declare -r    __TGET_PATH="${1:?}"	# target path
	declare -r    __MENU_TITL="${2:?}"	# menu title

	cp --preserve=timestamps "${__OUTD}"/grub.cfg "${__TGET_MNTP}"/boot/grub/
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
