# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make aomei backup section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_CONF : read
function fnMk_pxeboot_slnx_aomei() {
	declare       __ENTR=""
	__ENTR="$(printf "%-55.55s%19.19s" "- ${4//%20/ }  ${_TEXT_SPCE// /.}" "${16//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${4}
		  menu label ^${__ENTR:-}
		  linux  memdisk
		  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}${15#"${_DIRS_ISOS}"}
		  append iso raw
_EOT_
	unset __ENTR
}
