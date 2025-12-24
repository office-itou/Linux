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
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		iseq \${platform} efi && set knlfile \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || set knlfile \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit
_EOT_
}
