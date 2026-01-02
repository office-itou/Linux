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
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) ;;
	esac
	case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	__BOPT=("${__BOPT[@]//\$\{srvraddr\}/${_SRVR_PROT:?}:\/\/${_SRVR_ADDR:?}}")
	__BOPT=("${__BOPT[@]//\$\{hostname\}/${__HOST:-}}")
	__BOPT=("${__BOPT[@]//\$\{ethrname\}/${__NICS:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4addr\}/${_IPV4_ADDR:-}${__CIDR:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4mask\}/${_IPV4_MASK:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4gway\}/${_IPV4_GWAY:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4nsvr\}/${_IPV4_NSVR:-}}")
	__BOPT=("${__BOPT[@]:1}")
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		  initrd ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		  append ${__BOPT[@]} --- quiet
_EOT_
	unset __ENTR __BOPT __ENTR __CIDR __WORK
}
