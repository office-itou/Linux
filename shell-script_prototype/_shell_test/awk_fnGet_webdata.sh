#!/bin/bash

set -eu

#_URLS="https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.[0-9.]*-amd64-netinst.iso" 
#_URLS="https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.2.0-amd64-netinst.iso" 
#wget --server-response --output-document=- "${_URLS%/*}" 2>&1 | tr -d '\r' | \
#_URLS="$1"
#echo "" | awk -v _urls="${_URLS}" -v _dirs="${_URLS%/*}" -v _file="${_URLS##*/}" '

for _URLS in \
	"https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso" \
	"https://releases.ubuntu.com/25.10/ubuntu-25.10[0-9.]*-live-server-amd64.iso" \
	"https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso"
do
echo "" | awk -v _urls="${_URLS}" '
	function fnGet_webdata(_retn, _urls,  i, j, _list, _line, _code, _leng, _lmod, _date, _ptrn, _dirs, _file, _rear) {
		# --- set pattern part ----------------------------------------------------
		_ptrn=""
		_dirs=""
		_rear=""
		match(_urls, "/[^/ \t]*\\[[^/ \t]+\\][^/ \t]*")
		if (RSTART == 0) {
			_comd="wget --tries=3 --timeout=60 --quiet --spider --server-response --output-document=- "_urls" 2>&1"
		} else {
			_ptrn=substr(_urls, RSTART+1, RLENGTH-1)
			_dirs=substr(_urls, 1, RSTART-1)
			_rear=substr(_urls, RSTART+RLENGTH+1)
			_comd="wget --tries=3 --timeout=60 --quiet --server-response --output-document=- "_dirs" 2>&1"
		}
		# --- get web data --------------------------------------------------------
		delete _list
		i=0
		while (_comd | getline) {
			_line=$0
			_list[i++]=_line
		}
		close(_comd)
		# --- get results ---------------------------------------------------------
		_code=""
		_leng=""
		_lmod=""
		_date=""
		for (i in _list) {
			_line=_list[i]
			sub("^[ \t]+", "", _line)
			sub("[ \t]+$", "", _line)
			switch (tolower(_line)) {
				case /http\/[0-9.]+/:
					sub("[^ \t]+[ \t]+", "", _line)
					sub("[^0-9]*$", "", _line)
					_code=_line
					break
				case /content-length:/:
					sub("[[:graph:]]+[ \t]+", "", _line)
					_leng=_line
					break
				case /last-modified:/:
					sub("[[:graph:]]+[ \t]+", "", _line)
					_date="TZ=UTC date -d \""_line"\" \"+%Y-%m-%d%%20%H:%M:%S%z\""
					_date | getline _lmod
					break
				default:
					break
			}
		}
		# --- get url -------------------------------------------------------------
		_retn[1]=""
		_retn[2]=_code
		_retn[3]=""
		_retn[4]=""
		# --- check the results ---------------------------------------------------
		if (_code < 200 || _code > 299) {
			return							# other than success
		}
		# --- get file information ------------------------------------------------
		if (length(_ptrn) == 0) {
			_retn[1]=_urls
			_retn[2]=_code
			_retn[3]=_leng
			_retn[4]=_lmod
			return
		}
		# --- pattern completion --------------------------------------------------
		delete _file
		j=0
		for (i in _list) {
			_line=_list[i]
			# --- get pattern part ------------------------------------------------
			match(_line, "<a href=.*"_ptrn".*/a>")
			if (RSTART == 0) {
				continue
			}
			match(_line, _ptrn)
			if (RSTART == 0) {
				continue
			}
			_file[j++]=substr(_line, RSTART, RLENGTH)
		}
		for (j = length(_file)-1; j >= 0 ;j--) {
			# --- get next pattern part -------------------------------------------
			_urls=_dirs"/"_file[j]
			if (length(_rear) > 0) {
				_urls=_urls"/"_rear
			}
			fnGet_webdata(_retn, _urls)
			return
		}
	}

	BEGIN {
		fnGet_webdata(_retn, _urls)
		printf("_retn[1]=[%s]\n", _retn[1])
		printf("_retn[2]=[%s]\n", _retn[2])
		printf("_retn[3]=[%s]\n", _retn[3])
		printf("_retn[4]=[%s]\n", _retn[4])
	}
	{
	}
	END {
	}
' &
done
wait
