#!/bin/sh

###############################################################################
#
#	autoinstall (run) shell script
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

	# --- working directory ---------------------------------------------------
	readonly      _PROG_PATH="$0"
	readonly      _PROG_PARM="${*:-}"
#	readonly      _PROG_DIRS="${_PROG_PATH%/*}"
	readonly      _PROG_NAME="${_PROG_PATH##*/}"
#	readonly      _PROG_PROC="${_PROG_NAME}.$$"

	# --- command line parameter ----------------------------------------------
	              _COMD_LINE="$(cat /proc/cmdline || true)"	# command line parameter
	readonly      _COMD_LINE

# *** function section (common functions) *************************************

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : section (start, complete, remove, umount, failed, ...)
#   input :     $2     : message
#   input :     $3     : log file name (optional)
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
fnMsgout() {
	{
		case "${1:-}" in
			start    | complete) printf "\033[m${_PROG_NAME}: \033[92m--- %-8.8s: %s ---\033[m\n" "$1" "$2";; # info
			remove   | umount  ) printf "\033[m${_PROG_NAME}: \033[93m    %-8.8s: %s\033[m\n"     "$1" "$2";; # warn
			success            ) printf "\033[m${_PROG_NAME}: \033[92m    %-8.8s: %s\033[m\n"     "$1" "$2";; # info
			failed             ) printf "\033[m${_PROG_NAME}: \033[91m    %-8.8s: %s\033[m\n"     "$1" "$2";; # alert
			*                  ) printf "\033[m${_PROG_NAME}: \033[37m%12.12s: %s\033[m\n"        "$1" "$2";; # normal
		esac
	} | tee -a ${3:+"$3"} 1>&2
}

# *** main section ************************************************************

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- boot parameter selection --------------------------------------------
	for __LINE in ${_COMD_LINE:-} ${_PROG_PARM:-}
	do
		case "${__LINE}" in
			debug    | dbg      ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout   ) _DBGS_FLAG="true";;
			*) ;;
		esac
	done

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		fnMsgout "debug" "start: _COMD_LINE"
		printf "%s\n" "${_COMD_LINE:-}"
		fnMsgout "debug" "end  : _COMD_LINE"
	fi

	# --- main processing -----------------------------------------------------
	/bin/kill-all-dhcp
	/bin/netcfg

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################