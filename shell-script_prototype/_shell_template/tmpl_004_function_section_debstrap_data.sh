# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <debstrap data> =========================================================

# -----------------------------------------------------------------------------
# descript: get debstrap data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnGet_debstrap_data() {
	declare       __PATH=""				# full path
	declare       __LINE=""				# work variable
	# --- list data -----------------------------------------------------------
	_LIST_DSTP=()
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_DSTP##*/}"}" \
		"${_PATH_DSTP}"
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
			_LIST_DSTP+=("${__LINE}")
		done < "${__PATH:?}"
		if [[ -n "${_DBGS_FLAG:-}" ]]; then
			printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_DSTP[@]}" 1>&2
		fi
		break
	done
	if [[ -z "${_LIST_DSTP[*]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "data file not found: [${_PATH_DSTP}]" 1>&2
#		exit 1
	fi
}
