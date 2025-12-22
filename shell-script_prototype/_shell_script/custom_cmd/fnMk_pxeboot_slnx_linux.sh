# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make linux section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _NWRK_HOST : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NICS_NAME : read
#   g-var : _IPV4_ADDR : read
#   g-var : _IPV4_MASK : read
#   g-var : _IPV4_GWAY : read
#   g-var : _IPV4_NSVR : read
#   g-var : _SRVR_PROT : read
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_slnx_linux() {
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	case "${4:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	__BOPT=("${__BOPT[@]//\$\{hostname\}/${_NWRK_HOST/:_DISTRO_:/${4%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}}")
	__BOPT=("${__BOPT[@]//\$\{ethrname\}/${_NICS_NAME:-ens160}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4addr\}/${_IPV4_ADDR:-}${__CIDR:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4mask\}/${_IPV4_MASK:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4gway\}/${_IPV4_GWAY:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4nsvr\}/${_IPV4_NSVR:-}}")
	__BOPT=("${__BOPT[@]//\$\{srvraddr\}/${_SRVR_PROT:?}:\/\/${_SRVR_ADDR:?}}")
	__ENTR="$(printf "%-55.55s%19.19s" "- ${4//%20/ }  ${_TEXT_SPCE// /.}" "${16//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${4}
		  menu label ^${__ENTR:-}
		  linux  ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${4}/${24#*/"${4}"/}
		  initrd ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${4}/${23#*/"${4}"/}
		  append ${__BOPT[@]} --- quiet
_EOT_
	unset __ENTR __BOPT __ENTR __CIDR __WORK
}
