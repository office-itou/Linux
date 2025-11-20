# shellcheck disable=SC2148

	declare       __LINE=""
	# --- boot parameter selection --------------------------------------------
	for __LINE in ${_COMD_LINE:-} ${_PROG_PARM:-}
	do
		case "${__LINE}" in
			debug    | dbg                ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout             ) _DBGS_FLAG="true";;
			*) ;;
		esac
	done
