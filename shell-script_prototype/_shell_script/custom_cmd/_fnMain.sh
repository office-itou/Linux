# -----------------------------------------------------------------------------
# descript: main
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
#   g-var : _DIRS_WTOP : read
# shellcheck disable=SC2148
function fnMain() {
	declare -i    __time_start=0		# elapsed time: start
	declare -i    __time_end=0			# "           : end
	declare -i    __time_elapsed=0		# "           : result

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=()				# options
	declare       __ORET=""				# "       return
	declare -a    __ARRY=()				# work variables

	set -f -- "${@:-}"
	set +f
	__OPTN=()
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			clean    )
				fnMsgout "remove" "${_DIRS_WTOP:?} (y or n) ?"
				rm -rI "${_DIRS_WTOP:?}"
				break
				;;
			help     )
				fnHelp
				break
				;;
			testparm )
				fnInitialize
				fnDebugout_allparameters
				break
				;;
			create   )
				fnInitialize
				fnRootfs
				fnContainer
				fnSquashfs
				fnCdfs
				;;
			pxeboot  ) ;;
			list     ) ;;
			update   ) ;;
			download ) ;;
			link     )
				fnMKdirectory
				break
				;;
			conf     ) ;;
			preconf  ) ;;
			initial  )
				fnMKinitialfile
				fnSet_srvr_data
				fnPut_conf_data "${_PATH_CONF:?}"
				break
				;;
			*        )
				__OPTN+=("${1:-}")
				;;
		esac
		shift
	done
	__NAME_REFR="${__OPTN[*]:-}"

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))
	fnDbgparameters
}
