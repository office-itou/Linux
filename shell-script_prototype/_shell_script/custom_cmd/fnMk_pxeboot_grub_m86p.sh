# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_grub_m86p() {
	declare       __ENTR=""
	__ENTR="$(printf "%-55.55s%19.19s" "- ${4//%20/ }  ${_TEXT_SPCE// /.}" "${16//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${5//%20/ } ...'
		    set srvraddr=${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		    set knladdr=\${srvraddr}/${_DIRS_IMGS##*/}/${4}
		    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		    insmod net
		    insmod http
		    insmod progress
		    echo Loading boot files ...
		    if [ "\${grub_platform}" = "pc" ]; then
		      linux \${knladdr}/${24#*/"${4}"/}
		    else
		      linux \${knladdr}/${25#*/"${4}"/}
		    fi
		  }
		fi
_EOT_
	unset __ENTR
}
