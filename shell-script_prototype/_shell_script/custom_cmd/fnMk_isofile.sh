# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make iso files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnMk_isofile() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare -A    __PTRN=()				# pattern
	declare       __TYPE=""				# target type
	declare       __TGID=""				# target id
	declare       __LINE=""				# data line
	declare -a    __TGET=()				# target data line
	declare -a    __MDIA=()				# media info data
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# data array
	declare -i    __TABS=0				# tab count
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -qd "${_DIRS_TEMP:-/tmp}/${__FUNC_NAME}.XXXXXX")"
	readonly      __TEMP
	declare -r    __DOVL="${__TEMP}/overlay"				# overlay
	declare -r    __DUPR="${__DOVL}/upper"					# upperdir
	declare -r    __DLOW="${__DOVL}/lower"					# lowerdir
	declare -r    __DWKD="${__DOVL}/work"					# workdir
	declare -r    __DMRG="${__DOVL}/merged"					# merged
	declare       __WORK=""
	declare       __FKNL=""
	declare       __FIRD=""
	declare       __HOST=""
	declare       __CIDR=""
	declare -r    __BOPT=()
	declare -i    I=0
	declare -i    J=0

	# --- get target ----------------------------------------------------------
	__PTRN=()
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__TYPE="${1%%:*}"
		__TGID="${1#"${__TYPE:+"${__TYPE}":}"}"
		__TYPE="${__TYPE,,}"
		__TGID="${__TGID,,}"
		case "${__TYPE:-}" in
			a|all    ) __PTRN=(["mini"]=".*" ["netinst"]=".*" ["dvd"]=".*" ["liveinst"]=".*"); shift; break;;
			mini     ) ;;
			netinst  ) ;;
			dvd      ) ;;
			liveinst ) ;;
			live     ) shift; continue;;
			tool     ) shift; continue;;
			clive    ) shift; continue;;
			cnetinst ) shift; continue;;
			system   ) shift; continue;;
			*) break;;
		esac
		case "${__TGID:-}" in
			a|all           ) __PTRN["${__TYPE}"]=".*";;
			[0-9]|[0-9][0-9]) __PTRN["${__TYPE}"]="${__PTRN["${__TYPE}"]:+"${__PTRN["${__TYPE}"]} "}${__TGID}";;
			*               ) ;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	# --- create custom iso file ----------------------------------------------
	for __TYPE in "${_LIST_TYPE[@]}"
	do
		[[ -z "${__PTRN["${__TYPE:-}"]:-}" ]] && continue
		__TGID="${__PTRN["${__TYPE:-}"]// /|}"
		fnMk_print_list __LINE "${__TYPE:-}" "${__TGID:-}"
		IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			case "${__MDIA[$((_OSET_MDIA+1))]}" in
				m) continue;;			# (menu)
				o)						# (output)
					case "${__MDIA[$((_OSET_MDIA+2))]}" in
						windows-*              ) continue;;
						winpe-*|ati*x64|ati*x86) continue;;
						aomei-backupper        ) continue;;
						memtest86*             ) continue;;
						*                      )
							case "${__MDIA[$((_OSET_MDIA+27))]}" in
								c) ;;
								d)
									__RETN="- - - -"
									__WORK="$(fnTrim "${__MDIA[$((_OSET_MDIA+14))]}" "-")"
									if [[ -n "${__WORK:-}" ]]; then
										fnDownload "${__MDIA[$((_OSET_MDIA+9))]}" "${__MDIA[$((_OSET_MDIA+14))]}" "${__MDIA[$((_OSET_MDIA+11))]}"
										__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+14))]}")"
									fi
									read -r -a __ARRY < <(echo "${__RETN}")
									__MDIA[_OSET_MDIA+15]="${__ARRY[1]:-}"	# iso_tstamp
									__MDIA[_OSET_MDIA+16]="${__ARRY[2]:-}"	# iso_size
									__MDIA[_OSET_MDIA+17]="${__ARRY[3]:-}"	# iso_volume
									;;
								*) ;;
							esac
							# --- rsync ---------------------------------------
							fnRsync "${__MDIA[$((_OSET_MDIA+14))]}" "${_DIRS_IMGS}/${__MDIA[$((_OSET_MDIA+2))]}"
							# --- mount ---------------------------------------
							rm -rf "${__DOVL:?}"
							mkdir -p "${__DUPR}" "${__DLOW}" "${__DWKD}" "${__DMRG}"
							mount -r "${__MDIA[$((_OSET_MDIA+14))]}" "${__DLOW}" && _LIST_RMOV+=("${__DLOW:?}")
							mount -t overlay overlay -o lowerdir="${__DLOW}",upperdir="${__DUPR}",workdir="${__DWKD}" "${__DMRG}" && _LIST_RMOV+=("${__DMRG:?}")
							# --- create auto install configuration file ------
							__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
							IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
							__FNAM="${__MDIA[$((_OSET_MDIA+14))]##*/}"
							__TSMP="${__MDIA[$((_OSET_MDIA+15))]:+" (${__MDIA[$((_OSET_MDIA+15))]//%20/ })"}"
							__FKNL="${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}"
							__FIRD="${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/}"
							case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
								*-mini-*) __FIRD="${__FIRD%/*}/${_MINI_IRAM:?}";;
								*       ) ;;
							esac
							__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
							case "${__MDIA[$((_OSET_MDIA+3))]:-}" in
								ubuntu*) __CIDR="";;
								*      ) __CIDR="/${_IPV4_CIDR:-}";;
							esac
							fnMk_isofile_grub "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							fnMk_isofile_ilnx "${__DMRG}" "${__FNAM:-}" "${__TSMP:-}" "${__FKNL:-}" "${__FIRD:-}" "${__HOST:-}" "${__CIDR:-}" "${__BOPT[@]:-}"
							# --- rebuild -------------------------------------
							__LABL="$(blkid -o value -s PTTYPE "${__MDIA[$((_OSET_MDIA+14))]}")"
							case "${_LABL:-}" in
								dos) ;;
								gpt)
									__FMBR="${__TEMP}/mbr.img"
									__FEFI="${__TEMP}/efi.img"
									__WORK="$(fdisk -l "${__MDIA[$((_OSET_MDIA+14))]}" 2>&1 | awk '$6~/EFI|ef/ {print $2, $4;}')"
									read -r  __SKIP __SIZE < <(echo "${__WORK:-}")
									dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=1 count=446 of="${__FMBR}" > /dev/null 2>&1
									dd if="${__MDIA[$((_OSET_MDIA+14))]}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${__FEFI}" > /dev/null 2>&1
									;;
								*  ) ;;
							esac
							__FCAT="$(find "${__DMRG}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \))"
							__FBIN="$(find "${__DMRG}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \))"
							fnMk_isofile_rebuild "${__DMRG}" "${__MDIA[$((_OSET_MDIA+18))]}" "${__MDIA[$((_OSET_MDIA+17))]}" "${__FMBR:-}" "${__FEFI:-}" "${__FCAT:-}" "${__FBIN:-}"
							__RETN="$(fnGetFileinfo "${__MDIA[$((_OSET_MDIA+18))]}")"
							read -r -a __ARRY < <(echo "${__RETN}")
							__MDIA[_OSET_MDIA+19]="${__ARRY[1]:-}"	# rmk_tstamp
							__MDIA[_OSET_MDIA+20]="${__ARRY[2]:-}"	# rmk_size
							__MDIA[_OSET_MDIA+21]="${__ARRY[3]:-}"	# rmk_volume
							# --- umount --------------------------------------
							umount "${__DMRG}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							umount "${__DLOW}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
							rm -rf "${__TEMP:?}"
							;;
					esac
					;;
				*) continue;;			# (hidden)
			esac
			# --- data registration -------------------------------------------
			__MDIA=("${__MDIA[@]// /%20}")
			J="${__MDIA[0]}"
			_LIST_MDIA[J]="$(
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-47s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__MDIA[@]:"${_OSET_MDIA}"}"
			)"
		done
	done
	fnList_mdia_Put "work.txt"
	unset __OPTN __PTRN __TYPE __LINE __TGET __MDIA __RETN __ARRY __TABS I J

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
