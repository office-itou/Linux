#!/bin/bash

#-shellcheck disable=SC2148
# *** initialization **********************************************************
	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# === data section ========================================================

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)
	declare       _DBGS_LOGS=""			# debug file (empty: normal, else: debug)
	declare       _DBGS_SIMU=""			# debug flag (empty: normal, else: simulation)
	declare -a    _DBGS_FAIL=()			# debug flag (empty: success, else: failure)

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare       _PROG_DIRS="${_PROG_PATH%/*}"
	              _PROG_DIRS="$(realpath "${_PROG_DIRS%/}")"
	readonly      _PROG_DIRS
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare -r    _SUDO_USER="${SUDO_USER:-}"
	declare       _SUDO_HOME="${SUDO_HOME:-}"
	if [[ -n "${_SUDO_USER}" ]] && [[ -z "${_SUDO_HOME}" ]]; then
		_SUDO_HOME="$(awk -F ':' '$1=="'"${_SUDO_USER}"'" {print $6;}' /etc/passwd)"
	fi
	readonly      _SUDO_HOME

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"${LOGNAME:-"$(whoami || true)"}"}"

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:?}" != "root" ]]; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "run as root user."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "your username is ${_USER_NAME}."
		exit 1
	fi

	# --- help ----------------------------------------------------------------
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ${_PROG_PATH:-"$0"} [command (options)]
_EOT_
}

	if [[ -z "${_PROG_PARM[*]:-}" ]]; then
		fnHelp
		exit 0
	fi

	# --- get command line ----------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			--dbglog) shift; _DBGS_LOGS="/tmp/${_PROG_PROC}.$(date +"%Y%m%d%H%M%S" || true).log";;
			--simu  ) shift; _DBGS_SIMU="true";;
			help    ) shift; fnHelp; exit 0;;
			*       ) shift;;
		esac
	done
	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file

# -----------------------------------------------------------------------------
# descript: trap
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnTrap() {
	declare -r    __FUNC_NAME="fnTrap"
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare       __PATH=""				# full path
	declare       __MPNT=""				# mount point
	declare -i    I=0

	if [[ "${#_DBGS_FAIL[@]}" -gt 0 ]]; then
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "failed."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "function: ${_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]}"
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "Working files will be deleted when this shell exits."
		read -r -p "Press any key to exit..."
	fi

	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
#		if [[ -n "${_DBGS_FAIL[*]}" ]] && [[ "${__PATH}" != "${_DIRS_TEMP:-}" ]]; then
#			continue
#		fi
		if mountpoint --quiet "${__PATH}"; then
			printf "\033[m${_PROG_NAME}: \033[93m%s\033[m\n" "    umount  : ${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}"
		fi
		case "${__PATH}" in
			"${_DIRS_TEMP:?}" | \
			"${_DIRS_WDIR:?}" )
				printf "\033[m${_PROG_NAME}: \033[93m%s\033[m\n" "    remove  : ${__PATH}" 1>&2
				rm -rf "${__PATH:?}"
				;;
			*) ;;
		esac
	done

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
}

	trap fnTrap EXIT

	# --- temporary directory -------------------------------------------------
	declare       _DIRS_TEMP="${_PROG_DIRS:-"${SUDO_HOME:-"${HOME:-"${TMPDIR:-"/tmp"}"}"}"}"
	mkdir -p   "${_DIRS_TEMP}"
	              _DIRS_TEMP="$(mktemp -qtd -p "${_DIRS_TEMP}" "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")			# temporary

	# --- working directory ---------------------------------------------------
	declare       _DIRS_WDIR="${SUDO_HOME:-"${HOME:-"${TMPDIR:-"/tmp"}"}"}/.workdirs"
	mkdir -p   "${_DIRS_WDIR}"
	              _DIRS_WDIR="$(mktemp -qtd -p "${_DIRS_WDIR}" "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_WDIR
	              _LIST_RMOV+=("${_DIRS_WDIR:?}")			# working

	# --- shared directory parameter ------------------------------------------
	declare -r    _DIRS_TOPS="/srv"							# top of shared directory
#	declare -r    _DIRS_HGFS="${_DIRS_TOPS}/hgfs"			# vmware shared
#	declare -r    _DIRS_HTML="${_DIRS_TOPS}/http/html"		# html contents#
#	declare -r    _DIRS_SAMB="${_DIRS_TOPS}/samba"			# samba shared
#	declare -r    _DIRS_TFTP="${_DIRS_TOPS}/tftp"			# tftp contents
	declare -r    _DIRS_USER="${_DIRS_TOPS}/user"			# user file

	# --- shared of user file -------------------------------------------------
	declare -r    _DIRS_SHAR="${_DIRS_USER}/share"			# shared of user file
	declare -r    _DIRS_CONF="${_DIRS_SHAR}/conf"			# configuration file
#	declare -r    _DIRS_DATA="${_DIRS_CONF}/_data"			# data file
#	declare -r    _DIRS_KEYS="${_DIRS_CONF}/_keyring"		# keyring file
	declare -r    _DIRS_MKOS="${_DIRS_CONF}/_mkosi"			# mkosi configuration files
	declare -r    _DIRS_TMPL="${_DIRS_CONF}/_template"		# templates for various configuration files
	declare -r    _DIRS_SHEL="${_DIRS_CONF}/script"			# shell script file
#	declare -r    _DIRS_IMGS="${_DIRS_SHAR}/imgs"			# iso file extraction destination
#	declare -r    _DIRS_ISOS="${_DIRS_SHAR}/isos"			# iso file
#	declare -r    _DIRS_LOAD="${_DIRS_SHAR}/load"			# load module
	declare -r    _DIRS_RMAK="${_DIRS_SHAR}/rmak"			# remake file
#	declare -r    _DIRS_CHRT="${_DIRS_SHAR}/chroot"			# container file
	declare -r    _DIRS_CTNR="${_DIRS_SHAR}/containers"		# container file
	declare -r    _DIRS_CACH="${_DIRS_SHAR}/cache"			# cache file

	# --- shell script --------------------------------------------------------
#	declare -r    _SHEL_ERLY="${_DIRS_SHEL}/autoinst_cmd_early.sh"				# shell commands to run early
	declare -r    _SHEL_LATE="${_DIRS_SHEL}/autoinst_cmd_late.sh"				# shell commands to run late
#	declare -r    _SHEL_PART="${_DIRS_SHEL}/autoinst_cmd_part.sh"				# shell commands to run after partition
#	declare -r    _SHEL_RUNS="${_DIRS_SHEL}/autoinst_cmd_run.sh"				# shell commands to run preseed/run

	# === mkosi ver. 25.3 for debian ==========================================

	# --- mkosi target distribution -------------------------------------------
#	declare -r    _TGET_DIST="fedora"
#	declare -r    _TGET_DIST="debian"
#	declare -r    _TGET_DIST="kali"
#	declare -r    _TGET_DIST="ubuntu"
#	declare -r    _TGET_DIST="arch"
#	declare -r    _TGET_DIST="opensuse"
#	declare -r    _TGET_DIST="mageia"
#	declare -r    _TGET_DIST="centos"
#	declare -r    _TGET_DIST="rhel"
#	declare -r    _TGET_DIST="rhel-ubi"
#	declare -r    _TGET_DIST="openmandriva"
#	declare -r    _TGET_DIST="rocky"
#	declare -r    _TGET_DIST="alma"
#	declare -r    _TGET_DIST="azure"

	# --- mkosi output image format type --------------------------------------
	declare -r    _TGET_MDIA="directory"
#	declare -r    _TGET_MDIA="tar"
#	declare -r    _TGET_MDIA="cpio"
#	declare -r    _TGET_MDIA="disk"
#	declare -r    _TGET_MDIA="uki"
#	declare -r    _TGET_MDIA="esp"
#	declare -r    _TGET_MDIA="oci"
#	declare -r    _TGET_MDIA="sysext"
#	declare -r    _TGET_MDIA="confext"
#	declare -r    _TGET_MDIA="portable"
#	declare -r    _TGET_MDIA="addon"
#	declare -r    _TGET_MDIA="none"

	# --- live media parameter ------------------------------------------------
	declare       _DIRS_LIVE=""			# live / LiveOS
	declare       _FILE_LIVE=""			# filesystem.squashfs / squashfs.img

	# --- menu parameter ------------------------------------------------------
	declare -r    _MENU_TOUT="5"		# timeout (sec)
#	declare -r    _MENU_RESO="1280x720"	# resolution (widht x hight): 16:9
	declare -r    _MENU_RESO="854x480"	# "                         : 16:9
#	declare -r    _MENU_RESO="1024x768"	# "                         :  4:3
#	declare -r    _MENU_DPTH=""			# colors
#	declare -r    _MENU_MODE=""			# screen mode (vga=nnn)
	declare       _MENU_SPLS=""			# splash file

# -----------------------------------------------------------------------------
# descript: exec mkosi
#   input :   $1   : target configuration file
#   input :   $2   : target media type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)
#   input :   $3   : target distribution (fedora,  debian,  kali, ubuntu,  arch,  opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
#   input :   $4   : target release version
#   input :   $5   : work directory
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnExec_mkosi() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnExec_mkosi"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __TGET_INCL="${1:-}"	# target include configuration file
	declare -r    __TGET_MDIA="${2:-}"	# target media type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)
	declare -r    __TGET_DIST="${3:-}"	# target distribution (fedora,  debian,  kali, ubuntu,  arch,  opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
	declare -r    __TGET_VERS="${4:-}"	# target release version
	declare -r    __DIRS_WDIR="${5:-}"	# work directory
	declare -r    __DIRS_CACH="${6:-}"	# cache directory
	declare -r    __COMD_MKOS="${7:-}"	# mkosi command
	declare -i    __RTCD=0				# return code
	declare -r -a __OPTN=(\
		--force \
		--wipe-build-dir \
		--bootable=no \
		--selinux-relabel=yes \
		--with-network=yes \
		${__TGET_INCL:+--include="${__TGET_INCL}"} \
		${__TGET_MDIA:+--format="${__TGET_MDIA}"} \
		${__TGET_DIST:+--distribution="${__TGET_DIST%%-*}"} \
		${__TGET_VERS:+--release="${__TGET_VERS}"} \
		${__DIRS_WDIR:+--workspace-directory="${__DIRS_WDIR}/workspace"} \
		${__DIRS_CACH:+--cache-directory="${__DIRS_CACH}"} \
		${__DIRS_CACH:+--package-cache-dir="${__DIRS_CACH}"} \
		${__DIRS_WDIR:+--directory="${__DIRS_WDIR}/source"} \
		${__DIRS_WDIR:+--output-directory="${__DIRS_WDIR}"} \
		${__COMD_MKOS:+"${__COMD_MKOS}"} \
	)

	if [[ -e "${_SHEL_LATE:-}" ]]; then
		cp --preserve=timestamps "${_SHEL_LATE}" "${__DIRS_WDIR}/source"
		chmod +x "${__DIRS_WDIR}/source/${_SHEL_LATE##*/}"
	fi
	if [[ -n "${_DBGS_SIMU:-}" ]]; then
		printf "%s %s\n" "mkosi" "${__OPTN[*]}" > "${PWD}/mkosi.debugout"
		cp -a "${__DIRS_WDIR}/source/${_SHEL_LATE##*/}" "${PWD}"
	fi
	if ! nice -n 0 mkosi "${__OPTN[@]}" 2>&1 | tee "${PWD}/mkosi.debuglog"; then
		__RTCD="$?"
		printf "%s %s\n" "mkosi" "${__OPTN[*]}" > "${PWD}/mkosi.debugout"
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "mkosi failed."
		printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "Working files will be deleted when this shell exits."
		read -r -p "Press any key to exit..."
		exit "${__RTCD}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create squashfs file
#   input :   $1   : work directory
#   input :   $2   : menu target name
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_squashfs() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_squashfs"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_NAME="${2:-}"	# menu target name
	declare -r    __DIRS_MNTP="${__DIRS_WDIR}/image"
	declare -r    __PATH_SRCS="${__DIRS_WDIR}/image.raw"
	declare -r    __PATH_SQFS="${__DIRS_WDIR}/${_FILE_LIVE}"
	declare       __PATH=""				# full path
	declare -a    __ARRY=()				# array
	declare -i    __SECT=0				# sector size
	declare -i    __STRT=0				# start sector

	printf "\033[m${_PROG_NAME}: \033[42m%s\033[m\n" " create mode: ${__TGET_MDIA:-"default"}"

	# --- if the image format type is disk ------------------------------------
	if [[ -e "${__PATH_SRCS}" ]]; then
		# --- directory initializing ------------------------------------------
		rm -rf "${__DIRS_MNTP:?}"
		mkdir -p "${__DIRS_MNTP}"

		# --- get offset sector -----------------------------------------------
		__ARRY=("$(fdisk -l "${__PATH_SRCS}")")
		__SECT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/Sector size/ s/^.*:[ \t]*\([0-9,]\+\)[ \t]*.*$/\1/p')"
		__STRT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/'"${__PATH_SRCS##*/}"'1/ s/^[^ \t]\+[ \t]\+\([0-9,]\+\)[ \t]\+.*$/\1/p')"

		# --- mount -----------------------------------------------------------
		mount -t ext4 -o loop,ro,offset=$((__SECT*__STRT)) "${__PATH_SRCS}" "${__DIRS_MNTP}" && _LIST_RMOV+=("${__DIRS_MNTP:?}")
	fi

	# --- copy initrd/vmlinux -------------------------------------------------
	find "${__DIRS_MNTP}/boot" -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*' -o -name linux                                                 \) -exec cp --preserve=timestamps '{}' "${__DIRS_WDIR}" \;
	find "${__DIRS_MNTP}/boot" -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  -o -name initrd.gz -o -name 'initramfs' -o -name 'initramfs-*' \) -exec cp --preserve=timestamps '{}' "${__DIRS_WDIR}" \;

	if command -v convert > /dev/null 2>&1; then
		case "${__TGET_NAME}" in
			debian-6.0         ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/spacefun-theme/grub/grub-16x9.png       ;;
			debian-7.0         ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/joy-theme/grub/grub-16x9.png            ;;
			debian-8.0         ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/lines-theme/grub/grub-16x9.png          ;;
			debian-9.0         ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/softwaves-theme/grub/grub-16x9.png      ;;
			debian-10.0        ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/futureprototype-theme/grub/grub-16x9.png;;
			debian-11.0        ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/homeworld-theme/grub/grub-16x9.png      ;;
			debian-12.0        ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/emerald-theme/grub/grub-16x9.png        ;;
			debian-13.0        ) __PATH="${__DIRS_MNTP}"/usr/share/desktop-base/ceratopsian-theme/grub/grub-16x9.png    ;;
			debian-14.0        ) ;;
			debian-15.0        ) ;;
			debian-testing     ) ;;
			debian-sid         ) ;;
			ubuntu-16.04       ) ;;
			ubuntu-18.04       ) ;;
			ubuntu-20.04       ) ;;
			ubuntu-22.04       ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/warty-final-ubuntu.png;;
			ubuntu-24.04       ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/warty-final-ubuntu.png;;
			ubuntu-24.10       ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/warty-final-ubuntu.png;;
			ubuntu-25.04       ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/warty-final-ubuntu.png;;
			ubuntu-25.10       ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/warty-final-ubuntu.png;;
			fedora-42          ) ;;
			fedora-43          ) ;;
			centos-9           ) ;;
			centos-10          ) ;;
			alma-9             ) ;;
			alma-10            ) __PATH="${__DIRS_MNTP}"/usr/share/backgrounds/almalinux-day.jpg;;
			rocky-9            ) ;;
			rocky-10           ) ;;
#			miraclelinux-9     ) ;;
#			miraclelinux-10    ) ;;
			opensuse-leap-15   ) ;;
			opensuse-leap-16   ) ;;
			opensuse-tumbleweed) ;;
#			kali-*             ) ;;
#			arch-*             ) ;;
#			mageia-*           ) ;;
#			rhel-ubi-*         ) ;;
#			rhel-*             ) ;;
#			openmandriva-*     ) ;;
#			azure-*            ) ;;
#			custom-*           ) ;;
			*                  ) echo "not found: ${__TGET_NAME:-}"; exit 1;;
		esac
		# --- convert splash file ---------------------------------------------
		if [[ -n "${__PATH:-}" ]] && [[ -e "${__PATH}" ]]; then
			_MENU_SPLS="${__DIRS_WDIR}/splash.png"
			convert "${__PATH}" -format "png" -resize "${_MENU_RESO}" "${_MENU_SPLS}" || true
		fi
	fi

	# --- clean up ------------------------------------------------------------
	rm -rf "${__DIRS_MNTP}"/{.autorelabel,.cache,work}

	# --- create squashfs file ------------------------------------------------
	mksquashfs "${__DIRS_MNTP}" "${__PATH_SQFS}" -noappend

	# --- unmount -------------------------------------------------------------
	if [[ -e "${__PATH_SRCS}" ]]; then
		umount "${__DIRS_MNTP}"
	fi

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create uefi/biso image
#   input :   $1   : work directory
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_ueif_bios_image() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_ueif_bios_image"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_DIST="${2:-}"	# target distribution (fedora,  debian,  kali, ubuntu,  arch,  opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
	declare -r    __DIRS_MNTP="${__DIRS_WDIR}/mnt"
	declare -r    __PATH_UEFI="${__DIRS_WDIR}/uefi.img"
	declare -a    __ARRY=()				# array
	declare -i    __SECT=0				# sector size
	declare -i    __STRT=0				# start sector
	declare       __LOOP=""				# loop device

	# --- directory initializing ----------------------------------------------
	rm -rf "${__DIRS_MNTP:?}"
	mkdir -p "${__DIRS_MNTP}"

	# --- create dummy image --------------------------------------------------
	dd if=/dev/zero of="${__PATH_UEFI}" bs=1M count=100
	__LOOP="$(losetup --find --show "${__PATH_UEFI}")"
	sfdisk "${__LOOP}" <<- _EOT_
		,,U,
_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1

	# --- install grub module -------------------------------------------------
	rm -rf "${__DIRS_MNTP:?}"
	mkdir -p "${__DIRS_MNTP}"
	mount "${__LOOP}"p1 "${__DIRS_MNTP}" && _LIST_RMOV+=("${__DIRS_MNTP:?}")
	grub-install \
		--target=x86_64-efi \
		--efi-directory="${__DIRS_MNTP}" \
		--boot-directory="${__DIRS_MNTP}/boot" \
		--bootloader-id="${__TGET_DIST%%-*}" \
		--removable
	grub-install \
		--target=i386-pc \
		--boot-directory="${__DIRS_MNTP}/boot" \
		"${__LOOP}"
	cp --preserve=timestamps --recursive "${__DIRS_MNTP}/." "${__DIRS_WDIR}"
	umount "${__DIRS_MNTP}"
	losetup --detach "${__LOOP}"

	# --- create uefi/bios image ----------------------------------------------
	__ARRY=("$(fdisk -l "${__PATH_UEFI}")")
	__SECT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/Sector size/ s/^.*:[ \t]*\([0-9,]\+\)[ \t]*.*$/\1/p')"
	__STRT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/'"${__PATH_UEFI##*/}"'1/ s/^[^ \t]\+[ \t]\+\([0-9,]\+\)[ \t]\+.*$/\1/p')"
	__CONT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/'"${__PATH_UEFI##*/}"'1/ s/^[^ \t]\+[ \t]\+[0-9,]\+[ \t]\+[0-9,]\+[ \t]\+\([0-9,]\+\)[ \t]\+.*$/\1/p')"
	dd if="${__PATH_UEFI}" of="${__DIRS_WDIR}/efi.img" bs="${__SECT}" skip="${__STRT}" count="${__CONT}"
	dd if="${__PATH_UEFI}" of="${__DIRS_WDIR}/bios.img" bs=1 count=446

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create cdfs directory
#   input :   $1   : work directory
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_cdfs() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_cdfs"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_DIST="${2:-}"	# target distribution (fedora,  debian,  kali, ubuntu,  arch,  opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)
	declare -r    __DIRS_MNTP="${__DIRS_WDIR}/mnt"
	declare -r    __DIRS_CDFS="${__DIRS_WDIR}/cdfs"
	declare -r    __PATH_UEFI="${__DIRS_WDIR}/uefi.img"
	declare -a    __ARRY=()				# array
	declare -i    __SECT=0				# sector size
	declare -i    __STRT=0				# start sector
	declare       __LOOP=""				# loop device

	# --- directory initializing ----------------------------------------------
	rm -rf "${__DIRS_CDFS:?}"
	mkdir -p "${__DIRS_CDFS}"/{.disk,EFI/{BOOT,"${__TGET_DIST%%-*}"},boot/grub/{i386-pc,x86_64-efi},isolinux,${_DIRS_LIVE}/{boot,config.conf.d,config-hooks,config-preseed}}

	# --- create cdfs image ---------------------------------------------------
	touch "${__DIRS_CDFS}/.disk/info"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__DIRS_CDFS}/EFI/BOOT/grub.cfg" || true
		search --file --set=root /.disk/info
		set prefix=($root)/boot/grub
		source $prefix/grub.cfg
_EOT_

	find "${__DIRS_WDIR}" -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*' -o -name linux                                                 \) -exec cp --preserve=timestamps '{}' "${__DIRS_CDFS}/${_DIRS_LIVE}"            \;
	find "${__DIRS_WDIR}" -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  -o -name initrd.gz -o -name 'initramfs' -o -name 'initramfs-*' \) -exec cp --preserve=timestamps '{}' "${__DIRS_CDFS}/${_DIRS_LIVE}"            \;
	find "${__DIRS_WDIR}" -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*' -o -name linux                                                 \) -exec cp --preserve=timestamps '{}' "${__DIRS_CDFS}/${_DIRS_LIVE}/vmlinuz"    \;
	find "${__DIRS_WDIR}" -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  -o -name initrd.gz -o -name 'initramfs' -o -name 'initramfs-*' \) -exec cp --preserve=timestamps '{}' "${__DIRS_CDFS}/${_DIRS_LIVE}/initrd.img" \;
	[[ -e "${__DIRS_WDIR}/${_FILE_LIVE}"   ]] && cp --preserve=timestamps             "${__DIRS_WDIR}/${_FILE_LIVE}"   "${__DIRS_CDFS}/${_DIRS_LIVE}/"
	[[ -e "${__DIRS_WDIR}/efi.img"         ]] && cp --preserve=timestamps             "${__DIRS_WDIR}/efi.img"         "${__DIRS_CDFS}/boot/grub/"
	[[ -e /usr/lib/grub/i386-pc/.          ]] && cp --preserve=timestamps --recursive /usr/lib/grub/i386-pc/*          "${__DIRS_CDFS}/boot/grub/i386-pc/"
	[[ -e /usr/lib/grub/x86_64-efi/.       ]] && cp --preserve=timestamps --recursive /usr/lib/grub/x86_64-efi/*       "${__DIRS_CDFS}/boot/grub/x86_64-efi/"
	[[ -e /usr/lib/syslinux/modules/bios/. ]] && cp --preserve=timestamps --recursive /usr/lib/syslinux/modules/bios/* "${__DIRS_CDFS}/isolinux/"
	[[ -e /usr/lib/ISOLINUX/isolinux.bin   ]] && cp --preserve=timestamps             /usr/lib/ISOLINUX/isolinux.bin   "${__DIRS_CDFS}/isolinux/"
	[[ -e "${_MENU_SPLS:-}"                ]] && cp --preserve=timestamps             "${_MENU_SPLS}"                  "${__DIRS_CDFS}/isolinux/"

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create menu isolinux.cfg
#   input :   $1   : work directory
#   input :   $2   : menu target name
#   input :   $3   : boot parameter
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_menu_isolinux() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_menu_isolinux"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_NAME="${2:-}"	# menu target name
	declare -r    __OPTN_BOOT="${3:-}"	# boot parameter
	declare -r    __DIRS_CDFS="${__DIRS_WDIR}/cdfs"

	# --- create isolinux.cfg -------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__DIRS_CDFS}/isolinux/isolinux.cfg" || true
		path

		default             vesamenu.c32

		menu resolution     ${_MENU_RESO//x/ }
		menu title          Boot Menu: Live media
		menu background     ${_MENU_SPLS##*/}
		menu color title    * #FFFFFFFF *
		menu color border   * #00000000 #00000000 none
		menu color sel      * #ffffffff #76a1d0ff *
		menu color hotsel   1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg   * #ffffffff #00000000 *
		menu color help     37;40 #ffdddd00 #00000000 none
		menu vshift         8
		menu rows           12
		menu helpmsgrow     14
		menu cmdlinerow     16
		menu timeoutrow     16
		menu tabmsgrow      18
		menu tabmsg         Press ENTER to boot or TAB to edit a menu entry

		label live
		  menu label ^${__TGET_NAME}
		  menu default
		  linux  /${_DIRS_LIVE}/vmlinuz
		  initrd /${_DIRS_LIVE}/initrd.img
		  append ${__OPTN_BOOT}

		label poweroff
		  menu label ^System shutdown
		  com32 poweroff.c32

		label reboot
		  menu label ^System restart
		  com32 reboot.c32

		prompt 0
		timeout ${_MENU_TOUT}0
_EOT_

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create menu theme.txt
#   input :   $1   : work directory
#   input :   $2   : menu target name
#   input :   $3   : boot parameter
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_menu_theme() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_menu_theme"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_NAME="${2:-}"	# menu target name
	declare -r    __OPTN_BOOT="${3:-}"	# boot parameter
	declare -r    __DIRS_CDFS="${__DIRS_WDIR}/cdfs"

	# --- create theme.txt ----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__DIRS_CDFS}/boot/grub/theme.txt" || true
		desktop-image: "/isolinux/${_MENU_SPLS##*/}"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: Live media"
		message-font: "Unifont Regular 16"
		terminal-font: "Unifont Regular 16"
		terminal-border: "0"

		#help bar at the bottom
		+ label {
		  top = 100%-50
		  left = 0
		  width = 100%
		  height = 20
		  text = "@KEYMAP_SHORT@"
		  align = "center"
		  color = "#ffffff"
		  font = "Unifont Regular 16"
		}

		#boot menu
		+ boot_menu {
		  left = 10%
		  width = 80%
		  top = 20%
		  height = 50%-80
		  item_color = "#a8a8a8"
		  item_font = "Unifont Regular 16"
		  selected_item_color= "#ffffff"
		  selected_item_font = "Unifont Regular 16"
		  item_height = 16
		  item_padding = 0
		  item_spacing = 4
		  icon_width = 0
		  icon_heigh = 0
		  item_icon_space = 0
		}

		#progress bar
		+ progress_bar {
		  id = "__timeout__"
		  left = 15%
		  top = 100%-80
		  height = 16
		  width = 70%
		  font = "Unifont Regular 16"
		  text_color = "#000000"
		  fg_color = "#ffffff"
		  bg_color = "#a8a8a8"
		  border_color = "#ffffff"
		  text = "@TIMEOUT_NOTIFICATION_LONG@"
		}
_EOT_

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create menu grub.cfg
#   input :   $1   : work directory
#   input :   $2   : menu target name
#   input :   $3   : boot parameter
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_menu_grub() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_menu_grub"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_NAME="${2:-}"	# menu target name
	declare -r    __OPTN_BOOT="${3:-}"	# boot parameter
	declare -r    __DIRS_CDFS="${__DIRS_WDIR}/cdfs"

	# --- create theme.txt ----------------------------------------------------
	# https://www.gnu.org/software/grub/
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__DIRS_CDFS}/boot/grub/grub.cfg" || true
		set font="\${prefix}/font.pf2"
		if [ "\${feature_default_font_path}" = "y" ]; then
		  set font="unicode"
		fi

		loadfont "\${font}"
		set gfxpayload="keep"
		set gfxmode="${_MENU_RESO}"
		insmod efi_gop
		insmod efi_uga
		insmod video_bochs
		insmod video_cirrus
		insmod all_video
		insmod gfxterm
		insmod png
		terminal_output gfxterm

		set menu_color_normal="cyan/blue"
		set menu_color_highlight="white/blue"

		set wall=""
		if [ -e "/isolinux/${_MENU_SPLS##*/}" ]; then
		  wall="/isolinux/${_MENU_SPLS##*/}"
		elif [ -e "/${_MENU_SPLS##*/}" ]; then
		  wall="/${_MENU_SPLS##*/}"
		fi
		if [ -n "\${wall}" ]; then
		  if background_image --mode stretch "\${wall}"; then
		    unset menu_color_normal
		    unset menu_color_highlight
		    set color_normal="light-gray/black"
		    set color_highlight="white/black"
		  fi
		fi

		insmod play
		play 960 440 1 0 4 440 1

		set default="0"
		set timeout="5"
		set timeout_style="menu"
		set theme="/boot/grub/theme.txt"
		export theme

		insmod net
		insmod http
		insmod progress
		insmod gzio
		insmod part_gpt
		insmod ext2
		insmod chain

		menuentry '${__TGET_NAME}' {
		  echo '${__TGET_NAME} ...'
		  set gfxpayload="keep"
		  set background_color="black"
		  set options="${__OPTN_BOOT}"
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading linux ...'
		  linux  /${_DIRS_LIVE}/vmlinuz \${options}
		  echo 'Loading initrd ...'
		  initrd /${_DIRS_LIVE}/initrd.img
		}

		menuentry 'System shutdown' {
		  echo 'System shutting down ...'
		  halt
		}

		menuentry 'System restart' {
		  echo 'System rebooting ...'
		  reboot
		}

		if [ "\${grub_platform}" = "efi" ]; then
		  menuentry 'Boot from next volume' {
		    exit 1
		  }

		  menuentry 'UEFI Firmware Settings' {
		    fwsetup
		  }
		fi
_EOT_

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# -----------------------------------------------------------------------------
# descript: create iso image
#   input :   $1   : work directory
#   input :   $2   : menu target name
#   input :   $3   : target file
#   output: stdout : unused
#   return:        : unused
#-shellcheck disable=SC2317,SC2329
function fnCreate_iso_image() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_iso_image"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __DIRS_WDIR="${1:-}"	# work directory
	declare -r    __TGET_NAME="${2:-}"	# menu target name
	declare -r    __TGET_PATH="${3:-}"	# target file
	declare -r    __DIRS_CDFS="${__DIRS_WDIR}/cdfs"
	declare -i    __RTCD=0				# return code
	declare       __PATH=""				# full path
	              __PATH="$(mktemp -q -p "${__DIRS_WDIR}" "${__TGET_PATH##*/}.XXXXXX")"
	readonly      __PATH
	declare -r -a __OPTN=(\
		-rational-rock \
		-volid "${__TGET_NAME^}-Live-Media" \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		--grub2-mbr ../bios.img \
		--mbr-force-bootable \
		-append_partition 2 0xEF boot/grub/efi.img \
		-appended_part_as_gpt \
		-eltorito-catalog isolinux/boot.catalog \
		-eltorito-boot isolinux/isolinux.bin \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot \
		-output "${__PATH}" \
		.
	)

	# --- create iso image ----------------------------------------------------
	pushd "${__DIRS_CDFS}" > /dev/null || exit
		if ! nice -n -0 xorrisofs "${__OPTN[@]}"  . > /dev/null 2>&1; then
			__RTCD="$?"
			printf "%s %s\n" "xorrisofs" "${__OPTN[*]}" > "${PWD}/xorrisofs.debugout"
			printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n"     "xorr  failed: ${__TGET_PATH##*/}"
			printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "Working files will be deleted when this shell exits."
			read -r -p "Press any key to exit..."
			exit "${__RTCD}"
		else
			if ! cp --preserve=timestamps "${__PATH}" "${__TGET_PATH}"; then
				printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "  cp failed.: ${__TGET_PATH##*/}"
				printf "\033[m${_PROG_NAME}: \033[91m%s\033[m\n" "Working files will be deleted when this shell exits."
				read -r -p "Press any key to exit..."
				exit "${__RTCD}"
			else
				printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "     success: ${__TGET_PATH##*/}" 1>&2
				ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${__TGET_PATH}" || true
			fi
		fi
		rm -f "${__PATH:?}"
	popd > /dev/null

	# --- complete ------------------------------------------------------------
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

function fnCreate_media() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnCreate_media"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -r    __TGET_INCL="${1:-}"	# target configuration file
	declare -r    __TGET_MDIA="${2:-}"	# target media type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)
	declare -r    __TGET_DIST="${3:-}"	# target distribution (fedora, debian, kali, ubuntu, arch, opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure)-version
	declare -r    __TGET_VERS="${4:-}"	# target release version
	declare -r    __DIRS_WDIR="${_DIRS_WDIR}/${__TGET_DIST}"
	declare -r    __DIRS_CACH="${_DIRS_CACH}/${__TGET_DIST}"
	declare -r    __DIRS_MNTP="${__DIRS_WDIR}/image"
	declare -a    __OPTN_BOOT=()
	declare -r -a _BOOT_DEBS=(\
		"boot=${_DIRS_LIVE}" \
		"nonetworking" \
		"dhcp" \
		"components" \
		"overlay-size=90%" \
		"hooks=medium" \
		"utc=yes" \
		"locales=ja_JP.UTF-8" \
		"timezone=Asia/Tokyo" \
		"keyboard-layouts=jp,us" \
		"keyboard-model=pc105" \
		"keyboard-variants=," \
		"---" \
		"quiet" \
		"splash" \
		"fsck.mode=skip" \
		"raid=noautodetect" \
		"${_MENU_MODE:+"vga=${_MENU_MODE}"}" \
	)
	declare -r -a _BOOT_RHEL=(\
		"ip=dhcp" \
		"root=live:LABEL=${__TGET_DIST^}-Live-Media" \
		"rd.locale.LANG=ja_JP.utf8" \
		"rd.vconsole.keymap=jp" \
		"rd.live.image=1" \
		"${_MENU_MODE:+"vga=${_MENU_MODE}"}" \
	)
	declare -r -a _BOOT_SUSE=(\
	)
	declare -i    __SLNX=0				# selinux 0:disable/1:enable

	rm -rf "${__DIRS_WDIR:?}"
	mkdir -p "${__DIRS_WDIR}"/{workspace,source}

	fnExec_mkosi "${__TGET_INCL:-}" "${__TGET_MDIA:-}" "${__TGET_DIST:-}" "${__TGET_VERS:-}" "${__DIRS_WDIR:-}" "${__DIRS_CACH:-}" "${_DBGS_SIMU:+"summary"}"

	# --- boot parameter ------------------------------------------------------
	case "${__TGET_DIST%%-*}" in
		debian         | \
		ubuntu         ) __OPTN_BOOT=("${_BOOT_DEBS[@]}");;
		fedora         | \
		centos         | \
		alma           | \
		rocky          ) __OPTN_BOOT=("${_BOOT_RHEL[@]}");;
		opensuse       ) __OPTN_BOOT=("${_BOOT_SUSE[@]}");;
		*              ) ;;
	esac

	# --- apparmor/selinux ----------------------------------------------------
	case "${__TGET_DIST%%-*}" in
		debian | ubuntu ) __SLNX=0;;
		*               ) __SLNX=1;;
	esac
	if [[ -e "${__DIRS_MNTP:-}"/usr/bin/aa-enabled ]]; then
		printf "\033[m${_PROG_NAME}: \033[93m%s\033[m\n" "activating apparmor"
		__OPTN_BOOT+=("security=apparmor apparmor=1")
	elif [[ -e "${__DIRS_MNTP:-}"/usr/bin/getenforce  ]] \
	||   [[ -e "${__DIRS_MNTP:-}"/usr/sbin/getenforce ]]; then
		printf "\033[m${_PROG_NAME}: \033[93m%s\033[m\n" "activating se linux"
		__OPTN_BOOT+=("security=selinux selinux=1 enforcing=${__SLNX:-0}")
	fi

	# --- create media file ---------------------------------------------------
	if [[ -z "${_DBGS_SIMU:-}" ]]; then
		fnCreate_squashfs        "${__DIRS_WDIR:-}" "${__TGET_DIST}"
		fnCreate_ueif_bios_image "${__DIRS_WDIR:-}" "${__TGET_DIST}"
		fnCreate_cdfs            "${__DIRS_WDIR:-}" "${__TGET_DIST}"
		fnCreate_menu_isolinux   "${__DIRS_WDIR:-}" "${__TGET_DIST^}" "${__OPTN_BOOT[*]}"
		fnCreate_menu_theme      "${__DIRS_WDIR:-}" "${__TGET_DIST^}" "${__OPTN_BOOT[*]}"
		fnCreate_menu_grub       "${__DIRS_WDIR:-}" "${__TGET_DIST^}" "${__OPTN_BOOT[*]}"
		fnCreate_iso_image       "${__DIRS_WDIR:-}" "${__TGET_DIST^}" "${_DIRS_RMAK}/live-${__TGET_DIST}.iso"
	fi

	rm -rf "${__DIRS_WDIR:?}"

	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

function fnMain() {
#	_DBGS_FAIL+=("fail")
	declare -r    __FUNC_NAME="fnMain"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"

	declare -i    __time_start=0		# start of elapsed time
	declare -i    __time_end=0			# end of elapsed time
	declare -i    __time_elapsed=0		# result of elapsed time
	declare -a    __OPTN=()
	declare       __DIST=""
	declare       __VERS=""
	declare       __CODE=""

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__OPTN=()
		case "${1:-}" in
			fedora-*       | \
			debian-*       | \
			kali-*         | \
			ubuntu-*       | \
			arch-*         | \
			opensuse-*     | \
			mageia-*       | \
			centos-*       | \
			rhel-ubi-*     | \
			rhel-*         | \
			openmandriva-* | \
			rocky-*        | \
			alma-*         | \
			azure-*        )
				__DIST="${1,,}"
#				[[ "${__DIST%.*}" = "debian-${__DIST#*-}" ]] && __DIST="${__DIST}.0"
				__VERS="${__DIST#*-}"
				case "${__DIST}" in
					debian-1.1         ) __CODE="buzz"     ;;
					debian-1.2         ) __CODE="rex"      ;;
					debian-1.3         ) __CODE="bo"       ;;
					debian-2.0         ) __CODE="hamm"     ;;
					debian-2.1         ) __CODE="slink"    ;;
					debian-2.2         ) __CODE="potato"   ;;
					debian-3.0         ) __CODE="woody"    ;;
					debian-3.1         ) __CODE="sarge"    ;;
					debian-4.0         ) __CODE="etch"     ;;
					debian-5.0         ) __CODE="lenny"    ;;
					debian-6.0         ) __CODE="squeeze"  ;;
					debian-7.0         ) __CODE="wheezy"   ;;
					debian-8.0         ) __CODE="jessie"   ;;
					debian-9.0         ) __CODE="stretch"  ;;
					debian-10.0        ) __CODE="buster"   ;;
					debian-11.0        ) __CODE="bullseye" ;;
					debian-12.0        ) __CODE="bookworm" ;;
					debian-13.0        ) __CODE="trixie"   ;;
					debian-14.0        ) __CODE="forky"    ;;
					debian-15.0        ) __CODE="duke"     ;;
					debian-testing     ) __CODE="testing"  ;;
					debian-sid         ) __CODE="sid"      ;;
					ubuntu-4.10        ) __CODE="warty"    ;;
					ubuntu-5.04        ) __CODE="hoary"    ;;
					ubuntu-5.10        ) __CODE="breezy"   ;;
					ubuntu-6.06        ) __CODE="dapper"   ;;
					ubuntu-6.10        ) __CODE="edgy"     ;;
					ubuntu-7.04        ) __CODE="feisty"   ;;
					ubuntu-7.10        ) __CODE="gutsy"    ;;
					ubuntu-8.04        ) __CODE="hardy"    ;;
					ubuntu-8.10        ) __CODE="intrepid" ;;
					ubuntu-9.04        ) __CODE="jaunty"   ;;
					ubuntu-9.10        ) __CODE="karmic"   ;;
					ubuntu-10.04       ) __CODE="lucid"    ;;
					ubuntu-10.10       ) __CODE="maverick" ;;
					ubuntu-11.04       ) __CODE="natty"    ;;
					ubuntu-11.10       ) __CODE="oneiric"  ;;
					ubuntu-12.04       ) __CODE="precise"  ;;
					ubuntu-12.10       ) __CODE="quantal"  ;;
					ubuntu-13.04       ) __CODE="raring"   ;;
					ubuntu-13.10       ) __CODE="saucy"    ;;
					ubuntu-14.04       ) __CODE="trusty"   ;;
					ubuntu-14.10       ) __CODE="utopic"   ;;
					ubuntu-15.04       ) __CODE="vivid"    ;;
					ubuntu-15.10       ) __CODE="wily"     ;;
					ubuntu-16.04       ) __CODE="xenial"   ;;
					ubuntu-16.10       ) __CODE="yakkety"  ;;
					ubuntu-17.04       ) __CODE="zesty"    ;;
					ubuntu-17.10       ) __CODE="artful"   ;;
					ubuntu-18.04       ) __CODE="bionic"   ;;
					ubuntu-18.10       ) __CODE="cosmic"   ;;
					ubuntu-19.04       ) __CODE="disco"    ;;
					ubuntu-19.10       ) __CODE="eoan"     ;;
					ubuntu-20.04       ) __CODE="focal"    ;;
					ubuntu-20.10       ) __CODE="groovy"   ;;
					ubuntu-21.04       ) __CODE="hirsute"  ;;
					ubuntu-21.10       ) __CODE="impish"   ;;
					ubuntu-22.04       ) __CODE="jammy"    ;;
					ubuntu-22.10       ) __CODE="kinetic"  ;;
					ubuntu-23.04       ) __CODE="lunar"    ;;
					ubuntu-23.10       ) __CODE="mantic"   ;;
					ubuntu-24.04       ) __CODE="noble"    ;;
					ubuntu-24.10       ) __CODE="oracular" ;;
					ubuntu-25.04       ) __CODE="plucky"   ;;
					ubuntu-25.10       ) __CODE="questing" ;;
					*                  ) __CODE="${1#*-}";;
				esac
				case "${__DIST:-}" in
					debian-*       | \
					ubuntu-*       ) _DIRS_LIVE="live"; _FILE_LIVE="filesystem.squashfs";;
					fedora-*       | \
					centos-*       | \
					alma-*         | \
					rocky-*        ) _DIRS_LIVE="LiveOS"; _FILE_LIVE="squashfs.img";;
					opensuse-*     ) _DIRS_LIVE="LiveOS"; _FILE_LIVE="squashfs.img";;
					*              ) ;;
				esac
				if [[ -n "${__DIST:-}" ]] && [[ -n "${_DIRS_LIVE:-}" ]] && [[ -n "${_FILE_LIVE:-}" ]]; then
					fnCreate_media "${_DIRS_MKOS}" "${_TGET_MDIA}" "${__DIST}" "${__CODE:-}"
				fi
				;;
			help    ) shift; fnHelp; break;;
#			debug   ) shift; fnDebug_parameter; break;;
			*       ) ;;
		esac
		shift
#		__OPTN=("${@:-}")
#		set -f -- "${__OPTN[@]}"
#		set +f
	done

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end-__time_start))

	printf "\033[m\033[45m%s\033[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))

	printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
}

# *** main processing section *************************************************
	fnMain "${_PROG_PARM[@]:-}"
#	read -r -p "Press any key to exit..."
	exit 0

### eof #######################################################################
