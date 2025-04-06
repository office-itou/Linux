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

	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		 	# === system ==============================================================
		
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
		 	# 10: web_size      ( 11)   "         file size
		 	# 11: web_status    ( 15)   "         download status
		 	# 12: iso_path      ( 63)   iso image file path
		 	# 13: iso_tstamp    ( 23)   "         time stamp
		 	# 14: iso_size      ( 11)   "         file size
		 	# 15: iso_volume    ( 15)   "         volume id
		 	# 16: rmk_path      ( 63)   remaster  file path
		 	# 17: rmk_tstamp    ( 23)   "         time stamp
		 	# 18: rmk_size      ( 11)   "         file size
		 	# 19: rmk_volume    ( 15)   "         volume id
		 	# 20: ldr_initrd    ( 63)   initrd    file path
		 	# 21: ldr_kernel    ( 63)   kernel    file path
		 	# 22: cfg_path      ( 63)   config    file path
		 	# 23: cfg_tstamp    ( 23)   "         time stamp
		 	# 24: lnk_path      ( 63)   symlink   directory or file path
		
_EOT_

	declare -a _LINE=()

	while IFS= read -r -d $'\n' _LINE
	do
		IFS= mapfile -d '|' -t _LIST < <(echo -n "${_LINE// /%20}")
		if [[ "${_FLAG:-"${_LIST[0]:-}"}" != "${_LIST[0]:-}" ]]; then
			_FLAG=""
#			printf "\t)  # %-14.14s %-15.15s %-39.39s %-39.39s %-23.23s %-23.23s %-15.15s %-15.15s %-143.143s %-23.23s %-11.11s %-15.15s %-63.63s %-23.23s %-11.11s %-15.15s %-63.63s %-23.23s %-11.11s %-15.15s %-63.63s %-63.63s %-63.63s %-23.23s %-63.63s\n\n" \
			printf "\t)  # %-14s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-23s %-11s %-15s %-63s %-23s %-11s %-15s %-63s %-23s %-11s %-15s %-63s %-63s %-63s %-23s %s\n\n" \
			"0:type"        \
			"1:entry_flag"  \
			"2:entry_name"  \
			"3:entry_disp"  \
			"4:version"     \
			"5:latest"      \
			"6:release"     \
			"7:support"     \
			"8:web_url"     \
			"9:web_tstamp"  \
			"10:web_size"   \
			"11:web_status" \
			"12:iso_path"   \
			"13:iso_tstamp" \
			"14:iso_size"   \
			"15:iso_volume" \
			"16:rmk_path"   \
			"17:rmk_tstamp" \
			"18:rmk_size"   \
			"19:rmk_volume" \
			"20:ldr_initrd" \
			"21:ldr_kernel" \
			"22:cfg_path"   \
			"23:cfg_tstamp" \
			"24:lnk_path"
		fi
		if [[ -z "${_FLAG:-}" ]]; then
			_FLAG="${_LIST[0]:-}"
			case "${_LIST[0]:-}" in
				mini.iso      ) _DATA_NAME="DATA_LIST_MINI"; _DATA_NOTE="mini.iso";;
				netinst       ) _DATA_NAME="DATA_LIST_NET" ; _DATA_NOTE="netinst";;
				dvd           ) _DATA_NAME="DATA_LIST_DVD" ; _DATA_NOTE="dvd image";;
				live_install  ) _DATA_NAME="DATA_LIST_INST"; _DATA_NOTE="live media install mode";;
				live          ) _DATA_NAME="DATA_LIST_LIVE"; _DATA_NOTE="live media live mode";;
				tool          ) _DATA_NAME="DATA_LIST_TOOL"; _DATA_NOTE="tool";;
				custom_live   ) _DATA_NAME="DATA_LIST_CSML"; _DATA_NOTE="custom iso image live media";;
				custom_netinst) _DATA_NAME="DATA_LIST_CSMN"; _DATA_NOTE="custom iso image netinst media";;
				system        ) _DATA_NAME="DATA_LIST_SCMD"; _DATA_NOTE="system command";;
				*             ) _DATA_NAME=""              ; _DATA_NOTE="";;
			esac
			printf "\t%-75.75s\n" "# --- ${_DATA_NOTE:-} ${_WORK_GAPS}"
			printf "\tdeclare -r -a %-894.894s\\\\\n" "${_DATA_NAME:-}=("
		fi
#		printf "\t\t'%-14.14s %-15.15s %-39.39s %-39.39s %-23.23s %-23.23s %-15.15s %-15.15s %-143.143s %-23.23s %-11.11s %-15.15s %-63.63s %-23.23s %-11.11s %-15.15s %-63.63s %-23.23s %-11.11s %-15.15s %-63.63s %-63.63s %-63.63s %-23.23s %-63.63s'\t\\\\\n" \
		printf "\t\t'%-14s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-23s %-11s %-15s %-63s %-23s %-11s %-15s %-63s %-23s %-11s %-15s %-63s %-63s %-63s %-23s %-63s'\t\\\\\n" \
		"${_LIST[0]:--}" \
		"${_LIST[1]:--}" \
		"${_LIST[2]:--}" \
		"${_LIST[3]:--}" \
		"${_LIST[4]:--}" \
		"${_LIST[5]:-"${_LIST[4]:--}"}" \
		"${_LIST[6]:--}" \
		"${_LIST[7]:--}" \
		"${_LIST[8]:--}" \
		"${_LIST[9]:--}" \
		"${_LIST[10]:--}" \
		"${_LIST[11]:--}" \
		"${_LIST[12]:--}" \
		"${_LIST[13]:--}" \
		"${_LIST[14]:--}" \
		"${_LIST[15]:--}" \
		"${_LIST[16]:--}" \
		"${_LIST[17]:--}" \
		"${_LIST[18]:--}" \
		"${_LIST[19]:--}" \
		"${_LIST[20]:--}" \
		"${_LIST[21]:--}" \
		"${_LIST[22]:--}" \
		"${_LIST[23]:--}" \
		"${_LIST[24]:--}"
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
    , latest ~ 'debian-*' DESC
    , latest ~ 'ubuntu-*' DESC
    , latest ~ 'fedora-*' DESC
    , latest ~ 'centos-*' DESC
    , latest ~ 'almalinux-*' DESC
    , latest ~ 'rockylinux-*' DESC
    , latest ~ 'miraclelinux-*' DESC
    , latest ~ 'opensuse-*' DESC
    , latest ~ 'windows-*' DESC
    , latest ~ 'memtest86plus' DESC
    , latest ~ 'winpe-x64' DESC
    , latest ~ 'winpe-x86' DESC
    , latest ~ 'ati2020x64' DESC
    , latest ~ 'ati2020x86' DESC
    , entry_name ~ 'ubuntu-legacy-*' DESC
    , entry_name ~ 'ubuntu-server-*' DESC
    , latest ~ regexp_replace(latest, '[0-9].*$', '') DESC
    , LPAD(SPLIT_PART(SubString(regexp_replace(latest, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(latest, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(latest, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0')
    , entry_name
;" || true)

	if [[ -n "${_FLAG:-}" ]]; then
		printf "\t)  # %-14.14s %-15.15s %-39.39s %-39.39s %-19.19s %-19.19s %-11.11s %-11.11s %-143.143s %-23.23s %-11.11s %-15.15s %-59.59s %-23.23s %-11.11s %-15.15s %-11.11s %-23.23s %-11.11s %-15.15s %-63.63s %-63.63s %-51.51s %-23.23s %s\n\n" \
		"0:type"        \
		"1:entry_flag"  \
		"2:entry_name"  \
		"3:entry_disp"  \
		"4:version"     \
		"5:latest"      \
		"6:release"     \
		"7:support"     \
		"8:web_url"     \
		"9:web_tstamp"  \
		"10:web_size"   \
		"11:web_status" \
		"12:iso_path"   \
		"13:iso_tstamp" \
		"14:iso_size"   \
		"15:iso_volume" \
		"16:rmk_path"   \
		"17:rmk_tstamp" \
		"18:rmk_size"   \
		"19:rmk_volume" \
		"20:ldr_initrd" \
		"21:ldr_kernel" \
		"22:cfg_path"   \
		"23:cfg_tstamp" \
		"24:lnk_path"
	fi

	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		 	# --- data list -----------------------------------------------------------
		 	declare -a    DATA_LIST=(  \
		 		"${DATA_LIST_MINI[@]}" \
		 		"${DATA_LIST_NET[@]}"  \
		 		"${DATA_LIST_DVD[@]}"  \
		 		"${DATA_LIST_INST[@]}" \
		 		"${DATA_LIST_LIVE[@]}" \
		 		"${DATA_LIST_TOOL[@]}" \
		 		"${DATA_LIST_CSML[@]}" \
		 		"${DATA_LIST_CSMN[@]}" \
		 		"${DATA_LIST_SCMD[@]}" \
		 	)
		
		 	# --- target of creation --------------------------------------------------
		 	declare -a    TGET_LIST=()
		 	declare       TGET_INDX=""
_EOT_

#		if [[ -n "${_LIST[24]:-}" ]]; then
#			_DATA_NAME="$(echo "${_LIST[24]:-}")"
#			echo "1:${_LIST[24]/\$\{HGFS_DIRS\}/"${HGFS_DIRS:-}"}"
#			_DATA_NAME="$(eval echo "${_LIST[24]:-}")"
#			echo "2:${_WORK:-}"
#		fi
