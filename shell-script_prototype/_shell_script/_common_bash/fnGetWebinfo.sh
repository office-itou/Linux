# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get web information data
#   input :     $1     : target url
#   output:   stdout   : output (url,last-modified,content-length,code,message)
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
		function fnAwk_GetWebdata(_retn, _urls, _wget,  i, j, _list, _line, _code, _leng, _lmod, _date, _lcat, _ptrn, _dirs, _file, _rear, _mesg) {
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
						sub("[^0-9]*$", "", _line)
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
			_retn[1]=_urls
			_retn[2]="-"
			_retn[3]="-"
			_retn[4]=_code
			_retn[5]=_mesg[1]
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
			printf("%s %s %s %s %s", _retn[1], _retn[2], _retn[3], _retn[4], _retn[5])
		}
	' || true
}
