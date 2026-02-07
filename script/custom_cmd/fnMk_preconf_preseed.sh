# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make preseed.cfg
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
#   g-var : _PATH_SEDD : read
# shellcheck disable=SC2317,SC2329
function fnMk_preconf_preseed() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_SEDD}" "${__TGET_PATH}"
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                             \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g'                                                   \
			    -e 's/connman/network-manager/                              } '
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}"
	unset __REAL __DIRS __OWNR
#	unset __TGET_PATH
}
