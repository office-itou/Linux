# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: select target
#   n-ref :     $1     : return value : option parameter
#   n-ref :     $2     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : result
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _LIST_TYPE : read
function fnSelect_target() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NREF="${1:-}"		# name reference
	declare -n    __RETN="${2:-}"		# name reference
	shift 2
	              __NREF="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options

	declare       __TYPE=""				# media type
	declare       __RANG=""				# range
	declare -a    __ARRY=()				# arry
	declare -A    __AARY=()				# associative arrays

	# --- split optional parameters -------------------------------------------
	__AARY=()
	for I in "${_LIST_TYPE[@]}"
	do
		__AARY["${I}"]=""
	done
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__TYPE="${1%%:*}"
		__RANG="${1#"${__TYPE:-}"}"
		__RANG="${__RANG#"${__RANG%%[^:]*}"}"
		__RANG="${__RANG%"${__RANG##*[^:]}"}"
		case "${__TYPE:-}" in
			all      ) IFS= mapfile -d $'\n' -t __ARRY < <(printf "%s:all\n" "${_LIST_TYPE[@]}"); shift; break;;
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
		case "${__RANG:-}" in
			'' | \
			all| \
			[0-9]|[0-9][0-9]|[0-9][0-9][0-9])
				__RANG="${__RANG:-"inp"}"
				__AARY["${__TYPE:?}"]+="${__RANG:+"${__AARY["${__TYPE}"]:+","}${__RANG}"}"
				;;
			*) ;;
		esac
		shift
	done
	__NREF="${*:-}"
	# --- formatting the return value -----------------------------------------
	__ARRY=()
	for I in "${_LIST_TYPE[@]}"
	do
		__ARRY+=("${I}=${__AARY["${I}"]:-}")
	done
	# --- output and finalization ---------------------------------------------
	__RETN="${__ARRY[*]}"
	unset __TYPE __RANG __AARY __ARRY

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
