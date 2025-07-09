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
	declare -r    PROG_PATH="$0"
#	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
#	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

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
	declare       FLAG_CHRT=""			# not empty: already running in chroot
	declare -r    DIRS_CHRT="${1%/}"
	shift

#	mkdir -p "${DIRS_CHRT}"/srv/{hgfs,http,samba,tftp,user}

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${DIRS_TEMP:?}")

# shellcheck disable=SC2317
function funcTrap() {
	declare       _PATH=""
	declare -i    I=0
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -Vr)
	do
		_PATH="${_LIST_RMOV[I]}"
		if [[ -e "${_PATH}" ]] && mountpoint --quiet "${_PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${_PATH}"
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		fi
	done
	if [[ -e "${DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${DIRS_TEMP:?}"
		rm -rf "${DIRS_TEMP:?}"
	fi
}

	trap funcTrap EXIT

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	# --- overlay -------------------------------------------------------------
	declare -r    DIRS_OLAY="${PWD:?}/overlay/${DIRS_CHRT##*/}"

function funcMount_overlay() {
	# shellcheck disable=SC2140
	mount -t overlay overlay -o lowerdir="${1:?}/",upperdir="${2:?}",workdir="${3:?}" "${4:?}" && _LIST_RMOV+=("${4:?}")
}

	# --- systemd-nspawn ------------------------------------------------------
	FLAG_CHRT="$(find /tmp/ -type d \( -name "${PROG_NAME}.*" -a -not -name "${DIRS_TEMP##*/}" \) -exec find '{}' -type f -name "${DIRS_CHRT##*/}" \; 2> /dev/null || true)"
	touch "${DIRS_TEMP:?}/${DIRS_CHRT##*/}"
	if [[ -z "${FLAG_CHRT}" ]]; then
		OPTN_PARM=()
#		OPTN_PARM+=("--private-users=0")
#		OPTN_PARM+=("--private-users-ownership=chown")
#		OPTN_PARM+=("--capability=CAP_MKNOD,CAP_SYS_ADMIN")
#		OPTN_PARM+=("--property=DeviceAllow=/dev/loop-control rw")
#		OPTN_PARM+=("--property=DeviceAllow=block-loop rw")
#		OPTN_PARM+=("--property=DeviceAllow=block-blkext rw")
		OPTN_PARM+=("--bind=${DIRS_TOPS}:${DIRS_TOPS}:norbind,rootidmap")
		OPTN_PARM+=("--bind=${DIRS_HGFS}:${DIRS_HGFS}:norbind,noidmap")
		if [[ -f /run/systemd/resolve/stub-resolv.conf ]]; then
			OPTN_PARM+=("--resolv-conf=copy-uplink")
		fi
		rm -rf   "${DIRS_OLAY:?}"/work
		mkdir -p "${DIRS_OLAY}"/{upper,lower,work,merged}
#		mkdir -p "${DIRS_OLAY}/upper/${DIRS_HGFS}"
		funcMount_overlay "${DIRS_CHRT:?}" "${DIRS_OLAY}/upper" "${DIRS_OLAY}/work/" "${DIRS_OLAY}/merged"
set -x
		systemd-nspawn --boot -U --directory="${DIRS_OLAY}/merged/" --machine="${DIRS_CHRT##*/}" "${OPTN_PARM[@]}"
set +x
		umount "${DIRS_OLAY}/merged/"
	fi
	rm -rf "${DIRS_TEMP:?}/${DIRS_CHRT##*/}"

	# --- exit ----------------------------------------------------------------
	exit 0

### eof #######################################################################
