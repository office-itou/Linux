#!/bin/bash
###############################################################################
##
##	ファイル名	:	debootstrap.sh
##
##	機能概要	:	Live DVD作成ツール (mmdebstrap版)
##
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian / Ubuntu (64bit)
##	---------------------------------------------------------------------------
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2022/06/01
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- ----------------------------------------
##	2022/06/01 000.0000 J.Itou         新規作成
##	2022/06/04 000.0000 J.Itou         不具合修正
##	2022/06/05 000.0000 J.Itou         処理見直し
##	2022/06/06 000.0000 J.Itou         不具合修正
##	2022/06/08 000.0000 J.Itou         処理見直し
##	2022/06/09 000.0000 J.Itou         動作環境追加
##	2022/06/11 000.0000 J.Itou         処理見直し
##	2022/10/29 000.0000 J.Itou         処理見直し
##	2022/11/23 000.0000 J.Itou         リスト更新
##	2023/03/16 000.0000 J.Itou         不具合修正
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	sudo apt-get -y install mmdebstrap squashfs-tools xorriso
# *****************************************************************************
# debootstrap for stable/testing cdrom
#  debian: sudo apt-get install ubuntu-keyring (ubuntuから入手)
#  ubuntu: sudo apt-get install debian-archive-keyring
# *****************************************************************************
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

	trap 'exit 1' 1 2 3 15

# === 初期設定値 ==============================================================
	FLG_LOGOUT="false"
	TARGET_ARCH=""
	TARGET_SUITE=""
	TARGET_KEYRING=""
	TARGET_MIRROR=""

	ARRAY_LIST=(
	    "debian         amd64,i386 preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         amd64,i386 preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         amd64,i386 preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         amd64,i386 preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         amd64,i386 preseed_ubuntu.cfg                          2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         amd64      preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2020-04-23   2030-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         amd64      preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	    "ubuntu         amd64      preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
	    "ubuntu         amd64      preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	)   # 0:区分        1:arch     2:定義ファイル                              3:リリース日 4:サポ終了日 5:備考          6:備考2
#	    "ubuntu         amd64      preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \

# === 共通関数: string ========================================================
fncString () {
	if [ "$2" = " " ]; then
		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
	else
		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
	fi
}

# === 共通関数: print =========================================================
fncPrint () {
	local RET_STR=""
	MAX_COLS=$((COL_SIZE-1))
	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	if [ $? -ne 0 ]; then
		MAX_COLS=$((COL_SIZE-2))
		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	fi
	echo "${RET_STR}"
}

# === ヘルプ表示 ==============================================================
fncHelp () {
	local LINE
	local -a LIST=()

	fncInitialize_List

	printf "  usage: sudo $0 -a architecture -s suite [ -k directory ] [ -m mirror ]\n"
	printf "\n"
	printf "    %-10.10s : %s\n" "-h,--help"   "This message."
	printf "    %-10.10s : %s\n" "-l,--log"    "Output log to text file."
	printf "    %-10.10s : %s\n" "-a,--arch"   "See arch below."
	printf "    %-10.10s : %s\n" "-s,--suite"  "See suite below."
	printf "    %-10.10s : %s\n" "-k,--key"    "GPG key file directory."
	printf "    %-10.10s : %s\n" "-m,--mirror" "Mirror server."
	printf "\n"
	printf "    %-10.10s : %-15.15s : %s\n" "arch" "suite" "distribution"
	for LINE in "${ARRAY_LIST[@]}"
	do
		LIST=(${LINE})
		printf "    %-10.10s : %-15.15s : %s\n" "${LIST[1]}" "`echo ${LIST[5]%%_*} | tr A-Z a-z`" "${LIST[6]//_/ }"
	done
}

# === 初期化処理 ==============================================================
fncInitialize () {
	WHO_AMI=`whoami`															# 実行ユーザー名
	NOW_DATE=`date +"%Y/%m/%d"`													# yyyy/mm/dd
	NOW_DTTM=`date +"%Y%m%d%H%M%S"`												# yyyymmddhhmmss
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`									# プログラム名
	PGM_DIR=$(cd $(dirname $0); pwd)											# プログラムディレクトリー名
	WRK_DIR=${PGM_DIR}															# ワークディレクトリー名
#	WRK_DIR=`awk -F ':' '$1=='\"${SUDO_USER:-${USER}}\"' {print $6;}' /etc/passwd`
	#--- 画面表示領域設定 -----------------------------------------------------
	ROW_SIZE=25																	# 行の最小値
	COL_SIZE=80																	# 列の最小値
	if [ "`which tput 2> /dev/null`" != "" ]; then
		ROW_SIZE=`tput lines`
		COL_SIZE=`tput cols`
	fi
	if [ ${COL_SIZE} -lt 80 ]; then
		COL_SIZE=80
	fi
	if [ ${COL_SIZE} -gt 100 ]; then
		COL_SIZE=100
	fi
	# --- cpu type -------------------------------------------------------------
	CPU_TYPE=`LANG=C lscpu | awk '/Architecture:/ {print $2;}'`					# CPU TYPE (x86_64/armv5tel/...)
	CPU_LBIT=`getconf LONG_BIT`													# 32 / 64 bit
	# --- system info ----------------------------------------------------------
	SYS_NAME=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
	SYS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
	SYS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
	SYS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
	SYS_VNUM=`echo ${SYS_VRID:--1} | bc`										#   〃          (取得できない場合は-1)
	SYS_NOOP=0																	# 対象OS=1,それ以外=0
	if [ "${SYS_CODE}" = "" -o ${SYS_VNUM} -lt 0 ]; then
		if [ -f /etc/lsb-release ]; then
			SYS_CODE=`awk -F '=' '$1=="DISTRIB_CODENAME" {gsub("\"",""); print $2;}' /etc/lsb-release`	# コード名
		else
			case "${SYS_NAME}" in
				"debian"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`       ;;
				"ubuntu"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`       ;;
#				"centos"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/centos-release`       ;;
#				"fedora"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $3;}' /etc/fedora-release`       ;;
#				"rocky"               ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/rocky-release`        ;;
#				"miraclelinux"        ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/miraclelinux-release` ;;
#				"almalinux"           ) SYS_CODE=`awk                    '{gsub("\"",""); print $3;}' /etc/redhat-release`       ;;
#				"opensuse-leap"       ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`           ;;
				"opensuse-tumbleweed" ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`           ;;
				*                     )                                                                                          ;;
			esac
		fi
	fi
	if [ "${SYS_NAME}" = "debian" ] && [ "${SYS_CODE}" = "sid" ]; then
		SYS_NOOP=1
	else
		if [ "${CPU_TYPE}" = "x86_64" ]; then
			case "${SYS_NAME}" in
				"debian"              ) SYS_NOOP=`echo "${SYS_VNUM} >=  9"       | bc`;;
				"ubuntu"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 18.04"    | bc`;;
#				"centos"              ) SYS_NOOP=`echo "${SYS_VNUM} >=  8"       | bc`;;
#				"fedora"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 32"       | bc`;;
#				"rocky"               ) SYS_NOOP=`echo "${SYS_VNUM} >=  8.4"     | bc`;;
#				"miraclelinux"        ) SYS_NOOP=`echo "${SYS_VNUM} >=  8"       | bc`;;
#				"almalinux"           ) SYS_NOOP=`echo "${SYS_VNUM} >=  9"       | bc`;;
#				"opensuse-leap"       ) SYS_NOOP=`echo "${SYS_VNUM} >= 15.2"     | bc`;;
				"opensuse-tumbleweed" ) SYS_NOOP=`echo "${SYS_VNUM} >= 20201002" | bc`;;
				*                     )                                               ;;
			esac
		fi
	fi
#	if [ ${SYS_NOOP} -eq 0 ]; then
#		echo "${SYS_NAME} ${SYS_VERS:-${SYS_CODE}} (${CPU_TYPE}) ではテストをしていないので実行できません。"
#		exit 1
#	fi
}

# === リスト初期化処理 ========================================================
fncInitialize_List () {
	case "${SYS_NAME}" in
		"debian" )
			for FILE in /etc/apt/trusted.gpg.d/ubuntu*.gpg "${TARGET_KEYRING}"/ubuntu*.gpg
			do
				if [ -e "$FILE" ]; then
					return;
				fi
			done
			ARRAY=("${ARRAY_LIST[@]}")
			for ((I=0; I<${#ARRAY_LIST[@]}; I++))
			do
				LIST=(${ARRAY[I]})
				if [ "${LIST[0]}" = "ubuntu" ]; then
					unset ARRAY[I]
				fi
			done
			ARRAY_LIST=("${ARRAY[@]}")
			;;
		"ubuntu" )
			for FILE in /etc/apt/trusted.gpg.d/debian*.gpg "${TARGET_KEYRING}"/debian*.gpg
			do
				if [ -e "$FILE" ]; then
					return;
				fi
			done
			ARRAY=("${ARRAY_LIST[@]}")
			for ((I=0; I<${#ARRAY_LIST[@]}; I++))
			do
				LIST=(${ARRAY[I]})
				if [ "${LIST[0]}" = "debian" ]; then
					unset ARRAY[I]
				fi
			done
			ARRAY_LIST=("${ARRAY[@]}")
			;;
		*        )
			;;
	esac
}

# === オプション入力処理 ======================================================
fncOption () {
	local PARAM

	PARAM=$(getopt -n $0 -o hla:s:k:m: -l help,log,arch:,suite:,key:mirror: -- "$@")
	eval set -- "$PARAM"

	while [ -n "${1:-}" ]
	do
		case $1 in
			-h | --help   )
				fncHelp
				exit 1
				;;
			-l | --log    )
				FLG_LOGOUT="true"
				shift
				;;
			-a | --arch   )
				shift
				TARGET_ARCH="$1"
				shift
				;;
			-s | --suite  )
				shift
				TARGET_SUITE="$1"
				shift
				;;
			-k | --key    )
				shift
				if [ -n "$1" ]; then
					if [ -d "$1" ]; then
						TARGET_KEYRING="$1"
					elif [ -f "$1" ]; then
						TARGET_KEYRING=`dirname "$1"`
					fi
				fi
				shift
				;;
			-m | --mirror )
				shift
				if [ -n "$1" ]; then
					TARGET_MIRROR="$1"
				fi
				shift
				;;
			* )
				shift
				;;
		esac
	done

	if [ "${FLG_LOGOUT}" = "true" ]; then
		exec &> >(tee -a "./${PGM_NAME}.log")
	fi

	fncInitialize_List
}

# === チェック処理 ============================================================
fncCheck () {
	if [ "${TARGET_ARCH}" = "" ] || [ "${TARGET_SUITE}" = "" ]; then
		fncHelp
		exit 1
	fi
	#--------------------------------------------------------------------------
	if [ ${SYS_NOOP} -eq 0 ]; then
		echo "${SYS_NAME} ${SYS_VERS:-${SYS_CODE}} (${CPU_TYPE}) ではテストをしていないので実行できません。"
		fncHelp
		exit 1
	fi
	#--------------------------------------------------------------------------
	if [ "${SYS_NAME}" != "debian" ] && [ "${SYS_NAME}" != "ubuntu" ]; then
		echo "$0 はDebian/Ubuntuで使用して下さい。"
		fncHelp
		exit 1
	fi
	#--------------------------------------------------------------------------
	TARGET_DIST=""
	for LINE in "${ARRAY_LIST[@]}"
	do
		LIST=(${LINE})
		if [ "`echo ${LIST[5]%%_*} | tr A-Z a-z`" = "${TARGET_SUITE}" ]; then
			ARCH=($(echo ${LIST[1]//,/ }))
			if [ "${TARGET_ARCH}" = "${ARCH[0]:-}" ] || [ "${TARGET_ARCH}" = "${ARCH[1]:-}" ]; then
				TARGET_DIST=${LIST[0]}
			fi
			break
		fi
	done
	if [ "${TARGET_DIST}" = "" ]; then
		echo "${TARGET_SUITE} の ${TARGET_ARCH} 版は作成対象外です。"
		fncHelp
		exit 1
	fi
	#--------------------------------------------------------------------------
	if [ "${WHO_AMI}" != "root" ]; then
		echo "管理者権限で実行して下さい。"
		fncHelp
		exit 1
	fi
}

# === default =================================================================
fncSet_default () {
	local _DIST="`echo \"${TARGET_DIST}\" | sed -e 's/\(.\)\(.*\)/\U\1\L\2/g'`"

	fncPrint "--- set default value $(fncString ${COL_SIZE} '-')"
	HOSTNAME="live-${TARGET_DIST}"							# ホスト名
	WORKGROUP="workgroup"									# ワークグループ名
	USERNAME="master"										# ログインユーザー名
	PASSWORD="master"										# ログインパスワード
	FULLNAME="${_DIST} Live user (${USERNAME})"				# ユーザーフルネーム
}

# === set parameter ===========================================================
fncSet_parameter () {
	fncPrint "--- set parameter $(fncString ${COL_SIZE} '-')"
	# --- 個別パラメータ設定 --------------------------------------------------
	# --variant=[ extract | custom | essential | apt | minbase | buildd | debootstrap | standard ]
	TARGET_VARIANT="debootstrap"
	TARGET_COMPONENTS=""
#	TARGET_MIRROR=""
	TARGET_PACKAGE=" \
	    open-infrastructure-system-boot \
	    open-infrastructure-system-build \
	    open-infrastructure-system-config \
	    open-infrastructure-system-images \
	    isolinux syslinux \
	    build-essential curl vim \
	    open-vm-tools open-vm-tools-desktop \
	    clamav \
	    bind9 dnsutils \
	    openssh-server \
	    samba smbclient cifs-utils \
	    isc-dhcp-server \
	    minidlna \
	    fonts-noto \
	    ibus-mozc mozc-utils-gui \
	    libreoffice-l10n-ja libreoffice-help-ja \
	"
	case "${TARGET_DIST}" in
		"debian" )
			TARGET_COMPONENTS="main non-free contrib"
			TARGET_MIRROR="${TARGET_MIRROR:-http://deb.debian.org/debian/}"
			TARGET_PACKAGE+=" \
			    linux-headers-${TARGET_ARCH//i386/686} \
			    linux-image-${TARGET_ARCH//i386/686} \
			    task-lxde-desktop \
			    task-japanese-desktop \
			    task-japanese-gnome-desktop \
			    thunderbird-l10n-ja \
			"
			;;
		"ubuntu" )
			TARGET_COMPONENTS="main multiverse restricted universe"
			TARGET_MIRROR="${TARGET_MIRROR:-http://archive.ubuntu.com/ubuntu/}"
			TARGET_PACKAGE+=" \
			    linux-headers-generic \
			    linux-image-generic \
			    ubuntu-desktop ubuntu-server \
			    language-pack-ja \
			    language-pack-gnome-ja \
			    thunderbird-locale-ja \
			"
			;;
		*        )
			;;
	esac
	case "${TARGET_SUITE}" in
		"oldoldstable" | \
		"oldstable"    | \
		"stable"       | \
		"testing"      | \
		"jammy"        | \
		"kinetic"      )
			TARGET_PACKAGE+=" \
			    task-laptop \
			    task-japanese \
			"
			;;
		*              )
			;;
	esac
}

# === get debian installer ====================================================
fncGet_debian_installer () {
	fncPrint "--- get debian installer $(fncString ${COL_SIZE} '-')"
	case "${TARGET_DIST}" in
		"debian" )
			TAR_INST=debian-cd_info-${TARGET_SUITE}-${TARGET_ARCH}.tar.gz
			TAR_URL="https://cdimage.debian.org/debian/dists/${TARGET_SUITE}/main/installer-${TARGET_ARCH}/current/images/cdrom/debian-cd_info.tar.gz"
			if [ ! -f "${DIR_TOP}/${TAR_INST}" ]; then
				curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "${DIR_TOP}/${TAR_INST}" "${TAR_URL}" || \
				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
					echo "URL: ${TAR_URL}"
					exit 1;
				fi
			fi
			tar -xzf "${DIR_TOP}/${TAR_INST}" -C "${DIR_WRK}/_work/"
			;;
		"ubuntu" )
#			TAR_INST=debian-cd_info-focal-${TARGET_ARCH}.tar.gz
#			TAR_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-${TARGET_ARCH}/current/legacy-images/cdrom/debian-cd_info.tar.gz"
			TAR_INST=debian-cd_info-stable-${TARGET_ARCH}.tar.gz
			TAR_URL="https://cdimage.debian.org/debian/dists/stable/main/installer-${TARGET_ARCH}/current/images/cdrom/debian-cd_info.tar.gz"
			PNG_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
			if [ ! -f "${DIR_TOP}/${TAR_INST}" ]; then
				curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "${DIR_TOP}/${TAR_INST}" "${TAR_URL}" || \
				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
					echo "URL: ${TAR_URL}"
					exit 1;
				fi
			fi
			if [ ! -f "${DIR_TOP}/splash.png" ]; then
				curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "${DIR_TOP}/splash.png"  "${PNG_URL}" || \
				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
					echo "URL: ${PNG_URL}"
					exit 1;
				fi
			fi
			tar -xzf "${DIR_TOP}/${TAR_INST}" -C "${DIR_WRK}/_work/"
			cp -p "${DIR_TOP}/splash.png" "${DIR_WRK}/_work/"
			chown root:root "${DIR_WRK}/_work/splash.png"
			;;
		*        )
			;;
	esac
}

# === make inst-net.sh ========================================================
fncMake_inst_net_sh () {
	fncPrint "--- make inst-net.sh $(fncString ${COL_SIZE} '-')"
	cat <<- '_EOT_SH_' | \
		sed -e 's/^ //g'                      \
		    -e "s/_HOSTNAME_/${HOSTNAME}/g"   \
		    -e "s/_WORKGROUP_/${WORKGROUP}/g" \
		> "${DIR_TOP}/inst-net.sh"
		#!/bin/bash
		# =============================================================================
		#	set -n								# 構文エラーのチェック
		#	set -x								# コマンドと引数の展開を表示
		 	set -o ignoreeof					# Ctrl+Dで終了しない
		 	set +m								# ジョブ制御を無効にする
		 	set -e								# ステータス0以外で終了
		 	set -u								# 未定義変数の参照で終了
		 	trap 'exit 1' 1 2 3 15
		# -- initialize ---------------------------------------------------------------
		 	ROW_SIZE=25
		 	COL_SIZE=80
		 	if [ "`which tput 2> /dev/null`" != "" ]; then
		 		ROW_SIZE=`tput lines`
		 		COL_SIZE=`tput cols`
		 	fi
		 	if [ ${COL_SIZE} -lt 80 ]; then
		 		COL_SIZE=80
		 	fi
		 	if [ ${COL_SIZE} -gt 100 ]; then
		 		COL_SIZE=100
		 	fi
		# -- string -------------------------------------------------------------------
		fncString () {
		 	if [ "$2" = " " ]; then
		 		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
		 	else
		 		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
		 	fi
		}
		# -- print --------------------------------------------------------------------
		fncPrint () {
		 	local RET_STR=""
		 	MAX_COLS=$((COL_SIZE-1))
		 	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
		 	if [ $? -ne 0 ]; then
		 		MAX_COLS=$((COL_SIZE-2))
		 		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
		 	fi
		 	echo "${RET_STR}"
		}
		# -- systemctl ----------------------------------------------------------------
		fncSystemctl () {
		 	echo "systemctl $@"
		 	case "$1" in
		 		"disable" | "mask" )
		 			shift
		 			systemctl --quiet --no-reload disable $@
		 			systemctl --quiet --no-reload mask $@
		 			;;
		 		"enable" | "unmask" )
		 			shift
		 			systemctl --quiet --no-reload unmask $@
		 			systemctl --quiet --no-reload enable $@
		 			;;
		 		* )
		 			systemctl --quiet --no-reload $@
		 			;;
		 	esac
		}
		# -- terminate ----------------------------------------------------------------
		fncEnd() {
		 	fncPrint "--- termination $(fncString ${COL_SIZE} '-')"
		 	RET_STS=$1
		 	history -c
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]: ${OS_NAME} ${VERSION}"
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	exit ${RET_STS}
		}
		# == main =====================================================================
		 	OS_NAME=`sed -n 's/^NAME="\(.*\)"$/\1/p' /etc/os-release`
		 	VERSION=`sed -n 's/^VERSION="\(.*\)"$/\1/p' /etc/os-release`
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]: ${OS_NAME} ${VERSION}"
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "--- initialize $(fncString ${COL_SIZE} '-')"
		 	fncPrint "---- os name  : ${OS_NAME} $(fncString ${COL_SIZE} '-')"
		 	fncPrint "---- version  : ${VERSION} $(fncString ${COL_SIZE} '-')"
		 	fncPrint "---- hostname : _HOSTNAME_ $(fncString ${COL_SIZE} '-')"
		 	fncPrint "---- workgroup: _WORKGROUP_ $(fncString ${COL_SIZE} '-')"
		 	export PS1="(chroot) "
		 	echo "_HOSTNAME_" > /etc/hostname
		#	hostname -b -F /etc/hostname
		 	if [ -d "/usr/lib/systemd/" ]; then
		 		DIR_SYSD="/usr/lib/systemd/"
		 	elif [ -d "/lib/systemd/" ]; then
		 		DIR_SYSD="/lib/systemd"
		 	else
		 		DIR_SYSD=""
		 	fi
		# -- module update, upgrade, tasksel, install ---------------------------------
		 	fncPrint "--- module update, install, clean $(fncString ${COL_SIZE} '-')"
		 	if [ `getconf LONG_BIT` -eq 32 ]; then
		 		APP_CHROME=""
		 	else
		 		fncPrint "---- google-chrome signing key install $(fncString ${COL_SIZE} '-')"
		 		APP_CHROME="google-chrome-stable"
		 		KEY_CHROME="https://dl-ssl.google.com/linux/linux_signing_key.pub"
		 		pushd /tmp/ > /dev/null
		 			if [ ! -f ./linux_signing_key.pub ]; then
		 				set +e
		 				curl -L -s -R -S -f --connect-timeout 3 --retry 3 -O "${KEY_CHROME} " || \
		 				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
		 					echo "URL: ${KEY_CHROME}"
		 					fncEnd 1;
		 				fi
		 				set -e
		 			fi
		 			if [ ! -d /etc/apt/trusted.gpg.d/ ]; then
		 				mkdir -p /etc/apt/trusted.gpg.d
		 			fi
		 			gpg --dearmor < ./linux_signing_key.pub > /etc/apt/trusted.gpg.d/google-chrome.gpg
		 			rm -f ./linux_signing_key.pub
		 			echo 'deb http://dl.google.com/linux/chrome/deb/ stable main'     \
		 			    > /etc/apt/sources.list.d/google-chrome.list
		 		popd > /dev/null
		 	fi
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "---- update sources.list $(fncString ${COL_SIZE} '-')"
		 	case "`echo ${OS_NAME} | awk '{print tolower($1);}'`" in
		 		"debian" )	APT_MIRROR="http://deb.debian.org/debian/"		;;
		 		"ubuntu" )	APT_MIRROR="http://archive.ubuntu.com/ubuntu/"	;;
		 		*        )	APT_MIRROR=""									;;
		 	esac
		 	if [ "${APT_MIRROR}" != "" ]; then
		 		OLD_MIRROR=`sed -n '/^deb .* main */p' /etc/apt/sources.list | sed -e 's/\[.*\] //g' | awk '$3!~/-/ {print $2;}'`
		 		APT_SUITE=`sed -n '/^deb .* main */p' /etc/apt/sources.list | sed -e 's/\[.*\] //g' | awk '$3!~/-/ {print $3;}'`
		 		APT_COMPONENTS=`sed -n "s/^deb .* ${APT_SUITE} \(.*\)\$/\1/p" /etc/apt/sources.list | sed -z 's/\n/ /g'`
		 		sed -i /etc/apt/sources.list \
		 		    -e '/^deb/ s/^/#/g'
		 		cat <<- _EOT_ >> /etc/apt/sources.list
		 			deb ${APT_MIRROR} ${APT_SUITE} ${APT_COMPONENTS}
		_EOT_
		 	fi
		 	# -------------------------------------------------------------------------
		 	if [ -d /var/lib/apt/lists ]; then
		 		fncPrint "---- remove /var/lib/apt/lists $(fncString ${COL_SIZE} '-')"
		 		rm -rf /var/lib/apt/lists
		 	fi
		 	# -------------------------------------------------------------------------
		 	export DEBIAN_FRONTEND=noninteractive
		 	APT_OPTIONS="-o Dpkg::Options::=--force-confdef    \
		 	             -o Dpkg::Options::=--force-confnew    \
		 	             -o Dpkg::Options::=--force-overwrite"
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "---- module dpkg $(fncString ${COL_SIZE} '-')"
		 	dpkg --audit                                                           || fncEnd $?
		 	dpkg --configure -a                                                    || fncEnd $?
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "---- module apt-get update $(fncString ${COL_SIZE} '-')"
		 	apt-get update       -qq                                   > /dev/null || fncEnd $?
		 	fncPrint "---- module apt-get upgrade $(fncString ${COL_SIZE} '-')"
		 	apt-get upgrade      -qq  -y ${APT_OPTIONS}                > /dev/null || fncEnd $?
		 	fncPrint "---- module apt-get dist-upgrade $(fncString ${COL_SIZE} '-')"
		 	apt-get dist-upgrade -qq  -y ${APT_OPTIONS}                > /dev/null || fncEnd $?
		 	fncPrint "---- module apt-get install $(fncString ${COL_SIZE} '-')"
		 	apt-get install      -qq  -y ${APT_OPTIONS} --auto-remove               \
		 	    ${APP_CHROME}                                                       \
		 	                                                           > /dev/null || fncEnd $?
		#	fncPrint "---- tasksel $(fncString ${COL_SIZE} '-')"
		#	tasksel install                                                         \
		#	    _LST_TASK_                                                          \
		#	                                                           > /dev/null || fncEnd $?
		 	fncPrint "---- module autoremove, autoclean, clean $(fncString ${COL_SIZE} '-')"
		 	apt-get autoremove   -qq -y                                > /dev/null || fncEnd $?
		 	apt-get autoclean    -qq                                   > /dev/null || fncEnd $?
		 	apt-get clean        -qq                                   > /dev/null || fncEnd $?
		# -- Change system control ----------------------------------------------------
		# 	Set disable to mask because systemd-sysv-generator will recreate the symbolic link.
		 	fncPrint "--- change system control $(fncString ${COL_SIZE} '-')"
		 	fncSystemctl  enable clamav-freshclam
		 	fncSystemctl  enable ssh
		 	if [ "`systemctl is-enabled named 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl enable named
		 	else
		 		fncSystemctl enable bind9
		 	fi
		 	fncSystemctl  enable smbd
		 	fncSystemctl  enable nmbd
		 	fncSystemctl disable isc-dhcp-server
		 	if [ "`systemctl is-enabled isc-dhcp-server6 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable isc-dhcp-server6
		 	fi
		 	fncSystemctl disable minidlna
		 	if [ "`systemctl is-enabled unattended-upgrades 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable unattended-upgrades
		 	fi
		 	if [ "`systemctl is-enabled brltty 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable brltty-udev
		 		fncSystemctl disable brltty
		 	fi
		 	case "`sed -n '/^UBUNTU_CODENAME=/ s/.*=\(.*\)/\1/p' /etc/os-release`" in
		 		"focal"   | \
		 		"impish"  | \
		 		"jammy"   | \
		 		"kinetic" )
		 			if [ "`systemctl is-enabled systemd-udev-settle 2> /dev/null || :`" != "" ]; then
		 				fncSystemctl disable systemd-udev-settle
		 			fi
		 			;;
		 		* )
		 			;;
		 	esac
		# -- Change service configure -------------------------------------------------
		#	if [ -f /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service ]; then
		#		fncPrint "--- change cups-browsed configure $(fncString ${COL_SIZE} '-')"
		#		cat <<- _EOT_ > /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service.override
		#			[Service]
		#			TimeoutStopSec=3
		#_EOT_
		#	fi
		# -- Change resolv configure --------------------------------------------------
		 	if [ -d /etc/NetworkManager/ ]; then
		 		fncPrint "--- change NetworkManager configure $(fncString ${COL_SIZE} '-')"
		 		touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
		 		cat <<- _EOT_ > /etc/NetworkManager/conf.d/NetworkManager.conf.override
		 			[main]
		 			dns=default
		 _EOT_
		 		fncPrint "--- change resolv.conf configure $(fncString ${COL_SIZE} '-')"
		 		cat <<- _EOT_ > /etc/systemd/resolved.conf.override
		 			[Resolve]
		 			DNSStubListener=no
		_EOT_
		 		ln -sf /run/systemd/resolve/resolv.conf etc/resolv.conf
		 	fi
		# -- Change avahi-daemon configure --------------------------------------------
		 	if [ -f /etc/nsswitch.conf ]; then
		 		fncPrint "--- change avahi-daemon configure $(fncString ${COL_SIZE} '-')"
		 		OLD_IFS=${IFS}
		 		IFS=$'\n'
		 		INS_ROW=$((`sed -n '/^hosts:/ =' /etc/nsswitch.conf | head -n 1`))
		 		INS_TXT=`sed -n '/^hosts:/ s/\(hosts:[ \t]*\).*$/\1mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns mdns/p' /etc/nsswitch.conf`
		 		sed -e '/^hosts:/ s/^/#/' /etc/nsswitch.conf | \
		 		sed -e "${INS_ROW}a ${INS_TXT}"                \
		 		> nsswitch.conf
		 		cat nsswitch.conf > /etc/nsswitch.conf
		 		rm nsswitch.conf
		 		IFS=${OLD_IFS}
		 	fi
		# -- Change clamav configure --------------------------------------------------
		 	if [ "`which freshclam 2> /dev/null`" != "" ]; then
		 		fncPrint "---- change freshclam.conf $(fncString ${COL_SIZE} '-')"
		 		sed -i /etc/clamav/freshclam.conf     \
		 		    -e 's/^Example/#&/'               \
		 		    -e 's/^CompressLocalDatabase/#&/' \
		 		    -e 's/^SafeBrowsing/#&/'          \
		 		    -e 's/^NotifyClamd/#&/'
		 		fncPrint "---- run freshclam $(fncString ${COL_SIZE} '-')"
		 		set +e
		 		freshclam --quiet
		 		set -e
		 	fi
		# -- Change sshd configure ----------------------------------------------------
		 	if [ -d /etc/ssh/ ]; then
		 		fncPrint "--- change sshd configure $(fncString ${COL_SIZE} '-')"
		 		if [ ! -d /etc/ssh/sshd_config.d/ ]; then
		 			cat <<- _EOT_ >> /etc/ssh/sshd_config
		 				
		 				# --- user settings ---
		 				PermitRootLogin no
		 				PubkeyAuthentication yes
		 				PasswordAuthentication yes
		_EOT_
		 			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
		 				cat <<- _EOT_ >> /etc/ssh/sshd_config
		 					PubkeyAcceptedAlgorithms +ssh-rsa
		 					HostkeyAlgorithms +ssh-rsa
		_EOT_
		 			fi
		 		else
		 			cat <<- _EOT_ > /etc/ssh/sshd_config.d/sshd_config.override
		 				PermitRootLogin no
		 				PubkeyAuthentication yes
		 				PasswordAuthentication yes
		_EOT_
		 			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
		 				cat <<- _EOT_ >> /etc/ssh/sshd_config.d/sshd_config.override
		 					PubkeyAcceptedAlgorithms +ssh-rsa
		 					HostkeyAlgorithms +ssh-rsa
		_EOT_
		 			fi
		 		fi
		 	fi
		# -- Change samba configure ---------------------------------------------------
			if [ -f /etc/samba/smb.conf ]; then
		 		fncPrint "--- change samba configure $(fncString ${COL_SIZE} '-')"
		 		SVR_NAME="_HOSTNAME_"						# 本機のホスト名
		 		WGP_NAME="_WORKGROUP_"						# 本機のワークグループ名
		 		CMD_UADD=`which useradd`
		 		CMD_UDEL=`which userdel`
		 		CMD_GADD=`which groupadd`
		 		CMD_GDEL=`which groupdel`
		 		CMD_GPWD=`which gpasswd`
		 		CMD_FALS=`which false`
		 		# ---------------------------------------------------------------------
		 		testparm -s -v |                                                                        \
		 		sed -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
		 		    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
		 		    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
		 		    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
		 		    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
		 		    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
		 		    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
		 		    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
		 		    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
		 		    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
		 		    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
		 		    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
		 		    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
		 		    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
		 		    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
		 		    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
		 		    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
		 		    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
		 		    -e 's/\(min protocol\) =.*$/\1 = NT1/g'                                             \
		 		    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
		 		    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
		 		    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
		 		    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
		 		    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
		 		    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
		 		    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
		 		    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
		 		    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
		 		    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
		 		    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
		 		    -e '/[ \t]*.* = $/d'                                                                \
		 		    -e '/[ \t]*\(client ipc\|client\|server\) min protocol = .*$/d'                     \
		 		    -e '/[ \t]*acl check permissions =.*$/d'                                            \
		 		    -e '/[ \t]*allocation roundup size =.*$/d'                                          \
		 		    -e '/[ \t]*blocking locks =.*$/d'                                                   \
		 		    -e '/[ \t]*client NTLMv2 auth =.*$/d'                                               \
		 		    -e '/[ \t]*client lanman auth =.*$/d'                                               \
		 		    -e '/[ \t]*client plaintext auth =.*$/d'                                            \
		 		    -e '/[ \t]*client schannel =.*$/d'                                                  \
		 		    -e '/[ \t]*client use spnego =.*$/d'                                                \
		 		    -e '/[ \t]*client use spnego principal =.*$/d'                                      \
		 		    -e '/[ \t]*copy =.*$/d'                                                             \
		 		    -e '/[ \t]*dns proxy =.*$/d'                                                        \
		 		    -e '/[ \t]*domain logons =.*$/d'                                                    \
		 		    -e '/[ \t]*domain master =.*$/d'                                                    \
		 		    -e '/[ \t]*enable privileges =.*$/d'                                                \
		 		    -e '/[ \t]*encrypt passwords =.*$/d'                                                \
		 		    -e '/[ \t]*idmap backend =.*$/d'                                                    \
		 		    -e '/[ \t]*idmap gid =.*$/d'                                                        \
		 		    -e '/[ \t]*idmap uid =.*$/d'                                                        \
		 		    -e '/[ \t]*lanman auth =.*$/d'                                                      \
		 		    -e '/[ \t]*logon path =.*$/d'                                                       \
		 		    -e '/[ \t]*logon script =.*$/d'                                                     \
		 		    -e '/[ \t]*lsa over netlogon =.*$/d'                                                \
		 		    -e '/[ \t]*map to guest =.*$/d'                                                     \
		 		    -e '/[ \t]*nbt client socket address =.*$/d'                                        \
		 		    -e '/[ \t]*null passwords =.*$/d'                                                   \
		 		    -e '/[ \t]*obey pam restrictions =.*$/d'                                            \
		 		    -e '/[ \t]*only user =.*$/d'                                                        \
		 		    -e '/[ \t]*pam password change =.*$/d'                                              \
		 		    -e '/[ \t]*paranoid server security =.*$/d'                                         \
		 		    -e '/[ \t]*password level =.*$/d'                                                   \
		 		    -e '/[ \t]*preferred master =.*$/d'                                                 \
		 		    -e '/[ \t]*raw NTLMv2 auth =.*$/d'                                                  \
		 		    -e '/[ \t]*realm =.*$/d'                                                            \
		 		    -e '/[ \t]*security =.*$/d'                                                         \
		 		    -e '/[ \t]*server role =.*$/d'                                                      \
		 		    -e '/[ \t]*server schannel =.*$/d'                                                  \
		 		    -e '/[ \t]*server services =.*$/d'                                                  \
		 		    -e '/[ \t]*server string =.*$/d'                                                    \
		 		    -e '/[ \t]*share modes =.*$/d'                                                      \
		 		    -e '/[ \t]*syslog =.*$/d'                                                           \
		 		    -e '/[ \t]*syslog only =.*$/d'                                                      \
		 		    -e '/[ \t]*time offset =.*$/d'                                                      \
		 		    -e '/[ \t]*unicode =.*$/d'                                                          \
		 		    -e '/[ \t]*unix password sync =.*$/d'                                               \
		 		    -e '/[ \t]*use spnego =.*$/d'                                                       \
		 		    -e '/[ \t]*usershare allow guests =.*$/d'                                           \
		 		    -e '/[ \t]*winbind separator =.*$/d'                                                \
		 		    -e '/[ \t]*wins support =.*$/d'                                                     \
		 		> ./smb.conf
		 		# ---------------------------------------------------------------------
		 		testparm -s ./smb.conf > /etc/samba/smb.conf
		 		rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
		fi
		# -- Change gdm3 configure ----------------------------------------------------
		#	if [ -f /etc/gdm3/custom.conf ] && [ ! -f /etc/gdm3/daemon.conf ]; then
		#		fncPrint "--- create gdm3 daemon.conf $(fncString ${COL_SIZE} '-')"
		#		cp -p /etc/gdm3/custom.conf /etc/gdm3/daemon.conf
		#		: > /etc/gdm3/daemon.conf
		#	fi
		# -- Change xdg configure -----------------------------------------------------
		 	if [  -f /etc/xdg/autostart/gnome-initial-setup-first-login.desktop ]; then
		 		fncPrint "--- change xdg configure $(fncString ${COL_SIZE} '-')"
		 		mkdir -p /etc/skel/.config
		 		touch /etc/skel/.config/gnome-initial-setup-done
		 	fi
		# -- Change dconf configure ---------------------------------------------------
		 	if [ "`which dconf 2> /dev/null`" != "" ]; then
		 		fncPrint "--- change dconf configure $(fncString ${COL_SIZE} '-')"
		 		# -- create dconf profile ---------------------------------------------
		 		fncPrint "--- create dconf profile $(fncString ${COL_SIZE} '-')"
		 		if [ ! -d /etc/dconf/db/local.d/ ]; then
		 			mkdir -p /etc/dconf/db/local.d
		 		fi
		 		if [ ! -d /etc/dconf/profile/ ]; then
		 			mkdir -p /etc/dconf/profile
		 		fi
		 		cat <<- _EOT_ > /etc/dconf/profile/user
		 			user-db:user
		 			system-db:local
		_EOT_
		 		# -- dconf org/gnome/desktop/screensaver ------------------------------
		 		fncPrint "---- dconf org/gnome/desktop/screensaver $(fncString ${COL_SIZE} '-')"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-screensaver
		 			[org/gnome/desktop/screensaver]
		 			idle-activation-enabled=false
		 			lock-enabled=false
		_EOT_
		 		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		 		fncPrint "---- dconf org/gnome/shell/extensions/dash-to-dock $(fncString ${COL_SIZE} '-')"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-dash-to-dock
		 			[org/gnome/shell/extensions/dash-to-dock]
		 			hot-keys=false
		 			hotkeys-overlay=false
		 			hotkeys-show-dock=false
		_EOT_
		 		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		 		fncPrint "---- dconf apps/update-manager $(fncString ${COL_SIZE} '-')"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-update-manager
		 			[apps/update-manager]
		 			check-dist-upgrades=false
		 			first-run=false
		_EOT_
		 		# -- dconf update -----------------------------------------------------
		 		fncPrint "---- dconf update $(fncString ${COL_SIZE} '-')"
		 		dconf update
		 	fi
		# -- Change release-upgrades configure ----------------------------------------
		#	if [ -f /etc/update-manager/release-upgrades ]; then
		#		fncPrint "--- change release-upgrades configure $(fncString ${COL_SIZE} '-')"
		#		sed -i /etc/update-manager/release-upgrades \
		#		    -e 's/^\(Prompt\)=.*$/\1=never/'
		#	fi
		#	if [ -f /usr/lib/ubuntu-release-upgrader/check-new-release-gtk ]; then
		#	fi
		# -- Copy pulse configure -----------------------------------------------------
		 	if [ -f /usr/share/gdm/default.pa ]; then
		 		fncPrint "--- copy pulse configure $(fncString ${COL_SIZE} '-')"
		 		mkdir -p /etc/skel/.config/pulse
		 		cp -p /usr/share/gdm/default.pa /etc/skel/.config/pulse/
		 	fi
		# -- root and user's setting --------------------------------------------------
		 	fncPrint "--- root and user's setting $(fncString ${COL_SIZE} '-')"
		 	LST_SHELL="`sed -n '/^#/! s~/~\\\\/~gp' /etc/shells |  sed -z 's/\n/|/g' | sed -e 's/|$//'`"
		 	for USER_NAME in "skel" `awk -F ':' '$7~/'"${LST_SHELL}"'/ {print $1;}' /etc/passwd`
		 	do
		 		fncPrint "---- ${USER_NAME}'s setting $(fncString ${COL_SIZE} '-')"
		 		if [ "${USER_NAME}" == "skel" ]; then
		 			USER_HOME="/etc/skel"
		 		else
		 			USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		 		fi
		 		if [ "${USER_HOME}" != "" ]; then
		 			pushd ${USER_HOME} > /dev/null
		 				# --- .bashrc -------------------------------------------------
		 				cat <<- _EOT_ >> .bashrc
		 					# --- 日本語文字化け対策 ---
		 					case "\${TERM}" in
		 					    "linux" ) export LANG=C;;
		 					    * )                    ;;
		 					esac
		 					export GTK_IM_MODULE=ibus
		 					export XMODIFIERS=@im=ibus
		 					export QT_IM_MODULE=ibus
		_EOT_
		 				# --- .vimrc --------------------------------------------------
		 				cat <<- _EOT_ > .vimrc
		 					set number              " Print the line number in front of each line.
		 					set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
		 					set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
		 					set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
		 					set nowrap              " This option changes how text is displayed.
		 					set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
		 					set laststatus=2        " The value of this option influences when the last window will have a status line always.
		 					syntax on               " Vim5 and later versions support syntax highlighting.
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .vimrc
		 				fi
		 				# --- .curlrc -------------------------------------------------
		 				cat <<- _EOT_ > .curlrc
		 					location
		 					progress-bar
		 					remote-time
		 					show-error
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .curlrc
		 				fi
		 				# --- xinput.d ------------------------------------------------
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					mkdir .xinput.d
		 					ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
		 					chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
		 				fi
		 				# --- .credentials --------------------------------------------
		 				cat <<- _EOT_ > .credentials
		 					username=value
		 					password=value
		 					domain=value
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .credentials
		 					chmod 0600 .credentials
		 				fi
		 				# --- libfm.conf ----------------------------------------------
		 				if [   -f .config/libfm/libfm.conf      ] \
		 				&& [ ! -f .config/libfm/libfm.conf.orig ]; then
		 					sed -i.orig .config/libfm/libfm.conf   \
		 					    -e 's/^\(single_click\)=.*$/\1=0/'
		 				fi
		 			popd > /dev/null
		 		fi
		 	done
		# -----------------------------------------------------------------------------
		 	fncPrint "--- cleaning and exit $(fncString ${COL_SIZE} '-')"
		 	fncEnd 0
		# == EOF ======================================================================
_EOT_SH_

	chmod +x "${DIR_TOP}/inst-net.sh"
}

# === make 0000-user.conf =====================================================
# mountpoint="/live/medium" -> "/run/live/medium" の暫定対応
fncMake_0000_user_conf () {
	fncPrint "--- make 0000-user.conf $(fncString ${COL_SIZE} '-')"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > "${DIR_TOP}/0000-user.conf"
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		
		# Reading configuration files from filesystem and live-media
		set -o allexport
		for _FILE in /run/live/medium/live/config.conf /run/live/medium/live/config.conf.d/*.conf \
		 	         ${rootmnt}/lib/live/mount/medium/live/config.conf ${rootmnt}/lib/live/mount/medium/live/config.conf.d/*.conf
		do
		 	if [ -e "${_FILE}" ]; then
		 		. "${_FILE}"
		 	fi
		done
		set +o allexport
_EOT_SH_

	chmod +x "${DIR_TOP}/0000-user.conf"
}

# === make 9999-user.conf =====================================================
fncMake_9999_user_conf () {
	fncPrint "--- make 9999-user.conf $(fncString ${COL_SIZE} '-')"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > "${DIR_TOP}/9999-user.conf"
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		#set -o allexport
		#set -o
		
		# === Fix Parameters ==========================================================
		# /bin/live-config or /lib/live/init-config.sh
		#  LIVE_HOSTNAME="debian"
		#  LIVE_USERNAME="user"
		#  LIVE_USER_FULLNAME="Debian Live user"
		#  LIVE_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"
		
		# === Fix Parameters [ /lib/live/config/0030-live-debconfig_passwd ] ======
		#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
		
		# === Fix Parameters [ /lib/live/config/0030-user-setup ] =================
		#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
		
		# === User parameters =========================================================
		export LIVE_CONFIG_CMDLINE				# この変数はブートローダのコマンドラインに相当します。(/proc/cmdline)
		export LIVE_CONFIG_COMPONENTS			# この変数は「live-config.components=構成要素1,構成要素2, ...  構成要素n」パラメータに相当します。
		export LIVE_CONFIG_NOCOMPONENTS			# この変数は「live-config.nocomponents=構成要素1,構成要素2,  ... 構成要素n」パラメータに相当します。
		export LIVE_DEBCONF_PRESEED				# この変数は「live-config.debconf-preseed=filesystem|medium|URL1|URL2|  ...  |URLn」パラメータに相当します。
		export LIVE_HOSTNAME					# この変数は「live-config.hostname=ホスト名」パラメータに相当します。
		export LIVE_USERNAME					# この変数は「live-config.username=ユーザ名」パラメータに相当します。
		export LIVE_PASSWORD					# ユーザーパスワード
		export LIVE_EMPTYPWD					# TRUEで空パスワード
		export LIVE_CRYPTPWD					# 暗号化パスワード
		export LIVE_USER_DEFAULT_GROUPS			# この変数は「live-config.user-default-groups="グループ1,グループ2  ... グループn"」パラメータに相当します。
		export LIVE_USER_FULLNAME				# この変数は「live-config.user-fullname="ユーザのフルネーム"」パラメータに相当します。
		export LIVE_LOCALES						# この変数は「live-config.locales=ロケール1,ロケール2 ...  ロケールn」パラメータに相当します。
		export LIVE_TIMEZONE					# この変数は「live-config.timezone=タイムゾーン」パラメータに相当します。
		export LIVE_KEYBOARD_MODEL				# この変数は「live-config.keyboard-model=キーボードの種類」パラメータに相当します。
		export LIVE_KEYBOARD_LAYOUTS			# この変数は「live-config.keyboard-layouts=キーボードレイアウト1,キーボードレイアウト2... キーボードレイアウトn」パラメータに相当します。
		export LIVE_KEYBOARD_VARIANTS			# この変数は「live-config.keyboard-variants=キーボード配列1,キーボード配列2 ... キーボード配列n」パラメータに相当します。
		export LIVE_KEYBOARD_OPTIONS			# この変数は「live-config.keyboard-options=キーボードオプション」パラメータに相当します。
		export LIVE_SYSV_RC						# この変数は「live-config.sysv-rc=サービス1,サービス2  ... サービスn」パラメータに相当します。
		export LIVE_UTC							# この変数は「live-config.utc=yes|no」パラメータに相当します。
		export LIVE_X_SESSION_MANAGER			# この変数は「live-config.x-session-manager=Xセッションマネージャ」パラメータに相当します。
		export LIVE_XORG_DRIVER					# この変数は「live-config.xorg-driver=XORGドライバ」パラメータに相当します。
		export LIVE_XORG_RESOLUTION				# この変数は「live-config.xorg-resolution=XORG解像度」パラメータに相当します。
		export LIVE_WLAN_DRIVER					# この変数は「live-config.wlan-driver=WLANドライバ」パラメータに相当します。
		export LIVE_HOOKS						# この変数は「live-config.hooks=filesystem|medium|URL1|URL2| ... |URLn」パラメータに相当します。
		export LIVE_CONFIG_DEBUG				# この変数は「live-config.debug」パラメータに相当します。
		export LIVE_CONFIG_NOAUTOLOGIN			# 
		export LIVE_CONFIG_NOROOT				# 
		export LIVE_CONFIG_NOX11AUTOLOGIN		# 
		export LIVE_SESSION						# 固定値
		export LIVE_DEBUGOUT					# Debug変数
		
		LIVE_HOSTNAME="debian"					# hostname
		
		LIVE_USER_FULLNAME="Debian Live user"	# full name
		LIVE_USERNAME="user"					# user name
		LIVE_PASSWORD="live"					# password
		#LIVE_CRYPTPWD='8Ab05sVQ4LLps'			# '/bin/echo "live" | mkpasswd -s'
		
		LIVE_LOCALES="ja_JP.UTF-8"				# locales
		LIVE_KEYBOARD_MODEL="pc105"				# keybord
		LIVE_KEYBOARD_LAYOUTS="jp"
		LIVE_KEYBOARD_VARIANTS="OADG109A"
		LIVE_TIMEZONE="Asia/Tokyo"				# timezone
		LIVE_UTC="yes"
		LIVE_XORG_RESOLUTION="1024x768"			# xorg resolution
		
		# === Change hostname =========================================================
		if [ -n "${LIVE_HOSTNAME:-""}" ]; then
		 	/bin/echo "${LIVE_HOSTNAME}" > /etc/hostname
		fi
		
		# === Copy shell file =========================================================
		for _FILE in /lib/live/mount/medium/live/config.conf.d/????-user-* \
		             /run/live/medium/live/config.conf.d/????-user-*
		do
		 	if [ -e "${_FILE}" ]; then
		 		cp -p "${_FILE}" /lib/live/config/
		 	fi
		done
		
		# === Creating state file =====================================================
		touch /var/lib/live/config/9999-user-config
		
		# =============================================================================
		#set +e
		# === Memo ====================================================================
		#	/lib/live/init-config.sh
		#	/lib/live/config/0020-hostname
		#	/lib/live/config/0030-live-debconfig_passwd
		#	/lib/live/config/0030-user-setup
		#	/lib/live/config/1160-openssh-server
		# *****************************************************************************
_EOT_SH_

	chmod +x "${DIR_TOP}/9999-user.conf"
}

# === make 9999-user-setting ==================================================
fncMake_9999_user_setting () {
	fncPrint "--- make 9999-user-setting $(fncString ${COL_SIZE} '-')"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > "${DIR_TOP}/9999-user-setting"
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		#set -o allexport
		#set -o
		
		/bin/echo ""
		/bin/echo "Start 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		
		#. /lib/live/config.sh
		
		#set -e
		
		Cmdline ()
		{
		 	# Reading kernel command line
		 	for _PARAMETER in ${LIVE_CONFIG_CMDLINE}
		 	do
		 		case "${_PARAMETER}" in
		 			debug   | \
		 			debugout)
		 				LIVE_DEBUGOUT="true"
		 				;;
		 			username=*)
		 				LIVE_USERNAME="${_PARAMETER#*username=}"
		 				;;
		 			password=*)
		 				LIVE_PASSWORD="${_PARAMETER#*password=}"
		 				;;
		 			emptypwd=*)
		 				LIVE_EMPTYPWD="${_PARAMETER#*emptypwd=}"
		 				;;
		 		esac
		 	done
		}
		
		Init ()
		{
		 	:
		}
		
		Config ()
		{
		 	# === Change user password ================================================
		 	if [ -n "${LIVE_USERNAME:-""}" ]; then
		#		useradd ${LIVE_USERNAME}
		 		if [ "${LIVE_EMPTYPWD:-""}" = "true" ]; then
		 			/bin/echo ""
		 			/bin/echo "Remove user password ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			passwd -d ${LIVE_USERNAME}
		 			LIVE_PASSWORD=""
		 		elif [ -n "${LIVE_PASSWORD:-""}" ]; then
		 			/bin/echo ""
		 			/bin/echo "Change user password ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | passwd ${LIVE_USERNAME}
		 		fi
		 		# === Change smb password =============================================
		 		if [ -n "`which smbpasswd 2> /dev/null`" ]; then
		 			/bin/echo ""
		 			/bin/echo "Create an smb user ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			smbpasswd -a ${LIVE_USERNAME} -n
		 			/bin/echo ""
		 			/bin/echo "Change smb password :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | smbpasswd ${LIVE_USERNAME}
		 		fi
		 		# === Change user mode ====================================================
		 		if [ `passwd -S ${LIVE_USERNAME} | awk '{print $7;}'` -ne -1 ]; then
		 			/bin/echo ""
		 			/bin/echo "Change user mode ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			usermod -f -1 ${LIVE_USERNAME}
		 		fi
		 	fi
		
		 	# === Change sshd configure ===============================================
		 	if [ -f /etc/ssh/sshd_config ]; then
		 		/bin/echo ""
		 		/bin/echo "Change sshd configure :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		sed -i /etc/ssh/sshd_config \
		 		    -e 's/^#*[ \t]*\(PasswordAuthentication\)[ \t]*.*$/\1 yes/g'
		 	fi
		
		 	# === Setup VMware configure ==============================================
		 	if [ "`lscpu | grep -i vmware`" != "" ]; then
		 		/bin/echo ""
		 		/bin/echo "Setup VMware configure ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		mkdir -p /media/hgfs
		 		chmod a+w /media/hgfs
		 		cat <<- _EOT_ >> /etc/fstab
		 			.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,users 0 0
		 _EOT_
		 		cat <<- _EOT_ >> /etc/fuse.conf
		 			user_allow_other
		 _EOT_
		 	fi
		
		 	# === Change gdm3 configure ===============================================
		 	if [ -f /etc/gdm3/custom.conf ] && [ -n "${LIVE_USERNAME:-""}" ]; then
		 		/bin/echo ""
		 		/bin/echo "Change gdm3 configure :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		OLD_IFS=${IFS}
		 		IFS= INS_STR=$(
		 			cat <<- _EOT_ | sed ':l; N; s/\n//; b l;'
		 				WaylandEnable=false\\n
		 				AutomaticLoginEnable=true\n
		 				AutomaticLogin=${LIVE_USERNAME}\\n
		 				TimedLoginEnable=false\\n
		 _EOT_
		 		)
		 		IFS=${OLD_IFS}
		 		sed -i /etc/gdm3/custom.conf \
		 		    -e '/^\[daemon\]/,/^\[/ {/^[#|\[]/! s/\(.*\)$/#  \1/g}' \
		 		    -e "/^\\[daemon\\]/a ${INS_STR}"
		 		if [ ! -f /etc/gdm3/daemon.conf ]; then
		 			/bin/echo ""
		 			/bin/echo "Create gdm3 daemon.conf :::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			touch /etc/gdm3/daemon.conf
		 		fi
		 	fi
		
		 	# === Change video mode configure =========================================
		 	if [ -f /etc/X11/Xsession.d/21xvidemode ]; then
		 		/bin/echo ""
		 		/bin/echo "Change video mode configure :::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		sed -i /etc/X11/Xsession.d/21xvidemode \
		 		    -e '1i {\nsleep 10' \
		 		    -e '$a } &'
		 	fi
		}
		
		Debug ()
		{
		 	if [ -z ${LIVE_DEBUGOUT:-""} ]; then
		 		return 0
		 	fi
		 	# === Display of parameters ===============================================
		 	/bin/echo ""
		 	/bin/echo "Display of parameters :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 	set | grep -e "^LIVE_.*="
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	dconf dump /org/gnome/desktop/screensaver/
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	dconf dump /org/gnome/todo/
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	printenv | sort
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	for F in $(find "/lib/systemd/system/" -type f -name "*.service" -print | sort -u)
		 	do
		 		S=`basename $F`
		 		R=`systemctl is-enabled "$S" || :`
		 		/bin/echo "$S: $R"
		 	done
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	mount | sort
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	set -o
		 	/bin/echo "-------------------------------------------------------------------------------"
		}
		
		Cmdline
		Init
		Config
		Debug
		
		# === Creating state file =====================================================
		/bin/echo ""
		/bin/echo "Creating state file :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		touch /var/lib/live/config/9999-user-setting

		/bin/echo ""
		/bin/echo "End 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
_EOT_SH_

	chmod +x "${DIR_TOP}/9999-user-setting"
	# ---------------------------------------------------------------------
	fncPrint "--- change 9999-user-setting $(fncString ${COL_SIZE} '-')"
	if [ -f "${DIR_TOP}/preseed.cfg" ]; then
		OLD_IFS=${IFS}
		IFS=$'\n'
		HOSTNAME="`awk '(!/#/&&/d-i[ \t]+netcfg\/get_hostname[ \t]+/),(!/\\\\/)  {print $0;}' \"${DIR_TOP}/preseed.cfg\" | sed -z 's/\n//g' | sed -e 's/.*[ \t]*string[ \t]*//'`"
		FULLNAME="`awk '(!/#/&&/d-i[ \t]+passwd\/user-fullname[ \t]+/),(!/\\\\/) {print $0;}' \"${DIR_TOP}/preseed.cfg\" | sed -z 's/\n//g' | sed -e 's/.*[ \t]*string[ \t]*//'`"
		USERNAME="`awk '(!/#/&&/d-i[ \t]+passwd\/username[ \t]+/),(!/\\\\/)      {print $0;}' \"${DIR_TOP}/preseed.cfg\" | sed -z 's/\n//g' | sed -e 's/.*[ \t]*string[ \t]*//'`"
		PASSWORD="`awk '(!/#/&&/d-i[ \t]+passwd\/user-password[ \t]+/),(!/\\\\/) {print $0;}' \"${DIR_TOP}/preseed.cfg\" | sed -z 's/\n//g' | sed -e 's/.*[ \t]*password[ \t]*//'`"
		IFS=${OLD_IFS}
	fi

	if [ -z "${HOSTNAME}" ]; then sed -i "${DIR_TOP}/9999-user.conf" -e 's/^\([ \t]*LIVE_HOSTNAME=\)/#\1/'; fi
	if [ -z "${FULLNAME}" ]; then sed -i "${DIR_TOP}/9999-user.conf" -e 's/^\([ \t]*LIVE_USER_FULLNAME=\)/#\1/'; fi
	if [ -z "${USERNAME}" ]; then sed -i "${DIR_TOP}/9999-user.conf" -e 's/^\([ \t]*LIVE_USERNAME=\)/#\1/'; fi
	if [ -z "${PASSWORD}" ]; then sed -i "${DIR_TOP}/9999-user.conf" -e 's/^\([ \t]*LIVE_PASSWORD=\)/#\1/'; fi

	sed -i "${DIR_TOP}/9999-user.conf"                             \
	    -e "s/^\([ \t]*LIVE_HOSTNAME\)=.*$/\1='${HOSTNAME}'/"      \
	    -e "s/^\([ \t]*LIVE_USER_FULLNAME\)=.*$/\1='${FULLNAME}'/" \
	    -e "s/^\([ \t]*LIVE_USERNAME\)=.*$/\1='${USERNAME}'/"      \
	    -e "s/^\([ \t]*LIVE_PASSWORD\)=.*$/\1='${PASSWORD}'/"
}

# === run mmdebstrap ==========================================================
fncRun_mmdebstrap () {
	fncPrint "-- Run mmdebstrap $(fncString ${COL_SIZE} '-')"
	rm -rf "${DIR_WRK}"/fsimg/*
	mkdir -p "${DIR_WRK}/fsimg"
	HOOK_CMD=""
	# -------------------------------------------------------------------------
	KEY_CHROME="https://dl-ssl.google.com/linux/linux_signing_key.pub"
	case ${TARGET_ARCH} in
		"amd64" )
			if [ ! -f "${DIR_TOP}/linux_signing_key.pub" ]; then
				fncPrint "--- get google-chrome signing key $(fncString ${COL_SIZE} '-')"
				curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "${DIR_TOP}/linux_signing_key.pub"  "${KEY_CHROME}" || \
				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
					echo "URL: ${KEY_CHROME}"
					exit 1;
				fi
			fi
			HOOK_CMD+=$(
				cat <<- _EOT_
					cp -p "${DIR_TOP}/linux_signing_key.pub" "${DIR_WRK}/fsimg/tmp/";
_EOT_
			)
			;;
		"i386"  )
			;;
		*       )
			;;
	esac
	# -------------------------------------------------------------------------
	HOOK_CMD+=$(
		cat <<- _EOT_
			cp -p "${DIR_TOP}/inst-net.sh" "${DIR_WRK}/fsimg/";
			chroot "${DIR_WRK}/fsimg/" /bin/bash /inst-net.sh;
_EOT_
	)
	# -------------------------------------------------------------------------
	if [ "${TARGET_KEYRING}" != "" ]; then
		KEYRING="--keyring=${TARGET_KEYRING}"
	fi
	# -------------------------------------------------------------------------
	mmdebstrap \
	    --components="${TARGET_COMPONENTS}" \
	    --variant=${TARGET_VARIANT} \
	    --mode=sudo \
	    --aptopt='Apt::Install-Recommends "true"' \
	    --include="${TARGET_PACKAGE} " \
	    --architectures=${TARGET_ARCH} \
	    --customize-hook="${HOOK_CMD}" \
	    ${KEYRING:-} \
	    ${TARGET_SUITE} \
	    "${DIR_WRK}/fsimg/" \
	    ${TARGET_MIRROR}
	# -------------------------------------------------------------------------
	fncPrint "--- cleaning $(fncString ${COL_SIZE} '-')"
	find "${DIR_WRK}/fsimg/var/log/" -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf "${DIR_WRK}/fsimg/inst-net.sh"                  \
	       "${DIR_WRK}/fsimg/root/.bash_history"           \
	       "${DIR_WRK}/fsimg/root/.viminfo"                \
	       "${DIR_WRK}"/fsimg/tmp/*                        \
	       "${DIR_WRK}/fsimg/var/cache/apt/*.bin"          \
	       "${DIR_WRK}/fsimg/var/cache/apt/archives/*.deb"
}

# === make dvd image ==========================================================
fncMake_dvd_image () {
	fncPrint "-- Make dvd image $(fncString ${COL_SIZE} '-')"
	rm -rf "${DIR_WRK}"/cdimg/*
	mkdir -p "${DIR_WRK}/cdimg/.disk"              \
	         "${DIR_WRK}/cdimg/EFI"                \
	         "${DIR_WRK}/cdimg/boot/grub"          \
	         "${DIR_WRK}/cdimg/isolinux"           \
	         "${DIR_WRK}/cdimg/live"               \
	         "${DIR_WRK}/cdimg/live/config.conf.d" \
	         "${DIR_WRK}/cdimg/preseed"
	# --- DVDイメージ展開用パラメーター ---------------------------------------
	OS_KERNEL="`find \"${DIR_WRK}\"/fsimg/boot/ -name \"vmlinuz*\" -print | sed -n 's/.*vmlinuz-//gp'`"
	OS_NAME="`sed -n '/^NAME=/ s/.*="\([a-zA-Z]*\).*"/\1/p' ${DIR_WRK}/fsimg/etc/os-release | tr A-Z a-z`"
	OS_VERSION="`sed -n '/^VERSION=/ s/^.*=\(.*\)/\1/p' ${DIR_WRK}/fsimg/etc/os-release | sed -e 's/\"//g'`"
	OS_VERSION_ID="`sed -n '/^VERSION=/ s/^.*="*\([0-9.]*\).*"*$/\1/p' ${DIR_WRK}/fsimg/etc/os-release`"
	OS_NAME="${OS_NAME:-${TARGET_DIST}}"
	if [ "${OS_VERSION}" = "" ] || [ "${OS_VERSION_ID}" = "" ]; then
		OS_VERSION="`cat ${DIR_WRK}/fsimg/etc/debian_version`"
		OS_VERSION_ID="${OS_VERSION##*/}"
	fi
	MNU_LABEL="${OS_NAME} ${OS_VERSION} Live ${TARGET_ARCH} (kernel ${OS_KERNEL})"
	DVD_NAME="${OS_NAME}-live-${OS_VERSION_ID}-${TARGET_SUITE}-${TARGET_ARCH}-debootstrap.iso"
	DVD_VOLID="d-live ${OS_NAME} ${TARGET_SUITE} ${TARGET_ARCH}"
	# --- DVDイメージの展開 ---------------------------------------------------
	fncPrint "--- copy system file $(fncString ${COL_SIZE} '-')"
	echo -en "${OS_NAME} ${OS_VERSION} Live ${TARGET_ARCH} `date +"%Y-%m-%d %H:%M"`" > "${DIR_WRK}/cdimg/.disk/info"
	cp -pr "${DIR_WRK}"/_work/grub/*                                     "${DIR_WRK}/cdimg/boot/grub/"
	cp -p  "${DIR_WRK}/_work/splash.png"                                 "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/_work/menu.cfg"                                   "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/_work/stdmenu.cfg"                                "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/_work/isolinux.cfg"                               "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/ISOLINUX/isolinux.bin"              "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/hdt.c32"      "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/ldlinux.c32"  "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/libcom32.c32" "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/libgpl.c32"   "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/libmenu.c32"  "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/libutil.c32"  "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/modules/bios/vesamenu.c32" "${DIR_WRK}/cdimg/isolinux/"
	cp -p  "${DIR_WRK}/fsimg/usr/lib/syslinux/memdisk"                   "${DIR_WRK}/cdimg/isolinux/"
	cp -pr "${DIR_WRK}"/fsimg/boot/*                                     "${DIR_WRK}/cdimg/live/"
	# --- メニューの背景 ------------------------------------------------------
	if [ -f "${DIR_TOP}/splash.png" ]; then
		cp -p  "${DIR_TOP}/splash.png" "${DIR_WRK}/cdimg/isolinux/"
		chown root:root "${DIR_WRK}/cdimg/isolinux/splash.png"
	fi
	# --- 変更するパラメーター関係とユーザー設定関係のシェル ------------------
	cp -p "${DIR_TOP}"/9999-* "${DIR_WRK}/cdimg/live/config.conf.d/"
	chown root:root "${DIR_WRK}"/cdimg/live/config.conf.d/*
	chmod +x "${DIR_WRK}"/cdimg/live/config.conf.d/*
	# --- mountpoint="/live/medium" -> "/run/live/medium" の暫定対応 ----------
	cp -p "${DIR_TOP}/0000-user.conf" "${DIR_WRK}/fsimg/etc/live/config.conf.d/"
	chown root:root "${DIR_WRK}/fsimg/etc/live/config.conf.d/0000-user.conf"
	chmod +x "${DIR_WRK}/fsimg/etc/live/config.conf.d/0000-user.conf"
	# --- DVDイメージへEFIファイルの展開 --------------------------------------
	fncPrint "--- copy EFI directory $(fncString ${COL_SIZE} '-')"
	mkdir -p "${DIR_WRK}/media/"
	mount -r -o loop "${DIR_WRK}/cdimg/boot/grub/efi.img" "${DIR_WRK}/media/"
	cp -pr "${DIR_WRK}"/media/efi/* "${DIR_WRK}/cdimg/EFI/"
	umount -q "${DIR_WRK}/media/" || umount -q -lf "${DIR_WRK}/media/"
	# --- ファイルシステムイメージの作成 --------------------------------------
	fncPrint "--- make file system image $(fncString ${COL_SIZE} '-')"
	rm -f "${DIR_WRK}/cdimg/live/filesystem.squashfs"
	mksquashfs "${DIR_WRK}/fsimg" "${DIR_WRK}/cdimg/live/filesystem.squashfs" -not-reproducible -xattrs -wildcards -noappend -quiet
	ls -lthLgG --time-style="+%Y/%m/%d %H:%M:%S" "${DIR_WRK}/cdimg/live/filesystem.squashfs" 2> /dev/null | awk '{gsub(/.*\//,"",$6); print $4,$5,$3,$6;}'
	# --- ブートメニューの作成 ------------------------------------------------
	fncPrint "--- edit grub.cfg file $(fncString ${COL_SIZE} '-')"
	cat <<- _EOT_ >> "${DIR_WRK}/cdimg/boot/grub/grub.cfg"
		if [ \${iso_path} ] ; then
		set loopback="findiso=\${iso_path}"
		export loopback
		fi
		
		menuentry "${MNU_LABEL}" {
		  linux  /live/vmlinuz-${OS_KERNEL} boot=live components splash quiet "\${loopback}"
		  initrd /live/initrd.img-${OS_KERNEL}
		}

		set timeout=5
_EOT_
	fncPrint "--- edit menu.cfg file $(fncString ${COL_SIZE} '-')"
	cat <<- _EOT_ > "${DIR_WRK}/cdimg/isolinux/menu.cfg"
		INCLUDE stdmenu.cfg
		MENU title Main Menu
		DEFAULT ${MNU_LABEL}
		LABEL ${MNU_LABEL}
		  SAY "Booting ${MNU_LABEL}..."
		  linux /live/vmlinuz-${OS_KERNEL} noeject
		  APPEND initrd=/live/initrd.img-${OS_KERNEL} boot=live components splash quiet
_EOT_
	fncPrint "--- edit isolinux.cfg file $(fncString ${COL_SIZE} '-')"
	sed -i "${DIR_WRK}/cdimg/isolinux/isolinux.cfg" \
	    -e 's/^\(timeout\) .*/\1 50/'
	# --- DVDイメージの作成 ---------------------------------------------------
	fncPrint "--- make iso image $(fncString ${COL_SIZE} '-')"
	pushd "${DIR_WRK}/cdimg" > /dev/null
	    find . ! -name "md5sum.txt" -type f -exec md5sum -b {} \; > md5sum.txt
	    xorriso -as mkisofs                                       \
	        -quiet                                                \
	        -iso-level 3                                          \
	        -full-iso9660-filenames                               \
	        -volid "${DVD_VOLID}"                                 \
	        -eltorito-boot isolinux/isolinux.bin                  \
	        -eltorito-catalog isolinux/boot.cat                   \
	        -no-emul-boot -boot-load-size 4 -boot-info-table      \
	        -isohybrid-mbr ../fsimg/usr/lib/ISOLINUX/isohdpfx.bin \
	        -eltorito-alt-boot                                    \
	        -e boot/grub/efi.img                                  \
	        -no-emul-boot -isohybrid-gpt-basdat                   \
	        -output "${PGM_DIR}/${PGM_NAME}/${DVD_NAME}"          \
	        .
	popd > /dev/null
	ls -lthLgG --time-style="+%Y/%m/%d %H:%M:%S" "${PGM_DIR}/${PGM_NAME}/${DVD_NAME}" 2> /dev/null | awk '{gsub(/.*\//,"",$6); print $4,$5,$3,$6;}'
}

# === main ====================================================================
	fncInitialize
	fncOption $@
	fncCheck
	# -------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]: ${TARGET_DIST} (${TARGET_SUITE})-${TARGET_ARCH}"
	fncPrint "$(fncString ${COL_SIZE} '*')"
	# -------------------------------------------------------------------------
	LST_PACK=""
	if [ "`which curl 2> /dev/null`" = "" ]; then
		LST_PACK+="curl "
	fi
	if [ "`which mmdebstrap 2> /dev/null`" = "" ]; then
		LST_PACK+="mmdebstrap "
	fi
	if [ "`which mksquashfs 2> /dev/null`" = "" ]; then
		LST_PACK+="squashfs-tools "
	fi
	if [ "`which xorriso 2> /dev/null`" = "" ]; then
		LST_PACK+="xorriso "
	fi
	if [ "${LST_PACK}" != "" ]; then
		apt-get -qq update
		apt-get -qq -y install ${LST_PACK}
	fi
	# -------------------------------------------------------------------------
	DIR_TOP="${PGM_DIR}/${PGM_NAME}/${TARGET_DIST}.${TARGET_SUITE}.${TARGET_ARCH}"
	DIR_WRK="${WRK_DIR}/${PGM_NAME}/${TARGET_DIST}.${TARGET_SUITE}.${TARGET_ARCH}/work"
	# --- マウント強制解除 ----------------------------------------------------
	MONT_LIST="`mount | grep "${DIR_WRK#*/}" | awk '{print $3;}'`"
	if [ "${MONT_LIST}" != "" ]; then
		fncPrint "-- Unmount $(fncString ${COL_SIZE} '-')"
		for POINT in ${MONT_LIST}
		do
			set +e
			mountpoint -q "${POINT}"
			if [ $? -eq 0 ]; then
				if [ "`basename ${POINT}`" = "dev" ]; then
					fncPrint "--- unmount ${POINT}/pts $(fncString ${COL_SIZE} '-')"
					umount -q "${POINT}/pts" || umount -q -lf "${POINT}/pts"
				fi
				fncPrint "--- unmount ${POINT} $(fncString ${COL_SIZE} '-')"
				umount -q "${POINT}" || umount -q -lf "${POINT}"
			fi
			set -e
		done
	fi
	# -------------------------------------------------------------------------
	fncPrint "-- Initialize $(fncString ${COL_SIZE} '-')"
	# --- ディレクトリー作成 --------------------------------------------------
	rm -rf   "${DIR_WRK}"
	mkdir -p "${DIR_TOP}" "${DIR_WRK}/media" "${DIR_WRK}/cdimg" "${DIR_WRK}/fsimg" "${DIR_WRK}/_work"
	# --- main処理 ------------------------------------------------------------
	fncSet_default
	fncSet_parameter
	fncGet_debian_installer
	fncMake_inst_net_sh
	fncMake_0000_user_conf
	fncMake_9999_user_conf
	fncMake_9999_user_setting
	fncRun_mmdebstrap
	fncMake_dvd_image
	# -------------------------------------------------------------------------
	fncPrint "-- Termination $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	rm -rf   "${DIR_WRK}"
	# -------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]: ${TARGET_DIST} (${TARGET_SUITE})-${TARGET_ARCH}"
	fncPrint "$(fncString ${COL_SIZE} '*')"
	exit 0
# == memo =====================================================================
#	sudo bash -c 'mount --bind /dev ./debootstrap/fsimg/dev && mount --bind /dev/pts ./debootstrap/fsimg/dev/pts && mount --bind /proc ./debootstrap/fsimg/proc'
#	sudo bash -c 'LANG=C chroot ./debootstrap/fsimg/'
#	sudo bash -c 'umount -lf ./debootstrap/fsimg/proc && umount -lf ./debootstrap/fsimg/dev/pts && umount -lf ./debootstrap/fsimg/dev'
# -----------------------------------------------------------------------------
#	tar -cz ./debootstrap/fsimg/inst-dvd.sh | xxd -ps
#	cat <<- _EOT_ | xxd -r -p | tar -xz
# -----------------------------------------------------------------------------
#	sudo apt-get -y install squashfs-tools xorriso cloop-utils isolinux
# -----------------------------------------------------------------------------
#	sudo unmkinitramfs ./cdimg/live/initrd.img-5.15.0-27-generic ./initrd/
# -----------------------------------------------------------------------------
#	sudo bash -c 'for S in oldoldstable oldstable stable testing
#	do
#	  for A in amd64 i386
#	  do
#	    ./debootstrap.sh -a $A -s $S
#	  done
#	done'
#
#	sudo bash -c 'for S in bionic focal impish jammy kinetic
#	do
#	  for A in amd64 i386
#	  do
#	    ./debootstrap.sh -a $A -s $S
#	  done
#	done'
# === EOF =====================================================================
