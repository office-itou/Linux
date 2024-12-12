#!/bin/bash

case "${1:-}" in
	-dbg) set -x; shift;;
	-sym) set -n; shift;;
	*) ;;
esac

	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

_DTAG="filesys/debian-sid"

while read -r _SORC
do
	_FILE="${_SORC##*/}"
	_PATH="${_SORC#"${_DTAG:?}"/}"
	_DIST="${_DTAG:?}/usr/${_PATH}"
	if [[ -e "${_DIST}" ]]; then
		# --- same file -----------------------------------------------
		if [[ -f "${_SORC}" ]] && [[ -f "${_DIST}" ]]; then
			if cmp --quiet "${_SORC}" "${_DIST}"; then
				echo "skip: ${_PATH}"
				continue
			fi
			echo "diff: ${_PATH}"
		fi
		# --- source is a symbolic link -------------------------------
		if [[ -h "${_SORC}" ]]; then
			_LSRC="$(readlink -f "${_SORC}")"
			if [[ ! -e "${_DTAG}/}${_LSRC#/}" ]]; then
				echo "lost: ${_PATH}->${_LSRC}"
			fi
			if [[ "${_LSRC:0:1}" = "/" ]]; then
				echo "fadr: ${_PATH}->${_LSRC}"
			else
				echo "radr: ${_PATH}->${_LSRC}"
			fi
		fi
	fi
#	echo "copy: ${_PATH}"
#	echo mkdir -p "${_DIST%/*}"
#	echo cp -a "${_SORC}" "${_DIST}"
done < <(find "${_DTAG:?}"{/bin/,/sbin/,/lib/,/lib64/} ! -type d 2> /dev/null | sort -V || true)

exit
