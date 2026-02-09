# Common functions

<details><summary>for GNU Bourne Again SHell</summary>

## [fnBasename.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnBasename.sh)

<details><summary>dirname</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: dirname
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnDirname() {
	declare       __WORK=""				# work
	__WORK="${1%"${1##*/}"}"
	[[ "${__WORK:-}" != "/" ]] && __WORK="${__WORK%"${__WORK##*[^/]}"}"
	echo -n "${__WORK:-}"
}
```

</details>

<details><summary>basename</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: basename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnBasename() {
	declare       __WORK=""				# work
	__WORK="${1#"${1%/*}"}"
	__WORK="${__WORK:-"${1:-}"}"
	__WORK="${__WORK#"${__WORK%%[^/]*}"}"
	echo -n "${__WORK:-}"
}
```

</details>

<details><summary>extension</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: extension
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExtension() {
	declare       __BASE=""				# basename
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__WORK="${__BASE#"${__BASE%.*}"}"
	__WORK="${__WORK#"${__WORK%%[^.]*}"}"
	echo -n "${__WORK:-}"
}
```

</details>

<details><summary>filename</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: filename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnFilename() {
	declare       __BASE=""				# basename
	declare       __EXTN=""				# extension
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__EXTN="$(fnExtension "${__BASE:-}")"
	__WORK="${__BASE%".${__EXTN:-}"}"
	echo -n "${__WORK:-}"
}
```

</details>

## [fnColorcode.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnColorcode.sh)

<details><summary>color code</summary>

``` bash:
	# --- color code ----------------------------------------------------------
	# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
	declare       _CODE_ESCP=""
	              _CODE_ESCP="$(printf '\x1b')"
	readonly      _CODE_ESCP
	declare -r    _TEXT_RESET="${_CODE_ESCP}[0m"				# reset all attributes
	declare -r    _TEXT_BOLD="${_CODE_ESCP}[1m"					#
	declare -r    _TEXT_FAINT="${_CODE_ESCP}[2m"				#
	declare -r    _TEXT_ITALIC="${_CODE_ESCP}[3m"				#
	declare -r    _TEXT_UNDERLINE="${_CODE_ESCP}[4m"			# set underline
	declare -r    _TEXT_BLINK="${_CODE_ESCP}[5m"				#
	declare -r    _TEXT_FAST_BLINK="${_CODE_ESCP}[6m"			#
	declare -r    _TEXT_REVERSE="${_CODE_ESCP}[7m"				# set reverse display
	declare -r    _TEXT_CONCEAL="${_CODE_ESCP}[8m"				#
	declare -r    _TEXT_STRIKE="${_CODE_ESCP}[9m"				#
	declare -r    _TEXT_GOTHIC="${_CODE_ESCP}[20m"				#
	declare -r    _TEXT_DOUBLE_UNDERLINE="${_CODE_ESCP}[21m"	#
	declare -r    _TEXT_NORMAL="${_CODE_ESCP}[22m"				#
	declare -r    _TEXT_NO_ITALIC="${_CODE_ESCP}[23m"			#
	declare -r    _TEXT_NO_UNDERLINE="${_CODE_ESCP}[24m"		# reset underline
	declare -r    _TEXT_NO_BLINK="${_CODE_ESCP}[25m"			#
	declare -r    _TEXT_NO_REVERSE="${_CODE_ESCP}[27m"			# reset reverse display
	declare -r    _TEXT_NO_CONCEAL="${_CODE_ESCP}[28m"			#
	declare -r    _TEXT_NO_STRIKE="${_CODE_ESCP}[29m"			#
	declare -r    _TEXT_BLACK="${_CODE_ESCP}[30m"				# text dark black
	declare -r    _TEXT_RED="${_CODE_ESCP}[31m"					# text dark red
	declare -r    _TEXT_GREEN="${_CODE_ESCP}[32m"				# text dark green
	declare -r    _TEXT_YELLOW="${_CODE_ESCP}[33m"				# text dark yellow
	declare -r    _TEXT_BLUE="${_CODE_ESCP}[34m"				# text dark blue
	declare -r    _TEXT_MAGENTA="${_CODE_ESCP}[35m"				# text dark purple
	declare -r    _TEXT_CYAN="${_CODE_ESCP}[36m"				# text dark light blue
	declare -r    _TEXT_WHITE="${_CODE_ESCP}[37m"				# text dark white
	declare -r    _TEXT_DEFAULT="${_CODE_ESCP}[39m"				#
	declare -r    _TEXT_BG_BLACK="${_CODE_ESCP}[40m"			# text reverse black
	declare -r    _TEXT_BG_RED="${_CODE_ESCP}[41m"				# text reverse red
	declare -r    _TEXT_BG_GREEN="${_CODE_ESCP}[42m"			# text reverse green
	declare -r    _TEXT_BG_YELLOW="${_CODE_ESCP}[43m"			# text reverse yellow
	declare -r    _TEXT_BG_BLUE="${_CODE_ESCP}[44m"				# text reverse blue
	declare -r    _TEXT_BG_MAGENTA="${_CODE_ESCP}[45m"			# text reverse purple
	declare -r    _TEXT_BG_CYAN="${_CODE_ESCP}[46m"				# text reverse light blue
	declare -r    _TEXT_BG_WHITE="${_CODE_ESCP}[47m"			# text reverse white
	declare -r    _TEXT_BG_DEFAULT="${_CODE_ESCP}[49m"			#
	declare -r    _TEXT_BR_BLACK="${_CODE_ESCP}[90m"			# text black
	declare -r    _TEXT_BR_RED="${_CODE_ESCP}[91m"				# text red
	declare -r    _TEXT_BR_GREEN="${_CODE_ESCP}[92m"			# text green
	declare -r    _TEXT_BR_YELLOW="${_CODE_ESCP}[93m"			# text yellow
	declare -r    _TEXT_BR_BLUE="${_CODE_ESCP}[94m"				# text blue
	declare -r    _TEXT_BR_MAGENTA="${_CODE_ESCP}[95m"			# text purple
	declare -r    _TEXT_BR_CYAN="${_CODE_ESCP}[96m"				# text light blue
	declare -r    _TEXT_BR_WHITE="${_CODE_ESCP}[97m"			# text white
	declare -r    _TEXT_BR_DEFAULT="${_CODE_ESCP}[99m"			#
```

</details>

## [fnGetFileinfo.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnGetFileinfo.sh)

<details><summary>get file information data</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: get file information data
#   input :     $1     : file name
#   output:   stdout   : output (path,time stamp,size,volume id)
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnGetFileinfo() {
	declare       __INFO=""				# file path / size / timestamp
	declare       __VLID=""				# volume id
	declare -a    __LIST=()				# data list
	__LIST=("-" "-" "-")
	__VLID="-"
	__INFO="$(LANG=C find "${1%/*}" -name "${1##*/}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s")"
	if [[ -n "${__INFO:-}" ]]; then
		read -r -a __LIST < <(echo "${__INFO}")
		__LIST[1]="$(TZ=UTC date -d "${__LIST[1]//%20/ }" "+%Y-%m-%d%%20%H:%M:%S%z")"
		__VLID="$(blkid -s LABEL -o value "${1}")"
	fi
	printf "%s %s %s %s" "${__LIST[0]// /%20}" "${__LIST[1]// /%20}" "${__LIST[2]// /%20}" "${__VLID// /%20}"
}
```

</details>

## [fnGetWebinfo.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnGetWebinfo.sh)

<details><summary>get web information data</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: get web information data
#   input :     $1     : target url
#   output:   stdout   : output (url,last-modified,content-length,check-date,code,message)
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnGetWebinfo() {
	awk -v _urls="${1:?}" -v _wget="${2:-"wget"}" '
		function fnAwk_GetWebstatus(_retn, _code,  _mesg) {
			# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
			_mesg="Unknown Code"
			switch (_code) {
				case 100: _mesg="Continue"; break
				case 101: _mesg="Switching Protocols"; break
				case 200: _mesg="OK"; break
				case 201: _mesg="Created"; break
				case 202: _mesg="Accepted"; break
				case 203: _mesg="Non-Authoritative Information"; break
				case 204: _mesg="No Content"; break
				case 205: _mesg="Reset Content"; break
				case 206: _mesg="Partial Content"; break
				case 300: _mesg="Multiple Choices"; break
				case 301: _mesg="Moved Permanently"; break
				case 302: _mesg="Found"; break
				case 303: _mesg="See Other"; break
				case 304: _mesg="Not Modified"; break
				case 305: _mesg="Use Proxy"; break
				case 306: _mesg="(Unused)"; break
				case 307: _mesg="Temporary Redirect"; break
				case 308: _mesg="Permanent Redirect"; break
				case 400: _mesg="Bad Request"; break
				case 401: _mesg="Unauthorized"; break
				case 402: _mesg="Payment Required"; break
				case 403: _mesg="Forbidden"; break
				case 404: _mesg="Not Found"; break
				case 405: _mesg="Method Not Allowed"; break
				case 406: _mesg="Not Acceptable"; break
				case 407: _mesg="Proxy Authentication Required"; break
				case 408: _mesg="Request Timeout"; break
				case 409: _mesg="Conflict"; break
				case 410: _mesg="Gone"; break
				case 411: _mesg="Length Required"; break
				case 412: _mesg="Precondition Failed"; break
				case 413: _mesg="Content Too Large"; break
				case 414: _mesg="URI Too Long"; break
				case 415: _mesg="Unsupported Media Type"; break
				case 416: _mesg="Range Not Satisfiable"; break
				case 417: _mesg="Expectation Failed"; break
				case 418: _mesg="(Unused)"; break
				case 421: _mesg="Misdirected Request"; break
				case 422: _mesg="Unprocessable Content"; break
				case 426: _mesg="Upgrade Required"; break
				case 500: _mesg="Internal Server Error"; break
				case 501: _mesg="Not Implemented"; break
				case 502: _mesg="Bad Gateway"; break
				case 503: _mesg="Service Unavailable"; break
				case 504: _mesg="Gateway Timeout"; break
				case 505: _mesg="HTTP Version Not Supported"; break
				default : break
			}
			_mesg=sprintf("%-3s(%s)", _code, _mesg)
			gsub(" ", "%20", _mesg)
			_retn[1]=_mesg
		}
		function fnAwk_GetWebdata(_retn, _urls, _wget,  i, j, _list, _line, _code, _leng, _lmod, _date, _lcat, _ptrn, _dirs, _file, _rear, _mesg, _chek) {
			# --- set pattern part --------------------------------------------
			_ptrn=""
			_dirs=""
			_rear=""
			match(_urls, "/[^/ \t]*\\[[^/ \t]+\\][^/ \t]*")
			if (RSTART == 0) {
				if (_wget == "curl") {
					_comd="LANG=C curl --location --http1.1 --no-progress-meter --no-progress-bar --remote-time --show-error --fail --retry-max-time 3 --retry 3 --connect-timeout 60 --head "_urls" 2>&1"
				} else {
					_comd="LANG=C wget --tries=3 --timeout=60 --quiet --spider --server-response --output-document=- "_urls" 2>&1"
				}
			} else {
				_ptrn=substr(_urls, RSTART+1, RLENGTH-1)
				_dirs=substr(_urls, 1, RSTART-1)
				_rear=substr(_urls, RSTART+RLENGTH+1)
				if (_wget == "curl") {
					_comd="LANG=C curl --location --http1.1 --no-progress-meter --no-progress-bar --remote-time --show-error --fail --retry-max-time 3 --retry 3 --connect-timeout 60 --show-headers --output - "_dirs" 2>&1"
				} else {
					_comd="LANG=C wget --tries=3 --timeout=60 --quiet --server-response --output-document=- "_dirs" 2>&1"
				}
			}
			# --- get web data ------------------------------------------------
			delete _list
			i=0
			while (_comd | getline) {
				_line=$0
				sub("\r", "", _line)
				_list[i++]=_line
			}
			close(_comd)
			# --- get results -------------------------------------------------
			_code=""
			_leng=""
			_lmod=""
			_date=""
			_lcat=""
			_file=""
			for (i in _list) {
				_line=_list[i]
				sub("^[ \t]+", "", _line)
				sub("[ \t]+$", "", _line)
				switch (tolower(_line)) {
					case /^http\/[0-9]+.[0-9]+/:
						sub("[^ \t]+[ \t]+", "", _line)
						sub("[^0-9]+$", "", _line)
						_code=_line
						break
					case /^content-length:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_leng=_line
						break
					case /^last-modified:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_date="TZ=UTC date -d \""_line"\" \"+%Y-%m-%d%%20%H:%M:%S%z\""
						_date | getline _lmod
						break
					case /^location:/:
						sub("[[:graph:]]+[ \t]+", "", _line)
						_lcat=_line
						break
					default:
						break
				}
				if (length(_ptrn) == 0) {
					continue
				}
				match(_line, "<a href=\""_ptrn"/*\".*>")
				if (RSTART == 0) {
					continue
				}
				match(_line, "\""_ptrn"/*\"")
				if (RSTART == 0) {
					continue
				}
				_file=substr(_line, RSTART, RLENGTH)
				sub("^\"", "", _file)
				sub("\"$", "", _file)
				sub("^/", "", _file)
				sub("/$", "", _file)
			}
			# --- get url -----------------------------------------------------
			delete _mesg
			fnAwk_GetWebstatus(_mesg, _code)
			_date="TZ=UTC date \"+%Y-%m-%d%%20%H:%M:%S%z\""
			_date | getline _chek
			_retn[1]=_urls
			_retn[2]="-"
			_retn[3]="-"
			_retn[4]=_chek
			_retn[5]=_code
			_retn[6]=_mesg[1]
			# --- check the results -------------------------------------------
			if (_code < 200 || _code > 299) {
				return							# other than success
			}
			# --- get file information ----------------------------------------
			if (length(_ptrn) == 0) {
				_retn[2]=_lmod
				_retn[3]=_leng
				return
			}
			# --- pattern completion ------------------------------------------
			_urls=_dirs
			if (length(_file) > 0) {
				_urls=_urls"/"_file
			}
			if (length(_rear) > 0) {
				_urls=_urls"/"_rear
			}
			fnAwk_GetWebdata(_retn, _urls, _wget)
			return
		}
		BEGIN {
			fnAwk_GetWebdata(_retn, _urls, _wget)
			for (i in _retn) {
				if (length(_retn[i]) == 0) {_retn[i]="-"}
				gsub(" ", "%20", _retn[i])
			}
			printf("%s %s %s %s %s %s", _retn[1], _retn[2], _retn[3], _retn[4], _retn[5], _retn[6])
		}
	' || true
}
```

</details>

## [fnIPv4Netmask.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnIPv4Netmask.sh)

<details><summary>IPv4 netmask conversion</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
function fnIPv4Netmask() {
	echo "${1:?}" |
		awk -F '.' '{
			if (NF==1) {
				n=lshift(0xFFFFFFFF,32-$1)
				printf "%d.%d.%d.%d",
					and(rshift(n,24),0xFF),
					and(rshift(n,16),0xFF),
					and(rshift(n,8),0xFF),
					and(n,0xFF)
			} else {
				n=xor(0xFFFFFFFF,lshift($1,24)+lshift($2,16)+lshift($3,8)+$4)
				c=0
				while (n>0) {
					if (n%2==1) {
						c++
					}
					n=int(n/2)
				}
				printf "%d",(32-c)
			}
		}'
}
```

</details>

## [fnIPv6FullAddr.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnIPv6FullAddr.sh)

<details><summary>IPv6 full address</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :     $1     : value
#   input :     $2     : format (not empty: zero padding)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# https://www.gnu.org/software/gawk/manual/html_node/Strtonum-Function.html
# shellcheck disable=SC2148,SC2317,SC2329
function fnIPv6FullAddr() {
	declare       ___ADDR="${1:?}"
	declare       ___FMAT="${2:+"%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"}"
	echo "${___ADDR}" |
		awk -F '/' '{
			str=$1
			gsub("[^:]","",str)
			sep=""
			for (i=1;i<=7-length(str)+2;i++) {
				sep=sep":"
			}
			str=$1
			gsub("::",sep,str)
			split(str,arr,":")
			for (i=0;i<length(arr);i++) {
				str="0x"arr[i]
				str=substr(str,3)
				n=length(str)
				ret=0
				for (j=1;j<=n;j++){
					c=substr(str,j,1)
					c=tolower(c)
					k=index("123456789abcdef",c)
					ret=ret*16+k
				}
				num[i]=ret
			}
			printf "'"${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}"'",
				num[1],num[2],num[3],num[4],num[5],num[6],num[7],num[8]
		}'
	unset ___ADDR ___FMAT
}
```

</details>

## [fnIPv6RevAddr.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnIPv6RevAddr.sh)

<details><summary>IPv6 reverse address</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnIPv6RevAddr() {
	echo "${1:?}" |
	    awk 'gsub(":","") {
	        for(i=length();i>1;i--)
	            printf("%c.", substr($0,i,1))
	        printf("%c" , substr($0,1,1))
		}'
}
```

</details>

## [fnMsgout.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnMsgout.sh)

<details><summary>message output</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : title (program name, etc)
#   input :     $2     : section (start, complete, remove, umount, failed, ...)
#   input :     $3     : message
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnMsgout() {
	case "${2:-}" in
		start    | complete)
			case "${3:-}" in
				*/*/*) printf "\033[m${1:-}\033[m: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}\033[m:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		active             ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		inactive           ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		caution            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}\033[m:     \033[36m%-8.8s: %s\033[m\n"        "${2#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}\033[m: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}\033[m: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}\033[m: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}\033[m: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
	esac
}
```

</details>

## [fnString.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnString.sh)

<details><summary>string output</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}
```

</details>

## [fnStrmsg.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnStrmsg.sh)

<details><summary>string output with message</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnStrmsg() {
	declare      ___TEXT="${1:-}"
	declare      ___TXT1=""
	declare      ___TXT2=""
	___TXT1="$(echo "${___TEXT:-}" | cut -c -3)"
	___TXT2="$(echo "${___TEXT:-}" | cut -c "$((${#___TXT1}+2+${#2}+1+${#_PROG_NAME}+16))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TEXT
	unset ___TXT1
	unset ___TXT2
}
```

</details>

## [fnTargetsys.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnTargetsys.sh)

<details><summary>target system state</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnTargetsys() {
	declare       ___VIRT=""			# virtualization (ex. vmware)
	declare       ___CHRT=""			# is chgroot     (empty: none, else: chroot)
	declare       ___CNTR=""			# is container   (empty: none, else: container)
	if command -v systemd-detect-virt > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt --vm || true)"
		systemd-detect-virt --quiet --chroot    && ___CHRT="true"
		systemd-detect-virt --quiet --container && ___CNTR="true"
	fi
	readonly ___VIRT
	readonly ___CHRT
	readonly ___CNTR
	printf "%s,%s,%s" "${___VIRT:-}" "${___CHRT:-}" "${___CNTR:-}"
	unset ___VIRT ___CHRT ___CNTR
}
```

</details>

## [fnTrim.sh](https://github.com/office-itou/Linux/blob/master/script/_common_bash/fnTrim.sh)

<details><summary>ltrim</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: ltrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnLtrim() {
	echo -n "${1#"${1%%[^"${2:-"${IFS}"}"]*}"}"	# ltrim
}
```

</details>

<details><summary>rtrim</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: rtrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnRtrim() {
	echo -n "${1%"${1##*[^"${2:-"${IFS}"}"]}"}"	# rtrim
}
```

</details>

<details><summary>trim</summary>

``` bash:
# -----------------------------------------------------------------------------
# descript: trim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnTrim() {
	declare       __WORK=""
	__WORK="$(fnLtrim "${1:-}"      "${2:-}")"
	__WORK="$(fnRtrim "${__WORK:-}" "${2:-}")"
	echo -n "${__WORK:-}"
	unset __WORK
}
```

</details>

</details>

<details><summary>for POSIPOSIX-compliant shell</summary>

## [fnColorcode.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnColorcode.sh)

<details><summary>color code</summary>

``` sh:
	# --- color code ----------------------------------------------------------
	# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
	         _CODE_ESCP="$(printf '\x1b')"
	readonly _CODE_ESCP
	readonly _TEXT_RESET="${_CODE_ESCP}[0m"					# reset all attributes
	readonly _TEXT_BOLD="${_CODE_ESCP}[1m"					#
	readonly _TEXT_FAINT="${_CODE_ESCP}[2m"					#
	readonly _TEXT_ITALIC="${_CODE_ESCP}[3m"				#
	readonly _TEXT_UNDERLINE="${_CODE_ESCP}[4m"				# set underline
	readonly _TEXT_BLINK="${_CODE_ESCP}[5m"					#
	readonly _TEXT_FAST_BLINK="${_CODE_ESCP}[6m"			#
	readonly _TEXT_REVERSE="${_CODE_ESCP}[7m"				# set reverse display
	readonly _TEXT_CONCEAL="${_CODE_ESCP}[8m"				#
	readonly _TEXT_STRIKE="${_CODE_ESCP}[9m"				#
	readonly _TEXT_GOTHIC="${_CODE_ESCP}[20m"				#
	readonly _TEXT_DOUBLE_UNDERLINE="${_CODE_ESCP}[21m"		#
	readonly _TEXT_NORMAL="${_CODE_ESCP}[22m"				#
	readonly _TEXT_NO_ITALIC="${_CODE_ESCP}[23m"			#
	readonly _TEXT_NO_UNDERLINE="${_CODE_ESCP}[24m"			# reset underline
	readonly _TEXT_NO_BLINK="${_CODE_ESCP}[25m"				#
	readonly _TEXT_NO_REVERSE="${_CODE_ESCP}[27m"			# reset reverse display
	readonly _TEXT_NO_CONCEAL="${_CODE_ESCP}[28m"			#
	readonly _TEXT_NO_STRIKE="${_CODE_ESCP}[29m"			#
	readonly _TEXT_BLACK="${_CODE_ESCP}[30m"				# text dark black
	readonly _TEXT_RED="${_CODE_ESCP}[31m"					# text dark red
	readonly _TEXT_GREEN="${_CODE_ESCP}[32m"				# text dark green
	readonly _TEXT_YELLOW="${_CODE_ESCP}[33m"				# text dark yellow
	readonly _TEXT_BLUE="${_CODE_ESCP}[34m"					# text dark blue
	readonly _TEXT_MAGENTA="${_CODE_ESCP}[35m"				# text dark purple
	readonly _TEXT_CYAN="${_CODE_ESCP}[36m"					# text dark light blue
	readonly _TEXT_WHITE="${_CODE_ESCP}[37m"				# text dark white
	readonly _TEXT_DEFAULT="${_CODE_ESCP}[39m"				#
	readonly _TEXT_BG_BLACK="${_CODE_ESCP}[40m"				# text reverse black
	readonly _TEXT_BG_RED="${_CODE_ESCP}[41m"				# text reverse red
	readonly _TEXT_BG_GREEN="${_CODE_ESCP}[42m"				# text reverse green
	readonly _TEXT_BG_YELLOW="${_CODE_ESCP}[43m"			# text reverse yellow
	readonly _TEXT_BG_BLUE="${_CODE_ESCP}[44m"				# text reverse blue
	readonly _TEXT_BG_MAGENTA="${_CODE_ESCP}[45m"			# text reverse purple
	readonly _TEXT_BG_CYAN="${_CODE_ESCP}[46m"				# text reverse light blue
	readonly _TEXT_BG_WHITE="${_CODE_ESCP}[47m"				# text reverse white
	readonly _TEXT_BG_DEFAULT="${_CODE_ESCP}[49m"			#
	readonly _TEXT_BR_BLACK="${_CODE_ESCP}[90m"				# text black
	readonly _TEXT_BR_RED="${_CODE_ESCP}[91m"				# text red
	readonly _TEXT_BR_GREEN="${_CODE_ESCP}[92m"				# text green
	readonly _TEXT_BR_YELLOW="${_CODE_ESCP}[93m"			# text yellow
	readonly _TEXT_BR_BLUE="${_CODE_ESCP}[94m"				# text blue
	readonly _TEXT_BR_MAGENTA="${_CODE_ESCP}[95m"			# text purple
	readonly _TEXT_BR_CYAN="${_CODE_ESCP}[96m"				# text light blue
	readonly _TEXT_BR_WHITE="${_CODE_ESCP}[97m"				# text white
	readonly _TEXT_BR_DEFAULT="${_CODE_ESCP}[99m"			#
```

</details>

## [fnIPv4Netmask_gawk.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnIPv4Netmask_gawk.sh)

<details><summary>IPv4 netmask conversion</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv4Netmask_gawk() {
	echo "${1:?}" |
		gawk -F '.' '{
			if (NF==1) {
				n=lshift(0xFFFFFFFF,32-$1)
				printf "%d.%d.%d.%d",
					and(rshift(n,24),0xFF),
					and(rshift(n,16),0xFF),
					and(rshift(n,8),0xFF),
					and(n,0xFF)
			} else {
				n=xor(0xFFFFFFFF,lshift($1,24)+lshift($2,16)+lshift($3,8)+$4)
				c=0
				while (n>0) {
					if (n%2==1) {
						c++
					}
					n=int(n/2)
				}
				printf "%d",(32-c)
			}
		}'
}
```

</details>

## [fnIPv4Netmask_mawk.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnIPv4Netmask_mawk.sh)

<details><summary>IPv4 netmask conversion</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv4Netmask_mawk() {
	echo "${1:?}" |
		mawk -F '.' '
			# --- and ---------------------------------------------------------
			function fnAnd(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 && x2>0) {
					if (((x1%2)==1) && ((x2%2)==1))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- or ----------------------------------------------------------
			function fnOr(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 || x2>0) {
					if (((x1%2)==1) || ((x2%2)==1))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- xor ---------------------------------------------------------
			function fnXor(x1,x2, res,bit) {
				res=0
				bit=1
				while (x1>0 || x2>0) {
					if ((((x1%2)==1) && ((x2%2)==0)) || (((x1%2)==0) && ((x2%2)==1)))
						res+=bit
					x1=int(x1/2)
					x2=int(x2/2)
					bit*=2
				}
				return res
			}
			# --- lshift ------------------------------------------------------
#			function fnLshift(x,n) {
#				return int(x*(2^n))
#			}
			# --- rshift ------------------------------------------------------
#			function fnRshift(x,n) {
#				return int(x/(2^n))
#			}
			# --- cidr -> netmask ---------------------------------------------
			function fnCidr2netmask(x, n){
				n=fnXor((2^32-1),(int(2^(32-x))-1))
				printf "%d.%d.%d.%d",
					fnAnd(int(n/(2^24)),255),
					fnAnd(int(n/(2^16)),255),
					fnAnd(int(n/(2^ 8)),255),
					fnAnd(    n        ,255)
			}
			# --- netmask -> cidr ---------------------------------------------
			function fnNetmask2cidr(x1,x2,x3,x4, n,c){
				n=fnXor((2^32-1),(int(x1*(2^24))+int(x2*(2^16))+int(x3*(2^8))+x4))
				c=0
				while (n>0) {
					if (n%2==1)
						c++
					n=int(n/2)
				}
				printf "%d",(32-c)
			}
			# -----------------------------------------------------------------
			{
				if (NF==1)
					fnCidr2netmask($1)
				else
					fnNetmask2cidr($1,$2,$3,$4)
			}
		'
}
```

</details>

## [fnIPv4Netmask.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnIPv4Netmask.sh)

<details><summary>IPv4 netmask conversion</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: IPv4 netmask conversion
#   input :     $1     : value (nn or nnn.nnn.nnn.nnn)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# --- private ip address ------------------------------------------------------
# class | ipv4 address range            | subnet mask range
#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv4Netmask() {
	if command -v gawk > /dev/null 2>&1; then
		fnIPv4Netmask_gawk "${@:-}"
	elif command -v mawk > /dev/null 2>&1; then
		fnIPv4Netmask_mawk "${@:-}"
	fi
}
```

</details>

## [fnIPv6FullAddr.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnIPv6FullAddr.sh)

<details><summary>IPv6 full address</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: IPv6 full address
#   input :     $1     : value
#   input :     $2     : format (not empty: zero padding)
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# https://www.gnu.org/software/gawk/manual/html_node/Strtonum-Function.html
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv6FullAddr() {
	___ADDR="${1:?}"
	___FMAT="${2:+"%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"}"
	echo "${___ADDR}" |
		awk -F '/' '{
			str=$1
			gsub("[^:]","",str)
			sep=""
			for (i=1;i<=7-length(str)+2;i++) {
				sep=sep":"
			}
			str=$1
			gsub("::",sep,str)
			split(str,arr,":")
			for (i=0;i<length(arr);i++) {
				str="0x"arr[i]
				str=substr(str,3)
				n=length(str)
				ret=0
				for (j=1;j<=n;j++){
					c=substr(str,j,1)
					c=tolower(c)
					k=index("123456789abcdef",c)
					ret=ret*16+k
				}
				num[i]=ret
			}
			printf "'"${___FMAT:-"%x:%x:%x:%x:%x:%x:%x:%x"}"'",
				num[1],num[2],num[3],num[4],num[5],num[6],num[7],num[8]
		}'
	unset ___ADDR ___FMAT
}
```

</details>

## [fnIPv6RevAddr.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnIPv6RevAddr.sh)

<details><summary>IPv6 reverse address</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: IPv6 reverse address
#   input :     $1     : value
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnIPv6RevAddr() {
	echo "${1:?}" |
	    awk 'gsub(":","") {
	        for(i=length();i>1;i--)
	            printf("%c.", substr($0,i,1))
	        printf("%c" , substr($0,1,1))
		}'
}
```

</details>

## [fnMsgout.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnMsgout.sh)

<details><summary>message output</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : title (program name, etc)
#   input :     $2     : section (start, complete, remove, umount, failed, ...)
#   input :     $3     : message
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnMsgout() {
	case "${2:-}" in
		start    | complete)
			case "${3:-}" in
				*/*/*) printf "\033[m${1:-}\033[m: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}\033[m:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		active             ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		inactive           ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		caution            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}\033[m:     \033[36m%-8.8s: %s\033[m\n"        "${2#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}\033[m: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}\033[m: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}\033[m: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}\033[m: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
	esac
}
```

</details>

## [fnString.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnString.sh)

<details><summary>string output</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: string output
#   input :     $1     : count
#   input :     $2     : character
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnString() {
	printf "%${1:-80}s" "" | tr ' ' "${2:- }"
}
```

</details>

## [fnStrmsg.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnStrmsg.sh)

<details><summary>string output with message</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: string output with message
#   input :     $1     : gaps
#   input :     $2     : message
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnStrmsg() {
	___TEXT="${1:-}"
	___TXT1="$(echo "${___TEXT:-}" | cut -c -3)"
	___TXT2="$(echo "${___TEXT:-}" | cut -c "$((${#___TXT1}+2+${#2}+1+${#_PROG_NAME}+16))"-)"
	printf "%s %s %s" "${___TXT1}" "${2:-}" "${___TXT2}"
	unset ___TEXT
	unset ___TXT1
	unset ___TXT2
}
```

</details>

## [fnTargetsys.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnTargetsys.sh)

<details><summary>target system state</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnTargetsys() {
	___VIRT=""							# virtualization (ex. vmware)
	___CHRT=""							# is chgroot     (empty: none, else: chroot)
	___CNTR=""							# is container   (empty: none, else: container)
	if command -v systemd-detect-virt > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt --vm || true)"
		systemd-detect-virt --quiet --chroot    && ___CHRT="true"
		systemd-detect-virt --quiet --container && ___CNTR="true"
	fi
	readonly ___VIRT
	readonly ___CHRT
	readonly ___CNTR
	printf "%s,%s,%s" "${___VIRT:-}" "${___CHRT:-}" "${___CNTR:-}"
	unset ___VIRT ___CHRT ___CNTR
}
```

</details>

## [fnTrim.sh](https://github.com/office-itou/Linux/blob/master/script/_common_sh/fnTrim.sh)

<details><summary>ltrim</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: ltrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnLtrim() {
	printf "%s" "${1#"${1%%[^"${IFS}"]*}"}"	# ltrim
}
```

</details>

<details><summary>rtrim</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: rtrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnRtrim() {
	printf "%s" "${1%"${1##*[^"${IFS}"]}"}"	# rtrim
}
```

</details>

<details><summary>trim</summary>

``` sh:
# -----------------------------------------------------------------------------
# descript: trim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnTrim() {
	fnRtrim "$(fnLtrim "$1")"
}
```

</details>

</details>
