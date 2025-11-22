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
#	source "${_SHEL_COMD:?}"/fnGlobal_variables.sh			# global variables (for basic)
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD:?}"/fnGlobal_common.sh				# global variables (for application)

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

# --- set system parameter ------------------------------------------------
if [[ -n "${TERM:-}" ]] \
&& command -v tput > /dev/null 2>&1; then
	_ROWS_SIZE=$(tput lines || true)
	_COLS_SIZE=$(tput cols  || true)
fi
[[ "${_ROWS_SIZE:-"0"}" -lt 25 ]] && _ROWS_SIZE=25
[[ "${_COLS_SIZE:-"0"}" -lt 80 ]] && _COLS_SIZE=80
readonly _ROWS_SIZE
readonly _COLS_SIZE

__COLS="${_COLS_SIZE}"
[[ -n "${_PROG_NAME:-}" ]] && __COLS=$((_COLS_SIZE-${#_PROG_NAME}-16))
_TEXT_GAP1="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '-')"
_TEXT_GAP2="$(fnString "${__COLS:-"${_COLS_SIZE}"}" '=')"
unset __COLS
readonly _TEXT_GAP1
readonly _TEXT_GAP2

if realpath "$(command -v cp || true)" | grep 'busybox'; then
	_COMD_BBOX="true"
	_OPTN_COPY="-p"
fi

# --- target virtualization -----------------------------------------------
__WORK="$(fnTargetsys)"
case "${__WORK##*,}" in
	offline) _TGET_CNTR="true";;
	*      ) _TGET_CNTR="";;
esac
readonly _TGET_CNTR
readonly _TGET_VIRT="${__WORK%,*}"

_DIRS_TGET=""
for __DIRS in \
	/target \
	/mnt/sysimage \
	/mnt/
do
	[[ ! -e "${__DIRS}"/root/. ]] && continue
	_DIRS_TGET="${__DIRS}"
	break
done
readonly _DIRS_TGET

# --- samba ---------------------------------------------------------------
_SHEL_NLIN="$(fnFind_command 'nologin' | sort -r | head -n 1)"
_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /usr/sbin/nologin ]]; then echo "/usr/sbin/nologin"; fi)"}"
_SHEL_NLIN="${_SHEL_NLIN:-"$(if [[ -e /sbin/nologin     ]]; then echo "/sbin/nologin"; fi)"}"
readonly _SHEL_NLIN

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnCmdline.sh		# command line

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	fnSystem_param
#set -x
_LIST_CONF=()
	fnGet_conf_data "$1"
#printf "[%s]\n" "${_LIST_CONF[@]:-}"
#set +x
	fnDec_conf_data
#set -x
	fnNetwork_param
#set +x

_NICS_FQDN="sv-${_DIST_NAME}.workgroup"
_NICS_NAME="ens160"
_NICS_MADR="00:11:22:33:44:55"
_NICS_IPV4="192.168.1.11/24"
_NICS_GATE="192.168.1.254"
_NICS_DNS4="192.168.1.254 8.8.8.8 8.8.4.4"
_IPV6_ADDR="2000::123/3"
_LINK_ADDR="fe80::123/10"

___WORK="$(echo "${_NICS_IPV4:-}" | sed 's/[^0-9./]\+//g')"
_NICS_IPV4="$(echo "${___WORK}/" | cut -d '/' -f 1)"
_NICS_BIT4="$(echo "${___WORK}/" | cut -d '/' -f 2)"
if [ -z "${_NICS_BIT4}" ]; then
	_NICS_BIT4="$(fnIPv4Netmask "${_NICS_MASK:-"255.255.255.0"}")"
else
	_NICS_MASK="$(fnIPv4Netmask "${_NICS_BIT4:-"24"}")"
fi
_NICS_HOST="$(echo "${_NICS_FQDN}." | cut -d '.' -f 1)"
_NICS_WGRP="$(echo "${_NICS_FQDN}." | cut -d '.' -f 2)"
_NICS_HOST="$(echo "${_NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
_NICS_WGRP="$(echo "${_NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
_IPV4_UADR="${_NICS_IPV4%.*}"
_IPV4_LADR="${_NICS_IPV4#"${_IPV4_UADR:-"*"}."}"
_IPV6_CIDR="${_IPV6_ADDR##*/}"
_IPV6_ADDR="${_IPV6_ADDR%/"${_IPV6_CIDR:-"*"}"}"
_IPV6_FADR="$(fnIPv6FullAddr "${_IPV6_ADDR:-}" "true")"
_IPV6_UADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
_IPV6_LADR="$(echo "${_IPV6_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
_IPV6_RADR="$(fnIPv6RevAddr "${_IPV6_FADR:-}")"
_LINK_CIDR="${_LINK_ADDR##*/}"
_LINK_ADDR="${_LINK_ADDR%/"${_LINK_CIDR:-"*"}"}"
_LINK_FADR="$(fnIPv6FullAddr "${_LINK_ADDR:-}" "true")"
_LINK_UADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
_LINK_LADR="$(echo "${_LINK_FADR:-}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
_LINK_RADR="$(fnIPv6RevAddr "${_LINK_FADR:-}")"

if false; then
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
fi

if true; then
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
		printf "%s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
	done
fi

#fnDbgparameters_all

#	printf "%s\n" "${_LIST_CONF[@]:-}"

	fnEnc_conf_data 
	printf "%s\n" "${_LIST_CONF[@]:-}"
