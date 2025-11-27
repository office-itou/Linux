# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: encoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_mdia_Enc() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	declare       __VALU=""				# setting value
	declare       __WNAM=""				# work: variable name
	declare       __WVAL=""				# work: setting value
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare -a    __LIST=()				# work
	declare -a    __ARRY=()				# work
	declare -i    I=0					# work
	declare -i    J=0					# work

	__ARRY=()
	for I in $(printf "%d\n" "${!_LIST_CONF[@]}" | sort -rV)
	do
		__LINE="${_LIST_CONF[I]:-}"
		__NAME="${__LINE%%[!_[:alnum:]]*}"
		[[ -z "${__NAME:-}" ]] && continue
		case "${__NAME}" in
			PATH_*     ) ;;
			DIRS_*     ) ;;
			FILE_*     ) ;;
			*          ) continue;;
		esac
		__ARRY+=("${__NAME}")
	done
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]:-}"
		for J in "${!__ARRY[@]}"
		do
			__WNAM="${__ARRY[J]}"
			__WORK="_${__WNAM}"
			__WVAL="${!__WORK:-}"
			__WVAL="${__WVAL#\"}"
			__WVAL="${__WVAL%\"}"
			[[ -z "${__WVAL:-}" ]] && continue
			__LINE="${__LINE//"${__WVAL}"/"${__WNAM:+":_${__WNAM}_:"}"}"
		done
		read -r -a __LIST < <(echo "${__LINE:-}")
		_LIST_MDIA[I]="$(\
			printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__LIST[@]}"
		)"
	done
	_LIST_MDIA=("${_LIST_MDIA[@]:-}")
	unset __NAME __VALU __WNAM __WVAL __WORK __LINE __LIST __ARRY I J

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
