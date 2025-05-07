#!/bin/bash

set -eu
#set -x

# --- get volume id -----------------------------------------------------------
# shellcheck disable=SC2317
function funcGetVolID() {
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	if [[ -n "${1:-}" ]] && [[ -s "${1:?}" ]]; then
	case "${_FLAG}" in
		b)
			_VLID="$(LANG=C blkid -s LABEL -o value "$1")"
			;;
		s)
			_VLID="$(LANG=C file -L "$1")"
			_VLID="$(echo -n "${_VLID}" | sed -e 's/^.*'\''\(.*\)'\''.*$/\1/')"
			;;
		*)
			_VLID="$(LANG=C file -L "$1")"
			_VLID="${_VLID#*: }"
			_WORK="${_VLID%%\'*}"
			_VLID="${_VLID#"${_WORK}"}"
			_WORK="${_VLID##*\'}"
			_VLID="${_VLID%"${_WORK}"}"
			;;
	esac
	fi
	echo -n "${_VLID}"
}

# --- get file information ----------------------------------------------------
# shellcheck disable=SC2317
function funcGetFileinfo() {
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	# -------------------------------------------------------------------------
	_ARRY=()
	if [[ -n "${1:-}" ]] && [[ -s "${1:?}" ]]; then
		_WORK="$(realpath -s "$1")"		# full path
		_FNAM="${_WORK##*/}"
		_DIRS="${_WORK%"${_FNAM}"}"
		_WORK="$(LANG=C find "${_DIRS:-.}" -name "${_FNAM}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS+%TZ %s")"
		if [[ -n "${_WORK}" ]]; then
			read -r -a _ARRY < <(echo "${_WORK}")
#			_ARRY[0]					# full path
#			_ARRY[1]					# time stamp
#			_ARRY[2]					# size
			_VLID="$(set -e; funcGetVolID "${_ARRY[0]}")"
			_VLID="${_VLID#\'}"
			_VLID="${_VLID%\'}"
			_VLID="${_VLID:--}"
			_ARRY+=("${_VLID// /%20}")	# volume id
		fi
	fi
	echo -n "${_ARRY[*]}"
}

sync
echo 3 > /proc/sys/vm/drop_caches
free

declare       _WORK=""				# work variables
declare -a    _ARRY=()				# work variables

_CODE_ESCP="$(printf '\033')"

_FLAG="$1"
shift

_time_start=$(date +%s)
printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

while read -r F
do
	_WORK="$(set -e; funcGetFileinfo "${F}")"
	if [[ -z "${_WORK}" ]]; then
		continue
	fi
	read -r -a _ARRY < <(echo "${_WORK}")
	_ARRY=("${_ARRY[@]//%20/ }")
	printf "%-43.43s %-19.19s %12d [%s]\n" "${_ARRY[0]##*/}" "${_ARRY[1]%.*}" "${_ARRY[2]}" "${_ARRY[3]}"
done < <(printf "%s\n" "$@")

_time_end=$(date +%s)
_time_elapsed=$((_time_end-_time_start))

printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))

sync
echo 3 > /proc/sys/vm/drop_caches
free
