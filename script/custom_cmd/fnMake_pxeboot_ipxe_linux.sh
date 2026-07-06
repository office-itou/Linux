# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make linux section for ipxe menu
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
function fnMk_pxeboot_ipxe_linux() {
	declare -a    __MDIA=("${@:-}")
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
#		mini    ) ;;
#		netinst ) ;;
#		dvd     ) ;;
#		liveinst) ;;
		live    ) fnMk_pxeboot_ipxe_linux_live "${__MDIA[@]}";;		# original media live mode
#		tool    ) ;;												# tools
		clive   ) fnMk_pxeboot_ipxe_linux_clive "${__MDIA[@]}";;	# custom media live mode
		cnetinst) fnMk_pxeboot_ipxe_linux_cnetinst "${__MDIA[@]}";;	# custom media install mode
#		system  ) ;;												# system command
		*       ) fnMk_pxeboot_ipxe_linux_default "${__MDIA[@]}";;	# original media install mode
	esac
	unset __MDIA
}
