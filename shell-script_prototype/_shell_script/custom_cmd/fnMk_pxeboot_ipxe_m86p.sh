# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_ipxe_m86p() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${4}
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		iseq \${platform} efi && set knlfile \${knladdr}/${23#*/"${4}"/} || set knlfile \${knladdr}/${24#*/"${4}"/}
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit
_EOT_
}
