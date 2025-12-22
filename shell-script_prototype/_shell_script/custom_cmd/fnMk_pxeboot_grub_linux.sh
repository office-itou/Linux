# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make linux section for grub.cfg
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
function fnMk_pxeboot_grub_linux() {
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
	__ENTR="$(printf "%-55.55s%19.19s" "- ${4//%20/ }  ${_TEXT_SPCE// /.}" "${15//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		menuentry '${__ENTR:-}' {
		  echo 'Loading ${5//%20/ } ...'
		  set hostname=${_NWRK_HOST/:_DISTRO_:/${4%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
		  set ethrname=${_NICS_NAME:-ens160}
		  set ipv4addr=${_IPV4_ADDR:-}${__CIDR:-}
		  set ipv4mask=${_IPV4_MASK:-}
		  set ipv4gway=${_IPV4_GWAY:-}
		  set ipv4nsvr=${_IPV4_NSVR:-}
		  set autoinst=${__BOPT[0]:-} ${__BOPT[1]:-}
		  set language=${__BOPT[2]:-}
		  set networks=${__BOPT[3]:-}
		  set otheropt=${__BOPT[@]:4}
		  set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		  set knladdr=\${srvraddr}/${_DIRS_IMGS##*/}/${4}
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  insmod net
		  insmod http
		  insmod progress
		  echo Loading boot files ...
		  linux  \${knladdr}/${24#*/"${4}"/}
		  initrd \${knladdr}/${23#*/"${4}"/}
		}
_EOT_
	unset __ENTR __BOPT __ENTR __CIDR __WORK
}
