#!/bin/bash
###############################################################################
##
##	ファイル名	:	dist_remaster_dvd.sh
##
##	機能概要	:	ブータブルDVDの作成用シェル [DVD版]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian / Ubuntu / CentOS7 / Fedora / openSUSE (64bit)
##	---------------------------------------------------------------------------
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2018/05/01
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- ----------------------------------------
##	2018/05/01 000.0000 J.Itou         新規作成
##	2021/05/29 000.0000 J.Itou         memo修正 / 履歴整理 / 不具合修正 / CentOS-Stream-8-x86_64-20210524-dvd1 変更
##	2021/06/03 000.0000 J.Itou         情報登録用配列の修正 / CentOS-Stream-8-x86_64-20210528-dvd1 変更
##	2021/06/04 000.0000 J.Itou         memo修正 / openSUSE対応 / CentOS-8.4.2105-x86_64-dvd1 / CentOS-Stream-8-x86_64-20210603-dvd1 変更
##	2021/06/12 000.0000 J.Itou         URLのワイルドカード対応
##	2021/06/13 000.0000 J.Itou         作業ディレクトリ削除処理追加
##	2021/06/21 000.0000 J.Itou         CentOSの接続先変更 / [0-9].* 変更
##	2021/06/23 000.0000 J.Itou         Rocky Linux 追加
##	2021/06/28 000.0000 J.Itou         Debian 11 対応
##	2021/07/02 000.0000 J.Itou         memo修正
##	2021/07/07 000.0000 J.Itou         cpio 表示出力抑制追加
##	2021/07/13 000.0000 J.Itou         ubuntu 無人インストール定義ファイルの処理変更
##	2021/07/17 000.0000 J.Itou         処理見直し
##	2021/08/02 000.0000 J.Itou         ubuntu desktop版対応
##	2021/08/04 000.0000 J.Itou         debian-bullseye-DI-rc3-amd64-DVD-1.iso追加
##	2021/08/06 000.0000 J.Itou         処理見直し
##	2021/08/08 000.0000 J.Itou         不具合修正
##	2021/08/09 000.0000 J.Itou         処理見直し
##	2021/08/15 000.0000 J.Itou         debian 11 対応
##	2021/08/17 000.0000 J.Itou         対象OS整理
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	set -x													# コマンドと引数の展開を表示
#	set -n													# 構文エラーのチェック
#	set -eu													# ステータス0以外と未定義変数の参照で終了
	set -u													# 未定義変数の参照で終了
#	set -o ignoreof											# Ctrl+Dで終了しない
	trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
	INP_INDX=${@:-""}										# 処理ID
# -----------------------------------------------------------------------------
	WHO_AMI=`whoami`										# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
# -----------------------------------------------------------------------------
	readonly WORK_DIRS=`basename $0 | sed -e 's/\..*$//'`	# 作業ディレクトリ名(プログラム名)
# -----------------------------------------------------------------------------
	ARRAY_NAME=(                                                                                                                                                                                                           \
	    "debian https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso              preseed_debian.cfg                          2017-06-17 2022-06-30 oldoldstable  " \
	    "debian https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso                 preseed_debian.cfg                          2019-07-06 2024-xx-xx oldstable     " \
	    "debian https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-[0-9].*-amd64-DVD-1.iso                          preseed_debian.cfg                          2021-08-14 20xx-xx-xx stable        " \
	    "debian https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                            preseed_debian.cfg                          20xx-xx-xx 20xx-xx-xx testing       " \
	    "ubuntu https://releases.ubuntu.com/xenial/ubuntu-[0-9].*-server-amd64.iso                                                       preseed_ubuntu.cfg                          2016-04-21 2024-04-xx Xenial_Xerus  " \
	    "ubuntu http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-[0-9].*-server-amd64.iso                                        preseed_ubuntu.cfg                          2018-04-26 2028-04-xx Bionic_Beaver " \
	    "ubuntu https://releases.ubuntu.com/focal/ubuntu-[0-9].*-live-server-amd64.iso                                                   preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2020-04-23 2030-04-xx Focal_Fossa   " \
	    "ubuntu https://releases.ubuntu.com/hirsute/ubuntu-[0-9].*-live-server-amd64.iso                                                 preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2021-04-22 2022-01-xx Hirsute_Hippo " \
	    "centos http://ftp.riken.jp/Linux/centos/8/isos/x86_64/CentOS-[0-9].*-x86_64-dvd1.iso                                            kickstart_centos.cfg                        2021-06-03 2021-12-31 RHEL_8.4      " \
	    "centos http://ftp.riken.jp/Linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-[0-9].*-dvd1.iso                            kickstart_centos.cfg                        2019-xx-xx 2024-05-31 RHEL_x.x      " \
	    "fedora https://download.fedoraproject.org/pub/fedora/linux/releases/34/Server/x86_64/iso/Fedora-Server-dvd-x86_64-34-1.2.iso    kickstart_fedora.cfg                        2021-04-27 20xx-xx-xx kernel_5.11   " \
	    "suse   http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64.iso                                yast_opensuse153.xml                        2021-06-02 20xx-xx-xx kernel_5.3.18 " \
	    "suse   http://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                   yast_opensuse16.xml                         2021-xx-xx 20xx-xx-xx kernel_x.x    " \
	    "rocky  https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-[0-9].*-x86_64-dvd1.iso                                    kickstart_rocky.cfg                         2021-06-21 20xx-xx-xx RHEL_8.4      " \
	    "ubuntu https://releases.ubuntu.com/xenial/ubuntu-[0-9].*-desktop-amd64.iso                                                      preseed_ubuntu.cfg                          2016-04-21 2024-04-xx Xenial_Xerus  " \
	    "ubuntu https://releases.ubuntu.com/bionic/ubuntu-[0-9].*-desktop-amd64.iso                                                      preseed_ubuntu.cfg                          2018-04-26 2028-04-xx Bionic_Beaver " \
	    "ubuntu https://releases.ubuntu.com/focal/ubuntu-[0-9].*-desktop-amd64.iso                                                       preseed_ubuntu.cfg                          2020-04-23 2030-04-xx Focal_Fossa   " \
	    "ubuntu https://releases.ubuntu.com/hirsute/ubuntu-[0-9].*-desktop-amd64.iso                                                     preseed_ubuntu.cfg                          2021-04-22 2022-01-xx Hirsute_Hippo " \
	    "ubuntu http://cdimage.ubuntu.com/daily-live/current/impish-desktop-amd64.iso                                                    preseed_ubuntu.cfg                          2021-10-24 2022-07-xx Impish_Indri  " \
	    "ubuntu http://cdimage.ubuntu.com/daily-canary/current/impish-desktop-canary-amd64.iso                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2021-10-24 2022-07-xx Impish_Indri  " \
	    "debian http://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-lxde.iso                 preseed_debian.cfg                          2017-06-17 2022-06-30 oldoldstable  " \
	    "debian http://cdimage.debian.org/cdimage/archive/10.10.0-live/amd64/iso-hybrid/debian-live-10.10.0-amd64-lxde.iso               preseed_debian.cfg                          2019-07-06 2024-xx-xx oldstable     " \
	    "debian http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso               preseed_debian.cfg                          2021-08-14 20xx-xx-xx stable        " \
	    "debian http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                 preseed_debian.cfg                          20xx-xx-xx 20xx-xx-xx testing       " \
	)   # 区分  ダウンロード先URL                                                                                                        定義ファイル                                リリース日 サポ終了日 備考
#	    "ubuntu https://releases.ubuntu.com/groovy/ubuntu-[0-9].*-live-server-amd64.iso                                                  preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2020-10-22 2021-07-xx Groovy_Gorilla" \
#	    "ubuntu https://releases.ubuntu.com/groovy/ubuntu-[0-9].*-desktop-amd64.iso                                                      preseed_ubuntu.cfg                          2020-10-22 2021-07-22 Groovy_Gorilla" \

# -----------------------------------------------------------------------------
fncMenu () {
	local ARRY_NAME=()										# 配列展開
	local CODE_NAME=()										# 配列宣言
	local DIR_NAME											# ディレクトリ名
	local FIL_NAME											# ファイル名
	echo "#-----------------------------------------------------------------------------#"
	echo "#ID：Version                         ：リリース日：サポ終了日：備考           #"
	for ((I=1; I<=${#ARRAY_NAME[@]}; I++))
	do
		ARRY_NAME=(${ARRAY_NAME[$I-1]})
		CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
		CODE_NAME[1]=`basename ${ARRY_NAME[1]} | sed -e 's/.iso//ig'`	# DVDファイル名
		CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
		CODE_NAME[3]=${ARRY_NAME[2]}									# 定義ファイル
		CODE_NAME[4]=${ARRY_NAME[3]}									# リリース日
		CODE_NAME[5]=${ARRY_NAME[4]}									# サポ終了日
		CODE_NAME[6]=${ARRY_NAME[5]}									# 備考
		# ---------------------------------------------------------------------
		if [ "`echo ${CODE_NAME[1]} | sed -n '/\.\*/p'`" != "" ]; then
			DIR_NAME=`dirname ${CODE_NAME[2]}`
			FIL_NAME=`curl -L -l -R -S -s -f "${DIR_NAME}" 2> /dev/null | sed -n "s/.*\"\(${CODE_NAME[1]}.iso\)\".*/\1/p" | uniq`
			CODE_NAME[1]=`echo ${FIL_NAME} | sed -e 's/.iso//ig'`
			CODE_NAME[2]=`echo ${DIR_NAME}/${FIL_NAME}`
			ARRAY_NAME[$I-1]=`printf "%s %s %s %s %s %s" ${CODE_NAME[0]} ${CODE_NAME[2]} ${CODE_NAME[3]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}`
		fi
		# ---------------------------------------------------------------------
		printf "#%2d：%-32.32s：%-10.10s：%-10.10s：%-15.15s#\n" ${I} ${CODE_NAME[1]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}
	done
	echo "#-----------------------------------------------------------------------------#"
	if [ ${#INP_INDX} -le 0 ]; then							# 引数無しで入力スキップ
		echo "ID番号+Enterを入力して下さい。"
		read INP_INDX
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
fncPrint () {
	local RET_STR=""
	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -79 | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	if [ $? -ne 0 ]; then
		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -78 | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
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
fncRemaster () {
	# --- ARRAY_NAME ----------------------------------------------------------
	local ARRY_NAME=($1)											# 配列展開
	local CODE_NAME=()												# 配列宣言
	CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
	CODE_NAME[1]=`basename ${ARRY_NAME[1]} | sed -e 's/.iso//ig'`	# DVDファイル名
	CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
	CODE_NAME[3]=${ARRY_NAME[2]}									# 定義ファイル
	# -------------------------------------------------------------------------
	fncPrint "↓処理中：${CODE_NAME[0]}：${CODE_NAME[1]} -------------------------------------------------------------------------------"
	# --- DVD -----------------------------------------------------------------
	local DVD_NAME="${CODE_NAME[1]}"
	local DVD_URL="${CODE_NAME[2]}"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="${CODE_NAME[3]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}"
	# -------------------------------------------------------------------------
	umount -q ${WORK_DIRS}/${CODE_NAME[1]}/mnt > /dev/null 2>&1
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 22 ]; then return 1; fi
		else
			curl -L -R -S -s -f --connect-timeout 60 --dump-header "header.txt" "${DVD_URL}" || if [ $? -eq 22 ]; then return 1; fi
			local WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" != "${DVD_SIZE}" -o "${WEB_DATE}" != "${DVD_DATE}" ]; then
				curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 22 ]; then return 1; fi
			fi
			if [ -f "header.txt" ]; then
				rm -f "header.txt"
			fi
		fi
															# Volume ID
		if [ "`which volname 2> /dev/null`" != "" ]; then
			local VOLID=`volname "../${DVD_NAME}.iso"`
		else
			local VOLID=`LANG=C blkid -s LABEL "../${DVD_NAME}.iso" | sed -e 's/.*="\(.*\)"/\1/g'`
		fi
		# --- mnt -> image ----------------------------------------------------
		echo "--- copy DVD -> work directory ------------------------------------------------"
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
							echo "--- get splash.png ------------------------------------------------------------"
							curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
						else
							curl -L -R -S -s -f --connect-timeout 60 --dump-header "header.txt" "${WALL_URL}"
							WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
							WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
							WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
							FILE_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "../../../${WALL_FILE}"`
							FILE_SIZE=`echo ${FILE_INFO} | awk '{print $5;}'`
							FILE_DATE=`echo ${FILE_INFO} | awk '{print $6;}'`
							if [ "${WEB_SIZE}" != "${FILE_SIZE}" ] || [ "${WEB_DATE}" != "${FILE_DATE}" ]; then
								echo "--- get splash.png ------------------------------------------------------------"
								curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
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
					if [ -f "../../../${CFG_FILE}" ]; then
						cp --preserve=timestamps "../../../${CFG_FILE}" "preseed/preseed.cfg"
					else
						echo "--- get preseed.cfg -----------------------------------------------------------"
						curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "preseed/preseed.cfg" "${CFG_ADDR}" || if [ $? -eq 22 ]; then return 1; fi
					fi
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
							if [ -f "../../../${CFG_FILE}" ]; then
								cp --preserve=timestamps "../../../${CFG_FILE}" "nocloud/user-data"
							else
								echo "--- get user-data -------------------------------------------------------------"
								curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "nocloud/user-data" "${CFG_ADDR}" || if [ $? -eq 22 ]; then return 1; fi
							fi
							;;
#						*desktop* )							# --- get sub shell
#							SUB_PROG="ubuntu-sub_success_command.sh"
#							CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${SUB_PROG}~"`
#							if [ -f "../../../${SUB_PROG}" ]; then
#								cp --preserve=timestamps "../../../${SUB_PROG}" "preseed/${SUB_PROG}"
#							else
#								echo "--- get sub shell -------------------------------------------------------------"
#								curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "preseed/${SUB_PROG}" "${CFG_ADDR}" || if [ $? -eq 22 ]; then return 1; fi
#							fi
#							;;
						* )	;;
					esac
					;;
				"centos" | \
				"fedora" | \
				"rocky"  )	# --- get ks.cfg ----------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-kickstart"
					mkdir -p "kickstart"
					if [ -f "../../../${CFG_NAME}" ]; then
						cp --preserve=timestamps "../../../${CFG_NAME}" "kickstart/ks.cfg"
					else
						echo "--- get ks.cfg ----------------------------------------------------------------"
						curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "kickstart/ks.cfg" "${CFG_URL}" || if [ $? -eq 22 ]; then return 1; fi
					fi
					case "${WORK_DIRS}" in
						*net* )
							sed -i kickstart/ks.cfg     \
							    -e 's/^\(cdrom\)/#\1/g' \
							    -e 's/#\(url \)/\1/g'   \
							    -e 's/#\(repo \)/\1/g'
							;;
						*dvd* )
							sed -i kickstart/ks.cfg                              \
							    -e 's/#\(cdrom\)/\1/g'                           \
							    -e 's/^\(url \)/repo --name="New_Repository" /g'
							;;
					esac
					;;
				"suse")	# --- get autoinst.xml --------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-autoyast"
					mkdir -p "autoyast"
					if [ -f "../../../${CFG_NAME}" ]; then
						cp --preserve=timestamps "../../../${CFG_NAME}" "autoyast/autoinst.xml"
					else
						echo "--- get autoinst.xml ----------------------------------------------------------"
						curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "autoyast/autoinst.xml" "${CFG_URL}" || if [ $? -eq 22 ]; then return 1; fi
					fi
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
							# -------------------------------------------------
							LATE_CMD="\      in-target sed -i.orig /etc/apt/sources.list -e '/cdrom/ s/^ *\(deb\)/# \1/g'; \\\\\n"
							LATE_CMD+="      in-target apt -qq    update; \\\\\n"
							LATE_CMD+="      in-target apt -qq -y full-upgrade; \\\\\n"
							LATE_CMD+="      in-target apt -qq -y install ${LIST_PACK}; \\\\\n"
							LATE_CMD+="      in-target tasksel install ${LIST_TASK};"
							mount -r -o loop ./live/filesystem.squashfs ../mnt
							if [ -f ../media/usr/lib/systemd/system/connman.service ]; then
								LATE_CMD+=" \\\\\n      in-target systemctl disable connman.service;"
							fi
							umount ../mnt
							sed -i "preseed/preseed.cfg"                  \
							    -e '/preseed\/late_command/ s/#/ /g'      \
							    -e "/preseed\/late_command/a ${LATE_CMD}"
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
						*-bullseye-* | \
						*-testing-*  )
							sed -i "preseed/preseed.cfg"                                                 \
							    -e 's/#[ \t]\(d-i[ \t]*preseed\/late_command string\)/  \1/'             \
							    -e 's/#[ \t]\([ \t]*in-target systemctl disable connman.service\)/  \1/'
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
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry \"\(Install \)*Ubuntu\( Server\)*\"/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"\(Install \)*Ubuntu\( Server\)*\"/,/^}/p' boot/grub/grub.cfg | \
							sed -n '0,/\}/p'                                                                   | \
							sed -e '/menuentry/ s/ *Install *//'                                                 \
							    -e 's/\"\(Ubuntu.*\)\"/\"Auto Install \1\"/'                                     \
							    -e 's/file.*seed//'                                                              \
							    -e "s/\(vmlinuz\) */\1 ${INS_CFG} /"                                           | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                                 | \
							sed -e '1i set timeout=5'                                                            \
							    -e 's/\(set default\)="1"/\1="0"/'                                               \
							    -e 's/\(set timeout\).*$/\1=5/'                                                  \
							    -e 's/\(set gfxmode\)/# \1/g'                                                    \
							    -e 's/ vga=[0-9]*//g'                                                            \
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
							sed -n '/^menuentry \"Try Ubuntu.*\"\|\"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\"\(Try Ubuntu.*\)\"/\"\1 for Japanese language\"/'                 \
							    -e 's/\"\(Ubuntu\)\"/\"\1 for Japanese language\"/'                     | \
							sed -e "s~\(file\)~${INS_CFG} \1~"                                          | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                          | \
							sed -e 's/\(set default\)="1"/\1="0"/'                                        \
							    -e 's/\(set timeout\).*$/\1=5/'                                           \
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
							INS_ROW=$((`sed -n '/^menuentry "Try Ubuntu without installing"\|menuentry "Ubuntu"/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Install\|Ubuntu\"/,/^}/p' boot/grub/grub.cfg    | \
							sed -e 's/\"Install \(Ubuntu\)\"/\"Auto Install \1\"/'                  \
							    -e 's/\"\(Ubuntu\)\"/\"Auto Install \1\"/'                          \
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
							;;
						* )	;;
					esac
					# --- success_command -------------------------------------
					OLD_IFS=${IFS}
					IFS=$'\n'
#					LATE_CMD="\      /cdrom/preseed/ubuntu-sub_success_command.sh /cdrom/preseed/preseed.cfg /target;"
					# --- packages --------------------------------------------
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
					# ---------------------------------------------------------
					LATE_CMD="\      in-target sed -i.orig /etc/apt/sources.list -e '/cdrom/ s/^ *\(deb\)/# \1/g'; \\\\\n"
					LATE_CMD+="      in-target apt -qq    update; \\\\\n"
					LATE_CMD+="      in-target apt -qq -y full-upgrade; \\\\\n"
					LATE_CMD+="      in-target apt -qq -y install ${LIST_PACK}; \\\\\n"
					LATE_CMD+="      in-target tasksel install ${LIST_TASK};"
					# --- network ---------------------------------------------
					if [ -f ./install/filesystem.squashfs ]; then
						mount -r -o loop ./install/filesystem.squashfs ../mnt
					elif [ -f ./casper/filesystem.squashfs ]; then
						mount -r -o loop ./casper/filesystem.squashfs  ../mnt
					else
						mount -r -o loop ./casper/minimal.squashfs     ../mnt
					fi
					if [ -f ../mnt/usr/lib/systemd/system/connman.service ]; then
						LATE_CMD+=" \\\\\n      in-target systemctl disable connman.service;"
					fi
					IPV4_DHCP=`awk 'BEGIN {result="true";} !/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {if ($4=="true") result="false";} END {print result;}' preseed/preseed.cfg`
					if [ "${IPV4_DHCP}" != "true" ]; then
						ENET_NICS=`awk '!/#/&&/netcfg\/choose_interface/ {print $4;}' preseed/preseed.cfg`
						if [ "${ENET_NICS}" = "auto" -o "${ENET_NICS}" = "" ]; then
							ENET_NIC1=ens160
						else
							ENET_NIC1=${ENET_NICS}
						fi
						IPV4_ADDR=`awk '!/#/&&/netcfg\/get_ipaddress/    {print $4;}' preseed/preseed.cfg`
						IPV4_MASK=`awk '!/#/&&/netcfg\/get_netmask/      {print $4;}' preseed/preseed.cfg`
						IPV4_GWAY=`awk '!/#/&&/netcfg\/get_gateway/      {print $4;}' preseed/preseed.cfg`
						IPV4_NAME=`awk '!/#/&&/netcfg\/get_nameservers/  {print $4;}' preseed/preseed.cfg`
						NWRK_WGRP=`awk '!/#/&&/netcfg\/get_domain/       {print $4;}' preseed/preseed.cfg`
						IPV4_BITS=`fncIPv4GetNetmaskBits "${IPV4_MASK}"`
						if [ -d ../mnt/etc/netplan ]; then
							IPV4_YAML=$(IFS= cat <<- _EOT_ | xxd -ps | sed -z 's/\n//g'
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
_EOT_
							)
							LATE_CMD+=" \\\\\n      in-target bash -c \'echo \"${IPV4_YAML}\" | xxd -r -p > /etc/netplan/99-network-manager-static.yaml\'"
						else
							IPV4_NWRK=$(IFS= cat <<- _EOT_ | xxd -ps | sed -z 's/\n//g'
								
								allow-hotplug ${ENET_NIC1}
								iface ${ENET_NIC1} inet static
								    address ${IPV4_ADDR}
								    netmask ${IPV4_MASK}
								    gateway ${IPV4_GWAY}
								    dns-nameservers ${IPV4_NAME}
								    dns-search ${NWRK_WGRP}
_EOT_
							)
							LATE_CMD+=" \\\\\n      in-target bash -c \'echo \"${IPV4_NWRK}\" | xxd -r -p >> /etc/network/interfaces\'"
						fi
					fi
					umount ../mnt
					# --- success_command 変更 --------------------------------
					sed -i "preseed/preseed.cfg"                      \
					    -e '/ubiquity\/success_command/ s/#/ /g'      \
					    -e "/ubiquity\/success_command/a ${LATE_CMD}"
					IFS=${OLD_IFS}
					# ---------------------------------------------------------
					if [ -f "nocloud/user-data"      ]; then chmod 444 "nocloud/user-data";      fi
					if [ -f "nocloud/meta-data"      ]; then chmod 444 "nocloud/meta-data";      fi
					if [ -f "nocloud/vendor-data"    ]; then chmod 444 "nocloud/vendor-data";    fi
					if [ -f "nocloud/network-config" ]; then chmod 444 "nocloud/network-config"; fi
					if [ -f "preseed/preseed.cfg"    ]; then chmod 444 "preseed/preseed.cfg";    fi
#					if [ -f "preseed/${SUB_PROG}"    ]; then chmod 555 "preseed/${SUB_PROG}";    fi
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
					    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                 | \
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
			# -----------------------------------------------------------------
			echo "--- make iso file -------------------------------------------------------------"
			case "${CODE_NAME[0]}" in
				"debian" | \
				"ubuntu" | \
				"centos" | \
				"fedora" | \
				"rocky"  )	# ･････････････････････････････････････････････････
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
					    .
					;;
				* )	;;
			esac
			if [ "`which implantisomd5 2> /dev/nul`" != "" ]; then
				LANG=C implantisomd5 "../../${ISO_NAME}.iso"
			fi
		popd > /dev/null
	popd > /dev/null
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	fncPrint "↑処理済：${CODE_NAME[0]}：${CODE_NAME[1]} -------------------------------------------------------------------------------"
	return 0
}
# -----------------------------------------------------------------------------
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 作成処理を開始します。"
	echo "*******************************************************************************"
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
			if [ "`which aptitude 2> /dev/null`" != "" ]; then
				CMD_AGET="aptitude -y -q"
			else
				CMD_AGET="apt -y -qq"
			fi
			DIR_LINX="/usr/lib/ISOLINUX/isohdpfx.bin"
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`which dnf 2> /dev/null`" != "" ]; then
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
			if [ "`which xorriso 2> /dev/nul`" = ""       \
			-o   "`which implantisomd5 2> /dev/nul`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`which xorriso 2> /dev/nul`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ "`which implantisomd5 2> /dev/nul`" = "" ]; then
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
			if [ "`which xorriso 2> /dev/nul`" = ""       \
			-o   "`which implantisomd5 2> /dev/nul`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`which xorriso 2> /dev/nul`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ "`which implantisomd5 2> /dev/nul`" = "" ]; then
					${CMD_AGET} install isomd5sum
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					${CMD_AGET} install syslinux
				fi
			fi
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			if [ "`which xorriso 2> /dev/nul`" = ""       \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`which xorriso 2> /dev/nul`" = "" ]; then
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
	fncMenu
	# -------------------------------------------------------------------------
	for I in `eval echo "${INP_INDX}"`						# 連番可
	do
		if [ `fncIsInt "$I"` -eq 0 ] && [ $I -ge 1 ] && [ $I -le ${#ARRAY_NAME[@]} ]; then
			fncRemaster "${ARRAY_NAME[$I-1]}" || exit 1
		fi
	done
	# -------------------------------------------------------------------------
	ls -lthLgG "${WORK_DIRS}/"*.iso
# -----------------------------------------------------------------------------
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 作成処理が終了しました。"
	echo "*******************************************************************************"
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
#  10.0:buster           :2019-07-06:2022-xx-xx/2024-xx-xx[LTS]:oldstable
#  11.0:bullseye         :2021-08-14:                          :stable
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
#x12.04:Precise Pangolin :2012-04-26:2017-04-28/2019-04-xx:LTS
#x12.10:Quantal Quetzal  :2012-10-18:2014-05-16
#x13.04:Raring Ringtail  :2013-04-25:2014-01-27
#x13.10:Saucy Salamander :2013-10-17:2014-07-17
#x14.04:Trusty Tahr      :2014-04-17:2019-04-25/2022-04-xx:LTS
#x14.10:Utopic Unicorn   :2014-10-23:2015-07-23
#x15.04:Vivid Vervet     :2015-04-23:2016-02-04
#x15.10:Wily Werewolf    :2015-10-22:2016-07-28
# 16.04:Xenial Xerus     :2016-04-21:2021-04-xx/2024-04-xx:LTS
#x16.10:Yakkety Yak      :2016-10-13:2017-07-20
#x17.04:Zesty Zapus      :2017-04-13:2018-01-13
#x17.10:Artful Aardvark  :2017-10-19:2018-07-19
# 18.04:Bionic Beaver    :2018-04-26:2023-04-xx/2028-04-xx:LTS
#x18.10:Cosmic Cuttlefish:2018-10-18:2019-07-18
# 19.04:Disco Dingo      :2019-04-18:2020-01-23
# 19.10:Eoan Ermine      :2019-10-17:2020-07-17
# 20.04:Focal Fossa      :2020-04-23:2025-04-xx/2030-04-xx:LTS
# 20.10:Groovy Gorilla   :2020-10-22:2021-07-22
# 21.04:Hirsute Hippo    :2021-04-22:2022-01-xx
# 21.10:Impish Indri     :2021-10-14:2022-07-xx
# --- https://ja.wikipedia.org/wiki/CentOS ------------------------------------
# Ver.    :リリース日:RHEL      :メンテ期限:kernel
# 7.4-1708:2017-09-14:2017-08-01:2024-06-30: 3.10.0- 693
# 7.5-1804:2018-05-10:2018-04-10:2024-06-30: 3.10.0- 862
# 7.6-1810:2018-12-03:2018-10-30:2024-06-30: 3.10.0- 957
# 7.7-1908:2019-09-17:2019-08-06:2024-06-30: 3.10.0-1062
# 7.8-2003:2020-04-27:2020-03-30:2024-06-30: 3.10.0-1127
# 8.0-1905:2019-09-24:2019-05-07:2021-12-31: 4.18.0- 80
# 8.1-1911:2020-01-15:2019-11-05:2021-12-31: 4.18.0-147
# 8.2.2004:2020-06-15:2020-04-28:2021-12-31: 4.18.0-193
# 8.3.2011:2020-11-03:2020-12-07:2021-12-31: 4.18.0-240
# 8.4.2015:2021-06-03:2021-05-18:2021-12-31: 4.18.0-305
# --- https://ja.wikipedia.org/wiki/Rocky_Linux -------------------------------
# Ver. :リリース日:RHEL      :メンテ期限:kernel
#  8.4 :2021-06-21:2021-05-18:         : 4.18.0-305
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# Ver. :コードネーム     :リリース日:サポ期限  :kernel
#x27   :                 :2017-11-14:2018-11-27: 4.13
#x28   :                 :2018-05-01:2019-05-29: 4.16
#x29   :                 :2018-10-30:2019-11-26: 4.18
#x30   :                 :2019-04-29:2020-05-26: 5.0
#x31   :                 :2019-10-29:2020-11-24: 5.3
# 32   :                 :2020-04-28:2021-05-25: 5.6
# 33   :                 :2020-10-27:          : 5.8
# 34   :                 :2021-04-27:          : 5.11
# 35   :                 :2021-10-19:          : 
# --- https://ja.wikipedia.org/wiki/OpenSUSE ----------------------------------
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 15.2 :openSUSE Leap      :2020-07-02:2021-12-31: 5.3.18
# 15.3 :openSUSE Leap      :2021-06-02:          : 5.3.18
# xx.x :openSUSE Tumbleweed:20xx-xx-xx:20xx-xx-xx:
# -----------------------------------------------------------------------------
