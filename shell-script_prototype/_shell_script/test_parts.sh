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

	declare       __TYPE=""
	declare       __LINE=""
	declare -a    __TGET=()
	declare -a    __MDIA=()
	declare -i    I=0
	declare -i    J=0

function fnMk_boot_option_preseed() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}auto=true preseed/file=/cdrom${25#"${_DIRS_CONF}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/file=\/cdrom/url=\$\{srvraddr\}}"
		case "${4}" in
			ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*                        ) __WORK="${__WORK/\/cdrom/}";;
			*                               ) ;;
		esac
	fi
	case "${1}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${4}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		case "${4}" in
			ubuntu-*) __WORK="${__WORK:+"${__WORK} "}netcfg/target_network_config=NetworkManager";;
			*       ) ;;
		esac
		__WORK="${__WORK:+"${__WORK} "}netcfg/disable_autoconfig=true"
		__WORK="${__WORK:+"${__WORK} "}netcfg/choose_interface=\${ethrname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_hostname=\${hostname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_ipaddress=\${ipv4addr}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_netmask=\${ipv4mask}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_gateway=\${ipv4gway}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_nameservers=\${ipv4nsvr}"
	fi
	case "${1}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${4}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\${srvraddr}/${_DIRS_IMGS##*/}/${23#"${_DIRS_LOAD}"} iso-url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_RMAK##*/}/${15##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
function fnMk_boot_option_nocloud() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=/cdrom${25#"${_DIRS_CONF}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/file=\/cdrom/url=\${srvraddr}}"
	fi
	case "${1}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${4}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		case "${4}" in
			ubuntu-live-18.04   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
			*                   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
		esac
	fi
	case "${1}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${4}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\${srvraddr}/${_DIRS_IMGS##*/}/${23#"${_DIRS_LOAD}"} iso-url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_RMAK##*/}/${15##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
function fnMk_boot_option_kickstart() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}inst.ks=hd:sr0:${25#"${_DIRS_CONF}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/hd:sr0:/\${srvraddr}}"
			__WORK="${__WORK/_dvd/_web}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	fi
	case "${1}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK:+"${__WORK} "}inst.repo=\${srvraddr}/${_DIRS_IMGS##*/}/${4}"
		else
			__WORK="${__WORK:+"${__WORK} "}inst.stage2=hd:LABEL=${18}"
		fi
	else
		case "${1}" in
			clive) __WORK="${__WORK:+"${__WORK} "}root=live:\${srvraddr}/${_DIRS_RMAK##*/}/${15##*/}";;
			*    ) __WORK="${__WORK:+"${__WORK} "}root=live:\${srvraddr}/${_DIRS_ISOS##*/}/${15##*/}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
function fnMk_boot_option_autoyast() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}autoyast=cd:${25#"${_DIRS_CONF}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/cd:/\${srvraddr}}"
			__WORK="${__WORK/_dvd/_web}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr}/${_IPV4_CIDR:-},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
		case "${4}" in
			opensuse-*-15*) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
			*             ) ;;
		esac
	fi
	case "${1}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			case "${4}" in
				opensuse-leap*netinst*      ) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/distribution/leap/${4##*[^0-9]}/repo/oss/";;
				opensuse-tumbleweed*netinst*) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
				*                           ) __WORK="${__WORK:+"${__WORK} "}install=\${srvraddr}/${_DIRS_IMGS##*/}/${4##*[^0-9]}";;
			esac
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
function fnMk_boot_option_agama() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}live.password=install inst.auto=dvd:${25#"${_DIRS_CONF}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/dvd:/\${srvraddr}}"
			__WORK="${__WORK/_dvd/_web}"
		else
			__WORK="${__WORK:+"${__WORK}?devices=sr0"}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr}/${_IPV4_CIDR:-},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
		case "${4}" in
			opensuse-*-15*) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
			*             ) ;;
		esac
	fi
	case "${1}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${25##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			case "${4}" in
				opensuse-leap*netinst*      ) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/distribution/leap/${4##*[^0-9]}/repo/oss/";;
				opensuse-tumbleweed*netinst*) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
				*                           ) __WORK="${__WORK:+"${__WORK} "}install=\${srvraddr}/${_DIRS_IMGS##*/}/${4##*[^0-9]}";;
			esac
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
function fnMk_boot_options() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	case "${4}" in
		debian-*|live-debian-*| \
		ubuntu-*|live-ubuntu-*)
			case "${25}" in
				*/preseed/*) fnMk_boot_option_preseed "${__TGET_TYPE}" "${@}";;
				*/nocloud/*) fnMk_boot_option_nocloud "${__TGET_TYPE}" "${@}";;
				*          ) ;;
			esac
			;;
		fedora-*      |live-fedora-*      | \
		centos-*      |live-centos-*      | \
		almalinux-*   |live-almalinux-*   | \
		rockylinux-*  |live-rockylinux-*  | \
		miraclelinux-*|live-miraclelinux-*)
			case "${25}" in
				*/kickstart/*) fnMk_boot_option_kickstart "${__TGET_TYPE}" "${@}";;
				*            ) ;;
			esac
			;;
		opensuse-*|live-opensuse-*)
			case "${25}" in
				*/autoyast/*) fnMk_boot_option_autoyast "${__TGET_TYPE}" "${@}";;
				*/agama/*   ) fnMk_boot_option_agama    "${__TGET_TYPE}" "${@}";;
				*           ) ;;
			esac
			;;
		* ) ;;
	esac
}
function fnMk_pxeboot_clear_menu() {
	declare       __DIRS=""
	__DIRS="$(fnDirname "${1:?}")"
	if [[ -z "${__DIRS:-}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "invalid value: [${1:-}]"
		return
	fi
	mkdir -p "${__DIRS:?}"
	: > "${1:?}"
}
function fnMk_pxeboot_ipxe_hdrftr() {
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH}" || true
		#!ipxe

		cpuid --ext 29 && set arch amd64 || set arch x86

		dhcp

		set optn-timeout 1000
		set menu-timeout 0
		isset ${menu-default} || set menu-default exit

		:start

		:menu
		menu Select the OS type you want to boot
		item --gap --                                   --------------------------------------------------------------------------
		item --gap --                                   [ System command ]
		item -- shell                                   - iPXE shell
		#item -- shutdown                               - System shutdown
		item -- restart                                 - System reboot
		item --gap --                                   --------------------------------------------------------------------------
		choose --timeout ${menu-timeout} --default ${menu-default} selected || goto menu
		goto ${selected}

		:shell
		echo "Booting iPXE shell ..."
		shell
		goto start

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:error
		prompt Press any key to continue
		exit

		:exit
		exit
_EOT_
}
function fnMk_pxeboot_ipxe_windows() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
		:${4}
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w${4##*-}.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}
function fnMk_pxeboot_ipxe_winpe() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
		:${4}
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}
function fnMk_pxeboot_ipxe_aomei() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
		:${4}
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set ipxaddr \${srvraddr}/${_DIRS_TFTP##*/}/ipxe
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit
_EOT_
}
function fnMk_pxeboot_ipxe_m86p() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
		:${4}
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://${_SRVR_ADDR:?}
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		iseq \${platform} efi && set knlfile \${knladdr}/${23#*/"${4}"/} || set knlfile \${knladdr}/${24#*/"${4}"/}
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit
_EOT_
}
function fnMk_pxeboot_ipxe_linux() {
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	case "${1}" in
#		mini    ) ;;
#		netinst ) ;;
#		dvd     ) ;;
#		liveinst) ;;
		live    ) __ENTR="live-";;		# original media live mode
#		tool    ) ;;					# tools
#		clive   ) ;;					# custom media live mode
#		cnetinst) ;;					# custom media install mode
#		system  ) ;;					# system command
		*       )						# original media install mode
	esac
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
		:${__ENTR:-}${4}
		prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && set openmenu 1 ||
		set hostname ${_NWRK_HOST/:_DISTRO_:/${4%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
		set ethrname ${_NICS_NAME:-ens160}
		set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
		set ipv4gway ${_IPV4_GWAY:-}
		set ipv4nsvr ${_IPV4_NSVR:-}
		form                                    Configure Network Options
		item hostname                           Hostname
		item ethrname                           Interface
		item ipv4addr                           IPv4 address/netmask
		item ipv4gway                           IPv4 gateway
		item ipv4nsvr                           IPv4 nameservers
		isset \${openmenu} && present ||
		set srvraddr ${_SRVR_PROT:?}://\${66}
		set autoinst ${__BOPT[0]:-} ${__BOPT[1]:-}
		set language ${__BOPT[2]:-}
		set networks ${__BOPT[3]:-}
		set otheropt ${__BOPT[@]:4}
		form                                    Configure Autoinstall Options
		item autoinst                           Auto install
		item language                           Language
		item networks                           Network
		item otheropt                           Other options
		isset \${openmenu} && present ||
		echo Loading ${5//%20/ } ...
		set srvraddr ${_SRVR_PROT:?}://\${66}
		set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
		set options \${autoinst} \${language} \${networks} \${otheropt}
		echo Loading boot files ...
		kernel \${knladdr}/${24#*/"${4}"/} \${options} --- quiet || goto error
		initrd \${knladdr}/${23#*/"${4}"/} || goto error
		boot || goto error
		exit
_EOT_
}
function fnMk_pxeboot_ipxe() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
	declare -a    __MDIA=()
	declare       __WORK=""
	__MDIA=("${__LIST_MDIA[@]//%20/ }")
	[[ ! -s "${__TGET_PATH}" ]] && fnMk_pxeboot_ipxe_hdrftr
	case "${__MDIA[2]}" in
		m)								# (menu)
			if [[ -z "$(fnTrim "${__MDIA[4]:-}" " ")" ]]; then
				return
			fi
			__WORK="$(printf "%-48.48s[ %s ]" "item --gap --" "${__MDIA[4]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__MDIA[3]}"/. ]] \
			|| [[ ! -s "${__MDIA[14]}" ]]; then
				return
			fi
			__WORK="$(printf "%-48.48s%-55.55s%19.19s" "item -- ${__LIST_MDIA[3]}" "- ${__MDIA[4]//%20/ } ${_TEXT_SPCE// /.}" "${__MDIA[15]//%20/ }")"
			sed -i "${__TGET_PATH}" -e "/\[ System command \]/i \\${__WORK}"
			case "${__MDIA[3]}" in
				windows-*              ) __WORK="$(fnMk_pxeboot_ipxe_windows "${__MDIA[@]}")";;
				winpe-*|ati*x64|ati*x86) __WORK="$(fnMk_pxeboot_ipxe_winpe   "${__MDIA[@]}")";;
				aomei-backupper        ) __WORK="$(fnMk_pxeboot_ipxe_aomei   "${__MDIA[@]}")";;
				memtest86*             ) __WORK="$(fnMk_pxeboot_ipxe_m86p    "${__MDIA[@]}")";;
				*                      ) __WORK="$(fnMk_pxeboot_ipxe_linux   "${__MDIA[@]}")";;
			esac
			sed -i "${__TGET_PATH}" -e "/^:shell$/i \\${__WORK}\n"
			;;
		*) ;;							# (hidden)
	esac
}
function fnMk_pxeboot_grub() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
}
function fnMk_pxeboot_slnx() {
	declare -r    __TGET_PATH="${1:?}"
	declare -r    __CONT_TABS="${2:?}"
	declare -r -a __LIST_MDIA=("${@:3}")
}

	fnMk_pxeboot_clear_menu "${_PATH_IPXE:?}"				# ipxe
	fnMk_pxeboot_clear_menu "${_PATH_GRUB:?}"				# grub
	fnMk_pxeboot_clear_menu "${_PATH_SLNX:?}"				# syslinux (bios)
	fnMk_pxeboot_clear_menu "${_PATH_UEFI:?}"				# syslinux (efi64)
	for __TYPE in "${_LIST_TYPE[@]}"
	do
		fnMk_print_list __LINE "${__TYPE}"
		IFS= mapfile -d $'\n' -t __TGET < <(echo -n "${__LINE}")
		for I in "${!__TGET[@]}"
		do
			read -r -a __MDIA < <(echo "${__TGET[I]}")
			case "${__MDIA[2]}" in
				m) ;;
				*)
					case "${__MDIA[27]}" in
						c) ;;
						d)
							__RETN="- - - -"
							if [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]]; then
								fnDownload "${__MDIA[10]}" "${__MDIA[14]}"
								__RETN="$(fnGetFileinfo "${__MDIA[14]}")"
							fi
							read -r -a __ARRY < <(echo "${__RETN}")
							__MDIA[15]="${__ARRY[1]:-}"	# iso_tstamp
							__MDIA[16]="${__ARRY[2]:-}"	# iso_size
							__MDIA[17]="${__ARRY[3]:-}"	# iso_volume
							;;
						*) ;;
					esac
					# --- rsync -----------------------------------------------
					fnRsync "${__MDIA[14]}" "${_DIRS_IMGS}/${__MDIA[3]}"
					;;
			esac
			# --- create menu file --------------------------------------------
			fnMk_pxeboot_ipxe "${_PATH_IPXE:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# ipxe
			fnMk_pxeboot_grub "${_PATH_GRUB:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# grub
			fnMk_pxeboot_slnx "${_PATH_SLNX:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (bios)
			fnMk_pxeboot_slnx "${_PATH_UEFI:?}" "${__TABS:-"0"}" "${__MDIA[@]:-}"	# syslinux (efi64)
			# --- data registration -------------------------------------------
			__MDIA=("${__MDIA[@]// /%20}")
			J="${__MDIA[0]}"
			_LIST_MDIA[J]="$(
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
				"${__MDIA[@]:1}"
			)"
		done
	done

#printf "%s\n" "${_LIST_MDIA[@]}"

	# --- put media information data ------------------------------------------
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
