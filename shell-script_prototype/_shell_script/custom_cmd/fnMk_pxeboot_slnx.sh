# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make syslinux for pxeboot
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_slnx() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __SPCS=""				# tabs string (space)
	declare       __ENTR=""
	declare       __WORK=""
	# --- tab string ----------------------------------------------------------
	__SPCS="$(printf "%$(("${__CONT_TABS}" * 2))s" "")"
	# --- menu list -----------------------------------------------------------
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_slnx_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[$((_OSET_MDIA+1))]}" in
		m) ;;							# (menu)
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[$((_OSET_MDIA+2))]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[$((_OSET_MDIA+14))]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[$((_OSET_MDIA+2))]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_slnx_windows "${__LIST_MDIA[@]}")";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_slnx_winpe   "${__LIST_MDIA[@]}")";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_slnx_aomei   "${__LIST_MDIA[@]}")";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_slnx_m86p    "${__LIST_MDIA[@]}")";;
				*                      ) __WORK="$(fnMk_pxeboot_slnx_linux   "${__LIST_MDIA[@]}")";;
			esac
			__WORK="$(printf "%s" "${__WORK}" | sed -e ':l; N; s/\n/\\n/; b l;')"
			sed -i "${__TGET_PATH}" -e "/^label System-command$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}
