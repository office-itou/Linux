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
	declare -r    _SHEL_COMN="${_SHEL_TOPS:-}/_common_bash"
	declare -r    _SHEL_COMD="${_SHEL_TOPS:-}/custom_cmd"
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_variables.sh			# global variables (for basic)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_common.sh				# global variables (for application)

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
	source "${_SHEL_COMD}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgdump.sh						# dump output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparam.sh					# parameter debug output
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparameters.sh				# print out of internal variables
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparameters_all.sh			# print out of all variables
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFind_command.sh				# find command
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFind_service.sh				# find service
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnNetwork_param.sh				# get network parameter
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFile_backup.sh					# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnInitialize.sh					# initialize
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnSet_conf_data.sh				# set default common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnEnc_conf_data.sh				# encoding common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDec_conf_data.sh				# decoding common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnGet_conf_data.sh				# get auto-installation configuration file
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnPut_conf_data.sh				# put common configuration data
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_preconf.sh					# make preconfiguration files
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot.sh					# make pxeboot files
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_isofile.sh					# make iso files

# *** main section ************************************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnCmdline.sh		# command line

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	fnSystem_param

	fnGet_conf_data "$1"

#fnDbgparameters_all

	fnDec_conf_data

	for __NAME in $(eval printf "%q\\\n" "\${!"{{A..Z},{a..z},_}"@}")
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME}" in
			_PATH_*) ;;
			_DIRS_*) ;;
			_FILE_*) ;;
			*      ) continue;;
		esac
#		echo "${__NAME:?}"
		__WORK="$(declare -p "${__NAME:?}" | awk -F ' ' '{print $2;}')"
		[[ "${__WORK:-}" = "-r" ]] && continue
		__VALU="${!__NAME:-}"
		__VALU="${__VALU/\/srv/\/srv\/public}"
		read -r "${__NAME:?}" < <(echo "${__VALU}" || true)
	done
#_DIRS_TOPS="/srv/public"
#_DIRS_HGFS="${_DIRS_TOPS:-}/hgfs"
#_DIRS_HTML="${_DIRS_TOPS:-}/http/html"
#_DIRS_SAMB="${_DIRS_TOPS:-}/samba"
#_DIRS_TFTP="${_DIRS_TOPS:-}/tftp"
#_DIRS_USER="${_DIRS_TOPS:-}/user"

if false; then
	for __NAME in $(eval printf "%q\\\n" "\${!"{{A..Z},{a..z},_}"@}")
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME}" in
			''     | \
			__NAME | \
			__VALU ) continue;;
			_[[:alnum:]]*) ;;
			*) continue;;
		esac
		__VALU="${!__NAME:-}"
		printf "${FUNCNAME[0]:-"top"}: %s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
	done
fi

#fnDbgparameters_all

#	printf "%s\n" "${_LIST_CONF[@]:-}"

	fnEnc_conf_data 
	printf "%s\n" "${_LIST_CONF[@]:-}"
