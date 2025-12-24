# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make Windows section for grub.cfg
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_CONF : read
function fnMk_pxeboot_grub_windows() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-55.55s%19.19s" "- ${__MDIA[$((_OSET_MDIA+2))]//%20/ }  ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+14))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		if [ "\${grub_platform}" = "pc" ]; then
		  menuentry '${__ENTR:-}' {
		    echo 'Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...'
		    set isofile="(${_SRVR_PROT:?},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}"
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
