#!/bin/dash

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

	# --- working directory ---------------------------------------------------
	readonly _PROG_PATH="$0"
	readonly _PROG_PARM="${*:-}"
	readonly _PROG_DIRS="${_PROG_PATH%/*}"
	readonly _PROG_NAME="${_PROG_PATH##*/}"
#	readonly _PROG_PROC="${_PROG_NAME}.$$"

	readonly _SHEL_TOPS="${_PROG_DIRS:?}"
	readonly _SHEL_COMN="${_PROG_DIRS:?}/_common_sh"
	# shellcheck source=/dev/null
	. "${_SHEL_COMN:?}"/fnGlobal_variables.sh

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnMsgout.sh							# message output

	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnFind_command.sh						# 

	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnFind_service.sh						# 

fnSetup_sudo() {
	__FUNC_NAME="fnSetup_sudo"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	__PATH="$(fnFind_command 'sudo' | sort | head -n 1)"
	if [ -z "${__PATH:-}" ]; then
		fnMsgout "skip" "[${__FUNC_NAME}]"
		return
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}

fnSetup_sudo

exit 0