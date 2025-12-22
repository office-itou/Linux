#!/bin/bash

###############################################################################
#
#	custom iso image creation and pxeboot configuration shell
#	  developed for debian
#
#	developer   : J.Itou
#	release     : 2025/11/01
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2025/11/01 000.0000 J.Itou         first release
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
#	source "${_SHEL_COMN}"/fnWget.sh						# wget / curl

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
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnDownload.sh					# wget / curl file download
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnRsync.sh						# rsync

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
	source "${_SHEL_COMD}"/fnMk_print_list.sh				# print media list
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_option_preseed.sh		# make boot options for preseed
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_option_nocloud.sh		# make boot options for nocloud
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_option_kickstart.sh	# make boot options for kickstart
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_option_autoyast.sh		# make boot options for autoyast
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_option_agama.sh		# make boot options for agama
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_boot_options.sh				# make boot options
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_clear_menu.sh		# clear pxeboot menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_hdrftr.sh		# make header and footer for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_windows.sh		# make Windows section for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_winpe.sh		# make WinPE section for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_aomei.sh		# make aomei backup section for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_m86p.sh		# make memtest86+ section for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe_linux.sh		# make linux section for ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_ipxe.sh				# make ipxe menu
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_hdrftr.sh		# make header and footer for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_windows.sh		# make Windows section for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_winpe.sh		# make WinPE section for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_aomei.sh		# make aomei backup section for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_m86p.sh		# make memtest86+ section for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub_linux.sh		# make linux section for grub.cfg
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot_grub.sh				# make grub.cfg for pxeboot
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_hdrftr.sh		# make header and footer for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_windows.sh		# make Windows section for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_winpe.sh		# make WinPE section for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_aomei.sh		# make aomei backup section for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_m86p.sh		# make memtest86+ section for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx_linux.sh		# make linux section for syslinux
	# shellcheck source=/dev/null
#	source "${_SHEL_COMD}"/fnMk_pxeboot_slnx.sh				# make syslinux for pxeboot
	# shellcheck source=/dev/null
	source "${_SHEL_COMD}"/fnMk_pxeboot.sh					# make pxeboot files

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
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	unset __time_start __time_end __time_elapsed

	exit 0

# ### eof #####################################################################
