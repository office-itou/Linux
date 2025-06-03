# === <web_tools> =============================================================

# -----------------------------------------------------------------------------
# descript: get web contents
#   input :   $1   : output path
#   input :   $2   : url
#   output: stdout : message
#   return:        : status
# shellcheck disable=SC2317
function fnGetWeb_contents() {
	fnDebugout ""
	declare -a    __OPTN=()				# options
	declare -i    __RTCD=0				# return code
	declare -a    __LIST=()				# data list
	declare       __TEMP=""				# temporary file
	              __TEMP="$(mktemp -q "${TMPDIR:-/tmp}/${1##*/}.XXXXXX")"
	readonly      __TEMP
	# -------------------------------------------------------------------------
	__RTCD=0
	if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
		__OPTN=("${_OPTN_WGET[@]}" "--continue" "--show-progress" "--progress=bar" "--output-document=${__TEMP:?}" "${2:?}")
		LANG=C wget "${__OPTN[@]}" 2>&1 || __RTCD="$?"
	else
		__OPTN=("${_OPTN_CURL[@]}" "--progress-bar" "--continue-at" "-" "--create-dirs" "--output-dir" "${__TEMP%/*}" --output "${__TEMP##*/}" "${2:?}")
		LANG=C curl "${__OPTN[@]}" 2>&1 || __RTCD="$?"
	fi
	# -------------------------------------------------------------------------
	if [[ "${__RTCD}" -eq 0 ]]; then
		mkdir -p "${1%/*}"
		if [[ ! -s "$1" ]]; then
			: > "$1"
		fi
		if ! cp --preserve=timestamps "${__TEMP}" "$1"; then
			printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[41m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "error [cp]" "${1##*/}"
		else
			IFS= mapfile -d ' ' -t __LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "$1" || true)
			printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "complete" "${1##*/} (${__LIST[4]})"
		fi
	fi
	# -------------------------------------------------------------------------
	rm -f "${__TEMP:?}"
	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web header
#   n-ref :   $1   : return value : path tmstamp size status contents
#   input :   $2   : url
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_header() {
	fnDebugout ""
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -a    __OPTN=()				# options
#	declare -i    __RTCD=0				# return code
	declare       __RSLT=""				# result
	declare       __FILD=""				# field name
	declare       __VALU=""				# value
	declare       __CODE=""				# status codes
	declare       __LENG=""				# content-length
	declare       __LMOD=""				# last-modified
	declare -a    __LIST=()				# work variables
	declare       __LINE=""				# work variables
	declare -i    I=0					# work variables
	# -------------------------------------------------------------------------
#	__RTCD=0
	__RSLT=""
	if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
		__OPTN=("${_OPTN_WGET[@]}" "--spider" "--server-response" "--output-document=-" "${2:?}")
		__RSLT="$(LANG=C wget "${__OPTN[@]}" 2>&1 || true)"
	else
		__OPTN=("${_OPTN_CURL[@]}" "--header" "${2:?}")
		__RSLT="$(LANG=C curl "${__OPTN[@]}" 2>&1 || true)"
	fi
	if [[ -n "${_DBGS_LOGS}" ]]; then
		{
			echo "### ${FUNCNAME[0]} ###"
			echo "URL=[${2:-}]"
			echo "${__RSLT}"
		} >> "${_DBGS_LOGS}"
	fi
	# -------------------------------------------------------------------------
	__RSLT="${__RSLT//$'\r\n'/$'\n'}"	# crlf -> lf
	__RSLT="${__RSLT//$'\r'/$'\n'}"		# cr   -> lf
	__RSLT="${__RSLT//></>\n<}"
	__RSLT="${__RSLT#"${__RSLT%%[!"${IFS}"]*}"}"	# ltrim
	__RSLT="${__RSLT%"${__RSLT##*[!"${IFS}"]}"}"	# rtrim
	IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
	for I in "${!__LIST[@]}"
	do
		__LINE="${__LIST[I],,}"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__FILD="${__LINE%% *}"
		__VALU="${__LINE#* }"
		case "${__FILD%% *}" in
			http/*         ) __CODE="${__VALU%% *}";;
			content-length:) __LENG="${__VALU}";;
			last-modified: ) __LMOD="$(TZ=UTC date -d "${__VALU}" "+%Y-%m-%d%%20%H:%M:%S%z")";;
			*              ) ;;
		esac
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${2// /%20} ${__LMOD:--} ${__LENG:--} ${__CODE:--} ${__RSLT// /%20}"
#	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web address completion
#   n-ref :   $1   : return value : address completion path
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_address() {
	fnDebugout ""
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare -r    __PATN='?*[]'			# web file regexp
	declare       __MATC=""				# web file regexp match
	declare -a    __OPTN=()				# options
#	declare -i    __RTCD=0				# return code
	declare       __RSLT=""				# result
	declare       __FILD=""				# field name
	declare       __VALU=""				# value
	declare       __CODE=""				# status codes
	declare       __LENG=""				# content-length
	declare       __LMOD=""				# last-modified
	declare -i    __RTRY=3				# retry count
	declare -a    __LIST=()				# work variables
	declare       __LINE=""				# work variables
	declare -i    I=0					# work variables
	# --- URL completion ------------------------------------------------------
	__PATH="${2:?}"
	while [[ -n "${__PATH//[!"${__PATN}"]/}" ]]
	do
		__DIRS="${__PATH%%["${__PATN}"]*}"	# directory
		__DIRS="${__DIRS%/*}"
		__MATC="${__PATH#"${__DIRS}"/}"	# match
		__MATC="${__MATC%%/*}"
		__FNAM="${__PATH#*"${__MATC}"}"	# file name
		__FNAM="${__FNAM#*/}"
		__PATH="${__DIRS}"
		# ---------------------------------------------------------------------
		while [[ "${__RTRY}" -gt 0 ]]
		do
			((__RTRY--))
#			__RTCD=0
			__RSLT=""
			if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
				__OPTN=("${_OPTN_WGET[@]}" "--server-response" "--output-document=-" "${__PATH:?}")
				__RSLT="$(LANG=C wget "${__OPTN[@]}" 2>&1 || true)"
			else
				__OPTN=("${_OPTN_CURL[@]}" "--header" "${__PATH:?}")
				__RSLT="$(LANG=C curl "${__OPTN[@]}" 2>&1 || true)"
			fi
			if [[ -n "${_DBGS_LOGS}" ]]; then
				{
					echo "### ${FUNCNAME[0]} ###"
					echo "URL=[${__PATH:-}]"
					echo "${__RSLT}"
				} >> "${_DBGS_LOGS}"
			fi
			if [[ -z "${__RSLT:-}" ]]; then
				continue
			fi
			# -----------------------------------------------------------------
			__RSLT="${__RSLT//$'\r\n'/$'\n'}"	# crlf -> lf
			__RSLT="${__RSLT//$'\r'/$'\n'}"		# cr   -> lf
			__RSLT="${__RSLT//></>\n<}"
			__RSLT="${__RSLT#"${__RSLT%%[!"${IFS}"]*}"}"	# ltrim
			__RSLT="${__RSLT%"${__RSLT##*[!"${IFS}"]}"}"	# rtrim
			IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
			__CODE=""
			__LENG=""
			__LMOD=""
			for I in "${!__LIST[@]}"
			do
				__LINE="${__LIST[I],,}"
				__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
				__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
				__FILD="${__LINE%% *}"
				__FILD="${__FILD%% *}"
				__VALU="${__LINE#* }"
				case "${__FILD,,}" in
					http/*         ) __CODE="${__VALU%% *}";;
					content-length:) __LENG="${__VALU}";;
					last-modified: ) __LMOD="$(TZ=UTC date -d "${__VALU}" "+%Y-%m-%d%%20%H:%M:%S%z")";;
					*              ) ;;
				esac
			done
			# -----------------------------------------------------------------
			case "${__CODE}" in				# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
				1??) ;;						# 1xx (Informational)
				2??)						# 2xx (Successful)
					IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__RSLT}")
					__PATH="$(printf "%s\n" "${__LIST[@]//%20/ }" | sed -ne 's%^.*<a href="'"${__MATC}"'/*">\(.*\)</a>.*$%\1%gp' | sort -rVu | head -n 1 || true)"
					__PATH="${__PATH:+"${__DIRS%%/}/${__PATH%%/}${__FNAM:+/"${__FNAM##/}"}"}"
					;;
				3??) ;;						# 3xx (Redirection)
				4??) ;;						# 4xx (Client Error)
				5??) ;;						# 5xx (Server Error)
				*  ) ;;						# xxx (Unknown Code)
			esac
			break
		done
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${__PATH}"
#	return "${__RTCD}"
}

# -----------------------------------------------------------------------------
# descript: get web information
#   n-ref :   $1   : return value : path tmstamp size status contents
#   input :   $2   : url
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_info() {
	fnDebugout ""
#	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __WORK=""				# work variables

	fnGetWeb_address "__WORK" "${2:?}"
	fnGetWeb_header "${1}" "${__WORK}"
}

# -----------------------------------------------------------------------------
# descript: get web status message
#   input :   $1   : input vale
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnGetWeb_status() {
	fnDebugout ""
	case "${1:?}" in					# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
		100) echo -n "$1: Continue";;
		101) echo -n "$1: Switching Protocols";;
		1??) echo -n "$1: (Informational): The request was received, continuing process";;
		200) echo -n "$1: OK";;
		201) echo -n "$1: Created";;
		202) echo -n "$1: Accepted";;
		203) echo -n "$1: Non-Authoritative Information";;
		204) echo -n "$1: No Content";;
		205) echo -n "$1: Reset Content";;
		206) echo -n "$1: Partial Content";;
		2??) echo -n "$1: (Successful): The request was successfully received, understood, and accepted";;
		300) echo -n "$1: Multiple Choices";;
		301) echo -n "$1: Moved Permanently";;
		302) echo -n "$1: Found";;
		303) echo -n "$1: See Other";;
		304) echo -n "$1: Not Modified";;
		305) echo -n "$1: Use Proxy";;
		306) echo -n "$1: (Unused)";;
		307) echo -n "$1: Temporary Redirect";;
		308) echo -n "$1: Permanent Redirect";;
		3??) echo -n "$1: (Redirection): Further action needs to be taken in order to complete the request";;
		400) echo -n "$1: Bad Request";;
		401) echo -n "$1: Unauthorized";;
		402) echo -n "$1: Payment Required";;
		403) echo -n "$1: Forbidden";;
		404) echo -n "$1: Not Found";;
		405) echo -n "$1: Method Not Allowed";;
		406) echo -n "$1: Not Acceptable";;
		407) echo -n "$1: Proxy Authentication Required";;
		408) echo -n "$1: Request Timeout";;
		409) echo -n "$1: Conflict";;
		410) echo -n "$1: Gone";;
		411) echo -n "$1: Length Required";;
		412) echo -n "$1: Precondition Failed";;
		413) echo -n "$1: Content Too Large";;
		414) echo -n "$1: URI Too Long";;
		415) echo -n "$1: Unsupported Media Type";;
		416) echo -n "$1: Range Not Satisfiable";;
		417) echo -n "$1: Expectation Failed";;
		418) echo -n "$1: (Unused)";;
		421) echo -n "$1: Misdirected Request";;
		422) echo -n "$1: Unprocessable Content";;
		426) echo -n "$1: Upgrade Required";;
		4??) echo -n "$1: (Client Error): The request contains bad syntax or cannot be fulfilled";;
		500) echo -n "$1: Internal Server Error";;
		501) echo -n "$1: Not Implemented";;
		502) echo -n "$1: Bad Gateway";;
		503) echo -n "$1: Service Unavailable";;
		504) echo -n "$1: Gateway Timeout";;
		505) echo -n "$1: HTTP Version Not Supported";;
		5??) echo -n "$1: (Server Error): The server failed to fulfill an apparently valid request";;
		*  ) echo -n "$1: (Unknown Code)";;
	esac
}
