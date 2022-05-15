#!/bin/bash
###############################################################################
##
##	ファイル名 / 機能概要 :
##		dist_remaster_mini.sh	/	ブータブルCDの作成用シェル [mini.iso/initrd版]
##		dist_remaster_net.sh	/	ブータブルDVDの作成用シェル [netinst版]
##		dist_remaster_dvd.sh	/	ブータブルDVDの作成用シェル [DVD版]
##		live-custom.sh			/	Live diskの作成用シェル [DVD版]
##
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian (64bit)
##	---------------------------------------------------------------------------
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2021/08/16
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- ----------------------------------------
##	2021/08/16 000.0000 J.Itou         新規作成
##	2022/05/14 000.0000 J.Itou         シェル統合
##	2022/05/15 000.0000 J.Itou         不具合修正
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

	trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
	INP_INDX=${@:-""}					# 処理ID
# -----------------------------------------------------------------------------
	if [ "${INP_INDX}" = "init" ]; then
		SCRIPT_NAME=`basename $0`
		FLG_LINK=0
		for TARGET in "dist_remaster_mini" "dist_remaster_net" "dist_remaster_dvd" "live-custom"
		do
			if [ ! -f "./${TARGET}.sh" ] && [ ! -L "./${TARGET}.sh" ]; then
				ln -s "./${SCRIPT_NAME}" "./${TARGET}.sh"
				FLG_LINK=1
			fi
		done
		if [ ${FLG_LINK} -ne 0 ]; then
			echo "シンボリックリンクを作成しました。"
		fi
		exit 0
	fi
# -----------------------------------------------------------------------------
	WHO_AMI=`whoami`					# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
# -----------------------------------------------------------------------------
	readonly WORK_DIRS=`basename $0 | sed -e 's/\..*$//'`	# 作業ディレクトリ名(プログラム名)
# -----------------------------------------------------------------------------
#	readonly ARC_TYPE=i386				# CPUタイプ(32bit)
	readonly ARC_TYPE=amd64				# CPUタイプ(64bit)
# -----------------------------------------------------------------------------
	ARRAY_NAME=()

	readonly ARRAY_NAME_MINI=(                                                                                                                                                                                                                                                                                                        \
	    "debian         http://deb.debian.org/debian/dists/oldoldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                               -                                           preseed_debian.cfg                          2017-06-17   2022-06-xx   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://deb.debian.org/debian/dists/oldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                  -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://deb.debian.org/debian/dists/stable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                     -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/netboot/mini.iso                                                                   -                                           preseed_debian.cfg                          202x-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                         -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   bionic          Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/netboot/mini.iso                   -                                           preseed_ubuntu.cfg                          2020-04-23   2030-04-23   focal           Ubuntu_20.04(Focal_Fossa):LTS    " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                      2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2

	readonly ARRAY_NAME_NET=(                                                                                                                                                                                                                                                                                                         \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-[0-9].*-amd64-netinst.iso                             -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable   Debian__9.xx(stretch)             " \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-[0-9].*-amd64-netinst.iso                                -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable      Debian_10.xx(buster)              " \
	    "debian         https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-[0-9].*-amd64-netinst.iso                                         -                                           preseed_debian.cfg                          2019-07-06   2026-xx-xx   stable         Debian_11.xx(bullseye)            " \
	    "debian         https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                          -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing        Debian_12.xx(bookworm)            " \
	    "centos         https://ftp.yz.yamagata-u.ac.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                             -                                           kickstart_centos.cfg                        20xx-xx-xx   2024-05-31   RHEL_8.x       -                                 " \
	    "centos         https://ftp.yz.yamagata-u.ac.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                -                                           kickstart_centos.cfg                        2021-xx-xx   20xx-xx-xx   RHEL_9.x       -                                 " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/35/Server/x86_64/iso/Fedora-Server-netinst-x86_64-35-1.2.iso                -                                           kickstart_fedora.cfg                        2021-11-02   2022-12-07   kernel_5.14    -                                 " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/x86_64/iso/Fedora-Server-netinst-x86_64-36-1.5.iso                -                                           kickstart_fedora.cfg                        2022-05-10   2023-05-16   kernel_5.17     -                                " \
	    "suse           http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-NET-x86_64-Current.iso                                        -                                           yast_opensuse.xml                           2021-06-02   20xx-xx-xx   kernel_5.3.18  -                                 " \
	    "suse           http://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                   -                                           yast_opensuse.xml                           20xx-xx-xx   20xx-xx-xx   kernel_x.x     -                                 " \
	    "rocky          https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-[0-9].*-x86_64-boot.iso                                                    -                                           kickstart_rocky.cfg                         2021-11-15   20xx-xx-xx   RHEL_8.5       -                                 " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                      2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2

	readonly ARRAY_NAME_DVD=(                                                                                                                                                                                                                                                                                                         \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso                              -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso                                 -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso                                          -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                            -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-[0-9].*-server-amd64.iso                                                        -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9].*-live-server-amd64.iso                                                                   -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2020-04-23   2030-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9].*-live-server-amd64.iso                                                                  -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9].*-live-server-amd64.iso                                                                   -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	    "centos         https://ftp.yz.yamagata-u.ac.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                             -                                           kickstart_centos.cfg                        2019-xx-xx   2024-05-31   RHEL_8.x        -                                " \
	    "centos         https://ftp.yz.yamagata-u.ac.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                -                                           kickstart_centos.cfg                        2021-xx-xx   20xx-xx-xx   RHEL_9.x        -                                " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/35/Server/x86_64/iso/Fedora-Server-dvd-x86_64-35-1.2.iso                    -                                           kickstart_fedora.cfg                        2021-11-02   2022-12-07   kernel_5.15     -                                " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/x86_64/iso/Fedora-Server-dvd-x86_64-36-1.5.iso                    -                                           kickstart_fedora.cfg                        2022-05-10   2023-05-16   kernel_5.17     -                                " \
	    "suse           http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Current.iso                                        -                                           yast_opensuse.xml                           2021-06-02   20xx-xx-xx   kernel_5.3.18   -                                " \
	    "suse           http://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                   -                                           yast_opensuse.xml                           2021-xx-xx   20xx-xx-xx   kernel_x.x      -                                " \
	    "rocky          https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-[0-9].*-x86_64-dvd1.iso                                                    -                                           kickstart_rocky.cfg                         2021-11-15   20xx-xx-xx   RHEL_8.5        -                                " \
	    "miraclelinux   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.4-released/x86_64/MIRACLELINUX-[0-9].*-rtm-x86_64.iso                             -                                           kickstart_miraclelinux.cfg                  2021-10-04   20xx-xx-xx   RHEL_8.4        -                                " \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                   -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                      -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                               -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                 -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         https://releases.ubuntu.com/bionic/ubuntu-[0-9].*-desktop-amd64.iso                                                                      -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9].*-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2020-04-23   2030-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9].*-desktop-amd64.iso                                                                      -                                           preseed_ubuntu.cfg                          2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9].*-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                      2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2

	readonly ARRAY_NAME_LIVE=(                                                                                                                                                                                                                                                                                                        \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                   -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                      -                                           preseed_debian.cfg                          2019-07-06   2024-xx-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso                               -                                           preseed_debian.cfg                          2021-08-14   20xx-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                 -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         https://releases.ubuntu.com/bionic/ubuntu-[0-9].*-desktop-amd64.iso                                                                      -                                           preseed_ubuntu.cfg                          2018-04-26   2023-04-xx   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9].*-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2020-04-23   2025-04-xx   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9].*-desktop-amd64.iso                                                                      -                                           preseed_ubuntu.cfg                          2021-10-24   2022-07-xx   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9].*-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                      2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2
# -----------------------------------------------------------------------------
	readonly TXT_RESET="\033[m"
	readonly TXT_ULINE="\033[4m"
	readonly TXT_ULINERST="\033[24m"
	readonly TXT_REV="\033[7m"
	readonly TXT_REVRST="\033[27m"
	readonly TXT_BLACK="\033[30m"
	readonly TXT_RED="\033[31m"
	readonly TXT_GREEN="\033[32m"
	readonly TXT_YELLOW="\033[33m"
	readonly TXT_BLUE="\033[34m"
	readonly TXT_MAGENTA="\033[35m"
	readonly TXT_CYAN="\033[36m"
	readonly TXT_WHITE="\033[37m"
	readonly TXT_BBLACK="\033[40m"
	readonly TXT_BRED="\033[41m"
	readonly TXT_BGREEN="\033[42m"
	readonly TXT_BYELLOW="\033[43m"
	readonly TXT_BBLUE="\033[44m"
	readonly TXT_BMAGENTA="\033[45m"
	readonly TXT_BCYAN="\033[46m"
	readonly TXT_BWHITE="\033[47m"
# -----------------------------------------------------------------------------
fncMenu () {
	local OLD_IFS
	local RET_CD											# 戻り値退避用
	local ARRY_NAME=()										# 配列展開
	local CODE_NAME=()										# 配列宣言
	local DIR_NAME											# ディレクトリ名
	local FIL_INFO=()										# ファイル情報
	local WEB_INFO=()										# WEB情報
#	local FIL_NAME											# ファイル名
	local FIL_DATE											# ファイル日付
	local DVD_INFO											# DVD情報
	local DVD_SIZE											# DVDサイズ
	local DVD_DATE											# DVD日付
	local WEB_STAT
	local WEB_SIZE
	local WEB_LAST
	local WEB_DATE
	local TXT_COLOR
	local DST_FILE
	local DST_DATE
	fncPrint "# $(fncString $((${COL_SIZE}-5)) '-') #"
	fncPrint "#ID：Version$(fncString $((${COL_SIZE}-55)) ' ')：リリース日：サポ終了日：備考           #"
	for ((I=1; I<=${#ARRAY_NAME[@]}; I++))
	do
		TXT_COLOR=""
		ARRY_NAME=(${ARRAY_NAME[$I-1]})
		CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
		CODE_NAME[1]=`basename ${ARRY_NAME[1]} | sed -e 's/.iso//ig'`	# DVDファイル名
		CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
		CODE_NAME[3]=${ARRY_NAME[3]}									# 定義ファイル
		CODE_NAME[4]=${ARRY_NAME[4]}									# リリース日
		CODE_NAME[5]=${ARRY_NAME[5]}									# サポ終了日
		CODE_NAME[6]=${ARRY_NAME[6]}									# 備考
		CODE_NAME[7]=${ARRY_NAME[7]}									# 備考2
		DIR_NAME=`dirname ${CODE_NAME[2]}`
		# ---------------------------------------------------------------------
		OLD_IFS=${IFS}
		IFS=
		set +e
		WEB_INFO=($(curl -L -R -S -s -f --connect-timeout 3 "${DIR_NAME}" 2> /dev/null))
		RET_CD=$?
		set -e
		IFS=${OLD_IFS}
		# ---------------------------------------------------------------------
		if [ ${RET_CD} -eq 18 -o ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then	# WEB情報取得失敗
			TXT_COLOR=${TXT_RED}
		else												# WEB取得取得成功
			FIL_INFO=($(echo "${WEB_INFO[@]}" | LANG=C sed -n "s/^.*<a href=.*> *\(${CODE_NAME[1]}\.iso\) *<\/a.*> *\([0-9a-zA-Z]*-[0-9a-zA-Z]*-[0-9a-zA-Z]*\) *\([0-9]*:[0-9]*\).*$/\1 \2 \3/p"))
			if [ "${FIL_INFO[2]:+UNSET}" = "" ]; then
				FIL_INFO[2]="00:00"
			fi
			CODE_NAME[1]=`echo "${FIL_INFO[0]}" | sed -e 's/.iso//ig'`	# dvd/net
			CODE_NAME[2]=`echo "${DIR_NAME}/${FIL_INFO[0]}"`
			CODE_NAME[4]=`TZ=UTC date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y-%m-%d"`
		fi
		if [ "${CODE_NAME[1]}" = "mini" ]; then
			CODE_NAME[1]="mini-${ARRY_NAME[6]}-${ARC_TYPE}"	# mini.iso
		fi
		# ---------------------------------------------------------------------
		if [ "${ARRY_NAME[2]}" != "-" ]; then				# DVDファイル別名
			CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`
		fi
		# ---------------------------------------------------------------------
		if [ "${TXT_COLOR}" != "${TXT_RED}" ]; then
			if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
				TXT_COLOR=${TXT_YELLOW}
			else
				FIL_DATE=`TZ=UTC date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y%m%d%H%M%S"`
				DVD_DATE=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${WORK_DIRS}/${CODE_NAME[1]}.iso" | awk '{print $6;}'`
#				DST_FILE=`find "${WORK_DIRS}/" -regextype posix-basic -regex ".*/${CODE_NAME[1]}-\(custom-\)*\(autoyast\|kickstart\|nocloud\|preseed\)\.iso.*" -print`
				set +e
				DST_FILE=`ls "${WORK_DIRS}/"*iso | grep -e "${CODE_NAME[1]}-*\(custom\)*-\(autoyast\|kickstart\|nocloud\|preseed\).iso"`
				set -e
				if [ "${DST_FILE}" = "" ]; then
					DST_DATE=""
					TXT_COLOR=${TXT_YELLOW}
				else
					DST_DATE=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${DST_FILE}" | awk '{print $6;}'`
					if [ ${DVD_DATE} -gt ${DST_DATE} ]; then
						TXT_COLOR=${TXT_YELLOW}
					fi
				fi
				if [ ${FIL_DATE} -gt ${DVD_DATE} ]; then
					set +e
					curl -L -R -S -s -f --connect-timeout 3 -I --dump-header "header.txt" "${CODE_NAME[2]}" > /dev/null
					RET_CD=$?
					set -e
					# -------------------------------------------------------------
					if [ ${RET_CD} -eq 18 -o ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then
						TXT_COLOR=${TXT_RED}
					else
						DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${WORK_DIRS}/${CODE_NAME[1]}.iso"`
						DVD_SIZE=`echo "${DVD_INFO}" | awk '{print $5;}'`
						DVD_DATE=`echo "${DVD_INFO}" | awk '{print $6;}'`
						WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
						WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
						WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
						WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
						if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" -ne "${DVD_SIZE}" -o "${WEB_DATE}" -gt "${DVD_DATE}" ]; then
							TXT_COLOR=${TXT_YELLOW}
							CODE_NAME[4]=`echo "${WEB_DATE:0:4}-${WEB_DATE:4:2}-${WEB_DATE:6:2}"`
						fi
						if [ -f "header.txt" ]; then
							rm -f "header.txt"
						fi
					fi
				fi
			fi
		fi
		if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
			TXT_COLOR+=${TXT_REV}
		fi
		# ---------------------------------------------------------------------
		ARRAY_NAME[$I-1]=`printf "%s %s %s %s %s %s %s %s" ${CODE_NAME[0]} ${CODE_NAME[2]} ${CODE_NAME[1]}.iso ${CODE_NAME[3]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]} ${CODE_NAME[7]}`
		# ---------------------------------------------------------------------
		printf "#${TXT_COLOR}%2d：%-"$((${COL_SIZE}-48))"."$((${COL_SIZE}-48))"s：%-10.10s：%-10.10s：%-15.15s${TXT_RESET}#\n" ${I} ${CODE_NAME[1]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}
	done
	fncPrint "# $(fncString $((${COL_SIZE}-5)) '-') #"
	if [ ${#INP_INDX} -le 0 ]; then							# 引数無しで入力スキップ
		echo "ID番号+Enterを入力して下さい。"
		read INP_INDX
		case "${INP_INDX,,}" in
			"a" | "all" )
				INP_INDX="{1..${#ARRAY_NAME[@]}}"
				;;
			* )
				;;
		esac
	fi
}
# -----------------------------------------------------------------------------
fncIsInt () {
	set +e
	expr ${1:-""} + 1 > /dev/null 2>&1
	if [ $? -ge 2 ]; then echo 1; else echo 0; fi
	set -e
}
# -----------------------------------------------------------------------------
fncString () {
	if [ "$2" = " " ]; then
		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
	else
		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
	fi
}
# -----------------------------------------------------------------------------
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
# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=`echo ${INP_ADDR} | awk -F '.' '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
	done
	echo "${OUT_ARRY[@]}"
}
# -----------------------------------------------------------------------------
fncRemaster_mini () {
	# --- ARRAY_NAME ----------------------------------------------------------
	local ARRY_NAME=($1)											# 配列展開
	local CODE_NAME=()												# 配列宣言
	CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
	CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`	# DVDファイル名
	CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
	CODE_NAME[3]=${ARRY_NAME[3]}									# 定義ファイル
	CODE_NAME[4]=${ARRY_NAME[4]}									# リリース日
	CODE_NAME[5]=${ARRY_NAME[5]}									# サポ終了日
	CODE_NAME[6]=${ARRY_NAME[6]}									# 備考
	CODE_NAME[7]=${ARRY_NAME[7]}									# 備考2
	# -------------------------------------------------------------------------
	fncPrint "↓処理中：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '-')"
	# --- DVD -----------------------------------------------------------------
	local DVD_NAME="${CODE_NAME[1]}"
	local DVD_URL="${CODE_NAME[2]}"
	local EFI_IMAG="boot/grub/efi.img"
	local ISO_NAME="${DVD_NAME}-preseed"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="${CODE_NAME[3]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}"
	# -------------------------------------------------------------------------
	for POINT in `mount | sed -n "/${WORK_DIRS}\/${CODE_NAME[1]}/ s/.*on[ \t]*\(.*\)[ \t]*type.*\$/\1/gp"`
	do
		set +e
		mountpoint -q "${POINT}"
		if [ $? -eq 0 ]; then
			if [ "`basename ${POINT}`" = "dev" ]; then
				umount -q "${POINT}/pts" || umount -q -lf "${POINT}/pts"
			fi
			umount -q "${POINT}" || umount -q -lf "${POINT}"
		fi
		set -e
	done
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
			set +e
			curl -L -# -R -S -f --connect-timeout 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
		else
			set +e
			curl -L -R -S -s -f --connect-timeout 3 -I --dump-header "header.txt" "${DVD_URL}" > /dev/null || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
			local WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" != "${DVD_SIZE}" -o "${WEB_DATE}" != "${DVD_DATE}" ]; then
				fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
				set +e
				curl -L -# -R -S -f --connect-timeout 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
				set -e
			fi
			if [ -f "header.txt" ]; then
				rm -f "header.txt"
			fi
		fi
															# Volume ID
		if [ "`${CMD_WICH} volname 2> /dev/null`" != "" ]; then
			local VOLID=`volname "../${DVD_NAME}.iso"`
		else
			local VOLID=`LANG=C blkid -s LABEL "../${DVD_NAME}.iso" | sed -e 's/.*="\(.*\)"/\1/g'`
		fi
		# --- mnt -> image ----------------------------------------------------
		fncPrint "--- copy DVD -> work directory $(fncString ${COL_SIZE} '-')"
		mount -r -o loop "../${DVD_NAME}.iso" mnt
		pushd mnt > /dev/null								# 作業用マウント先
			find . -depth -print | cpio -pdm --quiet ../image/
		popd > /dev/null
		umount mnt
		# --- image -> decomp -> image ----------------------------------------
		pushd decomp > /dev/null							# initrd.gz 展開先
			gunzip < ../image/initrd.gz | cpio -i --quiet
			# --- preseed.cfg -> image ----------------------------------------
			if [ ! -f "../../../${CFG_NAME}" ]; then
				fncPrint "--- get ${CFG_NAME} $(fncString ${COL_SIZE} '-')"
				set +e
				curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
				set -e
			fi
			cp --preserve=timestamps "../../../${CFG_NAME}" "./preseed.cfg"
			# --- preseed.cfg -------------------------------------------------
			case "`echo ${CODE_NAME[7]} | sed -e 's/^.*(\(.*\)).*$/\1/'`" in
				wheezy         )
					sed -i "./preseed.cfg"                                                                        \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/country\).*$/\1 string manual/'                           \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/hostname\).*$/\1 string archive.debian.org/'        \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/directory\).*$/\1 string \/debian/'                 \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/mirror select\).*$/\1 select archive.debian.org/'   \
					    -e 's/\(^[ \t]*d-i[ \t]*apt-setup\/services-select\).*$/\1 multiselect updates/'
					;;
				jessie         )
					sed -i "./preseed.cfg"                                                                        \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/country\).*$/\1 string manual/'                           \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/hostname\).*$/\1 string archive.debian.org/'        \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/directory\).*$/\1 string \/debian/'                 \
					    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/mirror select\).*$/\1 select archive.debian.org/'   \
					    -e 's/^#\([ \t]*d-i debian-installer\/allow_unauthenticated .*$\)/ \1/'
					;;
				stretch        | \
				buster         )
					;;
				bullseye       | \
				bookworm       | \
				testing        )
#					sed -i "./preseed.cfg"                                                                     \
#					    -e 's/#[ \t]\(d-i[ \t]*preseed\/late_command string\)/  \1/'                           \
#					    -e 's/#[ \t]\([ \t]*in-target --pass-stdout systemctl disable connman.service\)/  \1/'
					sed -i "./preseed.cfg"      \
					    -e '/network-manager/d'
					;;
				Trusty_Tahr    )
					sed -i "./preseed.cfg"                     \
					    -e 's/ubuntu-server//'                 \
					    -e 's/gnome-getting-started-docs-ja//' \
					    -e 's/gnome-user-docs-ja//'
					;;
				Xenial_Xerus   )
					sed -i "./preseed.cfg"                     \
					    -e 's/gnome-user-docs-ja//'
					
					;;
				Bionic_Beaver  | \
				Focal_Fossa    )
					;;
				Groovy_Gorilla | \
				Hirsute_Hippo  | \
				Impish_Indri   )
					;;
				* )	;;
			esac
			# --- make initps.gz ----------------------------------------------
			find . | cpio -H newc --create --quiet | gzip -9 > ../image/initps.gz
		popd > /dev/null
		# --- image -----------------------------------------------------------
		pushd image > /dev/null								# 作業用ディスクイメージ
			# --- Get EFI Image -----------------------------------------------
			if [ ! -f ${EFI_IMAG} ]; then
				ISO_SKIPS=`fdisk -l "../../../${DVD_NAME}.iso" | awk '/EFI/ {print $2;}'`
				ISO_COUNT=`fdisk -l "../../../${DVD_NAME}.iso" | awk '/EFI/ {print $4;}'`
				dd if="../../../${DVD_NAME}.iso" of=${EFI_IMAG} bs=512 skip=${ISO_SKIPS} count=${ISO_COUNT} status=none
			fi
			if [ ! -d EFI ]; then
				fncPrint "--- copy EFI directory $(fncString ${COL_SIZE} '-')"
				mount -r -o loop  ${EFI_IMAG} ../mnt/
				pushd ../mnt/efi/ > /dev/null
					find . -depth -print | cpio -pdm --quiet ../../image/EFI/
				popd > /dev/null
				umount ../mnt/
			fi
			# -------------------------------------------------
#			INS_CFG="auto=true file=\/cdrom\/preseed.cfg"
			# --- txt.cfg -------------------------------------
			sed -i isolinux.cfg -e 's/\(timeout\).*$/\1 50/'
			sed -i prompt.cfg   -e 's/\(timeout\).*$/\1 50/'
#			sed -i gtk.cfg      -e '/^.*menu default.*$/d'
			sed -i txt.cfg      -e '/^.*menu default.*$/d'
			INS_ROW=$((`sed -n '/^label/ =' txt.cfg | head -n 1`-1))
			INS_STR="\\`sed -n '/menu label/p' txt.cfg | head -n 1 | sed -e 's/\(^.*menu\).*/\1 default/'`"
			if [ ${INS_ROW} -ge 1 ]; then
				sed -n '/label install/,/append/p' txt.cfg | \
				sed -e 's/^\(label\) install/\1 autoinst/'   \
				    -e 's/\(Install\)/Auto \1/'              \
				    -e "s/initrd.gz/initps.gz/"              \
				    -e "/menu label/a ${INS_STR}"          | \
				sed -e "${INS_ROW}r /dev/stdin" txt.cfg      \
				    -e '1i timeout 50'                       \
				> txt.cfg.temp
			else
				sed -n '/label install/,/append/p' txt.cfg | \
				sed -e 's/^\(label\) install/\1 autoinst/'   \
				    -e 's/\(Install\)/Auto \1/'              \
				    -e "s/initrd.gz/initps.gz/"              \
				    -e "/menu label/a ${INS_STR}"            \
				    -e '1i timeout 50'                       \
				> txt.cfg.temp
				cat txt.cfg >> txt.cfg.temp
			fi
			mv txt.cfg.temp txt.cfg
			# --- grub.cfg ----------------------------------------------------
			INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
			if [ ${INS_ROW} -ge 1 ]; then
				sed -n '/^menuentry .*['\''"]Install['\''\"]/,/^}/p' boot/grub/grub.cfg | \
				sed -e 's/\(Install\)/Auto \1/'                                           \
				    -e "s/initrd.gz/initps.gz/"                                           \
				    -e 's/\(--hotkey\)=./\1=a/'                                         | \
				sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                      | \
				sed -e 's/\(set default\)="1"/\1="0"/'                                    \
				    -e '1i set timeout=5'                                                 \
				    -e 's/\(set theme\)/# \1/g'                                           \
				    -e 's/\(set gfxmode\)/# \1/g'                                         \
				    -e 's/ vga=[0-9]*//g'                                                 \
				> grub.cfg.temp
				mv grub.cfg.temp boot/grub/grub.cfg
			else
				cat <<- _EOT_ >> boot/grub/grub.cfg
					menuentry 'Auto Install' {
					    set background_color=black
					    linux    /linux vga=788 --- quiet
					    initrd   /initps.gz
					}
_EOT_
			fi
			# -----------------------------------------------------------------
			fncPrint "--- make iso file $(fncString ${COL_SIZE} '-')"
			# -----------------------------------------------------------------
			rm -f md5sum.txt
			find . ! -name "md5sum.txt" ! -name "boot.catalog" ! -name "boot.cat" ! -name "isolinux.bin" ! -name "eltorito.img" -type f -exec md5sum {} \; > md5sum.txt
			# --- make iso file -----------------------------------------------
			if [ -f isolinux.bin ]; then
				ELT_BOOT=isolinux.bin
				ELT_CATA=boot.cat
			elif [ -f isolinux/isolinux.bin ]; then
				ELT_BOOT=isolinux/isolinux.bin
				ELT_CATA=isolinux/boot.cat
			elif [ -f boot/grub/i386-pc/eltorito.img ]; then
				ELT_BOOT=boot/grub/i386-pc/eltorito.img
				ELT_CATA=boot.catalog
			fi
			xorriso -as mkisofs \
			    -quiet \
			    -iso-level 3 \
			    -full-iso9660-filenames \
			    -volid "${VOLID}" \
			    -eltorito-boot "${ELT_BOOT}" \
			    -eltorito-catalog "${ELT_CATA}" \
			    -no-emul-boot -boot-load-size 4 -boot-info-table \
			    -isohybrid-mbr "${DIR_LINX}" \
			    -eltorito-alt-boot \
			    -e "${EFI_IMAG}" \
			    -no-emul-boot -isohybrid-gpt-basdat \
			    -output "../../${ISO_NAME}.iso" \
			    . > /dev/null
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" != "" ]; then
				LANG=C implantisomd5 "../../${ISO_NAME}.iso" > /dev/null
			fi
		popd > /dev/null
	popd > /dev/null
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	fncPrint "↑処理済：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '-')"
	return 0
}
# -----------------------------------------------------------------------------
fncRemaster () {
	# --- ARRAY_NAME ----------------------------------------------------------
	local ARRY_NAME=($1)											# 配列展開
	local CODE_NAME=()												# 配列宣言
	CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
	CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`	# DVDファイル名
	CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
	CODE_NAME[3]=${ARRY_NAME[3]}									# 定義ファイル
	# -------------------------------------------------------------------------
	fncPrint "↓処理中：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '-')"
	# --- DVD -----------------------------------------------------------------
	local DVD_NAME="${CODE_NAME[1]}"
	local DVD_URL="${CODE_NAME[2]}"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="${CODE_NAME[3]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}"
	# -------------------------------------------------------------------------
	for POINT in `mount | sed -n "/${WORK_DIRS}\/${CODE_NAME[1]}/ s/.*on[ \t]*\(.*\)[ \t]*type.*\$/\1/gp"`
	do
		set +e
		mountpoint -q "${POINT}"
		if [ $? -eq 0 ]; then
			if [ "`basename ${POINT}`" = "dev" ]; then
				umount -q "${POINT}/pts" || umount -q -lf "${POINT}/pts"
			fi
			umount -q "${POINT}" || umount -q -lf "${POINT}"
		fi
		set -e
	done
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
			set +e
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
		else
			set +e
			curl -L -R -S -s -f --connect-timeout 60 -I --dump-header "header.txt" "${DVD_URL}" > /dev/null || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
			local WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" != "${DVD_SIZE}" -o "${WEB_DATE}" != "${DVD_DATE}" ]; then
				fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
				set +e
				curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
				set -e
			fi
			if [ -f "header.txt" ]; then
				rm -f "header.txt"
			fi
		fi
															# Volume ID
		if [ "`${CMD_WICH} volname 2> /dev/null`" != "" ]; then
			local VOLID=`volname "../${DVD_NAME}.iso"`
		else
			local VOLID=`LANG=C blkid -s LABEL "../${DVD_NAME}.iso" | sed -e 's/.*="\(.*\)"/\1/g'`
		fi
		# --- mnt -> image ----------------------------------------------------
		fncPrint "--- copy DVD -> work directory $(fncString ${COL_SIZE} '-')"
		mount -r -o loop "../${DVD_NAME}.iso" mnt
		pushd mnt > /dev/null								# 作業用マウント先
			find . -depth -print | cpio -pdm --quiet ../image/
		popd > /dev/null
		umount mnt
		# --- image -----------------------------------------------------------
		pushd image > /dev/null								# 作業用ディスクイメージ
			# --- splash.png --------------------------------------------------
			case "${CODE_NAME[0]}" in
				"ubuntu" )
#					WALL_URL="http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
					WALL_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
					WALL_FILE="ubuntu_splash.png"
					if [ -f isolinux/txt.cfg ]; then
						if [ ! -f "../../../${WALL_FILE}" ]; then
							fncPrint "--- get ${WALL_FILE} $(fncString ${COL_SIZE} '-')"
							set +e
							curl -L -# -R -S -f --connect-timeout 3 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
							set -e
						else
							set +e
							curl -L -R -S -s -f --connect-timeout 3 -I --dump-header "header.txt" "${WALL_URL}" > /dev/null
							set -e
							WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
							WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
							WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
							FILE_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../../../${WALL_FILE}"`
							FILE_SIZE=`echo ${FILE_INFO} | awk '{print $5;}'`
							FILE_DATE=`echo ${FILE_INFO} | awk '{print $6;}'`
							if [ "${WEB_SIZE}" != "${FILE_SIZE}" ] || [ "${WEB_DATE}" != "${FILE_DATE}" ]; then
								fncPrint "--- get ${WALL_FILE} $(fncString ${COL_SIZE} '-')"
								set +e
								curl -L -# -R -S -f --connect-timeout 3 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
								set -e
							fi
							if [ -f "header.txt" ]; then
								rm -f "header.txt"
							fi
						fi
					fi
					;;
				* )	;;
			esac
			# --- preseed.cfg -> image ----------------------------------------
			case "${CODE_NAME[0]}" in
				"debian" | \
				"ubuntu" )
					EFI_IMAG="boot/grub/efi.img"
					ISO_NAME="${DVD_NAME}-preseed"
					# ---------------------------------------------------------
					mkdir -p "preseed"
					CFG_FILE=`echo ${CFG_NAME} | awk -F ',' '{print $1;}'`
					CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${CFG_FILE}~"`
					# --- preseed.cfg -> image --------------------------------
					if [ ! -f "../../../${CFG_FILE}" ]; then
						fncPrint "--- get ${CFG_FILE} $(fncString ${COL_SIZE} '-')"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_ADDR}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_FILE}" "preseed/preseed.cfg"
					# ---------------------------------------------------------
					case "${CODE_NAME[1]}" in
						debian-live-* )
							;;
						*canary*      | \
						*live-server* )						# --- get user-data
							EFI_IMAG="boot/grub/efi.img"
							ISO_NAME="${DVD_NAME}-nocloud"
							# -------------------------------------------------
							mkdir -p "nocloud"
							touch nocloud/user-data			# 必須
							touch nocloud/meta-data			# 必須
#							touch nocloud/vendor-data		# 省略可能
#							touch nocloud/network-config	# 省略可能
							CFG_FILE=`echo ${CFG_NAME} | awk -F ',' '{print $2;}'`
							CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${CFG_FILE}~"`
							if [ ! -f "../../../${CFG_FILE}" ]; then
								fncPrint "--- get ${CFG_FILE} $(fncString ${COL_SIZE} '-')"
								set +e
								curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_ADDR}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
								set -e
							fi
							cp --preserve=timestamps "../../../${CFG_FILE}" "nocloud/user-data"
							;;
						* )	;;
					esac
					;;
				"centos"       | \
				"fedora"       | \
				"rocky"        | \
				"miraclelinux" )	# --- get ks.cfg ----------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-kickstart"
					mkdir -p "kickstart"
					if [ ! -f "../../../${CFG_NAME}" ]; then
						fncPrint "--- get ${CFG_NAME} $(fncString ${COL_SIZE} '-')"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_NAME}" "kickstart/ks.cfg"
					case "${WORK_DIRS}" in
						*net* )
							sed -i kickstart/ks.cfg                   \
							    -e '/^cdrom/                  s/^/#/' \
							    -e '/^#url .* --url=/         s/^#//' \
							    -e '/^#url .* --mirrorlist=/  s/^#//' \
							    -e '/^#repo .* --mirrorlist=/ s/^#//'
							;;
						*dvd* )
							sed -i kickstart/ks.cfg                    \
							    -e '/^#cdrom/                 s/^#//'  \
							    -e '/^url .* --url=/          s/^/#/'  \
							    -e '/^url .* --mirrorlist=/   s/^/#/'  \
							    -e '/^#repo .* --mirrorlist=/ s/^#//'
							;;
					esac
					case "${CODE_NAME[1]}" in
						*Stream-8* )
							sed -i kickstart/ks.cfg                             \
							    -e '/mirrorlist/ s/\(release\)=8/\1=8-stream/g'
							;;
						*Stream-9* )
#							sed -i kickstart/ks.cfg                             \
#							    -e '/mirrorlist/ s/\(release\)=9/\1=9-stream/g'
							OLD_IFS=${IFS}
							case "${WORK_DIRS}" in
								*net* )
									IFS= INS_STR=$(
										cat <<- _EOT_ | sed -z 's/\n//g'
											url                         --url=http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/\\n
											#repo --name="AppStream" --baseurl=http://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
_EOT_
									)
									;;
								*dvd* )
									IFS= INS_STR=$(
										cat <<- _EOT_ | sed -z 's/\n//g'
											#url                         --url=http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/\\n
											#repo --name="AppStream" --baseurl=http://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
_EOT_
									)
									;;
							esac
							IFS=${OLD_IFS}
							sed -i kickstart/ks.cfg                         \
							    -e 's/\(version\)=RHEL8/\1=RHEL9/'          \
							    -e '/url .*--mirrorlist=/d'                 \
							    -e '/repo .*--mirrorlist=/d'                \
							    -e "/Use network installation/a ${INS_STR}" \
							    -e '/epel-release-.*$/ s/8/9/g'             \
							    -e '/remi-release-.*$/ s/8/9/g'
							;;
						Fedora-* )		# comps.xml 参照
							VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '-' '{print $5;}')
							sed -i kickstart/ks.cfg                                            \
							    -e "/url .*--mirrorlist/ s/\(fedora\)-[0-9]*/\1-${VER_NUM}/g"  \
							    -e "/repo .*--mirrorlist/ s/\(fedora\)-[0-9]*/\1-${VER_NUM}/g" \
							    -e '/%anaconda/,/%end/ s/^/#/g'                                \
							    -e '/%packages/,/%end/ s/\(basic-desktop\)-environment/\1/g'
							;;
					esac
					;;
				"suse")	# --- get autoinst.xml --------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-autoyast"
					mkdir -p "autoyast"
					if [ ! -f "../../../${CFG_NAME}" ]; then
						fncPrint "--- get ${CFG_NAME} $(fncString ${COL_SIZE} '-')"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_NAME}" "autoyast/autoinst.xml"
					case "${CODE_NAME[1]}" in
						*Leap* )
							VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '-' '{print $3;}')
							sed -i autoyast/autoinst.xml                                                 \
							    -e "/<media_url>/ s~\(update/leap\)/.*/\(oss\)~\1/${VER_NUM}/\2~"        \
							    -e "/<media_url>/ s~\(distribution/leap\)/.*/\(repo\)~\1/${VER_NUM}/\2~" \
							    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~'
							;;
						*Tumbleweed* )
							sed -i autoyast/autoinst.xml                                        \
							    -e '/<media_url>/ s~update/leap/.*/oss~update/tumbleweed~'      \
							    -e '/<media_url>/ s~distribution/leap/.*/repo~tumbleweed/repo~' \
							    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~'              \
							    -e 's/eth0/ens160/g'
							;;
					esac
					;;
				* )	;;
			esac
			# --- Get EFI Image -----------------------------------------------
			if [ ! -f ${EFI_IMAG} ]; then
				ISO_SKIPS=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $2;}'`
				ISO_COUNT=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $4;}'`
				dd if="../../${DVD_NAME}.iso" of=${EFI_IMAG} bs=512 skip=${ISO_SKIPS} count=${ISO_COUNT} status=none
			fi
			# --- mrb:txt.cfg / efi:grub.cfg ----------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )	# ･････････････････････････････････････････････････
					case "${CODE_NAME[1]}" in
						*-live-* )
							# === 日本語化 ====================================
							INS_CFG="locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp"
							# --- grub.cfg --------------------------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Debian GNU\/Linux.*\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(Debian GNU\/Linux.*)\)/\1 for Japanese language/'                      \
							    -e "s~\(components\)~\1 ${INS_CFG}~"                               | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       \
							    -e '1i set default=0'                                                \
							    -e '1i set timeout=5'                                                \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- menu.cfg --------------------------------------------------------
							INS_ROW=$((`sed -n '/^LABEL/ =' isolinux/menu.cfg | head -n 1`-1))
							INS_STR=`sed -n 's/LABEL \(Debian GNU\/Linux Live.*\)/\1 for Japanese language/p' isolinux/menu.cfg`
							sed -n '/LABEL Debian GNU\/Linux Live.*/,/^$/p' isolinux/menu.cfg | \
							sed -e "s~\(LABEL\) .*~\1 ${INS_STR}~"                              \
							    -e "s~\(SAY\) .*~\1 \"${INS_STR}\.\.\.\"~"                      \
							    -e "s~\(APPEND .* components\) \(.*$\)~\1 ${INS_CFG} \2~"     | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                 | \
							sed -e "s~^\(DEFAULT\) .*$~\1 ${INS_STR}~"                          \
							> menu.cfg
							mv menu.cfg isolinux/
							# ---------------------------------------------------------------------
							sed -i isolinux/isolinux.cfg     \
							    -e 's/\(timeout\).*$/\1 50/'
							# === preseed =====================================
							INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
							# --- grub.cfg ----------------------------------------------------
							INS_ROW=$((`sed -n '/^menuentry "Graphical Debian Installer"/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry "Graphical Debian Installer"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(menuentry "Graphical Debian\) \(Installer"\)/\1 Auto \2/'         \
							    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                                   | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                            \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- menu.cfg ----------------------------------------------------
							INS_ROW=$((`sed -n '/^LABEL Graphical Debian Installer/ =' isolinux/menu.cfg | head -n 1`-1))
							sed -n '/LABEL Graphical Debian Installer$/,/^$/p' isolinux/menu.cfg | \
							sed -e 's/^\(LABEL Graphical Debian\) \(Installer\)/\1 Auto \2/'       \
							    -e "s/\(APPEND.*\$\)/\1 ${INS_CFG}/"                             | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                      \
							> menu.cfg
							mv menu.cfg isolinux/
							# --- success_command -----------------------------
							OLD_IFS=${IFS}
							IFS=$'\n'
							# --- packages ------------------------------------
							LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' preseed/preseed.cfg  | \
							           sed -z 's/\n//g'                                                          | \
							           sed -e 's/.* multiselect *//'                                               \
							               -e 's/[,|\\\\]//g'                                                      \
							               -e 's/\t/ /g'                                                           \
							               -e 's/  */ /g'                                                          \
							               -e 's/^ *//'`
							LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' preseed/preseed.cfg | \
							           sed -z 's/\n//g'                                                          | \
							           sed -e 's/.* string *//'                                                    \
							               -e 's/[,|\\\\]//g'                                                      \
							               -e 's/\t/ /g'                                                           \
							               -e 's/  */ /g'                                                          \
							               -e 's/^ *//'`
							IFS=${OLD_IFS}
							;;
						* )
							INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
							# --- grub.cfg --------------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry .*'\''Install'\''/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(Install\)/Auto \1/'                                    \
							    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                          \
							    -e 's/\(--hotkey\)=./\1=a/'                                  | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg               | \
							sed -e 's/\(set default\)="1"/\1="0"/'                             \
							    -e '1i set timeout=5'                                          \
							    -e 's/\(set theme\)/# \1/g'                                    \
							    -e 's/\(set gfxmode\)/# \1/g'                                  \
							    -e 's/ vga=[0-9]*//g'                                          \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- txt.cfg ---------------------------------------------
							sed -i isolinux/isolinux.cfg     \
							    -e 's/\(timeout\).*$/\1 50/'
							sed -i isolinux/prompt.cfg       \
							    -e 's/\(timeout\).*$/\1 50/'
							sed -i isolinux/gtk.cfg        \
							    -e '/^.*menu default.*$/d'
							sed -i isolinux/txt.cfg        \
							    -e '/^.*menu default.*$/d'
							INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
							INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | head -n 1 | sed -e 's/\(^.*menu\) label.*$/\1 default/'`"
							if [ ${INS_ROW} -ge 1 ]; then
								sed -n '/label install/,/^$/p' isolinux/txt.cfg  | \
								sed -e 's/^\(label\) install/\1 autoinst/'         \
								    -e 's/\(Install\)/Auto \1/'                    \
								    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"           \
								    -e "/menu label/a  ${INS_STR}"               | \
								sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg   \
								    -e 's/\(timeout\).*$/\1 50/'                   \
								> txt.cfg
							else
								sed -n '/label install/,/^$/p' isolinux/txt.cfg  | \
								sed -e 's/^\(label\) install/\1 autoinst/'         \
								    -e 's/\(Install\)/Auto \1/'                    \
								    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"           \
								    -e "/menu label/a  ${INS_STR}"                 \
								> txt.cfg
								cat isolinux/txt.cfg >> txt.cfg
							fi
							mv txt.cfg isolinux/
							;;
					esac
					case "${CODE_NAME[1]}" in
						*-7.*        | \
						*-8.*        )
							sed -i "preseed/preseed.cfg"                                                                               \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/hostname\).*$/\1 string archive.debian.org/'                     \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/directory\).*$/\1 string \/debian-archive\/debian/'              \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror/http/mirror select\).*$/\1 select archive.debian.org/'                  \
							    -e 's/\(^[ \t]*d-i[ \t]*apt-setup\/services-select\).*$/\1 multiselect updates/'
#							    -e 's/\(^[ \t]*d-i[ \t]*netcfg\/get_nameservers\)[ \t]*[A-Za-z]*[ \t]*\(.*\)$/\1 string 127.0.0.1 \2/'
							;;
						*-9.*        )
							;;
						*-10.*       )
							;;
						*-11.*       | \
						*-12.*       | \
						*-bullseye-* | \
						*-bookworm-* | \
						*-testing-*  )
#							sed -i "preseed/preseed.cfg"                                                               \
#							    -e 's/#[ \t]\(d-i[ \t]*preseed\/late_command string\)/  \1/'                           \
#							    -e 's/#[ \t]\([ \t]*in-target --pass-stdout systemctl disable connman.service\)/  \1/'
							sed -i "preseed/preseed.cfg" \
							    -e '/network-manager/d'
							;;
						* )	;;
					esac
					# ---------------------------------------------------------
					chmod 444 "preseed/preseed.cfg"
					;;
				"ubuntu" )	# ･････････････････････････････････････････････････
					if [ -f isolinux/isolinux.cfg ]; then
						sed -i isolinux/isolinux.cfg     \
						    -e 's/\(timeout\).*$/\1 50/'
					fi
					if [ -f isolinux/prompt.cfg ]; then
						sed -i isolinux/prompt.cfg       \
						    -e 's/\(timeout\).*$/\1 50/'
					fi
					case "${CODE_NAME[1]}" in
						ubuntu-16.04* )
							sed -i "preseed/preseed.cfg"       \
							    -e 's/network-manager[,| ]*//' \
							    -e 's/fonts-noto-cjk-extra//'  \
							    -e 's/gnome-user-docs-ja//'
							;;
						ubuntu-18.04* )
							sed -i "preseed/preseed.cfg"              \
							    -e 's/network-manager[,| ]*//'        \
							    -e 's/ubuntu-desktop-minimal[,| ]*//' \
							    -e 's/[,| ]*$//'
							if [ -f "nocloud/user-data" ]; then
								sed -i "nocloud/user-data"  \
								    -e '/bind9-utils/d'     \
								    -e '/bind9-dnsutils/d'  \
								    -e '/fonts-noto-core/d'
							fi
							;;
						ubuntu-21.10* | \
						impish-*      )
							sed -i "preseed/preseed.cfg"                      \
							    -e 's/gnome-getting-started-docs-ja[,| ]*//'  \
							    -e 's/[,| ]*$//'
							;;
						ubuntu-22.04* | \
						jammy-*       )
							sed -i "preseed/preseed.cfg"                      \
							    -e 's/inxi[,| ]*//'                           \
							    -e 's/gnome-getting-started-docs-ja[,| ]*//'  \
							    -e 's/[,| ]*$//'
							;;
						* )	;;
					esac
					case "${CODE_NAME[1]}" in
						*canary* | \
						*live*   | \
						*server* )
							case "${CODE_NAME[1]}" in
								*canary* | \
								*live*   ) INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\"" ;;
								*server* ) INS_CFG="file=\/cdrom\/preseed\/preseed.cfg auto=true"    ;;
								* )	;;
							esac
							INS_CFG+=" debian-installer\/language=ja keyboard-configuration\/layoutcode\?=jp keyboard-configuration\/modelcode\?=jp106"
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry \".*\(Install \)*Ubuntu\( Server\)*\"/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \".*\(Install \)*Ubuntu\( Server\)*\"/,/^}/p' boot/grub/grub.cfg | \
							sed -n '0,/\}/p'                                                                     | \
							sed -e 's/\".*\(Install \)*\(Ubuntu.*\)\"/\"Auto Install \2\"/'                        \
							    -e 's/file.*seed//'                                                                \
							    -e "s/\(vmlinuz\) */\1 ${INS_CFG} /"                                               \
							    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/'                | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                                   | \
							sed -e '1i set timeout=5'                                                              \
							    -e 's/\(set default\)="1"/\1="0"/'                                                 \
							    -e 's/\(set timeout\).*$/\1=5/'                                                    \
							    -e 's/\(set gfxmode\)/# \1/g'                                                      \
							    -e 's/ vga=[0-9]*//g'                                                              \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- txt.cfg -------------------------------------
							if [ -f isolinux/txt.cfg ]; then
								INS_ROW=$((`sed -n '/^label \(install\|live\)$/ =' isolinux/txt.cfg | head -n 1`-1))
								sed -n '/label \(install\|live\)$/,/append/p' isolinux/txt.cfg | \
								sed -e 's/^\(label\).*/\1 autoinst/'                             \
								    -e 's/\(Install\)/Auto \1/'                                  \
								    -e 's/file.*seed//'                                          \
								    -e "s/\(append\) */\1 ${INS_CFG//\"/} /"                   | \
								sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg               | \
								sed -e 's/\(default\) .*/\1 autoinst/'                           \
								    -e 's/\(set gfxmode\)/# \1/g'                                \
								    -e 's/ vga=[0-9]*//g'                                        \
								> txt.cfg
								mv txt.cfg isolinux/
								# --- isolinux.cfg ----------------------------
								sed -i isolinux/isolinux.cfg         \
								    -e 's/\(timeout\) .*/\1 50/'     \
								    -e '/ui gfxboot bootlogo/d'
								# --- menu.cfg --------------------------------
								sed -i isolinux/menu.cfg             \
								    -e '/menu hshift .*/d'           \
								    -e '/menu width .*/d'            \
								    -e '/menu margin .*/d'
								# --- stdmenu.cfg -----------------------------
								sed -i isolinux/stdmenu.cfg          \
								    -e 's/\(menu vshift\) .*/\1 9/'  \
								    -e '/menu rows .*/d'             \
								    -e '/menu helpmsgrow .*/d'       \
								    -e '/menu cmdlinerow .*/d'       \
								    -e '/menu timeoutrow .*/d'       \
								    -e '/menu tabmsgrow .*/d'
								# --- splash.png ------------------------------
								cp -p ../../../${WALL_FILE} isolinux/splash.png
								chmod 444 "isolinux/splash.png"
							fi
							;;
						*desktop* )							# --- preseed.cfg -
							# === 日本語化 ====================================
							INS_CFG="debian-installer/language=ja keyboard-configuration/layoutcode?=jp keyboard-configuration/modelcode?=jp106"
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Try Ubuntu.*\"\|\"Ubuntu\"\|\"Try or Install Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\"\(Try Ubuntu.*\)\"/\"\1 for Japanese language\"/'                                            \
							    -e 's/\"\(Ubuntu\)\"/\"\1 for Japanese language\"/'                                                  \
							    -e 's/\"\(Try or Install Ubuntu\)\"/\"\1 for Japanese language\"/'                                 | \
							sed -e "s~\(file\)~${INS_CFG} \1~"                                                                     | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                                                     | \
							sed -e 's/\(set default\)="1"/\1="0"/'                                                                   \
							    -e 's/\(set timeout\).*$/\1=5/'                                                                      \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- txt.cfg -------------------------------------
							if [ -f isolinux/txt.cfg ]; then
								INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
								sed -n '/label live$/,/append/p' isolinux/txt.cfg            | \
								sed -e 's/^\(label\) \(.*\)/\1 \2_for_japanese_language/'      \
								    -e 's/\^\(Try Ubuntu.*\)/\1 for \^Japanese language/'    | \
								sed -e "s~\(file\)~${INS_CFG} \1~"                           | \
								sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg             | \
								sed -e 's/^\(default\) .*$/\1 live_for_japanese_language/'     \
								> txt.cfg
								mv txt.cfg isolinux/
								# --- isolinux.cfg ----------------------------
								sed -i isolinux/isolinux.cfg         \
								    -e 's/\(timeout\) .*/\1 50/'     \
								    -e '/ui gfxboot bootlogo/d'
								# --- menu.cfg --------------------------------
								sed -i isolinux/menu.cfg             \
								    -e '/menu hshift .*/d'           \
								    -e '/menu width .*/d'            \
								    -e '/menu margin .*/d'
								# --- stdmenu.cfg -----------------------------
								sed -i isolinux/stdmenu.cfg          \
								    -e 's/\(menu vshift\) .*/\1 9/'  \
								    -e '/menu rows .*/d'             \
								    -e '/menu helpmsgrow .*/d'       \
								    -e '/menu cmdlinerow .*/d'       \
								    -e '/menu timeoutrow .*/d'       \
								    -e '/menu tabmsgrow .*/d'
								# --- splash.png ------------------------------
								cp -p ../../../${WALL_FILE} isolinux/splash.png
								chmod 444 "isolinux/splash.png"
							fi
							# === preseed =====================================
							INS_CFG="file=\/cdrom\/preseed\/preseed.cfg auto=true"
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry "Try Ubuntu without installing"\|menuentry "Ubuntu"\|menuentry "Ubuntu (safe graphics)"/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Install\|Ubuntu\"/,/^}/p' boot/grub/grub.cfg    | \
							sed -e 's/\"Install \(Ubuntu\)\"/\"Auto Install \1\"/'                  \
							    -e 's/\"\(Ubuntu\)\"/\"Auto Install \1\"/'                          \
							    -e 's/\"Try or Install \(Ubuntu\)\"/\"Auto Install \1\"/'           \
							    -e 's/file.*seed//'                                                 \
							    -e "s/\(vmlinuz\) */\1 ${INS_CFG} /"                                \
							    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                    | \
							sed -e 's/\(set default\)="1"/\1="0"/'                                  \
							    -e 's/\(set timeout\).*$/\1=5/'                                     \
							    -e 's/\(set gfxmode\)/# \1/g'                                       \
							    -e 's/ vga=[0-9]*//g'                                               \
							> grub.cfg
							mv grub.cfg boot/grub/
							# --- txt.cfg -------------------------------------
							if [ -f isolinux/txt.cfg ]; then
								INS_ROW=$((`sed -n '/^label live$/ =' isolinux/txt.cfg | head -n 1`-1))
								sed -n '/label live-install$/,/append/p' isolinux/txt.cfg             | \
								sed -e 's/^\(label\).*/\1 autoinst/'                                    \
								    -e 's/\(Install\)/Auto \1/'                                         \
								    -e 's/file.*seed//'                                                 \
								    -e "s/\(append\) */\1 ${INS_CFG//\"/} /"                            \
								    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
								sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg                        \
								> txt.cfg
								mv txt.cfg isolinux/
							fi
							# --- success_command -----------------------------
							cat <<- '_EOT_' | sed 's/^ *//g' > preseed/sub_success_command.sh
								#!/bin/bash
								#	set -x													# コマンドと引数の展開を表示
								#	set -n													# 構文エラーのチェック
								#	set -eu													# ステータス0以外と未定義変数の参照で終了
								#	set -o ignoreof											# Ctrl+Dで終了しない
								 	trap 'exit 1' 1 2 3 15
								# IPv4 netmask変換処理 --------------------------------------------------------
								fncIPv4GetNetmaskBits () {
								 	local INP_ADDR
								 	local -a OUT_ARRY=()
								 	# -------------------------------------------------------------------------
								 	for INP_ADDR in "$@"
								 	do
								 		OUT_ARRY+=`echo ${INP_ADDR} | awk -F '.' '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
								 	done
								 	echo "${OUT_ARRY[@]}"
								}
								# --- packages ----------------------------------------------------------------
								 	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg  | \
								 	           sed -z 's/\n//g'                                                                 | \
								 	           sed -e 's/.* multiselect *//'                                                      \
								 	               -e 's/[,|\\\\]//g'                                                             \
								 	               -e 's/\t/ /g'                                                                  \
								 	               -e 's/  */ /g'                                                                 \
								 	               -e 's/^ *//'`
								 	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg | \
								 	           sed -z 's/\n//g'                                                                 | \
								 	           sed -e 's/.* string *//'                                                           \
								 	               -e 's/[,|\\\\]//g'                                                             \
								 	               -e 's/\t/ /g'                                                                  \
								 	               -e 's/  */ /g'                                                                 \
								 	               -e 's/^ *//'`
								 	# -------------------------------------------------------------------------
								 	sed -i.orig /target/etc/apt/sources.list -e '/cdrom/ s/^ *(deb)/# 1/g'
								 	in-target apt -qq    update
								 	in-target apt -qq -y full-upgrade
								 	in-target apt -qq -y install ${LIST_PACK}
								 	in-target tasksel install ${LIST_TASK}
								 	if [ -f /target/usr/lib/systemd/system/connman.service ]; then
								 		in-target systemctl disable connman.service
								 	fi
								# --- network -----------------------------------------------------------------
								 	IPV4_DHCP=`awk 'BEGIN {result="true";} !/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {if ($4=="true") result="false";} END {print result;}' /cdrom/preseed/preseed.cfg`
								 	if [ "${IPV4_DHCP}" != "true" ]; then
								 		ENET_NICS=`awk '!/#/&&/netcfg\/choose_interface/ {print $4;}' /cdrom/preseed/preseed.cfg`
								 		if [ "${ENET_NICS}" = "auto" -o "${ENET_NICS}" = "" ]; then
								 			ENET_NIC1=ens160
								 		else
								 			ENET_NIC1=${ENET_NICS}
								 		fi
								 		IPV4_ADDR=`awk '!/#/&&/netcfg\/get_ipaddress/    {print $4;}' /cdrom/preseed/preseed.cfg`
								 		IPV4_MASK=`awk '!/#/&&/netcfg\/get_netmask/      {print $4;}' /cdrom/preseed/preseed.cfg`
								 		IPV4_GWAY=`awk '!/#/&&/netcfg\/get_gateway/      {print $4;}' /cdrom/preseed/preseed.cfg`
								 		IPV4_NAME=`awk '!/#/&&/netcfg\/get_nameservers/  {print $4;}' /cdrom/preseed/preseed.cfg`
								 		NWRK_WGRP=`awk '!/#/&&/netcfg\/get_domain/       {print $4;}' /cdrom/preseed/preseed.cfg`
								 		IPV4_BITS=`fncIPv4GetNetmaskBits "${IPV4_MASK}"`
								 		# ---------------------------------------------------------------------
								 		if [ -d /target/etc/netplan ]; then
								 			if [ -z "$(ls /target/etc/NetworkManager/system-connections/)" ]; then
								 				cat <<- _EOT_ > /target/etc/netplan/99-network-manager-static.yaml
								 					network:
								 					  version: 2
								 					  renderer: NetworkManager
								 					  ethernets:
								 					    ${ENET_NIC1}:
								 					      dhcp4: false
								 					      addresses: [ ${IPV4_ADDR}/${IPV4_BITS} ]
								 					      gateway4: ${IPV4_GWAY}
								 					      nameservers:
								 					          search: [ ${NWRK_WGRP} ]
								 					          addresses: [ ${IPV4_NAME} ]
								 					#     dhcp6: true
								 					#     ipv6-privacy: true
								 _EOT_
								 			fi
								 		else
								 			cat <<- _EOT_ >> /target/etc/network/interfaces
								 				
								 				allow-hotplug ${ENET_NIC1}
								 				iface ${ENET_NIC1} inet static
								 				    address ${IPV4_ADDR}
								 				    netmask ${IPV4_MASK}
								 				    gateway ${IPV4_GWAY}
								 				    dns-nameservers ${IPV4_NAME}
								 				    dns-search ${NWRK_WGRP}
								 _EOT_
								 		fi
								 	fi
								# --- exit --------------------------------------------------------------------
								 	exit 0
_EOT_
							LATE_CMD="\\      /cdrom/preseed/sub_success_command.sh;"
							# --- success_command 変更 ------------------------
							sed -i "preseed/preseed.cfg"                       \
							    -e '/ubiquity\/success_command/ s/#/ /g'       \
							    -e '/ubiquity\/success_command/ s/[,|\\\\]//g' \
							    -e '/ubiquity\/success_command/ s/$/ \\/g'     \
							    -e "/ubiquity\/success_command/a ${LATE_CMD}"
							;;
						* )	;;
					esac
					# ---------------------------------------------------------
					if [ -f "nocloud/user-data"              ]; then chmod 444 "nocloud/user-data";              fi
					if [ -f "nocloud/meta-data"              ]; then chmod 444 "nocloud/meta-data";              fi
					if [ -f "nocloud/vendor-data"            ]; then chmod 444 "nocloud/vendor-data";            fi
					if [ -f "nocloud/network-config"         ]; then chmod 444 "nocloud/network-config";         fi
					if [ -f "preseed/preseed.cfg"            ]; then chmod 444 "preseed/preseed.cfg";            fi
					if [ -f "preseed/sub_success_command.sh" ]; then chmod 544 "preseed/sub_success_command.sh"; fi
					;;
				"centos" )	# ･････････････････････････････････････････････････
					INS_CFG="inst.ks=cdrom:\/kickstart\/ks.cfg"
					# --- isolinux.cfg ----------------------------------------
					INS_ROW=$((`sed -n '/^label/ =' isolinux/isolinux.cfg | head -n 1`-1))
					INS_STR="\\`sed -n '/menu default/p' isolinux/isolinux.cfg`"
					sed -n '/label linux/,/^$/p' isolinux/isolinux.cfg    | \
					sed -e 's/^\(label\) linux/\1 autoinst/'                \
					    -e 's/\(Install\)/Auto \1/'                         \
					    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"                \
					    -e "/menu label/a  ${INS_STR}"                    | \
					sed -e "${INS_ROW}r /dev/stdin" isolinux/isolinux.cfg   \
					    -e '/menu default/{/menu default/d}'                \
					    -e 's/\(timeout\).*$/\1 50/'                        \
					> isolinux.cfg
					mv isolinux.cfg isolinux/
					# --- grub.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry '\''Install/,/^}/p' EFI/BOOT/grub.cfg | \
					sed -e 's/\(Install\)/Auto \1/'                             \
					    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                | \
					sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg         | \
					sed -e 's/\(set default\)="1"/\1="0"/'                      \
					    -e 's/\(set timeout\).*$/\1=5/'                         \
					> grub.cfg
					mv grub.cfg EFI/BOOT/
					# ---------------------------------------------------------
					chmod 444 "kickstart/ks.cfg"
					;;
				"fedora" )	# ･････････････････････････････････････････････････
					INS_CFG="inst.ks=cdrom:\/kickstart\/ks.cfg"
					# --- isolinux.cfg ----------------------------------------
					INS_ROW=$((`sed -n '/^label/ =' isolinux/isolinux.cfg | head -n 1`-1))
					INS_STR="\\`sed -n '/menu default/p' isolinux/isolinux.cfg`"
					sed -n '/label linux/,/^$/p' isolinux/isolinux.cfg    | \
					sed -e 's/^\(label\) linux/\1 autoinst/'                \
					    -e 's/\(Install\)/Auto \1/'                         \
					    -e "s/\(append.*$\)/\1 ${INS_CFG}/"                 \
					    -e "/menu label/a  ${INS_STR}"                    | \
					sed -e "${INS_ROW}r /dev/stdin" isolinux/isolinux.cfg   \
					    -e '/menu default/{/menu default/d}'                \
					    -e 's/\(timeout\).*$/\1 50/'                        \
					> isolinux.cfg
					mv isolinux.cfg isolinux/
					# --- grub.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry '\''Install/,/^}/p' EFI/BOOT/grub.cfg | \
					sed -e 's/\(Install\)/Auto \1/'                             \
					    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                | \
					sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg         | \
					sed -e 's/\(set default\)="1"/\1="0"/'                      \
					    -e 's/\(set timeout\).*$/\1=5/'                         \
					> grub.cfg
					mv grub.cfg EFI/BOOT/
					# ---------------------------------------------------------
					chmod 444 "kickstart/ks.cfg"
					;;
				"rocky" )	# ･････････････････････････････････････････････････
					INS_CFG="inst.ks=cdrom:\/kickstart\/ks.cfg"
					# --- isolinux.cfg ----------------------------------------
					INS_ROW=$((`sed -n '/^label/ =' isolinux/isolinux.cfg | head -n 1`-1))
					INS_STR="\\`sed -n '/menu default/p' isolinux/isolinux.cfg`"
					sed -n '/label linux/,/^$/p' isolinux/isolinux.cfg    | \
					sed -e 's/^\(label\) linux/\1 autoinst/'                \
					    -e 's/\(Install\)/Auto \1/'                         \
					    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"                \
					    -e "/menu label/a  ${INS_STR}"                    | \
					sed -e "${INS_ROW}r /dev/stdin" isolinux/isolinux.cfg   \
					    -e '/menu default/{/menu default/d}'                \
					    -e 's/\(timeout\).*$/\1 50/'                        \
					> isolinux.cfg
					mv isolinux.cfg isolinux/
					# --- grub.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry '\''Install/,/^}/p' EFI/BOOT/grub.cfg | \
					sed -e 's/\(Install\)/Auto \1/'                             \
					    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                 | \
					sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg         | \
					sed -e 's/\(set default\)="1"/\1="0"/'                      \
					    -e 's/\(set timeout\).*$/\1=5/'                         \
					> grub.cfg
					mv grub.cfg EFI/BOOT/
					# ---------------------------------------------------------
					chmod 444 "kickstart/ks.cfg"
					;;
				"miraclelinux" ) # ････････････････････････････････････････････
					INS_CFG="inst.ks=cdrom:\/kickstart\/ks.cfg"
					# --- isolinux.cfg ----------------------------------------
					INS_ROW=$((`sed -n '/^label/ =' isolinux/isolinux.cfg | head -n 1`-1))
					INS_STR="\\`sed -n '/menu default/p' isolinux/isolinux.cfg`"
					sed -n '/label linux/,/^$/p' isolinux/isolinux.cfg    | \
					sed -e 's/^\(label\) linux/\1 autoinst/'                \
					    -e 's/\(Install\)/Auto \1/'                         \
					    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"                \
					    -e "/menu label/a  ${INS_STR}"                    | \
					sed -e "${INS_ROW}r /dev/stdin" isolinux/isolinux.cfg   \
					    -e '/menu default/{/menu default/d}'                \
					    -e 's/\(timeout\).*$/\1 50/'                        \
					> isolinux.cfg
					mv isolinux.cfg isolinux/
					# --- grub.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry '\''Install/,/^}/p' EFI/BOOT/grub.cfg | \
					sed -e 's/\(Install\)/Auto \1/'                             \
					    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                 | \
					sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg         | \
					sed -e 's/\(set default\)="1"/\1="0"/'                      \
					    -e 's/\(set timeout\).*$/\1=5/'                         \
					> grub.cfg
					mv grub.cfg EFI/BOOT/
					# ---------------------------------------------------------
					chmod 444 "kickstart/ks.cfg"
					;;
				"suse" )	# ･････････････････････････････････････････････････
					INS_CFG="autoyast=cd:\/autoyast\/autoinst\.xml ifcfg=e*=dhcp"
					# --- isolinux.cfg ----------------------------------------
					sed -n '/#[ \t][ \t]*install/,/append/p' boot/x86_64/loader/isolinux.cfg | \
					sed -e 's/\(install\)/auto \1/'                                            \
					    -e 's/\(label\) linux/\1 autoinst/'                                    \
					    -e "/append/ s/\$/ ${INS_CFG}/"                                      | \
					sed -e '/^default.*$/r /dev/stdin' boot/x86_64/loader/isolinux.cfg       | \
					sed -e 's/^\(default\) harddisk$/\1=autoinst\n/'                           \
					    -e 's/\(timeout\).*$/\1 50/'                                           \
					> isolinux.cfg
					mv isolinux.cfg boot/x86_64/loader/
					# --- grub.cfg --------------------------------------------
					case "${CODE_NAME[1]}" in
						*15.2* )
							sed -n '/menuentry[ \t][ \t]*'\''Installation'\''.*{/,/}/p' EFI/BOOT/grub.cfg             | \
							sed -e 's/^}/}\n/'                                                                          \
							    -e 's/'\''\(Installation\)'\''/'\''Auto \1'\''/'                                        \
							    -e "/linuxefi/ s/\$/ ${INS_CFG}/"                                                     | \
							sed -e '/\# look for an installed SUSE system and boot it/r /dev/stdin' EFI/BOOT/grub.cfg | \
							sed -e 's/^\(default\)=1$/\1=0/'                                                            \
							    -e 's/\(timeout\).*$/\1=5/'                                                             \
							> grub.cfg
							mv grub.cfg EFI/BOOT/
							;;
						* )
							INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | head -n 1`-1))
							sed -n '/menuentry[ \t][ \t]*'\''Installation'\''.*{/,/}/p' EFI/BOOT/grub.cfg             | \
							sed -e 's/^}/}\n/'                                                                          \
							    -e 's/'\''\(Installation\)'\''/'\''Auto \1'\''/'                                        \
							    -e "/linux/ s/\$/ ${INS_CFG}/"                                                        | \
							sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg                                         | \
							sed -e 's/^\(default\)=1$/\1=0/'                                                            \
							    -e 's/\(timeout\).*$/\1=5/'                                                             \
							> grub.cfg
							mv grub.cfg EFI/BOOT/
							;;
					esac
					# ---------------------------------------------------------
					chmod 444 "autoyast/autoinst.xml"
					;;
				* )	;;
			esac
			case "${WORK_DIRS}" in
				"live-custom" )
					# --- customize live disc [chroot] ------------------------
					fncPrint "--- customize live disc [chroot] $(fncString ${COL_SIZE} '-')"
					ISO_NAME="${DVD_NAME}-custom-preseed"
					pushd ../ > /dev/null							# 作業用ディレクトリー
						case "${CODE_NAME[0]}" in
							"debian"       | \
							"ubuntu"       )		# ･････････････････････････
								if [ -d ./image/live/ ]; then
									# --- live configure ----------------------------------
									#LIVE_CONFIG_CMDLINE=パラメータ1 パラメータ2 ... パラメータn									# この変数はブートローダのコマンドラインに相当します。
									#LIVE_CONFIG_COMPONENTS=構成要素1,構成要素2, ... 構成要素n										# この変数は「live-config.components=構成要素1,構成要素2, ...  構成要素n」パラメータに相当します。
									#LIVE_CONFIG_NOCOMPONENTS=構成要素1,構成要素2, ... 構成要素n									# この変数は「live-config.nocomponents=構成要素1,構成要素2,  ... 構成要素n」パラメータに相当します。
									#LIVE_DEBCONF_PRESEED=filesystem|medium|URL1|URL2| ... |URLn									# この変数は「live-config.debconf-preseed=filesystem|medium|URL1|URL2|  ...  |URLn」パラメータに相当します。
									#LIVE_HOSTNAME=ホスト名																			# この変数は「live-config.hostname=ホスト名」パラメータに相当します。
									#LIVE_USERNAME=ユーザ名																			# この変数は「live-config.username=ユーザ名」パラメータに相当します。
									#LIVE_USER_DEFAULT_GROUPS=グループ1,グループ2 ... グループn										# この変数は「live-config.user-default-groups="グループ1,グループ2  ... グループn"」パラメータに相当します。
									#LIVE_USER_FULLNAME="ユーザのフルネーム"														# この変数は「live-config.user-fullname="ユーザのフルネーム"」パラメータに相当します。
									#LIVE_LOCALES=ロケール1,ロケール2 ... ロケールn													# この変数は「live-config.locales=ロケール1,ロケール2 ...  ロケールn」パラメータに相当します。
									#LIVE_TIMEZONE=タイムゾーン																		# この変数は「live-config.timezone=タイムゾーン」パラメータに相当します。
									#LIVE_KEYBOARD_MODEL=キーボードの種類															# この変数は「live-config.keyboard-model=キーボードの種類」パラメータに相当します。
									#LIVE_KEYBOARD_LAYOUTS=キーボードレイアウト1,キーボードレイアウト2  ...  キーボードレイアウトn	# この変数は「live-config.keyboard-layouts=キーボードレイアウト1,キーボードレイアウト2... キーボードレイアウトn」パラメータに相当します。
									#LIVE_KEYBOARD_VARIANTS=キーボード配列1,キーボード配列2 ... キーボード配列n						# この変数は「live-config.keyboard-variants=キーボード配列1,キーボード配列2 ... キーボード配列n」パラメータに相当します。
									#LIVE_KEYBOARD_OPTIONS=キーボードオプション														# この変数は「live-config.keyboard-options=キーボードオプション」パラメータに相当します。
									#LIVE_SYSV_RC=サービス1,サービス2 ... サービスn													# この変数は「live-config.sysv-rc=サービス1,サービス2  ... サービスn」パラメータに相当します。
									#LIVE_UTC=yes|no																				# この変数は「live-config.utc=yes|no」パラメータに相当します。
									#LIVE_X_SESSION_MANAGER=Xセッションマネージャ													# この変数は「live-config.x-session-manager=Xセッションマネージャ」パラメータに相当します。
									#LIVE_XORG_DRIVER=XORGドライバ																	# この変数は「live-config.xorg-driver=XORGドライバ」パラメータに相当します。
									#LIVE_XORG_RESOLUTION=XORG解像度																# この変数は「live-config.xorg-resolution=XORG解像度」パラメータに相当します。
									#LIVE_WLAN_DRIVER=WLANドライバ																	# この変数は「live-config.wlan-driver=WLANドライバ」パラメータに相当します。
									#LIVE_HOOKS=filesystem|medium|URL1|URL2| ... |URLn												# この変数は「live-config.hooks=filesystem|medium|URL1|URL2| ... |URLn」パラメータに相当します。
									#LIVE_CONFIG_DEBUG=true|false																	# この変数は「live-config.debug」パラメータに相当します。
									#LIVE_CONFIG_NOAUTOLOGIN=true|																	# 
									#LIVE_CONFIG_NOROOT=true|																		# 
									#LIVE_CONFIG_NOX11AUTOLOGIN=true|																# 
									#LIVE_SESSION=plasma.desktop|lxqt.desktop														# 固定値
									fncPrint "--- live configure $(fncString ${COL_SIZE} '-')"
									cat <<- '_EOT_' | sed 's/^ //g' | sed -e "s/_HOSTNAME_/${CODE_NAME[0]}/" > ./image/live/config.conf
										# *****************************************************************************
										#set -e
										#set -o allexport
										#set +o | tee
										# === Fix Parameters [ /lib/live/init-config.sh ] =============================
										#LIVE_HOSTNAME="debian"
										#LIVE_USERNAME="user"
										#LIVE_USER_FULLNAME="Debian Live user"
										#LIVE_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"
										# === Fix Parameters [ /lib/live/config/0030-live-debconfig_passwd ] ==========
										#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
										# === Fix Parameters [ /lib/live/config/0030-user-setup ] =====================
										#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
										# === User parameters =========================================================
										LIVE_HOSTNAME="_HOSTNAME_-live"
										# -----------------------------------------------------------------------------
										LIVE_USER_FULLNAME="Master"				# full name
										LIVE_USERNAME="master"					# user name
										LIVE_PASSWORD="master"					# password
										#LIVE_CRYPTPWD='8Ab05sVQ4LLps'
										# -----------------------------------------------------------------------------
										LIVE_LOCALES="ja_JP.UTF-8"
										LIVE_KEYBOARD_MODEL="pc105"
										LIVE_KEYBOARD_LAYOUTS="jp"
										LIVE_KEYBOARD_VARIANTS="OADG109A"
										LIVE_TIMEZONE="Asia/Tokyo"
										LIVE_UTC="yes"
										# -----------------------------------------------------------------------------
										#set | grep -e "^LIVE_" | tee
										# === Change hostname =========================================================
										if [ -n "${LIVE_HOSTNAME}" ]; then
										 	/bin/echo "${LIVE_HOSTNAME}" > /etc/hostname
										fi
										# === Output to shell files ===================================================
										cat <<- '_EOT_SH_' | sed 's/^ //g' > /lib/live/config/9999-user-setting
										 	#!/bin/sh
										
										 	/bin/echo ""
										 	/bin/echo "Start 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										
										 	#. /lib/live/config.sh
										 
										 	#set -e
										
										 	Cmdline ()
										 	{
										 	 	:
										 	}
										 	
										 	Init ()
										 	{
										 	 	:
										 	}
										
										 	Config ()
										 	{
										 	 	# === Change user password ================================================
										 	 	if [ -n "${LIVE_USERNAME}" ] && [ -n "${LIVE_PASSWORD}" ]; then
										 	 		/bin/echo ""
										 	 		/bin/echo "Change user password ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										 	#		useradd ${LIVE_USERNAME}
										 	 		/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | passwd ${LIVE_USERNAME}
										 	 	fi
										 	 	# === Change smb password =================================================
										 	 	if [ -n "`which smbpasswd 2> /dev/null`" ] && [ -n "${LIVE_USERNAME}" ] && [ -n "${LIVE_PASSWORD}" ]; then
										 	 		/bin/echo ""
										 	 		/bin/echo "Change smb password :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										 	 		smbpasswd -a ${LIVE_USERNAME} -n
										 	 		/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | smbpasswd ${LIVE_USERNAME}
										 	 	fi
										 	 	# === Change sshd configure ===============================================
										 	 	if [ -f /etc/ssh/sshd_config ]; then
										 	 		/bin/echo ""
										 	 		/bin/echo "Change sshd configure :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										 	 		sed -i /etc/ssh/sshd_config \
										 	 		    -e 's/^#*[ \t]*\(PasswordAuthentication\)[ \t]*.*$/\1 yes/g'
										 	 	fi
										 	 	# --- Creating state file -------------------------------------------------
										 	 	/bin/echo "Creating state file :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										 	 	touch /var/lib/live/config/user-setting
										 	}
										
										 	Debug ()
										 	{
										 	 	# === Display of parameters ===============================================
										 	 	/bin/echo ""
										 	 	/bin/echo "Display of parameters :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										 	 	/bin/echo "LIVE_USER_FULLNAME    =${LIVE_USER_FULLNAME}"
										 	 	/bin/echo "LIVE_USERNAME         =${LIVE_USERNAME}"
										 	 	/bin/echo "LIVE_PASSWORD         =${LIVE_PASSWORD}"
										 	 	/bin/echo "LIVE_CRYPTPWD         =${LIVE_CRYPTPWD}"
										 	 	/bin/echo "LIVE_LOCALES          =${LIVE_LOCALES}"
										 	 	/bin/echo "LIVE_KEYBOARD_MODEL   =${LIVE_KEYBOARD_MODEL}"
										 	 	/bin/echo "LIVE_KEYBOARD_LAYOUTS =${LIVE_KEYBOARD_LAYOUTS}"
										 	 	/bin/echo "LIVE_KEYBOARD_VARIANTS=${LIVE_KEYBOARD_VARIANTS}"
										 	 	/bin/echo "LIVE_TIMEZONE         =${LIVE_TIMEZONE}"
										 	 	/bin/echo "LIVE_UTC              =${LIVE_UTC}"
										 	}
										
										 	Cmdline
										 	Init
										 	Config
										 	#Debug
										
										 	/bin/echo ""
										 	/bin/echo "End 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
										_EOT_SH_
										chmod +x /lib/live/config/9999-user-setting
										# -----------------------------------------------------------------------------
										#set | grep -e "^LIVE_" | tee
										# === Creating state file =====================================================
										touch /var/lib/live/config/config-conf
										# =============================================================================
										#set +e
										# === Memo ====================================================================
										#	/lib/live/init-config.sh
										#	/lib/live/config/0020-hostname
										#	/lib/live/config/0030-live-debconfig_passwd
										#	/lib/live/config/0030-user-setup
										#	/lib/live/config/1160-openssh-server
										# *****************************************************************************
_EOT_
								fi
								# ---------------------------------------------
if [ 1 -eq 1 ]; then
#								WORKGROUP=`sed -n 's/^[ \t]*d-i[ \t]*netcfg\/get_domain[ \t]*string[ \t]*\(.*\)$/\1/p' image/preseed/preseed.cfg`
#								cat <<- '_EOT_SH_' | sed 's/^ //g' | sed -e "s/_WORKGROUP_/${WORKGROUP:-localdomain}/" > ./decomp/setup.sh
								cat <<- '_EOT_SH_' | sed 's/^ //g' > ./decomp/setup.sh
									#!/bin/bash
									# -----------------------------------------------------------------------------
									#	set -n								# 構文エラーのチェック
									#	set -x								# コマンドと引数の展開を表示
									 	set -o ignoreeof					# Ctrl+Dで終了しない
									 	set +m								# ジョブ制御を無効にする
									 	set -e								# ステータス0以外で終了
									 	set -u								# 未定義変数の参照で終了
									 	trap 'exit 1' 1 2 3 15
									 	echo "*******************************************************************************"
									 	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
									 	echo "*******************************************************************************"
									# -- terminate ----------------------------------------------------------------
									fncEnd() {
									 	echo "--- terminate -----------------------------------------------------------------"
									 	RET_STS=$1
									 	history -c
									 	echo "*******************************************************************************"
									 	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
									 	echo "*******************************************************************************"
									 	exit ${RET_STS}
									}
									# -- initialize ---------------------------------------------------------------
									 	echo "--- initialize ----------------------------------------------------------------"
									#	trap 'fncEnd 1' 1 2 3 15
									 	export PS1="(chroot) "
									 	# --- 追加ユーザー情報 ----------------------------------------------------
									#	username="master"
									#	password="master"
									# -- which command ------------------------------------------------------------
									 	if [ "`command -v which 2> /dev/null`" != "" ]; then
									 		CMD_WICH="command -v"
									 	else
									 		CMD_WICH="which"
									 	fi
									# -- system info --------------------------------------------------------------
									 	echo "--- system info ---------------------------------------------------------------"
									 	SYS_NAME=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
									 	SYS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
									 	SYS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
									 	SYS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
									 	if [ "${SYS_CODE}" = "" ]; then
									 		SYS_CODE=`echo ${SYS_VERS} | awk -F ',' '{split($2,array," "); print tolower(array[1]);}'`
									 	fi
									# -- apt setup ----------------------------------------------------------------
									 	echo "--- apt setup -----------------------------------------------------------------"
									 	case "${SYS_NAME}" in
									 		"debian" )
									 			APT_HOST="http://deb.debian.org/debian/"
									 			APT_SECU="http://security.debian.org/debian-security"
									 			APT_OPTI=""
									#			cp -p > /etc/apt/sources.list > /etc/apt/sources.list.orig
									 			cat <<- _EOT_ > /etc/apt/sources.list
									 				deb     ${APT_HOST} ${SYS_CODE} main non-free contrib
									 				deb-src ${APT_HOST} ${SYS_CODE} main non-free contrib
									 				deb     ${APT_SECU} ${SYS_CODE}-security main non-free contrib
									 				deb-src ${APT_SECU} ${SYS_CODE}-security main non-free contrib
									 				deb     ${APT_HOST} ${SYS_CODE}-updates main non-free contrib
									 				deb-src ${APT_HOST} ${SYS_CODE}-updates main non-free contrib
									 				deb     ${APT_HOST} ${SYS_CODE}-backports main non-free contrib
									 				deb-src ${APT_HOST} ${SYS_CODE}-backports main non-free contrib
									_EOT_
									 			if [ ${SYS_VRID} -ge 9 ]; then
									 				sed -i /etc/apt/sources.list    \
									 				    -e '/security.debian.org/d'
									 			fi
									 			;;
									 		"ubuntu" )
									 			APT_HOST="http://jp.archive.ubuntu.com/ubuntu/"
									 			APT_SECU="http://security.ubuntu.com/ubuntu"
									 			APT_OPTI="http://archive.canonical.com/ubuntu"
									#			cp -p > /etc/apt/sources.list > /etc/apt/sources.list.orig
									 			cat <<- _EOT_ > /etc/apt/sources.list
									 				deb     ${APT_HOST} ${SYS_CODE} main restricted universe multiverse
									 				deb-src ${APT_HOST} ${SYS_CODE} main restricted universe multiverse
									 				deb     ${APT_SECU} ${SYS_CODE}-security main restricted universe multiverse
									 				deb-src ${APT_SECU} ${SYS_CODE}-security main restricted universe multiverse
									 				deb     ${APT_HOST} ${SYS_CODE}-updates main restricted universe multiverse
									 				deb-src ${APT_HOST} ${SYS_CODE}-updates main restricted universe multiverse
									 				deb     ${APT_HOST} ${SYS_CODE}-backports main restricted universe multiverse
									 				deb-src ${APT_HOST} ${SYS_CODE}-backports main restricted universe multiverse
									 				deb     ${APT_OPTI} ${SYS_CODE} partner
									 				deb-src ${APT_OPTI} ${SYS_CODE} partner
									_EOT_
									 			;;
									 		* ) ;;
									 	esac
									# -- module install -----------------------------------------------------------
									 	echo "--- module install ------------------------------------------------------------"
									 	# -------------------------------------------------------------------------
									 	dpkg --audit
									 	dpkg --configure -a
									 	# -------------------------------------------------------------------------
									 	export DEBIAN_FRONTEND=noninteractive
									 	# -------------------------------------------------------------------------
									 	APT_OPTIONS="-o Dpkg::Options::=--force-confdef    \
									 	             -o Dpkg::Options::=--force-confnew    \
									 	             -o Dpkg::Options::=--force-overwrite"
									 	# -------------------------------------------------------------------------
									 	echo "--- apt-get -------------------------------------------------------------------"
									 	apt-get update                                                             || fncEnd $?
									 	apt-get upgrade      -q -y ${APT_OPTIONS}                                  || fncEnd $?
									 	apt-get dist-upgrade -q -y ${APT_OPTIONS}                                  || fncEnd $?
									 	apt-get install      -q -y ${APT_OPTIONS} --auto-remove                    \
									 	    __INST_PACK__                                                          \
									 	                                                                           || fncEnd $?
									 	# -------------------------------------------------------------------------
									 	echo "--- tasksel -------------------------------------------------------------------"
									 	tasksel install                                                            \
									 	    __INST_TASK__                                                          \
									 	                                                                           || fncEnd $?
									# --- google chrome install ---------------------------------------------------
									 	echo "--- google chrome install -----------------------------------------------------"
									#	if [ "${SYS_NAME}" = "debian" -a ("${SYS_CODE}" = "oldstable" -o "${SYS_CODE}" = "oldoldstable" -o "${SYS_CODE}" = "oldoldoldstable") ]; then
									 	if [ 1 -eq 1 ]; then
									 		# --- apt-get ---------------------------------------------------------
									 		set +e
									 		curl -L -# -R -S -f --connect-timeout 3                                \
									 		    -O "https://dl-ssl.google.com/linux/linux_signing_key.pub"         \
									 		                                                                       || if [ ${RET_CD} -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then fncEnd $?; fi
									 		set -e
									 		apt-key add ./linux_signing_key.pub
									 		if [ -f ./linux_signing_key.pub ]; then
									 			rm -f ./linux_signing_key.pub
									 		fi
									 		echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' \
									 		    > /etc/apt/sources.list.d/google-chrome.list
									 		apt-get update                                                         || fncEnd $?
									 		apt-get install      -q -y ${APT_OPTIONS} --auto-remove                \
									 		    google-chrome-stable                                               \
									 		                                                                       || fncEnd $?
									 	else
									 		# --- deb package -----------------------------------------------------
									 		set +e
									 		curl -L -# -R -S -f --connect-timeout 3                                \
									 		    -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
									 		                                                                       || if [ ${RET_CD} -eq 18 -o $? -eq 22 -o $? -eq 28  ]; then fncEnd $?; fi
									 		set -e
									 		apt-get install      -q -y ${APT_OPTIONS} --auto-remove                \
									 		    ./google-chrome-stable_current_amd64.deb                           \
									 		                                                                       || fncEnd $?
									 		if [ -f ./google-chrome-stable_current_amd64.deb ]; then
									 			rm -f ./google-chrome-stable_current_amd64.deb
									 		fi
									 	fi
									# --- cleaning ----------------------------------------------------------------
									 	apt-get autoremove   -q -y                                                 || fncEnd $?
									 	apt-get autoclean    -q -y                                                 || fncEnd $?
									 	apt-get clean        -q -y                                                 || fncEnd $?
									 	# -------------------------------------------------------------------------
									 	export -n DEBIAN_FRONTEND
									# -- network ------------------------------------------------------------------
									#	echo "--- network -------------------------------------------------------------------"
									#	CON_NAME=`nmcli -t -f name c | head -n 1`								# 接続名
									#	CON_UUID=`nmcli -t -f uuid c | head -n 1`								# 接続UUID
									 	# -------------------------------------------------------------------------
									#	nmcli c modify "${CON_UUID}" ipv6.method auto
									#	nmcli c modify "${CON_UUID}" ipv6.ip6-privacy 1
									#	nmcli c modify "${CON_UUID}" ipv6.dns "::1"
									#	nmcli c modify "${CON_UUID}" ipv6.dns-search ${WGP_NAME}.
									#	nmcli c modify "${CON_UUID}" ipv4.dns "127.0.0.1"
									#	nmcli c modify "${CON_UUID}" ipv4.dns-search ${WGP_NAME}.
									#	nmcli c down   "${CON_UUID}" > /dev/null
									#	nmcli c up     "${CON_UUID}" > /dev/null
									# -- localize -----------------------------------------------------------------
									 	echo "--- localize ------------------------------------------------------------------"
									 	sed -i /etc/locale.gen                   \
									 	    -e 's/^[a-zA-Z]/# &/g'               \
									 	    -e 's/# *\(ja_JP.UTF-8 UTF-8\)/\1/g' \
									 	    -e 's/# *\(en_US.UTF-8 UTF-8\)/\1/g'
									 	locale-gen
									 	update-locale LANG="ja_JP.UTF-8" LANGUAGE="ja:en"
									 	localectl set-x11-keymap --no-convert "jp,us" "pc105"
									# -- mozc ---------------------------------------------------------------------
									 	if [ -f /usr/share/ibus/component/mozc.xml ]; then
									 		sed -i /usr/share/ibus/component/mozc.xml                                     \
									 		    -e '/<engine>/,/<\/engine>/ s/\(<layout>\)default\(<\/layout>\)/\1jp\2/g'
									 	fi
									# -- clamav -------------------------------------------------------------------
									 	if [ -f /etc/clamav/freshclam.conf ]; then
									 		echo "--- clamav --------------------------------------------------------------------"
									 		sed -i /etc/clamav/freshclam.conf \
									 		    -e 's/^NotifyClamd/#&/'
									 	fi
									# -- sshd ---------------------------------------------------------------------
									 	if [ -f /etc/ssh/sshd_config ]; then
									 		echo "--- sshd ----------------------------------------------------------------------"
									 		sed -i /etc/ssh/sshd_config                    \
									 		    -e 's/^\( *PermitRootLogin \)/#\1/'        \
									 		    -e 's/^\( *PubkeyAuthentication \)/#\1/'   \
									 		    -e 's/^\( *PasswordAuthentication \)/#\1/' \
									 		    -e '$a \\n# --- user settings ---'         \
									 		    -e '$a PermitRootLogin no'                 \
									 		    -e '$a UseDNS no'                          \
									 		    -e '$a #PubkeyAuthentication yes'          \
									 		    -e '$a #PasswordAuthentication yes'
									 		if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
									 			sed -i /etc/ssh/sshd_config                     \
									 			    -e '$a PubkeyAcceptedAlgorithms +ssh-rsa'   \
									 			    -e '$a HostkeyAlgorithms +ssh-rsa'
									 		fi
									#		ssh-keygen -N "" -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key
									#		ssh-keygen -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
									 	fi
									# -- ftpd ---------------------------------------------------------------------
									 	if [ -f /etc/vsftpd.conf ]; then
									 		echo "--- ftpd ----------------------------------------------------------------------"
									 	fi
									# -- samba --------------------------------------------------------------------
									 	if [ -f /etc/samba/smb.conf ]; then
									 		echo "--- samba ---------------------------------------------------------------------"
									 		SVR_FQDN=`hostname`														# 本機のFQDN
									 		SVR_NAME=`hostname -s`													# 本機のホスト名
									 		if [ "${SVR_FQDN}" != "${SVR_NAME}" ]; then								# ワークグループ名(ドメイン名)
									 			WGP_NAME=`hostname | awk -F '.' '{ print $2; }'`
									 		else
									 			WGP_NAME=`hostname -d 2> /dev/null || :`
									#			if [ -z ${WGP_NAME} ]; then
									#				WGP_NAME="_WORKGROUP_"
									#			fi
									 			SVR_FQDN=${SVR_NAME}.${WGP_NAME}									# 本機のFQDN
									 		fi
									 		CMD_UADD=`${CMD_WICH} useradd`
									 		CMD_UDEL=`${CMD_WICH} userdel`
									 		CMD_GADD=`${CMD_WICH} groupadd`
									 		CMD_GDEL=`${CMD_WICH} groupdel`
									 		CMD_GPWD=`${CMD_WICH} gpasswd`
									 		CMD_FALS=`${CMD_WICH} false`
									 		# ---------------------------------------------------------------------
									 		testparm -s -v |                                                                        \
									 		sed -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
									 		    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
									 		    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
									 		    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
									 		    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
									 		    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
									 		    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
									 		    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
									 		    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
									 		    -e 's/\(min protocol\) =.*$/\1 = NT1/g'                                             \
									 		    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
									 		    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
									 		    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
									 		    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
									 		    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
									 		    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
									 		    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
									 		    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
									 		    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
									 		    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
									 		    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
									 		    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
									 		    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
									 		    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
									 		    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
									 		    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
									 		    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
									 		    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
									 		    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
									 		    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
									 		    -e '/[ |\t]*map to guest =.*$/d'                                                    \
									 		    -e '/[ |\t]*null passwords =.*$/d'                                                  \
									 		    -e '/[ |\t]*obey pam restrictions =.*$/d'                                           \
									 		    -e '/[ |\t]*enable privileges =.*$/d'                                               \
									 		    -e '/[ |\t]*password level =.*$/d'                                                  \
									 		    -e '/[ |\t]*client use spnego principal =.*$/d'                                     \
									 		    -e '/[ |\t]*syslog =.*$/d'                                                          \
									 		    -e '/[ |\t]*syslog only =.*$/d'                                                     \
									 		    -e '/[ |\t]*use spnego =.*$/d'                                                      \
									 		    -e '/[ |\t]*paranoid server security =.*$/d'                                        \
									 		    -e '/[ |\t]*dns proxy =.*$/d'                                                       \
									 		    -e '/[ |\t]*time offset =.*$/d'                                                     \
									 		    -e '/[ |\t]*usershare allow guests =.*$/d'                                          \
									 		    -e '/[ |\t]*idmap backend =.*$/d'                                                   \
									 		    -e '/[ |\t]*idmap uid =.*$/d'                                                       \
									 		    -e '/[ |\t]*idmap gid =.*$/d'                                                       \
									 		    -e '/[ |\t]*winbind separator =.*$/d'                                               \
									 		    -e '/[ |\t]*acl check permissions =.*$/d'                                           \
									 		    -e '/[ |\t]*only user =.*$/d'                                                       \
									 		    -e '/[ |\t]*share modes =.*$/d'                                                     \
									 		    -e '/[ |\t]*nbt client socket address =.*$/d'                                       \
									 		    -e '/[ |\t]*lsa over netlogon =.*$/d'                                               \
									 		    -e '/[ |\t]*.* = $/d'                                                               \
									 		    -e '/[ |\t]*client lanman auth =.*$/d'                                              \
									 		    -e '/[ |\t]*client NTLMv2 auth =.*$/d'                                              \
									 		    -e '/[ |\t]*client plaintext auth =.*$/d'                                           \
									 		    -e '/[ |\t]*client schannel =.*$/d'                                                 \
									 		    -e '/[ |\t]*client use spnego principal =.*$/d'                                     \
									 		    -e '/[ |\t]*client use spnego =.*$/d'                                               \
									 		    -e '/[ |\t]*domain logons =.*$/d'                                                   \
									 		    -e '/[ |\t]*enable privileges =.*$/d'                                               \
									 		    -e '/[ |\t]*encrypt passwords =.*$/d'                                               \
									 		    -e '/[ |\t]*idmap backend =.*$/d'                                                   \
									 		    -e '/[ |\t]*idmap gid =.*$/d'                                                       \
									 		    -e '/[ |\t]*idmap uid =.*$/d'                                                       \
									 		    -e '/[ |\t]*lanman auth =.*$/d'                                                     \
									 		    -e '/[ |\t]*lsa over netlogon =.*$/d'                                               \
									 		    -e '/[ |\t]*nbt client socket address =.*$/d'                                       \
									 		    -e '/[ |\t]*null passwords =.*$/d'                                                  \
									 		    -e '/[ |\t]*raw NTLMv2 auth =.*$/d'                                                 \
									 		    -e '/[ |\t]*server schannel =.*$/d'                                                 \
									 		    -e '/[ |\t]*syslog =.*$/d'                                                          \
									 		    -e '/[ |\t]*syslog only =.*$/d'                                                     \
									 		    -e '/[ |\t]*unicode =.*$/d'                                                         \
									 		    -e '/[ |\t]*acl check permissions =.*$/d'                                           \
									 		    -e '/[ |\t]*allocation roundup size =.*$/d'                                         \
									 		    -e '/[ |\t]*blocking locks =.*$/d'                                                  \
									 		    -e '/[ |\t]*copy =.*$/d'                                                            \
									 		    -e '/[ |\t]*winbind separator =.*$/d'                                               \
									 		    -e '/[ |\t]*domain master =.*$/d'                                                   \
									 		    -e '/[ |\t]*logon path =.*$/d'                                                      \
									 		    -e '/[ |\t]*logon script =.*$/d'                                                    \
									 		    -e '/[ |\t]*pam password change =.*$/d'                                             \
									 		    -e '/[ |\t]*preferred master =.*$/d'                                                \
									 		    -e '/[ |\t]*server role =.*$/d'                                                     \
									 		    -e '/[ |\t]*wins support =.*$/d'                                                    \
									 		    -e '/[ |\t]*dns proxy =.*$/d'                                                       \
									 		    -e '/[ |\t]*map to guest =.*$/d'                                                    \
									 		    -e '/[ |\t]*obey pam restrictions =.*$/d'                                           \
									 		    -e '/[ |\t]*pam password change =.*$/d'                                             \
									 		    -e '/[ |\t]*realm =.*$/d'                                                           \
									 		    -e '/[ |\t]*server role =.*$/d'                                                     \
									 		    -e '/[ |\t]*server services =.*$/d'                                                 \
									 		    -e '/[ |\t]*server string =.*$/d'                                                   \
									 		    -e '/[ |\t]*syslog =.*$/d'                                                          \
									 		    -e '/[ |\t]*unix password sync =.*$/d'                                              \
									 		    -e '/[ |\t]*usershare allow guests =.*$/d'                                          \
									 		    -e '/[ |\t]*\(client ipc\|client\|server\) min protocol = .*$/d'                    \
									 		    -e '/[ |\t]*security =.*$/d'                                                        \
									 		> ./smb.conf
									 		# ---------------------------------------------------------------------
									 		testparm -s ./smb.conf > /etc/samba/smb.conf
									 		rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
									 	fi
									# -- minidlna -----------------------------------------------------------------
									 	if [ -f /etc/minidlna.conf ]; then
									 		echo "--- minidlna.conf -------------------------------------------------------------"
									 		systemctl disable minidlna.service
									 	fi
									# -- open vm tools ------------------------------------------------------------
									 	if [ "`dpkg -l open-vm-tools | awk '$1==\"ii\" && $2=\"open-vm-tools\" {print $2;}'`" = "open-vm-tools" ]; then
									 		echo "--- open vm tools -------------------------------------------------------------"
									 		if [ ! -d /media/hgfs ]; then
									 			mkdir -p /media/hgfs
									 		fi
									 		echo -e '# Added by User\n' \
									 		        '.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,noauto,users,defaults 0 0' \
									 		>> /etc/fstab
									 	fi
									# -- root and user's setting --------------------------------------------------
									 	echo "--- root and user's setting ---------------------------------------------------"
									#	useradd ${username}
									#	echo -e "${password}\n${password}\n" | passwd ${username}
									#	smbpasswd -a ${username} -n
									#	echo -e "${password}\n${password}\n" | smbpasswd ${username}
									 	# -------------------------------------------------------------------------
									 	for USER_NAME in "skel" "root"
									 	do
									 		if [ "${USER_NAME}" == "skel" ]; then
									 			USER_HOME="/etc/skel"
									 		else
									 			USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
									 		fi
									 		pushd ${USER_HOME} > /dev/null
									 			echo "--- .bashrc -------------------------------------------------------------------"
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
									 			echo "--- .vimrc --------------------------------------------------------------------"
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
									 				chown ${USER_NAME}. .vimrc
									 			fi
									 			echo "--- .curlrc -------------------------------------------------------------------"
									 			cat <<- _EOT_ > .curlrc
									 				location
									 				progress-bar
									 				remote-time
									 				show-error
									_EOT_
									 			if [ "${USER_NAME}" != "skel" ]; then
									 				chown ${USER_NAME}. .curlrc
									 			fi
									 			if [ "${USER_NAME}" != "skel" ]; then
									 				echo "--- .credentials --------------------------------------------------------------"
									 				cat <<- _EOT_ > .credentials
									 					username=value
									 					password=value
									 					domain=value
									_EOT_
									 				chown ${USER_NAME}. .credentials
									 				chmod 0600 .credentials
									 			fi
									 			if [ -f .config/libfm/libfm.conf ]; then
									 				echo "--- libfm.conf ----------------------------------------------------------------"
									 				sed -i .config/libfm/libfm.conf   \
									 				    -e 's/^\(single_click\)=.*$/\1=0/'
									 			fi
									 		popd > /dev/null
									 	done
									# -- cleaning -----------------------------------------------------------------
									 	echo "--- cleaning ------------------------------------------------------------------"
									 	fncEnd 0
									# -- EOF ----------------------------------------------------------------------
									# *****************************************************************************
									# <memo>
									#   [im-config]
									#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
									# *****************************************************************************
_EOT_SH_
								# --- packages --------------------------------
								OLD_IFS=${IFS}
								IFS=$'\n'
								LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg  | \
								           sed -z 's/\n//g'                                                                | \
								           sed -e 's/.* multiselect *//'                                                     \
								               -e 's/[,|\\\\]//g'                                                            \
								               -e 's/\t/ /g'                                                                 \
								               -e 's/  */ /g'                                                                \
								               -e 's/^ *//'`
								LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg | \
								           sed -z 's/\n//g'                                                                | \
								           sed -e 's/.* string *//'                                                          \
								               -e 's/[,|\\\\]//g'                                                            \
								               -e 's/\t/ /g'                                                                 \
								               -e 's/  */ /g'                                                                \
								               -e 's/^ *//'`
								INST_TASK=${LIST_TASK}
								INST_PACK=`echo "${LIST_PACK}" | sed -e 's/ *isc-dhcp-server//'`
								INST_PACK+=" whois"
								sed -i ./decomp/setup.sh               \
								    -e "s/__INST_PACK__/${INST_PACK}/" \
								    -e "s/__INST_TASK__/${INST_TASK}/"
								IFS=${OLD_IFS}
								# --- copy media -> fsimg ---------------------
								fncPrint "--- copy media -> fsimg $(fncString ${COL_SIZE} '-')"
								if [ -f ./image/live/filesystem.squashfs ]; then
									mount -r -o loop ./image/live/filesystem.squashfs    ./mnt
								elif [ -f ./image/install/filesystem.squashfs ]; then
									mount -r -o loop ./image/install/filesystem.squashfs ./mnt
								elif [ -f ./image/casper/filesystem.squashfs ]; then
									mount -r -o loop ./image/casper/filesystem.squashfs  ./mnt
								elif [ -f ./image/casper/minimal.squashfs ]; then
									mount -r -o loop ./image/casper/minimal.squashfs     ./mnt
								fi
								cp -pr ./mnt/* ./decomp/
								umount ./mnt
								# --- network ---------------------------------
#								if [ -f ./decomp/etc/resolv.conf ]; then
#									sed -i.orig ./decomp/etc/resolv.conf \
#									    -e '$a nameserver 1.1.1.1'       \
#									    -e '$a nameserver 1.0.0.1'
#								fi
								cp -p ./decomp/etc/apt/sources.list      \
								      ./decomp/etc/apt/sources.list.orig
								# --- time zone -------------------------------
								rm -f ./decomp/etc/localtime
								ln -s /usr/share/zoneinfo/Asia/Tokyo ./decomp/etc/localtime
								# --- mount -----------------------------------
								mount --bind /run     ./decomp/run
								mount --bind /dev     ./decomp/dev
								mount --bind /dev/pts ./decomp/dev/pts
								mount --bind /proc    ./decomp/proc
								mount --bind /sys     ./decomp/sys
								# --- chroot ----------------------------------
								LANG=C chroot ./decomp /bin/bash /setup.sh
								RET_STS=$?
								# --- unmount ---------------------------------
								umount ./decomp/sys     || umount -lf ./decomp/sys
								umount ./decomp/proc    || umount -lf ./decomp/proc
								umount ./decomp/dev/pts || umount -lf ./decomp/dev/pts
								umount ./decomp/dev     || umount -lf ./decomp/dev
								umount ./decomp/run     || umount -lf ./decomp/run
								# --- error check -----------------------------
								if [ ${RET_STS} -ne 0 ]; then
									exit ${RET_STS}
								fi
								# --- cleaning --------------------------------
								if [ -f ./decomp/etc/resolv.conf.orig ]; then
									mv ./decomp/etc/resolv.conf.orig \
									   ./decomp/etc/resolv.conf
								fi
								if [ -f ./decomp/etc/apt/sources..orig ]; then
									mv ./decomp/etc/apt/sources.list.orig \
									   ./decomp/etc/apt/sources.list
								fi
								find   ./decomp/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
								rm -rf ./decomp/root/.bash_history           \
								       ./decomp/root/.viminfo                \
								       ./decomp/tmp/*                        \
								       ./decomp/var/cache/apt/*.bin          \
								       ./decomp/var/cache/apt/archives/*.deb \
								       ./decomp/setup.sh
#								if [ -f ./decomp/etc/hostname ]; then
#									mv ./decomp/etc/hostname ./decomp/etc/hostname.orig
#								fi
								# --- filesystem manifest ---------------------
								case "${CODE_NAME[0]}" in
									"debian" )	# ･････････････････････････････
										;;
									"ubuntu" )	# ･････････････････････････････
										rm ./image/casper/filesystem.size                    \
										   ./image/casper/filesystem.manifest                \
										   ./image/casper/filesystem.manifest-remove         
#										   ./image/casper/filesystem.manifest-minimal-remove 
										# -------------------------------------
										touch ./image/casper/filesystem.size
										touch ./image/casper/filesystem.manifest
										touch ./image/casper/filesystem.manifest-remove
#										touch ./image/casper/filesystem.manifest-minimal-remove
										# -------------------------------------
										printf $(LANG=C chroot ./decomp du -sx --block-size=1 | cut -f1) > ./image/casper/filesystem.size
										LANG=C chroot ./decomp dpkg-query -W --showformat='${Package} ${Version}\n' > ./image/casper/filesystem.manifest
										cp -p ./image/casper/filesystem.manifest ./image/casper/filesystem.manifest-desktop
										sed -i ./image/casper/filesystem.manifest-desktop \
										    -e '/^casper.*$/d'                            \
										    -e '/^lupin-casper.*$/d'                      \
										    -e '/^ubiquity.*$/d'                          \
										    -e '/^ubiquity-casper.*$/d'                   \
										    -e '/^ubiquity-frontend-gtk.*$/d'             \
										    -e '/^ubiquity-slideshow-ubuntu.*$/d'         \
										    -e '/^ubiquity-ubuntu-artwork.*$/d'
										;;
									* )	;;
								esac
								# --- copy fsimg -> media ---------------------
								fncPrint "--- copy fsimg -> media $(fncString ${COL_SIZE} '-')"
								case "${CODE_NAME[0]}" in
									"debian" )	# ･････････････････････････････････････
										rm -f ./image/live/filesystem.squashfs
										mksquashfs ./decomp ./image/live/filesystem.squashfs -mem 1G
										ls -lht ./image/live/filesystem.squashfs
										FSIMG_SIZE=`LANG=C ls -lh ./image/live/filesystem.squashfs | awk '{print $5;}'`
										;;
									"ubuntu" )	# ･････････････････････････････････････
										rm -f ./image/casper/filesystem.squashfs
										mksquashfs ./decomp ./image/casper/filesystem.squashfs -mem 1G
										ls -lht ./image/casper/filesystem.squashfs
										FSIMG_SIZE=`LANG=C ls -lh ./image/casper/filesystem.squashfs | awk '{print $5;}'`
										;;
									* )	;;
								esac
fi
								;;
							"centos"       | \
							"fedora"       | \
							"rocky"        | \
							"miraclelinux" )		# ･････････････････････････････････
								;;
							"suse"         )		# ･････････････････････････････････
								;;
							*              ) ;;		# ･････････････････････････････････
						esac
					popd > /dev/null
					;;
				* ) ;;
			esac
			# --- make iso file -----------------------------------------------
			fncPrint "--- make iso file $(fncString ${COL_SIZE} '-')"
			case "${CODE_NAME[0]}" in
				"debian"       | \
				"ubuntu"       | \
				"centos"       | \
				"fedora"       | \
				"rocky"        | \
				"miraclelinux" )	# ･････････････････････････････････････････････････
					rm -f md5sum.txt
					find . ! -name "md5sum.txt" ! -name "boot.catalog" ! -name "boot.cat" ! -name "isolinux.bin" ! -name "eltorito.img" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
					# --- make iso file -----------------------------------------------
					if [ -f isolinux.bin ]; then
						ELT_BOOT=isolinux.bin
						ELT_CATA=boot.cat
					elif [ -f isolinux/isolinux.bin ]; then
						ELT_BOOT=isolinux/isolinux.bin
						ELT_CATA=isolinux/boot.cat
					elif [ -f boot/grub/i386-pc/eltorito.img ]; then
						ELT_BOOT=boot/grub/i386-pc/eltorito.img
						ELT_CATA=boot.catalog
					fi
					xorriso -as mkisofs \
					    -quiet \
					    -iso-level 3 \
					    -full-iso9660-filenames \
					    -volid "${VOLID}" \
					    -eltorito-boot "${ELT_BOOT}" \
					    -eltorito-catalog "${ELT_CATA}" \
					    -no-emul-boot -boot-load-size 4 -boot-info-table \
					    -isohybrid-mbr "${DIR_LINX}" \
					    -eltorito-alt-boot \
					    -e "${EFI_IMAG}" \
					    -no-emul-boot -isohybrid-gpt-basdat \
					    -output "../../${ISO_NAME}.iso" \
					    .
					;;
				"suse" )	# ･････････････････････････････････････････････････
#					find boot EFI docu media.1 -type f -exec sha256sum {} \; > CHECKSUMS
					xorriso -as mkisofs \
					    -quiet \
					    -iso-level 3 \
					    -full-iso9660-filenames \
					    -volid "${VOLID}" \
					    -eltorito-boot boot/x86_64/loader/isolinux.bin \
					    -no-emul-boot -boot-load-size 4 -boot-info-table \
					    -isohybrid-mbr "${DIR_LINX}" \
					    -eltorito-alt-boot \
					    -e boot/x86_64/efi \
					    -no-emul-boot -isohybrid-gpt-basdat \
					    -output "../../${ISO_NAME}.iso" \
					    . > /dev/null
					;;
				* )	;;
			esac
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" != "" ]; then
				LANG=C implantisomd5 "../../${ISO_NAME}.iso" > /dev/null
			fi
		popd > /dev/null
	popd > /dev/null
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	fncPrint "↑処理済：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '-')"
	return 0
}
# which command ---------------------------------------------------------------
	if [ "`command -v which 2> /dev/null`" != "" ]; then
		CMD_WICH="command -v"
	else
		CMD_WICH="which"
	fi
# terminal size ---------------------------------------------------------------
	ROW_SIZE=25
	COL_SIZE=80
	if [ "`${CMD_WICH} tput 2> /dev/null`" != "" ]; then
		ROW_SIZE=`tput lines`
		COL_SIZE=`tput cols`
	fi
	if [ ${COL_SIZE} -lt 80 ]; then
		COL_SIZE=80
	fi
	if [ ${COL_SIZE} -gt 100 ]; then
		COL_SIZE=100
	fi
# -----------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` 作成処理を開始します。"
	fncPrint "$(fncString ${COL_SIZE} '*')"
# cpu type --------------------------------------------------------------------
	CPU_TYPE=`LANG=C lscpu | awk '/Architecture:/ {print $2;}'`					# CPU TYPE (x86_64/armv5tel/...)
# system info -----------------------------------------------------------------
	SYS_NAME=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
	SYS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
	SYS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
	SYS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
	SYS_VNUM=`echo ${SYS_VRID:--1} | bc`										#   〃          (取得できない場合は-1)
	SYS_NOOP=0																	# 対象OS=1,それ以外=0
	if [ "${SYS_CODE}" = "" ]; then
		case "${SYS_NAME}" in
			"debian"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`;;
			"ubuntu"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`;;
			"centos"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/centos-release`;;
			"fedora"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $3;}' /etc/fedora-release`;;
			"rocky"               ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/rocky-release` ;;
			"opensuse-leap"       ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`    ;;
			"opensuse-tumbleweed" ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`    ;;
			*                     )                                                                                   ;;
		esac
	fi
	if [ "${CPU_TYPE}" = "x86_64" ]; then
		case "${SYS_NAME}" in
			"debian"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 10"       | bc`;;
			"ubuntu"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 20.04"    | bc`;;
			"centos"              ) SYS_NOOP=`echo "${SYS_VNUM} >=  8"       | bc`;;
			"fedora"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 32"       | bc`;;
			"rocky"               ) SYS_NOOP=`echo "${SYS_VNUM} >=  8.4"     | bc`;;
			"opensuse-leap"       ) SYS_NOOP=`echo "${SYS_VNUM} >= 15.2"     | bc`;;
			"opensuse-tumbleweed" ) SYS_NOOP=`echo "${SYS_VNUM} >= 20201002" | bc`;;
			*                     )                                               ;;
		esac
	fi
	if [ ${SYS_NOOP} -eq 0 ]; then
		echo "${SYS_NAME} ${SYS_VERS:-${SYS_CODE}} (${CPU_TYPE}) ではテストをしていないので実行できません。"
		exit 1
	fi
# -----------------------------------------------------------------------------
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			if [ "`${CMD_WICH} aptitude 2> /dev/null`" != "" ]; then
				CMD_AGET="aptitude -y -q"
			else
				CMD_AGET="apt -y -qq"
			fi
			DIR_LINX="/usr/lib/ISOLINUX/isohdpfx.bin"
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`${CMD_WICH} dnf 2> /dev/null`" != "" ]; then
				CMD_AGET="dnf -y -q --allowerasing"
			else
				CMD_AGET="yum -y -q"
			fi
			DIR_LINX="/usr/share/syslinux/isohdpfx.bin"
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			CMD_AGET="zypper -n -t"
			DIR_LINX="/usr/share/syslinux/isohdpfx.bin"
			;;
		* )
			;;
	esac
# -----------------------------------------------------------------------------
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = ""       \
			-o   "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" ]; then
					${CMD_AGET} install isomd5sum
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					${CMD_AGET} install isolinux
				fi
			fi
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = ""       \
			-o   "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" ]; then
					${CMD_AGET} install isomd5sum
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					${CMD_AGET} install syslinux
				fi
			fi
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = ""       \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					${CMD_AGET} install isolinux
				fi
			fi
			ARRAY_WORK=("${ARRAY_NAME[@]}")
			for ((I=1; I<=${#ARRAY_NAME[@]}; I++))
			do
				ARRY_NAME=(${ARRAY_WORK[$I-1]})
				if [ "${ARRY_NAME[0]}" != "suse" ]; then
					unset ARRAY_WORK[$I-1]
				fi
			done
			ARRAY_NAME=("${ARRAY_WORK[@]}")
			;;
		* )
			;;
	esac
# -----------------------------------------------------------------------------
	case "${WORK_DIRS}" in
		"dist_remaster_mini" )	ARRAY_NAME=("${ARRAY_NAME_MINI[@]}");;
		"dist_remaster_net"  )	ARRAY_NAME=("${ARRAY_NAME_NET[@]}");;
		"dist_remaster_dvd"  )	ARRAY_NAME=("${ARRAY_NAME_DVD[@]}");;
		"live-custom"        )	ARRAY_NAME=("${ARRAY_NAME_LIVE[@]}");;
		*                    )	;;
	esac
	# -------------------------------------------------------------------------
	case "${INP_INDX,,}" in
		"a" | "all" )
			INP_INDX="{1..${#ARRAY_NAME[@]}}"
			;;
		* )
			;;
	esac
	# -------------------------------------------------------------------------
	fncMenu
	# -------------------------------------------------------------------------
	for I in `eval echo "${INP_INDX}"`						# 連番可
	do
		if [ `fncIsInt "$I"` -eq 0 ] && [ $I -ge 1 ] && [ $I -le ${#ARRAY_NAME[@]} ]; then
			case "${WORK_DIRS}" in
				"dist_remaster_mini" )	fncRemaster_mini "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"dist_remaster_net"  )	fncRemaster      "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"dist_remaster_dvd"  )	fncRemaster      "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"live-custom"        )	fncRemaster      "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				*                    )	                                        RET_CD=0 ;;
			esac
			if [ ${RET_CD} != 0 ]; then
				while true
				do
					popd > /dev/null 2>&1
					if [ $? != 0 ]; then
						break
					fi
				done
				echo "skip"
			fi
		fi
	done
	# -------------------------------------------------------------------------
	set +e
	ls -lthLgG --time-style="+%Y/%m/%d %H:%M:%S" "${WORK_DIRS}/"*iso 2> /dev/null | \
	    grep -e ".*-*\(custom\)*-\(autoyast\|kickstart\|nocloud\|preseed\).iso"   | \
	    cut -c 13-
	set -e
# -----------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` 作成処理が終了しました。"
	fncPrint "$(fncString ${COL_SIZE} '*')"
# -----------------------------------------------------------------------------
	exit 0
# = eof =======================================================================
# <memo>
# -----------------------------------------------------------------------------
# vga：解像度    ：色数
# 771： 800× 600：256色
# 773：1024× 768：256色
# 775：1280×1024：256色
# 788： 800× 600：6万5000色
# 791：1024× 768：6万5000色
# 794：1280×1024：6万5000色
# 789： 800× 600：1600万色
# 792：1024× 768：1600万色
# 795：1280×1024：1600万色
# ---  https://ja.wikipedia.org/wiki/Debian -----------------------------------
# Ver. :コードネーム     :リリース日:サポート期限
#x  1.1:buzz             :1996-06-17:
#x  1.2:rex              :1996-12-12:
#x  1.3:bo               :1997-06-02:
#x  2.0:hamm             :1998-07-24:
#x  2.1:slink            :1999-03-09:
#x  2.2:potato           :2000-08-15:
#x  3.0:woody            :2002-07-19:2006-06-30
#x  3.1:sarge            :2005-06-06:2008-03-31
#x  4.0:etch             :2007-04-08:2010-02-15
#x  5.0:lenny            :2009-02-14:2012-02-06
#x  6.0:squeeze          :2011-02-06:2014-05-31/2016-02-29[LTS]
#x  7.0:wheezy           :2013-05-04:2016-04-25/2018-05-31[LTS]
#x  8.0:jessie           :2015-04-25:2018-06-17/2020-06-30[LTS]
#   9.0:stretch          :2017-06-17:2020-07-06/2022-06-30[LTS]:oldoldstable
#  10.0:buster           :2019-07-06:2022-06-xx/2024-06-xx[LTS]:oldstable
#  11.0:bullseye         :2021-08-14:2024-xx-xx/2026-xx-xx[LTS]:stable
#  12.0:bookworm         :          :                           testing
# --- https://en.wikipedia.org/wiki/Ubuntu_version_history --------------------
# [https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja]
# Ver. :コードネーム     :リリース日:サポート期限
#x 4.10:Warty Warthog    :2004-10-20:2006-04-30
#x 5.04:Hoary Hedgehog   :2005-04-08:2006-10-31
#x 5.10:Breezy Badger    :2005-10-13:2007-04-13
#x 6.06:Dapper Drake     :2006-06-01:2011-06-01(Server)   :LTS
#x 6.10:Edgy Eft         :2006-10-26:2008-04-25
#x 7.04:Feisty Fawn      :2007-04-19:2008-10-19
#x 7.10:Gutsy Gibbon     :2007-10-18:2009-04-18
#x 8.04:Hardy Heron      :2008-04-24:2013-05-09(Server)   :LTS
#x 8.10:Intrepid Ibex    :2008-10-30:2010-04-30
#x 9.04:Jaunty Jackalope :2009-04-23:2010-10-23
#x 9.10:Karmic Koala     :2009-10-29:2011-04-30
#x10.04:Lucid Lynx       :2010-04-29:2015-04-30(Server)   :LTS
#x10.10:Maverick Meerkat :2010-10-10:2012-04-10
#x11.04:Natty Narwhal    :2011-04-28:2012-10-28
#x11.10:Oneiric Ocelot   :2011-10-13:2013-05-09
#x12.04:Precise Pangolin :2012-04-26:2017-04-28/2019-04-26:LTS
#x12.10:Quantal Quetzal  :2012-10-18:2014-05-16
#x13.04:Raring Ringtail  :2013-04-25:2014-01-27
#x13.10:Saucy Salamander :2013-10-17:2014-07-17
#x14.04:Trusty Tahr      :2014-04-17:2019-04-25/2024-04-25:LTS
#x14.10:Utopic Unicorn   :2014-10-23:2015-07-23
#x15.04:Vivid Vervet     :2015-04-23:2016-02-04
#x15.10:Wily Werewolf    :2015-10-22:2016-07-28
#x16.04:Xenial Xerus     :2016-04-21:2021-04-30/2026-04-23:LTS
#x16.10:Yakkety Yak      :2016-10-13:2017-07-20
#x17.04:Zesty Zapus      :2017-04-13:2018-01-13
#x17.10:Artful Aardvark  :2017-10-19:2018-07-19
# 18.04:Bionic Beaver    :2018-04-26:2023-04-26/2028-04-26:LTS
#x18.10:Cosmic Cuttlefish:2018-10-18:2019-07-18
#x19.04:Disco Dingo      :2019-04-18:2020-01-23
#x19.10:Eoan Ermine      :2019-10-17:2020-07-17
# 20.04:Focal Fossa      :2020-04-23:2025-04-23/2030-04-23:LTS
#x20.10:Groovy Gorilla   :2020-10-22:2021-07-22
#x21.04:Hirsute Hippo    :2021-04-22:2022-01-20
# 21.10:Impish Indri     :2021-10-14:2022-07-14
# 22.04:Jammy Jellyfish  :2022-04-21:2027-04-21/2032-04-21:LTS
# --- https://ja.wikipedia.org/wiki/CentOS ------------------------------------
# [https://en.wikipedia.org/wiki/CentOS]
# Ver.    :リリース日:RHEL      :メンテ期限:kernel
# 7.4-1708:2017-09-14:2017-08-01:2024-06-30: 3.10.0- 693
# 7.5-1804:2018-05-10:2018-04-10:2024-06-30: 3.10.0- 862
# 7.6-1810:2018-12-03:2018-10-30:2024-06-30: 3.10.0- 957
# 7.7-1908:2019-09-17:2019-08-06:2024-06-30: 3.10.0-1062
# 7.8-2003:2020-04-27:2020-03-30:2024-06-30: 3.10.0-1127
#x8.0-1905:2019-09-24:2019-05-07:2021-12-31: 4.18.0- 80
#x8.1-1911:2020-01-15:2019-11-05:2021-12-31: 4.18.0-147
#x8.2.2004:2020-06-15:2020-04-28:2021-12-31: 4.18.0-193
#x8.3.2011:2020-11-03:2020-12-07:2021-12-31: 4.18.0-240
#x8.4.2015:2021-06-03:2021-05-18:2021-12-31: 4.18.0-305
#x8.5.2111:2021-11-16:2021-11-09:2021-12-31: 4.18.0-348
# --- https://ja.wikipedia.org/wiki/Rocky_Linux -------------------------------
# [https://en.wikipedia.org/wiki/Rocky_Linux]
# Ver. :リリース日:RHEL      :メンテ期限:kernel
#  8.4 :2021-06-21:2021-05-18:         : 4.18.0-305
#  8.5 :2021-11-15:2021-11-09:         : 4.18.0-348
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# [https://en.wikipedia.org/wiki/Fedora_Linux]
# Ver. :コードネーム     :リリース日:サポ期限  :kernel
#x27   :                 :2017-11-14:2018-11-27: 4.13
#x28   :                 :2018-05-01:2019-05-29: 4.16
#x29   :                 :2018-10-30:2019-11-26: 4.18
#x30   :                 :2019-04-29:2020-05-26: 5.0
#x31   :                 :2019-10-29:2020-11-24: 5.3
#x32   :                 :2020-04-28:2021-05-25: 5.6
# 33   :                 :2020-10-27:2021-11-30: 5.8
# 34   :                 :2021-04-27:2022-05-17: 5.11
# 35   :                 :2021-11-02:2022-12-07: 5.15
# 36   :                 :2022-05-10:2023-05-16: 5.17
# 37   :                 :2022-10-18:2023-11-22:
# --- https://ja.wikipedia.org/wiki/OpenSUSE ----------------------------------
# [https://en.wikipedia.org/wiki/OpenSUSE]
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 15.2 :openSUSE Leap      :2020-07-02:2021-12-31: 5.3.18
# 15.3 :openSUSE Leap      :2021-06-02:          : 5.3.18
# xx.x :openSUSE Tumbleweed:20xx-xx-xx:20xx-xx-xx:
# --- https://ja.wikipedia.org/wiki/MIRACLE_LINUX -----------------------------
# [https://en.wikipedia.org/wiki/Miracle_Linux]
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 8.4  :Peony              :2021-10-04:          :4.18.0-305.el8
# -----------------------------------------------------------------------------
