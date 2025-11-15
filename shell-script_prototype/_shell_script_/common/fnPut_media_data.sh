# -----------------------------------------------------------------------------
# descript: put media data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnPut_media_data() {
	declare       __TGET_PATH="${1:?}"	# target path
    declare       __NAME=""             # variable name
    declare       __VALU=""             # "        value
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare -i    I=0
	# --- file export ---------------------------------------------------------
	fnExec_backup "${__TGET_PATH:?}"
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		for __NAME in "${!_@}"
		do
			case "${__NAME:-}" in
				_DIRS_LIVE | \
				_FILE_LIVE ) ;;
				_DIRS_*    | \
				_FILE_*    )
					__VALU="${!__NAME:-}"
					__LINE="${__LINE//${__VALU}/:_${__NAME##_}_:}"
					;;
				*          ) ;;
			esac
		done
		read -r -a __LIST < <(echo "${__LINE}")
		printf -v _LIST_MDIA[I] "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s " \
			"${__LIST[@]}"
	done
	printf "%s\n" "${_LIST_MDIA[@]}" > "${__TGET_PATH}"
}
# --- media information (media.dat) -------------------------------------------
#  0: type          ( 11)   TEXT           NOT NULL     media type
#  1: entry_flag    ( 11)   TEXT           NOT NULL     [m] menu, [o] output, [else] hidden
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
# 13: iso_path      ( 87)   TEXT                        iso image file path
# 14: iso_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT                      "         file size
# 16: iso_volume    ( 43)   TEXT                        "         volume id
# 17: rmk_path      ( 87)   TEXT                        remaster  file path
# 18: rmk_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 87)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 87)   TEXT                        kernel    file path
# 23: cfg_path      ( 87)   TEXT                        config    file path
# 24: cfg_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 87)   TEXT                        symlink   directory or file path
# 26: create_flag   ( 11)   TEXT                        create flag
# -----------------------------------------------------------------------------
