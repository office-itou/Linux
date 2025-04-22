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
#	_time_start=$(date +%s)
#	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	mkdir -p /run/systemd/resolve
	cp /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
	# --- complete ------------------------------------------------------------
#	_time_end=$(date +%s)
#	_time_elapsed=$((_time_end-_time_start))
#	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
#	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
	exit 0

### eof #######################################################################
