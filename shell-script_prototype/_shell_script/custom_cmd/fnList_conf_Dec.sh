# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: decoding common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_CONF : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_conf_Dec() {
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
	declare -i    I=0					# work

	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]}"
		# comments with "#" do not work
		__NAME="${__LINE%%[!_[:alnum:]]*}"
		__VALU="${__LINE#"${__NAME:-}="}"
		__CMNT="${__VALU#"${__VALU%%\#*}"}"
		__CMNT="${__CMNT#"${__CMNT%%[!"${IFS}"]*}"}"	# ltrim
		__CMNT="${__CMNT%"${__CMNT##*[!"${IFS}"]}"}"	# rtrim
		__VALU="${__VALU%"${__CMNT:-}"}"
		__VALU="${__VALU#"${__VALU%%[!"${IFS}"]*}"}"	# ltrim
		__VALU="${__VALU%"${__VALU##*[!"${IFS}"]}"}"	# rtrim
		# --- store in a variable ---------------------------------------------
		[[ -z "${__NAME:-}" ]] && continue
#		case "${__NAME}" in
#			PATH_*     ) ;;
#			DIRS_*     ) ;;
#			FILE_*     ) ;;
#			*          ) continue;;
#		esac
		__WNAM="${__NAME:-}"
		__NAME="_${__WNAM:-}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		# --- setting value conversion ----------------------------------------
		case "${__WNAM}" in
			PATH_*     | \
			DIRS_*     | \
			FILE_*     )
				while true
				do
					__WNAM="${__VALU#"${__VALU%%:_[[:alnum:]]*_[[:alnum:]]*_:*}"}"
					__WNAM="${__WNAM%"${__WNAM##*:_[[:alnum:]]*_[[:alnum:]]*_:}"}"
					__WNAM="${__WNAM%%[!:_[:alnum:]]*}"
					__WNAM="${__WNAM#:_}"
					__WNAM="${__WNAM%_:}"
					[[ -z "${__WNAM:-}" ]] && break
					__VALU="${__VALU/":_${__WNAM}_:"/"\${_${__WNAM}}"}"
				done
				;;
			*) ;;
		esac
		read -r "${__NAME:?}" < <(eval echo "${__VALU}" || true)
	done
	unset __NAME __VALU __CMNT __WNAM __WVAL __WORK __LINE I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
