# === <interface> =============================================================

# -----------------------------------------------------------------------------
# descript: print out of menu
#   n-ref :   $1   : return value : options
#   input :   $2   : command type
#   input :   $3   : target range
#   input :   $@   : target data
#   output: stdout : message
#   return:        : unused
function fnPrint_menu() {
	declare -n    __RETN_VALU="$1"		# return value
	declare -r    __COMD_TYPE="$2"		# command type
	declare -r    __TGET_RANG="$3"		# target range
	declare -a    __TGET_LIST=("${@:4}") # target data
	declare       __RANG=""				# range
	declare -i    __IDNO=0				# id number (1..)
	declare       __CLR0=""				# message color (line)
	declare       __CLR1=""				# message color (word)
	declare       __MESG=""				# message text
	declare       __RETN=""				# return value
#	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __BASE=""				# base name
	declare       __EXTN=""				# extension
	declare       __SEED=""				# preseed
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    J=0					# work variables

	case "${__TGET_RANG,,}" in
		a|all) __RANG="$(eval "echo {1..${#__TGET_LIST[@]}}")";;
		*    ) __RANG="${__TGET_RANG}";;
	esac
	for I in "${!__TGET_LIST[@]}"
	do
		read -r -a __LIST < <(echo "${__TGET_LIST[I]}")
#		__LIST=("${__LIST[@]##-}")
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]##-}"		# empty
#			__LIST[J]="${__LIST[J]//%20/ }"	# space
		done
		case "${__COMD_TYPE}" in
			list)
				case "${__LIST[1]:--}" in
					m) continue;;
					*) ;;
				esac
				;;
			*)
				case "${__LIST[1]:--}" in
					o) ;;
					m)
						printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "# ${_TEXT_GAP1:1:((${#_TEXT_GAP1}-4))} #" 1>&2
						case "${__LIST[3]:--}" in
							-) ;;
							*)
								__IDNO=0
								printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}#%-2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((${_SIZE_COLS:-80}-70)).$((${_SIZE_COLS:-80}-70))s${_CODE_ESCP:+"${_CODE_ESCP}[m"}#\n" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo" 1>&2
								;;
						esac
						continue
						;;
					*) continue;;
				esac
				if [[ -z "${__LIST[3]}" ]]; then
					continue
				fi
				if [[ -z "${__LIST[13]}" ]]; then
					continue
				fi
				;;
		esac
		((++__IDNO))
		if ! echo "${__IDNO}" | grep -qE '^('"${__RANG[*]// /\|}"')$'; then
			continue
		fi
		# --- web original iso file -------------------------------------------
		__RETN=""
		__MESG=""											# contents
		if [[ -n "${__LIST[8]}" ]]; then
			fnGetWeb_info "__RETN" "${__LIST[8]}"			# web_regexp
			read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
			__ARRY=("${__ARRY[@]##-}")
			case "${__ARRY[3]}" in
				200)
					__LIST[9]="${__ARRY[0]:-}"				# web_path
					__LIST[10]="${__ARRY[1]:-}"				# web_tstamp
					__LIST[11]="${__ARRY[2]:-}"				# web_size
					__LIST[12]="${__ARRY[3]:-}"				# web_status
					case "${__LIST[9]##*/}" in
						mini.iso) ;;
						*       )
							__FNAM="${__LIST[9]##*/}"
							__WORK="${__FNAM%.*}"
							__EXTN="${__FNAM#"${__WORK}"}"
							__BASE="${__FNAM%"${__EXTN}"}"
															# iso_path
							__LIST[13]="${__LIST[13]%/*}/${__FNAM}"
															# rmk_path
							if [[ -n "${__LIST[17]##-}" ]]; then
								__SEED="${__LIST[17]##*_}"
								__WORK="${__SEED%.*}"
								__WORK="${__SEED#"${__WORK}"}"
								__SEED="${__SEED%"${__WORK}"}"
								__LIST[17]="${__LIST[17]%/*}/${__BASE}${__SEED:+"_${__SEED}"}${__EXTN}"
							fi
							;;
					esac
					;;
				*) ;;
			esac
			__MESG="${__ARRY[4]:--}"		# contents
		fi
		# --- local original iso file -----------------------------------------
		if [[ -n "${__LIST[13]}" ]]; then
			fnGetFileinfo __RETN "${__LIST[13]}"			# iso_path
			read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
			__ARRY=("${__ARRY[@]##-}")
#			__LIST[13]="${__ARRY[0]:-}"						# iso_path
			__LIST[14]="${__ARRY[1]:-}"						# iso_tstamp
			__LIST[15]="${__ARRY[2]:-}"						# iso_size
			__LIST[16]="${__ARRY[3]:-}"						# iso_volume
		fi
		# --- local remastering iso file --------------------------------------
		if [[ -n "${__LIST[17]}" ]]; then
			fnGetFileinfo __RETN "${__LIST[17]}"			# rmk_path
			read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
			__ARRY=("${__ARRY[@]##-}")
#			__LIST[17]="${__ARRY[0]:-}"						# rmk_path
			__LIST[18]="${__ARRY[1]:-}"						# rmk_tstamp
			__LIST[19]="${__ARRY[2]:-}"						# rmk_size
			__LIST[20]="${__ARRY[3]:-}"						# rmk_volume
		fi
		# --- config file  ----------------------------------------------------
		if [[ -n "${__LIST[23]}" ]]; then
			if [[ -d "${__LIST[23]}" ]]; then				# cfg_path: cloud-init
				fnGetFileinfo __RETN "${__LIST[23]}/user-data"
			else											# cfg_path
				fnGetFileinfo __RETN "${__LIST[23]}"
			fi
			read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
#			__LIST[23]="${__ARRY[0]:-}"						# cfg_path
			__LIST[24]="${__ARRY[1]:-}"						# cfg_tstamp
		fi
		# --- print out -------------------------------------------------------
		# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
		# 1xx (Informational): The request was received, continuing process
		# 2xx (Successful)   : The request was successfully received, understood, and accepted
		# 3xx (Redirection)  : Further action needs to be taken in order to complete the request
		# 4xx (Client Error) : The request contains bad syntax or cannot be fulfilled
		# 5xx (Server Error) : The server failed to fulfill an apparently valid request
		__MESG=""
		__CLR0=""
		__CLR1=""
		if [[ -z "${__LIST[8]##-}" ]] && [[ -z "${__LIST[14]##-}" ]]; then
			__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[33m"}"		# unreleased
		elif [[ -z "${__LIST[14]##-}" ]]; then
			__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[46m"}"		# new file
		else
			if [[ -n "${__LIST[18]##-}" ]]; then
				__WORK="$(fnDateDiff "${__LIST[18]}" "${__LIST[14]}")"
				if [[ "${__WORK}" -gt 0 ]]; then
					__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}"	# remaster < local
				fi
			fi
			if [[ -n "${__LIST[10]##-}" ]]; then
				__WORK="$(fnDateDiff "${__LIST[10]}" "${__LIST[14]}")"
				if [[ "${__WORK}" -lt 0 ]]; then
					__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[92m"}"	# web > local
				fi
			fi
		fi
		case "${__LIST[12]:--}" in
			-  ) ;;
			200) ;;
			1??) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			2??) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			3??) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			4??) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
			5??) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
			*  ) __MESG="$(set -e; fnGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
		esac
		__MESG="${__MESG//%20/ }"
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}#${__CLR0}%2d:%-42.42s:%-10.10s:%-10.10s:${__CLR1}%-$((_SIZE_COLS-70)).$((_SIZE_COLS-70))s${_CODE_ESCP:+"${_CODE_ESCP}[m"}#\n" "${__IDNO}" "${__LIST[13]##*/}" "${__LIST[10]:+"${__LIST[10]::10}"}${__LIST[14]:-"${__LIST[6]::10}"}" "${__LIST[7]::10}" "${__MESG:-"${__LIST[23]##*/}"}" 1>&2
#		((__IDNO+=1))
		# --- update media data record ----------------------------------------
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]:--}"		# empty
			__LIST[J]="${__LIST[J]// /%20}"	# space
		done
		__WORK="$( \
			printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-85s %-47s %-15s %-43s %-85s %-47s %-15s %-43s %-85s %-85s %-85s %-47s %-85s" \
				"${__LIST[@]}" \
		)"
		__TGET_LIST[I]="${__WORK}"
	done
	__RETN_VALU="$(printf "%s\n" "${__TGET_LIST[@]}")"
}
