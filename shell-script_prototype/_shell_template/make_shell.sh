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

	# --- work variables ------------------------------------------------------
	declare -r    _ORIG_IFS="${IFS:-}"	# IFS backup
	declare -r    _COMD_IFS=" =,"		# IFS for command line

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
	declare -n    _NAME_REFS="$1"		# name reference
	shift
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare       _LINE=""				# work variable
	declare       _SKEL=""				# work variable (skeleton)
	declare       _TMPL=""				# work variable (template)
	declare       _CRAT=""				# work variable (created)

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-*) break;;
			* )
				_SKEL="$1"
				shift
				if [[ ! -f "${_SKEL}" ]]; then
					printf "\033[m\033[91m%s\033[m\n" "not exist ${_SKEL}"
					continue
				fi
				_CRAT="${_SKEL}.txt"
				printf "\033[m%s\033[m\n" "create start    ${_SKEL}"
				printf "\033[m%s\033[m\n" "create start    ${_CRAT}"
				rm -f "${_CRAT:?}"
				while IFS= read -r _LINE
				do
					_TMPL="${_LINE#"${_LINE%%:*}"}"
					_TMPL="${_TMPL%"${_TMPL##*:}"}"
					case "${_TMPL}" in
						:_tmpl_*.sh_:)
							_TMPL="${_TMPL#:_}"
							_TMPL="${_TMPL%_:}"
							if [[ "${_TMPL##*/}" = "${_TMPL%/*}" ]]; then
								_TMPL="${_SKEL%/*}/${_TMPL}"
							fi
							if [[ ! -f "${_TMPL}" ]]; then
								printf "\033[m\033[91m%s\033[m\n" "not exist ${_TMPL}"
								continue
							fi
							cat "${_TMPL}"  >> "${_CRAT}" || true
							;;
						*)
							echo "${_LINE}" >> "${_CRAT}"
							;;
					esac
				done < <(sed -e '/^#.*initialization.*$/,/^$/d' -e '/^#.*debug out parameter.*$/,/^$/d' "${_SKEL}" || true)
				printf "\033[m%s\033[m\n" "create complete ${_CRAT}"
				printf "\033[m%s\033[m\n" "create complete ${_SKEL}"
				;;
		esac
	done
	_NAME_REFS="${*:-}"
}

# === main ====================================================================

function funcMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference

	# --- check the execution user --------------------------------------------
#	if [[ "$(whoami || true)" != "root" ]]; then
#		printf "\033[m%s\033[m\n" "run as root user."
#		exit 1
#	fi

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

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
	funcDebugout_parameter				# debug out parameter

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1%%=*}" in
			--create) shift; funcCreate _RETN_PARM "$@";;
			*       ) shift; _RETN_PARM=("$@");;
		esac
		IFS="${_COMD_IFS:-}"
		set -f -- "${_RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
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
