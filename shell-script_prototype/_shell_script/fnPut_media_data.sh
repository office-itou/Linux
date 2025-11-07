# -----------------------------------------------------------------------------
# descript: put media data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnPut_media_data() {
	declare       __TGET_PATH="${1:?}"	# target path
    declare       __NAME=""             # variable name
    declare       __VALU=""             # "        value
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare -i    I=0
	# --- file export ---------------------------------------------------------
	fnExec_backup "${__TGET_PATH:?}"
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		for __NAME in "${!_@}"
		do
			case "${__NAME:-}" in
				_DIRS_LIVE | \
				_FILE_LIVE ) ;;
				_DIRS_*    | \
				_FILE_*    )
					__VALU="${!__NAME:-}"
					__LINE="${__LINE//${__VALU}/:_${__NAME##_}_:}"
					;;
				*          ) ;;
			esac
		done
		read -r -a __LIST < <(echo "${__LINE}")
		printf -v _LIST_MDIA[I] "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s " \
			"${__LIST[@]}"
	done
	printf "%s\n" "${_LIST_MDIA[@]}" > "${__TGET_PATH}"
}
