#!/bin/sh

# *** initialization **********************************************************

	_COMD_LINE="$(cat /proc/cmdline)"
	for _LINE in ${_COMD_LINE:-} "${@:-}"
	do
		case "${_LINE}" in
			debug              ) _FLAG_DBGS="true"; set -x;;
			debugout|dbg|dbgout) _FLAG_DBGS="true";;
			*) ;;
		esac
	done

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
	if command -v pvs > /dev/null 2>&1; then
		for _LINE in $(pvs --noheading --separator '|' | cut -d '|' -f 1-2 | grep "${1:?}" | sort -u)
		do
			_VG_NAME="${_LINE#*\|}"
			printf "%s\n" "${0##*/}: remove vg=[${_VG_NAME}]"
			lvremove -q -y -ff "${_VG_NAME}"
		done
		for _LINE in $(pvs --noheading --separator '|' | cut -d '|' -f 1-2 | grep "${1:?}" | sort -u)
		do
			_PV_NAME="${_LINE%\|*}"
			printf "%s\n" "${0##*/}: remove pv=[${_PV_NAME}]"
			pvremove -q -y -ff "${_PV_NAME}"
		done
	fi
	dd if=/dev/zero of="/dev/${1:?}" bs=1M count=10
	if mount | grep -q '/media'; then
		umount /media || umount -l /media || true
	fi
	if command -v wireplumber > /dev/null 2>&1; then
		_PATH_CONF="/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
		mkdir -p "${_PATH_CONF%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH_CONF}"
			monitor.alsa.rules = [
			  {
			    matches = [
			      # This matches the value of the node.name property of the node.
			      {
			        node.name = "~alsa_output.*"
			      }
			    ]
			    actions = {
			      # Apply all the desired node specific settings here.
			      update-props = {
			        api.alsa.period-size   = 1024
			        api.alsa.headroom      = 8192
			        session.suspend-timeout-seconds = 0
			      }
			    }
			  }
			]
_EOT_
		for _USER in $(ps --no-headers -C wireplumber -o user)
		do
			printf "%s\n" "${0##*/}: [${_USER}]@ restart wireplumber.service"
			systemctl --user --machine="${_USER}"@ restart wireplumber.service || true
		done
	fi;
	# --- complete ------------------------------------------------------------
#	_time_end=$(date +%s)
#	_time_elapsed=$((_time_end-_time_start))
#	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
#	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
	exit 0

### eof #######################################################################
