#!/bin/bash

###############################################################################
#
#	custom iso image creation and pxeboot configuration shell
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

	declare -r    _SHEL_TOPS="${_PROG_DIRS:?}"
	declare -r    _SHEL_COMN="${_PROG_DIRS:?}/../_common_bash"
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/fnGlobal_variables.sh			# global variables (for basic)
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/fnGlobal_common.sh				# global variables (for application)

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnMsgout.sh						# message output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnString.sh						# string output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnStrmsg.sh						# string output with message
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnTargetsys.sh					# target system state
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6FullAddr.sh				# IPv6 full address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6RevAddr.sh					# IPv6 reverse address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv4Netmask.sh					# IPv4 netmask conversion

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnDbgdump.sh						# dump output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnDbgparam.sh					# parameter debug output
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnFind_command.sh				# find command
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnFind_service.sh				# find service
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnNetwork_param.sh				# get network parameter
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnFile_backup.sh					# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnInitialize.sh					# initialize
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnSet_conf_data.sh				# set default common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnGet_conf_file.sh				# get auto-installation configuration file
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnPut_conf_data.sh				# put common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnMk_preconf.sh					# make preconfiguration files
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnMk_pxeboot.sh					# make pxeboot files
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fnMk_isofile.sh					# make iso files

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMain() {
	declare -r    _FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${_FUNC_NAME}]"

	declare       __PROC=""
	declare -a    __OPTN=()
	declare       __RSLT=""

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize

	# --- main processing -----------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			help    ) fnHelp; break;;
			reconf  ) fnMk_preconf "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			pxeboot ) fnMk_pxeboot "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			create  ) fnMk_isofile "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			*       ) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- debug output --------------------------------------------------------

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${_FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}

	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS}"/fncmdline.sh		# command line

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		fnDbgout "command line" \
			"debug,_COMD_LINE=[${_COMD_LINE:-}]"
	fi

	# --- main processing -----------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################
