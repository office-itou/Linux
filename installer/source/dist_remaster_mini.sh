#!/bin/bash
###############################################################################
##
##	ファイル名	:	dist_remaster_mini.sh
##
##	機能概要	:	ブータブルCDの作成用シェル [mini.iso/initrd版]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian / Ubuntu (64bit)
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
##	2022/05/10 000.0000 J.Itou         処理見直し
##	2022/05/11 000.0000 J.Itou         処理見直し
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
#	ARC_TYPE=i386											# CPUタイプ(32bit)
	ARC_TYPE=amd64											# CPUタイプ(64bit)
	ARRAY_NAME=(                                                                                                                                                                                                                                                                                                                  \
	    "debian         http://deb.debian.org/debian/dists/oldoldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                               -                                           preseed_debian.cfg                          2017-06-17 2022-06-xx oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://deb.debian.org/debian/dists/oldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                  -                                           preseed_debian.cfg                          2019-07-06 2024-06-xx oldstable       Debian_10.xx(buster)             " \
	    "debian         http://deb.debian.org/debian/dists/stable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                     -                                           preseed_debian.cfg                          2021-08-14 2026-xx-xx stable          Debian_11.xx(bullseye)           " \
	    "debian         https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/netboot/mini.iso                                                                   -                                           preseed_debian.cfg                          202x-xx-xx 20xx-xx-xx testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                         -                                           preseed_ubuntu.cfg                          2018-04-26 2028-04-26 bionic          Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/netboot/mini.iso                   -                                           preseed_ubuntu.cfg                          2020-04-23 2030-04-23 focal           Ubuntu_20.04(Focal_Fossa):LTS    " \
	)   # 区分          ダウンロード先URL                                                                                                                        別名                                        定義ファイル                                リリース日 サポ終了日 備考            備考2
# -----------------------------------------------------------------------------
	TXT_RESET="\033[m"
	TXT_ULINE="\033[4m"
	TXT_ULINERST="\033[24m"
	TXT_REV="\033[7m"
	TXT_REVRST="\033[27m"
	TXT_BLACK="\033[30m"
	TXT_RED="\033[31m"
	TXT_GREEN="\033[32m"
	TXT_YELLOW="\033[33m"
	TXT_BLUE="\033[34m"
	TXT_MAGENTA="\033[35m"
	TXT_CYAN="\033[36m"
	TXT_WHITE="\033[37m"
	TXT_BBLACK="\033[40m"
	TXT_BRED="\033[41m"
	TXT_BGREEN="\033[42m"
	TXT_BYELLOW="\033[43m"
	TXT_BBLUE="\033[44m"
	TXT_BMAGENTA="\033[45m"
	TXT_BCYAN="\033[46m"
	TXT_BWHITE="\033[47m"
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
		if [ ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then	# WEB情報取得失敗
			TXT_COLOR=${TXT_RED}
		else												# WEB取得取得成功
			FIL_INFO=($(echo "${WEB_INFO[@]}" | LANG=C sed -n "s/^.*<a href=.*> *\(${CODE_NAME[1]}\.iso\) *<\/a.*> *\([0-9a-zA-Z]*-[0-9a-zA-Z]*-[0-9a-zA-Z]*\) *\([0-9]*:[0-9]*\).*$/\1 \2 \3/p"))
			if [ "${FIL_INFO[2]:+UNSET}" = "" ]; then
				FIL_INFO[2]="00:00"
			fi
			CODE_NAME[1]=`echo "${FIL_INFO[0]}" | sed -e 's/.iso//ig'`	# dvd/net
			CODE_NAME[2]=`echo "${DIR_NAME}/${FIL_INFO[0]}"`
			CODE_NAME[4]=`date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y-%m-%d"`
			if [ "${CODE_NAME[1]}" = "mini" ]; then
				CODE_NAME[1]="mini-${ARRY_NAME[6]}-${ARC_TYPE}"			# mini.iso
			fi
		fi
		# ---------------------------------------------------------------------
		if [ "${ARRY_NAME[2]}" != "-" ]; then							# DVDファイル別名
			CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`
		fi
		# ---------------------------------------------------------------------
		if [ "${TXT_COLOR}" != "${TXT_RED}" ]; then
			if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
				TXT_COLOR=${TXT_YELLOW}
			else
				FIL_DATE=`date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y%m%d%H%M%S"`
				DVD_DATE=`ls -lL --time-style="+%Y%m%d%H%M%S" "${WORK_DIRS}/${CODE_NAME[1]}.iso" | awk '{print $6;}'`
				DST_FILE=`find "${WORK_DIRS}/" -regextype posix-basic -regex ".*/${CODE_NAME[1]}-\(autoyast\|kickstart\|nocloud\|preseed\).iso.*" -print`
				if [ "${DST_FILE}" = "" ]; then
					DST_DATE=""
					TXT_COLOR=${TXT_YELLOW}
				else
					DST_DATE=`ls -lL --time-style="+%Y%m%d%H%M%S" "${DST_FILE}" | awk '{print $6;}'`
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
					if [ ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then
						TXT_COLOR=${TXT_RED}
					else
						DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "${WORK_DIRS}/${CODE_NAME[1]}.iso"`
						DVD_SIZE=`echo "${DVD_INFO}" | awk '{print $5;}'`
						DVD_DATE=`echo "${DVD_INFO}" | awk '{print $6;}'`
						WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
						WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
						WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
						WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
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
fncRemaster () {
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
	set +e
	umount -q ${WORK_DIRS}/${CODE_NAME[1]}/mnt > /dev/null 2>&1
	set -e
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
			set +e
			curl -L -# -R -S -f --connect-timeout 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
		else
			set +e
			curl -L -R -S -s -f --connect-timeout 3 -I --dump-header "header.txt" "${DVD_URL}" > /dev/null || if [ $? -eq 22 -o $? -eq 28  ]; then return 1; fi
			set -e
			local WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" != "${DVD_SIZE}" -o "${WEB_DATE}" != "${DVD_DATE}" ]; then
				fncPrint "--- get ${DVD_NAME}.iso $(fncString ${COL_SIZE} '-')"
				set +e
				curl -L -# -R -S -f --connect-timeout 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 22 -o $? -eq 28  ]; then return 1; fi
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
				curl -L -# -R -S -f --connect-timeout 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 22 -o $? -eq 28  ]; then return 1; fi
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
			    .
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" != "" ]; then
				LANG=C implantisomd5 "../../${ISO_NAME}.iso"
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
			fncRemaster "${ARRAY_NAME[$I-1]}"
			if [ $? != 0 ]; then
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
	ls -lthLgG "${WORK_DIRS}/"*.iso 2> /dev/null
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
