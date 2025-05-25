#!/bin/bash

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

function fnLtrim() {
	echo -n "${1#"${1%%[!"${IFS}"]*}"}"	# ltrim
}

function fnRtrim() {
	echo -n "${1%"${1##*[!"${IFS}"]}"}"	# rtrim
}

function fnTrim() {
	declare       __WORK=""
	__WORK="$(fnLtrim "$1")"
	fnRtrim "${__WORK}"
}

function fnString() {
	echo "" | IFS= awk '{s=sprintf("%'"${1:?}"'s",""); gsub(" ","'"${2:-\" \"}"'",s); print s;}'
}

function fnCenter() {
	declare -r -i __SIZE="${1:?}"
	declare       __TEXT="${2:?}"
	declare -i    __LEFT=0
	declare -i    __RIGT=0
	declare       __WORK=""
	__TEXT="$(fnTrim "${__TEXT}")"
	__LEFT=$(((__SIZE - "${#__TEXT}") / 2))
	__RIGT=$((__SIZE - "${__LEFT}" - "${#__TEXT}"))
	printf "%${__LEFT}s%-s%${__RIGT}s" "" "${__TEXT}" ""
}

function fnTableHeader() {
	declare -a    __ARRY=()
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/{' -e 's/^ *//g' -e 's/^ \+$//g}'
		  
		### **$1**  
		  
_EOT_
	__ARRY=()
	__ARRY+=("$(fnCenter  "97" "shell file name")")
	__ARRY+=("$(fnCenter "117" "function name")")
	__ARRY+=("$(fnCenter  "77" "explanation")")
	printf "| %-97s | %-117s | %-77s |\n" "${__ARRY[@]}"
	__ARRY=()
	__ARRY+=(":$(fnString "$(( 97-1))" "-")")
	__ARRY+=(":$(fnString "$((117-1))" "-")")
	__ARRY+=(":$(fnString "$(( 77-1))" "-")")
	printf "| %-97s | %-117s | %-77s |\n" "${__ARRY[@]}"
}

declare -a    __TBLE=()
declare -a    __DTAL=()
declare       __TYPE=""

IFS= mapfile -d $'\n' -t __TBLE < <(
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/{' -e 's/^ *//g' -e 's/^ \+$//g}' || true
		# **function**  
		  
		## **list of functions**  
_EOT_
)

IFS= mapfile -d $'\n' -t __DTAL < <(
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/{' -e 's/^ *//g' -e 's/^ \+$//g}' || true
		## **explanation**  
_EOT_
)

__FILE=""
__SAME=""
__DTAL=()
while read -r __PATH
do
	if [[ "${__FILE:-}" != "${__PATH##*/}" ]]; then
		__FILE="${__PATH##*/}"
		IFS= mapfile -d $'\n' -t __ARRY < <(
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/{' -e 's/^ *//g' -e 's/^ \+$//g}' || true
				  
				* * *
				  
				### **${__FILE}**  
_EOT_
		)
		__DTAL+=("${__ARRY[@]}")
		__SAME=""
	fi
#	__FILE="${__PATH##*/}"
	case "${__FILE}" in
		skel_*)
			if [[ "${__TYPE}" != "skeleton" ]]; then
				__TYPE="skeleton"
				__WORK="$(fnTableHeader "${__TYPE}")"
				IFS= mapfile -d $'\n' -t __ARRY < <(echo -n "${__WORK}")
				__TBLE+=("${__ARRY[@]}")
			fi
			;;
		tmpl_*)
			if [[ "${__TYPE}" != "template" ]]; then
				__TYPE="template"
				__WORK="$(fnTableHeader "${__TYPE}")"
				IFS= mapfile -d $'\n' -t __ARRY < <(echo -n "${__WORK}")
				__TBLE+=("${__ARRY[@]}")
			fi
			;;
		*     ) ;;
	esac
	__FUNC=""
	__LIST=()
	while read -r __LINE
	do
		if ! echo -n "${__LINE}" | grep -qE '^(#.*:|function)'; then
			continue
		fi
		__WORK="${__LINE#\#}"
		__WORK="${__WORK#"${__WORK%%[!"${IFS}"]*}"}"	# ltrim
		__WORK="${__WORK%%:*}"
		__WORK="${__WORK%% *}"
		case ".${__WORK:-}" in
			.\"      | \
			.descript| \
			.n-ref   | \
			.input   | \
			.output  | \
			.return  )
				__LIST+=("${__LINE}")
				;;
			.function)
				__FUNC="${__LINE#function }"
				__FUNC="${__FUNC%%(*}"
				__FUNC="${__FUNC%% *}"
				printf "%-50s: %-s\n" "${__FILE}" "${__FUNC}"
				# -------------------------------------------------------------
				__OPTN=()
				__TAIL=()
				for I in "${!__LIST[@]}"
				do
					IFS= mapfile -d ':' -t __ARRY < <(echo -n "${__LIST[I]#\#}")
					if echo -n "${__ARRY[*]}" | grep -q "descript"; then
						continue
					fi
					__ARRY[0]="${__ARRY[0]:+"$( fnTrim "${__ARRY[0]}")"}"
					__ARRY[1]="${__ARRY[1]:+"$( fnTrim "${__ARRY[1]}")"}"
					__ARRY[2]="${__ARRY[2]:+"$( fnTrim "${__ARRY[2]}")"}"
					__ARRY[3]="${__ARRY[3]:+"$(fnRtrim "${__ARRY[3]# }")"}"
					__WORK="$(printf "| %-6s | %-6s | %-22s | %-42s |" "${__ARRY[@]}")"
					case "${__ARRY[1]}" in
						\$*) __OPTN+=("${__ARRY[1]}");;
						*  ) ;;
					esac
					__TAIL+=("${__WORK}")
				done
				# -------------------------------------------------------------
				__WORK=""
				if [[ -n "${__OPTN[*]}" ]]; then
					__WORK="$(printf '"%s" \n' "${__OPTN[@]}")"
					__WORK="${__WORK//$'\n'/}"
					__WORK="${__WORK%% }"
					__WORK="${__WORK//\$/\\\$}"
				fi
				__TEXT="$(printf "%s\n" "${__LIST[@]}" | sed -ne 's/^#[ \t]*descript:[ \t]*\(.*\)$/\1/p')"
				__LINK="$(echo -n "${__TEXT,,}" | awk -F '' '{gsub(/[\!\@\#\$\%\^\&\*\(\)\+\|\~\=\\\`\[\]\{\}\;'\''\:\"\,\.\/\<\>\?]/,""); print;}')"
				__LINK="${__LINK// /-}"
				if [[ -z "${__LINK}" ]]; then
					__LINK="${__FUNC}"
				else
					__LINK="[${__FUNC}](#${__LINK})${__WORK:+" ${__WORK}"}"
				fi
				if [[ -z "${__SAME:-}" ]]; then
					__TBLE+=("$(printf "| %-97s | %-117s | %-77s |" "[${__FILE}](./${__FILE})" "${__LINK}" "${__TEXT}")")
					__SAME="true"
				else
					__TBLE+=("$(printf "| %-97s | %-117s | %-77s |" "" "${__LINK}" "${__TEXT}")")
				fi
				IFS= mapfile -d $'\n' -t __ARRY < <(
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/{' -e 's/^ *//g' -e 's/^ \+$//g}' || true
						  
						* * *
						  
						#### ${__TEXT:-"no items"}  
						  
						*${__FUNC}${__WORK:+" ${__WORK}"}*  
						  
_EOT_
				)
				__DTAL+=("${__ARRY[@]}")
				__ARRY=()
				__ARRY+=("$(fnCenter "6" "i/o")")
				__ARRY+=("$(fnCenter "6" "value")")
				__ARRY+=("$(fnCenter "22" "explanation")")
				__ARRY+=("$(fnCenter "42" "note")")
				__WORK="$(printf "| %-6s | %-6s | %-22s | %-42s |" "${__ARRY[@]}")"
				__DTAL+=("${__WORK}")
				__ARRY=()
				__ARRY+=(":$(fnString "$((6-2))" "-"):")
				__ARRY+=(":$(fnString "$((6-2))" "-"):")
				__ARRY+=(":$(fnString "$((22-1))" "-")")
				__ARRY+=(":$(fnString "$((42-1))" "-")")
				__WORK="$(printf "| %-6s | %-6s | %-22s | %-42s |" "${__ARRY[@]}")"
				__DTAL+=("${__WORK}")
				__DTAL+=("${__TAIL[@]}")
#				__DTAL+=("  ")
				__LIST=()
				;;
			*)
				continue
				;;
		esac
	done < "${__PATH}"
	if [[ -z "${__FUNC}" ]] ;then
		if [[ -z "${__SAME:-}" ]]; then
			__TBLE+=("$(printf "| %-97s | %-117s | %-77s |\n" "[${__FILE}](./${__FILE})" "" "")")
			__SAME="true"
		else
			__TBLE+=("$(printf "| %-97s | %-117s | %-77s |\n" "" "" "")")
		fi
	fi
done < <(find "${1:?}" -maxdepth 1 \( -name 'skel_*.sh' -o -name 'tmpl_*.sh' \) -type f | sort -V || true)

{
	printf "%s\n" "${__TBLE[@]}"
	printf "%s\n" "${__DTAL[@]}"
} > "${2:?}"
