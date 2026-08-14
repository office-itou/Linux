#!/bin/bash
	# --- include -------------------------------------------------------------
	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
#	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

function fnOutput_json() {
	declare -r    __PATH="${1:?}"
	declare -r    __JSON="./${__PATH##*/}.json"
	declare       __LINE=""
	declare -a    __LIST=()
	declare -a    __HEAD=()
	declare       __DATA=""
	declare       __WORK=""

	echo "start   :${__JSON}"

	__HEAD=()
	__DATA=""
	while read -r __LINE
	do
		read -r -a __LIST < <(echo "${__LINE:-}")
		if [[ -z "${__HEAD[*]}" ]]; then
			__HEAD=("${__LIST[@]}")
			__WORK=""
			for I in "${!__HEAD[@]}"
			do
				__WORK="${__WORK:+"${__WORK},"}\"${__LIST[I]}\""
			done
			__WORK="  [${__WORK}]"
			if [[ -n "${__DATA:-}" ]]; then
				__DATA="${__DATA},"$'\n'
			fi
			__DATA="${__DATA:-}${__WORK}"
			continue
		fi
		__WORK=""
		for I in "${!__HEAD[@]}"
		do
#			__WORK="${__WORK:+"${__WORK},"}\"${__HEAD[I]}\":\"${__LIST[I]}\""
			__WORK="${__WORK:+"${__WORK},"}\"${__LIST[I]}\""
		done
#		__WORK="${__WORK//%20/ }"
#		__WORK="${__WORK//\"-\"/\"\"}"
#		__WORK="  {${__WORK}}"
		__WORK="  [${__WORK}]"
		if [[ -n "${__DATA:-}" ]]; then
			__DATA="${__DATA},"$'\n'
#			__DATA="${__DATA}"$'\n'
		fi
		__DATA="${__DATA:-}${__WORK}"
	done < "${__PATH}"

	{
		printf "%s\n" "["
		printf "%s\n" "${__DATA}"
		printf "%s\n" "]"
	} > "${__JSON}"
	echo "complete:${__JSON}"
}

	fnOutput_json "./distribution.dat"	# distribution data file
	fnOutput_json "./media.dat"			# media data file
#	fnOutput_json "./work.txt"

# printf "%s\n" "$(cat distribution.dat.json | jq -r '.[-0] | @tsv')"
