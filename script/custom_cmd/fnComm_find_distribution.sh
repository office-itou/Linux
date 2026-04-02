# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: find distribution
#   input :     $1     : distribution
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
function fnFind_distribution() {
	declare -r    __TGET_DIST="${1:?}"	# distribution
	declare       __DIST=""				# distribution

	case "${__TGET_DIST,,}" in
		debian  ) __DIST="Debian";;
		ubuntu  ) __DIST="Ubuntu";;
		fedora  ) __DIST="Fedora";;
		centos  ) __DIST="CentOS-Stream";;
		alma    ) __DIST="AlmaLinux";;
		rocky   ) __DIST="Rocky";;
		opensuse) __DIST="openSUSE";;
#		miracle ) __DIST="MIRACLE-LINUX";;
		*       ) __DIST="${__TGET_DIST,,}";;
	esac
	echo "${__DIST}"
}
