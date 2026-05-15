# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make nbd exports.conf
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_nbds() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")

	case "${__LIST_MDIA[$((_OSET_MDIA+1))]:?}" in
		m) return;;				# (menu)
		o) ;;					# (output)
		*) return;;				# (hidden)
	esac

	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__TGET_PATH:?}" || true
		[${__LIST_MDIA[$((_OSET_MDIA+2))]:?}]
		exportname = ${__LIST_MDIA[$((_OSET_MDIA+14))]:?}
		copyonwrite = false

_EOT_
}
