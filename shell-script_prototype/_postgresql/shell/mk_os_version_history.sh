#!/bin/bash

set -e
set -u
#set -x

	# --- shared directory parameter ------------------------------------------
#	declare -r    DIRS_TOPS="/srv"							# top of shared directory
#	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
#	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
#	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
#	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
#	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
#	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
#	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
#	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
#	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
#	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
#	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
#	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
#	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	declare       _FLAG=""
	declare -a    _LINE=()

	declare       _DATA_NAME=""
	declare       _DATA_NOTE=""

	declare       _WORK_GAPS=""
	              _WORK_GAPS="$(printf "%80s" '' | tr ' ' '-')"
	readonly      _WORK_GAPS

	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		# **Version history**

		## History list

		|         version          |        code_name         | life |  release   |  support   | long_term  |    rhel    |         kerne         |     note     |
		| :----------------------- | :----------------------- | :--: | :--------: | :--------: | :--------: | :--------: | :-------------------- | :----------- |
_EOT_

	declare -a _LINE=()

	while IFS= read -r -d $'\n' _LINE
	do
		IFS= mapfile -d '|' -t _LIST < <(echo -n "${_LINE//%20/ }")
		if [[ "${_LIST[4]:-}" = "EOL" ]]; then
			continue
		fi
		printf "| %-24s | %-24s | %-4s | %-10s | %-10s | %-10s | %-10s | %-21s | %-12s |\n" \
		"${_LIST[1]:-}${_LIST[2]:+"-${_LIST[2]}"}" \
		"${_LIST[3]:-}" \
		"${_LIST[4]:-}" \
		"${_LIST[5]//-/\/}" \
		"${_LIST[6]//-/\/}" \
		"${_LIST[7]//-/\/}" \
		"${_LIST[8]//-/\/}" \
		"${_LIST[9]:-}" \
		"${_LIST[10]:-}"
	done < <(psql -qtAX --host=localhost --username=dbuser --dbname=mydb --command="
SELECT
    *
FROM
    distribution
ORDER BY
      distribution.version ~ 'debian-*' DESC
    , distribution.version ~ 'ubuntu-*' DESC
    , distribution.version ~ 'fedora-*' DESC
    , distribution.version ~ 'centos-[0-9]+-*' DESC
    , distribution.version ~ 'centos-stream-*' DESC
    , distribution.version ~ 'almalinux-*' DESC
    , distribution.version ~ 'rockylinux-*' DESC
    , distribution.version ~ 'miraclelinux-*' DESC
    , distribution.version ~ 'opensuse-*' DESC
    , distribution.version ~ 'windows-*' DESC
    , distribution.version ~ 'memtest86plus' DESC
    , distribution.version ~ 'winpe-x64' DESC
    , distribution.version ~ 'winpe-x86' DESC
    , distribution.version ~ 'ati2020x64' DESC
    , distribution.version ~ 'ati2020x86' DESC
    , distribution.version ~ regexp_replace(distribution.version, '[0-9].*$', '')
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0')
    , distribution.version
;" || true)

	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'

		## WiKi

		### Debian

		* <https://en.wikipedia.org/wiki/Debian_version_history>
		* <https://ja.wikipedia.org/wiki/Debian>

		### Ubuntu

		* <https://en.wikipedia.org/wiki/Ubuntu_version_history>
		* <https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja>

		### Fedora

		* <https://en.wikipedia.org/wiki/Fedora_Linux>
		* <https://ja.wikipedia.org/wiki/Fedora>

		### CentOS Stream

		* <https://en.wikipedia.org/wiki/CentOS_Stream>

		### CentOS

		* <https://en.wikipedia.org/wiki/CentOS>
		* <https://ja.wikipedia.org/wiki/CentOS>

		### AlmaLinux

		* <https://en.wikipedia.org/wiki/AlmaLinux>

		### Rocky Linux

		* <https://en.wikipedia.org/wiki/Rocky_Linux>
		* <https://ja.wikipedia.org/wiki/Rocky_Linux>

		### Miracle Linux

		* <https://en.wikipedia.org/wiki/Miracle_Linux>
		* <https://ja.wikipedia.org/wiki/MIRACLE_LINUX>

		### openSUSE

		* <https://en.wikipedia.org/wiki/OpenSUSE>
		* <https://ja.wikipedia.org/wiki/OpenSUSE>

		### Windows

		* <https://ja.wikipedia.org/wiki/Microsoft_Windows_11%E3%81%AE%E3%83%90%E3%83%BC%E3%82%B8%E3%83%A7%E3%83%B3%E5%B1%A5%E6%AD%B4>
_EOT_
