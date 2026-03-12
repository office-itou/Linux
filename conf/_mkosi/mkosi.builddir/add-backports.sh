#!/bin/bash

	set -eu

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

function fnDbgparameters() {
	:
}

function fnMkosi_sync_add_debian_backports() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __JSON=""				# json file
	declare       __MIRR=""				# mirror
	declare       __RELS=""				# release
	declare       __REPO=""				# repositories

	# --- debian-backports.sources --------------------------------------------
	__JSON="${MKOSI_CONFIG:?}"
	__MIRR="$(jq -r '.Mirror' "${__JSON}")"
	__RELS="$(jq -r '.Release' "${__JSON}")"
	__REPO="$(jq -r '.Repositories | join(" ")' "${__JSON}")"
	__MIRR="${__MIRR#"null"}"
	__RELS="${__RELS#"null"}"
	__REPO="${__REPO#"null"}"
	case "${DISTRIBUTION:?}" in
		debian)
			__MIRR="${__MIRR:-"http://deb.debian.org/debian/"}"
			__KEYR="/usr/share/keyrings/debian-archive-keyring.gpg"
			__PATH="${SRCDIR:?}/mkosi.builddir/debian-backports-${__RELS:?}.sources"
			;;
		ubuntu)
			__MIRR="${__MIRR:-"http://archive.ubuntu.com/ubuntu/"}"
			__KEYR="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
			__PATH="${SRCDIR:?}/mkosi.builddir/ubuntu-backports-${__RELS:?}.sources"
			;;
		*)
			__MIRR=""
			__KEYR=""
			__PATH=""
			;;
	esac
	  if [[ -z "${__PATH:-}"      ]]; then
		:
	elif [[ -z "${__MIRR#"null"}" ]] \
	||   [[ -z "${__RELS#"null"}" ]] \
	||   [[ -z "${__REPO#"null"}" ]]; then
		: > "${__PATH}"
	else
		mkdir -p "${__PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}" || true
			Types: deb deb-src
			URIs: ${__MIRR:?}
			Suites: ${__RELS:?}-backports
			Components: ${__REPO:?}
			Enabled: yes
			Signed-By: ${__KEYR:?}
_EOT_
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}

fnMkosi_sync_add_debian_backports
