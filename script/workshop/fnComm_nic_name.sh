# shellcheck disable=SC2148

function fnMk_nic_name() {
	declare -r    __TGET_DIST="${1:?}"		# distribution
	declare       __NICS=""				# network interface card name

	# --- ethrname ------------------------------------------------------------
	case "${__TGET_DIST:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) __NICS="${_NICS_NAME:-"ens160"}";;
	esac
	echo "${__NICS:?}"
}
