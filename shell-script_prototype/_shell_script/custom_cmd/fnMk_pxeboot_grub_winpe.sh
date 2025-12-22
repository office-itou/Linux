# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make WinPE section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_CONF : read
function fnMk_pxeboot_grub_winpe() {
	declare       __ENTR=""
	__ENTR="$(printf "%-55.55s%19.19s" "- ${4//%20/ }  ${_TEXT_SPCE// /.}" "${15//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${5//%20/ } ...'
		    set isofile="(${_SRVR_PROT:?},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}${15#"${_DIRS_ISOS}"}"
		    export isofile
		    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		    insmod net
		    insmod http
		    insmod progress
		    echo 'Loading linux ...'
		    linux  memdisk iso raw
		    echo 'Loading initrd ...'
		    initrd \$isofile
		  }
		fi
_EOT_
	unset __ENTR
}
