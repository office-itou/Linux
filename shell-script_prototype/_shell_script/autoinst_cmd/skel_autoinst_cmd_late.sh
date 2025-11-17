#!/bin/sh

###############################################################################
#
#	autoinstall (late) shell script
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

	export LANG=C
#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

	# --- debug parameter -----------------------------------------------------
	_DBGS_FLAG=""						# debug flag (empty: normal, else: debug)

	# --- working directory ---------------------------------------------------
	readonly _PROG_PATH="$0"
	readonly _PROG_PARM="${*:-}"
	readonly _PROG_DIRS="${_PROG_PATH%/*}"
	readonly _PROG_NAME="${_PROG_PATH##*/}"
#	readonly _PROG_PROC="${_PROG_NAME}.$$"

	readonly _SHEL_TOPS="${_PROG_DIRS:?}"
	readonly _SHEL_COMN="${_PROG_DIRS:?}/../_common_sh"
	# shellcheck source=/dev/null
	. "${_SHEL_COMN:?}"/fnGlobal_variables.sh

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnDbgout.sh							# message output (debug out)
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnDbgdump.sh							# dump output (debug out)
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnMsgout.sh							# message output
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnString.sh							# string output
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnStrmsg.sh							# string output with message
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnFind_command.sh						# find command
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnFind_service.sh						# find service
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv6FullAddr.sh						# IPv6 full address
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv6RevAddr.sh						# IPv6 reverse address
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnIPv4Netmask.sh						# IPv4 netmask conversion
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnDetect_virt.sh						# detecting target virtualization
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnSystem_param.sh						# get system parameter
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnNetwork_param.sh					# get network parameter
	# shellcheck source=/dev/null
	. "${_SHEL_COMN}"/fnFile_backup.sh						# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnInitialize.sh						# initialize
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnPackage_update.sh					# package updates
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnMkdir_share.sh						# creating a shared directory
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_connman.sh					# connman
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_netplan.sh					# netplan
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_netman.sh						# network manager
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_hostname.sh					# hostname
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_hosts.sh						# hosts
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_firewalld.sh					# firewalld
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_dnsmasq.sh					# dnsmasq
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_resolv.sh						# resolv.conf
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_apache.sh						# apache
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_samba.sh						# samba
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_timesyncd.sh					# timesyncd
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_chronyd.sh					# chronyd
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_ssh.sh						# openssh-server
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_vmware.sh						# vmware shared directory
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_wireplumber.sh				# wireplumber
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_skel.sh						# skeleton
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_sudo.sh						# sudoers
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_blacklist.sh					# blacklist
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetupModule_ipxe.sh					# ipxe module
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_apparmor.sh					# apparmor
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_selinux.sh					# selinux
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_ipfilter.sh					# ipfilter
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fnSetup_grub_menu.sh					# grub menu settings

# *** main section ************************************************************

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_BACK : read
# shellcheck disable=SC2148,SC2317,SC2329
fnMain() {
	_FUNC_NAME="fnMain"
	fnMsgout "start" "[${_FUNC_NAME}]"

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize
	fnPackage_update					# package updates
	fnMkdir_share						# creating a shared directory

	# --- network manager -----------------------------------------------------
	fnSetup_connman						# connman
	fnSetup_netplan						# netplan
	fnSetup_netman						# network manager

	# --- application setup ---------------------------------------------------
	fnSetup_hostname					# hostname
	fnSetup_hosts						# hosts
#	fnSetup_hosts_access				# hosts.allow/hosts.deny
	fnSetup_firewalld					# firewalld
	fnSetup_dnsmasq						# dnsmasq
	fnSetup_resolv						# resolv.conf
	fnSetup_apache						# apache
	fnSetup_samba						# samba
	fnSetup_timesyncd					# timesyncd
	fnSetup_chronyd						# chronyd
	fnSetup_ssh							# openssh-server
	fnSetup_vmware						# vmware shared directory
	fnSetup_wireplumber					# wireplumber
	fnSetup_skel						# skeleton
	fnSetup_sudo						# sudoers
	fnSetup_blacklist					# blacklist
	fnSetupModule_ipxe					# ipxe module
	fnSetup_apparmor					# apparmor
	fnSetup_selinux						# selinux
	fnSetup_ipfilter					# ipfilter

	# --- booting setup -------------------------------------------------------
	fnSetup_grub_menu					# grub menu settings

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_BACK:-}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${_FUNC_NAME}]"
}

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# shellcheck source=/dev/null
	. "${_SHEL_TOPS}"/fncmdline.sh		# command line

	# --- debug output redirection --------------------------------------------
	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		fnDbgout "command line" \
			"debug,_COMD_LINE=[${_COMD_LINE:-}]"
	fi

	# --- main processing -----------------------------------------------------
	fnMain

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end - __time_start))
	fnMsgout "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
	fnMsgout "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"

	exit 0

# ### eof #####################################################################
