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
	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  Live%20media%20Live%20mode          -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  live-debian-10-buster       Live%20Debian%2010                  debian          live-debian-10-buster-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-debian-11-bullseye     Live%20Debian%2011                  debian          live-debian-11-bullseye-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-debian-12-bookworm     Live%20Debian%2012                  debian          live-debian-12-bookworm-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-debian-13-trixie       Live%20Debian%2013                  debian          live-debian-13-trixie-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"o  live-debian-xx-unstable     Live%20Debian%20xx                  debian          live-debian-xx-unstable-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
		"x  live-ubuntu-14.04-trusty    Live%20Ubuntu%2014.04               ubuntu          live-ubuntu-14.04-trusty                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"L  live-ubuntu-16.04-xenial    Live%20Ubuntu%2016.04               ubuntu          live-ubuntu-16.04-xenial                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"L  live-ubuntu-18.04-bionic    Live%20Ubuntu%2018.04               ubuntu          live-ubuntu-18.04-bionic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"s  live-ubuntu-20.04-focal     Live%20Ubuntu%2020.04               ubuntu          live-ubuntu-20.04-focal                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-22.04-jammy     Live%20Ubuntu%2022.04               ubuntu          live-ubuntu-22.04-jammy                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"x  live-ubuntu-23.04-lunar     Live%20Ubuntu%2023.04               ubuntu          live-ubuntu-23.04-lunar                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"x  live-ubuntu-23.10-mantic    Live%20Ubuntu%2023.10               ubuntu          live-ubuntu-23.10-mantic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-24.04-noble     Live%20Ubuntu%2024.04               ubuntu          live-ubuntu-24.04-noble                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"o  live-ubuntu-24.10-oracular  Live%20Ubuntu%2024.10               ubuntu          live-ubuntu-24.10-oracular                  live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
		"s  live-ubuntu-xx.xx-devel     Live%20Ubuntu%20xx.xx               ubuntu          live-ubuntu-xx.xx-devel                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

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
	declare       FLAG_KEEP=""
	declare       FLAG_SIMU=""
	declare       FLAG_CONT=""
	declare       OPTN_CONF=""
	declare       OPTN_KEYS=""
	declare       OPTN_COMP=""
	declare       FILE_YAML=""
	declare       FILE_CONF=""
#	declare       DIRS_CONF=""
	declare       DIRS_LIVE=""
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

	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	echo -e "\033[m\033[42m--- start ---\033[m"
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

#	rm -rf ${DIRS_WORK:?}/live
#	mkdir -p ${DIRS_WORK}/live

	if [[ -z "${PROG_PARM[*]}" ]]; then
		echo "sudo ./${PROG_NAME} [ options ]"
#		echo "reusing a previously created filesystem.squashfs"
#		echo "  -k | --keep"
		echo "create a full suite"
		echo "  -a | --all"
		WORK_STRS=""
		for ((I=0; I<"${#TGET_LIST[@]}"; I++))
		do
			read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
			if [[ "${TGET_LINE[0]}" != "o" ]]; then
				continue
			fi
			WORK_STRS+="${WORK_STRS:+" | "}${TGET_LINE[1]##*-}"
		done
		echo "choose any suite"
		echo "  ${WORK_STRS:?}"
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
			echo -e "\033[m\033[45m${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]\033[m"
#			DIRS_CONF="${DIRS_WORK}/conf"
			DIRS_LIVE="${DIRS_WORK}/live/${TGET_LINE[1]}"
			DIRS_CDFS="${DIRS_TEMP}/${TGET_LINE[1]}/cdfs"
			DIRS_MNTS="${DIRS_TEMP}/${TGET_LINE[1]}/mnts"
			SQFS_NAME="${TGET_LINE[1]}.squashfs"
#			SQFS_NAME="filesystem.squashfs"
			# --- create cd/dvd image -----------------------------------------
			rm -rf "${DIRS_TEMP:?}/${TGET_LINE[1]}:?"
			mkdir -p "${DIRS_TEMP}/${TGET_LINE[1]}/"{cdfs/{.disk,EFI/boot,boot/grub/{live-theme,x86_64-efi},isolinux,live/{boot,config.conf.d}},mnts}
			# --- create squashfs file ----------------------------------------
			if [[ -z "${FLAG_KEEP}" ]] || [[ ! -f "${DIRS_LIVE}/${SQFS_NAME}" ]]; then
				rm -rf "${DIRS_LIVE:?}"
				mkdir -p "${DIRS_LIVE:?}"
				# -------------------------------------------------------------
				OPTN_COMP=""
#				case "${TGET_LINE[1]}" in
#					live-debian-10-buster      | \
#					live-debian-11-bullseye    ) OPTN_COMP="--components=main,contrib,non-free";;
#					live-debian-*              ) OPTN_COMP="--components=main,contrib,non-free,non-free-firmware";;
#					live-ubuntu-*              ) OPTN_COMP="--components=main,multiverse,restricted,universe";;
#					*                          ) OPTN_COMP="";;
#				esac
				# -------------------------------------------------------------
				FILE_YAML="${DIRS_CONF}/_template/live_${TGET_LINE[3]}.yaml"
				FILE_CONF="${DIRS_TEMP}/${TGET_LINE[1]}/${FILE_YAML##*/}"
				OPTN_CONF="--config ${FILE_CONF}"
				cp -a "${FILE_YAML}" "${FILE_CONF}"
				case "${TGET_LINE[1]}" in
					live-debian-10-*    | \
					live-debian-11-*    | \
					live-ubuntu-20.04-* )
						sed -e '/^ *components:/,/^ *- */ {'                                  \
						    -e 's/ *non-free-firmware//g}'                                    \
						    -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                        \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                    \
						    -e '/^ * *- *at-spi2-common\(\| .*\|#.*\)$/             s/^ /#/g' \
						    -e '/^ * *- *exfatprogs\(\| .*\|#.*\)$/                 s/^ /#/g' \
						    -e '/^ * *- *fuse3\(\| .*\|#.*\)$/                      s/^ /#/g' \
						    -e '/^ * *- *media-types\(\| .*\|#.*\)$/                s/^ /#/g' \
						    -e '/^ * *- *polkitd\(\| .*\|#.*\)$/                    s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-all\(\| .*\|#.*\)$/        s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-gtk[0-9]\+\(\| .*\|#.*\)$/ s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-qt[0-9]\+\(\| .*\|#.*\)$/  s/^ /#/g' \
						    -e '/^ * *- *ibus-gtk[0-9]\+\(\| .*\|#.*\)$/            s/^ /#/g' \
						    -e '/^ * *- *gnome-text-editor\(\| .*\|#.*\)$/          s/^ /#/g' \
						    -e '/^#* *- *fcitx5-frontend-gtk[2-3]\(\| .*\|#.*\)$/   s/^#/ /g' \
						    -e '/^#* *- *fcitx5-frontend-qt[4-5]\(\| .*\|#.*\)$/    s/^#/ /g' \
						    -e '/^#* *- *ibus-gtk[2-3]\(\| .*\|#.*\)$/              s/^#/ /g' \
						    -e '}}'                                                           \
						    "${FILE_YAML}"                                                    \
						> "${FILE_CONF}"
						;;
					live-debian-12-*    )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                        \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                    \
						    -e '/^ * *- *fcitx5-frontend-all\(\| .*\|#.*\)$/        s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-gtk[0-9]\+\(\| .*\|#.*\)$/ s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-qt[0-9]\+\(\| .*\|#.*\)$/  s/^ /#/g' \
						    -e '/^ * *- *ibus-gtk[0-9]\+\(\| .*\|#.*\)$/            s/^ /#/g' \
						    -e '/^#* *- *fcitx5-frontend-gtk[2-4]\(\| .*\|#.*\)$/   s/^#/ /g' \
						    -e '/^#* *- *fcitx5-frontend-qt[4-6]\(\| .*\|#.*\)$/    s/^#/ /g' \
						    -e '/^#* *- *ibus-gtk[2-4]\(\| .*\|#.*\)$/              s/^#/ /g' \
						    -e '}}'                                                           \
						    "${FILE_YAML}"                                                    \
						> "${FILE_CONF}"
						;;
					live-ubuntu-22.04-* )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                        \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                    \
						    -e '/^ * *- *fcitx5-frontend-all\(\| .*\|#.*\)$/        s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-gtk[0-9]\+\(\| .*\|#.*\)$/ s/^ /#/g' \
						    -e '/^ * *- *fcitx5-frontend-qt[0-9]\+\(\| .*\|#.*\)$/  s/^ /#/g' \
						    -e '/^ * *- *ibus-gtk[0-9]\+\(\| .*\|#.*\)$/            s/^ /#/g' \
						    -e '/^#* *- *fcitx5-frontend-gtk[2-4]\(\| .*\|#.*\)$/   s/^#/ /g' \
						    -e '/^#* *- *fcitx5-frontend-qt[4-5]\(\| .*\|#.*\)$/    s/^#/ /g' \
						    -e '/^#* *- *ibus-gtk[2-4]\(\| .*\|#.*\)$/              s/^#/ /g' \
						    -e '}}'                                                           \
						    "${FILE_YAML}"                                                    \
						> "${FILE_CONF}"
						;;
					live-debian-*       | \
					live-ubuntu-*       )
						sed -e '/^ *packages:/,/^[# ]*[[:graph:]]*:/{'                        \
						    -e '/^[# ]*-\(\| .*\|#.*\)$/{'                                    \
						    -e '/^ * *- *fcitx5-frontend-all\(\| .*\|#.*\)$/        s/^ /#/g' \
						    -e '/^#* *- *fcitx5-frontend-gtk[0-9]\(\| .*\|#.*\)$/   s/^#/ /g' \
						    -e '/^#* *- *fcitx5-frontend-qt[0-9]\(\| .*\|#.*\)$/    s/^#/ /g' \
						    -e '/^#* *- *ibus-gtk[0-9]\(\| .*\|#.*\)$/              s/^#/ /g' \
						    -e '}}'                                                           \
						    "${FILE_YAML}"                                                    \
						> "${FILE_CONF}"
						;;
					*                   ) OPTN_CONF="";;
				esac
				# -------------------------------------------------------------
				# shellcheck disable=SC2086,SC2090,SC2248
				ionice -c "${IONICE_CLAS}" bdebstrap \
				    ${OPTN_CONF:-} \
				    --name "${TGET_LINE[1]}" \
				    ${FLAG_SIMU:-} \
				    --output-base-dir "${DIRS_WORK}/live" \
				    ${OPTN_KEYS:-} \
				    ${OPTN_COMP:-} \
				    --suite "${TGET_LINE[1]##*-}" \
				    --target "${SQFS_NAME}" \
				    || if [[ -n "${FLAG_CONT:-}" ]]; then continue; else exit 1; fi
				if [[ -f "${FILE_CONF}" ]]; then
					cp -a "${FILE_CONF}" "${DIRS_LIVE}"
					chmod 644 "${DIRS_LIVE}/${FILE_CONF##*/}"
				fi
				if [[ -n "${FLAG_SIMU:-}" ]]; then
					continue
				fi
			fi
			# ---- copy script ------------------------------------------------
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
			# ---- create .disk/info ------------------------------------------
			touch "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/.disk/info"
			# ---- copy filesystem --------------------------------------------
			cp -a "${DIRS_LIVE}/manifest"     "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/filesystem.packages"
			cp -a "${DIRS_LIVE}/${SQFS_NAME}" "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/filesystem.squashfs"
			# ---- copy vmlinuz/initrd ----------------------------------------
			mount -r -t squashfs "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/filesystem.squashfs" "${DIRS_MNTS}"
			case "${TGET_LINE[3]}" in
				debian )
					cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-amd64    "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/vmlinuz"
					cp -a "${DIRS_MNTS}/boot/"initrd.img-*-amd64 "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/initrd.img"
					;;
				ubuntu )
					cp -a "${DIRS_MNTS}/boot/"vmlinuz-*-generic    "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/vmlinuz"
					cp -a "${DIRS_MNTS}/boot/"initrd.img-*-generic "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/live/initrd.img"
					;;
				* )
					break
					;;
			esac
			umount "${DIRS_MNTS}"
			# ---- create isolinux --------------------------------------------
	#		wget --directory-prefix="${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux" \
	#			"https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/boot-screens/splash.png"
			cp -a /usr/lib/syslinux/modules/bios/* "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux"
			cp -a /usr/lib/ISOLINUX/isolinux.bin   "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux"
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/isolinux.cfg"
				include menu.cfg
				default vesamenu.c32
				prompt 0
				timeout 50
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/menu.cfg"
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
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/stdmenu.cfg"
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
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/live.cfg"
				label ${TGET_LINE[2]//%20/_}
				 	menu label ^${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]
				 	menu default
				 	linux /live/vmlinuz
				 	initrd /live/initrd.img
				 	append boot=live components quiet splash overlay-size=90%
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/install.cfg"
				#label installstart
				#	menu label Start ^installer
				#	linux /install/gtk/vmlinuz
				#	initrd /install/gtk/initrd.gz
				#	append vga=788  --- quiet
_EOT_
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/isolinux/utilities.cfg"
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
			cp -a /usr/lib/grub/x86_64-efi/*  "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/boot/grub/x86_64-efi"
			cp -a /usr/share/grub/unicode.pf2 "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/boot/grub"
			cat <<- _EOT_ | sed -e '/^ [^ ]*/ s/^ *//g' > "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/boot/grub/grub.cfg"
				set timeout=5
				set default=0
				set lang=ja_JP
				grub_platform
				
				menuentry "${TGET_LINE[2]//%20/ } [${TGET_LINE[1]##*-}]" {
				 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				 	linux  /live/vmlinuz boot=live components quiet splash overlay-size=90%
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
			dd if=/dev/zero of="${DIRS_TEMP}/${TGET_LINE[1]}/efi.img" bs=1M count=100
			mkfs.fat "${DIRS_TEMP}/${TGET_LINE[1]}/efi.img"
			mount "${DIRS_TEMP}/${TGET_LINE[1]}/efi.img" "${DIRS_MNTS}"
			grub-install --target=x86_64-efi --efi-directory="${DIRS_MNTS}" --bootloader-id=boot --install-modules="" --removable
			cp -a "${DIRS_MNTS}/EFI/BOOT/BOOTX64.EFI" "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/EFI/boot/bootx64.efi"
			cp -a "${DIRS_MNTS}/EFI/BOOT/grubx64.efi" "${DIRS_TEMP}/${TGET_LINE[1]}/cdfs/EFI/boot/grubx64.efi"
			umount "${DIRS_MNTS}"
			# ---- create efi.img ---------------------------------------------
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
			    -output "${DIRS_LIVE}.iso"                      \
			    "${DIRS_CDFS}"
			if [[ -z "${FLAG_KEEP}" ]]; then
				rm -rf "${DIRS_LIVE:?}"
			fi
			end_time=$(date +%s)
#			echo "${TGET_LINE[2]//%20/ } elapsed time: $((end_time-section_start_time)) [sec]"
			printf "${TGET_LINE[2]//%20/ } elapsed time: %dd%02dh%02dm%02ds\n" $(((end_time-section_start_time)/86400)) $(((end_time-section_start_time)%86400/3600)) $(((end_time-section_start_time)%3600/60)) $(((end_time-section_start_time)%60))
		done
		ls -lth "${DIRS_WORK}/live/"*.iso
	fi

	date +"%Y/%m/%d %H:%M:%S"
	end_time=$(date +%s)
#	echo "elapsed time: $((end_time-start_time)) [sec]"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $(((end_time-start_time)/86400)) $(((end_time-start_time)%86400/3600)) $(((end_time-start_time)%3600/60)) $(((end_time-start_time)%60))
	echo -e "\033[m\033[42m--- complete ---\033[m"

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
