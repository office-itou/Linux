#!/bin/bash

set -e
set -u
#set -x

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	declare       _FLAG=""
	declare -a    _LINE=()

	declare       _DATA_NAME=""
	declare       _DATA_NOTE=""

	declare       _WORK_GAPS=""
	              _WORK_GAPS="$(printf "%80s" '' | tr ' ' '-')"
	readonly      _WORK_GAPS

	declare -a _LINE=()

	# --- media information ---------------------------------------------------
	#  0: type          ( 14)   media type
	#  1: entry_flag    ( 15)   [m] menu, [o] output, [else] hidden
	#  2: entry_name    ( 39)   entry name (unique)
	#  3: entry_disp    ( 39)   entry name for display
	#  4: version       ( 23)   version id
	#  5: latest        ( 23)   latest version
	#  6: release       ( 15)   release date
	#  7: support       ( 15)   support end date
	#  8: web_url       (143)   web file  url
	#  9: web_tstamp    ( 23)   "         time stamp
	# 10: web_size      ( 15)   "         file size
	# 11: web_status    ( 15)   "         download status
	# 12: iso_path      ( 71)   iso image file path
	# 13: iso_tstamp    ( 23)   "         time stamp
	# 14: iso_size      ( 15)   "         file size
	# 15: iso_volume    ( 41)   "         volume id
	# 16: rmk_path      ( 71)   remaster  file path
	# 17: rmk_tstamp    ( 23)   "         time stamp
	# 18: rmk_size      ( 15)   "         file size
	# 19: rmk_volume    ( 41)   "         volume id
	# 20: ldr_initrd    ( 71)   initrd    file path
	# 21: ldr_kernel    ( 71)   kernel    file path
	# 22: cfg_path      ( 71)   config    file path
	# 23: cfg_tstamp    ( 23)   "         time stamp
	# 24: lnk_path      ( 71)   symlink   directory or file path

	while IFS= read -r -d $'\n' _LINE
	do
		_LINE="${_LINE//:_DIRS_TOPS_:/"${DIRS_TOPS:-}"}"
		_LINE="${_LINE//:_DIRS_HGFS_:/"${DIRS_HGFS:-}"}"
		_LINE="${_LINE//:_DIRS_HTML_:/"${DIRS_HTML:-}"}"
		_LINE="${_LINE//:_DIRS_SAMB_:/"${DIRS_SAMB:-}"}"
		_LINE="${_LINE//:_DIRS_TFTP_:/"${DIRS_TFTP:-}"}"
		_LINE="${_LINE//:_DIRS_USER_:/"${DIRS_USER:-}"}"
		_LINE="${_LINE//:_DIRS_SHAR_:/"${DIRS_SHAR:-}"}"
		_LINE="${_LINE//:_DIRS_CONF_:/"${DIRS_CONF:-}"}"
		_LINE="${_LINE//:_DIRS_KEYS_:/"${DIRS_KEYS:-}"}"
		_LINE="${_LINE//:_DIRS_TMPL_:/"${DIRS_TMPL:-}"}"
		_LINE="${_LINE//:_DIRS_IMGS_:/"${DIRS_IMGS:-}"}"
		_LINE="${_LINE//:_DIRS_ISOS_:/"${DIRS_ISOS:-}"}"
		_LINE="${_LINE//:_DIRS_LOAD_:/"${DIRS_LOAD:-}"}"
		_LINE="${_LINE//:_DIRS_RMAK_:/"${DIRS_RMAK:-}"}"
		# --- split into array ------------------------------------------------
		IFS= mapfile -d '|' -t _LIST < <(echo -n "${_LINE//%20/ }|")
		# --- get original file information -----------------------------------
#		_LIST[12]="${_LIST[12]:-"${DIRS_ISOS:-}/"}"
		if [[ -f "${_LIST[12]:-}" ]]; then
			_WORK_TEXT="$(LANG=C TZ=UTC ls -lL --time-style="+%Y-%m-%d %H:%M:%S" "${_LIST[12]}")"
			IFS= mapfile -d ' ' -t _FILE_INFO < <(echo -n "${_WORK_TEXT}")
			_LIST[13]="${_FILE_INFO[5]} ${_FILE_INFO[6]}"	# iso_tstamp
			_LIST[14]="${_FILE_INFO[4]}"					# iso_size
			_LIST[15]="$(LANG=C file -L "${_LIST[12]}")"	# iso_volume
			_LIST[15]="${_LIST[15]#*\'}"
			_LIST[15]="${_LIST[15]%\'*}"
			# --- get remastered file information -----------------------------
			# :_DIRS_ISOS_:/mini-bookworm-amd64.iso
			# :_DIRS_RMAK_:/mini-bookworm-amd64_preseed.iso
			# :_DIRS_CONF_:/preseed/ps_debian_server.cfg
			if [[ -n "${_LIST[22]:-}" ]]; then
				_WORK_TEXT="${_LIST[22]#"${DIRS_CONF:-}"/}"
				_WORK_TEXT="${_WORK_TEXT%/*}"
				_LIST[16]="${_LIST[12]##*/}"
				_LIST[16]="${DIRS_RMAK}/${_LIST[16]%.*}_${_WORK_TEXT}.${_LIST[16]##*.}"
				if [[ -f "${_LIST[16]:-}" ]]; then
					_WORK_TEXT="$(LANG=C TZ=UTC ls -lL --time-style="+%Y-%m-%d %H:%M:%S" "${_LIST[16]}")"
					IFS= mapfile -d ' ' -t _FILE_INFO < <(echo -n "${_WORK_TEXT}")
					_LIST[17]="${_FILE_INFO[5]} ${_FILE_INFO[6]}"	# iso_tstamp
					_LIST[18]="${_FILE_INFO[4]}"					# iso_size
					_LIST[19]="$(LANG=C file -L "${_LIST[16]}")"	# iso_volume
					_LIST[19]="${_LIST[19]#*\'}"
					_LIST[19]="${_LIST[19]%\'*}"
				fi
			fi
		fi
		# --- data conversion -------------------------------------------------
		for I in "${!_LIST[@]}"
		do
			_LIST[I]="${_LIST[I]//"${DIRS_KEYS:-}"/:_DIRS_KEYS_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_TMPL:-}"/:_DIRS_TMPL_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_CONF:-}"/:_DIRS_CONF_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_IMGS:-}"/:_DIRS_IMGS_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_ISOS:-}"/:_DIRS_ISOS_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_LOAD:-}"/:_DIRS_LOAD_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_RMAK:-}"/:_DIRS_RMAK_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_SHAR:-}"/:_DIRS_SHAR_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_USER:-}"/:_DIRS_USER_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_HGFS:-}"/:_DIRS_HGFS_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_HTML:-}"/:_DIRS_HTML_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_SAMB:-}"/:_DIRS_SAMB_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_TFTP:-}"/:_DIRS_TFTP_:}"
			_LIST[I]="${_LIST[I]//"${DIRS_TOPS:-}"/:_DIRS_TOPS_:}"
			_LIST[I]="${_LIST[I]:--}"						# null
			_LIST[I]="${_LIST[I]// /%20}"					# blank
		done
		# --- put data list ---------------------------------------------------
		_LINE="$(
			printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-23s %-15s %-15s %-71s %-23s %-15s %-41s %-71s %-23s %-15s %-41s %-71s %-71s %-71s %-23s %-71s" \
				"${_LIST[0]}" \
				"${_LIST[1]}" \
				"${_LIST[2]}" \
				"${_LIST[3]}" \
				"${_LIST[4]}" \
				"${_LIST[5]}" \
				"${_LIST[6]}" \
				"${_LIST[7]}" \
				"${_LIST[8]}" \
				"${_LIST[9]}" \
				"${_LIST[10]}" \
				"${_LIST[11]}" \
				"${_LIST[12]}" \
				"${_LIST[13]}" \
				"${_LIST[14]}" \
				"${_LIST[15]}" \
				"${_LIST[16]}" \
				"${_LIST[17]}" \
				"${_LIST[18]}" \
				"${_LIST[19]}" \
				"${_LIST[20]}" \
				"${_LIST[21]}" \
				"${_LIST[22]}" \
				"${_LIST[23]}" \
				"${_LIST[24]}"
		)"
		printf "%s\n" "${_LINE:-}"
	done < <(psql -qtAX --dbname=mydb --command="
SELECT
    m.type
    , m.entry_flag
    , m.entry_name
    , m.entry_disp
    , m.version
    , d.version AS latest
    , d.release
    , d.support
    , m.web_url
    , m.web_tstamp
    , m.web_size
    , m.web_status
    , m.iso_path
    , m.iso_tstamp
    , m.iso_size
    , m.iso_volume
    , m.rmk_path
    , m.rmk_tstamp
    , m.rmk_size
    , m.rmk_volume
    , m.ldr_initrd
    , m.ldr_kernel
    , m.cfg_path
    , m.cfg_tstamp
    , lnk_path
FROM
    media AS m
    LEFT JOIN distribution AS d
        ON d.version = (
            SELECT
                s.version
            FROM
                distribution AS s
            WHERE LENGTH(m.version) > 0 AND
                s.version SIMILAR TO '%' || m.version || '\.*.*%'
            ORDER BY
                LPAD(SPLIT_PART(SubString(regexp_replace(s.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0') DESC
              , LPAD(SPLIT_PART(SubString(regexp_replace(s.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0') DESC
              , LPAD(SPLIT_PART(SubString(regexp_replace(s.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0') DESC
            LIMIT
                1
        )
ORDER BY
    type = 'mini.iso' DESC
    , type = 'netinst' DESC
    , type = 'dvd' DESC
    , type = 'live_install' DESC
    , type = 'live' DESC
    , type = 'tool' DESC
    , type = 'custom_live' DESC
    , type = 'custom_netinst' DESC
    , type = 'system' DESC
    , entry_disp != '-' DESC
    , entry_name = 'menu-entry' DESC
    , entry_flag = 'b'
    , entry_flag = 'd'
    , m.version ~ 'debian-*' DESC
    , m.version ~ 'ubuntu-*' DESC
    , m.version ~ 'fedora-*' DESC
    , m.version ~ 'centos-*' DESC
    , m.version ~ 'almalinux-*' DESC
    , m.version ~ 'rockylinux-*' DESC
    , m.version ~ 'miraclelinux-*' DESC
    , m.version ~ 'opensuse-*' DESC
    , m.version ~ 'windows-*' DESC
    , m.version ~ 'memtest86plus' DESC
    , m.version ~ 'winpe-x86' DESC
    , m.version ~ 'winpe-x64' DESC
    , m.version ~ 'ati2020x86' DESC
    , m.version ~ 'ati2020x64' DESC
    , entry_name ~ 'ubuntu-server-*' DESC
    , entry_name ~ 'ubuntu-desktop-*' DESC
    , entry_name ~ 'ubuntu-live-*' DESC
    , entry_name ~ 'ubuntu-legacy-*' DESC
    , m.version ~ regexp_replace(m.version, '[0-9].*$', '') DESC
    , LPAD(SPLIT_PART(SubString(regexp_replace(m.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(m.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(m.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0')
    , entry_name
    , entry_disp
;" || true)
