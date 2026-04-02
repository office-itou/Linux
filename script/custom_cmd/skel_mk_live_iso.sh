#!/bin/bash

###############################################################################
#
#	
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2025/11/01
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/04/01 000.0000 J.Itou         first release
#
#	shell check : shellcheck -o all "filename"
#	            : shellcheck -o all -e SC2154 *.sh
#
###############################################################################

# *** global section **********************************************************

	# --- include -------------------------------------------------------------
	declare -r    _SHEL_PATH="${0:?}"
	declare -r    _SHEL_TOPS="${_SHEL_PATH%/*}"/..
	declare -r    _SHEL_COMN="${_SHEL_TOPS:-}/_common_bash"
	declare -r    _SHEL_COMD="${_SHEL_TOPS:-}/custom_cmd"
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnComm_system_common.sh		# global variables (for system)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnComm_global_variables.sh		# global variables (for basic)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD:?}"/fnComm_global_common.sh		# global variables (for application)

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
#	source "${_SHEL_COMN}"/fnTargetsys.sh					# target system state
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv6FullAddr.sh				# IPv6 full address
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv6RevAddr.sh					# IPv6 reverse address
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnIPv4Netmask.sh					# IPv4 netmask conversion
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnGetWebinfo.sh					# get web information data
	# shellcheck source=/dev/null
	source "${_SHEL_COMN}"/fnGetFileinfo.sh					# get file information data
	# shellcheck source=/dev/null
#	source "${_SHEL_COMN}"/fnWget.sh						# wget / curl

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_dbgout.sh					# message output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_dbgdump.sh				# dump output (debug out)
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_dbgparam.sh				# parameter debug output
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_dbgparameters.sh			# print out of internal variables
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_dbgparameters_all.sh		# Print all global variables (_[A..Z]*)
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_find_command.sh			# find command
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_find_service.sh			# find service
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_system_param.sh			# get system parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_network_param.sh			# get network parameter
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_file_backup.sh			# file backup
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_download.sh				# wget / curl file download
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_rsync.sh					# rsync

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_trap.sh					# trap
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_init_mk_live_iso.sh		# initialize

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_list_conf_Get.sh			# get auto-installation configuration file
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnComm_list_conf_Put.sh			# put common configuration data

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_list_mdia_Get.sh			# get media information data
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_list_mdia_Put.sh			# put media information data

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_preconf.sh			# make mkosi preconfiguration files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_print_list.sh				# print media list

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_build.sh			# exec mkosi build

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_boot_options.sh		# make mkosi boot options

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_grub_conf.sh		# make mkosi grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_grub_theme.sh		# make theme.txt
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_grub.sh				# make mkosi grub files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_ilnx_isolinux.sh	# make mkosi isolinux.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_ilnx_theme.sh		# make mkosi theme.txt
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_ilnx.sh				# make isolinux files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_mkosi_cdfs.sh				# make mkosi cdfs files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_squashfs.sh				# make squashfs files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnComm_xorrisofs.sh				# make iso files

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_isofile.sh				# make iso files

# *** main section ************************************************************

	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_help_mk_live_iso.sh		# help
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMake_main_mk_live_iso.sh		# main routine

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
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	exit 0

# ### eof #####################################################################
