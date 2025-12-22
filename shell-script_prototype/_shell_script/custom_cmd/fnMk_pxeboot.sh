# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make pxeboot files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnMk_pxeboot() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __PTRN=""				# pattern
	declare       __TYPE=""				# target type
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# data array
	declare -i    __TABS=0				# tab count
	declare -i    I=0
	declare -i    J=0

	# --- get target ----------------------------------------------------------
	__PTRN=()
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "${1%%:*}" in
			a|all    ) __PTRN=("mini" "netinst" "dvd" "liveinst" "live" "tool" "clive" "cnetinst" "system"); shift; break;;
			mini     ) ;;
			netinst  ) ;;
			dvd      ) ;;
			liveinst ) ;;
			live     ) ;;
			tool     ) ;;
			clive    ) ;;
			cnetinst ) ;;
			system   ) ;;
			*) break;;
		esac
		__PTRN+=("${1:-}")
		shift
	done
	__NAME_REFR="${*:-}"
	# --- create pxeboot menu file --------------------------------------------
	fnMk_pxeboot_clear_menu "${_PATH_IPXE:?}"				# ipxe
	fnMk_pxeboot_clear_menu "${_PATH_GRUB:?}"				# grub
	fnMk_pxeboot_clear_menu "${_PATH_SLNX:?}"				# syslinux (bios)
	fnMk_pxeboot_clear_menu "${_PATH_UEFI:?}"				# syslinux (efi64)
	for __TYPE in "${__PTRN[@]}"
	do
		fnMk_print_list __LINE "${__TYPE}"
		IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			case "${__MDIA[2]}" in
				m)						# (menu)
					[[ "${__MDIA[4]}" = "%20" ]] && __TABS=$((__TABS-1))
					[[ "${__TABS}" -lt 0 ]] && __TABS=0
					;;
				o)						# (output)
					case "${__MDIA[27]}" in
						c) ;;
						d)
							__RETN="- - - -"
							if [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]]; then
								fnDownload "${__MDIA[10]}" "${__MDIA[14]}"
								__RETN="$(fnGetFileinfo "${__MDIA[14]}")"
							fi
							read -r -a __ARRY < <(echo "${__RETN}")
							__MDIA[15]="${__ARRY[1]:-}"	# iso_tstamp
							__MDIA[16]="${__ARRY[2]:-}"	# iso_size
							__MDIA[17]="${__ARRY[3]:-}"	# iso_volume
							;;
						*) ;;
					esac
					# --- rsync -----------------------------------------------
					fnRsync "${__MDIA[14]}" "${_DIRS_IMGS}/${__MDIA[3]}"
					;;
				*) ;;					# (hidden)
			esac
			# --- create menu file --------------------------------------------
			fnMk_pxeboot_ipxe "${_PATH_IPXE:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# ipxe
			fnMk_pxeboot_grub "${_PATH_GRUB:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# grub
#			fnMk_pxeboot_slnx "${_PATH_SLNX:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (bios)
#			fnMk_pxeboot_slnx "${_PATH_UEFI:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (efi64)
			# --- tab ---------------------------------------------------------
			case "${__MDIA[2]}" in
				m)						# (menu)
					[[ "${__MDIA[4]}" != "%20" ]] && __TABS=$((__TABS+1))
					[[ "${__TABS}" -lt 0 ]] && __TABS=0
					;;
				o) ;;					# (output)
				*) ;;					# (hidden)
			esac
			# --- data registration -------------------------------------------
			__MDIA=("${__MDIA[@]// /%20}")
			J="${__MDIA[0]}"
			_LIST_MDIA[J]="$(
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__MDIA[@]:1}"
			)"
		done
	done
	unset __OPTN __PTRN __TYPE __LINE __TGET __MDIA __RETN __ARRY __TABS I J

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
