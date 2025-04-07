#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	declare    _WORK_TEXT=""
	declare    _FILE_PATH=""
	declare -a _FILE_INFO=()
	declare -a _DIST_INFO=()

	find /srv/user/share/imgs/{fedora,centos-stream,almalinux,rockylinux,miraclelinux}-* -name 'install.img' -type f | sort -V | while IFS= read -r -d $'\n' _FILE_PATH
	do
		IFS= _WORK_TEXT="$(file "${_FILE_PATH}" | sed -e 's/^\([[:graph:]]\+\):.* \([0-9]\+\) inodes,.*$/\1 \2/')"
		IFS= mapfile -d ' ' -t _FILE_INFO < <(echo -n "${_WORK_TEXT:-}")
		if [[ "${_FILE_INFO[1]}" -gt 10 ]]; then
			mount -r "${_FILE_INFO[0]}" /mnt
			IFS= _WORK_TEXT="$(awk -F '=' '$1=="NAME"||$1=="VERSION" {gsub("\"","",$2); print $2;}' /mnt/etc/os-release)"
			umount /mnt
		else
			mount -r "${_FILE_INFO[0]}" /media
			mount -r /media/LiveOS/rootfs.img /mnt
			IFS= _WORK_TEXT="$(awk -F '=' '$1=="NAME"||$1=="VERSION" {gsub("\"","",$2); print $2;}' /mnt/etc/os-release)"
			umount /mnt /media
		fi
		IFS= mapfile -d $'\n' -t _DIST_INFO < <(echo -n "${_WORK_TEXT:-}")
		_WORK_TEXT="${_FILE_PATH}"
		_WORK_TEXT="${_WORK_TEXT#*/imgs/}"
		_WORK_TEXT="${_WORK_TEXT%%/*}"
		_DIST_VERS="${_DIST_INFO[1]%% *}"
		_DIST_CODE="${_DIST_INFO[1]#* }"
		_DIST_CODE="${_DIST_CODE//[()]/}"
		printf "%-32.32s:%-16.16s:%-10.10s:%s\n" "${_WORK_TEXT}" "${_DIST_INFO[0]}" "${_DIST_VERS}" "${_DIST_CODE}"
	done
