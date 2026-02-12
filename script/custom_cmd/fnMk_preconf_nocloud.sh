# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make nocloud
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
#   g-var : _PATH_CLUD : read
# shellcheck disable=SC2317,SC2329
function fnMk_preconf_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __WORK=""				# work
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_CLUD}" "${__TGET_PATH}"
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_server_oldold/*) ;;	# 20.04 - 23.10
		*_server_old/*)    ;;	# 24.04 - 25.10
		*_server/*)        ;;	# 26.04 -
		*_desktop_old/*)		# 24.04 - 25.10
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*_desktop/*)			# 26.04 -
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/!        s/^#/ /g                          ' \
			    -e '/^[ \t]*-[ \t]*.*mozc/ s/^ /#/                          }' 
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${__TGET_PATH%/*}/meta-data"      --reference "${__TGET_PATH}"
	touch -m "${__TGET_PATH%/*}/network-config" --reference "${__TGET_PATH}"
#	touch -m "${__TGET_PATH%/*}/user-data"      --reference "${__TGET_PATH}"
	touch -m "${__TGET_PATH%/*}/vendor-data"    --reference "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH%/*}"/*
	unset __REAL __DIRS __OWNR
#	unset __TGET_PATH
}
