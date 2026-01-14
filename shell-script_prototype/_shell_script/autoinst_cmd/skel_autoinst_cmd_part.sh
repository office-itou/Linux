#!/bin/sh

###############################################################################
#
#	autoinstall (part) shell script
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
#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	_DBGS_FLAG=""						# debug flag (empty: normal, else: debug)
	_DBGS_PARM="true"					# debug flag (empty: normal, else: debug out parameter)
	if [ -n "${debug:-}" ] || [ -n "${debugout:-}" ]; then
		_DBGS_FLAG="true"
		[ -n "${debug:-}" ] && set -x
		export -p
	fi

	# --- working directory ---------------------------------------------------
	readonly _PROG_PATH="$0"
	readonly _PROG_PARM="${*:-}"
	readonly _PROG_DIRS="${_PROG_PATH%/*}"
	readonly _PROG_NAME="${_PROG_PATH##*/}"
#	readonly _PROG_PROC="${_PROG_NAME}.$$"

	readonly _SHEL_PATH="${0:?}"
	readonly _SHEL_TOPS="${_SHEL_PATH%/*}"/..
	readonly _SHEL_COMN="${_SHEL_TOPS:-}/_common_sh"
	readonly _SHEL_COMD="${_SHEL_TOPS:-}/autoinst_cmd"
	# shellcheck source=/dev/null
	. "${_SHEL_COMD:?}"/fnGlobal_variables.sh				# global variables (for basic)

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnMsgout.sh							# message output
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnString.sh							# string output
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnStrmsg.sh							# string output with message
	# shellcheck source=/dev/null
#	. "${_SHEL_COMN}"/fnTargetsys.sh						# target system state
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv6FullAddr.sh						# IPv6 full address
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv6RevAddr.sh						# IPv6 reverse address
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv4Netmask.sh						# IPv4 netmask conversion

	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnDbgout.sh							# message output (debug out)
	# shellcheck source=/dev/null
#	. "${_SHEL_COMD}"/fnDbgdump.sh							# dump output (debug out)
	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnDbgparam.sh							# parameter debug output
	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnFind_command.sh						# find command
	# shellcheck source=/dev/null
#	. "${_SHEL_COMD}"/fnFind_service.sh						# find service
	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnSystem_param.sh						# get system parameter
	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnNetwork_param.sh					# get network parameter
	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnFile_backup.sh						# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnInitialize.sh						# initialize

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_BACK : read
# shellcheck disable=SC2148,SC2317,SC2329
fnMain() {
	_FUNC_NAME="fnMain"
	fnMsgout "${_PROG_NAME:-}" "start" "[${_FUNC_NAME}]"

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize
	fnDbgparam							# parameter debug output

	# --- main processing -----------------------------------------------------
	if [ ! -e /run/systemd/resolve/stub-resolv.conf ]; then
		fnMsgout "${_PROG_NAME:-}" "info" "copy /run/systemd/resolve/stub-resolv.conf"
		mkdir -p /run/systemd/resolve
		cp -v /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
	fi

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		tree --charset C -n --filesfirst "${_DIRS_BACK:-}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${_FUNC_NAME}]"
	unset _FUNC_NAME
}

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# shellcheck source=/dev/null
	. "${_SHEL_COMD}"/fnCmdline.sh		# command line

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
	unset __time_start __time_end __time_elapsed

	mkdir -p "${_PROG_PATH:?}.success"

	exit 0

# ### eof #####################################################################
