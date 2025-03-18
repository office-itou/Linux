#!/bin/bash

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

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
#	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	trap 'rm -rf '"${DIRS_TEMP:?}"'' EXIT

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
#	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- wget parameter ------------------------------------------------------
	declare -r -a WGET_OPTN=("--tries=3" "--timeout=10" "--no-verbose")

	# --- github download root url --------------------------------------------
	declare -r    ROOT_GHUB="https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script"

	# --- Configuration files for Linux ---------------------------------------
	echo "Get Configuration files for Linux"
	mkdir -p "${DIRS_TMPL:?}"
	pushd "${DIRS_TMPL}" > /dev/null
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/_template/kickstart_common.cfg"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/_template/nocloud-ubuntu-user-data"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/_template/preseed_debian.cfg"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/_template/preseed_ubuntu.cfg"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/_template/yast_opensuse.xml"
	popd > /dev/null

	# --- Configuration files for Windows -------------------------------------
	echo "Get Configuration files for Windows"
	mkdir -p "${DIRS_CONF:?}/windows"
	pushd "${DIRS_CONF}/windows" > /dev/null
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/WinREexpand.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/WinREexpand_bios.sub"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/WinREexpand_uefi.sub"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/bypass.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/inst_w10.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/inst_w11.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/shutdown.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/startnet.cmd"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/unattend.xml"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/conf/windows/winpeshl.ini"
	popd > /dev/null

	# --- Shell script files --------------------------------------------------
	echo "Get Shell script files"
	mkdir -p "${DIRS_USER:?}/private"
	pushd "${DIRS_USER}/private" > /dev/null
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/mk_custom_iso.sh"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/mk_pxeboot_conf.sh"
		LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress "${ROOT_GHUB}/sv_check.sh"
	popd > /dev/null

	# --- debian / ubuntu keyring ---------------------------------------------
	if command -v dpkg > /dev/null 2>&1; then
		echo "Get keyring files"
		mkdir -p "${DIRS_KEYS:?}/_archive"
		pushd "${DIRS_KEYS}/_archive" > /dev/null
			LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress https://deb.debian.org/debian/pool/main/d/debian-keyring/debian-keyring_2024.09.22_all.deb
			LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress https://archive.ubuntu.com/ubuntu/pool/main/u/ubuntu-keyring/ubuntu-keyring_2023.11.28.1_all.deb
			dpkg -x ./debian-keyring_2024.09.22_all.deb   "${DIRS_TEMP}/"
			dpkg -x ./ubuntu-keyring_2023.11.28.1_all.deb "${DIRS_TEMP}/"
			cp -a "${DIRS_TEMP}/usr/share/keyrings/debian-keyring.gpg"         "../"
			cp -a "${DIRS_TEMP}/usr/share/keyrings/ubuntu-archive-keyring.gpg" "../"
		popd > /dev/null
	fi

	# --- dnsmasq -------------------------------------------------------------
	echo "Get iPXE"
	/var/adm/installer/*/get_module_ipxe.sh
	echo "Set dnsmasq"
	cp -a /var/adm/installer/*/samp/etc/dnsmasq.d/pxeboot_ipxe.conf /etc/dnsmasq.d/
	if command -v semanage > /dev/null 2>&1; then
		semanage fcontext -a -t dnsmasq_etc_t '/etc/dnsmasq.d/pxeboot_ipxe.conf'
		restorecon -v '/etc/dnsmasq.d/pxeboot_ipxe.conf'
	fi
	systemctl restart dnsmasq.service

	rm -rf "${DIRS_TEMP:?}"

	echo "Complete"

	exit
