# === <web_tools> =============================================================

# --- get web information -----------------------------------------------------
# shellcheck disable=SC2317
function funcGetWebinfo() {
	declare       _FILD=""				# field name
	declare       _VALU=""				# value
	declare       _CODE=""				# status codes
	declare       _LENG=""				# content-length
	declare       _LMOD=""				# last-modified
	declare       _LINE=""				# work variables
	declare -a    _LIST=()				# work variables
	declare -a    _ARRY=()				# work variables
	declare -i    I=0					# work variables
	declare -i    R=0					# work variables

	_ARRY=()
	if [[ -n "${1:-}" ]]; then
		_LENG=""
		_LMOD=""
		for ((R=0; R<3; R++))
		do
			if ! _LINE="$(wget --trust-server-names --spider --server-response --output-document=- "$1" 2>&1)"; then
				continue
			fi
			IFS= mapfile -d $'\n' -t _LIST < <(echo "${_LINE}")
			for I in "${!_LIST[@]}"
			do
				_LINE="${_LIST[I],,}"
				_LINE="${_LINE#"${_LINE%%[!"${IFS}"]*}"}"	# ltrim
				_LINE="${_LINE%"${_LINE##*[!"${IFS}"]}"}"	# rtrim
				_FILD="${_LINE%% *}"
				_VALU="${_LINE#* }"
				case "${_FILD%% *}" in
					http/*         ) _CODE="${_VALU%% *}";;
					content-length:) _LENG="${_VALU}";;
					last-modified: ) _LMOD="$(TZ=UTC date -d "${_VALU}" "+%Y/%m/%d%%20%H:%M:%S+%Z")";;
					*) ;;
				esac
			done
			case "${_CODE}" in				# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
				1??) break            ;;	# 1xx (Informational): The request was received, continuing process
				2??) break            ;;	# 2xx (Successful)   : The request was successfully received, understood, and accepted
				3??) break            ;;	# 3xx (Redirection)  : Further action needs to be taken in order to complete the request
				4??) sleep 3; continue;;	# 4xx (Client Error) : The request contains bad syntax or cannot be fulfilled
				5??) sleep 3; continue;;	# 5xx (Server Error) : The server failed to fulfill an apparently valid request
				*  ) sleep 3; continue;;	#      Unknown Error
			esac
		done
		_ARRY=("$1" "${_LMOD}" "${_LENG}" "${_CODE}")
	fi
	echo -n "${_ARRY[*]}"
}
