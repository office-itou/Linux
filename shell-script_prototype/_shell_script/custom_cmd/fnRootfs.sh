# -----------------------------------------------------------------------------
# descript: rootfs
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
# shellcheck disable=SC2148
function fnRootfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare -r -a __OPTN=(\
		--force \
		--wipe-build-dir \
		--architecture=x86-64 \
		--root-password=r00t \
		--bootable=yes \
		--bootloader=systemd-boot \
		--selinux-relabel=yes \
		--with-network=yes \
		${__TGET_INCL:+--include="${__TGET_INCL}"} \
		${__TGET_MDIA:+--format="${__TGET_MDIA}"} \
		${__DIRS_WDIR:+--output-directory="${__DIRS_WDIR}"} \
		${__DIRS_CACH:+--cache-directory="${__DIRS_CACH}"} \
		${__DIRS_CACH:+--package-cache-dir="${__DIRS_CACH}"} \
		${__TGET_DIST:+--distribution="${__TGET_DIST%%-*}"} \
		${__TGET_VERS:+--release="${__TGET_VERS}"} \
		${__COMD_MKOS:+"${__COMD_MKOS}"} \
	)

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDebugout_parameters
}
