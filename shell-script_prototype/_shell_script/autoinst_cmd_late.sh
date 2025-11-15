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

	readonly _SHEL_TOPS="${0%/*}"
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnGlobal_variables.sh

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnDbgout.sh					# message output (debug out)
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnMsgout.sh					# message output
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnString.sh					# string output
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnStrmsg.sh					# string output with message
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnIPv6FullAddr.sh			# IPv6 full address
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnIPv6RevAddr.sh				# IPv6 reverse address
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnIPv4Netmask.sh				# IPv4 netmask conversion
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnDetect_virt.sh				# detecting target virtualization
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnSystem_param.sh			# get system parameter
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnNetwork_param.sh			# get network parameter
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/common/fnFile_backup.sh				# file backup

# *** function section (subroutine functions) *********************************

	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnInitialize.sh						# initialize
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnPackage_update.sh					# package updates
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnMkdir_share.sh					# creating a shared directory
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_connman.sh					# connman
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_netplan.sh					# netplan
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_manager.sh					# network manager
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_hostname.sh					# hostname
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_hosts.sh					# hosts
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_firewalld.sh				# firewalld
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_dnsmasq.sh					# dnsmasq
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_resolv.sh					# resolv.conf
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_apache.sh					# apache
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_samba.sh					# samba
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_timesyncd.sh				# timesyncd
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_chronyd.sh					# chronyd
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_ssh.sh						# openssh-server
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_vmware.sh					# vmware shared directory
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_wireplumber.sh				# wireplumber
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_skel.sh						# skeleton
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_sudo.sh						# sudoers
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_blacklist.sh				# blacklist
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetupModule_ipxe.sh				# ipxe module
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_apparmor.sh					# apparmor
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_selinux.sh					# selinux
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_ipfilter.sh					# ipfilter
	# shellcheck source=/dev/null
	. "${_SHEL_TOPS:?}"/fnSetup_grub_menu.sh				# grub menu settings

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
	fnSetup_manager						# network manager

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
		tree --charset C -n --filesfirst "${_DIRS_BACK}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${_FUNC_NAME}]"
}

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	fnMsgout "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"

	# --- boot parameter selection --------------------------------------------
	for __LINE in ${_COMD_LINE:-} ${_PROG_PARM:-}
	do
		case "${__LINE}" in
			debug    | dbg                ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout             ) _DBGS_FLAG="true";;
			target=*                      ) _DIRS_TGET="${__LINE#*target=}";;
			iso-url=*.iso  | url=*.iso    ) _ISOS_FILE="${__LINE#*url=}";;
			preseed/url=*  | url=*        ) _SEED_FILE="${__LINE#*url=}";;
			preseed/file=* | file=*       ) _SEED_FILE="${__LINE#*file=}";;
			ds=nocloud*                   ) _SEED_FILE="${__LINE#*ds=nocloud*=}";_SEED_FILE="${_SEED_FILE%%/}/user-data";;
			inst.ks=*                     ) _SEED_FILE="${__LINE#*inst.ks=}";;
			autoyast=*                    ) _SEED_FILE="${__LINE#*autoyast=}";;
			inst.auto=*                   ) _SEED_FILE="${__LINE#*inst.auto=}";;
			netcfg/target_network_config=*) _NMAN_FLAG="${__LINE#*target_network_config=}";;
			netcfg/choose_interface=*     ) _NICS_NAME="${__LINE#*choose_interface=}";;
			netcfg/disable_dhcp=*         ) _IPV4_DHCP="$([ "${__LINE#*disable_dhcp=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/disable_autoconfig=*   ) _IPV4_DHCP="$([ "${__LINE#*disable_autoconfig=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/get_ipaddress=*        ) _NICS_IPV4="${__LINE#*get_ipaddress=}";;
			netcfg/get_netmask=*          ) _NICS_MASK="${__LINE#*get_netmask=}";;
			netcfg/get_gateway=*          ) _NICS_GATE="${__LINE#*get_gateway=}";;
			netcfg/get_nameservers=*      ) _NICS_DNS4="${__LINE#*get_nameservers=}";;
			netcfg/get_hostname=*         ) _NICS_FQDN="${__LINE#*get_hostname=}";;
			netcfg/get_domain=*           ) _NICS_WGRP="${__LINE#*get_domain=}";;
			interface=*                   ) _NICS_NAME="${__LINE#*interface=}";;
			hostname=*                    ) _NICS_FQDN="${__LINE#*hostname=}";;
			domain=*                      ) _NICS_WGRP="${__LINE#*domain=}";;
			nameserver=*                  ) _NICS_DNS4="${__LINE#*nameserver=}";;
			ip=dhcp | ip4=dhcp | ipv4=dhcp) _IPV4_DHCP="true";;
			ip=* | ip4=* | ipv4=*         ) _IPV4_DHCP="false"
			                                _NICS_IPV4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 1)"
			                                _NICS_GATE="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 3)"
			                                _NICS_MASK="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 4)"
			                                _NICS_FQDN="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 5)"
			                                _NICS_NAME="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 6)"
			                                _NICS_DNS4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 8)"
			                                ;;
			ifcfg=*                       ) _NICS_NAME="$(echo "${__LINE#*ifcfg*=}" | cut -d '=' -f 1)"
			                                _NICS_IPV4="$(echo "${__LINE#*=*=}" | cut -d ',' -f 1)"
			                                case "${_NICS_IPV4:-}" in
			                                     dhcp6)
			                                        _IPV4_DHCP=""
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     dhcp|dhcp4)
			                                        _IPV4_DHCP="true"
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     *)
			                                        _IPV4_DHCP="false"
			                                        _NICS_IPV4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 1)"
			                                        _NICS_GATE="$(echo "${__LINE#*=*=}," | cut -d ',' -f 2)"
			                                        _NICS_DNS4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 3)"
			                                        _NICS_WGRP="$(echo "${__LINE#*=*=}," | cut -d ',' -f 4)"
			                                        ;;
			                                esac
			                                ;;
			*) ;;
		esac
	done

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