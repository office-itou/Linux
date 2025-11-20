#!/bin/bash

###############################################################################
#
#	make shell script
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2025/11/01
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2025/11/01 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#	            : shellcheck -o all -e SC2154 *.sh
#
###############################################################################

# *** global section **********************************************************

	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
#	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)

	# --- working directory ---------------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
#	declare -r    _PROG_PROC="${_PROG_NAME}.$$"

	# --- command line parameter ----------------------------------------------
									  	# command line parameter
	declare       _COMD_LINE=""
	              _COMD_LINE="$(cat /proc/cmdline)"
	readonly      _COMD_LINE

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)
	declare       _DBGS_LOGS=""			# debug file (empty: normal, else: debug)
	declare       _DBGS_PARM=""			# debug file (empty: normal, else: debug)
	declare       _DBGS_SIMU=""			# debug flag (empty: normal, else: simulation)
	declare       _DBGS_WRAP=""			# debug flag (empty: cut to screen width, else: wrap display)
	declare -a    _DBGS_FAIL=()			# debug flag (empty: success, else: failure)

	# --- working directory ---------------------------------------------------
	declare -r    _DIRS_WTOP="${_SUDO_HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
	mkdir -p   "${_DIRS_WTOP}"

	# --- temporary directory -------------------------------------------------
	declare       _DIRS_TEMP="${_DIRS_WTOP}"
	              _DIRS_TEMP="$(mktemp -qtd -p "${_DIRS_TEMP}" "${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- set system parameter ------------------------------------------------
	declare -i    _ROWS_SIZE=25			# screen size: rows
	declare -i    _COLS_SIZE=80			# screen size: columns
	declare       _TEXT_GAP1=""			# gap1: "-"
	declare       _TEXT_GAP2=""			# gap2: "="

	# --- external script -----------------------------------------------------
	declare -r    _SHEL_TOPS="${_PROG_DIRS:?}"
	declare -r    _SHEL_COMN="${_PROG_DIRS:?}/_common_bash"
	declare -r    _SHEL_CUST="${_PROG_DIRS:?}/custom_cmd"

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMN:?}"/fnMsgout.sh					# message output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN:?}"/fnString.sh					# string output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN:?}"/fnTrim.sh						# ltrim,rtrim,trim

	# shellcheck source=/dev/null
	source "${_SHEL_CUST:?}"/fnDbgout.sh					# message output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_CUST:?}"/fnDebugout_parameters.sh		# print out of internal variables
	# shellcheck source=/dev/null
	source "${_SHEL_CUST:?}"/fnTrap.sh						# trap

# *** function section (subroutine functions) *********************************

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var :  TERM      : read
#   g-var : _ROWS_SIZE : write
#   g-var : _COLS_SIZE : write
#   g-var : _TEXT_GAP1 : write
#   g-var : _TEXT_GAP2 : write
# shellcheck disable=SC2148,SC2317,SC2329
fnInitialize() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -i    __COLS=0				# work

	# --- set screen size: rows / columns -------------------------------------
	if [[ -n "${TERM:-}" ]] \
	&& command -v tput > /dev/null 2>&1; then
		_ROWS_SIZE=$(tput lines || true)
		_COLS_SIZE=$(tput cols  || true)
	fi
	[[ "${_ROWS_SIZE:-"0"}" -lt 25 ]] && _ROWS_SIZE=25
	[[ "${_COLS_SIZE:-"0"}" -lt 80 ]] && _COLS_SIZE=80
	readonly _ROWS_SIZE
	readonly _COLS_SIZE

	# --- set gap1 / gap2 -----------------------------------------------------
	__COLS="${_COLS_SIZE}"
	[[ -n "${_PROG_NAME:-}" ]] && __COLS=$((_COLS_SIZE-${#_PROG_NAME}-16))
	_TEXT_GAP1="$(fnString "${__COLS}" '-')"
	_TEXT_GAP2="$(fnString "${__COLS}" '=')"
	unset __COLS
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: initialize
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
# shellcheck disable=SC2148,SC2317,SC2329
function funcCreate() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=("${@:-}")		# options
	declare       __PARM=""				# parameters
	declare       __PATH=""				# full path
	declare       __TGET=""				# target
	declare       __TEMP=""				# temporary
	declare       __WORK=""				# work
	declare       __LINE=""				# work
	declare       __TEXT=""				# work
	declare       __FLAG=""				# work
	declare       __BLNK=""				# work

	__NAME_REFR="${__OPTN[*]:-}"
	while [[ -n "${1:-}" ]]
	do
		__PARM="$1"
		shift
#		__OPTN=("${@:-}")

		# --- file check ------------------------------------------------------
		if [[ ! -e "${__PARM}" ]]; then
			break
		fi
		__OPTN=("${@:-}")
		if file "${__PARM}" | grep -q 'with CRLF'; then
			fnMsgout "${_PROG_NAME:-}" "failed" "with CRLF: [${__PARM}]"
			exit 1
		fi

		# --- file creation ---------------------------------------------------
		__TGET="${__PARM//skel_/}"
		fnMsgout "${_PROG_NAME:-}" "start" "create   : [${__TGET}]"
		__TEMP="$(mktemp -q -p "${_DIRS_TEMP:-/tmp}" "${__TGET##*/}.XXXXXX")"
		: > "${__TEMP:?}"
		__BLNK=""
		while IFS= read -r __LINE
		do
			__WORK="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
			__WORK="${__WORK%"${__WORK##*[!"${IFS}"]}"}"	# rtrim
			case "${__WORK:-}" in
				"#"[${IFS}]*"shellcheck"[${IFS}]*"source="* ) continue;;
				"#"[${IFS}]*"shellcheck"[${IFS}]*"disable="*) continue;;
				"readonly"[${IFS}]*"_SHEL_TOPS="*) continue;;
				"readonly"[${IFS}]*"_SHEL_COMN="*) continue;;
				"declare"[${IFS}]*"-r"[${IFS}]*"_SHEL_TOPS="*) continue;;
				"declare"[${IFS}]*"-r"[${IFS}]*"_SHEL_COMN="*) continue;;
				*) ;;
			esac
			__WORK="${__WORK%%["${IFS}"]*}"
			case "${__WORK}" in
				'.' | 'source')
					__PATH="${__LINE}"
					__PATH="${__PATH%%#*}"
					__PATH="${__PATH#*[!"${IFS}"]}"
					__PATH="${__PATH#"${__PATH%%[!"${IFS}"]*}"}"	# ltrim
					__PATH="${__PATH%"${__PATH##*[!"${IFS}"]}"}"	# rtrim
					__PATH="${__PATH//\"\$\{_SHEL_TOPS*\}\"/${__PARM%/*}}"
					case "${__WORK}" in
						'.'     ) __PATH="${__PATH//\"\$\{_SHEL_COMN*\}\"/${__PARM%/*}\/..\/_common_sh}"  ;;
						'source') __PATH="${__PATH//\"\$\{_SHEL_COMN*\}\"/${__PARM%/*}\/..\/_common_bash}";;
						*       ) ;;
					esac
					__FLAG=""
					while IFS= read -r __TEXT
					do
						case "${__TEXT#"${__TEXT%%[!"${IFS}"]*}"}" in
							"#"[${IFS}]*"g-var"[${IFS}]*                ) continue;;
							"#"[${IFS}]*"shellcheck"[${IFS}]*"source="* ) continue;;
							"#"[${IFS}]*"shellcheck"[${IFS}]*"disable="*) continue;;
							"#"[${IFS}]*) __FLAG="true";;
							'') [[ -z "${__FLAG:-}" ]] && continue;;
							*) ;;
						esac
						echo "${__TEXT:-}" >> "${__TEMP}"
					done < "${__PATH}"
					echo "" >> "${__TEMP}"
					__BLNK="true"
					;;
				*)
					if [[ -n "${__BLNK:-}" ]] && [[ -z "${__LINE:-}" ]]; then
						:
					else
						echo "${__LINE:-}" >> "${__TEMP}"
					fi
					__BLNK=""
					;;
			esac
		done < "${__PARM}"

		# --- complete --------------------------------------------------------
		cp "${__TEMP}" "${__TGET}"
		rm -f "${__TEMP:?}"
		fnMsgout "${_PROG_NAME:-}" "complete" "create   : [${__TGET}]"
	done
	__NAME_REFR="${__OPTN[*]:-}"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: main
#   n-ref :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
#   g-var : _PROG_PARM : read
# shellcheck disable=SC2148
function fnMain() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PARM=""				# parameters
	declare -a    __OPTN=()				# options
	declare       __REFR=""				# name reference

	# --- subroutine ----------------------------------------------------------
	fnInitialize						# initialize

	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PARM="$1"
		shift
		__OPTN=("${@:-}")
		case "${__PARM}" in
			create)
				funcCreate __REFR "${__OPTN[@]:-}"
				read -r -a __OPTN < <(echo "${__REFR}")
				;;
			*) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

	declare -i    __time_start=0		# elapsed time: start
	declare -i    __time_end=0			# "           : end
	declare -i    __time_elapsed=0		# "           : result

	declare       __PARM=""				# parameters
	declare -a    __OPTN=()				# options

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- boot parameter selection --------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PARM="$1"
		shift
		__OPTN=("${@:-}")
		case "${__PARM}" in
			debug    | dbg                ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout             ) _DBGS_FLAG="true";;
			*) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- main routine --------------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################
