# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_CONF : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnGet_conf_data() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=("${@:-}")		# options
	declare       __REFR=""
	declare       __LINE=""
	declare       __NAME=""
	declare       __VALU=""
	declare       __WORK=""
	declare -i    I=0

	if [[ ! -e "${1:?}" ]]; then
		fnPut_conf_data __REFR "${@:-}"
		read -r -a __OPTN < <(echo "${__REFR}")
	fi

	_LIST_CONF=()
	IFS= mapfile -d $'\n' -t _LIST_CONF < <(expand -t 4 "$1" || true)

	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]}"
		__LINE="${__LINE%%#*}"
		__LINE="${__LINE//["${IFS}"]/ }"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__NAME="${__LINE%%=*}"
		case "${__NAME:-}" in
			"" ) continue;;
			\#*) continue;;
			*  ) ;;
		esac
		__VALU="${__LINE#*=}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		[[ -z "${__VALU:-}" ]] && continue
		while true
		do
			__WORK="${__VALU%%_:*}"
			__WORK="${__WORK##*:_}"
			case "${__WORK:-}" in
				DIRS_*) ;;
				FILE_*) ;;
				*     ) break;;
			esac
			__VALU="${__VALU/:_${__WORK}_:/\$\{_${__WORK}\}}"
		done
		read -r "_${__NAME}" < <(eval echo "${__VALU}" || true)
	done

	__NAME_REFR="${__OPTN[*]:-}"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
