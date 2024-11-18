#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		*) ;;
	esac

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# -------------------------------------------------------------------------
	# shellcheck disable=SC2155
	declare -r    APP_ARCH="$(dpkg --print-architecture)"
	declare -r -a APP_LIST=("bdebstrap" "dosfstools" "grub-efi-ia32-bin" "grub-pc-bin" "isolinux" "shellcheck" "tree" "squashfs-tools-ng" "xorriso")
	declare -a    APP_FIND=()
	declare       APP_LINE=""
	# shellcheck disable=SC2312
	mapfile APP_FIND < <(LANG=C apt list "${APP_LIST[@]}" 2> /dev/null | sed -e '/\(all\|'"${APP_ARCH:-}"'\)/ {' -e '/\(^[[:blank:]]*$\|WARNING\|Listing\|installed\)/! {' -e 's%\([[:graph:]]\)/.*%\1%g' -ne 'p}}' | sed -z 's/[\r\n]\+/ /g')
	for I in "${!APP_FIND[@]}"
	do
		APP_LINE+="${APP_LINE:+" "}${APP_FIND[${I}]}"
	done
	if [[ -n "${APP_LINE}" ]]; then
		echo "please install these:"
		echo "sudo apt-get install ${APP_LINE}"
		exit 1
	fi

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
#	declare -r    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
	declare -r    DIRS_WORK="${PWD}/share"
	if [[ "${DIRS_WORK}" = "/" ]]; then
		echo "terminate the process because the working directory is root"
		exit 1
	fi
#	declare -r    DIRS_BACK="${DIRS_WORK}/back"					# backup
	declare -r    DIRS_CONF="${DIRS_WORK}/conf"					# configuration file
#	declare -r    DIRS_HTML="${DIRS_WORK}/html"					# html contents
#	declare -r    DIRS_IMGS="${DIRS_WORK}/imgs"					# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_WORK}/isos"					# iso file
	declare -r    DIRS_LIVE="${DIRS_WORK}/live"					# live media
#	declare -r    DIRS_ORIG="${DIRS_WORK}/orig"					# original file
#	declare -r    DIRS_RMAK="${DIRS_WORK}/rmak"					# remake file
	declare -r    DIRS_TEMP="${DIRS_WORK}/temp/${PROG_PROC}"	# temporary directory
#	declare -r    DIRS_TFTP="${DIRS_WORK}/tftp"					# tftp contents

# --- niceness values ---------------------------------------------------------
	declare -r -i NICE_VALU=19								# -20: favorable to the process
															#  19: least favorable to the process
	declare -r -i IONICE_CLAS=3								#   1: Realtime
															#   2: Best-effort
															#   3: Idle
#	declare -r -i IONICE_VALU=7								#   0: favorable to the process
															#   7: least favorable to the process

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
#	|  EOL  |  23.10   | Mantic Minotaur    |  2023-10-12  |  2024-07-xx  |              | 6.5.0          |               |
#	|       |  24.04   | Noble Numbat       |  2024-04-25  |  2029-05-31  |  2034-04-25  | 6.8.0          |               |
#	|       |  24.10   | Oracular Oriole    |  2024-10-10  |  2025-07-xx  |              | 6.8.0          |               |

# --- custom live image -------------------------------------------------------
# --- custom live image -------------------------------------------------------
	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    \
		"m  menu-entry                  Custom%20Live%20Media               -                   -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  live-debian-10-buster       Live%20Debian%2010                  debian              live-debian-10-buster-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-11-bullseye     Live%20Debian%2011                  debian              live-debian-11-bullseye-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-12-bookworm     Live%20Debian%2012                  debian              live-debian-12-bookworm-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-13-trixie       Live%20Debian%2013                  debian              live-debian-13-trixie-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-xx-unstable     Live%20Debian%20xx                  debian              live-debian-xx-unstable-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"x  live-ubuntu-14.04-trusty    Live%20Ubuntu%2014.04               ubuntu              live-ubuntu-14.04-trusty-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-16.04-xenial    Live%20Ubuntu%2016.04               ubuntu              live-ubuntu-16.04-xenial-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-18.04-bionic    Live%20Ubuntu%2018.04               ubuntu              live-ubuntu-18.04-bionic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-20.04-focal     Live%20Ubuntu%2020.04               ubuntu              live-ubuntu-20.04-focal-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-22.04-jammy     Live%20Ubuntu%2022.04               ubuntu              live-ubuntu-22.04-jammy-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.04-lunar     Live%20Ubuntu%2023.04               ubuntu              live-ubuntu-23.04-lunar-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.10-mantic    Live%20Ubuntu%2023.10               ubuntu              live-ubuntu-23.10-mantic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2023-10-12  2024-07-11  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.04-noble     Live%20Ubuntu%2024.04               ubuntu              live-ubuntu-24.04-noble-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.10-oracular  Live%20Ubuntu%2024.10               ubuntu              live-ubuntu-24.10-oracular-amd64.iso            live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-xx.xx-devel     Live%20Ubuntu%20xx.xx               ubuntu              live-ubuntu-xx.xx-devel-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${DIRS_LIVE}                     20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"m  menu-entry                  -                                   -                   -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                   3                   4                                               5                                       6                           7                       8                                       9                                10          11          12          13  14  15  16

	declare -r    OLD_IFS="${IFS}"
	declare -i    start_time=0
	declare -i    end_time=0
	declare -i    section_start_time=0
	declare -a    COMD_LINE=("${PROG_PARM[@]}")
	declare -a    DIRS_LIST=()
	declare       DIRS_NAME=""
	declare       PSID_NAME=""
	declare -a    TGET_LIST=("${DATA_LIST_CSTM[@]}")
	declare -a    TGET_LINE=()
	declare       FLAG_KEEP=""			# reusing a previously created filesystem.squashfs
	declare       FLAG_SIMU=""			# check selected packages (simulation only)
	declare       FLAG_CONT=""			# do not stop on errors
	declare       OPTN_CONF=""
	declare       OPTN_KEYS=""
	declare       OPTN_COMP=""
	declare       FILE_YAML=""
	declare       FILE_CONF=""
#	declare       DIRS_CONF=""
#	declare       DIRS_LIVE=""
#	declare       DIRS_TEMP=""
	declare       DIRS_CDFS=""
	declare       DIRS_MNTS=""
	declare       PATH_SRCS=""
	declare       PATH_DEST=""
	declare       FILE_NAME=""
	declare       SQFS_NAME=""
	declare       WORK_STRS=""
#	declare -a    PARM=()
	declare -i    I=0
	declare -r    BOOT_OPTN="live components quiet splash overlay-size=90% hooks=medium xorg-resolution=1680x1050 utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A"

	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

#	echo -e "\033[m\033[42m--- start ---\033[m"
	printf "\033[m\033[42m%s\033[m\n" "--- start ---"
	start_time=$(date +%s)
	date +"%Y/%m/%d %H:%M:%S"

	# -------------------------------------------------------------------------
	renice -n "${NICE_VALU}"   -p "$$" > /dev/null
	ionice -c "${IONICE_CLAS}" -p "$$"
	# -------------------------------------------------------------------------
	DIRS_LIST=()
	for DIRS_NAME in "${DIRS_TEMP%.*}."*
	do
		if [[ ! -d "${DIRS_NAME}/." ]]; then
			continue
		fi
		PSID_NAME="$(ps --pid "${DIRS_NAME##*.}" --format comm= || true)"
		if [[ -z "${PSID_NAME:-}" ]]; then
			DIRS_LIST+=("${DIRS_NAME}")
		fi
	done
	if [[ "${#DIRS_LIST[@]}" -gt 0 ]]; then
		echo "remove unnecessary temporary directories"
		rm -rf "${DIRS_LIST[@]}"
	fi
	# -------------------------------------------------------------------------

#	rm -rf ${DIRS_LIVE:?}
#	mkdir -p ${DIRS_LIVE:?}

	if [[ -z "${PROG_PARM[*]}" ]]; then
		echo "sudo ./${PROG_NAME} [ options ] suites"
		echo "options"
#		echo "  reusing a previously created filesystem.squashfs"
#		echo "    -k | --keep"
		echo "  check selected packages (simulation only)"
		echo "    -s | --simu"
		echo "  do not stop on errors"
		echo "    -c | --continue"
		echo "suites"
		echo "  create a full suite or debian or ubuntu"
		echo "    -a | --all | debian | ubuntu"
		echo "  create one or more suites"
		WORK_STRS=""
		for ((I=0; I<"${#TGET_LIST[@]}"; I++))
		do
			read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
			if [[ "${TGET_LINE[0]}" != "o" ]]; then
				continue
			fi
			WORK_STRS+="${WORK_STRS:+" | "}${TGET_LINE[1]##*-}"
		done
		echo "    choose any suite"
		echo "      [ ${WORK_STRS:?} ]"
	else
		for ((I=0; I<"${#TGET_LIST[@]}"; I++))
		do
			read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
			if [[ "${TGET_LINE[0]}" != "o" ]]; then
				continue
			fi
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
				-f | --force )
					FLAG_KEEP="force"
					shift
					COMD_LINE=("${@:-}")
					;;
				-s | --simu )
					FLAG_SIMU="--simulate"
					shift
					COMD_LINE=("${@:-}")
					;;
				-c | --continue )
					FLAG_CONT="true"
					shift
					COMD_LINE=("${@:-}")
					;;
				-a | --all )
					for ((I=0; I<"${#TGET_LIST[@]}"; I++))
					do
						read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
						if [[ "${TGET_LINE[0]}" != "-" ]]; then
							continue
						fi
						TGET_LINE[0]="o"
						TGET_LIST[I]="${TGET_LINE[*]}"
					done
					shift
					COMD_LINE=("${@:-}")
					;;
				debian | \
				ubuntu )
					for ((I=0; I<"${#TGET_LIST[@]}"; I++))
					do
						read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
						if [[ "${TGET_LINE[0]}" != "-" ]] || [[ "${TGET_LINE[3]}" != "$1" ]]; then
							continue
						fi
						TGET_LINE[0]="o"
						TGET_LIST[I]="${TGET_LINE[*]}"
					done
					shift
					COMD_LINE=("${@:-}")
					;;
				* )
					for ((I=0; I<"${#TGET_LIST[@]}"; I++))
					do
						read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
						if [[ "${TGET_LINE[0]}" != "-" ]] || [[ "${TGET_LINE[1]##*-}" != "$1" ]]; then
							continue
						fi
						TGET_LINE[0]="o"
						TGET_LIST[I]="${TGET_LINE[*]}"
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

		if [[ -d "${DIRS_WORK}/keys/." ]]; then
			OPTN_KEYS="--keyring=${DIRS_WORK}/keys"
		fi

		for ((I=0; I<"${#TGET_LIST[@]}"; I++))
		do
			section_start_time=$(date +%s)
			read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
			if [[ "${TGET_LINE[0]}" != "o" ]]; then
				continue
			fi
			TGET_ARCH="${TGET_LINE[4]/.iso/}"
			TGET_ARCH="${TGET_ARCH##*-}"
#			echo -e "\033[m\033[45m${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]\033[m"
			printf "\033[m\033[45m%s %s\033[m\n" "${TGET_LINE[2]//%20/ }" "[${TGET_LINE[1]##*-}] ${TGET_ARCH}"
#			DIRS_CONF="${DIRS_WORK}/conf"
			DIRS_TGET="${DIRS_LIVE}/${TGET_LINE[4]/.iso/}"
			DIRS_CDFS="${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/cdfs"
			DIRS_MNTS="${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/mnts"
			SQFS_NAME="${TGET_LINE[4]/.iso/}.squashfs"
#			SQFS_NAME="filesystem.squashfs"
			FILE_YAML="${DIRS_CONF}/_template/live_${TGET_LINE[3]}.yaml"
			FILE_CONF="${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/${FILE_YAML##*/}"
			# --- create cd/dvd image [ create squashfs file ] ----------------
			if [[ "${FLAG_KEEP}" != "true" ]] \
			|| [[ ! -e "${DIRS_TGET}/${SQFS_NAME}" ]] \
			|| [[ ! -e "${DIRS_TGET}/manifest" ]] \
			|| [[ "${FILE_YAML}" -nt "${DIRS_TGET}/${SQFS_NAME}" ]]; then
#			|| [[ "${PROG_PATH}" -nt "${DIRS_TGET}/${SQFS_NAME}" ]]; then
				rm -rf "${DIRS_TGET:?}"
				mkdir -p "${DIRS_TGET:?}" \
				         "${DIRS_MNTS}"   \
				         "${DIRS_CDFS}/"{.disk,EFI/boot,boot/grub/{live-theme,x86_64-efi},isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
				# -------------------------------------------------------------
				OPTN_COMP=""
#				case "${TGET_LINE[4]/.iso/}" in
#					live-debian-10-buster      | \
#					live-debian-11-bullseye    ) OPTN_COMP="--components=main,contrib,non-free";;
#					live-debian-*              ) OPTN_COMP="--components=main,contrib,non-free,non-free-firmware";;
#					live-ubuntu-*              ) OPTN_COMP="--components=main,multiverse,restricted,universe";;
#					*                          ) OPTN_COMP="";;
#				esac
				# -------------------------------------------------------------
				OPTN_CONF="--config ${FILE_CONF}"
				cp -a "${FILE_YAML}" "${FILE_CONF}"
				case "${TGET_LINE[4]/.iso/}" in
					live-debian-11-*    )
						sed -e '/^ *components:/,/^ *- */ {'                                                      \
						    -e 's/ *non-free-firmware//g}'                                                        \
						    -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
							-e '/^ * *- *cron-daemon-common\(\| .*\|#.*\)$/                             s/^ /#/g' \
							-e '/^ * *- *fcitx5-frontend-[[:graph:]]\+\(\| .*\|#.*\)$/                  s/^ /#/g' \
							-e '/^ * *- *firmware-realtek-rtl8723cs-bt\(\| .*\|#.*\)$/                  s/^ /#/g' \
							-e '/^ * *- *gnome-browser-connector\(\| .*\|#.*\)$/                        s/^ /#/g' \
							-e '/^ * *- *gnome-shell-extension-desktop-icons-ng\(\| .*\|#.*\)$/         s/^ /#/g' \
							-e '/^ * *- *gstreamer1.0-libcamera\(\| .*\|#.*\)$/                         s/^ /#/g' \
							-e '/^ * *- *pipewire-alsa\(\| .*\|#.*\)$/                                  s/^ /#/g' \
							-e '/^ * *- *pipewire-audio\(\| .*\|#.*\)$/                                 s/^ /#/g' \
							-e '/^ * *- *pipewire-libcamera\(\| .*\|#.*\)$/                             s/^ /#/g' \
							-e '/^ * *- *pipewire-pulse\(\| .*\|#.*\)$/                                 s/^ /#/g' \
							-e '/^ * *- *plymouth-theme-mobian\(\| .*\|#.*\)$/                          s/^ /#/g' \
							-e '/^ * *- *polkitd-pkla\(\| .*\|#.*\)$/                                   s/^ /#/g' \
							-e '/^ * *- *python3-charset-normalizer\(\| .*\|#.*\)$/                     s/^ /#/g' \
							-e '/^ * *- *python3-markdown-it\(\| .*\|#.*\)$/                            s/^ /#/g' \
							-e '/^ * *- *python3-mdurl\(\| .*\|#.*\)$/                                  s/^ /#/g' \
							-e '/^ * *- *python3-rfc3987\(\| .*\|#.*\)$/                                s/^ /#/g' \
							-e '/^ * *- *samba-ad-provision\(\| .*\|#.*\)$/                             s/^ /#/g' \
							-e '/^ * *- *systemd-resolved\(\| .*\|#.*\)$/                               s/^ /#/g' \
							-e '/^ * *- *usr-is-merged\(\| .*\|#.*\)$/                                  s/^ /#/g' \
							-e '/^ * *- *wireplumber\(\| .*\|#.*\)$/                                    s/^ /#/g' \
						    -e '/^# * *- *fcitx5-frontend-gtk[2-3]\(\| .*\|#.*\)$/                      s/^#/ /g' \
						    -e '/^# * *- *fcitx5-frontend-qt5\(\| .*\|#.*\)$/                           s/^#/ /g' \
						    -e '/^# * *- *pulseaudio.*\(\| .*\|#.*\)$/                                  s/^#/ /g' \
						    -e '/^# * *- *resolvconf\(\| .*\|#.*\)$/                                    s/^#/ /g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					live-debian-12-*    )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
						    -e '/^ * *- *fcitx5-frontend-[[:graph:]]\+\(\| .*\|#.*\)$/                  s/^ /#/g' \
						    -e '/^# * *- *fcitx5-frontend-gtk[2-4]\(\| .*\|#.*\)$/                      s/^#/ /g' \
						    -e '/^# * *- *fcitx5-frontend-qt[5-6]\(\| .*\|#.*\)$/                       s/^#/ /g' \
						    -e '/^# * *- *fcitx5-frontend-fbterm\(\| .*\|#.*\)$/                        s/^#/ /g' \
						    -e '/^# * *- *fcitx5-frontend-tmux\(\| .*\|#.*\)$/                          s/^#/ /g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					live-debian-13-*    )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
						    -e '/^ * *- *bdebstrap\(\| .*\|#.*\)$/                                      s/^ /#/g' \
						    -e '/^ * *- *fbterm\(\| .*\|#.*\)$/                                         s/^ /#/g' \
						    -e '/^ * *- *httpfs2\(\| .*\|#.*\)$/                                        s/^ /#/g' \
						    -e '/^ * *- *mime-support\(\| .*\|#.*\)$/                                   s/^ /#/g' \
						    -e '/^ * *- *ofono\(\| .*\|#.*\)$/                                          s/^ /#/g' \
						    -e '/^ * *- *polkitd-pkla\(\| .*\|#.*\)$/                                   s/^ /#/g' \
						    -e '/^ * *- *python3-pysimplesoap\(\| .*\|#.*\)$/                           s/^ /#/g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					live-debian-xx-*    )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
						    -e '/^ * *- *httpfs2\(\| .*\|#.*\)$/                                        s/^ /#/g' \
						    -e '/^ * *- *mime-support\(\| .*\|#.*\)$/                                   s/^ /#/g' \
						    -e '/^ * *- *polkitd-pkla\(\| .*\|#.*\)$/                                   s/^ /#/g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					live-ubuntu-22.04-*    )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
						    -e '/^ * *- *cron-daemon-common\(\| .*\|#.*\)$/                             s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-[[:graph:]]\+\(\| .*\|#.*\)$/                  s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-fbterm\(\| .*\|#.*\)$/                         s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-qt6\(\| .*\|#.*\)$/                            s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-tmux\(\| .*\|#.*\)$/                           s/^ /#/g' \
						    -e '/^ * *- *firmware-realtek-rtl8723cs-bt\(\| .*\|#.*\)$/                  s/^ /#/g' \
						    -e '/^ * *- *fonts-liberation-sans-narrow\(\| .*\|#.*\)$/                   s/^ /#/g' \
						    -e '/^ * *- *gnome-browser-connector\(\| .*\|#.*\)$/                        s/^ /#/g' \
						    -e '/^ * *- *gnome-shell-extension-ubuntu-tiling-assistant\(\| .*\|#.*\)$/  s/^ /#/g' \
						    -e '/^ * *- *gstreamer1.0-libcamera\(\| .*\|#.*\)$/                         s/^ /#/g' \
						    -e '/^ * *- *libgpgme11t64\(\| .*\|#.*\)$/                                  s/^ /#/g' \
							-e '/^ * *- *pipewire-alsa\(\| .*\|#.*\)$/                                  s/^ /#/g' \
							-e '/^ * *- *pipewire-audio\(\| .*\|#.*\)$/                                 s/^ /#/g' \
							-e '/^ * *- *pipewire-libcamera\(\| .*\|#.*\)$/                             s/^ /#/g' \
							-e '/^ * *- *pipewire-pulse\(\| .*\|#.*\)$/                                 s/^ /#/g' \
						    -e '/^ * *- *python3-mdurl\(\| .*\|#.*\)$/                                  s/^ /#/g' \
						    -e '/^ * *- *python3-rfc3987\(\| .*\|#.*\)$/                                s/^ /#/g' \
						    -e '/^ * *- *samba-ad-provision\(\| .*\|#.*\)$/                             s/^ /#/g' \
						    -e '/^ * *- *systemd-resolved\(\| .*\|#.*\)$/                               s/^ /#/g' \
						    -e '/^ * *- *ubuntu-kernel-accessories\(\| .*\|#.*\)$/                      s/^ /#/g' \
							-e '/^ * *- *wireplumber\(\| .*\|#.*\)$/                                    s/^ /#/g' \
						    -e '/^# * *- *fcitx5-frontend-gtk[2-4]\(\| .*\|#.*\)$/                      s/^#/ /g' \
						    -e '/^# * *- *fcitx5-frontend-qt5\(\| .*\|#.*\)$/                           s/^#/ /g' \
						    -e '/^# * *- *pulseaudio.*\(\| .*\|#.*\)$/                                  s/^#/ /g' \
						    -e '/^# * *- *resolvconf\(\| .*\|#.*\)$/                                    s/^#/ /g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					live-debian-*       | \
					live-ubuntu-*       )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                                            \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                                        \
						    -e '/^ * *- *httpfs2\(\| .*\|#.*\)$/                                        s/^ /#/g' \
						    -e '}}'                                                                               \
						    "${FILE_YAML}"                                                                        \
						> "${FILE_CONF}"
						;;
					*                   ) OPTN_CONF="";;
				esac
				# -------------------------------------------------------------
				cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/customize-hooks.sh"
					#!/bin/sh
					
					#	set -n								# Check for syntax errors
					#	set -x								# Show command and argument expansion
					#	set -o ignoreeof					# Do not exit with Ctrl+D
					#	set +m								# Disable job control
					 	set -e								# End with status other than 0
					 	set -u								# End with undefined variable reference
					#	set -o pipefail						# End with in pipe error
					
					 	trap 'exit 1' HUP INT QUIT TERM
					
					 	readonly    PROG_PATH="$0"
					#	readonly -a PROG_PARM=("${@:-}")
					#	readonly    PROG_DIRS="${PROG_PATH%/*}"
					#	readonly    PROG_NAME="${PROG_PATH##*/}"
					#	readonly    PROG_PROC="${PROG_NAME}.$$"
					#	readonly    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
					#	readonly    DIRS_WORK="${PWD}/share"
					
					# --- start -------------------------------------------------------------------
					 	printf "\033[m\033[45mstart: %s\033[m\n" "${PROG_PATH}"
					 	_DISTRIBUTION="$(lsb_release -is | tr '[:upper:]' '[:lower:]' | sed -e 's| |-|g')"
					 	_RELEASE="$(lsb_release -rs | tr '[:upper:]' '[:lower:]')"
					 	_CODENAME="$(lsb_release -cs | tr '[:upper:]' '[:lower:]')"
					 	printf "\033[m\033[93m%s\033[m\n" "setup: ${_DISTRIBUTION:-} ${_RELEASE:-} ${_CODENAME:-}"
					
					# --- function systemctl ------------------------------------------------------
					funcSystemctl () {
					 	_OPTIONS="$1"
					 	_COMMAND="$2"
					 	_UNITS="$3"
					 	_PARM="$(echo "${_UNITS}" | sed -e 's/ /|/g')"
					 	# shellcheck disable=SC2086
					 	_RETURN_VALUE="$(systemctl ${_OPTIONS} list-unit-files ${_UNITS} | awk '$0~/'"${_PARM}"'/ {print $1;}')"
					 	if [ -n "${_RETURN_VALUE:-}" ]; then
					 		# shellcheck disable=SC2086
					 		systemctl ${_OPTIONS} "${_COMMAND}" ${_RETURN_VALUE}
					 	fi
					}
					
					# --- function is package -----------------------------------------------------
					funcIsPackage () {
					 	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
					}
					
					# --- setup root password -----------------------------------------------------
					 	printf "\033[m\033[42m%s\033[m\n" "setup root password: no password"
					#	_RETURN_VALUE="$(echo 'password' | openssl passwd -6 -stdin)"
					#	usermod --password "${_RETURN_VALUE}" root
					 	passwd --delete root
					
					# --- setup ssh login ---------------------------------------------------------
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'openssh-server'); then
					 		printf "\033[m\033[42m%s\033[m\n" "setup ssh login: permit root login without a password"
					 		_FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 			PasswordAuthentication no
					 			PermitRootLogin yes
					_EOT_
					 	fi
					
					# --- set network parameter ---------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'network-manager') \
					#	&& $(funcIsPackage 'netplan.io'     ); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup network parameter: nmcli with netplan"
					#		_FILE_PATH="/etc/netplan/99-network-manager-all.yaml"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			network:
					#			  version: 2
					#			  renderer: NetworkManager
					#_EOT_
					#		chmod 600 "${_FILE_PATH}"
					#		# ---------------------------------------------------------------------
					#		_FILE_PATH="/etc/netplan/99-network-config-all.yaml"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		: > "${_FILE_PATH}"
					#		for _NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
					#		do
					#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
					#				network:
					#				  version: 2
					#				  renderer: networkd
					#				  ethernets:
					#				    ${_NICS_NAME}
					#				      dhcp4: true
					#				      dhcp6: true
					#				      ipv6-privacy: true
					#_EOT_
					#		done
					#		chmod 600 "${_FILE_PATH}"
					#	fi
					
					# --- set bluetooth -----------------------------------------------------------
					# https://askubuntu.com/questions/1306723/bluetooth-service-fails-and-freezes-after-some-time-in-ubuntu-18-04
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'rfkill'   ) \
					#	&& $(funcIsPackage 'bluetooth'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup bluetooth parameter"
					#		rfkill unblock bluetooth || true
					#	fi
					#
					# --- setup systemd-resolved.service ------------------------------------------
					 	if [ -e /etc/systemd/resolved.conf ] \
					 	&& [ -e /etc/dnsmasq.conf          ]; then
					 		printf "\033[m\033[42m%s\033[m\n" "setup systemd-resolved.service"
					 		_FILE_PATH="/etc/systemd/resolved.conf.d/resolved.conf"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 			[Resolve]
					 			DNS=127.0.0.1
					_EOT_
					 		_FILE_PATH="/etc/dnsmasq.d/dnsmasq.conf"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 			no-poll                                 # don't poll /etc/resolv.conf for changes
					 			no-resolv                               # don't read /etc/resolv.conf
					 			listen-address=::1,127.0.0.1            # listen to ip address
					 			server=8.8.8.8                          # directly specify upstream server
					 			server=8.8.4.4                          # directly specify upstream server
					 			no-dhcp-interface=                      # disable DHCP service
					 			bind-interfaces                         # enable bind-interfaces
					_EOT_
					 	fi
					
					# --- setup systemd-timesyncd.service -----------------------------------------
					 	# timedatectl show-timesync --all
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'systemd-timesyncd'); then
					 		printf "\033[m\033[42m%s\033[m\n" "setup systemd-timesyncd.service"
					 		_FILE_PATH="/etc/systemd/timesyncd.conf.d/local.conf"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 			[Time]
					 			NTP=ntp.nict.jp
					 			FallbackNTP=ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp
					 			PollIntervalMinSec=1h
					 			PollIntervalMaxSec=1d
					 			SaveIntervalSec=infinity
					_EOT_
					 	fi
					
					# --- setup connman -----------------------------------------------------------
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'connman'); then
					 		printf "\033[m\033[42m%s\033[m\n" "setup connman"
					 		if _RETURN_VALUE="$(command -v connmand 2> /dev/null)"; then
					 			_FILE_PATH="/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
					 			mkdir -p "${_FILE_PATH%/*}"
					 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 				[Service]
					 				ExecStart=
					 				ExecStart=${_RETURN_VALUE:?} -n --nodnsproxy
					_EOT_
					 		fi
					 		_FILE_PATH="/etc/connman/main.conf"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		sed -i "${_FILE_PATH}"                                                                 \
					 		    -e '/^AllowHostnameUpdates[ \t]*=/      s/^/#/'                                    \
					 		    -e '/^PreferredTechnologies[ \t]*=/     s/^/#/'                                    \
					 		    -e '/^SingleConnectedTechnology[ \t]*=/ s/^/#/'                                    \
					 		    -e '/^EnableOnlineCheck[ \t]*=/         s/^/#/'                                    \
					 		    -e '/^NetworkInterfaceBlacklist*=/      s/^/#/'                                    \
					 		    -e '/^#[ \t]*AllowHostnameUpdates[ \t]*=/a AllowHostnameUpdates = false'           \
					 		    -e '/^#[ \t]*PreferredTechnologies[ \t]*=/a PreferredTechnologies = ethernet,wifi' \
					 		    -e '/^#[ \t]*SingleConnectedTechnology[ \t]*=/a SingleConnectedTechnology = true'  \
					 		    -e '/^#[ \t]*EnableOnlineCheck[ \t]*=/a EnableOnlineCheck = false'
					 	fi
					
					# --- setup fcitx5 ------------------------------------------------------------
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'fcitx5'); then
					 		printf "\033[m\033[42m%s\033[m\n" "setup fcitx5"
					 		_FILE_PATH="/etc/default/im-config"
					 		sed -i "${_FILE_PATH}"                                        \
					 		    -e '/^IM_CONFIG_DEFAULT_MODE=/   s/=.*$/=fcitx5/'         \
					 		    -e '/^CJKV_LOCALES=/             s/=.*$/="ja_JP"/'        \
					 		    -e '/^IM_CONFIG_PREFERRED_RULE=/ s/=.*$/="ja_JP,fcitx5"/'
					 	fi
					
					# --- setup samba -------------------------------------------------------------
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'samba'); then
					 		printf "\033[m\033[42m%s\033[m\n" "setup samba"
					 		_FILE_PATH="/etc/nsswitch.conf"
					 		sed -i "${_FILE_PATH}"       \
					 		    -e '/hosts:/{'           \
					 		    -e '/wins/! s/$/ wins/}'
					 	fi
					
					# --- setup lightdm -----------------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'lightdm'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup lightdm"
					#		dpkg-reconfigure --no-reload lightdm
					#	fi
					
					# --- setup wireplumber -------------------------------------------------------
					 	# shellcheck disable=SC2091,SC2310
					 	if $(funcIsPackage 'wireplumber'); then
					 		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
					 		printf "\033[m\033[42m%s\033[m\n" "setup wireplumber"
					 		mkdir -p "${_FILE_PATH%/*}"
					 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					 			monitor.alsa.rules = [
					 			  {
					 			    matches = [
					 			      # This matches the value of the 'node.name' property of the node.
					 			      {
					 			        node.name = "~alsa_output.*"
					 			      }
					 			    ]
					 			    actions = {
					 			      # Apply all the desired node specific settings here.
					 			      update-props = {
					 			        api.alsa.period-size   = 1024
					 			        api.alsa.headroom      = 8192
					 			        session.suspend-timeout-seconds = 0
					 			      }
					 			    }
					 			  }
					 			]
					 _EOT_
					 
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/51-alsa-pro-audio.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			monitor.alsa.rules = [
					#			  {
					#			    matches = [
					#			      {
					#			        device.name = "~alsa_card.*"
					#			      }
					#			    ]
					#			    actions = {
					#			      update-props = {
					#			        api.alsa.use-acp = false,
					#			        device.profile = "pro-audio"
					#			        api.acp.auto-profile = false
					#			        api.acp.auto-port = false
					#			      }
					#			    }
					#			  }
					#			]
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/51-headphones.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			monitor.bluez.rules = [
					#			  {
					#			    matches = [
					#			      {
					#			        node.name = "bluez_output.02_11_45_A0_B3_27.a2dp-sink"
					#			      }
					#			    ]
					#			    actions = {
					#			      update-props = {
					#			        node.nick = "Headphones"
					#			      }
					#			    }
					#			  }
					#			]
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/80-bluez-properties.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			 onitor.bluez.properties = {
					#			  bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hsp_hs hsp_ag hfp_hf hfp_ag ]
					#			  bluez5.hfphsp-backend = "native"
					#			}
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/80-disable-alsa-reserve.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			wireplumber.profiles = {
					#			  main = {
					#			    monitor.alsa.reserve-device = disabled
					#			  }
					#			}
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/80-disable-logind.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			wireplumber.profiles = {
					#			  main = {
					#			    monitor.bluez.seat-monitoring = disabled
					#			  }
					#			}
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/80-policy.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			wireplumber.settings = {
					#			  linking.allow-moving-streams = false
					#			  linking.follow-default-target = false
					#			}
					#_EOT_
					#		_FILE_PATH="/etc/wireplumber/wireplumber.conf.d/99-my-script.conf.sample"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			wireplumber.components = [
					#			  {
					#			    name = my-script.lua, type = script/lua
					#			    provides = custom.my-script
					#			  }
					#			]
					#
					#			wireplumber.profiles = {
					#			  main = {
					#			    custom.my-script = required
					#			  }
					#			}
					#_EOT_
					 	fi
					
					# --- setup pipewire ----------------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'pipewire'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup pipewire"
					#		# --- debian 11 -------------------------------------------------------
					#		# https://wiki.debian.org/PipeWire
					#		if [ "${_DISTRIBUTION:-}" = "debian" ] && [ "${_RELEASE:-}" = "11" ]; then
					#			# --- PulseAudio --------------------------------------------------
					#			_FILE_PATH="/etc/pipewire/media-session.d/with-pulseaudio"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			touch "${_FILE_PATH}"
					#			cp -a /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
					#			# --- ALSA --------------------------------------------------------
					#			_FILE_PATH="/etc/pipewire/media-session.d/with-alsa"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			touch "${_FILE_PATH}"
					#			cp -a /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
					#			# --- JACK --------------------------------------------------------
					#			_FILE_PATH="/etc/pipewire/media-session.d/with-alsa"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			touch "${_FILE_PATH}"
					#			sudo cp -a /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-*.conf /etc/ld.so.conf.d/
					#			# --- Bluetooth ---------------------------------------------------
					#			_FILE_PATH="/etc/pipewire/media-session.d/bluez-monitor.conf"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			touch "${_FILE_PATH}"
					#			# --- service -----------------------------------------------------
					#			systemctl --global daemon-reload || true
					#			systemctl --global disable pulseaudio || true
					#			systemctl --global mask    pulseaudio || true
					#			systemctl --global unmask  pipewire pipewire-pulse || true
					#			systemctl --global enable  pipewire pipewire-pulse || true
					#			ldconfig
					#			# --- config ------------------------------------------------------
					#			_FILE_PATH="/etc/pipewire/pipewire.conf.d/pipewire.conf"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#				properties = {
					#				    ## Properties for the DSP configuration
					#				    default.clock.rate =                48000
					#				    default.clock.quantum =             2048
					#				    default.clock.min-quantum =         2048
					#				    #default.clock.max-quantum =        8192
					#				    #default.video.width =              640
					#				    #default.video.height =             480
					#				    #default.video.rate.num =           25
					#				    #default.video.rate.denom =         1
					#				}
					#_EOT_
					#		else
					#			_FILE_PATH="/etc/pipewire/pipewire.conf.d/pipewire.conf"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#				context.properties = {
					#				    ## Properties for the DSP configuration.
					#				    default.clock.rate          = 48000
					#				    default.clock.allowed-rates = [ 384000 192000 96000 48000 44100 ]
					#				    default.clock.quantum       = 2048
					#				    default.clock.min-quantum   = 2048
					#				    # These overrides are only applied when running in a vm.
					#				    vm.overrides = {
					#				        default.clock.min-quantum = 2048
					#				    }
					#				}
					#				
					#				context.modules = [
					#				    { name = libpipewire-module-rt
					#				        args = {
					#				            nice.level    = -15
					#				            #rt.prio      = 88
					#				            #rt.time.soft = -1
					#				            #rt.time.hard = -1
					#				        }
					#				        flags = [ ifexists nofail ]
					#				    }
					#				]
					#_EOT_
					#			_FILE_PATH="/etc/pipewire/pipewire-pulse.conf.d/pipewire-pulse.conf"
					#			mkdir -p "${_FILE_PATH%/*}"
					#			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#				context.modules = [
					#				    { name = libpipewire-module-rt
					#				        args = {
					#				            nice.level   = -15
					#				            #rt.prio      = 88
					#				            #rt.time.soft = -1
					#				            #rt.time.hard = -1
					#				        }
					#				        flags = [ ifexists nofail ]
					#				    }
					#				]
					#				
					#				pulse.cmd = [
					#				    { cmd = "load-module" args = "module-always-sink" flags = [ ] }
					#				    { cmd = "load-module" args = "module-switch-on-connect" }
					#				    #{ cmd = "load-module" args = "module-gsettings" flags = [ "nofail" ] }
					#				]
					#_EOT_
					#		fi
					#	fi
					
					# --- setup pulseaudio --------------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'pulseaudio'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup pulseaudio"
					#		if id pulse > /dev/null 2>&1; then
					#			usermod -aG lp pulse
					#		fi
					#
					#		_FILE_PATH="/etc/pulse/default.pa.d/unload_driver_modules_for_bluetooth"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			### unload driver modules for Bluetooth hardware
					#			.ifexists module-bluetooth-policy.so
					#			  unload-module module-bluetooth-policy
					#			.endif
					#			
					#			.ifexists module-bluetooth-discover.so
					#			  unload-module module-bluetooth-discover
					#			.endif
					#_EOT_
					#		# --- service ---------------------------------------------------------
					#		systemctl --global daemon-reload || true
					#		systemctl --global disable pipewire pipewire-pulse || true
					#		systemctl --global mask    pipewire pipewire-pulse || true
					#		systemctl --global unmask  pulseaudio || true
					#		systemctl --global enable  pulseaudio || true
					#		ldconfig
					#	fi
					
					# --- setup bluetooth ---------------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'bluetooth'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup bluetooth"
					#		_FILE_PATH="/etc/bluetooth/audio.conf"
					#		mkdir -p "${_FILE_PATH%/*}"
					#		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
					#			[General]
					#			Enable=Source,Sink,Media,Socket
					#_EOT_
					#	fi
					
					# --- install snap packages ---------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'snap'); then
					#		printf "\033[m\033[42m%s\033[m\n" "install snap packages"
					#		snap install firefox chromium
					#	fi
					
					# --- setup firewall ----------------------------------------------------------
					#	# shellcheck disable=SC2091,SC2310
					#	if $(funcIsPackage 'firewalld'); then
					#		printf "\033[m\033[42m%s\033[m\n" "setup firewall"
					#		firewall-cmd --permanent --change-interface=ens160 --zone=home
					#	fi
					
					# --- setup systemctl ---------------------------------------------------------
					 	printf "\033[m\033[42m%s\033[m\n" "setup systemctl"
					#	funcSystemctl "--global" "mask"    "wireplumber.service"
					#	funcSystemctl "--system" "mask"    "avahi-daemon.service avahi-daemon.socket"
					 	funcSystemctl "--system" "disable" "firewalld.service clamav-freshclam.service tftpd-hpa.service apache2.service"
					 	funcSystemctl "--system" "enable"  "ssh.service dnsmasq.service smbd.service nmbd.service"
					
					# --- exit --------------------------------------------------------------------
					 	printf "\033[m\033[45mcomplete: %s\033[m\n" "${PROG_PATH}"
					 	exit 0
					
					# --- eof ---------------------------------------------------------------------
_EOT_SH_
				if LANG=C apt list 'shellcheck' 2> /dev/null | grep -q 'installed'; then
					if ! shellcheck -o all "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/customize-hooks.sh" > /dev/null 2>&1; then
						printf "\033[m\033[41mfail: %s\033[m" "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/customize-hooks.sh"
						shellcheck -o all "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/customize-hooks.sh"
						exit 1
					fi
				fi
				# -------------------------------------------------------------
				# shellcheck disable=SC2086,SC2090,SC2248
				ionice -c "${IONICE_CLAS}" bdebstrap \
				    ${OPTN_CONF:-} \
				    --name "${TGET_LINE[4]/.iso/}" \
				    ${FLAG_SIMU:-} \
				    --output-base-dir "${DIRS_LIVE}" \
				    ${OPTN_KEYS:-} \
				    ${OPTN_COMP:-} \
				    --architectures ${TGET_ARCH} \
				    --customize-hook "cp -a \"${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/customize-hooks.sh\" \"\$1\"" \
				    --customize-hook "chmod +x \"\$1/customize-hooks.sh\"" \
				    --customize-hook "chroot \"\$1\" \"/customize-hooks.sh\"" \
				    --customize-hook "rm -f \"\$1/customize-hooks.sh\"" \
				    --suite "${TGET_LINE[1]##*-}" \
				    --target "${SQFS_NAME}" \
				    || if [[ -n "${FLAG_CONT:-}" ]]; then continue; else exit 1; fi
				if [[ -e "${FILE_CONF}" ]]; then
					cp -a "${FILE_CONF}" "${DIRS_TGET}"
					chmod 644 "${DIRS_TGET}/${FILE_CONF##*/}"
				fi
				if [[ -n "${FLAG_SIMU:-}" ]]; then
					continue
				fi
			fi
			# ---- copy script ------------------------------------------------
			mkdir -p "${DIRS_MNTS}"   \
			         "${DIRS_CDFS}/"{.disk,EFI/boot,boot/grub/{live-theme,x86_64-efi},isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
			for PATH_SRCS in "${DIRS_CONF}/script/"live_*.{sh,conf}
			do
				FILE_NAME="${PATH_SRCS##*live_}"
				case "${PATH_SRCS##*live_}" in
					????-user-boot*     ) PATH_DEST="${DIRS_CDFS}/live/boot/${FILE_NAME}";;
					????-user-conf*.conf) PATH_DEST="${DIRS_CDFS}/live/config.conf.d/${FILE_NAME}";;
					????-user-conf*.sh  ) PATH_DEST="${DIRS_CDFS}/live/config-hooks/${FILE_NAME}";;
					*) continue;;
				esac
				echo "${PATH_SRCS} -> ${PATH_DEST}"
				cp -a "${PATH_SRCS}" "${PATH_DEST}"
				chmod 555 "${PATH_DEST}"
			done
			# ---- create .disk/info ------------------------------------------
			: > "${DIRS_CDFS}/.disk/info"
			# ---- copy filesystem --------------------------------------------
			                           cp -a "${DIRS_TGET}/manifest"     "${DIRS_CDFS}/live/filesystem.packages"
			ionice -c "${IONICE_CLAS}" cp -a "${DIRS_TGET}/${SQFS_NAME}" "${DIRS_CDFS}/live/filesystem.squashfs"
			# ---- copy vmlinuz/initrd ----------------------------------------
			mount -r -t squashfs "${DIRS_CDFS}/live/filesystem.squashfs" "${DIRS_MNTS}"
			case "${TGET_LINE[3]}" in
				debian )
					cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-amd64    "${DIRS_CDFS}/live/vmlinuz"
					cp -a "${DIRS_MNTS}/boot/"initrd.img-*-amd64 "${DIRS_CDFS}/live/initrd.img"
					;;
				ubuntu )
					cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-generic    "${DIRS_CDFS}/live/vmlinuz"
					cp -a "${DIRS_MNTS}/boot/"initrd.img-*-generic "${DIRS_CDFS}/live/initrd.img"
					;;
				* )
					break
					;;
			esac
			umount "${DIRS_MNTS}"
			# ---- create splash.png ------------------------------------------
			# 800x600x24 black
			# tar -cz splash.png | xxd -p
#			pushd "${DIRS_CDFS}/isolinux" > /dev/null
#				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -r -p | tar -xz
#					1f8b0800000000000003edceaf6ec2501887e10f080921298a1a54dddc72
#					3a4e391ad265ab61842cd92428101b251412e432472677035c01120f1781
#					d815cc4c6326389b2199188a3484f731df5ff14b864fdda47f391cf4e468
#					9455d3fab75a7feb95515a7c6d94d28109aa5551be1fd48c78ea7891f626
#					c9b83bf23c19c5f1f8bfbf43f713356b356f9c62a5685b27ba0ddb22394f
#					24fb58c8da8d5b762f44f26f5158bf9f7e7cad328e5daee7dbbbe79299a7
#					1a1b00cecbcb43eefb5d329be5faf3678cae9be1a2d1794d3b1600000000
#					0000000000000048d70e5c9338d500280000
#_EOT_
#			popd > /dev/null
			# ---- create isolinux --------------------------------------------
	#		wget --directory-prefix="${DIRS_CDFS}/isolinux" \
	#			"https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/boot-screens/splash.png"
			cp -a /usr/lib/syslinux/modules/bios/* "${DIRS_CDFS}/isolinux"
			cp -a /usr/lib/ISOLINUX/isolinux.bin   "${DIRS_CDFS}/isolinux"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/isolinux.cfg"
				include menu.cfg
				default vesamenu.c32
				prompt 0
				timeout 50
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/menu.cfg"
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
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/stdmenu.cfg"
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
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/live.cfg"
				label ${TGET_LINE[2]//%20/_}
				 	menu label ^${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]
				 	menu default
				 	linux /live/vmlinuz
				 	initrd /live/initrd.img
				 	append boot=${BOOT_OPTN}
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/install.cfg"
				#label installstart
				#	menu label Start ^installer
				#	linux /install/gtk/vmlinuz
				#	initrd /install/gtk/initrd.gz
				#	append vga=788  --- quiet
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/isolinux/utilities.cfg"
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
			cp -a /usr/lib/grub/x86_64-efi/*  "${DIRS_CDFS}/boot/grub/x86_64-efi"
			cp -a /usr/share/grub/unicode.pf2 "${DIRS_CDFS}/boot/grub"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_CDFS}/boot/grub/grub.cfg"
				set timeout=5
				set default=0
				set gfxmode=auto
				set lang=ja_JP
				
				if [ x\$feature_default_font_path = xy ] ; then
				   font=unicode
				else
				   font=\$prefix/font.pf2
				fi
				
				if loadfont \$font ; then
				  set gfxmode=1024x768
				  set gfxpayload=keep
				  insmod efi_gop
				  insmod efi_uga
				  insmod video_bochs
				  insmod video_cirrus
				  insmod gfxterm
				  insmod png
				  terminal_output gfxterm
				fi
				
				if background_image /isolinux/splash.png; then
				  set color_normal=light-gray/black
				  set color_highlight=white/black
				elif background_image /splash.png; then
				  set color_normal=light-gray/black
				  set color_highlight=white/black
				else
				  set menu_color_normal=cyan/blue
				  set menu_color_highlight=white/blue
				fi
				
				insmod play
				play 960 440 1 0 4 440 1
				#set theme=/boot/grub/theme/1
				
				menuentry "${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]" {
				 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				 	linux  /live/vmlinuz boot=${BOOT_OPTN}
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
			# ---- create dummy efi.img ---------------------------------------
			dd if=/dev/zero of="${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/efi.img" bs=1M count=100
			mkfs.fat "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/efi.img"
			mount "${DIRS_TEMP}/${TGET_LINE[4]/.iso/}/efi.img" "${DIRS_MNTS}"
			grub-install --target=x86_64-efi --efi-directory="${DIRS_MNTS}" --bootloader-id=boot --install-modules="" --removable
			cp -a "${DIRS_MNTS}/EFI/BOOT/BOOTX64.EFI" "${DIRS_CDFS}/EFI/boot/bootx64.efi"
			cp -a "${DIRS_MNTS}/EFI/BOOT/grubx64.efi" "${DIRS_CDFS}/EFI/boot/grubx64.efi"
			umount "${DIRS_MNTS}"
			# ---- create efi.img ---------------------------------------------
			ionice -c "${IONICE_CLAS}" dd if=/dev/zero of="${DIRS_CDFS}/boot/grub/efi.img" bs=1M count=10
			mkfs.fat "${DIRS_CDFS}/boot/grub/efi.img"
			mount "${DIRS_CDFS}/boot/grub/efi.img" "${DIRS_MNTS}"
			mkdir -p "${DIRS_MNTS}/"{EFI/boot,boot/grub}
			cp -a "${DIRS_CDFS}/EFI/boot/"{bootx64.efi,grubx64.efi} "${DIRS_MNTS}/EFI/boot/"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_MNTS}/boot/grub/grub.cfg"
				search --set=root --file /.disk/info
				set prefix=(\$root)/boot/grub
				configfile (\$root)/boot/grub/grub.cfg
_EOT_
			umount "${DIRS_MNTS}"
			# --- create iso file ---------------------------------------------
			ionice -c "${IONICE_CLAS}" xorriso -as mkisofs      \
			    -verbose                                        \
			    -iso-level 3                                    \
			    -full-iso9660-filenames                         \
			    -volid "${TGET_LINE[2]//%20/_}"                 \
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
			    -output "${DIRS_TGET}.iso"                      \
			    "${DIRS_CDFS}"
			if [[ -z "${FLAG_KEEP}" ]]; then
				rm -rf "${DIRS_TGET:?}"
			fi
			end_time=$(date +%s)
#			echo "${TGET_LINE[2]//%20/ } elapsed time: $((end_time-section_start_time)) [sec]"
#			echo -e "\033[m\033[45m${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]\033[m"
			printf "\033[m\033[45m%s %s\033[m\n" "${TGET_LINE[2]//%20/ }" "[${TGET_LINE[1]##*-}] ${TGET_ARCH}"
			printf "\033[m\033[45m${TGET_LINE[2]//%20/ } elapsed time: %dd%02dh%02dm%02ds\033[m\n" $(((end_time-section_start_time)/86400)) $(((end_time-section_start_time)%86400/3600)) $(((end_time-section_start_time)%3600/60)) $(((end_time-section_start_time)%60))
		done
		ls -lth "${DIRS_LIVE}/"*.iso 2> /dev/null || true
	fi

	date +"%Y/%m/%d %H:%M:%S"
	end_time=$(date +%s)
#	echo "elapsed time: $((end_time-start_time)) [sec]"
	printf "\033[m\033[45m${TGET_LINE[2]//%20/ } elapsed time: %dd%02dh%02dm%02ds\033[m\n" $(((end_time-start_time)/86400)) $(((end_time-start_time)%86400/3600)) $(((end_time-start_time)%3600/60)) $(((end_time-start_time)%60))
#	echo -e "\033[m\033[42m--- complete ---\033[m"
	printf "\033[m\033[42m%s\033[m\n" "--- complete ---"

	exit 0
# https://manpages.debian.org/bookworm/live-boot-doc/live-boot.7.ja.html
# https://manpages.debian.org/bookworm/bdebstrap/bdebstrap.1.en.html
#	bdebstrap 
#	    [-h|--help] 
#	    [-c|--config CONFIG] 
#	    [-n|--name NAME] 
#	    [-e|--env ENV] 
#	    [-s|--simulate|--dry-run] 
#	    [-b|--output-base-dir OUTPUT_BASE_DIR] 
#	    [-o|--output OUTPUT] 
#	    [-q|--quiet|--silent|-v|--verbose|--debug] 
#	    [-f|--force]
#	    [-t|--tmpdir TMPDIR] 
#	    [--variant {extract,custom,essential,apt,required,minbase,buildd,important,debootstrap,-,standard}] 
#	    [--mode {auto,sudo,root,unshare,fakeroot,fakechroot,proot,chrootless}] 
#	    [--format {auto,directory,dir,tar,squashfs,sqfs,ext2,null}] 
#	    [--aptopt APTOPT] 
#	    [--keyring KEYRING] 
#	    [--dpkgopt DPKGOPT] 
#	    [--hostname HOSTNAME] 
#	    [--install-recommends] 
#	    [--packages|--include PACKAGES] 
#	    [--components COMPONENTS] 
#	    [--architectures ARCHITECTURES] 
#	    [--setup-hook COMMAND] 
#	    [--essential-hook COMMAND] 
#	    [--customize-hook COMMAND] 
#	    [--cleanup-hook COMMAND] 
#	    [--suite SUITE] 
#	    [--target TARGET] 
#	    [--mirrors MIRRORS] 
#	    [SUITE [TARGET [MIRROR...]]]
# *****************************************************************************
# ALSA test
# aplay -l
# for F in /usr/share/sounds/alsa/*.wav; do aplay --device=sysdefault:CARD=Generic $F; done
# *****************************************************************************
