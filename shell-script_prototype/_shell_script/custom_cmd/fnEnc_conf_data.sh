# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: encoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_CONF : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnEnc_conf_data() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __NAME=""				# variable name
	declare       __VALU=""				# setting value
	declare       __CMNT=""				# comment
	declare       __WNAM=""				# work: variable name
	declare       __WVAL=""				# work: setting value
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare -a    __LIST=()				# work
	declare -a    __ARRY=()				# work
	declare -i    I=0					# work
	declare -i    J=0					# work

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
	__LIST=()
	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]:-}"
		__LIST+=("${__LINE:-}")
		# comments with "#" do not work
		# --- get variable name -----------------------------------------------
		__NAME="${__LINE%%[!_[:alnum:]]*}"
		# --- get setting value -----------------------------------------------
		__VALU="${__LINE#"${__NAME:-}="}"
		__VALU="${__VALU%"#${__VALU##*#}"}"
		__VALU="${__VALU#"${__VALU%%[!"${IFS}"]*}"}"	# ltrim
		__VALU="${__VALU%"${__VALU##*[!"${IFS}"]}"}"	# rtrim
		# --- get comment -----------------------------------------------------
		__CMNT="${__LINE#"${__NAME:+"${__NAME}="}${__VALU:-}"}"
		__CMNT="${__CMNT#"${__CMNT%%[!"${IFS}"]*}"}"	# ltrim
		__CMNT="${__CMNT%"${__CMNT##*[!"${IFS}"]}"}"	# rtrim
		# --- store in a variable ---------------------------------------------
		case "${__CMNT:-}" in
			*"application output"*)
				__LIST+=("#   $(date +"%Y/%m/%d %H:%M:%S") J.Itou          application output")
				continue
				;;
			*) ;;
		esac
		[[ -z "${__NAME:-}" ]] && continue
		case "${__NAME}" in
			PATH_*     ) ;;
			DIRS_*     ) ;;
			FILE_*     ) ;;
			*          ) continue;;
		esac
		__WNAM="_${__NAME}"
		__VALU="${!__WNAM:-}"
		# --- setting value conversion ----------------------------------------
		for J in "${!__ARRY[@]}"
		do
			__WNAM="${__ARRY[J]}"
			case "${__WNAM}" in
				"${__NAME}") continue;;
				PATH_*     ) ;;
				DIRS_*     ) ;;
				FILE_*     ) ;;
				*          ) continue;;
			esac
			__WORK="_${__WNAM}"
			__WVAL="${!__WORK:-}"
			__WVAL="${__WVAL#\"}"
			__WVAL="${__WVAL%\"}"
			[[ -z "${__WVAL:-}" ]] && continue
			__VALU="${__VALU//"${__WVAL}"/"${__WNAM:+":_${__WNAM}_:"}"}"
		done
		__LIST[${#__LIST[@]}-1]="$(printf "%-39s %s" "${__NAME:-}=\"${__VALU:-}\"" "${__CMNT:-}")"
	done
	_LIST_CONF=("${__LIST[@]}")

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
