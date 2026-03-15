#!/bin/bash

	# --- include -------------------------------------------------------------
	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
#	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)
	declare       _DBGS_PARM=""			# debug flag (empty: normal, else: debug out parameter)

	# --- working directory ---------------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -a    _PROG_PARM=()
	IFS= mapfile -d $'\n' -t _PROG_PARM < <(printf "%s\n" "${@:-}" || true)
	readonly      _PROG_PARM
	declare       _PROG_DIRS="${_PROG_PATH%/*}"
	              _PROG_DIRS="$(realpath "${_PROG_DIRS%/}")"
	readonly      _PROG_DIRS
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
#	declare -r    _PROG_PROC="${_PROG_NAME}.$$"

	# --- user data -----------------------------------------------------------
	declare -r    _USER_NAME="${USER:-"${LOGNAME:-"$(whoami || true)"}"}"		# execution user name
	declare -r    _SUDO_USER="${SUDO_USER:-"${_USER_NAME}"}"					# real user name
																				# "         home directory
	declare -r    _SUDO_HOME="${SUDO_HOME:-"$(eval echo "~${SUDO_USER:-"${USER:?}"}")"}"

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:-}" != "root" ]]; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "run as root user."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "your username is ${_USER_NAME}."
		exit 1
	fi

	# --- check the command ---------------------------------------------------
	__COMD="gawk"
	if ! command -v "${__COMD}" > /dev/null 2>&1; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "${__COMD} is not installed."
		exit 1
	fi

	# --- working directory ---------------------------------------------------
	declare -r    _DIRS_WTOP="${_SUDO_HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
	mkdir -p   "${_DIRS_WTOP}"
	chown "${_SUDO_USER:?}": "${_DIRS_WTOP}"

	# --- temporary directory -------------------------------------------------
	declare       _DIRS_TEMP="${_DIRS_WTOP}"
	              _DIRS_TEMP="$(mktemp -qd "${_DIRS_TEMP}/${_PROG_NAME}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap list -----------------------------------------------------------
	trap fnTrap EXIT

	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- shared directory parameter ------------------------------------------
	declare -r    _DIRS_TOPS="/srv"							# top of shared directory
	declare -r    _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
	declare -r    _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents
	declare -r    _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
	declare -r    _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	declare -r    _DIRS_USER="${_DIRS_TOPS}/user"			# user file

	# --- shared of user file -------------------------------------------------
	declare -r    _DIRS_PVAT="${_DIRS_USER}/private"		# private contents directory
	declare -r    _DIRS_SHAR="${_DIRS_USER}/share"			# shared of user file
	declare -r    _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
	declare -r    _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
	declare -r    _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
	declare -r    _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
	declare -r    _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
	declare -r    _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
	declare -r    _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
	declare -r    _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
	declare -r    _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
	declare -r    _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
	declare -r    _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file
	declare -r    _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
	declare -r    _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file (chroot)

	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_VADM="/var/admin"					# top of admin working directory
	declare       _DIRS_INST=""								# auto-install working directory
	declare       _DIRS_BACK=""								# top of backup directory
	declare       _DIRS_ORIG=""								# original file directory
	declare       _DIRS_INIT=""								# initial file directory
	declare       _DIRS_SAMP=""								# sample file directory
	declare       _DIRS_LOGS=""								# log file directory

	# --- common data file (prefer non-empty current file) --------------------
	declare -r    _FILE_CONF="common.cfg"					# common configuration file
	declare -r    _FILE_DIST="distribution.dat"				# distribution data file
	declare -r    _FILE_MDIA="media.dat"					# media data file
	declare -r    _FILE_DSTP="debstrap.dat"					# debstrap data file

	# --- common data file (prefer non-empty current file) --------------------
	declare -r    _PATH_CONF="${_DIRS_DATA}/${_FILE_CONF}"	# common configuration file
	declare -r    _PATH_DIST="${_DIRS_DATA}/${_FILE_DIST}"	# distribution data file
	declare -r    _PATH_MDIA="${_DIRS_DATA}/${_FILE_MDIA}"	# media data file
	declare -r    _PATH_DSTP="${_DIRS_DATA}/${_FILE_DSTP}"	# debstrap data file

# -----------------------------------------------------------------------------
# descript: trap
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
# shellcheck disable=SC2329,SC2317
function fnTrap() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PATH=""				# full path
	declare       __MPNT=""				# mount point
	declare -i    I=0

	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	if [[ "${#_DBGS_FAIL[@]}" -gt 0 ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "${_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]}"
		fnMsgout "${_PROG_NAME:-}" "failed" "Working files will be deleted when this shell exits."
		read -r -p "Press enter key to exit..."
	fi

	_LIST_RMOV=("${_LIST_RMOV[@]}")
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
		if mountpoint --quiet "${__PATH}"; then
			fnMsgout "${_PROG_NAME:-}" "umount" "${__PATH}"
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}"
		fi
		case "${__PATH}" in
			"${_DIRS_TEMP:?}")
				fnMsgout "${_PROG_NAME:-}" "remove" "${__PATH}"
				rm -rf "${__PATH:?}"
				;;
			*) ;;
		esac
	done
	unset __PATH __MPNT I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	fnDbgparameters
#	unset __FUNC_NAME
}

# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : title (program name, etc)
#   input :     $2     : section (start, complete, remove, umount, failed, ...)
#   input :     $3     : message
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnMsgout() {
	case "${2:-}" in
		start    | complete)
			case "${3:-}" in
				*/*/*) printf "\033[m${1:-}\033[m: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}\033[m:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		active             ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		inactive           ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		caution            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}\033[m:     \033[36m%-8.8s: %s\033[m\n"        "${2#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}\033[m: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}\033[m: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}\033[m: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}\033[m: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
	esac
}

function fnDbgparameters() {
	:
}

function fnOutput_json() {
	declare -r    __PATH="${1:?}"
	declare -r    __JSON="./${__PATH##*/}.json"
	declare       __LINE=""
	declare -a    __LIST=()
	declare -a    __HEAD=()
	declare       __DATA=""
	declare       __WORK=""

	echo "start   :${__JSON}"
	: > "${__JSON}"
	{
#		printf "%s\n" "{"
#		printf "%s\n" "  \"${__PATH##*/}\": ["
		printf "%s\n" "["
	} >> "${__JSON}"

	__HEAD=()
	__DATA=""
	while read -r __LINE
	do
		read -r -a __LIST < <(echo "${__LINE:-}")
		if [[ -z "${__HEAD[*]}" ]]; then
			__HEAD=("${__LIST[@]}")
			continue
		fi
		__WORK=""
		for I in "${!__HEAD[@]}"
		do
			__WORK="${__WORK:+"${__WORK},"}\"${__HEAD[I]}\":\"${__LIST[I]}\""
		done
		__WORK="${__WORK//%20/ }"
		__WORK="${__WORK//\"-\"/\"\"}"
		__WORK="  {${__WORK}}"
		if [[ -n "${__DATA:-}" ]]; then
			__DATA="${__DATA},"$'\n'
		fi
		__DATA="${__DATA:-}${__WORK}"
	done < "${__PATH}"

	{
		printf "%s\n" "${__DATA}"
		printf "%s\n" "]"
#		printf "%s\n" "  ]"
#		printf "%s\n" "}"
	} >> "${__JSON}"
	echo "complete:${__JSON}"
}

fnOutput_json "${_PATH_DIST}"			# distribution data file
fnOutput_json "${_PATH_MDIA}"			# media data file
fnOutput_json "/srv/hgfs/linux/script/work.txt"