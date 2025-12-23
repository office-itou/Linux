# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make grub.cfg for pxeboot
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_grub() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __SPCS=""				# tabs string (space)
	declare       __ENTR=""
	declare       __WORK=""
	# --- tab string ----------------------------------------------------------
	__SPCS="$(printf "%$(("${__CONT_TABS}" * 2))s" "")"
	# --- menu list -----------------------------------------------------------
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_grub_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[2]}" in
		m)								# (menu)
			case "${__LIST_MDIA[4]}" in
				System%20command) ;;
				%20             ) __WORK="${__SPCS}}\n";;
				*               ) __WORK="${__SPCS}submenu '[ ${__LIST_MDIA[4]//%20/ } ... ]' {";;
			esac
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[3]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[15]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[3]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_grub_windows "${__LIST_MDIA[@]}")";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_grub_winpe   "${__LIST_MDIA[@]}")";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_grub_aomei   "${__LIST_MDIA[@]}")";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_grub_m86p    "${__LIST_MDIA[@]}")";;
				*                      ) __WORK="$(fnMk_pxeboot_grub_linux   "${__LIST_MDIA[@]}")";;
			esac
			__WORK="$(printf "%s" "${__WORK}" | sed -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;')"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}
