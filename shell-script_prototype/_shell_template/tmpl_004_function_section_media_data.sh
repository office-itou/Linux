# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <media data> ============================================================

# -----------------------------------------------------------------------------
# descript: get media data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnGet_media_data() {
	declare       __PATH=""				# full path
	declare       __LINE=""				# work variable
	# --- list data -----------------------------------------------------------
	_LIST_MDIA=()
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_MDIA##*/}"}" \
		"${_PATH_MDIA}"
	do
		if [[ ! -s "${__PATH}" ]]; then
			continue
		fi
		while IFS=$'\n' read -r __LINE
		do
			__LINE="${__LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
			__LINE="${__LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
			__LINE="${__LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
			__LINE="${__LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
			__LINE="${__LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
			__LINE="${__LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
			__LINE="${__LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
			__LINE="${__LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
			__LINE="${__LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
			__LINE="${__LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
			__LINE="${__LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
			__LINE="${__LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
			__LINE="${__LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
			__LINE="${__LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
			__LINE="${__LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
			__LINE="${__LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
			__LINE="${__LINE//:_DIRS_CHRT_:/"${_DIRS_CHRT}"}"
			_LIST_MDIA+=("${__LINE}")
		done < "${__PATH:?}"
		if [[ -n "${_DBGS_FLAG:-}" ]]; then
			printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_MDIA[@]}" 1>&2
		fi
		break
	done
	if [[ -z "${_LIST_MDIA[*]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "data file not found: [${_PATH_MDIA}]" 1>&2
#		exit 1
	fi
}

# -----------------------------------------------------------------------------
# descript: put media data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnPut_media_data() {
	declare       __RNAM=""				# rename path
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare -i    I=0
#	declare -i    J=0
	# --- check file exists ---------------------------------------------------
	if [[ -f "${_PATH_MDIA:?}" ]]; then
		__RNAM="${_PATH_MDIA}.$(TZ=UTC find "${_PATH_MDIA}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		printf "%s: \"%s\"\n" "backup" "${__RNAM}" 1>&2
		cp -a "${_PATH_MDIA}" "${__RNAM}"
	fi
	# --- delete old files ----------------------------------------------------
	while read -r __PATH
	do
		printf "%s: \"%s\"\n" "remove" "${__PATH}" 1>&2
		rm -f "${__PATH:?}"
	done < <(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}.[0-9]*" | sort -r | tail -n +3  || true)
	# --- list data -----------------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		__LINE="${__LINE//"${_DIRS_CHRT}"/:_DIRS_CHRT_:}"
		__LINE="${__LINE//"${_DIRS_RMAK}"/:_DIRS_RMAK_:}"
		__LINE="${__LINE//"${_DIRS_LOAD}"/:_DIRS_LOAD_:}"
		__LINE="${__LINE//"${_DIRS_ISOS}"/:_DIRS_ISOS_:}"
		__LINE="${__LINE//"${_DIRS_IMGS}"/:_DIRS_IMGS_:}"
		__LINE="${__LINE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"
		__LINE="${__LINE//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"
		__LINE="${__LINE//"${_DIRS_KEYS}"/:_DIRS_KEYS_:}"
		__LINE="${__LINE//"${_DIRS_DATA}"/:_DIRS_DATA_:}"
		__LINE="${__LINE//"${_DIRS_CONF}"/:_DIRS_CONF_:}"
		__LINE="${__LINE//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"
		__LINE="${__LINE//"${_DIRS_USER}"/:_DIRS_USER_:}"
		__LINE="${__LINE//"${_DIRS_TFTP}"/:_DIRS_TFTP_:}"
		__LINE="${__LINE//"${_DIRS_SAMB}"/:_DIRS_SAMB_:}"
		__LINE="${__LINE//"${_DIRS_HTML}"/:_DIRS_HTML_:}"
		__LINE="${__LINE//"${_DIRS_HGFS}"/:_DIRS_HGFS_:}"
		__LINE="${__LINE//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"
		read -r -a __LIST < <(echo "${__LINE}")
#		for J in "${!__LIST[@]}"
#		do
#			__LIST[J]="${__LIST[J]:--}"		# empty
#			__LIST[J]="${__LIST[J]// /%20}"	# space
#		done
		printf "%-11s %-3s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-85s %-47s %-15s %-43s %-85s %-47s %-15s %-43s %-85s %-85s %-85s %-47s %-85s %-3s\n" \
			"${__LIST[@]}"
	done > "${_PATH_MDIA:?}"
}

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
