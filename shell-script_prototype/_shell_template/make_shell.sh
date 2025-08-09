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
	declare -r    _USER_NAME="${USER:-"$(whoami || true)"}"

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

# shellcheck disable=SC2317,SC2329
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
	declare       _VARS_CHAR="_"		# variable initial letter
	declare       _VARS_NAME=""			# "        name
	declare       _VARS_VALU=""			# "        value

	if [[ -z "${_DBGS_FLAG:-}" ]]; then
		return
	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for _VARS_CHAR in {A..Z} {a..z} "_"
#	do
		for _VARS_NAME in $(eval echo \$\{\!"${_VARS_CHAR}"\@\})
		do
			_VARS_NAME="${_VARS_NAME#\'}"
			_VARS_NAME="${_VARS_NAME%\'}"
			if [[ -z "${_VARS_NAME}" ]]; then
				continue
			fi
			case "${_VARS_NAME}" in
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

# --- create ------------------------------------------------------------------
function funcCreate() {
	declare -n    _NAME_REFS="$1"		# name reference
	shift
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare       _PATH=""				# path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
#	declare       _WORK=""				# work variable
	declare       _LINE=""				# work variable
	declare       _SKEL=""				# work variable (skeleton)
	declare       _TMPL=""				# work variable (template)
	declare       _CRAT=""				# work variable (created)
	declare       _TEMP=""				# work variable (temporary)

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-*) break;;
			* )
				_SKEL="$1"
				shift
				if [[ ! -f "${_SKEL}" ]]; then
					printf "\033[m\033[91m%20.20s: %s\033[m\n" "not exist" "${_SKEL}"
					continue
				fi
				if file "${_SKEL}" | grep 'with CRLF'; then
					printf "\033[m\033[91m%20.20s: %s\033[m\n" "with CRLF" "${_SKEL}"
					exit 1
				fi
				_FNAM="${_SKEL##*/}"
				_DIRS="${_SKEL%"${_FNAM}"}"
				_CRAT="${_DIRS}${_FNAM#skel_}"
				_TEMP="${_CRAT:?}.tmp"
				if [[ "${_CRAT:?}" = "${_SKEL:?}" ]]; then
					printf "%s\n" "abort because file name input and output are the same" 1>&2
					printf "%s\n" "input : ${_SKEL}" 1>&2
					printf "%s\n" "output: ${_CRAT}" 1>&2
					exit 1
				fi
				printf "\033[m%s\033[m\n" "create start    ${_SKEL}"
				printf "\033[m%s\033[m\n" "create start    ${_CRAT}"
				rm -f "${_TEMP:?}"
				while IFS= read -r _LINE
				do
					_TMPL="${_LINE#"${_LINE%%:*}"}"
					_TMPL="${_TMPL%"${_TMPL##*:}"}"
					case "${_TMPL}" in
						:_tmpl_*.sh_:)
							_TMPL="${_TMPL#:_}"
							_TMPL="${_TMPL%_:}"
							if [[ "${_TMPL##*/}" = "${_TMPL%/*}" ]]; then
								_FNAM="${_SKEL##*/}"
								_DIRS="${_SKEL%"${_FNAM}"}"
								_TMPL="${_DIRS}${_TMPL}"
								if file "${_TMPL}" | grep 'with CRLF'; then
									printf "\033[m\033[91m%20.20s: %s\033[m\n" "with CRLF" "${_TMPL}"
									exit 1
								fi
							fi
							if [[ ! -f "${_TMPL}" ]]; then
								printf "\033[m\033[91m%s\033[m\n" "not exist ${_TMPL}"
								continue
							fi
							cat "${_TMPL}"  >> "${_TEMP}" || true
							;;
						*)
							echo "${_LINE}" >> "${_TEMP}"
							;;
					esac
				done < <(sed -e '/^#.*initialization.*$/,/^$/d' "${_SKEL}" || true)
				mv --force "${_TEMP:?}" "${_CRAT:?}"
				printf "\033[m%s\033[m\n" "create complete ${_CRAT}"
				shellcheck -o all "${_CRAT}"
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
#	if [[ "${_USER_NAME:-}" != "root" ]]; then
#		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
#		exit 1
#	fi

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
	funcDebugout_parameter				# debug out parameter

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1%%=*}" in
			--dbgprn) shift; funcDebug_function;;
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

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
