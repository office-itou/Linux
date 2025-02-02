#!/bin/sh

# *** initialization **********************************************************

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
	trap 'exit 1' 1 2 3 15
	export LANG=C

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

# *** main processing section *************************************************
	# --- start ---------------------------------------------------------------
#	_start_time=$(date +%s)
#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
	# --- main ----------------------------------------------------------------
	/bin/kill-all-dhcp
	/bin/netcfg
	# --- complete ------------------------------------------------------------
#	_end_time=$(date +%s)
#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
#	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
	exit 0

### eof #######################################################################
