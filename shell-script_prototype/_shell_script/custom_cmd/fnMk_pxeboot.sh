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
	declare -a    __PTRN=()				# pattern
	declare -a    __TGET=()				# target
	declare       __LINE=""				# data line
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path

	# --- get target ----------------------------------------------------------
	__PTRN=()
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "${1%%:*}" in
			a|all    ) __PTRN=("mini:all" "netinst:all" "dvd:all" "liveinst:all" "live:all" "tool:all" "clive:all" "cnetinst:all" "system:all"); shift; break;;
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

	# --- create a file  ------------------------------------------------------
	if [[ -n "${__PTRN:-}" ]]; then
		__TGET=()
		for I in "${!_LIST_MDIA[@]}"
		do
			__LINE="${_LIST_MDIA[I]:-}"
			read -r -a __LIST < <(echo "${__LINE:-}")
			case "${__LIST[1]}" in			# entry_flag
				o) ;;
				*) continue;;
			esac
			case "${__LIST[23]##*/}" in		# cfg_path
				-) continue;;
				*) ;;
			esac
			__PATH="${__LIST[23]}"
			__TGET+=("${__PATH}")
			case "${__PATH}" in
				*/agama/*    ) __TGET+=("${__PATH/_leap-*_/_tumbleweed_}");;
				*/kickstart/*) __TGET+=("${__PATH/_dvd/_web}");;
				*            ) ;;
			esac
		done
		IFS= mapfile -d $'\n' -t __TGET < <(IFS= printf "%s\n" "${__TGET[@]}" | grep -E "${__PTRN}" | sort -uV || true)
		for __PATH in "${__TGET[@]}"
		do
			case "${__PATH}" in
				*/preseed/*  ) fnMk_preconf_preseed   "${__PATH}";;
				*/nocloud/*  ) fnMk_preconf_nocloud   "${__PATH}/user-data";;
				*/kickstart/*) fnMk_preconf_kickstart "${__PATH}";;
				*/autoyast/* ) fnMk_preconf_autoyast  "${__PATH}";;
				*/agama/*    ) fnMk_preconf_agama     "${__PATH}";;
				*)	;;
			esac
		done
	fi
	unset __NAME_REFR __OPTN __PTRN __TGET __LINE __LIST __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
