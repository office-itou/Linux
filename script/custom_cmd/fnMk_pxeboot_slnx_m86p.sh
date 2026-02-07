# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make memtest86+ section for syslinux
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_ADDR : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_slnx_m86p() {
	declare -a    __MDIA=("${@:-}")
	declare       __ENTR=""
	__ENTR="$(printf "%-54.54s %19.19s" "- ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[$((_OSET_MDIA+15))]//%20/ }")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label ${__MDIA[$((_OSET_MDIA+2))]}
		  menu label ^${__ENTR:-}
		  linux  ${_SRVR_PROT:?}://${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}
_EOT_
	unset __ENTR
}
