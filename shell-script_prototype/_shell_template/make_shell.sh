#!/bin/bash

###############################################################################
##
##	:_PROG_TITL_:
##	  developed for debian
##
##	developer   : :_PROG_USER_:
##	release     : :_PROG_RELS_:
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	yyyy/mm/dd 000.0000 xxxxxxxxxxxxxx first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************
	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# === data section ========================================================

	# --- debug parameter -----------------------------------------------------
	_DBGS_FLAG=""						# debug flag (empty: normal, else: debug)

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# shellcheck disable=SC2317
function funcTrap() {
	declare -i    I=0

	for I in "${!_LIST_RMOV[@]}"
	do
		rm -rf "${_LIST_RMOV[I]:?}"
	done
}

	trap funcTrap EXIT

# *** function section (sub functions) ****************************************

# --- initialization ----------------------------------------------------------
function funcInitialization() {
:
}

# --- debug out parameter -----------------------------------------------------
function funcDebugout_parameter() {
:
}

# --- create ------------------------------------------------------------------
function funcCreate() {
	declare -a    _COMD_LINE=("${@:-}")	# command line
	declare       _LINE=""				# work variable
	declare       _NAME=""				# variable name
	declare       _VALU=""				# value
	declare       _SKEL_PATH=""			# skeleton file path

	for _LINE in "${_COMD_LINE[@]:-}"
	do
		_LINE="${_LINE%%#*}"
		_LINE="${_LINE//["${IFS}"]/ }"
		_LINE="${_LINE#"${_LINE%%[!"${IFS}"]*}"}"	# ltrim
		_LINE="${_LINE%"${_LINE##*[!"${IFS}"]}"}"	# rtrim
		_NAME="${_LINE%%=*}"
		_VALU="${_LINE#*=}"
		_VALU="${_VALU#\"}"
		_VALU="${_VALU%\"}"
		case "${_NAME:-}" in
			skel) _SKEL_PATH="$(realpath "${_VALU:?}")";;
			*   ) ;;
		esac
	done

	if [[ ! -f "${_SKEL_PATH}" ]]; then
		printf "\033[m\033[91m%s\033[m\n" "not exist ${_SKEL_PATH}"
		return
	fi


	printf "\033[m%s\033[m\n" "create start    ${_SKEL_PATH}"
	printf "\033[m%s\033[m\n" "create complete ${_SKEL_PATH}"
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
			--create) funcCreate "${_COMD_LINE[@]:-}";;
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
