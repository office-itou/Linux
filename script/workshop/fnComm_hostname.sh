# shellcheck disable=SC2148

function fnMk_hostname() {
	declare -r    __TGET_DIST="${1:?}"		# distribution
	declare       __HOST=""				# host name

	# --- hostname ------------------------------------------------------------
	__HOST="${__TGET_DIST:+"${_NWRK_HOST/:_DISTRO_:/"${__TGET_DIST}${_NWRK_WGRP:+".${_NWRK_WGRP}"}"}"}"
	__HOST="${__HOST:-"localhost.localdomain"}"
	echo "${__HOST:?}"
}
