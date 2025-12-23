# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make make ipxe menu
#   input :     $1     : file name
#   input :     $2     : tab count
#   input :   $3..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_ipxe() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare       __ENTR=""
	declare       __WORK=""
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_ipxe_hdrftr > "${__TGET_PATH}"
	case "${__LIST_MDIA[2]}" in
		m)								# (menu)
			[[ "${__LIST_MDIA[4]:-}" = "%20" ]] && return
			__WORK="$(printf "%-48.48s[ %s ]" "item --gap --" "${__LIST_MDIA[4]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__LIST_MDIA[3]}"/. ]] \
			|| [[ ! -s "${__LIST_MDIA[15]}" ]]; then
				return
			fi
			case "${__LIST_MDIA[1]}" in
#				mini    ) ;;
#				netinst ) ;;
#				dvd     ) ;;
#				liveinst) ;;
				live    ) __ENTR="live-";;		# original media live mode
#				tool    ) ;;					# tools
#				clive   ) ;;					# custom media live mode
#				cnetinst) ;;					# custom media install mode
#				system  ) ;;					# system command
				*       ) __ENTR="";;			# original media install mode
			esac
			__WORK="$(printf "%-48.48s%-55.55s%19.19s" "item -- ${__ENTR:-}${__LIST_MDIA[3]}" "- ${__LIST_MDIA[4]//%20/ } ${_TEXT_SPCE// /.}" "${__LIST_MDIA[16]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			case "${__LIST_MDIA[3]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_ipxe_windows "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_ipxe_winpe   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_ipxe_aomei   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_ipxe_m86p    "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				*                      ) __WORK="$(fnMk_pxeboot_ipxe_linux   "${__LIST_MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
			esac
			sed -i "${__TGET_PATH}" -e "/^:shell$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
	unset __ENTR __WORK
}
