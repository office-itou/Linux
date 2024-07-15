#!/bin/bash

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# -------------------------------------------------------------------------
	declare -r -a APP_LIST=("bdebstrap" "dosfstools" "grub-efi-ia32-bin" "grub-pc-bin" "isolinux" "shellcheck" "tree" "squashfs-tools-ng" "xorriso")
	declare -a    APP_FIND=()
	declare       APP_LINE=""
	# shellcheck disable=SC2312
	mapfile APP_FIND < <(LANG=C apt list "${APP_LIST[@]}" 2> /dev/null | sed -e '/\(^[[:blank:]]*$\|WARNING\|Listing\|installed\)/! {' -e 's%\([[:graph:]]\)/.*%\1%g' -ne 'p}' | sed -z 's/[\r\n]\+/ /g')
	for I in "${!APP_FIND[@]}"
	do
		if [[ -n "${APP_LINE}" ]]; then
			APP_LINE+=" "
		fi
		APP_LINE+="${APP_FIND[${I}]}"
	done
	if [[ -n "${APP_LINE}" ]]; then
		echo "please install these:"
		echo "sudo apt-get install ${APP_LINE}"
		exit 1
	fi

	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
#	declare -r    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
	declare -r    DIRS_WORK="${PWD}/share"

#	sudo bash -c 'for D in share/{html,imgs,isos,rmak} ; do mv "${D}" "${D}.back"; ln -s "/mnt/share.nfs/master/share/${D##*/}" share; done'
#	sudo ln -s /mnt/hgfs/workspace/Image/linux/bin/keyring share/keys

# Debian  
#	| Life  | Version. | Code name          | Release date |End of support|  Long term   | Kernel         | Note          | 
#	| :---: | :------: | :----------------- | :----------: | :----------: | :----------: |:-------------- | :------------ | 
#	|  EOL  |   10.0   | Buster             |  2019-07-06  |  2022-09-10  |  2024-06-30  |                | oldoldstable  |
#	|       |   11.0   | Bullseye           |  2021-08-14  |  2024-07-01  |  2026-06-01  | 5.10.0         | oldstable     |
#	|       |   12.0   | Bookworm           |  2023-06-10  |  2026-06-01  |  2028-06-01  | 6.1.0          | stable        |
#	|       |   13.0   | Trixie             |  20xx-xx-xx  |  20xx-xx-xx  |  20xx-xx-xx  |                | testing       |
#	|       |   14.0   | Forky              |  20xx-xx-xx  |  20xx-xx-xx  |  20xx-xx-xx  |                |               |
#
# Ubuntu  
#	| Life  | Version. | Code name          | Release date |End of support|  Long term   | Kernel         | Note          |
#	| :---: | :------: | :----------------- | :----------: | :----------: | :----------: |:-------------- | :------------ |
#	|  EOL  |  14.04   | Trusty Tahr        |  2014-04-17  |  2019-04-25  |  2024-04-25  |                |               |
#	|  LTS  |  16.04   | Xenial Xerus       |  2016-04-21  |  2021-04-30  |  2026-04-23  |                |               |
#	|  LTS  |  18.04   | Bionic Beaver      |  2018-04-26  |  2023-05-31  |  2028-04-26  | 4.15.0         |               |
#	|       |  20.04   | Focal Fossa        |  2020-04-23  |  2025-05-29  |  2030-04-23  | 5.15.0/5.4.0   | desktop/other |
#	|       |  22.04   | Jammy Jellyfish    |  2022-04-21  |  2027-06-01  |  2032-04-21  | 6.5.0/5.15.0   | desktop/live  |
#	|  EOL  |  23.04   | Lunar Lobster      |  2023-04-20  |  2024-01-25  |              |                |               |
#	|       |  23.10   | Mantic Minotaur    |  2023-10-12  |  2024-07-xx  |              | 6.5.0          |               |
#	|       |  24.04   | Noble Numbat       |  2024-04-25  |  2029-05-31  |  2034-04-25  | 6.8.0          |               |
#	|       |  24.10   | Oracular Oriole    |  2024-10-10  |  2025-07-xx  |              | 6.8.0          |               |

# --- custom live image -------------------------------------------------------
	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  Live%20media%20Live%20mode          -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  live-denian-10-buster       Live%20Debian%2010                  debian          live-denian-10-buster-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-denian-11-bullseye     Live%20Debian%2011                  debian          live-denian-11-bullseye-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-denian-12-bookworm     Live%20Debian%2012                  debian          live-denian-12-bookworm-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-denian-13-trixie       Live%20Debian%2013                  debian          live-denian-13-trixie-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-denian-xx-unstable     Live%20Debian%20xx                  debian          live-denian-xx-unstable-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"x  live-ubuntu-14.04-trusty    Live%20Ubuntu%2014.04               ubuntu          live-ubuntu-14.04-trusty                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"L  live-ubuntu-16.04-xenial    Live%20Ubuntu%2016.04               ubuntu          live-ubuntu-16.04-xenial                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"L  live-ubuntu-18.04-bionic    Live%20Ubuntu%2018.04               ubuntu          live-ubuntu-18.04-bionic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-20.04-focal     Live%20Ubuntu%2020.04               ubuntu          live-ubuntu-20.04-focal                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-22.04-jammy     Live%20Ubuntu%2022.04               ubuntu          live-ubuntu-22.04-jammy                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"x  live-ubuntu-23.04-lunar     Live%20Ubuntu%2023.04               ubuntu          live-ubuntu-23.04-lunar                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-23.10-mantic    Live%20Ubuntu%2023.10               ubuntu          live-ubuntu-23.10-mantic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-10-12  2024-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-24.04-noble     Live%20Ubuntu%2024.04               ubuntu          live-ubuntu-24.04-noble                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-24.10-oracular  Live%20Ubuntu%2024.10               ubuntu          live-ubuntu-24.10-oracular                  live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-xx.xx-devel     Live%20Ubuntu%20xx.xx               ubuntu          live-ubuntu-xx.xx-devel                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

	declare -r    OLD_IFS="${IFS}"
	declare -a    COMD_LINE=("${PROG_PARM[@]}")
	declare -a    TGET_LIST=("${DATA_LIST_CSTM[@]}")
	declare -a    TGET_LINE=()
	declare       FLAG_KEEP=""
	declare       DIRS_CONF=""
	declare       DIRS_LIVE=""
	declare       DIRS_TEMP=""
	declare       DIRS_CDFS=""
	declare       DIRS_MNTS=""
	declare       PATH_SRCS=""
	declare       PATH_DEST=""
	declare       FILE_NAME=""
	declare       SQFS_NAME=""
#	declare -a    PARM=()
	declare -i    I=0

	date +"%Y/%m/%d %H:%M:%S"

#	rm -rf ${DIRS_WORK}/live
#	mkdir -p ${DIRS_WORK}/live

	for ((I=0; I<"${#TGET_LIST[@]}"; I++))
	do
		read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
		TGET_LINE[0]="-"
		TGET_LIST[I]="${TGET_LINE[*]}"
	done

	IFS=' =,'
	set -f
	set -- "${COMD_LINE[@]:-}"
	set +f
	IFS=${OLD_IFS}
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-k | --keep )
				FLAG_KEEP="true"
				shift
				COMD_LINE=("${@:-}")
				;;
			* )
				if [[ -z "${1:-}" ]]; then
					break
				fi
				for ((I=0; I<"${#TGET_LIST[@]}"; I++))
				do
					read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
					if [[ "${TGET_LINE[1]##*-}" = "$1" ]]; then
						TGET_LINE[0]="o"
						TGET_LIST[I]="${TGET_LINE[*]}"
						break
					fi
				done
				shift
				COMD_LINE=("${@:-}")
				;;
		esac
		if [[ -z "${COMD_LINE[*]:-}" ]]; then
			break
		fi
		IFS=' =,'
		set -f
		set -- "${COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
	done

	for ((I=0; I<"${#TGET_LIST[@]}"; I++))
	do
		read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
		if [[ "${TGET_LINE[0]}" != "o" ]]; then
			continue
		fi
		echo -e "\033[m\033[45m${TGET_LINE[2]//%20/ }\033[m"
		DIRS_CONF="${DIRS_WORK}/conf"
		DIRS_LIVE="${DIRS_WORK}/live/${TGET_LINE[1]}"
		DIRS_TEMP="${DIRS_WORK}/temp/${PROG_PROC}/${TGET_LINE[1]}"
		DIRS_CDFS="${DIRS_TEMP}/cdfs"
		DIRS_MNTS="${DIRS_TEMP}/mnts"
		SQFS_NAME="${TGET_LINE[1]}.squashfs"
#		SQFS_NAME="filesystem.squashfs"
		# --- create squashfs file --------------------------------------------
		if [[ -z "${FLAG_KEEP}" ]] || [[ ! -f "${DIRS_LIVE}/${SQFS_NAME}" ]]; then
			rm -rf "${DIRS_LIVE}"
			bdebstrap \
			    --config "${DIRS_CONF}/_template/live_${TGET_LINE[3]}.yaml" \
			    --suite "${TGET_LINE[1]##*-}" \
			    --name "${TGET_LINE[1]}" \
			    --output-base-dir "${DIRS_WORK}/live" \
			    --target "${SQFS_NAME}" \
			    || continue
		fi
		# --- create cd/dvd image ---------------------------------------------
		rm -rf "${DIRS_TEMP}"
		mkdir -p "${DIRS_TEMP}/"{cdfs/{.disk,EFI/boot,boot/grub/{live-theme,x86_64-efi},isolinux,live/{boot,config.conf.d}},mnts}
		# ---- copy script ----------------------------------------------------
		for PATH_SRCS in "${DIRS_CONF}/script/"live_*sh
		do
			FILE_NAME="${PATH_SRCS##*live_}"
			case "${PATH_SRCS##*live_}" in
				????-user-boot*) PATH_DEST="${DIRS_CDFS}/live/boot/${FILE_NAME}";;
				????-user-conf*) PATH_DEST="${DIRS_CDFS}/live/config.conf.d/${FILE_NAME}.conf";;
				*) continue;;
			esac
			echo "${PATH_SRCS} -> ${PATH_DEST}"
			cp -a "${PATH_SRCS}" "${PATH_DEST}"
			chmod 555 "${PATH_DEST}"
		done
		# ---- create .disk/info ----------------------------------------------
		touch "${DIRS_TEMP}/cdfs/.disk/info"
		# ---- copy filesystem ------------------------------------------------
		cp -a "${DIRS_LIVE}/manifest"     "${DIRS_TEMP}/cdfs/live/filesystem.packages"
		cp -a "${DIRS_LIVE}/${SQFS_NAME}" "${DIRS_TEMP}/cdfs/live/filesystem.squashfs"
		# ---- copy vmlinuz/initrd --------------------------------------------
		mount -r -t squashfs "${DIRS_TEMP}/cdfs/live/filesystem.squashfs" "${DIRS_MNTS}"
		case "${TGET_LINE[3]}" in
			debian )
				cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-amd64    "${DIRS_TEMP}/cdfs/live/vmlinuz"
				cp -a "${DIRS_MNTS}/boot/"initrd.img-*-amd64 "${DIRS_TEMP}/cdfs/live/initrd.img"
				;;
			ubuntu )
				cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-generic    "${DIRS_TEMP}/cdfs/live/vmlinuz"
				cp -a "${DIRS_MNTS}/boot/"initrd.img-*-generic "${DIRS_TEMP}/cdfs/live/initrd.img"
				;;
			* )
				break
				;;
		esac
		umount "${DIRS_MNTS}"
		# ---- create isolinux ------------------------------------------------
#		wget --directory-prefix="${DIRS_TEMP}/cdfs/isolinux" \
#			"https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/boot-screens/splash.png"
		cp -a /usr/lib/syslinux/modules/bios/* "${DIRS_TEMP}/cdfs/isolinux"
		cp -a /usr/lib/ISOLINUX/isolinux.bin   "${DIRS_TEMP}/cdfs/isolinux"
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/isolinux.cfg"
			include menu.cfg
			default vesamenu.c32
			prompt 0
			timeout 50
_EOT_
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/menu.cfg"
			menu resolution 1024 768
			menu hshift 12
			menu width 100
			
			menu title Boot menu
			include stdmenu.cfg
			include live.cfg
			include install.cfg
			menu begin utilities
			 	menu label ^Utilities
			 	menu title Utilities
			 	include stdmenu.cfg
			 	label mainmenu
			 		menu label ^Back..
			 		menu exit
			 	include utilities.cfg
			menu end
			
			menu clear
_EOT_
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/stdmenu.cfg"
			menu background		splash.png
			menu color title	* #FFFFFFFF *
			menu color border	* #00000000 #00000000 none
			menu color sel		* #ffffffff #76a1d0ff *
			menu color hotsel	1;7;37;40 #ffffffff #76a1d0ff *
			menu color tabmsg	* #ffffffff #00000000 *
			menu color help		37;40 #ffdddd00 #00000000 none
			menu vshift 12
			menu rows 10
			menu helpmsgrow 15
			# The command line must be at least one line from the bottom.
			menu cmdlinerow 16
			menu timeoutrow 16
			menu tabmsgrow 18
			menu tabmsg Press ENTER to boot or TAB to edit a menu entry
_EOT_
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/live.cfg"
			label ${TGET_LINE[2]//%20/_}
			 	menu label ^${TGET_LINE[2]//%20/ }
			 	menu default
			 	linux /live/vmlinuz
			 	initrd /live/initrd.img
			 	append boot=live components quiet splash
_EOT_
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/install.cfg"
			label installstart
			 	menu label Start ^installer
			 	linux /install/gtk/vmlinuz
			 	initrd /install/gtk/initrd.gz
			 	append vga=788  --- quiet
_EOT_
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/isolinux/utilities.cfg"
			label hdt
			 	menu label ^Hardware Detection Tool (HDT)
			 	com32 hdt.c32
			
			label poweroff
			 	menu label ^System shutdown
			 	com32 poweroff.c32
			
			label reboot
			 	menu label ^System restart
			 	com32 reboot.c32
_EOT_
		# ---- create grub ----------------------------------------------------
		cp -a /usr/lib/grub/x86_64-efi/*  "${DIRS_TEMP}/cdfs/boot/grub/x86_64-efi"
		cp -a /usr/share/grub/unicode.pf2 "${DIRS_TEMP}/cdfs/boot/grub"
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/cdfs/boot/grub/grub.cfg"
			set timeout=5
			set default=0
			set lang=ja_JP
			grub_platform
			
			if [ \${iso_path} ] ; then
			  set loopback="findiso=\${iso_path}"
			  export loopback
			fi
			
			menuentry "${TGET_LINE[2]//%20/ }" {
			  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			  linux  /live/vmlinuz boot=live components splash quiet "\${loopback}"
			  initrd /live/initrd.img
			}
			menuentry "System shutdown" {
			  echo "System shutting down ..."
			  halt
			}
			menuentry "System restart" {
			  echo "System rebooting ..."
			  reboot
			}
_EOT_
		# ---- create dummy efi.img -------------------------------------------
		dd if=/dev/zero of="${DIRS_TEMP}/efi.img" bs=1M count=100
		mkfs.fat "${DIRS_TEMP}/efi.img"
		mount "${DIRS_TEMP}/efi.img" "${DIRS_MNTS}"
		grub-install --target=x86_64-efi --efi-directory="${DIRS_MNTS}" --bootloader-id=boot --install-modules="" --removable
		cp -a "${DIRS_MNTS}/EFI/BOOT/BOOTX64.EFI" "${DIRS_TEMP}/cdfs/EFI/boot/bootx64.efi"
		cp -a "${DIRS_MNTS}/EFI/BOOT/grubx64.efi" "${DIRS_TEMP}/cdfs/EFI/boot/grubx64.efi"
		umount "${DIRS_MNTS}"
		# ---- create efi.img -------------------------------------------------
		dd if=/dev/zero of="${DIRS_CDFS}/boot/grub/efi.img" bs=1M count=10
		mkfs.fat "${DIRS_CDFS}/boot/grub/efi.img"
		mount "${DIRS_CDFS}/boot/grub/efi.img" "${DIRS_MNTS}"
		mkdir -p "${DIRS_MNTS}/"{EFI/boot,boot/grub}
		cp -a "${DIRS_CDFS}/EFI/boot/"{bootx64.efi,grubx64.efi} "${DIRS_MNTS}/EFI/boot/"
		cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_MNTS}/boot/grub/grub.cfg"
			search --set=root --file /.disk/info
			set prefix=(\$root)/boot/grub
			configfile (\$root)/boot/grub/grub.cfg
_EOT_
		umount "${DIRS_MNTS}"
		# --- create iso file -------------------------------------------------
		xorriso -as mkisofs                                 \
		    -verbose                                        \
		    -iso-level 3                                    \
		    -full-iso9660-filenames                         \
		    -volid "DEBIAN_LIVE"                            \
		    -eltorito-boot isolinux/isolinux.bin            \
		    -eltorito-catalog isolinux/boot.cat             \
		    -no-emul-boot                                   \
		    -boot-load-size 4                               \
		    -boot-info-table                                \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin   \
		    -eltorito-alt-boot                              \
		    -e boot/grub/efi.img                            \
		    -no-emul-boot                                   \
		    -isohybrid-gpt-basdat                           \
		    -output "${DIRS_LIVE}.iso"                      \
		    "${DIRS_CDFS}"
	done

	date +"%Y/%m/%d %H:%M:%S"

	exit 0
# https://manpages.debian.org/bookworm/live-boot-doc/live-boot.7.ja.html
# https://manpages.debian.org/bookworm/bdebstrap/bdebstrap.1.en.html
