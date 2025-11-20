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
	source "${_SHEL_COMN}"/fnString.sh						# string output
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnStrmsg.sh						# string output with message
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnTargetsys.sh					# target system state
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6FullAddr.sh				# IPv6 full address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6RevAddr.sh					# IPv6 reverse address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv4Netmask.sh					# IPv4 netmask conversion

	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnDbgdump.sh						# dump output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnDbgparam.sh					# parameter debug output
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFind_command.sh				# find command
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnFind_service.sh				# find service
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnNetwork_param.sh				# get network parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnFile_backup.sh					# file backup

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

fnNetwork_param

# shellcheck disable=SC1091
source "${_SHEL_COMD}"/fnCmdline.sh

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
	printf "%s=[%s]\n" "${__NAME}" "${!__NAME:-}"
done
