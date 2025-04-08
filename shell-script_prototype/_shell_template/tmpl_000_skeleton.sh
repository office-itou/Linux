# :_tmpl_001_initialize.sh_:

# :_tmpl_002_data_section.sh_:

# :_tmpl_003_function_section_common.sh_:

# --- initialization ----------------------------------------------------------
function funcInitialization() {
:
}

# --- debug out parameter -----------------------------------------------------
function funcDebugout_parameter() {
:
}

# === main ====================================================================

function funcMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -a    _COMD_LINE=("${@:-}")	# command line
	declare       _LINE=""				# work variable

	# --- check the execution user --------------------------------------------
	if [[ "$(whoami || true)" != "root" ]]; then
		printf "\033[m%s\033[m\n" "run as root user."
		exit 1
	fi

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- get command line ----------------------------------------------------
	for _LINE in "${_COMD_LINE[@]:-}"
	do
		case "${_LINE:-}" in
			--dbg   ) _DBGS_FLAG="true"; set -x;;
			--dbgout) _DBGS_FLAG="true";;
			*       ) ;;
		esac
	done

	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- main ----------------------------------------------------------------
	funcInitialization					# initialization
	funcDebugout_parameter				# debug out parameter

	for _LINE in "${_COMD_LINE[@]:-}"
	do
		case "${_LINE:-}" in
			--create) ;;
			*       ) ;;
		esac
	done

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))

	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
