#!/bin/bash

###############################################################################
##
##	overlay-fs test shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/05/01
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/05/01 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

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

	# --- constant for control code -------------------------------------------
	if [[ -z "${_CODE_ESCP+true}" ]]; then
		declare   _CODE_ESCP=""
		          _CODE_ESCP="$(printf '\033')"
		readonly  _CODE_ESCP
	fi

	# --- user name -----------------------------------------------------------
	declare       _USER_NAME="${USER:-"$(whoami || true)"}"

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare       _DIRS_TEMP=""
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
	declare -r    TMPDIR="${_DIRS_TEMP:-?}"

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# shellcheck disable=SC2317
function funcTrap() {
	declare       _PATH=""
	declare -i    I=0
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		_PATH="${_LIST_RMOV[I]}"
		if [[ -e "${_PATH}" ]] && mountpoint --quiet "${_PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${_PATH}" 1>&2
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		fi
	done
	if [[ -e "${_DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${_DIRS_TEMP}" 1>&2
		while read -r _PATH
		do
			printf "[%s]: umount \"%s\"\n" "-" "${_PATH}" 1>&2
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		done < <(grep "${_DIRS_TEMP:?}" /proc/mounts | cut -d ' ' -f 2 | sort -rV || true)
		rm -rf "${_DIRS_TEMP:?}"
	fi
}

	trap funcTrap EXIT

	# -------------------------------------------------------------------------
	declare       _CODE_NAME=""
	              _CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      _CODE_NAME

	if command -v apt-get > /dev/null 2>&1; then
		if ! ls /var/lib/apt/lists/*_"${_CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
			printf "%s\n" "please execute apt-get update:" 1>&2
			if [[ -n "${SUDO_USER:-}" ]] || { [[ -z "${SUDO_USER:-}" ]] && [[ "${_USER_NAME}" != "root" ]]; }; then
				echo -n "sudo "
			fi
			printf "%s\n" "apt-get update" 1>&2
			exit 1
		fi
		# ---------------------------------------------------------------------
		declare       _ARHC_MAIN=""
		              _ARHC_MAIN="$(dpkg --print-architecture)"
		readonly      _ARHC_MAIN
		declare       _ARCH_OTHR=""
		              _ARCH_OTHR="$(dpkg --print-foreign-architectures)"
		readonly      _ARCH_OTHR
		# --- for custom iso --------------------------------------------------
		declare -r -a PAKG_LIST=(\
		)
		# ---------------------------------------------------------------------
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_ARCH_OTHR:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			printf "%s\n" "please install these:" 1>&2
			if [[ "${_USER_NAME:-}" != "root" ]]; then
				printf "%s" "sudo " 1>&2
			fi
			printf "%s\n" "apt-get install ${PAKG_FIND% *}" 1>&2
			exit 1
		fi
	fi

	declare -r -a _LIST_MDIA=( \
		"mini.iso        m               menu-entry                              Auto%20install%20mini.iso               -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"mini.iso        o               debian-mini-11                          Debian%2011                             debian-11.0             debian-11.0             2021-08-14      2024-08-15      https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                                               https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                                               -                           -               -               :_DIRS_ISOS_:/mini-bullseye-amd64.iso                                                 2024-08-27%2006:14:31+09    54525952        ISOIMAGE                                    :_DIRS_RMAK_:/mini-bullseye-amd64_preseed.iso                                         -                           -               -                                           :_DIRS_LOAD_:/debian-mini-11/initrd.gz                                                :_DIRS_LOAD_:/debian-mini-11/linux                                                    :_DIRS_CONF_:/preseed/ps_debian_server_old.cfg                                        -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        o               debian-mini-12                          Debian%2012                             debian-12.0             debian-12.0             2023-06-10      2026-06-xx      https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                                               https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                                               -                           -               -               :_DIRS_ISOS_:/mini-bookworm-amd64.iso                                                 2025-03-10%2012:28:07+09    65011712        ISOIMAGE                                    :_DIRS_RMAK_:/mini-bookworm-amd64_preseed.iso                                         -                           -               -                                           :_DIRS_LOAD_:/debian-mini-12/initrd.gz                                                :_DIRS_LOAD_:/debian-mini-12/linux                                                    :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        o               debian-mini-13                          Debian%2013                             debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                                 https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                                 -                           -               -               :_DIRS_ISOS_:/mini-trixie-amd64.iso                                                   2024-12-27%2009:14:03+09    65011712        ISOIMAGE                                    :_DIRS_RMAK_:/mini-trixie-amd64_preseed.iso                                           -                           -               -                                           :_DIRS_LOAD_:/debian-mini-13/initrd.gz                                                :_DIRS_LOAD_:/debian-mini-13/linux                                                    :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        -               debian-mini-14                          Debian%2014                             debian-14.0             debian-14.0             2027-xx-xx      20xx-xx-xx      https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso                                                  https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso                                                  -                           -               -               :_DIRS_ISOS_:/mini-forky-amd64.iso                                                    -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-mini-14/initrd.gz                                                :_DIRS_LOAD_:/debian-mini-14/linux                                                    :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        o               debian-mini-testing                     Debian%20testing                        debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://ftp.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso                                                https://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso                                                -                           -               -               :_DIRS_ISOS_:/mini-testing-amd64.iso                                                  2024-12-27%2009:14:03+09    65011712        ISOIMAGE                                    :_DIRS_RMAK_:/mini-testing-amd64_preseed.iso                                          -                           -               -                                           :_DIRS_LOAD_:/debian-mini-testing/initrd.gz                                           :_DIRS_LOAD_:/debian-mini-testing/linux                                               :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        o               debian-mini-testing-daily               Debian%20testing%20daily                debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                                https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                                -                           -               -               :_DIRS_ISOS_:/mini-testing-daily-amd64.iso                                            2025-04-17%2000:02:11+09    67108864        ISOIMAGE                                    :_DIRS_RMAK_:/mini-testing-daily-amd64_preseed.iso                                    -                           -               -                                           :_DIRS_LOAD_:/debian-mini-testing-daily/initrd.gz                                     :_DIRS_LOAD_:/debian-mini-testing-daily/linux                                         :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"mini.iso        x               ubuntu-mini-20.04                       Ubuntu%2020.04                          ubuntu-20.04            ubuntu-20.04            2020-04-23      2025-05-29      http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso                                http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso                                        -                           -               -               :_DIRS_ISOS_:/mini-focal-amd64.iso                                                    2023-03-14%2022:28:31+09    82837504        CDROM                                       :_DIRS_RMAK_:/mini-focal-amd64_preseed.iso                                            -                           -               -                                           :_DIRS_LOAD_:/ubuntu-mini-20.04/initrd.gz                                             :_DIRS_LOAD_:/ubuntu-mini-20.04/linux                                                 :_DIRS_CONF_:/preseed/ps_ubuntu_server_old.cfg                                        -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"mini.iso        m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"netinst         m               menu-entry                              Auto%20install%20Net%20install          -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"netinst         o               debian-netinst-11                       Debian%2011                             debian-11.0             debian-11.0             2021-08-14      2024-08-15      https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso                                    https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso                                       -                           -               -               :_DIRS_ISOS_:/debian-11.11.0-amd64-netinst.iso                                        2024-08-31%2016:11:10+09    408944640       Debian%2011.11.0%20amd64%20n                :_DIRS_RMAK_:/debian-11.11.0-amd64-netinst_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/debian-netinst-11/install.amd/initrd.gz                                 :_DIRS_LOAD_:/debian-netinst-11/install.amd/vmlinuz                                   :_DIRS_CONF_:/preseed/ps_debian_server_old.cfg                                        -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"netinst         o               debian-netinst-12                       Debian%2012                             debian-12.0             debian-12.0             2023-06-10      2026-06-xx      https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso                                             https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso                                                -                           -               -               :_DIRS_ISOS_:/debian-12.10.0-amd64-netinst.iso                                        2025-03-15%2012:03:05+09    663748608       Debian%2012.10.0%20amd64%20n                :_DIRS_RMAK_:/debian-12.10.0-amd64-netinst_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/debian-netinst-12/install.amd/initrd.gz                                 :_DIRS_LOAD_:/debian-netinst-12/install.amd/vmlinuz                                   :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"netinst         o               debian-netinst-13                       Debian%2013                             debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-13.0.0-amd64-netinst.iso                                         -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-netinst-13/install.amd/initrd.gz                                 :_DIRS_LOAD_:/debian-netinst-13/install.amd/vmlinuz                                   :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"netinst         -               debian-netinst-14                       Debian%2014                             debian-14.0             debian-14.0             2027-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-14.0.0-amd64-netinst.iso                                         -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-netinst-14/install.amd/initrd.gz                                 :_DIRS_LOAD_:/debian-netinst-14/install.amd/vmlinuz                                   :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"netinst         o               debian-netinst-testing                  Debian%20testing                        debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                                 https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso                                     -                           -               -               :_DIRS_ISOS_:/debian-testing-amd64-netinst.iso                                        2025-04-17%2015:10:53+09    884998144       Debian%20testing%20amd64%20n                :_DIRS_RMAK_:/debian-testing-amd64-netinst_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/debian-netinst-testing/install.amd/initrd.gz                            :_DIRS_LOAD_:/debian-netinst-testing/install.amd/vmlinuz                              :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"netinst         x               fedora-netinst-40                       Fedora%20Server%2040                    fedora-40               fedora-40               2024-04-23      2025-05-28      https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso                   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-1.14.iso                      -                           -               -               :_DIRS_ISOS_:/Fedora-Server-netinst-x86_64-40-1.14.iso                                2024-04-14%2018:30:19+09    812312576       Fedora-S-dvd-x86_64-40                      :_DIRS_RMAK_:/Fedora-Server-netinst-x86_64-40-1.14_kickstart.iso                      -                           -               -                                           :_DIRS_LOAD_:/fedora-netinst-40/images/pxeboot/initrd.img                             :_DIRS_LOAD_:/fedora-netinst-40/images/pxeboot/vmlinuz                                :_DIRS_CONF_:/kickstart/ks_fedora-40_net.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"netinst         o               fedora-netinst-41                       Fedora%20Server%2041                    fedora-41               fedora-41               2024-10-29      2025-11-19      https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-[0-9.]*.iso                   https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-1.4.iso                       -                           -               -               :_DIRS_ISOS_:/Fedora-Server-netinst-x86_64-41-1.4.iso                                 2024-10-24%2013:36:10+09    954900480       Fedora-S-dvd-x86_64-41                      :_DIRS_RMAK_:/Fedora-Server-netinst-x86_64-41-1.4_kickstart.iso                       -                           -               -                                           :_DIRS_LOAD_:/fedora-netinst-41/images/pxeboot/initrd.img                             :_DIRS_LOAD_:/fedora-netinst-41/images/pxeboot/vmlinuz                                :_DIRS_CONF_:/kickstart/ks_fedora-41_net.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"netinst         o               fedora-netinst-42                       Fedora%20Server%2042                    fedora-42               fedora-42               2025-04-15      2026-05-13      https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-netinst-x86_64-42-[0-9.]*.iso                   https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-netinst-x86_64-42-1.1.iso                       -                           -               -               :_DIRS_ISOS_:/Fedora-Server-netinst-x86_64-42-1.1.iso                                 2025-04-09%2011:48:26+09    966010880       Fedora-S-dvd-x86_64-42                      :_DIRS_RMAK_:/Fedora-Server-netinst-x86_64-42-1.1_kickstart.iso                       -                           -               -                                           :_DIRS_LOAD_:/fedora-netinst-42/images/pxeboot/initrd.img                             :_DIRS_LOAD_:/fedora-netinst-42/images/pxeboot/vmlinuz                                :_DIRS_CONF_:/kickstart/ks_fedora-42_net.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"netinst         o               centos-stream-netinst-9                 CentOS%20Stream%209                     centos-stream-9         centos-stream-9         2021-12-03      2027-05-31      https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                                 https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                                 -                           -               -               :_DIRS_ISOS_:/CentOS-Stream-9-latest-x86_64-boot.iso                                  2025-04-14%2003:58:37+09    1258881024      CentOS-Stream-9-BaseOS-x86_64               :_DIRS_RMAK_:/CentOS-Stream-9-latest-x86_64-boot_kickstart.iso                        -                           -               -                                           :_DIRS_LOAD_:/centos-stream-netinst-9/images/pxeboot/initrd.img                       :_DIRS_LOAD_:/centos-stream-netinst-9/images/pxeboot/vmlinuz                          :_DIRS_CONF_:/kickstart/ks_centos-stream-9_net.cfg                                    -                           :_DIRS_HGFS_:/linux/centos                                                           "	\
		"netinst         o               centos-stream-netinst-10                CentOS%20Stream%2010                    centos-stream-10        centos-stream-10        2024-12-12      2030-01-01      https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso                               https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso                               -                           -               -               :_DIRS_ISOS_:/CentOS-Stream-10-latest-x86_64-boot.iso                                 2025-04-15%2019:58:45+09    857845760       CentOS-Stream-10-BaseOS-x86_64              :_DIRS_RMAK_:/CentOS-Stream-10-latest-x86_64-boot_kickstart.iso                       -                           -               -                                           :_DIRS_LOAD_:/centos-stream-netinst-10/images/pxeboot/initrd.img                      :_DIRS_LOAD_:/centos-stream-netinst-10/images/pxeboot/vmlinuz                         :_DIRS_CONF_:/kickstart/ks_centos-stream-10_net.cfg                                   -                           :_DIRS_HGFS_:/linux/centos                                                           "	\
		"netinst         o               almalinux-netinst-9                     Alma%20Linux%209                        almalinux-9             almalinux-9.5           2024-11-18      -               https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso                                                           https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso                                                           -                           -               -               :_DIRS_ISOS_:/AlmaLinux-9-latest-x86_64-boot.iso                                      2024-11-13%2009:40:34+09    1111998464      AlmaLinux-9-5-x86_64-dvd                    :_DIRS_RMAK_:/AlmaLinux-9-latest-x86_64-boot_kickstart.iso                            -                           -               -                                           :_DIRS_LOAD_:/almalinux-netinst-9/images/pxeboot/initrd.img                           :_DIRS_LOAD_:/almalinux-netinst-9/images/pxeboot/vmlinuz                              :_DIRS_CONF_:/kickstart/ks_almalinux-9_net.cfg                                        -                           :_DIRS_HGFS_:/linux/almalinux                                                        "	\
		"netinst         o               rockylinux-netinst-9                    Rocky%20Linux%209                       rockylinux-9            rockylinux-9.5          2024-11-19      -               https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso                                                          https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso                                                          -                           -               -               :_DIRS_ISOS_:/Rocky-9-latest-x86_64-boot.iso                                          2024-11-16%2001:52:35+09    1068498944      Rocky-9-5-x86_64-dvd                        :_DIRS_RMAK_:/Rocky-9-latest-x86_64-boot_kickstart.iso                                -                           -               -                                           :_DIRS_LOAD_:/rockylinux-netinst-9/images/pxeboot/initrd.img                          :_DIRS_LOAD_:/rockylinux-netinst-9/images/pxeboot/vmlinuz                             :_DIRS_CONF_:/kickstart/ks_rockylinux-9_net.cfg                                       -                           :_DIRS_HGFS_:/linux/rocky                                                            "	\
		"netinst         o               miraclelinux-netinst-9                  Miracle%20Linux%209                     miraclelinux-9          miraclelinux-9.4        2024-09-02      -               https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso                    https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-minimal-x86_64.iso                                -                           -               -               :_DIRS_ISOS_:/MIRACLELINUX-9.4-rtm-minimal-x86_64.iso                                 2024-08-23%2005:57:18+09    2184937472      MIRACLE-LINUX-9-4-x86_64                    :_DIRS_RMAK_:/MIRACLELINUX-9.4-rtm-minimal-x86_64_kickstart.iso                       -                           -               -                                           :_DIRS_LOAD_:/miraclelinux-netinst-9/images/pxeboot/initrd.img                        :_DIRS_LOAD_:/miraclelinux-netinst-9/images/pxeboot/vmlinuz                           :_DIRS_CONF_:/kickstart/ks_miraclelinux-9_net.cfg                                     -                           :_DIRS_HGFS_:/linux/miraclelinux                                                     "	\
		"netinst         o               opensuse-leap-netinst-15.6              openSUSE%20Leap%2015.6                  opensuse-leap-15.6      opensuse-leap-15.6      2024-06-12      2025-12-31      https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                                          https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Current.iso                                        -                           -               -               :_DIRS_ISOS_:/openSUSE-Leap-15.6-NET-x86_64-Media.iso                                 2024-06-20%2011:42:39+09    273678336       openSUSE-Leap-15.6-NET-x86_64710            :_DIRS_RMAK_:/openSUSE-Leap-15.6-NET-x86_64-Media_autoyast.iso                        -                           -               -                                           :_DIRS_LOAD_:/opensuse-leap-netinst-15.6/boot/x86_64/loader/initrd                    :_DIRS_LOAD_:/opensuse-leap-netinst-15.6/boot/x86_64/loader/linux                     :_DIRS_CONF_:/autoyast/autoinst_leap-15.6_net.xml                                     -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"netinst         o               opensuse-leap-netinst-16.0              openSUSE%20Leap%2016.0                  opensuse-leap-16.0      opensuse-leap-16.0      2025-10-xx      20xx-xx-xx      https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-NET-x86_64-Media.iso                                          https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-NET-x86_64-Current.iso                                        -                           -               -               :_DIRS_ISOS_:/openSUSE-Leap-16.0-NET-x86_64-Media.iso                                 -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/opensuse-leap-netinst-16.0/boot/x86_64/loader/initrd                    :_DIRS_LOAD_:/opensuse-leap-netinst-16.0/boot/x86_64/loader/linux                     :_DIRS_CONF_:/autoyast/autoinst_leap-16.0_net.xml                                     -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"netinst         o               opensuse-tumbleweed-netinst             openSUSE%20Tumbleweed                   opensuse-tumbleweed     opensuse-tumbleweed     2014-11-xx      20xx-xx-xx      https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                   -                           -               -               :_DIRS_ISOS_:/openSUSE-Tumbleweed-NET-x86_64-Current.iso                              2025-04-14%2017:26:16+09    309329920       openSUSE-Tumbleweed-NET-x86_64              :_DIRS_RMAK_:/openSUSE-Tumbleweed-NET-x86_64-Current_autoyast.iso                     -                           -               -                                           :_DIRS_LOAD_:/opensuse-tumbleweed-netinst/boot/x86_64/loader/initrd                   :_DIRS_LOAD_:/opensuse-tumbleweed-netinst/boot/x86_64/loader/linux                    :_DIRS_CONF_:/autoyast/autoinst_tumbleweed_net.xml                                    -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"netinst         m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"dvd             m               menu-entry                              Auto%20install%20DVD%20media            -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"dvd             o               debian-11                               Debian%2011                             debian-11.0             debian-11.0             2021-08-14      2024-08-15      https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso                                     https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso                                        -                           -               -               :_DIRS_ISOS_:/debian-11.11.0-amd64-DVD-1.iso                                          2024-08-31%2016:11:53+09    3992977408      Debian%2011.11.0%20amd64%201                :_DIRS_RMAK_:/debian-11.11.0-amd64-DVD-1_preseed.iso                                  -                           -               -                                           :_DIRS_LOAD_:/debian-11/install.amd/initrd.gz                                         :_DIRS_LOAD_:/debian-11/install.amd/vmlinuz                                           :_DIRS_CONF_:/preseed/ps_debian_server_old.cfg                                        -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"dvd             o               debian-12                               Debian%2012                             debian-12.0             debian-12.0             2023-06-10      2026-06-xx      https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso                                              https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.10.0-amd64-DVD-1.iso                                                 -                           -               -               :_DIRS_ISOS_:/debian-12.10.0-amd64-DVD-1.iso                                          2025-03-15%2012:03:59+09    3994091520      Debian%2012.10.0%20amd64%201                :_DIRS_RMAK_:/debian-12.10.0-amd64-DVD-1_preseed.iso                                  -                           -               -                                           :_DIRS_LOAD_:/debian-12/install.amd/initrd.gz                                         :_DIRS_LOAD_:/debian-12/install.amd/vmlinuz                                           :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"dvd             o               debian-13                               Debian%2013                             debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-13.0.0-amd64-DVD-1.iso                                           -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-13/install.amd/initrd.gz                                         :_DIRS_LOAD_:/debian-13/install.amd/vmlinuz                                           :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"dvd             -               debian-14                               Debian%2014                             debian-14.0             debian-14.0             2027-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-14.0.0-amd64-DVD-1.iso                                           -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-14/install.amd/initrd.gz                                         :_DIRS_LOAD_:/debian-14/install.amd/vmlinuz                                           :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"dvd             o               debian-testing                          Debian%20testing                        debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                                   https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                                   -                           -               -               :_DIRS_ISOS_:/debian-testing-amd64-DVD-1.iso                                          2025-04-14%2005:44:13+09    3989078016      Debian%20testing%20amd64%201                :_DIRS_RMAK_:/debian-testing-amd64-DVD-1_preseed.iso                                  -                           -               -                                           :_DIRS_LOAD_:/debian-testing/install.amd/initrd.gz                                    :_DIRS_LOAD_:/debian-testing/install.amd/vmlinuz                                      :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"dvd             x               ubuntu-live-20.04                       Ubuntu%2020.04%20Live%20Server          ubuntu-20.04            ubuntu-20.04            2020-04-23      2025-05-29      https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-live-server-amd64.iso                                                                     https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso                                                                          -                           -               -               :_DIRS_ISOS_:/ubuntu-20.04.6-live-server-amd64.iso                                    2023-03-14%2023:02:35+09    1487339520      Ubuntu-Server%2020.04.6%20LTS%20amd64       :_DIRS_RMAK_:/ubuntu-20.04.6-live-server-amd64_nocloud.iso                            -                           -               -                                           :_DIRS_LOAD_:/ubuntu-live-20.04/casper/initrd                                         :_DIRS_LOAD_:/ubuntu-live-20.04/casper/vmlinuz                                        :_DIRS_CONF_:/nocloud/ubuntu_server_old                                               -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"dvd             -               ubuntu-live-22.04                       Ubuntu%2022.04%20Live%20Server          ubuntu-22.04            ubuntu-22.04            2022-04-21      2027-06-01      https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-live-server-amd64.iso                                                                     https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso                                                                          -                           -               -               :_DIRS_ISOS_:/ubuntu-22.04.5-live-server-amd64.iso                                    2024-09-11%2018:46:55+09    2136926208      Ubuntu-Server%2022.04.5%20LTS%20amd64       :_DIRS_RMAK_:/ubuntu-22.04.5-live-server-amd64_nocloud.iso                            -                           -               -                                           :_DIRS_LOAD_:/ubuntu-live-22.04/casper/initrd                                         :_DIRS_LOAD_:/ubuntu-live-22.04/casper/vmlinuz                                        :_DIRS_CONF_:/nocloud/ubuntu_server_old                                               -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"dvd             o               ubuntu-live-24.04                       Ubuntu%2024.04%20Live%20Server          ubuntu-24.04            ubuntu-24.04            2024-04-25      2029-05-31      https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-live-server-amd64.iso                                                                     https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso                                                                          -                           -               -               :_DIRS_ISOS_:/ubuntu-24.04.2-live-server-amd64.iso                                    2025-02-16%2022:49:40+09    3213064192      Ubuntu-Server%2024.04.2%20LTS%20amd64       :_DIRS_RMAK_:/ubuntu-24.04.2-live-server-amd64_nocloud.iso                            -                           -               -                                           :_DIRS_LOAD_:/ubuntu-live-24.04/casper/initrd                                         :_DIRS_LOAD_:/ubuntu-live-24.04/casper/vmlinuz                                        :_DIRS_CONF_:/nocloud/ubuntu_server                                                   -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"dvd             o               ubuntu-live-24.10                       Ubuntu%2024.10%20Live%20Server          ubuntu-24.10            ubuntu-24.10            2024-10-10      2025-07-xx      https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-live-server-amd64.iso                                                                     https://releases.ubuntu.com/24.10/ubuntu-24.10-live-server-amd64.iso                                                                            -                           -               -               :_DIRS_ISOS_:/ubuntu-24.10-live-server-amd64.iso                                      2024-10-07%2021:19:04+09    2098460672      Ubuntu-Server%2024.10%20amd64               :_DIRS_RMAK_:/ubuntu-24.10-live-server-amd64_nocloud.iso                              -                           -               -                                           :_DIRS_LOAD_:/ubuntu-live-24.10/casper/initrd                                         :_DIRS_LOAD_:/ubuntu-live-24.10/casper/vmlinuz                                        :_DIRS_CONF_:/nocloud/ubuntu_server                                                   -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"dvd             o               ubuntu-live-25.04                       Ubuntu%2025.04%20Live%20Server          ubuntu-25.04            ubuntu-25.04            2025-04-17      2026-01-xx      https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-live-server-amd64.iso                                                                     https://releases.ubuntu.com/25.04/ubuntu-25.04-live-server-amd64.iso                                                                            -                           -               -               :_DIRS_ISOS_:/ubuntu-25.04-live-server-amd64.iso                                      2025-04-15%2022:38:47+09    2021750784      Ubuntu-Server%2025.04%20amd64               :_DIRS_RMAK_:/ubuntu-25.04-live-server-amd64_nocloud.iso                              -                           -               -                                           :_DIRS_LOAD_:/ubuntu-live-25.04/casper/initrd                                         :_DIRS_LOAD_:/ubuntu-live-25.04/casper/vmlinuz                                        :_DIRS_CONF_:/nocloud/ubuntu_server                                                   -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"dvd             x               fedora-40                               Fedora%20Server%2040                    fedora-40               fedora-40               2024-04-23      2025-05-28      https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso                       https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-1.14.iso                          -                           -               -               :_DIRS_ISOS_:/Fedora-Server-dvd-x86_64-40-1.14.iso                                    2024-04-14%2022:54:06+09    2612854784      Fedora-S-dvd-x86_64-40                      :_DIRS_RMAK_:/Fedora-Server-dvd-x86_64-40-1.14_kickstart.iso                          -                           -               -                                           :_DIRS_LOAD_:/fedora-40/images/pxeboot/initrd.img                                     :_DIRS_LOAD_:/fedora-40/images/pxeboot/vmlinuz                                        :_DIRS_CONF_:/kickstart/ks_fedora-40_dvd.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"dvd             o               fedora-41                               Fedora%20Server%2041                    fedora-41               fedora-41               2024-10-29      2025-11-19      https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-[0-9.]*.iso                       https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-1.4.iso                           -                           -               -               :_DIRS_ISOS_:/Fedora-Server-dvd-x86_64-41-1.4.iso                                     2024-10-24%2014:48:35+09    2818572288      Fedora-S-dvd-x86_64-41                      :_DIRS_RMAK_:/Fedora-Server-dvd-x86_64-41-1.4_kickstart.iso                           -                           -               -                                           :_DIRS_LOAD_:/fedora-41/images/pxeboot/initrd.img                                     :_DIRS_LOAD_:/fedora-41/images/pxeboot/vmlinuz                                        :_DIRS_CONF_:/kickstart/ks_fedora-41_dvd.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"dvd             o               fedora-42                               Fedora%20Server%2042                    fedora-42               fedora-42               2025-04-15      2026-05-13      https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-[0-9.]*.iso                       https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso                           -                           -               -               :_DIRS_ISOS_:/Fedora-Server-dvd-x86_64-42-1.1.iso                                     2025-04-09%2012:01:30+09    2925920256      Fedora-S-dvd-x86_64-42                      :_DIRS_RMAK_:/Fedora-Server-dvd-x86_64-42-1.1_kickstart.iso                           -                           -               -                                           :_DIRS_LOAD_:/fedora-42/images/pxeboot/initrd.img                                     :_DIRS_LOAD_:/fedora-42/images/pxeboot/vmlinuz                                        :_DIRS_CONF_:/kickstart/ks_fedora-42_dvd.cfg                                          -                           :_DIRS_HGFS_:/linux/fedora                                                           "	\
		"dvd             o               centos-stream-9                         CentOS%20Stream%209                     centos-stream-9         centos-stream-9         2021-12-03      2027-05-31      https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                                 https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                                 -                           -               -               :_DIRS_ISOS_:/CentOS-Stream-9-latest-x86_64-dvd1.iso                                  2025-04-14%2004:09:22+09    12827557888     CentOS-Stream-9-BaseOS-x86_64               :_DIRS_RMAK_:/CentOS-Stream-9-latest-x86_64-dvd1_kickstart.iso                        -                           -               -                                           :_DIRS_LOAD_:/centos-stream-9/images/pxeboot/initrd.img                               :_DIRS_LOAD_:/centos-stream-9/images/pxeboot/vmlinuz                                  :_DIRS_CONF_:/kickstart/ks_centos-stream-9_dvd.cfg                                    -                           :_DIRS_HGFS_:/linux/centos                                                           "	\
		"dvd             o               centos-stream-10                        CentOS%20Stream%2010                    centos-stream-10        centos-stream-10        2024-12-12      2030-01-01      https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso                               https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso                               -                           -               -               :_DIRS_ISOS_:/CentOS-Stream-10-latest-x86_64-dvd1.iso                                 2025-04-15%2020:05:55+09    7608401920      CentOS-Stream-10-BaseOS-x86_64              :_DIRS_RMAK_:/CentOS-Stream-10-latest-x86_64-dvd1_kickstart.iso                       -                           -               -                                           :_DIRS_LOAD_:/centos-stream-10/images/pxeboot/initrd.img                              :_DIRS_LOAD_:/centos-stream-10/images/pxeboot/vmlinuz                                 :_DIRS_CONF_:/kickstart/ks_centos-stream-10_dvd.cfg                                   -                           :_DIRS_HGFS_:/linux/centos                                                           "	\
		"dvd             o               almalinux-9                             Alma%20Linux%209                        almalinux-9             almalinux-9.5           2024-11-18      -               https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso                                                            https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso                                                            -                           -               -               :_DIRS_ISOS_:/AlmaLinux-9-latest-x86_64-dvd.iso                                       2024-11-13%2009:59:46+09    11382292480     AlmaLinux-9-5-x86_64-dvd                    :_DIRS_RMAK_:/AlmaLinux-9-latest-x86_64-dvd_kickstart.iso                             -                           -               -                                           :_DIRS_LOAD_:/almalinux-9/images/pxeboot/initrd.img                                   :_DIRS_LOAD_:/almalinux-9/images/pxeboot/vmlinuz                                      :_DIRS_CONF_:/kickstart/ks_almalinux-9_dvd.cfg                                        -                           :_DIRS_HGFS_:/linux/almalinux                                                        "	\
		"dvd             o               rockylinux-9                            Rocky%20Linux%209                       rockylinux-9            rockylinux-9.5          2024-11-19      -               https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso                                                           https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso                                                           -                           -               -               :_DIRS_ISOS_:/Rocky-9-latest-x86_64-dvd.iso                                           2024-11-16%2004:23:15+09    11510087680     Rocky-9-5-x86_64-dvd                        :_DIRS_RMAK_:/Rocky-9-latest-x86_64-dvd_kickstart.iso                                 -                           -               -                                           :_DIRS_LOAD_:/rockylinux-9/images/pxeboot/initrd.img                                  :_DIRS_LOAD_:/rockylinux-9/images/pxeboot/vmlinuz                                     :_DIRS_CONF_:/kickstart/ks_rockylinux-9_dvd.cfg                                       -                           :_DIRS_HGFS_:/linux/rocky                                                            "	\
		"dvd             o               miraclelinux-9                          Miracle%20Linux%209                     miraclelinux-9          miraclelinux-9.4        2024-09-02      -               https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso                            https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-x86_64.iso                                        -                           -               -               :_DIRS_ISOS_:/MIRACLELINUX-9.4-rtm-x86_64.iso                                         2024-08-23%2005:57:18+09    10582161408     MIRACLE-LINUX-9-4-x86_64                    :_DIRS_RMAK_:/MIRACLELINUX-9.4-rtm-x86_64_kickstart.iso                               -                           -               -                                           :_DIRS_LOAD_:/miraclelinux-9/images/pxeboot/initrd.img                                :_DIRS_LOAD_:/miraclelinux-9/images/pxeboot/vmlinuz                                   :_DIRS_CONF_:/kickstart/ks_miraclelinux-9_dvd.cfg                                     -                           :_DIRS_HGFS_:/linux/miraclelinux                                                     "	\
		"dvd             o               opensuse-leap-15.6                      openSUSE%20Leap%2015.6                  opensuse-leap-15.6      opensuse-leap-15.6      2024-06-12      2025-12-31      https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                                          https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Current.iso                                        -                           -               -               :_DIRS_ISOS_:/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                                 2024-06-20%2011:56:54+09    4631560192      openSUSE-Leap-15.6-DVD-x86_64710            :_DIRS_RMAK_:/openSUSE-Leap-15.6-DVD-x86_64-Media_autoyast.iso                        -                           -               -                                           :_DIRS_LOAD_:/opensuse-leap-15.6/boot/x86_64/loader/initrd                            :_DIRS_LOAD_:/opensuse-leap-15.6/boot/x86_64/loader/linux                             :_DIRS_CONF_:/autoyast/autoinst_leap-15.6_dvd.xml                                     -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"dvd             o               opensuse-leap-16.0                      openSUSE%20Leap%2016.0                  opensuse-leap-16.0      opensuse-leap-16.0      2025-10-xx      20xx-xx-xx      https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-DVD-x86_64-Media.iso                                          https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-DVD-x86_64-Current.iso                                        -                           -               -               :_DIRS_ISOS_:/openSUSE-Leap-16.0-DVD-x86_64-Media.iso                                 -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/opensuse-leap-16.0/boot/x86_64/loader/initrd                            :_DIRS_LOAD_:/opensuse-leap-16.0/boot/x86_64/loader/linux                             :_DIRS_CONF_:/autoyast/autoinst_leap-16.0_dvd.xml                                     -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"dvd             o               opensuse-tumbleweed                     openSUSE%20Tumbleweed                   opensuse-tumbleweed     opensuse-tumbleweed     2014-11-xx      20xx-xx-xx      https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                   -                           -               -               :_DIRS_ISOS_:/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                              2025-04-14%2017:29:38+09    4635754496      openSUSE-Tumbleweed-DVD-x86_64              :_DIRS_RMAK_:/openSUSE-Tumbleweed-DVD-x86_64-Current_autoyast.iso                     -                           -               -                                           :_DIRS_LOAD_:/opensuse-tumbleweed/boot/x86_64/loader/initrd                           :_DIRS_LOAD_:/opensuse-tumbleweed/boot/x86_64/loader/linux                            :_DIRS_CONF_:/autoyast/autoinst_tumbleweed_dvd.xml                                    -                           :_DIRS_HGFS_:/linux/opensuse                                                         "	\
		"dvd             o               windows-10                              Windows%2010                            windows-10.0            -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/Win10_22H2_Japanese_x64.iso                                             2022-10-18%2015:21:50+09    6003816448      CCCOMA_X64FRE_JA-JP_DV9                     -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/Windows10                                                      "	\
		"dvd             o               windows-11                              Windows%2011                            windows-11.0            -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/Win11_24H2_Japanese_x64.iso                                             2024-10-01%2012:18:50+09    5751373824      CCCOMA_X64FRE_JA-JP_DV9                     -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/Windows11                                                      "	\
		"dvd             -               windows-11                              Windows%2011%20custom                   windows-11.0            -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/Win11_24H2_Japanese_x64_custom.iso                                      -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/Windows11                                                      "	\
		"dvd             m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"live_install    m               menu-entry                              Live%20media%20Install%20mode           -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"live_install    o               debian-live-11                          Debian%2011%20Live                      debian-11.0             debian-11.0             2021-08-14      2024-08-15      https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                         https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso                            -                           -               -               :_DIRS_ISOS_:/debian-live-11.11.0-amd64-lxde.iso                                      2024-08-31%2015:15:29+09    2566914048      d-live%2011.11.0%20lx%20amd64               :_DIRS_RMAK_:/debian-live-11.11.0-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-11/d-i/initrd.gz                                            :_DIRS_LOAD_:/debian-live-11/d-i/vmlinuz                                              :_DIRS_CONF_:/preseed/ps_debian_desktop_old.cfg                                       -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live_install    o               debian-live-12                          Debian%2012%20Live                      debian-12.0             debian-12.0             2023-06-10      2026-06-xx      https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                  https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.10.0-amd64-lxde.iso                                     -                           -               -               :_DIRS_ISOS_:/debian-live-12.10.0-amd64-lxde.iso                                      2025-03-15%2009:09:36+09    3181445120      d-live%2012.10.0%20ld%20amd64               :_DIRS_RMAK_:/debian-live-12.10.0-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-12/install/initrd.gz                                        :_DIRS_LOAD_:/debian-live-12/install/vmlinuz                                          :_DIRS_CONF_:/preseed/ps_debian_desktop.cfg                                           -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live_install    o               debian-live-13                          Debian%2013%20Live                      debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-live-13.0.0-amd64-lxde.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-live-13/install/initrd.gz                                        :_DIRS_LOAD_:/debian-live-13/install/vmlinuz                                          :_DIRS_CONF_:/preseed/ps_debian_desktop.cfg                                           -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live_install    o               debian-live-testing                     Debian%20testing%20Live                 debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                       https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                       -                           -               -               :_DIRS_ISOS_:/debian-live-testing-amd64-lxde.iso                                      2025-04-14%2002:26:27+09    3683778560      d-live%20testing%20ld%20amd64               :_DIRS_RMAK_:/debian-live-testing-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-testing/install/initrd.gz                                   :_DIRS_LOAD_:/debian-live-testing/install/vmlinuz                                     :_DIRS_CONF_:/preseed/ps_debian_desktop.cfg                                           -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live_install    x               ubuntu-desktop-20.04                    Ubuntu%2020.04%20Desktop                ubuntu-20.04            ubuntu-20.04            2020-04-23      2025-05-29      https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-20.04.6-desktop-amd64.iso                                        2023-03-16%2015:58:09+09    4351463424      Ubuntu%2020.04.6%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-20.04.6-desktop-amd64_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-20.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-20.04/casper/vmlinuz                                     :_DIRS_CONF_:/preseed/ps_ubiquity_desktop_old.cfg                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live_install    -               ubuntu-desktop-22.04                    Ubuntu%2022.04%20Desktop                ubuntu-22.04            ubuntu-22.04            2022-04-21      2027-06-01      https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-22.04.5-desktop-amd64.iso                                        2024-09-11%2014:38:59+09    4762707968      Ubuntu%2022.04.5%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-22.04.5-desktop-amd64_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-22.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-22.04/casper/vmlinuz                                     :_DIRS_CONF_:/preseed/ps_ubiquity_desktop_old.cfg                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live_install    o               ubuntu-desktop-24.04                    Ubuntu%2024.04%20Desktop                ubuntu-24.04            ubuntu-24.04            2024-04-25      2029-05-31      https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-24.04.2-desktop-amd64.iso                                        2025-02-15%2009:16:38+09    6343219200      Ubuntu%2024.04.2%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-24.04.2-desktop-amd64_nocloud.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-24.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-24.04/casper/vmlinuz                                     :_DIRS_CONF_:/nocloud/ubuntu_desktop                                                  -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live_install    o               ubuntu-desktop-24.10                    Ubuntu%2024.10%20Desktop                ubuntu-24.10            ubuntu-24.10            2024-10-10      2025-07-xx      https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso                                                                                -                           -               -               :_DIRS_ISOS_:/ubuntu-24.10-desktop-amd64.iso                                          2024-10-09%2014:32:32+09    5665497088      Ubuntu%2024.10%20amd64                      :_DIRS_RMAK_:/ubuntu-24.10-desktop-amd64_nocloud.iso                                  -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-24.10/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-24.10/casper/vmlinuz                                     :_DIRS_CONF_:/nocloud/ubuntu_desktop                                                  -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live_install    o               ubuntu-desktop-25.04                    Ubuntu%2025.04%20Desktop                ubuntu-25.04            ubuntu-25.04            2025-04-17      2026-01-xx      https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/25.04/ubuntu-25.04-desktop-amd64.iso                                                                                -                           -               -               :_DIRS_ISOS_:/ubuntu-25.04-desktop-amd64.iso                                          2025-04-15%2018:47:56+09    6278520832      Ubuntu%2025.04%20amd64                      :_DIRS_RMAK_:/ubuntu-25.04-desktop-amd64_nocloud.iso                                  -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-25.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-25.04/casper/vmlinuz                                     :_DIRS_CONF_:/nocloud/ubuntu_desktop                                                  -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live_install    m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"live            m               menu-entry                              Live%20media%20Live%20mode              -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"live            o               debian-live-11                          Debian%2011%20Live                      debian-11.0             debian-11.0             2021-08-14      2024-08-15      https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                         https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso                            -                           -               -               :_DIRS_ISOS_:/debian-live-11.11.0-amd64-lxde.iso                                      2024-08-31%2015:15:29+09    2566914048      d-live%2011.11.0%20lx%20amd64               :_DIRS_RMAK_:/debian-live-11.11.0-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-11/live/initrd.img-5.10.0-32-amd64                          :_DIRS_LOAD_:/debian-live-11/live/vmlinuz-5.10.0-32-amd64                             -                                                                                     -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live            o               debian-live-12                          Debian%2012%20Live                      debian-12.0             debian-12.0             2023-06-10      2026-06-xx      https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                  https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.10.0-amd64-lxde.iso                                     -                           -               -               :_DIRS_ISOS_:/debian-live-12.10.0-amd64-lxde.iso                                      2025-03-15%2009:09:36+09    3181445120      d-live%2012.10.0%20ld%20amd64               :_DIRS_RMAK_:/debian-live-12.10.0-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-12/live/initrd.img                                          :_DIRS_LOAD_:/debian-live-12/live/vmlinuz                                             -                                                                                     -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live            o               debian-live-13                          Debian%2013%20Live                      debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/debian-live-13.0.0-amd64-lxde.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/debian-live-13/live/initrd.img                                          :_DIRS_LOAD_:/debian-live-13/live/vmlinuz                                             -                                                                                     -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live            o               debian-live-testing                     Debian%20testing%20Live                 debian-testing          debian-testing          20xx-xx-xx      20xx-xx-xx      https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                       https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                       -                           -               -               :_DIRS_ISOS_:/debian-live-testing-amd64-lxde.iso                                      2025-04-14%2002:26:27+09    3683778560      d-live%20testing%20ld%20amd64               :_DIRS_RMAK_:/debian-live-testing-amd64-lxde_preseed.iso                              -                           -               -                                           :_DIRS_LOAD_:/debian-live-testing/live/initrd.img                                     :_DIRS_LOAD_:/debian-live-testing/live/vmlinuz                                        -                                                                                     -                           :_DIRS_HGFS_:/linux/debian                                                           "	\
		"live            x               ubuntu-desktop-20.04                    Ubuntu%2020.04%20Desktop                ubuntu-20.04            ubuntu-20.04            2020-04-23      2025-05-29      https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-20.04.6-desktop-amd64.iso                                        2023-03-16%2015:58:09+09    4351463424      Ubuntu%2020.04.6%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-20.04.6-desktop-amd64_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-20.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-20.04/casper/vmlinuz                                     -                                                                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live            -               ubuntu-desktop-22.04                    Ubuntu%2022.04%20Desktop                ubuntu-22.04            ubuntu-22.04            2022-04-21      2027-06-01      https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-22.04.5-desktop-amd64.iso                                        2024-09-11%2014:38:59+09    4762707968      Ubuntu%2022.04.5%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-22.04.5-desktop-amd64_preseed.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-22.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-22.04/casper/vmlinuz                                     -                                                                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live            o               ubuntu-desktop-24.04                    Ubuntu%2024.04%20Desktop                ubuntu-24.04            ubuntu-24.04            2024-04-25      2029-05-31      https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso                                                                              -                           -               -               :_DIRS_ISOS_:/ubuntu-24.04.2-desktop-amd64.iso                                        2025-02-15%2009:16:38+09    6343219200      Ubuntu%2024.04.2%20LTS%20amd64              :_DIRS_RMAK_:/ubuntu-24.04.2-desktop-amd64_nocloud.iso                                -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-24.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-24.04/casper/vmlinuz                                     -                                                                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live            o               ubuntu-desktop-24.10                    Ubuntu%2024.10%20Desktop                ubuntu-24.10            ubuntu-24.10            2024-10-10      2025-07-xx      https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso                                                                                -                           -               -               :_DIRS_ISOS_:/ubuntu-24.10-desktop-amd64.iso                                          2024-10-09%2014:32:32+09    5665497088      Ubuntu%2024.10%20amd64                      :_DIRS_RMAK_:/ubuntu-24.10-desktop-amd64_nocloud.iso                                  -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-24.10/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-24.10/casper/vmlinuz                                     -                                                                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live            o               ubuntu-desktop-25.04                    Ubuntu%2025.04%20Desktop                ubuntu-25.04            ubuntu-25.04            2025-04-17      2026-01-xx      https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-desktop-amd64.iso                                                                         https://releases.ubuntu.com/25.04/ubuntu-25.04-desktop-amd64.iso                                                                                -                           -               -               :_DIRS_ISOS_:/ubuntu-25.04-desktop-amd64.iso                                          2025-04-15%2018:47:56+09    6278520832      Ubuntu%2025.04%20amd64                      :_DIRS_RMAK_:/ubuntu-25.04-desktop-amd64_nocloud.iso                                  -                           -               -                                           :_DIRS_LOAD_:/ubuntu-desktop-25.04/casper/initrd                                      :_DIRS_LOAD_:/ubuntu-desktop-25.04/casper/vmlinuz                                     -                                                                                     -                           :_DIRS_HGFS_:/linux/ubuntu                                                           "	\
		"live            m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"tool            m               menu-entry                              System%20tools                          -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"tool            o               memtest86plus                           Memtest86+%207.20                       memtest86plus           -                       -               -               https://www.memtest.org/download/v7.20/mt86plus_7.20_64.grub.iso.zip                                                                            https://www.memtest.org/download/v7.20/mt86plus_7.20_64.grub.iso.zip                                                                            -                           -               -               :_DIRS_ISOS_:/mt86plus_7.20_64.grub.iso                                               2024-11-11%2009:15:12+09    19988480        MT86PLUS_64                                 -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/memtest86plus/EFI/BOOT/memtest                                          :_DIRS_LOAD_:/memtest86plus/boot/memtest                                              -                                                                                     -                           :_DIRS_HGFS_:/linux/memtest86+                                                       "	\
		"tool            o               winpe-x86                               WinPE%20x86                             winpe-x86               -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/WinPEx86.iso                                                            -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/WinPE                                                          "	\
		"tool            o               winpe-x64                               WinPE%20x64                             winpe-x64               -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/WinPEx64.iso                                                            2024-10-21%2012:19:39+09    469428224       CD_ROM                                      -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/WinPE                                                          "	\
		"tool            o               ati2020x86                              ATI2020x86                              ati2020x86              -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/WinPE_ATI2020x86.iso                                                    2022-01-28%2013:07:12+09    555139072       CD_ROM                                      -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/ati                                                            "	\
		"tool            o               ati2020x64                              ATI2020x64                              ati2020x64              -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/WinPE_ATI2020x64.iso                                                    2022-01-28%2013:12:34+09    630548480       CD_ROM                                      -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           :_DIRS_HGFS_:/windows/ati                                                            "	\
		"tool            m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"custom_live     m               menu-entry                              Custom%20Live%20Media                   -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-debian-11-bullseye                 Live%20Debian%2011                      debian-11.0             debian-11.0             2021-08-14      2024-08-15      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-debian-11-bullseye-amd64.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-debian-11-bullseye/live/initrd.img                                 :_DIRS_LOAD_:/live-debian-11-bullseye/live/vmlinuz                                    -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-debian-12-bookworm                 Live%20Debian%2012                      debian-12.0             debian-12.0             2023-06-10      2026-06-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-debian-12-bookworm-amd64.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-debian-12-bookworm/live/initrd.img                                 :_DIRS_LOAD_:/live-debian-12-bookworm/live/vmlinuz                                    -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-debian-13-trixie                   Live%20Debian%2013                      debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-debian-13-trixie-amd64.iso                                         -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-debian-13-trixie/live/initrd.img                                   :_DIRS_LOAD_:/live-debian-13-trixie/live/vmlinuz                                      -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-debian-xx-unstable                 Live%20Debian%20xx                      debian-sid              debian-sid              20xx-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-debian-xx-unstable-amd64.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-debian-xx-unstable/live/initrd.img                                 :_DIRS_LOAD_:/live-debian-xx-unstable/live/vmlinuz                                    -                                                                                     -                           -                                                                                    "	\
		"custom_live     -               live-ubuntu-22.04-jammy                 Live%20Ubuntu%2022.04                   ubuntu-22.04            ubuntu-22.04            2022-04-21      2027-06-01      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-ubuntu-22.04-jammy-amd64.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-ubuntu-22.04-jammy/live/initrd.img                                 :_DIRS_LOAD_:/live-ubuntu-22.04-jammy/live/vmlinuz                                    -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-ubuntu-24.04-noble                 Live%20Ubuntu%2024.04                   ubuntu-24.04            ubuntu-24.04            2024-04-25      2029-05-31      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-ubuntu-24.04-noble-amd64.iso                                       -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-ubuntu-24.04-noble/live/initrd.img                                 :_DIRS_LOAD_:/live-ubuntu-24.04-noble/live/vmlinuz                                    -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-ubuntu-24.10-oracular              Live%20Ubuntu%2024.10                   ubuntu-24.10            ubuntu-24.10            2024-10-10      2025-07-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-ubuntu-24.10-oracular-amd64.iso                                    -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-ubuntu-24.10-oracular/live/initrd.img                              :_DIRS_LOAD_:/live-ubuntu-24.10-oracular/live/vmlinuz                                 -                                                                                     -                           -                                                                                    "	\
		"custom_live     o               live-ubuntu-25.04-plucky                Live%20Ubuntu%2025.04                   ubuntu-25.04            ubuntu-25.04            2025-04-17      2026-01-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               :_DIRS_ISOS_:/live-ubuntu-25.04-plucky-amd64.iso                                      -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/live-ubuntu-25.04-plucky/live/initrd.img                                :_DIRS_LOAD_:/live-ubuntu-25.04-plucky/live/vmlinuz                                   -                                                                                     -                           -                                                                                    "	\
		"custom_live     m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"custom_netinst  m               menu-entry                              Custom%20Initramfs%20boot               -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"custom_netinst  o               netinst-debian-11                       Net%20Installer%20Debian%2011           debian-11.0             debian-11.0             2021-08-14      2024-08-15      -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/netinst-debian-11/initrd.gz_debian-11                                   :_DIRS_LOAD_:/netinst-debian-11/linux_debian-11                                       :_DIRS_CONF_:/preseed/ps_debian_server_old.cfg                                        -                           -                                                                                    "	\
		"custom_netinst  o               netinst-debian-12                       Net%20Installer%20Debian%2012           debian-12.0             debian-12.0             2023-06-10      2026-06-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/netinst-debian-12/initrd.gz_debian-12                                   :_DIRS_LOAD_:/netinst-debian-12/linux_debian-12                                       :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           -                                                                                    "	\
		"custom_netinst  o               netinst-debian-13                       Net%20Installer%20Debian%2013           debian-13.0             debian-13.0             2025-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/netinst-debian-13/initrd.gz_debian-13                                   :_DIRS_LOAD_:/netinst-debian-13/linux_debian-13                                       :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           -                                                                                    "	\
		"custom_netinst  o               netinst-debian-sid                      Net%20Installer%20Debian%20sid          debian-sid              debian-sid              20xx-xx-xx      20xx-xx-xx      -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           :_DIRS_LOAD_:/netinst-debian-sid/initrd.gz_debian-sid                                 :_DIRS_LOAD_:/netinst-debian-sid/linux_debian-sid                                     :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                            -                           -                                                                                    "	\
		"custom_netinst  m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"system          m               menu-entry                              System%20command                        -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"system          o               hdt                                     Hardware%20info                         -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               hdt.c32                                                                               -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"system          o               restart                                 System%20restart                        -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               reboot.c32                                                                            -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"system          o               shutdown                                System%20shutdown                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               poweroff.c32                                                                          -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
		"system          m               menu-entry                              -                                       -                       -                       -               -               -                                                                                                                                               -                                                                                                                                               -                           -               -               -                                                                                     -                           -               -                                           -                                                                                     -                           -               -                                           -                                                                                     -                                                                                     -                                                                                     -                           -                                                                                    "	\
	)

	declare       _AUTO_INST="autoinst.cfg"

# --- distro to efi image file name -------------------------------------------
function funcDistro2efi() {
	declare       _PATH=""									# file name

	case "${1:?}" in
		debian      | \
		ubuntu      ) _PATH="boot/grub/efi.img";;
		fedora      | \
		centos      | \
		almalinux   | \
		rockylinux  | \
		miraclelinux) _PATH="images/efiboot.img";;
		opensuse    ) _PATH="boot/x86_64/efi";;
		*           ) ;;
	esac

	echo -n "${_PATH}"
}

# --- create boot options for preseed -----------------------------------------
function funcRemastering_preseed() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	_BOPT=""
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="auto=true preseed/file=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		case "${_TGET_LIST[2]}" in
			ubuntu-desktop-* | \
			ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}automatic-ubiquity noprompt ${_WORK}";;
			*-mini-*         ) _BOPT+="${_BOPT:+" "}${_WORK/\/cdrom/}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-*         ) _BOPT+="${_BOPT:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	_BOPT+="${_BOPT:+" "}netcfg/disable_autoconfig=true"
	_BOPT+="${_NICS_NAME:+"${_BOPT:+" "}netcfg/choose_interface=${_NICS_NAME}"}"
	_BOPT+="${_NWRK_HOST:+"${_BOPT:+" "}netcfg/get_hostname=${_NWRK_HOST}.${_NWRK_WGRP}"}"
	_BOPT+="${_IPV4_ADDR:+"${_BOPT:+" "}netcfg/get_ipaddress=${_IPV4_ADDR}"}"
	_BOPT+="${_IPV4_MASK:+"${_BOPT:+" "}netcfg/get_netmask=${_IPV4_MASK}"}"
	_BOPT+="${_IPV4_GWAY:+"${_BOPT:+" "}netcfg/get_gateway=${_IPV4_GWAY}"}"
	_BOPT+="${_IPV4_NSVR:+"${_BOPT:+" "}netcfg/get_nameservers=${_IPV4_NSVR}"}"
	# --- locale --------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                ) _BOPT+="${_BOPT:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for nocloud -----------------------------------------
function funcRemastering_nocloud() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for nocloud" 1>&2
	_BOPT=""
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="automatic-ubiquity noprompt autoinstall ds='nocloud;s=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}'"
		case "${_TGET_LIST[2]}" in
			ubuntu-live-18.* ) _BOPT+="${_BOPT:+" "}boot=casper ${_WORK}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-live-18.04) _BOPT+="${_BOPT:+" "}ip=${_NICS_NAME},${_IPV4_ADDR},${_IPV4_MASK},${_IPV4_GWAY} hostname=${_NWRK_HOST}.${_NWRK_WGRP}";;
		*                ) _BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}::${_NICS_NAME}:${_IPV4_ADDR:+static}:${_IPV4_NSVR} hostname=${_NWRK_HOST}.${_NWRK_WGRP}";;
	esac
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for kickstart ---------------------------------------
function funcRemastering_kickstart() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for kickstart" 1>&2
	_BOPT=""
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}:${_NWRK_HOST}.${_NWRK_WGRP}:${_NICS_NAME}:none,auto6 nameserver=${_IPV4_NSVR}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for autoyast ----------------------------------------
function funcRemastering_autoyast() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for autoyast" 1>&2
	_BOPT=""
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		opensuse-*-15* ) _WORK="eth0";;
		*              ) _WORK="${_NICS_NAME}";;
	esac
	_BOPT+="${_BOPT:+" "}hostname=${_NWRK_HOST}.${_NWRK_WGRP} ifcfg=${_WORK}=${_IPV4_ADDR}/${_IPV4_CIDR},${_IPV4_GWAY},${_IPV4_NSVR},${_NWRK_WGRP}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options -----------------------------------------------------
function funcRemastering_boot_options() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables

	# --- create boot options -------------------------------------------------
	case "${_TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${_TGET_LIST[23]}" in
				*/preseed/* ) _WORK="$(funcRemastering_preseed "${_TGET_LIST[@]}")";;
				*/nocloud/* ) _WORK="$(funcRemastering_nocloud "${_TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) _WORK="$(funcRemastering_kickstart "${_TGET_LIST[@]}")";;
		opensuse     ) _WORK="$(funcRemastering_autoyast "${_TGET_LIST[@]}")";;
		*            ) ;;
	esac
	_WORK+="${_MENU_MODE:+"${_WORK:+" "}vga=${_MENU_MODE}"}"
	_WORK+="${_WORK:+" "}fsck.mode=skip"
	echo -n "${_WORK}"
}

# --- create path for configuration file --------------------------------------
function funcRemastering_path() {
	declare -r    _PATH_TGET="${1:?}"	# target path
	declare -r    _DIRS_TGET="${2:?}"	# directory
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name

	_FNAM="${_PATH_TGET##*/}"
	_DIRS="${_PATH_TGET%"${_FNAM}"}"
	_DIRS="${_DIRS#"${_DIRS_TGET}"}"
	_DIRS="${_DIRS%%/}"
	_DIRS="${_DIRS##/}"
	echo -n "${_DIRS:+/"${_DIRS}"}/${_FNAM}"
}

# --- create autoinstall configuration file for isolinux ----------------------
function funcRemastering_isolinux_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_CONF="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd

	# --- header section ------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_CONF}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FTHM}"
		menu resolution ${_MENU_RESO/x/ }
		menu title Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}
		menu background splash.png
		menu color title	* #FFFFFFFF *
		menu color border	* #00000000 #00000000 none
		menu color sel		* #ffffffff #76a1d0ff *
		menu color hotsel	1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg	* #ffffffff #00000000 *
		menu color help		37;40 #ffdddd00 #00000000 none
		menu vshift 8
		menu rows 32
		menu helpmsgrow 34
		menu cmdlinerow 36
		menu timeoutrow 36
		menu tabmsgrow 38
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
		timeout ${_MENU_TOUT:-50}
		default auto_install

_EOT_

	# --- standard installation mode ------------------------------------------
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}"
		label auto_install
		  menu label ^Automatic installation
		  menu default
		  kernel ${_FKNL}
		  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
		
_EOT_
		# --- graphical installation mode -------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}"
				label auto_install_gui
				  menu label ^Automatic installation of gui
				  kernel ${_FKNL}
				  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
			
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing isolinux for autoinstall ----------------------------------------
function funcRemastering_isolinux() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# isolinux.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTHM="${_FNAM%/*}/theme.txt"
		_FTMP="${_PATH}.tmp"
		if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${_PATH}"; then
			sed -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${_PAUT}"'' \
			    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${_FTHM}"'' \
				"${_PATH}"                                                                    \
			>	"${_FTMP}"
		else
			sed -e '0,/\([Ll]abel\|LABEL\)/ {'                     \
				-e '/\([Ll]abel\|LABEL\)/i include '"${_PAUT}"'\n' \
				-e '}'                                             \
				"${_PATH}"                                         \
			>	"${_FTMP}"
		fi
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for isolinux --------------
		funcRemastering_isolinux_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'isolinux.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
		sed -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   d}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               d'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 d'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           d'  \
			"${_PATH}"                                                                   \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- create autoinstall configuration file for grub --------------------------
function funcRemastering_grub_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_CONF="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _FTHM=""				# theme.txt
	declare       _FPNG=""				# splash.png

	# --- theme section -------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_CONF}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	for _DIRS in / /isolinux /boot/grub /boot/grub/theme
	do
		_FPNG="${_DIRS}/splash.png"
		if [[ -e "${_DIRS_TGET}/${_FPNG}" ]]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}"
				desktop-image: "${_FPNG}"
_EOT_
			break
		fi
	done
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}"
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
	# --- header section ------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH}"
		#set gfxmode=${_MENU_RESO:+"${_MENU_RESO}${_MENU_DPTH:+x"${_MENU_DPTH}"},"}auto
		#set default=0
		set timeout=${_MENU_TOUT:-5}
		set timeout_style=menu
		set theme=${_FTHM#"${_DIRS_TGET}"}
		export theme
		
_EOT_
	# --- standard installation mode ------------------------------------------
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}"
			menuentry 'Automatic installation' {
			  set gfxpayload=keep
			  set background_color=black
			  echo 'Loading kernel ...'
			  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
			  echo 'Loading initial ramdisk ...'
			  initrd ${_FIRD}
			}

_EOT_
	# --- graphical installation mode -----------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}"
				menuentry 'Automatic installation of gui' {
				  set gfxpayload=keep
				  set background_color=black
				  echo 'Loading kernel ...'
				  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
				  echo 'Loading initial ramdisk ...'
				  initrd ${_FIRD}
				}
				
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing grub for autoinstall --------------------------------------------
function funcRemastering_grub() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# grub.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTMP="${_PATH}.tmp"
		if ! grep -qEi '^menuentry[ \t]+.*$' "${_PATH}"; then
			continue
		fi
		sed -e '0,/^menuentry/ {'                    \
			-e '/^menuentry/i source '"${_PAUT}"'\n' \
			-e '}'                                   \
				"${_PATH}"                           \
			>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for grub ------------------
		funcRemastering_grub_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'grub.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
		sed -e '/^[ \t]*\(\|set[ \t]\+\)default=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)timeout=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)theme=/   d' \
			"${_PATH}"                               \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- copy auto-install files -------------------------------------------------
function funcRemastering_copy() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# file name
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _BASE=""				# base name
	declare       _EXTN=""				# extension

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "copy" "auto-install files" 1>&2

	# -------------------------------------------------------------------------
	for _PATH in        \
		"${_SHEL_ERLY}" \
		"${_SHEL_LATE}" \
		"${_SHEL_PART}" \
		"${_SHEL_RUNS}" \
		"${_TGET_LIST[23]}"
	do
		if [[ ! -e "${_PATH}" ]]; then
			continue
		fi
		_DIRS="${_DIRS_TGET}${_PATH#"${_DIRS_CONF}"}"
		_DIRS="${_DIRS%/*}"
		mkdir -p "${_DIRS}"
		case "${_PATH}" in
			*/script/*   )
				printf "%20.20s: %s\n" "copy" "${_PATH#"${_DIRS_CONF}"/}" 1>&2
				cp -a "${_PATH}" "${_DIRS}"
				chmod ugo+xr-w "${_DIRS}/${_PATH##*/}"
				;;
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
				_FNAM="${_PATH##*/}"
				_WORK="${_FNAM%.*}"
				_EXTN="${_FNAM#"${_WORK}"}"
				_BASE="${_FNAM%"${_EXTN}"}"
				_WORK="${_PATH%"${_FNAM}"}"
				_WORK="${_WORK%%/}/${_BASE%_*}"
				printf "%20.20s: %s\n" "copy" "${_WORK#"${_DIRS_CONF}"/}*${_EXTN}" 1>&2
				cp -a "${_WORK}"*"${_EXTN}" "${_DIRS}"
				chmod ugo+r-xw "${_DIRS}/"*
				;;
			*/windows/*  ) ;;
			*            ) ;;
		esac
	done
}

# --- Extract a compressed cpio _TGET_FILE ------------------------------------
funcXcpio() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination _DIRS_DESTectory
	shift 2

	  if gzip -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then gzip -c -d    "${_TGET_FILE}"
	elif zstd -q -c -t "${_TGET_FILE}" > /dev/null 2>&1 ; then zstd -q -c -d "${_TGET_FILE}"
	elif xzcat -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then xzcat         "${_TGET_FILE}"
	elif lz4cat -t <   "${_TGET_FILE}" > /dev/null 2>&1 ; then lz4cat        "${_TGET_FILE}"
	elif bzip2 -t      "${_TGET_FILE}" > /dev/null 2>&1 ; then bzip2 -c -d   "${_TGET_FILE}"
	elif lzop -t       "${_TGET_FILE}" > /dev/null 2>&1 ; then lzop -c -d    "${_TGET_FILE}"
	fi | (
		if [[ -n "${_DIRS_DEST}" ]]; then
			mkdir -p -- "${_DIRS_DEST}"
			cd -- "${_DIRS_DEST}"
		fi
		cpio "$@"
	)
}

# --- Read bytes out of a file, checking that they are valid hex digits -------
funcReadhex() {
	dd if="${1:?}" bs=1 skip="${2:?}" count="${3:?}" 2> /dev/null | LANG=C grep -E "^[0-9A-Fa-f]{$3}\$"
}

# --- Check for a zero byte in a file -----------------------------------------
funcCheckzero() {
	dd if="${1:?}" bs=1 skip="${2:?}" count=1 2> /dev/null | LANG=C grep -q -z '^$'
}

# --- Split an initramfs into _TGET_FILEs and call funcXcpio on each ----------
funcSplit_initramfs() {
	declare -r    _TGET_FILE="${1:?}"	# target file
	declare -r    _DIRS_DEST="${2:-}"	# destination directory
	declare -r -a _OPTS=("--preserve-modification-time" "--no-absolute-filenames" "--quiet")
	declare -i    _CONT=0				# count
	declare -i    _PSTR=0				# start point
	declare -i    _PEND=0				# end point
	declare       _MGIC=""				# magic word
	declare       _DSUB=""				# sub directory
	declare       _SARC=""				# sub archive

	while true
	do
		_PEND="${_PSTR}"
		while true
		do
			# shellcheck disable=SC2310
			if funcCheckzero "${_TGET_FILE}" "${_PEND}"; then
				_PEND=$((_PEND + 4))
				# shellcheck disable=SC2310
				while funcCheckzero "${_TGET_FILE}" "${_PEND}"
				do
					_PEND=$((_PEND + 4))
				done
				break
			fi
			# shellcheck disable=SC2310
			_MGIC="$(funcReadhex "${_TGET_FILE}" "${_PEND}" "6")" || break
			test "${_MGIC}" = "070701" || test "${_MGIC}" = "070702" || break
			_NSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 94))" "8")
			_FSIZ=0x$(funcReadhex "${_TGET_FILE}" "$((_PEND + 54))" "8")
			_PEND=$((_PEND + 110))
			_PEND=$(((_PEND + _NSIZ + 3) & ~3))
			_PEND=$(((_PEND + _FSIZ + 3) & ~3))
		done
		if [[ "${_PEND}" -eq "${_PSTR}" ]]; then
			break
		fi
		_CONT=$((_CONT + 1))
		if [[ "${_CONT}" -eq 1 ]]; then
			_DSUB="early"
		else
			_DSUB="early${_CONT}"
		fi
		dd if="${_TGET_FILE}" skip="${_PSTR}" count="$((_PEND - _PSTR))" iflag=skip_bytes 2> /dev/null |
		(
			if [[ -n "${_DIRS_DEST}" ]]; then
				mkdir -p -- "${_DIRS_DEST}/${_DSUB}"
				cd -- "${_DIRS_DEST}/${_DSUB}"
			fi
			cpio -i "${_OPTS[@]}"
		)
		_PSTR="${_PEND}"
	done
	if [[ "${_PEND}" -gt 0 ]]; then
		_SARC="${_DIRS_TEMP}/${FUNCNAME[0]}"
		mkdir -p "${_SARC%/*}"
		dd if="${_TGET_FILE}" skip="${_PEND}" iflag=skip_bytes 2> /dev/null > "${_SARC}"
		funcXcpio "${_SARC}" "${_DIRS_DEST:+${_DIRS_DEST}/main}" -i "${_OPTS[@]}"
		rm -f "${_SARC:?}"
	else
		funcXcpio "${_TGET_FILE}" "${_DIRS_DEST}" -i "${_OPTS[@]}"
	fi
}

# --- remastering for initrd --------------------------------------------------
function funcRemastering_initrd() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _DTMP=""				# directory (extract)
	declare       _DTOP=""				# directory (main)
	declare       _DIRS=""				# directory

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "remake" "initrd" 1>&2

	# -------------------------------------------------------------------------
	_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
	_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"					# kernel
	_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"					# initrd
	_DTMP="$(mktemp -qtd "${_FIRD##*/}.XXXXXX")"

	# --- extract -------------------------------------------------------------
	funcSplit_initramfs "${_DIRS_TGET}${_FIRD}" "${_DTMP}"
	_DTOP="${_DTMP}"
	if [[ -d "${_DTOP}/main/." ]]; then
		_DTOP+="/main"
	fi
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DTOP}" "${_TGET_LIST[@]}"
#	ln -s "${_TGET_LIST[23]#"${_DIRS_CONF}"}" "${_DTOP}/preseed.cfg"
	# --- repackaging ---------------------------------------------------------
	pushd "${_DTOP}" > /dev/null
		find . | cpio --format=newc --create --quiet | gzip > "${_DIRS_TGET}${_FIRD%/*}/${_MINI_IRAM}"
	popd > /dev/null

	rm -rf "${_DTMP:?}"
}

# --- get volume id -----------------------------------------------------------
function funcGet_volid() {
	declare -r    _PATH_TGET="${1:?}"	# target path
	declare       _VLID=""				# volume id

	_VLID="$(LANG=C file -L "${_PATH_TGET}")"
	_VLID="${_VLID#*\'}"
	_VLID="${_VLID%\'*}"
	echo -n "${_VLID}"
}

# --- create iso image --------------------------------------------------------
function funcCreate_iso() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_MDIA="${2:?}"	# output path
	shift 2
	declare -r -a _OPTN_XORR=("$@")		# xorrisofs options
	declare -a    _LIST=()				# data list
	declare       _PATH=""				# file name
	              _PATH="$(mktemp -qt "${_PATH_MDIA##*/}.XXXXXX")"
	readonly      _PATH

	pushd "${_DIRS_TGET}" > /dev/null
	if ! nice -n "${_NICE_VALU:-19}" xorrisofs "${_OPTN_XORR[@]}" -output "${_PATH}" . > /dev/null 2>&1; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [xorriso]" "${_PATH_MDIA##*/}" 1>&2
	else
		if ! cp --preserve=timestamps "${_PATH}" "${_PATH_MDIA}"; then
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "error [cp]" "${_PATH_MDIA##*/}" 1>&2
		else
			IFS= mapfile -d ' ' -t _LIST < <(LANG=C TZ=UTC ls -lLh --time-style="+%Y-%m-%d %H:%M:%S" "${_PATH_MDIA}" || true)
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "complete" "${_PATH_MDIA##*/} (${_LIST[4]})" 1>&2
		fi
	fi
	rm -f "${_PATH:?}"
	popd > /dev/null
}

# --- remastering for media ---------------------------------------------------
function funcRemastering_media() {
	declare -r    _DIRS_TGET="${1:?}"						# target directory
	shift
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
#	declare       _PATH=""									# file name
	declare       _FMBR=""									# "         (mbr.img)
	declare       _FEFI=""									# "         (efi.img)
	declare       _FCAT=""									# "         (boot.cat or boot.catalog)
	declare       _FBIN=""									# "         (isolinux.bin or eltorito.img)
	declare       _FHBR=""									# "         (isohdpfx.bin)
	declare       _VLID=""									# 
	declare -i    _SKIP=0									# 
	declare -i    _SIZE=0									# 

	# --- pre-processing ------------------------------------------------------
#	_PATH="${_DWRK}/${_TGET_LIST[17]##*/}.tmp"				# file path
	_FCAT="$(find "${_DIRS_TGET}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
	_FBIN="$(find "${_DIRS_TGET}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
	_VLID="$(funcGet_volid "${_TGET_LIST[13]}")"
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	# --- create iso image file -----------------------------------------------
	if [[ -e "${_DIRS_TGET}/${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (hybrid)" 1>&2
		_FHBR="$(find /usr/lib  -iname 'isohdpfx.bin' -type f || true)"
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-cache-inodes \
			${_FHBR:+-isohybrid-mbr "${_FHBR}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			-boot-load-size 4 -boot-info-table \
			-no-emul-boot \
			-eltorito-alt-boot ${_FEFI:+-e "${_FEFI}"} \
			-no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
	else
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (grub2-mbr)" 1>&2
		_FMBR="${_DWRK}/mbr.img"
		_FEFI="${_DWRK}/efi.img"
		# --- extract the mbr template ----------------------------------------
		dd if="${_TGET_LIST[13]}" bs=1 count=446 of="${_FMBR}" > /dev/null 2>&1
		# --- extract efi partition image -------------------------------------
		_SKIP=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $2;}')
		_SIZE=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $4;}')
		dd if="${_TGET_LIST[13]}" bs=512 skip="${_SKIP}" count="${_SIZE}" of="${_FEFI}" > /dev/null 2>&1
		# --- create iso image file -------------------------------------------
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			${_FMBR:+--grub2-mbr "${_FMBR}"} \
			--mbr-force-bootable \
			${_FEFI:+-append_partition 2 0xEF "${_FEFI}"} \
			-appended_part_as_gpt \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			-no-emul-boot \
			-boot-load-size 4 -boot-info-table \
			--grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
			-no-emul-boot
	fi
}

# --- remastering -------------------------------------------------------------
function funcRemastering() {
	declare -i    _time_start=0								# start of elapsed time
	declare -i    _time_end=0								# end of elapsed time
	declare -i    _time_elapsed=0							# result of elapsed time
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
	declare -r    _DOVL="${_DWRK}/overlay"					# overlay
	declare -r    _DUPR="${_DOVL}/upper"					# upperdir
	declare -r    _DLOW="${_DOVL}/lower"					# lowerdir
	declare -r    _DWKD="${_DOVL}/work"						# workdir
	declare -r    _DMRG="${_DOVL}/merged"					# merged
	declare       _PATH=""									# file name
	declare       _FEFI=""									# "         (efiboot.img)
	declare       _BOPT=""									# boot options
	
	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" "${_TGET_LIST[13]##*/}" 1>&2

	# --- pre-check -----------------------------------------------------------
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	if [[ -z "${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "unknown target" "${_TGET_LIST[2]%%-*} [${_TGET_LIST[13]##*/}]" 1>&2
		return
	fi
	if [[ ! -s "${_TGET_LIST[13]}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[93m%20.20s: %s${_CODE_ESCP}[m\n" "not exist" "${_TGET_LIST[13]##*/}" 1>&2
		return
	fi
	if mountpoint --quiet "${_DMRG}"; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "already mounted" "${_DMRG#"${_DWRK}"/}" 1>&2
		return
	fi

	# --- pre-processing ------------------------------------------------------
	printf "%20.20s: %s\n" "start" "${_DMRG#"${_DWRK}"/}" 1>&2
	rm -rf "${_DOVL:?}"
	mkdir -p "${_DUPR}" "${_DLOW}" "${_DWKD}" "${_DMRG}"

	# --- main processing -----------------------------------------------------
	mount -r "${_TGET_LIST[13]}" "${_DLOW}"
	mount -t overlay overlay -o lowerdir="${_DLOW}",upperdir="${_DUPR}",workdir="${_DWKD}" "${_DMRG}"
	# --- create boot options -------------------------------------------------
	_BOPT="$(funcRemastering_boot_options "${_TGET_LIST[@]}")"
	# --- create autoinstall configuration file for isolinux ------------------
	funcRemastering_isolinux "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- create autoinstall configuration file for grub ----------------------
	funcRemastering_grub "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DMRG}" "${_TGET_LIST[@]}"
	# --- remastering for initrd ----------------------------------------------
	case "${_TGET_LIST[2]}" in
		*-mini-*         ) funcRemastering_initrd "${_DMRG}" "${_TGET_LIST[@]}";;
		*                ) ;;
	esac
	# --- create iso image file -----------------------------------------------
	funcRemastering_media "${_DMRG}" "${_TGET_LIST[@]}"
	umount "${_DMRG}"
	umount "${_DLOW}"

	# --- post-processing -----------------------------------------------------
	rm -rf "${_DOVL:?}"
	printf "%20.20s: %s\n" "finish" "${_DMRG#"${_DWRK}"/}" 1>&2

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true)" "finish" "${_TGET_LIST[13]##*/}" 1>&2
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%10dd%02dh%02dm%02ds: %-20.20s: %s${_CODE_ESCP}[m\n" "$((_time_elapsed/86400))" "$((_time_elapsed%86400/3600))" "$((_time_elapsed%3600/60))" "$((_time_elapsed%60))" "elapsed" "${_TGET_LIST[13]##*/}" 1>&2
}

	declare -i    _time_start=0								# start of elapsed time
	declare -i    _time_end=0								# end of elapsed time
	declare -i    _time_elapsed=0							# result of elapsed time

	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" 1>&2

	# --- network parameter ---------------------------------------------------
	declare       _NWRK_HOST=""								# hostname              (ex. sv-server)
	declare       _NWRK_WGRP="workgroup"					# domain                (ex. workgroup)
	declare       _NICS_NAME="ens160"						# network device name   (ex. ens160)
	declare       _NICS_MADR=""								#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR="192.168.1.1"					# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR="24"							# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
#	declare       _IPV4_UADR=""								# IPv4 address up       (ex. 192.168.1)
#	declare       _NMAN_NAME=""								# network manager name  (nm_config, ifupdown, loopback)
	declare       _MENU_RESO="1024x768"
	declare       _MENU_DPTH="16"
	declare       _MENU_MODE="791"
	declare       _MINI_IRAM="initps.gz"

	_DIRS_TOPS="${_DIRS_TOPS:-/srv}"
	_DIRS_HGFS="${_DIRS_HGFS:-"${_DIRS_TOPS}"/hgfs}"
	_DIRS_HTML="${_DIRS_HTML:-"${_DIRS_TOPS}"/http/html}"
	_DIRS_SAMB="${_DIRS_SAMB:-"${_DIRS_TOPS}"/samba}"
	_DIRS_TFTP="${_DIRS_TFTP:-"${_DIRS_TOPS}"/tftp}"
	_DIRS_USER="${_DIRS_USER:-"${_DIRS_TOPS}"/user}"
	_DIRS_SHAR="${_DIRS_SHAR:-"${_DIRS_USER}"/share}"
	_DIRS_CONF="${_DIRS_CONF:-"${_DIRS_SHAR}"/conf}"
	_DIRS_DATA="${_DIRS_DATA:-"${_DIRS_CONF}"/_data}"
	_DIRS_KEYS="${_DIRS_KEYS:-"${_DIRS_CONF}"/_keyring}"
	_DIRS_TMPL="${_DIRS_TMPL:-"${_DIRS_CONF}"/_template}"
	_DIRS_SHEL="${_DIRS_SHEL:-"${_DIRS_CONF}"/script}"
	_DIRS_IMGS="${_DIRS_IMGS:-"${_DIRS_SHAR}"/imgs}"
	_DIRS_ISOS="${_DIRS_ISOS:-"${_DIRS_SHAR}"/isos}"
	_DIRS_LOAD="${_DIRS_LOAD:-"${_DIRS_SHAR}"/load}"
	_DIRS_RMAK="${_DIRS_RMAK:-"${_DIRS_SHAR}"/rmak}"
	_PATH_CONF="${_PATH_CONF:-"${_DIRS_DATA}"/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-"${_DIRS_DATA}"/media.dat}"
	_CONF_KICK="${_CONF_KICK:-"${_DIRS_TMPL}"/kickstart_rhel.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-"${_DIRS_TMPL}"/user-data_ubuntu}"
	_CONF_SEDD="${_CONF_SEDD:-"${_DIRS_TMPL}"/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-"${_DIRS_TMPL}"/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-"${_DIRS_TMPL}"/yast_opensuse.xml}"
	_SHEL_ERLY="${_SHEL_ERLY:-"${_DIRS_SHEL}"/autoinst_cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-"${_DIRS_SHEL}"/autoinst_cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-"${_DIRS_SHEL}"/autoinst_cmd_part.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-"${_DIRS_SHEL}"/autoinst_cmd_run.sh}"

	for I in "${!_LIST_MDIA[@]}"
	do
		_LINE="${_LIST_MDIA[I]}"
		_LINE="${_LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
		_LINE="${_LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
		_LINE="${_LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
		_LINE="${_LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
		_LINE="${_LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
		_LINE="${_LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
		_LINE="${_LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
		_LINE="${_LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
		_LINE="${_LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
		_LINE="${_LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
		_LINE="${_LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
		_LINE="${_LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
		_LINE="${_LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
		_LINE="${_LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
		_LINE="${_LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
		_LINE="${_LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
		read -r -a _LIST < <(echo "${_LINE}")
		case "${_LIST[1]}" in
			o) ;;
			*) continue;;
		esac
		_NWRK_HOST="sv-${_LIST[2]%%-*}"
		funcRemastering "${_LIST[@]}"
	done

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "finish" 1>&2
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[97m%10dd%02dh%02dm%02ds: %s${_CODE_ESCP}[m\n" "$((_time_elapsed/86400))" "$((_time_elapsed%86400/3600))" "$((_time_elapsed%3600/60))" "$((_time_elapsed%60))" "elapsed" 1>&2

	exit