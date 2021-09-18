#!/bin/bash
###############################################################################
##
##	ファイル名	:	live-custom.sh
##
##	機能概要	:	Live diskの作成用シェル [DVD版]
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
##	2021/08/21 000.0000 J.Itou         処理見直し
##	2021/08/28 000.0000 J.Itou         処理見直し
##	2021/09/05 000.0000 J.Itou         処理見直し
##	2021/09/18 000.0000 J.Itou         debian / ubuntu url見直し
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
	    "debian http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso   preseed_debian.cfg                          2017-06-17 2022-06-30 oldoldstable  " \
	    "debian http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso      preseed_debian.cfg                          2019-07-06 2024-xx-xx oldstable     " \
	    "debian http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9].*-amd64-lxde.iso               preseed_debian.cfg                          2021-08-14 20xx-xx-xx stable        " \
	    "debian http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                 preseed_debian.cfg                          20xx-xx-xx 20xx-xx-xx testing       " \
	    "ubuntu https://releases.ubuntu.com/bionic/ubuntu-[0-9].*-desktop-amd64.iso                                                      preseed_ubuntu.cfg                          2018-04-26 2023-04-xx Bionic_Beaver " \
	    "ubuntu https://releases.ubuntu.com/focal/ubuntu-[0-9].*-desktop-amd64.iso                                                       preseed_ubuntu.cfg                          2020-04-23 2025-04-xx Focal_Fossa   " \
	    "ubuntu https://releases.ubuntu.com/hirsute/ubuntu-[0-9].*-desktop-amd64.iso                                                     preseed_ubuntu.cfg                          2021-04-22 2022-01-xx Hirsute_Hippo " \
	    "ubuntu http://cdimage.ubuntu.com/daily-live/current/impish-desktop-amd64.iso                                                    preseed_ubuntu.cfg                          2021-10-24 2022-07-xx Impish_Indri  " \
	)   # 区分  ダウンロード先URL                                                                                                        定義ファイル                                リリース日 サポ終了日 備考

# -----------------------------------------------------------------------------
fncMenu () {
	local ARRY_NAME=()										# 配列展開
	local CODE_NAME=()										# 配列宣言
	local DIR_NAME											# ディレクトリ名
	local FIL_INFO=()										# ファイル情報
#	local FIL_NAME											# ファイル名
#	local FIL_DATE											# ファイル日付
#	local DVD_INFO											# DVD情報
#	local DVD_SIZE											# DVDサイズ
#	local DVD_DATE											# DVD日付
	local TXT_COLOR
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
#		if [ "`echo ${CODE_NAME[1]} | sed -n '/\.\*/p'`" != "" ]; then
			DIR_NAME=`dirname ${CODE_NAME[2]}`
			FIL_INFO=($(curl -L -l -R -S -s -f "${DIR_NAME}" 2> /dev/null | sed -n "s/.*>\(${CODE_NAME[1]}.iso\)<.*> *\([0-9A-Za-z]*-[0-9A-Za-z]*-[0-9A-Za-z]*\) *\([0-9]*:[0-9]*\).*<*.*/\1 \2 \3/p"))
#			FIL_DATE=`date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y%m%d%H%M"`
			CODE_NAME[1]=`echo ${FIL_INFO[0]} | sed -e 's/.iso//ig'`
			CODE_NAME[2]=`echo ${DIR_NAME}/${FIL_INFO[0]}`
			CODE_NAME[4]=`date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y-%m-%d"`
			ARRAY_NAME[$I-1]=`printf "%s %s %s %s %s %s" ${CODE_NAME[0]} ${CODE_NAME[2]} ${CODE_NAME[3]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}`
#		fi
		# ---------------------------------------------------------------------
		TXT_COLOR=false
		if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
			TXT_COLOR=true
		else
			DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M" "${WORK_DIRS}/${CODE_NAME[1]}.iso"`
			DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ `date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y%m%d%H%M"` -gt ${DVD_DATE} ]; then
				TXT_COLOR=true
			fi
		fi
		# ---------------------------------------------------------------------
		if [ "${TXT_COLOR}" = "true" ]; then
			printf "#%2d：%-32.32s：\033[31m%-10.10s\033[m：%-10.10s：%-15.15s#\n" ${I} ${CODE_NAME[1]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}
		else
			printf "#%2d：%-32.32s：%-10.10s：%-10.10s：%-15.15s#\n" ${I} ${CODE_NAME[1]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}
		fi
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
			EFI_IMAG="boot/grub/efi.img"
			ISO_NAME="${DVD_NAME}-custom-preseed"
			# -----------------------------------------------------------------
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
			if [ "`echo ${CFG_NAME} | awk -F ',' '{print $2;}'`" != "" ]; then
#				EFI_IMAG="boot/grub/efi.img"
				ISO_NAME="${DVD_NAME}-custom-nocloud"
				# -------------------------------------------------------------
				mkdir -p "nocloud"
				touch nocloud/user-data			# 必須
				touch nocloud/meta-data			# 必須
#				touch nocloud/vendor-data		# 省略可能
#				touch nocloud/network-config	# 省略可能
				CFG_FILE=`echo ${CFG_NAME} | awk -F ',' '{print $2;}'`
				CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${CFG_FILE}~"`
				if [ -f "../../../${CFG_FILE}" ]; then
					cp --preserve=timestamps "../../../${CFG_FILE}" "nocloud/user-data"
				else
					echo "--- get user-data -------------------------------------------------------------"
					curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "nocloud/user-data" "${CFG_ADDR}" || if [ $? -eq 22 ]; then return 1; fi
				fi
			fi
			# --- Get EFI Image -----------------------------------------------
			if [ ! -f ${EFI_IMAG} ]; then
				ISO_SKIPS=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $2;}'`
				ISO_COUNT=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $4;}'`
				dd if="../../${DVD_NAME}.iso" of=${EFI_IMAG} bs=512 skip=${ISO_SKIPS} count=${ISO_COUNT} status=none
			fi
			# --- mrb:txt.cfg / efi:grub.cfg ----------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )	# ･････････････････････････････････････････････････
					# === 日本語化 ============================================
					INS_CFG="locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp"
					# --- grub.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry \"Debian GNU\/Linux.*\"/,/^}/p' boot/grub/grub.cfg | \
					sed -e 's/\(Debian GNU\/Linux.*)\)/\1 for Japanese language/'            \
					    -e "s~\(components\)~\1 ${INS_CFG}~"                               | \
					sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       \
					    -e '1i set default=0'                                                \
					    -e '1i set timeout=5'                                                \
					> grub.cfg
					mv grub.cfg boot/grub/
					# --- menu.cfg --------------------------------------------
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
					# ---------------------------------------------------------
					sed -i isolinux/isolinux.cfg     \
					    -e 's/\(timeout\).*$/\1 50/'
					# === preseed =============================================
					INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
					# --- grub.cfg ----------------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry "Graphical Debian Installer"/ =' boot/grub/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry "Graphical Debian Installer"/,/^}/p' boot/grub/grub.cfg | \
					sed -e 's/\(menuentry "Graphical Debian\) \(Installer"\)/\1 Auto \2/'         \
					    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                                   | \
					sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                            \
					> grub.cfg
					mv grub.cfg boot/grub/
					# --- menu.cfg --------------------------------------------
					INS_ROW=$((`sed -n '/^LABEL Graphical Debian Installer/ =' isolinux/menu.cfg | head -n 1`-1))
					sed -n '/LABEL Graphical Debian Installer$/,/^$/p' isolinux/menu.cfg | \
					sed -e 's/^\(LABEL Graphical Debian\) \(Installer\)/\1 Auto \2/'       \
					    -e "s/\(APPEND.*\$\)/\1 ${INS_CFG}/"                             | \
					sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                      \
					> menu.cfg
					mv menu.cfg isolinux/
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
							    -e 's/fonts-noto-cjk-extra//'  \
							    -e 's/gnome-user-docs-ja//'    \
							    -e 's/firefox-esr-l10n-ja//'   \
							    -e 's/thunderbird-l10n-ja//'
							;;
						ubuntu-18.04* )
							sed -i "preseed/preseed.cfg"              \
							    -e 's/network-manager[,| ]*//'        \
							    -e 's/ubuntu-desktop-minimal[,| ]*//' \
							    -e 's/[,| ]*$//'
							;;
						impish-* )
							sed -i "preseed/preseed.cfg"                      \
							    -e 's/inxi[,| ]*//'                           \
							    -e 's/mozc-utils-gui[,| ]*//'                 \
							    -e 's/gnome-getting-started-docs-ja[,| ]*//'  \
							    -e 's/fonts-noto\([,| ]\)/fonts-noto-core\1/' \
							    -e 's/bind9utils\([,| ]\)/bind9-utils\1/'     \
							    -e 's/dnsutils\([,| ]\)/bind9-dnsutils\1/'    \
							    -e 's/[,| ]*$//'
							;;
						* )	;;
					esac
					if [ -f nocloud/user-data ]; then
						INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\""
						# --- grub.cfg ----------------------------------------
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
						# --- txt.cfg -----------------------------------------
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
							# --- isolinux.cfg --------------------------------
							sed -i isolinux/isolinux.cfg         \
							    -e 's/\(timeout\) .*/\1 50/'     \
							    -e '/ui gfxboot bootlogo/d'
							# --- menu.cfg ------------------------------------
							sed -i isolinux/menu.cfg             \
							    -e '/menu hshift .*/d'           \
							    -e '/menu width .*/d'            \
							    -e '/menu margin .*/d'
							# --- stdmenu.cfg ---------------------------------
							sed -i isolinux/stdmenu.cfg          \
							    -e 's/\(menu vshift\) .*/\1 9/'  \
							    -e '/menu rows .*/d'             \
							    -e '/menu helpmsgrow .*/d'       \
							    -e '/menu cmdlinerow .*/d'       \
							    -e '/menu timeoutrow .*/d'       \
							    -e '/menu tabmsgrow .*/d'
							# --- splash.png ----------------------------------
							cp -p ../../../${WALL_FILE} isolinux/splash.png
							chmod 444 "isolinux/splash.png"
						fi
					else
						# === 日本語化 ========================================
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
						# --- txt.cfg -----------------------------------------
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
							# --- isolinux.cfg --------------------------------
							sed -i isolinux/isolinux.cfg         \
							    -e 's/\(timeout\) .*/\1 50/'     \
							    -e '/ui gfxboot bootlogo/d'
							# --- menu.cfg ------------------------------------
							sed -i isolinux/menu.cfg             \
							    -e '/menu hshift .*/d'           \
							    -e '/menu width .*/d'            \
							    -e '/menu margin .*/d'
							# --- stdmenu.cfg ---------------------------------
							sed -i isolinux/stdmenu.cfg          \
							    -e 's/\(menu vshift\) .*/\1 9/'  \
							    -e '/menu rows .*/d'             \
							    -e '/menu helpmsgrow .*/d'       \
							    -e '/menu cmdlinerow .*/d'       \
							    -e '/menu timeoutrow .*/d'       \
							    -e '/menu tabmsgrow .*/d'
							# --- splash.png ----------------------------------
							cp -p ../../../${WALL_FILE} isolinux/splash.png
							chmod 444 "isolinux/splash.png"
						fi
						# === preseed =========================================
						INS_CFG="file=\/cdrom\/preseed\/preseed.cfg auto=true"
						# --- grub.cfg ----------------------------------------
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
						# --- txt.cfg -----------------------------------------
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
					fi
					# --- success_command -------------------------------------
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
						#	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg  | \
						#	           sed -z 's/\n//g'                                                                 | \
						#	           sed -e 's/.* multiselect *//'                                                      \
						#	               -e 's/[,|\\\\]//g'                                                             \
						#	               -e 's/\t/ /g'                                                                  \
						#	               -e 's/  */ /g'                                                                 \
						#	               -e 's/^ *//'`
						#	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg | \
						#	           sed -z 's/\n//g'                                                                 | \
						#	           sed -e 's/.* string *//'                                                           \
						#	               -e 's/[,|\\\\]//g'                                                             \
						#	               -e 's/\t/ /g'                                                                  \
						#	               -e 's/  */ /g'                                                                 \
						#	               -e 's/^ *//'`
						#	# -------------------------------------------------------------------------
						#	sed -i.orig /target/etc/apt/sources.list -e '/cdrom/ s/^ *(deb)/# 1/g'
						#	in-target apt -qq    update
						#	in-target apt -qq -y full-upgrade
						#	in-target apt -qq -y install ${LIST_PACK}
						#	in-target tasksel install ${LIST_TASK}
						#	if [ -f /target/usr/lib/systemd/system/connman.service ]; then
						#		in-target systemctl disable connman.service
						#	fi
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
					;;
				* )	;;
			esac
			# --- success_command ---------------------------------------------
			OLD_IFS=${IFS}
			IFS=$'\n'
			# --- packages ----------------------------------------------------
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
			# -----------------------------------------------------------------
			LATE_CMD="\      in-target sed -i.orig /etc/apt/sources.list -e '/cdrom/ s/^ *\(deb\)/# \1/g'; \\\\\n"
			LATE_CMD+="      in-target apt -qq    update; \\\\\n"
			LATE_CMD+="      in-target apt -qq -y full-upgrade; \\\\\n"
			LATE_CMD+="      in-target apt -qq -y install ${LIST_PACK}; \\\\\n"
			LATE_CMD+="      in-target tasksel install ${LIST_TASK};"
			if [ -f ./live/filesystem.squashfs ]; then
				mount -r -o loop ./live/filesystem.squashfs ../mnt
			elif [ -f ./install/filesystem.squashfs ]; then
				mount -r -o loop ./install/filesystem.squashfs ../mnt
			elif [ -f ./casper/filesystem.squashfs ]; then
				mount -r -o loop ./casper/filesystem.squashfs  ../mnt
			else
				mount -r -o loop ./casper/minimal.squashfs     ../mnt
			fi
			if [ -f ../mnt/usr/lib/systemd/system/connman.service ]; then
				LATE_CMD+=" \\\\\n      in-target systemctl disable connman.service;"
			fi
			umount ../mnt
			if [ -f preseed/sub_success_command.sh ]; then
				LATE_CMD+=" \\\\\n      /cdrom/preseed/sub_success_command.sh;"
			fi
			# --- success_command 変更 ----------------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )
					sed -i "preseed/preseed.cfg"                   \
					    -e '/preseed\/late_command/ s/#/ /g'       \
					    -e '/preseed\/late_command/ s/[,|\\\\]//g' \
					    -e '/preseed\/late_command/ s/$/ \\/g'     \
					    -e "/preseed\/late_command/a ${LATE_CMD}"
					;;
				"ubuntu" )
					sed -i "preseed/preseed.cfg"                       \
					    -e '/ubiquity\/success_command/ s/#/ /g'       \
					    -e '/ubiquity\/success_command/ s/[,|\\\\]//g' \
					    -e '/ubiquity\/success_command/ s/$/ \\/g'     \
					    -e "/ubiquity\/success_command/a ${LATE_CMD}"
					;;
				* )	;;
			esac
			# -----------------------------------------------------------------
			IFS=${OLD_IFS}
			# -----------------------------------------------------------------
			if [ -f "nocloud/user-data"              ]; then chmod 444 "nocloud/user-data";              fi
			if [ -f "nocloud/meta-data"              ]; then chmod 444 "nocloud/meta-data";              fi
			if [ -f "nocloud/vendor-data"            ]; then chmod 444 "nocloud/vendor-data";            fi
			if [ -f "nocloud/network-config"         ]; then chmod 444 "nocloud/network-config";         fi
			if [ -f "preseed/preseed.cfg"            ]; then chmod 444 "preseed/preseed.cfg";            fi
			if [ -f "preseed/sub_success_command.sh" ]; then chmod 544 "preseed/sub_success_command.sh"; fi
		popd > /dev/null
		# ---------------------------------------------------------------------
		OLD_IFS=${IFS}
		IFS=$'\n'
		INST_TASK=${LIST_TASK}
		INST_PACK=`echo "${LIST_PACK}" | sed -e 's/ isc-dhcp-server//'`
		IFS=${OLD_IFS}
		# ---------------------------------------------------------------------
		cat <<- _EOT_SH_ > ./decomp/setup.sh
			#!/bin/bash
			# -----------------------------------------------------------------------------
			 	set -m								# ジョブ制御を有効にする
			 	set -eu								# ステータス0以外と未定義変数の参照で終了
			 	echo "*******************************************************************************"
			 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : start [\$0]"
			 	echo "*******************************************************************************"
			# -- terminate ----------------------------------------------------------------
			fncEnd() {
			 	echo "--- terminate -----------------------------------------------------------------"
			 	RET_STS=\$1
			 	history -c
			 	echo "*******************************************************************************"
			 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : end [\$0]"
			 	echo "*******************************************************************************"
			 	exit \${RET_STS}
			}
			# プロセス制御処理 ------------------------------------------------------------
			fncProc () {
			 	local INP_NAME=\$1
			 	local INP_COMD=\$2
			 	if [ "\${INP_COMD}" = "" ]; then
			 		return
			 	fi
			 	if [ ! -f /etc/init.d/\${INP_NAME} ]; then
			 		echo "\${INP_NAME} service not found"
			 		return
			 	fi
			 	echo "\${INP_NAME} service is \${INP_COMD}"
			 	if [ -f /lib/systemd/system/\${INP_NAME}.service ]; then
			 		if [ "`which systemctl 2> /dev/null`" != "" ]; then
			 			systemctl \${INP_COMD} \${INP_NAME}
			 		elif [ "`which service 2> /dev/null`" != "" ]; then
			 			echo service \${INP_NAME} \${INP_COMD}
			 		fi
			 	else
			 		if [ -f /lib/systemd/systemd-sysv-install ]; then
			 			/lib/systemd/systemd-sysv-install \${INP_COMD} \${INP_NAME}
			 		fi
			 	fi
			}
			# -- initialize ---------------------------------------------------------------
			 	echo "--- initialize ----------------------------------------------------------------"
			 	trap 'fncEnd 1' 1 2 3 15
			 	export PS1="(chroot) "
			# system info -------------------------------------------------------------
			 	SYS_NAME=\`awk -F '=' '\$1=="ID"               {gsub("\\"",""); print \$2;}' /etc/os-release\`	# ディストリビューション名
			 	SYS_CODE=\`awk -F '=' '\$1=="VERSION_CODENAME" {gsub("\\"",""); print \$2;}' /etc/os-release\`	# コード名
			 	SYS_VERS=\`awk -F '=' '\$1=="VERSION"          {gsub("\\"",""); print \$2;}' /etc/os-release\`	# バージョン名
			 	SYS_VRID=\`awk -F '=' '\$1=="VERSION_ID"       {gsub("\\"",""); print \$2;}' /etc/os-release\`	# バージョン番号
			 	if [ "\${SYS_CODE}" = "" ]; then
			 		SYS_CODE=\`echo \${SYS_VERS} | awk -F ',' '{split(\$2,array," "); print tolower(array[1]);}'\`
			 	fi
			# -- Google Public DNS  -------------------------------------------------------
			 	if [ -f /etc/resolv.conf -o -L /etc/resolv.conf ]; then
			 		mv  /etc/resolv.conf /etc/resolv.conf.orig
			 	fi
			 	cat <<- _EOT_ > /etc/resolv.conf
			 		nameserver 8.8.8.8
			 		nameserver 8.8.4.4
			_EOT_
			# -- module install -----------------------------------------------------------
			#	APT_HOST=\`awk '(\$1~/^deb\$/)&&\$4=="main"&&(\$3!~/-/) {print \$2;}' /etc/apt/sources.list\`
			#	APT_SECU=\`awk '(\$1~/^deb\$/)&&\$4=="main"&&(\$3~/-security/) {print \$2;}' /etc/apt/sources.list\`
			#	APT_OPTI=\`awk '(\$1~/^deb\$/)&&\$4=="partner" {print \$2;}' /etc/apt/sources.list\`
			 	case "\${SYS_NAME}" in
			 		"debian" )
			 			APT_HOST="http://deb.debian.org/debian/"
			 			APT_SECU="http://security.debian.org/debian-security"
			 			APT_OPTI=""
			 			cat <<- _EOT_ > /etc/apt/sources.list
			 				deb     \${APT_HOST} \${SYS_CODE} main non-free contrib
			 				deb-src \${APT_HOST} \${SYS_CODE} main non-free contrib
			 				deb     \${APT_SECU} \${SYS_CODE}-security main non-free contrib
			 				deb-src \${APT_SECU} \${SYS_CODE}-security main non-free contrib
			 				deb     \${APT_HOST} \${SYS_CODE}-updates main non-free contrib
			 				deb-src \${APT_HOST} \${SYS_CODE}-updates main non-free contrib
			 				deb     \${APT_HOST} \${SYS_CODE}-backports main non-free contrib
			 				deb-src \${APT_HOST} \${SYS_CODE}-backports main non-free contrib
			_EOT_
			 			case "\${SYS_VRID}" in
			 				 9 | \
			 				10 )
			 					sed -i /etc/apt/sources.list    \\
			 					    -e '/security.debian.org/d'
			 					;;
			 				* ) ;;
			 			esac
			 			;;
			 		"ubuntu" )
			 			APT_HOST="http://jp.archive.ubuntu.com/ubuntu/"
			 			APT_SECU="http://security.ubuntu.com/ubuntu"
			 			APT_OPTI="http://archive.canonical.com/ubuntu"
			 			cat <<- _EOT_ > /etc/apt/sources.list
			 				deb     \${APT_HOST} \${SYS_CODE} main restricted universe multiverse
			 				deb-src \${APT_HOST} \${SYS_CODE} main restricted universe multiverse
			 				deb     \${APT_SECU} \${SYS_CODE}-security main restricted universe multiverse
			 				deb-src \${APT_SECU} \${SYS_CODE}-security main restricted universe multiverse
			 				deb     \${APT_HOST} \${SYS_CODE}-updates main restricted universe multiverse
			 				deb-src \${APT_HOST} \${SYS_CODE}-updates main restricted universe multiverse
			 				deb     \${APT_HOST} \${SYS_CODE}-backports main restricted universe multiverse
			 				deb-src \${APT_HOST} \${SYS_CODE}-backports main restricted universe multiverse
			 				deb     \${APT_OPTI} \${SYS_CODE} partner
			 				deb-src \${APT_OPTI} \${SYS_CODE} partner
			_EOT_
			 			;;
			 		* ) ;;
			 	esac
			 	echo "--- module install ------------------------------------------------------------"
			 	export DEBIAN_FRONTEND=noninteractive
			 	apt update       -q                                                    && \\
			 	apt full-upgrade -q -y                                                 && \\
			 	apt install      -q -y ${INST_PACK}                                    && \\
			 	apt autoremove   -q -y                                                 && \\
			 	apt autoclean    -q -y                                                 && \\
			 	apt clean        -q -y                                                 || \\
			 	fncEnd 1
			 	echo "--- task install --------------------------------------------------------------"
			 	tasksel install ${INST_TASK}                                           || \\
			 	fncEnd 1
			 	echo "--- google chrome install -----------------------------------------------------"
			 	echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
			 	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
			 	if [ -f Release.key ]; then rm -f Release.key; fi
			 	apt update       -q                                                    && \\
			 	apt install      -q -y google-chrome-stable                            || \\
			 	fncEnd 1
			# -- localize -----------------------------------------------------------------
			 	echo "--- localize ------------------------------------------------------------------"
			 	sed -i /etc/locale.gen                  \\
			 	    -e 's/^[A-Za-z]/# &/g'              \\
			 	    -e 's/# \\(ja_JP.UTF-8 UTF-8\\)/\\1/g' \\
			 	    -e 's/# \\(en_US.UTF-8 UTF-8\\)/\\1/g'
			 	locale-gen
			 	update-locale LANG="ja_JP.UTF-8" LANGUAGE="ja:en"
			 	localectl set-x11-keymap --no-convert "jp,us" "pc105"
			# -- mozc ---------------------------------------------------------------------
			 	sed -i /usr/share/ibus/component/mozc.xml                                     \\
			 	    -e '/<engine>/,/<\\/engine>/ s/\\(<layout>\\)default\\(<\\/layout>\\)/\\1jp\\2/g'
			# -- clamav -------------------------------------------------------------------
			 	if [ -f /etc/clamav/freshclam.conf ]; then
			 		echo "--- clamav --------------------------------------------------------------------"
			 		sed -i /etc/clamav/freshclam.conf \\
			 		    -e 's/^NotifyClamd/#&/'
			 	fi
			# -- sshd ---------------------------------------------------------------------
			 	if [ -f /etc/ssh/sshd_config ]; then
			 		echo "--- sshd ----------------------------------------------------------------------"
			 		sed -i /etc/ssh/sshd_config                          \\
			 		    -e 's/^\\(PermitRootLogin\\) .*/\\1 yes/'           \\
			 		    -e 's/#\\(PasswordAuthentication\\) .*/\\1 yes/'    \\
			 		    -e 's/#\\(PermitEmptyPasswords\\) .*/\\1 yes/'      \\
			 		    -e 's/#\\(UsePAM\\) .*/\\1 yes/'                    \\
			 		    -e '/HostKey \\/etc\\/ssh\\/ssh_host_ecdsa_key/d'   \\
			 		    -e '/HostKey \\/etc\\/ssh\\/ssh_host_ed25519_key/d' \\
			 		    -e '\$aUseDNS no\\nIgnoreUserKnownHosts no'
			 	fi
			# -- ftpd ---------------------------------------------------------------------
			 	if [ -f /etc/vsftpd.conf ]; then
			 		echo "--- ftpd ----------------------------------------------------------------------"
			 		touch /etc/ftpusers					#
			 		touch /etc/vsftpd.conf				#
			 		touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
			 		touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
			 		touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
			 		touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
			 		# -------------------------------------------------------------------------
			 		chmod 0600 /etc/ftpusers               \\
			 				   /etc/vsftpd.conf            \\
			 				   /etc/vsftpd.chroot_list     \\
			 				   /etc/vsftpd.user_list       \\
			 				   /etc/vsftpd.banned_emails   \\
			 				   /etc/vsftpd.email_passwords
			 		# -------------------------------------------------------------------------
			 		sed -i /etc/ftpusers \\
			 		    -e 's/root/# &/'
			 		# -------------------------------------------------------------------------
			 		sed -i /etc/vsftpd.conf                                           \\
			 		    -e 's/^\\(listen\\)=.*\$/\\1=NO/'                                 \\
			 		    -e 's/^\\(listen_ipv6\\)=.*\$/\\1=YES/'                           \\
			 		    -e 's/^\\(anonymous_enable\\)=.*\$/\\1=NO/'                       \\
			 		    -e 's/^\\(local_enable\\)=.*\$/\\1=YES/'                          \\
			 		    -e 's/^#\\(write_enable\\)=.*\$/\\1=YES/'                         \\
			 		    -e 's/^#\\(local_umask\\)=.*\$/\\1=022/'                          \\
			 		    -e 's/^\\(dirmessage_enable\\)=.*\$/\\1=NO/'                      \\
			 		    -e 's/^\\(use_localtime\\)=.*\$/\\1=YES/'                         \\
			 		    -e 's/^\\(xferlog_enable\\)=.*\$/\\1=YES/'                        \\
			 		    -e 's/^\\(connect_from_port_20\\)=.*\$/\\1=YES/'                  \\
			 		    -e 's/^#\\(xferlog_std_format\\)=.*\$/\\1=NO/'                    \\
			 		    -e 's/^#\\(idle_session_timeout\\)=.*\$/\\1=300/'                 \\
			 		    -e 's/^#\\(data_connection_timeout\\)=.*\$/\\1=30/'               \\
			 		    -e 's/^#\\(ascii_upload_enable\\)=.*\$/\\1=YES/'                  \\
			 		    -e 's/^#\\(ascii_download_enable\\)=.*\$/\\1=YES/'                \\
			 		    -e 's/^#\\(chroot_local_user\\)=.*\$/\\1=NO/'                     \\
			 		    -e 's/^#\\(chroot_list_enable\\)=.*\$/\\1=NO/'                    \\
			 		    -e "s~^#\\(chroot_list_file\\)=.*\$~\\1=/etc/vsftpd.chroot_list~" \\
			 		    -e 's/^#\\(ls_recurse_enable\\)=.*\$/\\1=YES/'                    \\
			 		    -e 's/^\\(pam_service_name\\)=.*\$/\\1=vsftpd/'                   \\
			 		    -e '\$atcp_wrappers=YES'                                       \\
			 		    -e '\$auserlist_enable=YES'                                    \\
			 		    -e '\$auserlist_deny=YES'                                      \\
			 		    -e "\\\$auserlist_file=/etc\\/vsftpd.user_list"                  \\
			 		    -e '\$achmod_enable=YES'                                       \\
			 		    -e '\$aforce_dot_files=YES'                                    \\
			 		    -e '\$adownload_enable=YES'                                    \\
			 		    -e '\$avsftpd_log_file=\\/var\\/log\\/vsftpd\\.log'                \\
			 		    -e '\$adual_log_enable=NO'                                     \\
			 		    -e '\$asyslog_enable=NO'                                       \\
			 		    -e '\$alog_ftp_protocol=NO'                                    \\
			 		    -e '\$aftp_data_port=20'                                       \\
			 		    -e '\$apasv_enable=YES'
			 	fi
			# -- smb ----------------------------------------------------------------------
			 	if [ -f /etc/samba/smb.conf ]; then
			 		echo "--- smb.conf ------------------------------------------------------------------"
			 		testparm -s /etc/samba/smb.conf | sed -e '/global/ ados charset = CP932\\nclient ipc min protocol = NT1\\nclient min protocol = NT1\\nserver min protocol = NT1\\nidmap config * : range = 1000-10000\\n' > smb.conf
			 		testparm -s smb.conf > /etc/samba/smb.conf
			 		rm -f smb.conf
			 	fi
			# -- root and user's setting --------------------------------------------------
			 	echo "--- root and user's setting ---------------------------------------------------"
			 	for TARGET in "/etc/skel" "/root"
			 	do
			 		pushd \${TARGET} > /dev/null
			 			echo "---- .bashrc ------------------------------------------------------------------"
			 			cat <<- '_EOT_' >> .bashrc
			 				# --- 日本語文字化け対策 ---
			 				case "\\\${TERM}" in
			 				    "linux" ) export LANG=C;;
			 				    * )                    ;;
			 				esac
			 				# export GTK_IM_MODULE=ibus
			 				# export XMODIFIERS=@im=ibus
			 				# export QT_IM_MODULE=ibus
			_EOT_
			 			echo "---- .vimrc -------------------------------------------------------------------"
			 			cat <<- '_EOT_' > .vimrc
			 				set number              " Print the line number in front of each line.
			 				set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
			 				set list                " List mode: Show tabs as CTRL-I is displayed, display \\\$ after end of line.
			 				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
			 				set nowrap              " This option changes how text is displayed.
			 				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
			 				set laststatus=2        " The value of this option influences when the last window will have a status line always.
			 				syntax on               " Vim5 and later versions support syntax highlighting.
			_EOT_
			 			if [ "`which vim 2> /dev/null`" = "" ]; then
			 					sed -i .vimrc                    \\
			 					    -e 's/^\\(syntax on\\)/\\" \\1/'
			 			fi
			 			echo "---- .curlrc ------------------------------------------------------------------"
			 			cat <<- '_EOT_' > .curlrc
			 				location
			 				progress-bar
			 				remote-time
			 				show-error
			_EOT_
			 		popd > /dev/null
			 	done
			# -- service ------------------------------------------------------------------
			 	echo "--- service -------------------------------------------------------------------"
			#	fncProc clamav-freshclam disable
			#	fncProc ssh              enable
			#	fncProc apache2          disable
			#	fncProc vsftpd           disable
			#	if [ -f /lib/systemd/system/bind9.service ]; then
			#		fncProc bind9            enable
			#	else
			#		fncProc named            enable
			#	fi
			#	fncProc isc-dhcp-server  disable
			#	if [ -f /etc/init.d/isc-dhcp-server6 ]; then
			#		fncProc isc-dhcp-server6 disable
			#	fi
			#	fncProc smbd             enable
			#	fncProc nmbd             enable
			 	if [ -f /lib/systemd/system/connman.service ]; then
			 		fncProc connman.service  disable
			 	fi
			# -- swap off -----------------------------------------------------------------
			#	echo "--- swap off ------------------------------------------------------------------"
			#	swapoff -a
			# -- cleaning -----------------------------------------------------------------
			 	echo "--- cleaning ------------------------------------------------------------------"
			 	rm -f /etc/resolv.conf
			 	if [ -f /etc/resolv.conf.orig -o -L /etc/resolv.conf.orig ]; then
			 		mv /etc/resolv.conf.orig /etc/resolv.conf
			 	fi
			 	fncEnd 0
			# -- EOF ----------------------------------------------------------------------
			# *****************************************************************************
			# <memo>
			#   [im-config]
			#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
			# *****************************************************************************
_EOT_SH_
		sed -i ./decomp/setup.sh -e 's/^ //g'
		# --- copy media -> fsimg ---------------------------------------------
		echo "--- copy media -> fsimg -------------------------------------------------------"
		if [ -f ./image/live/filesystem.squashfs ]; then
			mount -r -o loop ./image/live/filesystem.squashfs    ./mnt
		elif [ -f ./image/install/filesystem.squashfs ]; then
			mount -r -o loop ./image/install/filesystem.squashfs ./mnt
		elif [ -f ./image/casper/filesystem.squashfs ]; then
			mount -r -o loop ./image/casper/filesystem.squashfs  ./mnt
		elif [ -f ./image/casper/minimal.squashfs ]; then
			mount -r -o loop ./image/casper/minimal.squashfs     ./mnt
		fi
		pushd ./mnt > /dev/null
			find . -depth -print | cpio -pdm --quiet ../decomp/
		popd > /dev/null
		umount ./mnt
		# ---------------------------------------------------------------------
		rm -f ./decomp/etc/localtime
		ln -s /usr/share/zoneinfo/Asia/Tokyo ./decomp/etc/localtime
		# ---------------------------------------------------------------------
		mount --bind /run     ./decomp/run
		mount --bind /dev     ./decomp/dev
		mount --bind /dev/pts ./decomp/dev/pts
		mount --bind /proc    ./decomp/proc
#		mount --bind /sys     ./decomp/sys
		# ---------------------------------------------------------------------
		LANG=C chroot ./decomp /bin/bash /setup.sh
		RET_STS=$?
		# ---------------------------------------------------------------------
#		umount ./decomp/sys     || umount -lf ./decomp/sys
		umount ./decomp/proc    || umount -lf ./decomp/proc
		umount ./decomp/dev/pts || umount -lf ./decomp/dev/pts
		umount ./decomp/dev     || umount -lf ./decomp/dev
		umount ./decomp/run     || umount -lf ./decomp/run
		# ---------------------------------------------------------------------
		if [ ${RET_STS} -ne 0 ]; then
			exit ${RET_STS}
		fi
		# ---------------------------------------------------------------------
		find   ./decomp/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
		rm -rf ./decomp/root/.bash_history           \
		       ./decomp/root/.viminfo                \
		       ./decomp/tmp/*                        \
		       ./decomp/var/cache/apt/*.bin          \
		       ./decomp/var/cache/apt/archives/*.deb \
		       ./decomp/setup.sh
		# ---------------------------------------------------------------------
		case "${CODE_NAME[0]}" in
			"debian" )	# ･････････････････････････････････････････････････････
				;;
			"ubuntu" )	# ･････････････････････････････････････････････････････
				rm ./image/casper/filesystem.size                    \
				   ./image/casper/filesystem.manifest                \
				   ./image/casper/filesystem.manifest-remove         
#				   ./image/casper/filesystem.manifest-minimal-remove 
				# -------------------------------------------------------------
				touch ./image/casper/filesystem.size
				touch ./image/casper/filesystem.manifest
				touch ./image/casper/filesystem.manifest-remove
#				touch ./image/casper/filesystem.manifest-minimal-remove
				# -------------------------------------------------------------
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
		# --- copy fsimg -> media ---------------------------------------------
		case "${CODE_NAME[0]}" in
			"debian" )	# ･････････････････････････････････････････････････････
				echo "--- copy fsimg -> media -------------------------------------------------------"
				rm -f ./image/live/filesystem.squashfs
				mksquashfs ./decomp ./image/live/filesystem.squashfs -mem 1G
				ls -lht ./image/live/filesystem.squashfs
				FSIMG_SIZE=`LANG=C ls -lh ./image/live/filesystem.squashfs | awk '{print $5;}'`
				;;
			"ubuntu" )	# ･････････････････････････････････････････････････････
				rm -f ./image/casper/filesystem.squashfs
				mksquashfs ./decomp ./image/casper/filesystem.squashfs -mem 1G
				ls -lht ./image/casper/filesystem.squashfs
				FSIMG_SIZE=`LANG=C ls -lh ./image/casper/filesystem.squashfs | awk '{print $5;}'`
				;;
			* )	;;
		esac
		# --- image -> dvd ----------------------------------------------------
		pushd image > /dev/null								# 作業用ディスクイメージ
			echo "--- make iso file -------------------------------------------------------------"
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
			if [ "`which implantisomd5 2> /dev/null`" != "" ]; then
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
			if [ "`which debootstrap 2> /dev/null`" = ""  \
			-o   "`which mksquashfs 2> /dev/null`" = ""    \
			-o   "`which xorriso 2> /dev/null`" = ""       \
			-o   "`which implantisomd5 2> /dev/null`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				LST_PACK=""
				if [ "`which debootstrap 2> /dev/null`" = "" ]; then
					LST_PACK+=" debootstrap"
				fi
				if [ "`which mksquashfs 2> /dev/null`" = "" ]; then
					LST_PACK+=" squashfs-tools"
				fi
				if [ "`which xorriso 2> /dev/null`" = "" ]; then
					LST_PACK+=" xorriso"
				fi
				if [ "`which implantisomd5 2> /dev/null`" = "" ]; then
					LST_PACK+=" isomd5sum"
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					LST_PACK+=" isolinux"
				fi
				${CMD_AGET} update
				${CMD_AGET} install ${LST_PACK}
			fi
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`which xorriso 2> /dev/null`" = ""       \
			-o   "`which implantisomd5 2> /dev/null`" = "" \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`which xorriso 2> /dev/null`" = "" ]; then
					${CMD_AGET} install xorriso
				fi
				if [ "`which implantisomd5 2> /dev/null`" = "" ]; then
					${CMD_AGET} install isomd5sum
				fi
				if [ ! -f "${DIR_LINX}" ]; then
					${CMD_AGET} install syslinux
				fi
			fi
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			if [ "`which xorriso 2> /dev/null`" = ""       \
			-o   ! -f "${DIR_LINX}" ]; then
				${CMD_AGET} update
				if [ "`which xorriso 2> /dev/null`" = "" ]; then
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
	ls -lthLgG "${WORK_DIRS}/"*.iso 2> /dev/null
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
