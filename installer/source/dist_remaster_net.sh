#!/bin/bash
###############################################################################
##
##	ファイル名	:	dist_remaster_net.sh
##
##	機能概要	:	ブータブルDVDの作成用シェル [netinst版]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian
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
##	2018/05/13 000.0000 J.Itou         新規作成
##	2018/06/14 000.0000 J.Itou         不具合修正(CentOS7対応含む)
##	2018/06/24 000.0000 J.Itou         debian 8.11 変更
##	2018/06/29 000.0000 J.Itou         Fedora 28追加
##	2018/07/07 000.0000 J.Itou         CentOS 7追加
##	2018/07/07 000.0000 J.Itou         仕様見直し
##	2018/07/15 000.0000 J.Itou         debian 9.5.0 変更
##	2018/11/06 000.0000 J.Itou         fedora 29 変更
##	2018/11/11 000.0000 J.Itou         debian 9.6.0 変更
##	2019/01/09 000.0000 J.Itou         debianファイル名修正/CentOS 7 1810変更
##	2018/11/11 000.0000 J.Itou         debian 9.7.0 変更
##	2019/02/17 000.0000 J.Itou         debian 9.8.0 変更
##	2019/02/06 000.0000 J.Itou         不具合修正
##	2019/07/09 000.0000 J.Itou         最新化修正
##	2019/09/08 000.0000 J.Itou         debian 9.10.0/10.1.0 変更
##	2019/09/10 000.0000 J.Itou         debian 9.11.0 変更
##	2019/09/18 000.0000 J.Itou         CentOS 7.7.1908 変更
##	2019/09/28 000.0000 J.Itou         CentOS 8.0.1905 追加
##	2019/11/17 000.0000 J.Itou         debian 10.2.0 変更
##	2019/11/23 000.0000 J.Itou         fedora 31 変更
##	2019/11/24 000.0000 J.Itou         CentOS Stream 追加
##	2019/11/29 000.0000 J.Itou         USBメモリーでのインストール対応
##	2020/02/22 000.0000 J.Itou         debian 9.12.0/10.3.0 変更 / CentOS 8.1 追加 / CentOS-Stream-8-x86_64-20191219-boot 変更
##	2020/02/22 000.0000 J.Itou         wget -> curl 変更
##	2020/05/05 000.0000 J.Itou         不具合修正
##	2020/05/11 000.0000 J.Itou         debian 10.4.0 変更 / fedora 32 変更
##	2020/07/10 000.0000 J.Itou         CentOS 8.2.2004 変更
##	2020/07/20 000.0000 J.Itou         debian 9.13.0 変更
##	2020/08/02 000.0000 J.Itou         debian 10.5.0 / CentOS-Stream-8-x86_64-20200730-boot 変更
##	2020/08/09 000.0000 J.Itou         CentOS-Stream-8-x86_64-20200801-boot 変更
##	2020/09/27 000.0000 J.Itou         debian 10.6.0 / CentOS-Stream-8-x86_64-20200921-boot 変更
##	2020/10/06 000.0000 J.Itou         CentOS-Stream-8-x86_64-20200928-boot 変更
##	2020/10/13 000.0000 J.Itou         CentOS-Stream-8-x86_64-20201007-boot 変更
##	2020/10/14 000.0000 J.Itou         openSUSE Leap / Tumbleweed 対応
##	2020/11/04 000.0000 J.Itou         memo修正 / fedora 33 変更
##	2020/11/11 000.0000 J.Itou         追加アプリ導入処理追加
##	2020/11/21 000.0000 J.Itou         不具合修正
##	2020/12/06 000.0000 J.Itou         debian 10.7.0 / CentOS-Stream-8-x86_64-20201203-boot 変更
##	2020/12/15 000.0000 J.Itou         CentOS 8.3.2011 / CentOS-Stream-8 20201211 変更
##	2020/12/20 000.0000 J.Itou         openSUSE Leap 15.3 追加
##	2021/01/11 000.0000 J.Itou         debian-testingをdaily-buildsに変更
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
	readonly ARRAY_NAME=(                                                                                                                                                                                 \
	    "debian debian-8.11.1-amd64-netinst            https://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-cd/debian-8.11.1-amd64-netinst.iso                               preseed_debian.cfg"   \
	    "debian debian-9.13.0-amd64-netinst            https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso                               preseed_debian.cfg"   \
	    "debian debian-10.7.0-amd64-netinst            https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso                              preseed_debian.cfg"   \
	    "debian debian-testing-amd64-netinst           https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso              preseed_debian.cfg"   \
	    "centos CentOS-8.3.2011-x86_64-boot            http://ftp.iij.ad.jp/pub/linux/centos/8.3.2011/isos/x86_64/CentOS-8.3.2011-x86_64-boot.iso                                   kickstart_centos.cfg" \
	    "centos CentOS-Stream-8-x86_64-20201211-boot   http://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20201211-boot.iso                          kickstart_centos.cfg" \
	    "fedora Fedora-Server-netinst-x86_64-33-1.2    https://download.fedoraproject.org/pub/fedora/linux/releases/33/Server/x86_64/iso/Fedora-Server-netinst-x86_64-33-1.2.iso    kickstart_fedora.cfg" \
	    "suse   openSUSE-Leap-15.2-NET-x86_64          http://download.opensuse.org/distribution/leap/15.2/iso/openSUSE-Leap-15.2-NET-x86_64.iso                                    yast_opensuse15.xml"  \
	    "suse   openSUSE-Tumbleweed-NET-x86_64-Current http://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                       yast_opensuse16.xml"  \
	)   # 区分  netinstファイル名                      ダウンロード先URL                                                                                                            定義ファイル
#	    "debian debian-testing-amd64-netinst           https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso                               preseed_debian.cfg"   \
#	    "suse   openSUSE-Leap-15.3-NET-x86_64-Current  http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-NET-x86_64-Current.iso                            yast_opensuse153.xml" \
# -----------------------------------------------------------------------------
fncMenu () {
	echo "# ----------------------------------------------------------------------------#"
	echo "# ID：Version                            ：リリース日：サポ終了日：備考       #"
	echo "#  1：debian-8.11.1-amd64-netinst        ：2015-04-25：2020-06-30：oldoldstable"
	echo "#  2：debian-9.13.0-amd64-netinst        ：2017-06-17：2022-06-xx：oldstable  #"
	echo "#  3：debian-10.7.0-amd64-netinst        ：2019-07-06：20xx-xx-xx：stable     #"
	echo "#  4：debian-testing-amd64-netinst       ：20xx-xx-xx：20xx-xx-xx：testing    #"
	echo "#  5：CentOS-8.3.2011-x86_64-boot        ：2020-06-15：2021-12-31：RHEL 8.0   #"
	echo "#  6：CentOS-Stream-8-x86_64-20201211-boo：20xx-xx-xx：20xx-xx-xx：RHEL x.x   #"
	echo "#  7：Fedora-Server-netinst-x86_64-33-1.2：2020-10-27：20xx-xx-xx：kernel 5.8 #"
	echo "#  8：openSUSE-Leap-15.2-NET-x86_64      ：2020-07-02：2021-11-xx：kernel 5.3 #"
	echo "#  9：openSUSE-Tumbleweed-NET-x86_64-Curr：20xx-xx-xx：20xx-xx-xx：           #"
	echo "# ----------------------------------------------------------------------------#"
	echo "ID番号+Enterを入力して下さい。"
	read INP_INDX
#	echo "#   ：openSUSE-Leap-15.3-NET-x86_64-Curre：20xx-xx-xx：20xx-xx-xx：           #"
}
# -----------------------------------------------------------------------------
fncIsInt () {
	set +e
	expr ${1:-""} + 1 > /dev/null 2>&1
	if [ $? -ge 2 ]; then echo 1; else echo 0; fi
	set -e
}
# -----------------------------------------------------------------------------
fncRemaster () {
	# --- ARRAY_NAME ----------------------------------------------------------
	local CODE_NAME=($1)									# 配列展開
	echo "↓処理中：${CODE_NAME[0]}：${CODE_NAME[1]} -------------------------------"
	# --- DVD -----------------------------------------------------------------
	local DVD_NAME="${CODE_NAME[1]}"
	local DVD_URL="${CODE_NAME[2]}"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="${CODE_NAME[3]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}"
	# -------------------------------------------------------------------------
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || { exit 1; }
		else
			curl -f -L -s --connect-timeout 60 --dump-header "header.txt" "${DVD_URL}"
			local WEB_STAT=`cat header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" != "${DVD_SIZE}" -o "${WEB_DATE}" != "${DVD_DATE}" ]; then
				curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || { exit 1; }
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
		mount -r -o loop "../${DVD_NAME}.iso" mnt
		pushd mnt > /dev/null								# 作業用マウント先
			find . -depth -print | cpio -pdm ../image/
		popd > /dev/null
		umount mnt
		# --- image -----------------------------------------------------------
		pushd image > /dev/null								# 作業用ディスクイメージ
			# --- preseed.cfg -> image ----------------------------------------
			case "${CODE_NAME[0]}" in
				"debian" | \
				"ubuntu" )
					case "${CODE_NAME[1]}" in
						ubuntu*20.04*live*    | \
						ubuntu*20.10*live*    | \
						ubuntu*20.04*desktop* | \
						ubuntu*20.10*desktop* )				# --- get user-data
							EFI_IMAG="boot/grub/efi.img"
							ISO_NAME="${DVD_NAME}-nocloud"
							mkdir -p "nocloud"
							touch nocloud/meta-data
							touch nocloud/user-data
							if [ -f "../../../${CFG_NAME}" ]; then
								cp --preserve=timestamps "../../../${CFG_NAME}" "nocloud/user-data"
							else
								curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "nocloud/user-data" "${CFG_URL}" || { exit 1; }
							fi
							;;
						* )									# --- get preseed.cfg
							EFI_IMAG="boot/grub/efi.img"
							ISO_NAME="${DVD_NAME}-preseed"
							mkdir -p "preseed"
							if [ -f "../../../${CFG_NAME}" ]; then
								cp --preserve=timestamps "../../../${CFG_NAME}" "preseed/preseed.cfg"
							else
								curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "preseed/preseed.cfg" "${CFG_URL}" || { exit 1; }
							fi
							;;
					esac
					;;
				"centos" | \
				"fedora")	# --- get ks.cfg ----------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-kickstart"
					mkdir -p "kickstart"
					if [ -f "../../../${CFG_NAME}" ]; then
						cp --preserve=timestamps "../../../${CFG_NAME}" "kickstart/ks.cfg"
					else
						curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "kickstart/ks.cfg" "${CFG_URL}" || { exit 1; }
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
						curl -f -L -# -R -S -f --create-dirs --connect-timeout 60 -o "autoyast/autoinst.xml" "${CFG_URL}" || { exit 1; }
					fi
					;;
				* )	;;
			esac
			# --- Get EFI Image ---------------------------------------------------
			if [ ! -f ${EFI_IMAG} ]; then
				ISO_SKIPS=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $2;}'`
				ISO_COUNT=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $4;}'`
				dd if="../../${DVD_NAME}.iso" of=${EFI_IMAG} bs=512 skip=${ISO_SKIPS} count=${ISO_COUNT}
			fi
			# --- mrb:txt.cfg / efi:grub.cfg ----------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )	# ･････････････････････････････････････････････････
					case "${CODE_NAME[1]}" in
						debian-7.* )
							sed -i "preseed/preseed.cfg"                                                                               \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/hostname\).*$/\1 string archive.debian.org/'                     \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/directory\).*$/\1 string \/debian-archive\/debian/'              \
							    -e 's/\(^[ \t]*d-i[ \t]*apt-setup\/services-select\).*$/\1 multiselect updates/'                       \
							    -e 's/\(^[ \t]*d-i[ \t]*netcfg\/get_nameservers\)[ \t]*[A-Za-z]*[ \t]*\(.*\)$/\1 string 127.0.0.1 \2/'
							;;
						* )	;;
					esac
					INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
					# --- txt.cfg -------------------------------------
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
					# --- grub.cfg ------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
					sed -n '/^menuentry .*'\''Install'\''/,/^}/p' boot/grub/grub.cfg | \
					sed -e 's/\(Install\)/Auto \1/'                                    \
					    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                          \
					    -e 's/\(--hotkey\)=./\1=a/'                                  | \
					sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg               | \
					sed -e 's/\(set default\)="1"/\1="0"/'                             \
					    -e '1i set timeout=5'                                          \
					> grub.cfg
					mv grub.cfg boot/grub/
					;;
				"ubuntu" )	# ･････････････････････････････････････････････････
					case "${CODE_NAME[1]}" in
						*20.10* )
							;;
						* )
							sed -i isolinux/isolinux.cfg     \
							    -e 's/\(timeout\).*$/\1 50/'
							sed -i isolinux/prompt.cfg       \
							    -e 's/\(timeout\).*$/\1 50/'
							;;
					esac
					case "${CODE_NAME[1]}" in
						"ubuntu-16.04.7-server-amd64"      )
							sed -i "preseed/preseed.cfg"      \
							    -e 's/fonts-noto-cjk-extra//' \
							    -e 's/gnome-user-docs-ja//'
							;;
						* )	;;
					esac
					case "${CODE_NAME[1]}" in
						*20.04*live* )						# --- nocloud -----
							INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\""
							# --- txt.cfg -------------------------------------
							INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
							INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | sed -e 's/\(^.*menu\).*$/\1 default/'`"
							sed -n '/label live$/,/append/p' isolinux/txt.cfg | \
							sed -e 's/^\(label\) live/\1 autoinst/'             \
							    -e 's/\(Install\)/Auto \1/'                     \
							    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"            \
							    -e 's/\"//g'                                  | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg    \
							> txt.cfg
							mv txt.cfg isolinux/
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Install.*Server\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(Install\)/Auto \1/'                                      \
							    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                          | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                 | \
							sed -e 's/\(set default\)="1"/\1="0"/'                               \
							    -e 's/\(set timeout\).*$/\1=5/'                                  \
							> grub.cfg
							mv grub.cfg boot/grub/
							;;
						*20.04*desktop* )					# --- nocloud -----
							INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\" vga=788"
							# --- txt.cfg -------------------------------------
							INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
							INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | sed -e 's/\(^[ \t]*menu\).*$/\1 default/g' | head -n 1`"
							sed -n '/label live-install$/,/append/p' isolinux/txt.cfg | \
							sed -e 's/^\(label\).*/\1 autoinst/'                        \
							    -e 's/\(Install\)/Auto \1/'                             \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                    \
							    -e "/menu label/a  ${INS_STR}"                          \
							    -e 's/only-ubiquity/boot=casper automatic-ubiquity/'  | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg            \
							> txt.cfg
							mv txt.cfg isolinux/
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
							sed -n '0,/\}/p'                                          | \
							sed -e 's/\(Ubuntu\)/Auto Install \1/'                      \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                    \
							    -e 's/maybe-ubiquity/boot=casper automatic-ubiquity/' | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg        | \
							sed -e 's/\(set default\)="1"/\1="0"/'                      \
							    -e 's/\(set timeout\).*$/\1=5/'                         \
							> grub.cfg
							mv grub.cfg boot/grub/
							;;
						*20.10*live* )						# --- nocloud -----
							INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\""
							# --- txt.cfg -------------------------------------
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Ubuntu Server\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(Ubuntu Server\)/Auto Install/'                         \
							    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                        | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg               | \
							sed -e 's/\(set default\)="1"/\1="0"/'                             \
							    -e 's/\(set timeout\).*$/\1=5/'                                \
							> grub.cfg
							mv grub.cfg boot/grub/
							;;
						*20.10*desktop* )					# --- nocloud -----
							INS_CFG="autoinstall \"ds=nocloud;s=\/cdrom\/nocloud\/\""
							# --- txt.cfg -------------------------------------
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
							sed -e 's/\(Ubuntu\)/Auto Install/'                         \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                    \
							    -e 's/maybe-ubiquity/boot=casper automatic-ubiquity/' | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg        | \
							sed -e 's/\(set default\)="1"/\1="0"/'                      \
							    -e 's/\(set timeout\).*$/\1=5/'                         \
							> grub.cfg
							mv grub.cfg boot/grub/
							;;
						*server* )							# --- preseed.cfg -
							INS_CFG="\/cdrom\/preseed\/preseed.cfg auto=true"
							# --- txt.cfg -------------------------------------
							INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
							INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | sed -e 's/\(^[ \t]*menu\).*$/\1 default/g' | head -n 1`"
							sed -n '/label install/,/append/p' isolinux/txt.cfg | \
							sed -e 's/^\(label\) install/\1 autoinst/'            \
							    -e 's/\(Install\)/Auto \1/'                       \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"              \
							    -e "/menu label/a  ${INS_STR}"                  | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg      \
							> txt.cfg
							mv txt.cfg isolinux/
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Install Ubuntu Server\"/,/^}/p' boot/grub/grub.cfg | \
							sed -n '0,/\}/p'                                                         | \
							sed -e 's/\(Install\)/Auto \1/'                                            \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                                 | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       | \
							sed -e 's/\(set default\)="1"/\1="0"/'                                     \
							    -e 's/\(set timeout\).*$/\1=5/'                                        \
							> grub.cfg
							if [ "`sed -n '/set default/p' grub.cfg`" = "" ]; then
								sed -i grub.cfg           \
								    -e '1i set default=0'
							fi
							if [ "`sed -n '/set timeout/p' grub.cfg`" = "" ]; then
								sed -i grub.cfg           \
								    -e '1i set timeout=5'
							fi
							mv grub.cfg boot/grub/
							;;
						*desktop* )							# --- preseed.cfg -
							INS_CFG="\/cdrom\/preseed\/preseed.cfg auto=true"
							# --- txt.cfg -------------------------------------
							INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
							INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | sed -e 's/\(^[ \t]*menu\).*$/\1 default/g' | head -n 1`"
							sed -n '/label live-install$/,/append/p' isolinux/txt.cfg | \
							sed -e 's/^\(label\).*/\1 autoinst/'                        \
							    -e 's/\(Install\)/Auto \1/'                             \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                    \
							    -e "/menu label/a  ${INS_STR}"                          \
							    -e 's/only-ubiquity/boot=casper automatic-ubiquity/'  | \
							sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg            \
							> txt.cfg
							mv txt.cfg isolinux/
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
							sed -n '/^menuentry \"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
							sed -n '0,/\}/p'                                          | \
							sed -e 's/\(Ubuntu\)/Auto Install \1/'                      \
							    -e "s/\(file\).*seed/\1=${INS_CFG}/"                    \
							    -e 's/maybe-ubiquity/boot=casper automatic-ubiquity/' | \
							sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg        | \
							sed -e 's/\(set default\)="1"/\1="0"/'                      \
							    -e 's/\(set timeout\).*$/\1=5/'                         \
							> grub.cfg
							mv grub.cfg boot/grub/
							;;
						* )	;;
					esac
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
				* )	;;
			esac
			case "${CODE_NAME[0]}" in
				"debian" | \
				"ubuntu" | \
				"centos" | \
				"fedora" )	# ･････････････････････････････････････････････････
					rm -f md5sum.txt
					find . ! -name "md5sum.txt" ! -name "boot.catalog" ! -name "boot.cat" ! -name "isolinux.bin" ! -name "eltorito.img" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
					# --- make iso file -----------------------------------------------
					case "${CODE_NAME[1]}" in
						ubuntu*20.10* )
							ELT_BOOT=boot/grub/i386-pc/eltorito.img
							ELT_CATA=boot.catalog
							;;
						* )
							ELT_BOOT=isolinux/isolinux.bin
							ELT_CATA=isolinux/boot.cat
							;;
					esac
					xorriso -as mkisofs \
					    -quiet \
					    -iso-level 3 \
					    -full-iso9660-filenames \
					    -volid "${VOLID}" \
					    -eltorito-boot ${ELT_BOOT} \
					    -eltorito-catalog ${ELT_CATA} \
					    -no-emul-boot -boot-load-size 4 -boot-info-table \
					    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
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
					    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
					    -eltorito-alt-boot \
					    -e boot/x86_64/efi \
					    -no-emul-boot -isohybrid-gpt-basdat \
					    -output "../../${ISO_NAME}.iso" \
					    .
					;;
				* )	;;
			esac
			LANG=C implantisomd5 "../../${ISO_NAME}.iso"
		popd > /dev/null
	popd > /dev/null
	echo "↑処理済：${CODE_NAME[0]}：${CODE_NAME[1]} -------------------------------"
}
# -----------------------------------------------------------------------------
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 作成処理を開始します。"
	echo "*******************************************************************************"
# -----------------------------------------------------------------------------
	if [ "`which xorriso 2> /dev/nul`" = "" ]; then
		if [ ! -f /etc/redhat-release ]; then
			apt -y update && apt -y upgrade && apt -y install xorriso
		else
			yum -y update && yum -y upgrade && yum -y install xorriso
		fi
	fi
	if [ "`which implantisomd5 2> /dev/nul`" = "" ]; then
		if [ ! -f /etc/redhat-release ]; then
			apt -y update && apt -y upgrade && apt -y install isomd5sum
		else
			yum -y update && yum -y upgrade && yum -y install isomd5sum
		fi
	fi
	if [ ! -f /usr/lib/ISOLINUX/isohdpfx.bin ]; then
		if [ ! -f /etc/redhat-release ]; then
			apt -y update && apt -y upgrade && apt -y install isolinux
		else
			yum -y update && yum -y upgrade && yum -y install isolinux
		fi
	fi
	# -------------------------------------------------------------------------
	if [ ${#INP_INDX} -le 0 ]; then							# 引数無しでメニュー表示
		fncMenu
	fi
	# -------------------------------------------------------------------------
	for I in `eval echo "${INP_INDX}"`						# 連番可
	do
		if [ `fncIsInt "$I"` -eq 0 ] && [ $I -ge 1 ] && [ $I -le ${#ARRAY_NAME[@]} ]; then
			fncRemaster "${ARRAY_NAME[$I-1]}"
		fi
	done
	# -------------------------------------------------------------------------
	ls -alLt "${WORK_DIRS}/"*.iso
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
#x  8.0:jessie           :2015-04-25:2018-06-17/2020-06-30[LTS]:oldoldstable
#   9.0:stretch          :2017-06-17:2020-xx-xx/2022-06-xx[LTS]:oldstable
#  10.0:buster           :2019-07-06:2022-xx-xx/2024-xx-xx[LTS]:stable
#  11.0:bullseye         :2021(予定):                          :testing
#  12.0:bookworm         :          :                          
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
# 20.10:Groovy Gorilla   :2020-10-22:2021-07-xx
# 21.04:Hirsute Hippo    :2021-04-22:2022-01-xx
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
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# Ver. :コードネーム     :リリース日:サポ期限  :kernel
#x27   :                 :2017-11-14:2018-11-27: 4.13
#x28   :                 :2018-05-01:2019-05-29: 4.16
#x29   :                 :2018-10-30:2019-11-26: 4.18
#x30   :                 :2019-04-29:2020-05-26: 5.0
# 31   :                 :2019-10-29:          : 5.3
# 32   :                 :2020-04-28:          : 5.6
# 33   :                 :2020-10-27:          : 5.8
# --- https://ja.wikipedia.org/wiki/OpenSUSE ----------------------------------
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 15.2 :openSUSE Leap      :2020-07-02:2021-11-xx: 5.3
# xx.x :openSUSE Tumbleweed:20xx-xx-xx:20xx-xx-xx:
# -----------------------------------------------------------------------------
