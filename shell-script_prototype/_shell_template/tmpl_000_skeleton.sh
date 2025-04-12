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
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"$(whoami || true)"}"

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare       _DIRS_TEMP=""
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

# :_tmpl_001_initialize.sh_:

# :_tmpl_002_data_section.sh_:

# :_tmpl_003_function_section_library.sh_:

# :_tmpl_004_function_section_common.sh_:

# --- initialization ----------------------------------------------------------
function funcInitialization() {
:
}

# --- debug out parameter -----------------------------------------------------
funcDebug_parameter() {
	declare       _VARS_CHAR="_"		# variable initial letter
	declare       _VARS_NAME=""			#          name
	declare       _VARS_VALU=""			#          value

#	if [[ -z "${_DBGS_FLAG:-}" ]]; then
#		return
#	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for _VARS_CHAR in {A..Z} {a..z} "_"
#	do
		for _VARS_NAME in $(eval printf "%q\\\n"  \$\{\!"${_VARS_CHAR}"\@\})
		do
			_VARS_NAME="${_VARS_NAME#\'}"
			_VARS_NAME="${_VARS_NAME%\'}"
			if [[ -z "${_VARS_NAME}" ]]; then
				continue
			fi
			case "${_VARS_NAME}" in
				_TEXT_*    | \
				_VARS_CHAR | \
				_VARS_NAME | \
				_VARS_VALU ) continue;;
				*) ;;
			esac
			_VARS_VALU="$(eval printf "%q" \$\{"${_VARS_NAME}":-\})"
			printf "%s=[%s]\n" "${_VARS_NAME}" "${_VARS_VALU/#\'\'/}"
		done
#	done
}

# === main ====================================================================

function funcMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME}" != "root" ]]; then
		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
		exit 1
	fi

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- get command line ----------------------------------------------------
	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			*       ) shift;;
		esac
	done

	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- main ----------------------------------------------------------------
	funcInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			create  ) ;;
			update  ) ;;
			download) ;;
			link    ) ;;
			conf    ) ;;
			debug   )
				shift
				case "${1:-}" in
					func) shift; funcDebug_function;;
					text) shift; funcDebug_color;;
					parm) shift; funcDebug_parameter;;
					*   ) ;;
				esac
				;;
			*       ) ;;
		esac
		_RETN_PARM=("$@")
		IFS="${_COMD_IFS:-}"
		set -f -- "${_RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
	done

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
