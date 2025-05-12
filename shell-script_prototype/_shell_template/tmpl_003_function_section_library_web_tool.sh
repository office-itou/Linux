# === <web_tools> =============================================================

# --- get web command ---------------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_command() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r -a __OPTN_WEBS=("${@:2}") # web file path
	declare -i    __RTCD=0				# return code
	declare       __PATH=""				# full path
	declare       __LMOD=""				# last-modified
	declare       __LENG=""				# content-length
	declare       __CODE=""				# status codes
	declare       __RSLT=""				# result
	declare       __FILD=""				# field name
	declare       __VALU=""				# value
	declare       __LINE=""				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    R=2					# retry
	# -------------------------------------------------------------------------
	__PATH=""
	for I in "${!__OPTN_WEBS[@]}"
	do
		__LINE="${__OPTN_WEBS[I]}"
		case "${__LINE%%://*}" in
			dict|file|ftp|ftps|gopher|gophers|http|https|imap|imaps|ldap|ldaps|mqtt|pop3|pop3s|rtmp|rtmps|rtsp|scp|sftp|smb|smbs|smtp|smtps|telnet|tftp|ws|wss)
				__PATH+="${__PATH:+,}${__LINE}";;
			*) ;;
		esac
	done
	# -------------------------------------------------------------------------
	__LENG=""
	__LMOD=""
	for ((; R>=0; R--))
	do
		if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
			__RSLT="$(LANG=C wget "${_OPTN_WGET[@]:-}" "${__OPTN_WEBS[@]}" 2>&1 || true)"
			__RTCD="$?"
		else
			__RSLT="$(LANG=C curl "${_OPTN_CURL[@]:-}" "${__OPTN_WEBS[@]}" 2>&1 || true)"
			__RTCD="$?"
		fi
		__RSLT="${__RSLT//$'\r\n'/$'\n'}"	# crlf -> lf
		__RSLT="${__RSLT//$'\r'/$'\n'}"		# cr   -> lf
		__RSLT="${__RSLT//></>\n<}"
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
		case "${__CODE}" in				# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			1??) break;;				# 1xx (Informational): The request was received, continuing process
			2??) break;;				# 2xx (Successful)   : The request was successfully received, understood, and accepted
			3??) break;;				# 3xx (Redirection)  : Further action needs to be taken in order to complete the request
			4??) break;;				# 4xx (Client Error) : The request contains bad syntax or cannot be fulfilled
			5??) break;;				# 5xx (Server Error) : The server failed to fulfill an apparently valid request
			*  ) ;;						#      Unknown Error
		esac
		__RSLT="retry error: [${__PATH}]"
		sleep 3
	done
	# -------------------------------------------------------------------------
	__RETN_VALU="${__PATH// /%20} ${__LMOD:--} ${__LENG:--} ${__CODE:--} ${__RSLT// /%20}"
}

# --- get web information -----------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_info_direct() {
#	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r    __PATH_WEBS="${2:?}"	# web file path
	declare -a    __OPTN=()				# options
	declare       __PATH=""				# full path
	# -------------------------------------------------------------------------
	__PATH="${__PATH_WEBS}"
	if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
		__OPTN=("--spider" "--server-response" "--output-document=-" "${__PATH}")
	else
		__OPTN=("--header" "${__PATH}")
	fi
	funcGetWeb_command "${1}" "${__OPTN[@]}"
}

# --- get web address completion ----------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_address() {
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r    __PATH_WEBS="${2:?}"	# web file path
	declare -a    __OPTN=()				# options
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare -r    __PATN='?*[]'			# web file regexp
	declare       __MATC=""				# web file regexp match
	declare       __DOCS=""				# output-document
	declare -a    __LIST=()				# work variables
	declare       __LINE=""				# work variables
	# --- URL completion [dir name] -------------------------------------------
	__PATH="${__PATH_WEBS}"
	while [[ -n "${__PATH//[!"${__PATN}"]/}" ]]
	do
		__DIRS="${__PATH%%["${__PATN}"]*}"	# directory
		__DIRS="${__DIRS%/*}"
		__MATC="${__PATH#"${__DIRS}"/}"	# match
		__MATC="${__MATC%%/*}"
		__FNAM="${__PATH#*"${__MATC}"}"	# file name
		__FNAM="${__FNAM#*/}"
		__PATH="${__DIRS}"
		if [[ -n "${_COMD_WGET}" ]] && [[ "${_COMD_WGET}" != "ver2" ]]; then
			__OPTN=("--server-response" "--output-document=-" "${__PATH}")
		else
			__OPTN=("--header" "${__PATH}")
		fi
		funcGetWeb_command "__DOCS" "${__OPTN[@]}"
		IFS= mapfile -d ' ' -t __LIST < <(echo -n "${__DOCS}")
		case "${__LIST[3]}" in			# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			2??)						# 2xx (Successful)   : The request was successfully received, understood, and accepted
				IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__LIST[4]}")
				__LINE="$(printf "%s\n" "${__LIST[@]//%20/ }" | sed -ne 's%^.*<a href="'"${__MATC}"'/*">\(.*\)</a>.*$%\1%gp' | sort -rVu | head -n 1 || true)"
				__PATH="${__DIRS%%/}/${__LINE%%/}${__FNAM:+/"${__FNAM##/}"}"
				;;
			*)	break;;
		esac
	done
	__RETN_VALU="${__PATH}"
}

# --- get web information -----------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_info() {
#	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r    __PATH_WEBS="${2:?}"	# web file path
	declare       __PATH=""				# full path
	declare       __WORK=""				# work variables
	declare -a    __LIST=()				# work variables

	__PATH="${__PATH_WEBS}"
	funcGetWeb_address "__WORK" "${__PATH}"
	IFS= mapfile -d ' ' -t __LIST < <(echo -n "${__WORK}")
	funcGetWeb_info_direct "${1}" "${__LIST[0]}"
}

# --- get web status message --------------------------------------------------
# shellcheck disable=SC2317
function funcGetWeb_status() {
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
