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
	_LV_PATH="${1:?}"					# Logical Volume path
	_DV_NAME="${2:?}"					# Device name
	lvremove --select "${_LV_PATH:?}" -ff -y
	vgremove --select "${_LV_PATH:?}" -ff -y
	pvremove /dev/"${_DV_NAME:?}"* -ff -y
	dd if=/dev/zero of=/dev/"${_DV_NAME:?}" bs=1M count=10
	umount /media || umount -l /media || true
	if [ ! -e /run/systemd/resolve/stub-resolv.conf ]; then
		mkdir -p /run/systemd/resolve
		cp /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
	fi
	# --- complete ------------------------------------------------------------
#	_time_end=$(date +%s)
#	_time_elapsed=$((_time_end-_time_start))
#	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
#	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
	exit 0

### eof #######################################################################
