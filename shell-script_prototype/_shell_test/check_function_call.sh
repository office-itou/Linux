#!/bin/bash

set -e
set -u
set -x

declare _FUNC_DLDR=""

# shellcheck disable=SC2317
function funcWget() {
	declare -n _RETN_STAT="$1"
	shift
	declare    _OPTN_PARM=("${@:-}")
	echo "${FUNCNAME[0]}"
	_RETN_STAT="wget"
	return 1
}

# shellcheck disable=SC2317
function funcWget2() {
	declare -n _RETN_STAT="$1"
	shift
	declare    _OPTN_PARM=("${@:-}")
	echo "${FUNCNAME[0]}"
	_RETN_STAT="wget2"
	return 0
}

# shellcheck disable=SC2317
function funcCurl() {
	declare -n _RETN_STAT="$1"
	shift
	declare    _OPTN_PARM=("${@:-}")
	echo "${FUNCNAME[0]}"
	_RETN_STAT="curl"
	return 0
}

function funcDownload() {
	declare -n _RETN_STAT="$1"
	if ! "${_FUNC_DLDR:?}" "$1"; then
		echo "error"
		return 1
	fi
	return 0
}

function funcSelectDownloader() {
	  if command -v wget2 > /dev/null 2>&1; then
		_FUNC_DLDR=""
	elif command -v wget > /dev/null 2>&1; then
		_FUNC_DLDR="funcWget"
	elif command -v curl > /dev/null 2>&1; then
		_FUNC_DLDR="funcCurl"
	else
		_FUNC_DLDR=""
	fi
}

declare _WEB_TEXT=""

funcSelectDownloader

if [[ -n "${_FUNC_DLDR:-}" ]]; then
	if funcDownload _WEB_TEXT; then
		echo "true"
	else
		echo "false"
	fi
	echo "${_WEB_TEXT}"
fi
exit
