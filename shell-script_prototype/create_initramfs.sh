#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		*) ;;
	esac

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

#	declare -r    PROG_PATH="$0"
	declare -r    DIRS_WORK="${PWD}/workdir"
	declare -r    _TGET_ARCH="amd64"
	declare -r    _TGET_PKGS="package"

	# 0: operation flags (o: execute, others: not execute)
	# 1: version
	# 2: code name
	# 3: kernel
	# 4: life
	# 5: release date
	# 6: end of support
	# 7: long term
	# 8: mirror

	declare -a    _OS_VERSION_HISTORY_LIST=(                                                                                                        \
	    "x  debian-1.1      buzz        -                       EOL     1996-06-17  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-1.2      rex         -                       EOL     1996-12-12  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-1.3      bo          -                       EOL     1997-06-05  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-2.0      hamm        -                       EOL     1998-07-24  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-2.1      slink       -                       EOL     1999-03-09  2000-10-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-2.2      potato      -                       EOL     2000-08-15  2003-06-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-3.0      woody       -                       EOL     2002-07-19  2006-06-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-3.1      sarge       -                       EOL     2005-06-06  2008-03-31  -           http://archive.debian.org/debian    "   \
	    "x  debian-4        etch        -                       EOL     2007-04-08  2010-02-15  -           http://archive.debian.org/debian    "   \
	    "x  debian-5        lenny       -                       EOL     2009-02-14  2012-02-06  -           http://archive.debian.org/debian    "   \
	    "x  debian-6        squeeze     -                       EOL     2011-02-06  2014-05-31  2016-02-29  http://archive.debian.org/debian    "   \
	    "x  debian-7        wheezy      -                       EOL     2013-05-04  2016-04-25  2018-05-31  http://archive.debian.org/debian    "   \
	    "x  debian-8        jessie      -                       EOL     2015-04-25  2018-06-17  2020-06-30  http://archive.debian.org/debian    "   \
	    "x  debian-9        stretch     -                       EOL     2017-06-17  2020-07-18  2022-06-30  http://archive.debian.org/debian    "   \
	    "o  debian-10       buster      4.19.0-21-_ARCH_-di     EOL     2019-07-06  2022-09-10  2024-06-30  http://archive.debian.org/debian    "   \
	    "o  debian-11       bullseye    5.10.0-32-_ARCH_-di     LTS     2021-08-14  2024-07-01  2026-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-12       bookworm    6.1.0-27-_ARCH_-di      -       2023-06-10  2026-06-01  2028-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-13       trixie      -                       -       2025-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "-  debian-14       forky       -                       -       2027-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "o  debian-sid      sid         6.10.11-_ARCH_-di       -       -           -           -           http://deb.debian.org/debian        "   \
	    "x  ubuntu-4.10     warty       -                       EOL     2004-10-20  2006-04-30  -           -                                   "   \
	    "x  ubuntu-5.04     hoary       -                       EOL     2005-04-08  2006-10-31  -           -                                   "   \
	    "x  ubuntu-5.10     breezy      -                       EOL     2005-10-12  2007-04-13  -           -                                   "   \
	    "x  ubuntu-6.06     dapper      -                       EOL     2006-06-01  2009-07-14  2011-06-01  -                                   "   \
	    "x  ubuntu-6.10     edgy        -                       EOL     2006-10-26  2008-04-25  -           -                                   "   \
	    "x  ubuntu-7.04     feisty      -                       EOL     2007-04-19  2008-10-19  -           -                                   "   \
	    "x  ubuntu-7.10     gutsy       -                       EOL     2007-10-18  2009-04-18  -           -                                   "   \
	    "x  ubuntu-8.04     hardy       -                       EOL     2008-04-24  2011-05-12  2013-05-09  -                                   "   \
	    "x  ubuntu-8.10     intrepid    -                       EOL     2008-10-30  2010-04-30  -           -                                   "   \
	    "x  ubuntu-9.04     jaunty      -                       EOL     2009-04-23  2010-10-23  -           -                                   "   \
	    "x  ubuntu-9.10     karmic      -                       EOL     2009-10-29  2011-04-30  -           -                                   "   \
	    "x  ubuntu-10.04    lucid       -                       EOL     2010-04-29  2013-05-09  2015-04-30  -                                   "   \
	    "x  ubuntu-10.10    maverick    -                       EOL     2010-10-10  2012-04-10  -           -                                   "   \
	    "x  ubuntu-11.04    natty       -                       EOL     2011-04-28  2012-10-28  -           -                                   "   \
	    "x  ubuntu-11.10    oneiric     -                       EOL     2011-10-13  2013-05-09  -           -                                   "   \
	    "x  ubuntu-12.04    precise     -                       EOL     2012-04-26  2017-04-28  2019-04-26  -                                   "   \
	    "x  ubuntu-12.10    quantal     -                       EOL     2012-10-18  2014-05-16  -           -                                   "   \
	    "x  ubuntu-13.04    raring      -                       EOL     2013-04-25  2014-01-27  -           -                                   "   \
	    "x  ubuntu-13.10    saucy       -                       EOL     2013-10-17  2014-07-17  -           -                                   "   \
	    "x  ubuntu-14.04    trusty      -                       EOL     2014-04-17  2019-04-25  2024-04-25  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-14.10    utopic      -                       EOL     2014-10-23  2015-07-23  -           -                                   "   \
	    "x  ubuntu-15.04    vivid       -                       EOL     2015-04-23  2016-02-04  -           -                                   "   \
	    "x  ubuntu-15.10    wily        -                       EOL     2015-10-22  2016-07-28  -           -                                   "   \
	    "-  ubuntu-16.04    xenial      -                       LTS     2016-04-21  2021-04-30  2026-04-23  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-16.10    yakkety     -                       EOL     2016-10-13  2017-07-20  -           -                                   "   \
	    "x  ubuntu-17.04    zesty       -                       EOL     2017-04-13  2018-01-13  -           -                                   "   \
	    "x  ubuntu-17.10    artful      -                       EOL     2017-10-19  2018-07-19  -           -                                   "   \
	    "-  ubuntu-18.04    bionic      4.15.0-20-generic-di    LTS     2018-04-26  2023-05-31  2028-04-26  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-18.10    cosmic      -                       EOL     2018-10-18  2019-07-18  -           -                                   "   \
	    "x  ubuntu-19.04    disco       -                       EOL     2019-04-18  2020-01-23  -           -                                   "   \
	    "x  ubuntu-19.10    eoan        -                       EOL     2019-10-17  2020-07-17  -           -                                   "   \
	    "o  ubuntu-20.04    focal       5.4.0-26-generic-di     -       2020-04-23  2025-05-29  2030-04-23  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-20.10    groovy      -                       EOL     2020-10-22  2021-07-22  -           -                                   "   \
	    "x  ubuntu-21.04    hirsute     -                       EOL     2021-04-22  2022-01-20  -           -                                   "   \
	    "x  ubuntu-21.10    impish      -                       EOL     2021-10-14  2022-07-14  -           -                                   "   \
	    "o  ubuntu-22.04    jammy       5.15.0-25-generic-di    -       2022-04-21  2027-06-01  2032-04-21  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-22.10    kinetic     -                       EOL     2022-10-20  2023-07-20  -           -                                   "   \
	    "x  ubuntu-23.04    lunar       -                       EOL     2023-04-20  2024-01-25  -           -                                   "   \
	    "x  ubuntu-23.10    mantic      -                       EOL     2023-10-12  2024-07-11  -           -                                   "   \
	    "o  ubuntu-24.04    noble       6.8.0-31-generic-di     -       2024-04-25  2029-05-31  2034-04-25  http://archive.ubuntu.com/ubuntu    "   \
	    "o  ubuntu-24.10    oracular    6.11.0-8-generic-di     -       2024-10-10  2025-07-xx  -           http://archive.ubuntu.com/ubuntu    "   \
	    "o  ubuntu-25.04    plucky      6.11.0-8-generic-di     -       2025-04-17  2026-01-xx  -           http://archive.ubuntu.com/ubuntu    "   \
	) # 0:  1:              2:          3:                      4:      5:          6:          7:          8:

	for ((I=0; I<"${#_OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LINE < <(echo "${_OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LINE[0]}"
		_DIST="${_LINE[1]}"
		_SUIT="${_LINE[2]}"
		_KVER="${_LINE[3]}"
		_LIFE="${_LINE[4]}"
		_RDAY="${_LINE[5]}"
		_EDAY="${_LINE[6]}"
		_LDAY="${_LINE[7]}"
		_MIRR="${_LINE[8]}"
#		if [[ "${_PROC}" != "o" ]]; then
#			continue
#		fi
		case "${_DIST}" in
			debian-*)
				_COMP="main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer"
				_LIMG="linux-image-${_TGET_ARCH}"
				_VERS="${_DIST##*-}"
				if [[ "${_VERS:-}" =~ ^-?[0-9]+\.?[0-9]*$ ]] && [[ "${_VERS%%.*}" -le 11 ]]; then
					_COMP="main,contrib,non-free,main/debian-installer,contrib/debian-installer,non-free/debian-installer"
				fi
				;;
			ubuntu-*)
				_COMP="main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer"
				_LIMG="linux-image-generic"
				;;
			*       )
				continue
				;;
		esac
		_LINE=(\
			"${_PROC}" \
			"${_DIST}" \
			"${_SUIT}" \
			"${_KVER}" \
			"${_LIFE}" \
			"${_RDAY}" \
			"${_EDAY}" \
			"${_LDAY}" \
			"${_MIRR}" \
			"${_COMP}" \
			"${_LIMG}" \
		)
		_OS_VERSION_HISTORY_LIST[I]="${_LINE[*]}"
	done

	declare -r -a _OS_VERSION_HISTORY_LIST

# --- create base system ------------------------------------------------------
	rm -rf "${DIRS_WORK}"
	mkdir -p "${DIRS_WORK}"
	mmdebstrap \
	    --variant=apt \
	    --mode=sudo \
	    --format=directory \
	    --keyring=/home/master/share/keys \
	    --include='fakechroot gnupg' \
	    --components='main contrib non-free non-free-firmware' \
	    --architectures="${_TGET_ARCH}" \
	    bookworm \
	    "${DIRS_WORK}"

# --- sources.list ------------------------------------------------------------
	for ((I=0; I<"${#_OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LINE < <(echo "${_OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LINE[0]}"
#		_DIST="${_LINE[1]}"
		_SUIT="${_LINE[2]}"
#		_KVER="${_LINE[3]}"
#		_LIFE="${_LINE[4]}"
#		_RDAY="${_LINE[5]}"
#		_EDAY="${_LINE[6]}"
#		_LDAY="${_LINE[7]}"
		_MIRR="${_LINE[8]}"
		_COMP="${_LINE[9]}"
#		_LIMG="${_LINE[10]}"
		if [[ "${_PROC}" != "o" ]]; then
			continue
		fi
		cat <<- _EOT_ > "${DIRS_WORK}/etc/apt/sources.list.d/${_SUIT}.list"
			deb ${_MIRR} ${_SUIT} ${_COMP//,/ }
_EOT_
	done

# --- keyring -----------------------------------------------------------------
	rm -f debian-keyring_*.deb ubuntu-keyring_*.deb
	wget --quiet --timestamping http://deb.debian.org/debian/pool/main/d/debian-keyring/debian-keyring_2024.09.22_all.deb
	wget --quiet --timestamping http://archive.ubuntu.com/ubuntu/pool/main/u/ubuntu-keyring/ubuntu-keyring_2023.11.28.1_all.deb
	dpkg --install --root="${DIRS_WORK}" debian-keyring_*.deb ubuntu-keyring_*.deb > /dev/null

# --- apt-get update ----------------------------------------------------------
	_FILE_PATH="${DIRS_WORK}/etc/apt/sources.list"
	if [[ -e "${_FILE_PATH}" ]]; then
		mv "${_FILE_PATH}" "${_FILE_PATH}.org"
	fi
	_COMD=(\
	    "apt-get -q update;" \
	)
	chroot "${DIRS_WORK}" bash -c "${_COMD[*]}"

# --- download packages -------------------------------------------------------
	rm -rf "${DIRS_WORK:?}/${_TGET_PKGS:?}"
	mkdir -p "/${DIRS_WORK}/${_TGET_PKGS}"
	chown -R _apt: "/${DIRS_WORK}/${_TGET_PKGS}"
	for ((I=0; I<"${#_OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LINE < <(echo "${_OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LINE[0]}"
		_DIST="${_LINE[1]}"
		_SUIT="${_LINE[2]}"
#		_KVER="${_LINE[3]}"
#		_LIFE="${_LINE[4]}"
#		_RDAY="${_LINE[5]}"
#		_EDAY="${_LINE[6]}"
#		_LDAY="${_LINE[7]}"
		_MIRR="${_LINE[8]}"
		_COMP="${_LINE[9]}"
		_LIMG="${_LINE[10]}"
		if [[ "${_PROC}" != "o" ]]; then
			continue
		fi
		_COMD=(\
		    "mkdir -p /${_TGET_PKGS}/${_DIST};" \
		    "chown -R _apt: /${_TGET_PKGS}/${_DIST};" \
		    "cd /${_TGET_PKGS}/${_DIST};" \
		    "apt-get -q --target-release=${_SUIT} download ${_LIMG};" \
		    "dpkg -x *.deb imgs;" \
		    "ls imgs/lib/modules/;" \
		)
		echo -n "${_DIST} ${_SUIT}: "
		chroot "${DIRS_WORK}" bash -c "${_COMD[*]}"
	done

# --- exit --------------------------------------------------------------------
	exit 0

# --- eof ---------------------------------------------------------------------
