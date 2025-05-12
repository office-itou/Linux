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

	declare -r    TABL_NAME="public.distribution"
	declare -a    TABL_LIST=()

	# --- read table data -----------------------------------------------------
	IFS= mapfile -d $'\n' -t TABL_LIST < "${1:?}"
	unset 'TABL_LIST[0]'
	TABL_LIST=("${TABL_LIST[@]}")
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
				0          ) _LIST[J]="'${_LIST[J]:?}'";;																								# NOT NULL
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
				INSERT INTO ${TABL_NAME:?}(version,name,version_id,code_name,life,release,support,long_term,rhel,kerne,note) VALUES ${_LINE}
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
						USING (VALUES (${_LIST[0]}))
							AS s(version)
							ON t.version = s.version
						WHEN MATCHED THEN
							UPDATE SET (version,name,version_id,code_name,life,release,support,long_term,rhel,kerne,note) = (${_LINE})
						WHEN NOT MATCHED THEN
							INSERT     (version,name,version_id,code_name,life,release,support,long_term,rhel,kerne,note) VALUES (${_LINE})
					;"; then
					echo "[${_LINE}]" > sql_error.txt
					exit 1
				fi
			done
			echo "complete"
			;;
	esac

# --- media information [new] -------------------------------------------------
#  0: version       ( 20)   TEXT           NOT NULL     
#  1: name          ( 16)   TEXT                        
#  2: version_id    ( 16)   TEXT                        
#  3: code_name     ( 20)   TEXT                        
#  4: life          ( 12)   TEXT                        
#  5: release       ( 12)   TEXT                        
#  6: support       ( 12)   TEXT                        
#  7: long_term     ( 12)   TEXT                        
#  8: rhel          ( 12)   TEXT                        
#  9: kerne         ( 24)   TEXT                        
# 10: note          ( 20)   TEXT                        
