#!/bin/bash

###############################################################################
#
#	mkosi finalize shell
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2026/02/28
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/02/28 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#	            : shellcheck -o all -e SC2154 *.sh
#
###############################################################################

# *** global section **********************************************************

	if [[ "${container:-}" != "mkosi" ]] && command -v mkosi-chroot > /dev/null 2>&1; then
		exec mkosi-chroot "${CHROOT_SCRIPT:?}" "$@"
		exit "$?"
	fi

	cd "${SRCDIR:?}" || exit 1

	# --- include -------------------------------------------------------------
	declare -r    _SHEL_PATH="${0:?}"
	declare -r    _SHEL_TOPS="${_SHEL_PATH%/*}"/..
	declare -r    _SHEL_COMN="${_SHEL_TOPS:-}/_common_bash"
	declare -r    _SHEL_COMD="${_SHEL_TOPS:-}/custom_cmd"
	declare -r    _SHEL_MAIN="${_SHEL_TOPS:-}/mkosi"
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN:?}"/fnMkosi_common.sh				# global variables

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnMsgout.sh						# message output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnString.sh						# string output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnStrmsg.sh						# string output with message

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparameters.sh				# print out of internal variables

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnTrap.sh						# trap
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_initialize.sh			# initialize
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_finalize_userenv.sh		# finalize user environment
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_finalize_locale.sh		# finalize locale
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_finalize_setup.sh		# finalize setup
	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_finalize_dracut.sh		# finalize dracut

# *** main section ************************************************************

	# shellcheck source=/dev/null
	source "${_SHEL_MAIN}"/fnMkosi_finalize_main.sh			# main routine

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [[ -n "${_DBGS_FLAG:-}" ]]; then
		fnDbgout "command line" \
			"debug,_COMD_LINE=[${_COMD_LINE:-}]"
	fi

	# --- start ---------------------------------------------------------------
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- main processing -----------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	exit 0

# ### eof #####################################################################
