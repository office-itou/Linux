#!/bin/bash

###############################################################################
##
##	common functions test shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/04/15
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/04/15 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# :_tmpl_001_initialize_common.sh_:

# :_tmpl_001_initialize_test_function.sh_:

	# --- curl / wget parameter -----------------------------------------------
	declare       _COMD_CURL=""
	declare       _COMD_WGET=""
	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=10" "--quiet")
	if command -v curl  > /dev/null 2>&1; then _COMD_CURL="true"; fi
	if command -v wget  > /dev/null 2>&1; then _COMD_WGET="true"; fi
	if command -v wget2 > /dev/null 2>&1; then _COMD_WGET="ver2"; fi
	readonly      _COMD_CURL
	readonly      _COMD_WGET

# :_tmpl_003_function_section_library.sh_:

# :_tmpl_003_function_section_library_network.sh_:

# :_tmpl_003_function_section_library_media.sh_:

# :_tmpl_003_function_section_library_web_tool.sh_:

# :_tmpl_004_function_section_template.sh_:

# :_tmpl_005_function_section_test_function.sh_:

# -----------------------------------------------------------------------------
# descript: initialization for skel_test_function.sh (dummy)
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnInitialization() {
:
}

# -----------------------------------------------------------------------------
# descript: debug out parameter for skel_test_function.sh
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnDebug_parameter() {
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

# -----------------------------------------------------------------------------
# descript: help for skel_test_function.sh
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ${_PROG_PATH} [command (options)]

		  debug print and test
		    debug [func|text|parm]
		      func              : function test
		      text              : text color test
		      parm              : display of main internal parameters
_EOT_
}

# === main ====================================================================

# -----------------------------------------------------------------------------
# descript: main for skel_test_function.sh
#   input :   $@   : option parameter
#   output: stdout : unused
#   return:        : unused
function fnMain() {
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference

	# --- check the execution user --------------------------------------------
#	if [[ "${_USER_NAME}" != "root" ]]; then
#		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
#		exit 1
#	fi

	# --- get command line ----------------------------------------------------
	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			help    ) shift; fnHelp; exit 0;;
			*       ) shift;;
		esac
	done

	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	fnInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			help    ) shift; fnHelp; break;;
			debug   )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						func) shift; fnDebug_function;;
						text) shift; fnDebug_color;;
						parm) shift; fnDebug_parameter;;
						*   ) break;;
					esac
				done
				;;
			*       ) shift;;
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
	fnMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
