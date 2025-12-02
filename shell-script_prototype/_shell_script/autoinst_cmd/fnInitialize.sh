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
#   g-var : _TGET_VIRT : write
#   g-var : _DIRS_TOPS : write
#   g-var : _DIRS_HGFS : write
#   g-var : _DIRS_HTML : write
#   g-var : _DIRS_SAMB : write
#   g-var : _DIRS_TFTP : write
#   g-var : _DIRS_USER : write
#   g-var : _DIRS_PVAT : write
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
#   g-var : _DIRS_INST : write
#   g-var : _DIRS_BACK : write
#   g-var : _DIRS_ORIG : write
#   g-var : _DIRS_INIT : write
#   g-var : _DIRS_SAMP : write
#   g-var : _DIRS_LOGS : write
#   g-var : _SHEL_NLIN : write
# shellcheck disable=SC2148,SC2317,SC2329
fnInitialize() {
	__FUNC_NAME="fnInitialize"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

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

	_TEXT_GAP1="$(fnString "${_COLS_SIZE}" '-')"
	_TEXT_GAP2="$(fnString "${_COLS_SIZE}" '=')"
	readonly _TEXT_GAP1
	readonly _TEXT_GAP2

	if realpath "$(command -v cp 2> /dev/null || true)" | grep -q 'busybox'; then
		fnMsgout "${_PROG_NAME:-}" "info" "busybox"
		_COMD_BBOX="true"
		_OPTN_COPY="-p"
	fi

	# --- target virtualization -----------------------------------------------
	__WORK="$(fnTargetsys)"
	case "${__WORK##*,}" in
		offline) _TGET_CNTR="true";;
		*      ) _TGET_CNTR="";;
	esac
	readonly _TGET_CNTR
	readonly _TGET_VIRT="${__WORK%,*}"

	_DIRS_TGET=""
	for __DIRS in \
		/target \
		/mnt/sysimage \
		/mnt/
	do
		[ ! -e "${__DIRS}"/root/. ] && continue
		_DIRS_TGET="${__DIRS}"
		break
	done
	readonly _DIRS_TGET

	# --- system parameter ----------------------------------------------------
	fnSystem_param
	# --- network parameter ---------------------------------------------------
	fnNetwork_param
	# --- firewalld parameter -------------------------------------------------
	# --- shared directory parameter ------------------------------------------
	readonly _DIRS_TOPS="${_DIRS_TGET:-}/srv"			# top of shared directory
	readonly _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
	readonly _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
	readonly _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
	readonly _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	readonly _DIRS_USER="${_DIRS_TOPS}/user"			# user file
	readonly _DIRS_PVAT="${_DIRS_USER}/private"			# private contents directory
	readonly _DIRS_SHAR="${_DIRS_USER}/share"			# shared contents directory
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
	# --- working directory parameter -----------------------------------------
										# top of working directory
	_DIRS_INST="${_DIRS_VADM:?}/${_PROG_NAME%%_*}.$(date ${__time_start:+-d "@${__time_start}"} +"%Y%m%d%H%M%S")"
	readonly _DIRS_INST							# auto-install working directory
	readonly _DIRS_BACK="${_DIRS_INST}"			# top of backup directory
	readonly _DIRS_ORIG="${_DIRS_BACK}/orig"	# original file directory
	readonly _DIRS_INIT="${_DIRS_BACK}/init"	# initial file directory
	readonly _DIRS_SAMP="${_DIRS_BACK}/samp"	# sample file directory
	readonly _DIRS_LOGS="${_DIRS_BACK}/logs"	# log file directory
	mkdir -p "${_DIRS_TGET:-}${_DIRS_INST%.*}/"
	chmod 600 "${_DIRS_TGET:-}${_DIRS_VADM:?}"
	find "${_DIRS_TGET:-}${_DIRS_VADM:?}" -name "${_PROG_NAME%%_*}.[0-9]*" -type d | sort -rV | tail -n +3 | \
	while read -r __TGET
	do
		__PATH="${__TGET}.tgz"
		fnMsgout "${_PROG_NAME:-}" "archive" "[${__TGET}] -> [${__PATH}]"
		if tar -C "${__TGET}" -cf "${__PATH}" .; then
			chmod 600 "${__PATH}"
			fnMsgout "${_PROG_NAME:-}" "remove"  "${__TGET}"
			rm -rf "${__TGET:?}"
		fi
	done
	mkdir -p "${_DIRS_TGET:-}${_DIRS_INST:?}"
	chmod 600 "${_DIRS_TGET:-}${_DIRS_INST:?}"
	# --- samba ---------------------------------------------------------------
	_SHEL_NLIN="$(fnFind_command 'nologin' | sort -rV | head -n 1)"
	_SHEL_NLIN="${_SHEL_NLIN#*"${_DIRS_TGET:-}"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [ -e /usr/sbin/nologin ]; then echo "/usr/sbin/nologin"; fi)"}"
	_SHEL_NLIN="${_SHEL_NLIN:-"$(if [ -e /sbin/nologin     ]; then echo "/sbin/nologin"; fi)"}"
	readonly _SHEL_NLIN
	# --- auto install --------------------------------------------------------
	# --- debug backup---------------------------------------------------------
	fnFile_backup "/proc/cmdline"
	fnFile_backup "/proc/mounts"
	fnFile_backup "/proc/self/mounts"
	unset __COLS __WORK __DIRS __PATH __TGET

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset __FUNC_NAME
}
