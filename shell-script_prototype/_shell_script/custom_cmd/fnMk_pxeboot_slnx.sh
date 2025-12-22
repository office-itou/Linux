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
	declare -a    __MDIA=()
	declare       __ENTR=""
	declare       __WORK=""
	__MDIA=("${__LIST_MDIA[@]//%20/ }")
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_slnx_hdrftr > "${__TGET_PATH}"
	case "${__MDIA[2]}" in
		m)								# (menu)
			if [[ -z "$(fnTrim "${__MDIA[4]:-}" " ")" ]]; then
				return
			fi
			__WORK="$(printf "%-48.48s[ %s ]" "item --gap --" "${__MDIA[4]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__MDIA[3]}"/. ]] \
			|| [[ ! -s "${__MDIA[14]}" ]]; then
				return
			fi
			case "${__MDIA[1]}" in
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
			__WORK="$(printf "%-48.48s%-55.55s%19.19s" "item -- ${__ENTR:-}${__LIST_MDIA[3]}" "- ${__MDIA[4]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[15]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			case "${__MDIA[3]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_slnx_windows "${__MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_slnx_winpe   "${__MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_slnx_aomei   "${__MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_slnx_m86p    "${__MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
				*                      ) __WORK="$(fnMk_pxeboot_slnx_linux   "${__MDIA[@]}" | sed -e ':l; N; s/\n/\\n/; b l;')";;
			esac
			sed -i "${__TGET_PATH}" -e "/^:shell$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
	unset __TGET_PATH __CONT_TABS __LIST_MDIA __MDIA __ENTR __WORK
}
