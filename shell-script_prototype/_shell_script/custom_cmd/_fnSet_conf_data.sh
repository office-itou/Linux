# -----------------------------------------------------------------------------
# descript: set common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_CONF : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnSet_conf_data() {
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
	declare       __LINE=""				# work variable
	declare       __WORK=""				# work variables
	declare -i    I=0
	# --- data conversion -----------------------------------------------------
	for I in "${!_LIST_CONF[@]}"
	do
		__LINE="${_LIST_CONF[I]}"
		__LINE="${__LINE%%#*}"
		__LINE="${__LINE//["${IFS}"]/ }"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__NAME="${__LINE%%=*}"
		case "${__NAME:-}" in
			'' ) continue;;
			\#*) continue;;
			*  ) ;;
		esac
		__VALU="${__LINE#*=}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		[[ -z "${__VALU:-}" ]] && continue
		while true
		do
			__WORK="${__VALU%%_:*}"
			__WORK="${__WORK##*:_}"
			case "${__WORK:-}" in
				DIRS_*) ;;
				FILE_*) ;;
				*     ) break;;
			esac
			__VALU="${__VALU/:_${__WORK}_:/\$\{_${__WORK}\}}"
		done
		read -r "_${__NAME}" < <(eval echo "${__VALU}" || true)
	done
	for __NAME in "${!_@}"
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME:-}" in
			''        ) continue;;
			_DBGS_FAIL) continue;;
			_LIST_RMOV) continue;;
			_PATH_CONF) continue;;
			_PATH_DIST) continue;;
			_PATH_MDIA) continue;;
			_PATH_DSTP) continue;;
			_LIST_CONF) continue;;
			_LIST_DIST) continue;;
			_LIST_MDIA) continue;;
			_LIST_DSTP) continue;;
			_SRVR_HTTP) continue;;
			_SRVR_PROT) continue;;
			_SRVR_NICS) continue;;
			_SRVR_MADR) continue;;
			_SRVR_ADDR) continue;;
			_SRVR_CIDR) continue;;
			_SRVR_MASK) continue;;
			_SRVR_GWAY) continue;;
			_SRVR_NSVR) continue;;
			_SRVR_UADR) continue;;
			_[A-Za-z]*) ;;
			*         ) continue;;
		esac
		readonly "${__NAME}"
	done

#	_CONF_AGMA,_CONF_CLUD,_CONF_KICK,_CONF_SEDD,_CONF_SEDU,_CONF_YAST
#	_DBGS_FAIL,_DBGS_FLAG,_DBGS_LOGS,_DBGS_PARM,_DBGS_SIMU
#	_DIRS_CACH,_DIRS_CHRT,_DIRS_CONF,_DIRS_CTNR,_DIRS_CURR,_DIRS_DATA,_DIRS_HGFS,_DIRS_HTML,_DIRS_IMGS,_DIRS_ISOS,_DIRS_KEYS,_DIRS_LOAD,_DIRS_MKOS,_DIRS_RMAK,_DIRS_SAMB,_DIRS_SHAR,_DIRS_SHEL,_DIRS_TEMP,_DIRS_TFTP,_DIRS_TMPL,_DIRS_TOPS,_DIRS_USER,_DIRS_WTOP
#	_FILE_AGMA,_FILE_CLUD,_FILE_CONF,_FILE_DIST,_FILE_DSTP,_FILE_ERLY,_FILE_KICK,_FILE_LATE,_FILE_MDIA,_FILE_PART,_FILE_RUNS,_FILE_SEDD,_FILE_SEDU,_FILE_YAST
#	_IPV4_ADDR,_IPV4_CIDR,_IPV4_GWAY,_IPV4_MASK,_IPV4_NSVR,_IPV4_UADR
#	_LIST_CONF,_LIST_DIST,_LIST_DSTP,_LIST_MDIA,_LIST_RMOV
#	_MENU_DPTH,_MENU_MODE,_MENU_RESO,_MENU_SPLS,_MENU_TOUT
#	_NICS_MADR,_NICS_NAME,
#	_NMAN_NAME
#	_NTPS_ADDR,_NTPS_IPV4
#	_NWRK_HOST,_NWRK_WGRP
#	_PATH_CONF,_PATH_DIST,_PATH_DSTP,_PATH_MDIA
#	_PROG_DIRS,_PROG_NAME,_PROG_PARM,_PROG_PATH,_PROG_PROC
#	_SHEL_ERLY,_SHEL_LATE,_SHEL_PART,_SHEL_RUNS
#	_SIZE_COLS,_SIZE_ROWS
#	_SRVR_ADDR,_SRVR_CIDR,_SRVR_GWAY,_SRVR_HTTP,_SRVR_MADR,_SRVR_MASK,_SRVR_NICS,_SRVR_NSVR,_SRVR_PROT,_SRVR_UADR
#	_SUDO_HOME,_SUDO_USER
#	_TEXT_GAP1,_TEXT_GAP2,_TEXT_SPCE
#	_USER_NAME
}
