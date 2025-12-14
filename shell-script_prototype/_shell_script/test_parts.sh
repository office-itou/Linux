#!/bin/bash

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

# *** global section **********************************************************

	# --- include -------------------------------------------------------------
	declare -r    _SHEL_PATH="${0:?}"
	declare -r    _SHEL_TOPS="${_SHEL_PATH%/*}"
	declare -r    _SHEL_COMN="${_SHEL_TOPS:-}/_common_bash"
	declare -r    _SHEL_COMD="${_SHEL_TOPS:-}/custom_cmd"
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnSystem_common.sh				# global variables (for system)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_variables.sh			# global variables (for basic)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnGlobal_common.sh				# global variables (for application)

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnTrim.sh						# ltrim/rtrim/trim
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnBasename.sh					# dirname/basename
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnMsgout.sh						# message output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnString.sh						# string output
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnStrmsg.sh						# string output with message
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnTargetsys.sh					# target system state
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6FullAddr.sh				# IPv6 full address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv6RevAddr.sh					# IPv6 reverse address
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnIPv4Netmask.sh					# IPv4 netmask conversion
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnGetWebinfo.sh					# get web information data
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnGetFileinfo.sh					# get file information data

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgout.sh						# message output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgdump.sh						# dump output (debug out)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparam.sh					# parameter debug output
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparameters.sh				# print out of internal variables
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDbgparameters_all.sh			# Print all global variables (_[A..Z]*)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFind_command.sh				# find command
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFind_service.sh				# find service
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnSystem_param.sh				# get system parameter
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnNetwork_param.sh				# get network parameter
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnFile_backup.sh					# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnTrap.sh						# trap
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnInitialize.sh					# initialize
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnList_conf_Set.sh				# set default common configuration data
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnList_conf_Enc.sh				# encoding common configuration data
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnList_conf_Dec.sh				# decoding common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnList_conf_Get.sh				# get auto-installation configuration file
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnList_conf_Put.sh				# put common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnList_mdia_Get.sh				# get media information data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnList_mdia_Put.sh				# put media information data
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnList_mdia_Dec.sh				# decoding common configuration data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_symlink_dir.sh				# make directory
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_symlink.sh					# make symlink
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf_preseed.sh			# make preseed.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf_nocloud.sh			# make nocloud
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf_kickstart.sh		# make kickstart.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf_autoyast.sh			# make autoyast.xml
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf_agama.sh			# make autoinst.json
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_preconf.sh					# make preconfiguration files
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot.sh					# make pxeboot files
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnCopy_iso.sh					# copy iso files
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_isofile.sh					# make iso files
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnSelect_target.sh				# select target
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnScreen_output.sh				# screen output

# *** main section ************************************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnHelp_mk_custom_iso.sh			# help
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMain_mk_custom_iso.sh			# main routine

	# --- help / debug --------------------------------------------------------
	[[ -z "${_PROG_PARM[*]:-}" ]] && fnHelp
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			-h|--help             ) fnHelp;;
			-D|--debug   |--dbg   ) _DBGS_FLAG="true"; set -x;;
			-O|--debugout|--dbgout) _DBGS_FLAG="true";;
			*                     ) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [[ -n "${_DBGS_FLAG:-}" ]]; then
		fnDbgout "command line" \
			"debug,_COMD_LINE=[${_COMD_LINE:-}]"
	fi

	# --- start ---------------------------------------------------------------
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0

	__time_start=$(date +%s)
	fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- main processing -----------------------------------------------------
	fnInitialize

#printf "%s\n" "${_LIST_CONF[@]}"
#printf "%s\n" "${_LIST_PARM[@]}"

#fnList_conf_Put "test.cfg"
#sleep 600

	declare       __REFR=""				# name reference
	declare       __PTRN=""				# pattern
	declare -a    __LIST=()				# list

time	for __TYPE in "${_LIST_TYPE[@]}"
	do
		IFS= mapfile -d $'\n' -t __TGET < <(\
			printf "%s\n" "${_LIST_MDIA[@]}" | \
			awk -v type="${__TYPE}" '$1==type && $2=="o" {print FNR-1, $0;}' \
		)
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			__MDIA=("${__MDIA[@]//%20/ }")
			# --- web file ----------------------------------------------------
			if [[ -n "$(fnTrim "${__MDIA[9]}" "-")" ]]; then
				__RETN="$(fnGetWebinfo "${__MDIA[9]}")"
				read -r -a __LIST < <(echo "${__RETN}")
				__MDIA[10]="${__LIST[0]}"	# web_path
				__MDIA[11]="${__LIST[3]}"	# web_tstamp
				__MDIA[12]="${__LIST[2]}"	# web_size
				__MDIA[13]="${__LIST[1]}"	# web_status
				case "${__MDIA[13]}" in
					2[0-9][0-9])
						__FILE="$(fnBasename "${__MDIA[10]}")"
						if [[ -n "${__FILE:-}" ]]; then
							case "${__FILE}" in
								mini.iso) ;;
								*       )
									__DIRS="$(fnDirname "${__MDIA[14]}")"
									__MDIA[14]="${__DIRS:-}/${__FILE}"	# iso_path
									;;
							esac
						fi
						;;
					*) ;;
				esac
			fi
			# --- iso file ----------------------------------------------------
			if [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]]; then
				__RETN="$(fnGetFileinfo "${__MDIA[14]}")"
				read -r -a __LIST < <(echo "${__RETN}")
				__MDIA[15]="${__LIST[1]:-}"	# iso_tstamp
				__MDIA[16]="${__LIST[2]:-}"	# iso_size
				__MDIA[17]="${__LIST[3]:-}"	# iso_volume
			fi
			# --- rmk file ----------------------------------------------------
			if [[ -n "$(fnTrim "${__MDIA[18]}" "-")" ]]; then
				__RETN="$(fnGetFileinfo "${__MDIA[18]}")"
				read -r -a __LIST < <(echo "${__RETN}")
				__MDIA[19]="${__LIST[1]:-}"	# rmk_tstamp
				__MDIA[20]="${__LIST[2]:-}"	# rmk_size
				__MDIA[21]="${__LIST[3]:-}"	# rmk_volume
			fi
			# --- conf file ---------------------------------------------------
			if [[ -n "$(fnTrim "${__MDIA[24]}" "-")" ]]; then
				__RETN="$(fnGetFileinfo "${__MDIA[24]}")"
				read -r -a __LIST < <(echo "${__RETN}")
				__MDIA[25]="${__LIST[1]:-}"	# rmk_tstamp
			fi
			# --- data registration -------------------------------------------
			__MDIA=("${__MDIA[@]// /%20}")
			I="${__MDIA[0]}"
			_LIST_MDIA[I]="$(
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__MDIA[@]:1}"
			)"
#printf "%s\n" "${_LIST_MDIA[I]:-}"
		done
	done

#printf "%s\n" "${_LIST_MDIA[@]}"

	fnList_mdia_Put "work.txt"


	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	exit 0

# ### eof #####################################################################
#    0: type        ( 11)   TEXT            NOT NULL    media type
#    1: entry_flag  ( 11)   TEXT            NOT NULL    [m] menu, [o] output, [else] hidden
#    2: entry_name  ( 39)   TEXT            NOT NULL    entry name (unique)
#    3: entry_disp  ( 39)   TEXT            NOT NULL    entry name for display
#    4: version     ( 23)   TEXT                        version id
#    5: latest      ( 23)   TEXT                        latest version
#    6: release     ( 15)   TEXT                        release date
#    7: support     ( 15)   TEXT                        support end date
#    8: web_regexp  (143)   TEXT                        web file  regexp
#    9: web_path    (143)   TEXT                        "         path
#   10: web_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
#   11: web_size    ( 15)   BIGINT                      "         file size
#   12: web_status  ( 15)   TEXT                        "         download status
#   13: iso_path    ( 87)   TEXT                        iso image file path
#   14: iso_tstamp  ( 47)   TEXT                        "         time stamp
#   15: iso_size    ( 15)   BIGINT                      "         file size
#   16: iso_volume  ( 43)   TEXT                        "         volume id
#   17: rmk_path    ( 87)   TEXT                        remaster  file path
#   18: rmk_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
#   19: rmk_size    ( 15)   BIGINT                      "         file size
#   20: rmk_volume  ( 43)   TEXT                        "         volume id
#   21: ldr_initrd  ( 87)   TEXT                        initrd    file path
#   22: ldr_kernel  ( 87)   TEXT                        kernel    file path
#   23: cfg_path    ( 87)   TEXT                        config    file path
#   24: cfg_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
#   25: lnk_path    ( 87)   TEXT                        symlink   directory or file path
#   26: create_flag ( 11)   TEXT                        create flag
