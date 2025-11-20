#!/bin/bash

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
	declare -r    _SHEL_COMN="${_PROG_DIRS:?}/_common_bash"
	declare -r    _SHEL_COMD="${_PROG_DIRS:?}/custom_cmd"
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_variables.sh			# global variables (for basic)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_common.sh				# global variables (for application)

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnMsgout.sh						# message output
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnString.sh						# string output
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnStrmsg.sh						# string output with message
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnTargetsys.sh					# target system state
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv6FullAddr.sh				# IPv6 full address
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv6RevAddr.sh					# IPv6 reverse address
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv4Netmask.sh					# IPv4 netmask conversion

	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnDbgdump.sh						# dump output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnDbgparam.sh					# parameter debug output
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnFind_command.sh				# find command
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnFind_service.sh				# find service
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnNetwork_param.sh				# get network parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_TOPS}"/fnFile_backup.sh					# file backup

# *** function section (subroutine functions) *********************************

# shellcheck disable=SC1091
source "${_SHEL_COMN}"/fnMsgout.sh
# shellcheck disable=SC1091
source "${_SHEL_COMD}"/fnDbgparameters.sh
# shellcheck disable=SC1091
source "${_SHEL_COMD}"/fnPut_conf_data.sh
# shellcheck disable=SC1091
source "${_SHEL_COMD}"/fnGet_conf_data.sh

declare -a    _LIST_CONF=()
declare       __PROC=""
declare -a    __OPTN=()
declare       __RSLT=""

set -f -- "${@:-}"
set +f
while [[ -n "${1:-}" ]]
do
	__PROC="${1:-}"
	shift
	__OPTN=("${@:-}")
	case "${__PROC:-}" in
		get) fnGet_conf_data __RSLT "${@:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
		put) fnPut_conf_data __RSLT "${@:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
		dsp) printf "%s\n" "${_LIST_CONF[@]:-}";;
		*  ) ;;
	esac
	set -f -- "${__OPTN[@]}"
	set +f
done

for __NAME in "${!_@}"
do
	__NAME="${__NAME#\'}"
	__NAME="${__NAME%\'}"
	case "${__NAME:-}" in
		''        ) continue;;
		_[A-Za-z]*) ;;
		*         ) continue;;
	esac
	__VALU="$(eval echo -n "\${${__NAME}:-}")"
	printf "%s=[%s]\n" "${__NAME}" "${__VALU:-}"
done
