# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: initialize
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : TERM       : read
#   g-var : _ROWS_SIZE : write
#   g-var : _COLS_SIZE : write
#   g-var : _TEXT_GAP1 : write
#   g-var : _TEXT_GAP2 : write
#   g-var : _TGET_VIRT : read
#   g-var : _DIST_NAME : read
#   g-var : _DIST_VERS : read
#   g-var : _DIST_CODE : read
#   g-var : _NICS_NAME : read
#   g-var : _NICS_MADR : read
#   g-var : _NICS_IPV4 : read
#   g-var : _NICS_MASK : read
#   g-var : _NICS_BIT4 : read
#   g-var : _NICS_DNS4 : read
#   g-var : _NICS_GATE : read
#   g-var : _NICS_FQDN : read
#   g-var : _NICS_HOST : read
#   g-var : _NICS_WGRP : read
#   g-var : _NMAN_FLAG : read
#   g-var : _NTPS_ADDR : read
#   g-var : _NTPS_IPV4 : read
#   g-var : _IPV6_LHST : read
#   g-var : _IPV4_LHST : read
#   g-var : _IPV4_DUMY : read
#   g-var : _IPV4_UADR : read
#   g-var : _IPV4_LADR : read
#   g-var : _IPV6_ADDR : read
#   g-var : _IPV6_CIDR : read
#   g-var : _IPV6_FADR : read
#   g-var : _IPV6_UADR : read
#   g-var : _IPV6_LADR : read
#   g-var : _IPV6_RADR : read
#   g-var : _LINK_ADDR : read
#   g-var : _LINK_CIDR : read
#   g-var : _LINK_FADR : read
#   g-var : _LINK_UADR : read
#   g-var : _LINK_LADR : read
#   g-var : _LINK_RADR : read
#   g-var : _FWAL_ZONE : read
#   g-var : _FWAL_NAME : read
#   g-var : _FWAL_PORT : read
#   g-var : _DIRS_TOPS : write
#   g-var : _DIRS_HGFS : write
#   g-var : _DIRS_HTML : write
#   g-var : _DIRS_SAMB : write
#   g-var : _DIRS_TFTP : write
#   g-var : _DIRS_USER : write
#   g-var : _DIRS_SHAR : write
#   g-var : _DIRS_CONF : write
#   g-var : _DIRS_DATA : write
#   g-var : _DIRS_KEYS : write
#   g-var : _DIRS_MKOS : write
#   g-var : _DIRS_TMPL : write
#   g-var : _DIRS_SHEL : write
#   g-var : _DIRS_IMGS : write
#   g-var : _DIRS_ISOS : write
#   g-var : _DIRS_LOAD : write
#   g-var : _DIRS_RMAK : write
#   g-var : _DIRS_CACH : write
#   g-var : _DIRS_CTNR : write
#   g-var : _DIRS_CHRT : write
#   g-var : _DIRS_ORIG : read
#   g-var : _DIRS_INIT : read
#   g-var : _DIRS_SAMP : read
#   g-var : _DIRS_LOGS : read
#   g-var : _SAMB_USER : read
#   g-var : _SAMB_GRUP : read
#   g-var : _SAMB_GADM : read
#   g-var : _SHEL_NLIN : read
# shellcheck disable=SC2148,SC2317,SC2329
fnInitialize() {
	__FUNC_NAME="fnInitialize"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- set system parameter ------------------------------------------------
	if [ -n "${TERM:-}" ] \
	&& command -v tput > /dev/null 2>&1; then
		_ROWS_SIZE=$(tput lines || true)
		_COLS_SIZE=$(tput cols  || true)
	fi
	[ "${_ROWS_SIZE:-"0"}" -lt 25 ] && _ROWS_SIZE=25
	[ "${_COLS_SIZE:-"0"}" -lt 80 ] && _COLS_SIZE=80
	readonly _ROWS_SIZE
	readonly _COLS_SIZE

	_TEXT_GAP1="$(fnString "$((_COLS_SIZE-${#_PROG_NAME}-16))" '-')"
	_TEXT_GAP2="$(fnString "$((_COLS_SIZE-${#_PROG_NAME}-16))" '=')"
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	# --- target virtualization -----------------------------------------------
	fnDetect_virt

	# --- system parameter ----------------------------------------------------
	fnSystem_param
	fnDbgout "system parameter" \
		"info,_TGET_VIRT=[${_TGET_VIRT:-}]" \
		"info,_DIRS_TGET=[${_DIRS_TGET:-}]" \
		"info,_DIST_NAME=[${_DIST_NAME:-}]" \
		"info,_DIST_VERS=[${_DIST_VERS:-}]" \
		"info,_DIST_CODE=[${_DIST_CODE:-}]"

	# --- network parameter ---------------------------------------------------
	fnNetwork_param
	fnDbgout "network info" \
		"info,_NICS_NAME=[${_NICS_NAME:-}]" \
		"debug,_NICS_MADR=[${_NICS_MADR:-}]" \
		"info,_NICS_IPV4=[${_NICS_IPV4:-}]" \
		"info,_NICS_MASK=[${_NICS_MASK:-}]" \
		"info,_NICS_BIT4=[${_NICS_BIT4:-}]" \
		"info,_NICS_DNS4=[${_NICS_DNS4:-}]" \
		"info,_NICS_GATE=[${_NICS_GATE:-}]" \
		"info,_NICS_FQDN=[${_NICS_FQDN:-}]" \
		"debug,_NICS_HOST=[${_NICS_HOST:-}]" \
		"debug,_NICS_WGRP=[${_NICS_WGRP:-}]" \
		"debug,_NMAN_FLAG=[${_NMAN_FLAG:-}]" \
		"info,_NTPS_ADDR=[${_NTPS_ADDR:-}]" \
		"debug,_NTPS_IPV4=[${_NTPS_IPV4:-}]" \
		"debug,_IPV6_LHST=[${_IPV6_LHST:-}]" \
		"debug,_IPV4_LHST=[${_IPV4_LHST:-}]" \
		"debug,_IPV4_DUMY=[${_IPV4_DUMY:-}]" \
		"debug,_IPV4_UADR=[${_IPV4_UADR:-}]" \
		"debug,_IPV4_LADR=[${_IPV4_LADR:-}]" \
		"debug,_IPV6_ADDR=[${_IPV6_ADDR:-}]" \
		"debug,_IPV6_CIDR=[${_IPV6_CIDR:-}]" \
		"debug,_IPV6_FADR=[${_IPV6_FADR:-}]" \
		"debug,_IPV6_UADR=[${_IPV6_UADR:-}]" \
		"debug,_IPV6_LADR=[${_IPV6_LADR:-}]" \
		"debug,_IPV6_RADR=[${_IPV6_RADR:-}]" \
		"debug,_LINK_ADDR=[${_LINK_ADDR:-}]" \
		"debug,_LINK_CIDR=[${_LINK_CIDR:-}]" \
		"debug,_LINK_FADR=[${_LINK_FADR:-}]" \
		"debug,_LINK_UADR=[${_LINK_UADR:-}]" \
		"debug,_LINK_LADR=[${_LINK_LADR:-}]" \
		"debug,_LINK_RADR=[${_LINK_RADR:-}]"

	# --- firewalld parameter -------------------------------------------------
	fnDbgout "firewalld info" \
		"info,_FWAL_ZONE=[${_FWAL_ZONE:-}]" \
		"debug,_FWAL_NAME=[${_FWAL_NAME:-}]" \
		"debug,_FWAL_PORT=[${_FWAL_PORT:-}]"

	# --- shared directory parameter ------------------------------------------
	readonly _DIRS_TOPS="${_DIRS_TGET:-}/srv"			# top of shared directory
	readonly _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
	readonly _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
	readonly _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
	readonly _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	readonly _DIRS_USER="${_DIRS_TOPS}/user"			# user file
	readonly _DIRS_SHAR="${_DIRS_USER}/share"			# shared of user file
	readonly _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
	readonly _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
	readonly _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
	readonly _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
	readonly _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
	readonly _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
	readonly _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
	readonly _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
	readonly _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
	readonly _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
	readonly _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file
	readonly _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
	readonly _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file (chroot)
	fnDbgout "shared directory" \
		"info,_DIRS_TOPS=[${_DIRS_TOPS:-}]" \
		"debug,_DIRS_HGFS=[${_DIRS_HGFS:-}]" \
		"debug,_DIRS_HTML=[${_DIRS_HTML:-}]" \
		"debug,_DIRS_SAMB=[${_DIRS_SAMB:-}]" \
		"debug,_DIRS_TFTP=[${_DIRS_TFTP:-}]" \
		"debug,_DIRS_USER=[${_DIRS_USER:-}]" \
		"debug,_DIRS_SHAR=[${_DIRS_SHAR:-}]" \
		"debug,_DIRS_CONF=[${_DIRS_CONF:-}]" \
		"debug,_DIRS_DATA=[${_DIRS_DATA:-}]" \
		"debug,_DIRS_KEYS=[${_DIRS_KEYS:-}]" \
		"debug,_DIRS_MKOS=[${_DIRS_MKOS:-}]" \
		"debug,_DIRS_TMPL=[${_DIRS_TMPL:-}]" \
		"debug,_DIRS_SHEL=[${_DIRS_SHEL:-}]" \
		"debug,_DIRS_IMGS=[${_DIRS_IMGS:-}]" \
		"debug,_DIRS_ISOS=[${_DIRS_ISOS:-}]" \
		"debug,_DIRS_LOAD=[${_DIRS_LOAD:-}]" \
		"debug,_DIRS_RMAK=[${_DIRS_RMAK:-}]" \
		"debug,_DIRS_CACH=[${_DIRS_CACH:-}]" \
		"debug,_DIRS_CTNR=[${_DIRS_CTNR:-}]" \
		"debug,_DIRS_CHRT=[${_DIRS_CHRT:-}]"

	# --- working directory parameter -----------------------------------------
										# top of working directory
	_DIRS_BACK="${_DIRS_TGET:-}/var/adm/${_PROG_NAME%%_*}.$(date ${__time_start:+"-d @${__time_start}"} +"%Y%m%d%H%M%S")"
	readonly _DIRS_BACK
	readonly _DIRS_ORIG="${_DIRS_BACK}/orig"	# original file directory
	readonly _DIRS_INIT="${_DIRS_BACK}/init"	# initial file directory
	readonly _DIRS_SAMP="${_DIRS_BACK}/samp"	# sample file directory
	readonly _DIRS_LOGS="${_DIRS_BACK}/logs"	# log file directory
	fnDbgout "working directory" \
		"debug,_DIRS_ORIG=[${_DIRS_ORIG:-}]" \
		"debug,_DIRS_INIT=[${_DIRS_INIT:-}]" \
		"debug,_DIRS_SAMP=[${_DIRS_SAMP:-}]" \
		"debug,_DIRS_LOGS=[${_DIRS_LOGS:-}]" \

	# --- samba ---------------------------------------------------------------
	fnDbgout "samba info" \
		"debug,_SAMB_USER=[${_SAMB_USER:-}]" \
		"debug,_SAMB_GRUP=[${_SAMB_GRUP:-}]" \
		"debug,_SAMB_GADM=[${_SAMB_GADM:-}]" \
		"debug,_SHEL_NLIN=[${_SHEL_NLIN:-}]"

	# --- debug backup---------------------------------------------------------
	__DIRS="${_DIRS_BACK##*/}"
	__DIRS="${__DIRS%%.[0-9]*}"
	find "${_DIRS_BACK%/*}" -name "${_PROG_NAME%%_*}.[0-9]*" -type d | sort -r | tail -n +3 | \
	while read -r __TGET
	do
		__PATH="${__TGET}.tgz"
		fnMsgout "archive" "[${__TGET}] -> [${__PATH}]"
		if tar -C "${__TGET}" -czf "${__PATH}" .; then
			chmod 600 "${__PATH}"
			fnMsgout "remove"  "${__TGET}"
			rm -rf "${__TGET:?}"
		fi
	done
	fnFile_backup "/proc/cmdline"
	fnFile_backup "/proc/mounts"
	fnFile_backup "/proc/self/mounts"

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
}
