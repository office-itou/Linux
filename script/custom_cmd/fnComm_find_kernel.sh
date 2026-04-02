# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: find kernel
#   input :     $1     : target directory
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_TGET : read
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
function fnFind_kernel() {
	declare -r    __TGET_DIRS="${1:?}"	# target directory
	declare       __VLNZ=""				# kernel
	declare       __IRAM=""				# initramfs
	           __VLNZ="$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'vmlinuz-*'    -o -name 'linux-*'         \) -print -quit)"
	__VLNZ="${__VLNZ:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'vmlinuz'      -o -name 'linux'           \) -print -quit)"}"
	           __IRAM="$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*.img' -o -name 'initramfs-*.img' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd.img-*' -o -name 'initramfs.img-*' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd.img'   -o -name 'initramfs.img'   \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__TGET_DIRS}"/{boot,} -maxdepth 1 \( -name 'initrd'       -o -name 'initramfs'       \) -print -quit)"}"
	__VLNZ="${__VLNZ#"${__TGET_DIRS}"/}"
	__IRAM="${__IRAM#"${__TGET_DIRS}"/}"
	printf "%s %s" "${__VLNZ:-"-"}" "${__IRAM:-"-"}"
}
