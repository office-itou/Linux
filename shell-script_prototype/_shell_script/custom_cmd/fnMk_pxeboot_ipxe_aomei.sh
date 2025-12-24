# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make aomei backup section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_CONF : read
function fnMk_pxeboot_ipxe_aomei() {
	declare -a    __MDIA=("${@:-}")
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:${__MDIA[$((_OSET_MDIA+2))]}
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}
