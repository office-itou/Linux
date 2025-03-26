#!/bin/bash

# *** initialization **********************************************************

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- working directory name ----------------------------------------------
#	declare -r    PROG_PATH="$0"
#	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
#	declare -r    PROG_NAME="${PROG_PATH##*/}"
#	declare -r    PROG_PROC="${PROG_NAME}.$$"
#	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
#	readonly      DIRS_TEMP

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
#	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
#	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
#	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
#	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
#	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
#	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
#	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
#	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
#	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
#	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
#	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- chgroot -------------------------------------------------------------
	declare -r    DIRS_CHRT="${1:-}"

#	mkdir -p "${DIRS_CHRT}"/srv/{hgfs,http,samba,tftp,user}

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	# --- mount ---------------------------------------------------------------
	mount  --bind "${DIRS_CHRT}" "${DIRS_CHRT}"             && mount --make-rprivate "${DIRS_CHRT}"
	mount  --bind "${DIRS_TOPS}" "${DIRS_CHRT}${DIRS_TOPS}" && mount --make-rprivate "${DIRS_CHRT}${DIRS_TOPS}"
	mount  --bind "${DIRS_HGFS}" "${DIRS_CHRT}${DIRS_HGFS}" && mount --make-rprivate "${DIRS_CHRT}${DIRS_HGFS}"
	mount --rbind /dev           "${DIRS_CHRT}/dev/"        && mount --make-rslave   "${DIRS_CHRT}/dev/"
	mount -t proc /proc          "${DIRS_CHRT}/proc/"
	mount --rbind /sys           "${DIRS_CHRT}/sys/"        && mount --make-rslave   "${DIRS_CHRT}/sys/"
	mount --rbind /tmp           "${DIRS_CHRT}/tmp/"
	mount  --bind /run           "${DIRS_CHRT}/run/"

	# --- daemon reload -------------------------------------------------------
	systemctl daemon-reload

	# --- chroot --------------------------------------------------------------
	chroot "${DIRS_CHRT}"

	# --- umount --------------------------------------------------------------
	umount             "${DIRS_CHRT}/run/"
	umount --recursive "${DIRS_CHRT}/tmp/"
	umount --recursive "${DIRS_CHRT}/sys/"
	umount             "${DIRS_CHRT}/proc/"
	umount --recursive "${DIRS_CHRT}/dev/"
	umount             "${DIRS_CHRT}${DIRS_HGFS}"
	umount             "${DIRS_CHRT}${DIRS_TOPS}"
	umount             "${DIRS_CHRT}"

	# --- exit ----------------------------------------------------------------
	exit 0

### eof #######################################################################
