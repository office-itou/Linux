# -----------------------------------------------------------------------------
# descript: set common media data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnSet_media_data() {
	declare       __PTRN=""				# pattern
	declare       __STRG=""				# string
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare       __WORK=""				# work variables
	declare -i    I=0
	# --- data conversion -----------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		while true
		do
			__WORK="${__LINE%%_:*}"
			__WORK="${__WORK##*:_}"
			case "${__WORK:-}" in
				DIRS_*) ;;
				FILE_*) ;;
				*     ) break;;
			esac
			__PTRN="${__WORK:-}"
			__STRG="$(eval echo \$\{_"${__WORK:-}"\})"
			__LINE="${__LINE/:_${__PTRN}_:/${__STRG}}"
		done
		read -r -a __LIST < <(echo "${__LINE}")
		_LIST_MDIA[I]="${__LIST[*]}"
	done
	fnDebugout_list "${_LIST_MDIA[@]}"
}
