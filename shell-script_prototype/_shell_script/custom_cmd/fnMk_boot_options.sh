# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make boot options
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_CONF : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_LOAD : read
#   g-var : _DIRS_ISOS : read
#   g-var : _DIRS_RMAK : read
# shellcheck disable=SC2317,SC2329
function fnMk_boot_options() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __MDIA=("${@:-}")
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		debian-*|live-debian-*| \
		ubuntu-*|live-ubuntu-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/preseed/*) fnMk_boot_option_preseed "${__TGET_TYPE}" "${@}";;
				*/nocloud/*) fnMk_boot_option_nocloud "${__TGET_TYPE}" "${@}";;
				*          ) ;;
			esac
			;;
		fedora-*      |live-fedora-*      | \
		centos-*      |live-centos-*      | \
		almalinux-*   |live-almalinux-*   | \
		rockylinux-*  |live-rockylinux-*  | \
		miraclelinux-*|live-miraclelinux-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/kickstart/*) fnMk_boot_option_kickstart "${__TGET_TYPE}" "${@}";;
				*            ) ;;
			esac
			;;
		opensuse-*|live-opensuse-*)
			case "${__MDIA[$((_OSET_MDIA+24))]:-}" in
				*/autoyast/*) fnMk_boot_option_autoyast "${__TGET_TYPE}" "${@}";;
				*/agama/*   ) fnMk_boot_option_agama    "${__TGET_TYPE}" "${@}";;
				*           ) ;;
			esac
			;;
		* ) ;;
	esac
}
