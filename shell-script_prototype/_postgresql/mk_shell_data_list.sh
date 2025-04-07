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
		 	#  8: web_regexp    (143)   web file  regexp
		 	#  9: web_path      (143)   "         path
		 	# 10: web_tstamp    ( 27)   "         time stamp
		 	# 11: web_size      ( 15)   "         file size
		 	# 12: web_status    ( 15)   "         download status
		 	# 13: iso_path      ( 71)   iso image file path
		 	# 14: iso_tstamp    ( 27)   "         time stamp
		 	# 15: iso_size      ( 15)   "         file size
		 	# 16: iso_volume    ( 43)   "         volume id
		 	# 17: rmk_path      ( 71)   remaster  file path
		 	# 18: rmk_tstamp    ( 27)   "         time stamp
		 	# 19: rmk_size      ( 15)   "         file size
		 	# 20: rmk_volume    ( 43)   "         volume id
		 	# 21: ldr_initrd    ( 71)   initrd    file path
		 	# 22: ldr_kernel    ( 71)   kernel    file path
		 	# 23: cfg_path      ( 71)   config    file path
		 	# 24: cfg_tstamp    ( 27)   "         time stamp
		 	# 25: lnk_path      ( 71)   symlink   directory or file path
		
_EOT_

	declare -a _LINE=()

	while IFS= read -r -d $'\n' _LINE
	do
		IFS= mapfile -d '|' -t _LIST < <(echo -n "${_LINE// /%20}")
		if [[ "${_FLAG:-"${_LIST[0]:-}"}" != "${_LIST[0]:-}" ]]; then
			_FLAG=""
			printf "\t)  # %-14s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-27s %-15s %-15s %-71s %-27s %-15s %-43s %-71s %-27s %-15s %-43s %-71s %-71s %-71s %-27s %s\n\n" \
			"0:type"        \
			"1:entry_flag"  \
			"2:entry_name"  \
			"3:entry_disp"  \
			"4:version"     \
			"5:latest"      \
			"6:release"     \
			"7:support"     \
			"8:web_regexp"  \
			"9:web_path"    \
			"10:web_tstamp"  \
			"11:web_size"   \
			"12:web_status" \
			"13:iso_path"   \
			"14:iso_tstamp" \
			"15:iso_size"   \
			"16:iso_volume" \
			"17:rmk_path"   \
			"18:rmk_tstamp" \
			"19:rmk_size"   \
			"20:rmk_volume" \
			"21:ldr_initrd" \
			"22:ldr_kernel" \
			"23:cfg_path"   \
			"24:cfg_tstamp" \
			"25:lnk_path"
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
			printf "\tdeclare -r -a %-1166.1166s\t\\\\\n" "${_DATA_NAME:-}=("
		fi
		printf "\t\t'%-14s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-27s %-15s %-15s %-71s %-27s %-15s %-43s %-71s %-27s %-15s %-43s %-71s %-71s %-71s %-27s %-71s'\t\\\\\n" \
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
		"${_LIST[24]:--}" \
		"${_LIST[25]:--}"
	done < <(psql -qtAX --dbname=mydb --command="
SELECT
    public.media.type
    , public.media.entry_flag
    , public.media.entry_name
    , public.media.entry_disp
    , public.media.version
    , public.media.latest
    , public.media.release
    , public.media.support
    , public.media.web_regexp
    , public.media.web_path
    , public.media.web_tstamp
    , public.media.web_size
    , public.media.web_status
    , public.media.iso_path
    , public.media.iso_tstamp
    , public.media.iso_size
    , public.media.iso_volume
    , public.media.rmk_path
    , public.media.rmk_tstamp
    , public.media.rmk_size
    , public.media.rmk_volume
    , public.media.ldr_initrd
    , public.media.ldr_kernel
    , public.media.cfg_path
    , public.media.cfg_tstamp
    , public.media.lnk_path 
FROM
    public.media 
WHERE
    public.media.entry_flag != 'x' 
    AND public.media.entry_flag != 'd' 
    AND public.media.entry_flag != 'b' 
ORDER BY
    public.media.type = 'mini.iso' DESC
    , public.media.type = 'netinst' DESC
    , public.media.type = 'dvd' DESC
    , public.media.type = 'live_install' DESC
    , public.media.type = 'live' DESC
    , public.media.type = 'tool' DESC
    , public.media.type = 'custom_live' DESC
    , public.media.type = 'custom_netinst' DESC
    , public.media.type = 'system' DESC
    , public.media.entry_disp != '-' DESC
    , public.media.version = 'menu-entry' DESC
    , public.media.version ~ 'debian-*' DESC
    , public.media.version ~ 'ubuntu-*' DESC
    , public.media.version ~ 'fedora-*' DESC
    , public.media.version ~ 'centos-stream-*' DESC
    , public.media.version ~ 'almalinux-*' DESC
    , public.media.version ~ 'rockylinux-*' DESC
    , public.media.version ~ 'miraclelinux-*' DESC
    , public.media.version ~ 'opensuse-*' DESC
    , public.media.version ~ 'windows-*' DESC
    , public.media.version = 'memtest86plus' DESC
    , public.media.version = 'winpe-x86' DESC
    , public.media.version = 'winpe-x64' DESC
    , public.media.version = 'ati2020x86' DESC
    , public.media.version = 'ati2020x64' DESC
    , public.media.version ~ '.*-sid'
    , public.media.version ~ '.*-testing'
    , public.media.version
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 3), 3, '0')
;" || true)

	if [[ -n "${_FLAG:-}" ]]; then
		printf "\t)  # %-14.14s %-15.15s %-39.39s %-39.39s %-23.23s %-23.23s %-15.15s %-15.15s %-143.143s %-143.143s %-27.27s %-15.15s %-15.15s %-71.71s %-27.27s %-15.15s %-43.43s %-71.71s %-27.27s %-15.15s %-43.43s %-71.71s %-71.71s %-71.71s %-27.27s %s\n\n" \
		"0:type"        \
		"1:entry_flag"  \
		"2:entry_name"  \
		"3:entry_disp"  \
		"4:version"     \
		"5:latest"      \
		"6:release"     \
		"7:support"     \
		"8:web_regexp"  \
		"9:web_path"    \
		"10:web_tstamp"  \
		"11:web_size"   \
		"12:web_status" \
		"13:iso_path"   \
		"14:iso_tstamp" \
		"15:iso_size"   \
		"16:iso_volume" \
		"17:rmk_path"   \
		"18:rmk_tstamp" \
		"19:rmk_size"   \
		"20:rmk_volume" \
		"21:ldr_initrd" \
		"22:ldr_kernel" \
		"23:cfg_path"   \
		"24:cfg_tstamp" \
		"25:lnk_path"
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

	exit
