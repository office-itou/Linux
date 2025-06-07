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
	declare       _LINE=""
	declare -a    _LIST=()

	declare       _DATA_NAME=""
	declare       _DATA_NOTE=""

	declare       _WORK_GAPS=""
	              _WORK_GAPS="$(printf "%80s" '' | tr ' ' '-')"
	readonly      _WORK_GAPS
	declare       _WORK_TEXT=""

	declare -r    TABL_NAME="public.media"
	declare -a    TABL_LIST=()

	# --- read table data -----------------------------------------------------
	IFS= mapfile -d $'\n' -t TABL_LIST < "${1:?}"
#	unset 'TABL_LIST[0]'
#	TABL_LIST=("${TABL_LIST[@]}")
	for I in "${!TABL_LIST[@]}"
	do
		read -r -a _LIST < <(echo "${TABL_LIST[I]}")
#		case "${_LIST[1]}" in
#			m|o|-) ;;
#			*    ) unset 'TABL_LIST[I]'; continue;;
#		esac
		_LINE=""
		for J in "${!_LIST[@]}"
		do
			case "${J}" in
				[0-3]      ) _LIST[J]="'${_LIST[J]:?}'";;																								# NOT NULL
				10|14|18|24) _LIST[J]="${_LIST[J]/#xx:xx:xx/-}"; _WORK="${_LIST[J]/#-/}"; _LIST[J]="${_WORK:+"'"}${_LIST[J]/#-/"NULL"}${_WORK:+"'"}";;	# TIMESTAMP
				11|15|19   ) _LIST[J]="${_LIST[J]/#0/-}"       ; _WORK="${_LIST[J]/#-/}"; _LIST[J]="${_WORK:+"'"}${_LIST[J]/#-/"NULL"}${_WORK:+"'"}";;	# BIGINT
				*          ) _LIST[J]="'${_LIST[J]/#-/}'";;																								# TEXT
			esac
			_LIST[J]="${_LIST[J]//%20/ }"
			_LINE+="${_LINE:+", "}${_LIST[J]:?}"
		done
		TABL_LIST[I]="${_LINE}"
	done
	TABL_LIST=("${TABL_LIST[@]}")

	# --- Insert data into a table --------------------------------------------
	case "${2:-}" in
		-f|--force)	# force insert (re-create table)
			_LINE=""
			for I in "${!TABL_LIST[@]}"
			do
				_LINE+="${_LINE:+", "}(${TABL_LIST[I]})"
			done
			echo "create table and insert data"
			if ! psql --host=localhost --username=dbuser --quiet   --dbname=mydb --command="
				DELETE FROM ${TABL_NAME:?};
				INSERT INTO ${TABL_NAME:?}(type,entry_flag,entry_name,entry_disp,version,latest,release,support,web_regexp,web_path,web_tstamp,web_size,web_status,iso_path,iso_tstamp,iso_size,iso_volume,rmk_path,rmk_tstamp,rmk_size,rmk_volume,ldr_initrd,ldr_kernel,cfg_path,cfg_tstamp,lnk_path,create_flag) VALUES ${_LINE}
				;"; then
				echo "[${_LINE}]" > sql_error.txt
				exit 1
			fi
			echo "complete"
			;;
		*)			# insert or update
			echo "insert or update data"
			for I in "${!TABL_LIST[@]}"
			do
				_LINE="${TABL_LIST[I]}"
				IFS= mapfile -d ',' -t _LIST < <(echo -n "${_LINE}")
				_LIST=("${_LIST[@]/# /}")
				if ! psql --host=localhost --username=dbuser --quiet   --dbname=mydb --command="
					MERGE INTO ${TABL_NAME:?} AS t
						USING (VALUES (${_LIST[0]}, ${_LIST[1]}, ${_LIST[2]}, ${_LIST[3]}))
							AS s(type, entry_flag, entry_name, entry_disp)
							ON t.type = s.type
							AND t.entry_flag = s.entry_flag
							AND t.entry_name = s.entry_name
							AND t.entry_disp = s.entry_disp
						WHEN MATCHED THEN
							UPDATE SET (type,entry_flag,entry_name,entry_disp,version,latest,release,support,web_regexp,web_path,web_tstamp,web_size,web_status,iso_path,iso_tstamp,iso_size,iso_volume,rmk_path,rmk_tstamp,rmk_size,rmk_volume,ldr_initrd,ldr_kernel,cfg_path,cfg_tstamp,lnk_path,create_flag) = (${_LINE})
						WHEN NOT MATCHED THEN
							INSERT     (type,entry_flag,entry_name,entry_disp,version,latest,release,support,web_regexp,web_path,web_tstamp,web_size,web_status,iso_path,iso_tstamp,iso_size,iso_volume,rmk_path,rmk_tstamp,rmk_size,rmk_volume,ldr_initrd,ldr_kernel,cfg_path,cfg_tstamp,lnk_path,create_flag) VALUES (${_LINE})
					;"; then
					echo "[${_LINE}]" > sql_error.txt
					exit 1
				fi
			done
			echo "complete"
			;;
	esac

# --- media information [new] -------------------------------------------------
#  0: type          ( 11)   TEXT           NOT NULL     media type
#  1: entry_flag    (  3)   TEXT           NOT NULL     [m] menu, [o] output, [else] hidden
#  2: entry_name    ( 39)   TEXT           NOT NULL     entry name (unique)
#  3: entry_disp    ( 39)   TEXT           NOT NULL     entry name for display
#  4: version       ( 23)   TEXT                        version id
#  5: latest        ( 23)   TEXT                        latest version
#  6: release       ( 15)   TEXT                        release date
#  7: support       ( 15)   TEXT                        support end date
#  8: web_regexp    (143)   TEXT                        web file  regexp
#  9: web_path      (143)   TEXT                        "         path
# 10: web_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 11: web_size      ( 15)   BIGINT                      "         file size
# 12: web_status    ( 15)   TEXT                        "         download status
# 13: iso_path      ( 85)   TEXT                        iso image file path
# 14: iso_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT          "           file size
# 16: iso_volume    ( 43)   TEXT            "           volume id
# 17: rmk_path      ( 85)   TEXT            remaster    file path
# 18: rmk_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 85)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 85)   TEXT                        kernel    file path
# 23: cfg_path      ( 85)   TEXT                        config    file path
# 24: cfg_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 85)   TEXT                        symlink   directory or file path
# 26: create_flag   (  3)   TEXT                        create flag
