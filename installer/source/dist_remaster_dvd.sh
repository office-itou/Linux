#!/bin/bash
###############################################################################
##
##	ファイル名	:	dist_remaster_dvd.sh
##
##	機能概要	:	ブータブルDVDの作成用シェル [DVD版]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian / Ubuntu / CentOS7 (64bit)
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
##	2018/05/11 000.0000 J.Itou         不具合修正
##	2018/05/11 000.0000 J.Itou         debian testing/CentOS 1810追加
##	2018/06/14 000.0000 J.Itou         不具合修正(CentOS7対応含む)
##	2018/06/24 000.0000 J.Itou         debian 8.11 変更
##	2018/06/29 000.0000 J.Itou         Fedora 28追加
##	2018/07/07 000.0000 J.Itou         仕様見直し
##	2018/07/15 000.0000 J.Itou         debian 9.5.0 変更
##	2018/07/27 000.0000 J.Itou         ubuntu 18.04.1 変更
##	2018/11/06 000.0000 J.Itou         ubuntu 18.10,19.04 / Fedora 29 変更
##	2018/11/11 000.0000 J.Itou         debian 9.6.0 変更
##	2019/01/09 000.0000 J.Itou         CentOS 7 1810変更
##	2019/01/24 000.0000 J.Itou         debian 9.7.0 変更
##	2019/02/17 000.0000 J.Itou         debian 9.8.0 変更
##	2019/02/06 000.0000 J.Itou         不具合修正
##	2019/07/09 000.0000 J.Itou         最新化修正
##	2019/08/11 000.0000 J.Itou         ubuntu 18.04.3 変更
##	2019/09/08 000.0000 J.Itou         debian 9.10.0/10.1.0 変更
##	2019/09/10 000.0000 J.Itou         debian 9.11.0 変更
##	2019/09/18 000.0000 J.Itou         CentOS 7.7.1908 変更
##	2019/09/28 000.0000 J.Itou         CentOS 8.0.1905 追加
##	2019/11/15 000.0000 J.Itou         不具合修正
##	2019/11/17 000.0000 J.Itou         debian 10.2.0 変更
##	2019/11/23 000.0000 J.Itou         fedora 31 変更
##	2019/11/24 000.0000 J.Itou         CentOS Stream 追加
##	2019/11/29 000.0000 J.Itou         USBメモリーでのインストール対応
##	2020/02/22 000.0000 J.Itou         debian 9.12.0/10.3.0 / ubuntu 18.04.4 変更 / CentOS 8.1 追加 / CentOS-Stream-8-x86_64-20191219-boot 変更
##	2020/02/22 000.0000 J.Itou         wget -> curl 変更
##	2020/05/05 000.0000 J.Itou         不具合修正
##	2020/05/05 000.0000 J.Itou         ubuntu 20.04 追加
##	2020/05/11 000.0000 J.Itou         debian 10.4.0 変更 / ubuntu-desktopの処理停止 / fedora 32 変更
##	2020/07/10 000.0000 J.Itou         CentOS 8.2.2004 変更
##	2020/07/20 000.0000 J.Itou         debian 9.13.0 変更
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
	readonly ARRAY_NAME=(                                                                                                                                                                               \
	    "debian debian-8.11.1-amd64-DVD-1            https://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-dvd/debian-8.11.1-amd64-DVD-1.iso                            preseed_debian.cfg"       \
	    "debian debian-9.13.0-amd64-DVD-1            https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso                            preseed_debian.cfg"       \
	    "debian debian-10.4.0-amd64-DVD-1            https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-10.4.0-amd64-DVD-1.iso                           preseed_debian.cfg"       \
	    "debian debian-testing-amd64-DVD-1           https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                            preseed_debian.cfg"       \
	    "ubuntu ubuntu-16.04.6-server-amd64          https://releases.ubuntu.com/xenial/ubuntu-16.04.6-server-amd64.iso                                                       preseed_ubuntu.cfg"       \
	    "ubuntu ubuntu-18.04.4-server-amd64          http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.4-server-amd64.iso                                        preseed_ubuntu.cfg"       \
	    "ubuntu ubuntu-19.10-server-amd64            http://cdimage.ubuntu.com/releases/eoan/release/ubuntu-19.10-server-amd64.iso                                            preseed_ubuntu.cfg"       \
	    "ubuntu ubuntu-20.04-legacy-server-amd64     http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/focal/release/ubuntu-20.04-legacy-server-amd64.iso               preseed_ubuntu.cfg"       \
	    "ubuntu ubuntu-20.04-live-server-amd64       https://releases.ubuntu.com/focal/ubuntu-20.04-live-server-amd64.iso                                                     nocloud-ubuntu-user-data" \
	    "centos CentOS-8.2.2004-x86_64-dvd1          http://ftp-srv2.kddilabs.jp/Linux/packages/CentOS/8.2.2004/isos/x86_64/CentOS-8.2.2004-x86_64-dvd1.iso                   kickstart_centos.cfg"     \
	    "centos CentOS-Stream-8-x86_64-20200629-dvd1 http://ftp-srv2.kddilabs.jp/Linux/packages/CentOS/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20200629-dvd1.iso          kickstart_centos.cfg"     \
	    "fedora Fedora-Server-dvd-x86_64-32-1.6      https://download.fedoraproject.org/pub/fedora/linux/releases/32/Server/x86_64/iso/Fedora-Server-dvd-x86_64-32-1.6.iso    kickstart_fedora.cfg"     \
	)   # 区分  DVDファイル名                        ダウンロード先URL                                                                                                        定義ファイル
#	    "ubuntu ubuntu-16.04.6-desktop-amd64         https://releases.ubuntu.com/xenial/ubuntu-16.04.6-desktop-amd64.iso                                                      preseed_ubuntu.cfg"       \
#	    "ubuntu ubuntu-18.04.4-desktop-amd64         https://releases.ubuntu.com/bionic/ubuntu-18.04.4-desktop-amd64.iso                                                      preseed_ubuntu.cfg"       \
#	    "ubuntu ubuntu-19.10-desktop-amd64           https://releases.ubuntu.com/eoan/ubuntu-19.10-desktop-amd64.iso                                                          preseed_ubuntu.cfg"       \
#	    "ubuntu ubuntu-20.04-desktop-amd64           https://releases.ubuntu.com/focal/ubuntu-20.04-desktop-amd64.iso                                                         preseed_ubuntu.cfg"       \

# -----------------------------------------------------------------------------
funcMenu () {
	echo "# ----------------------------------------------------------------------------#"
	echo "# ID：Version                         ：リリース日：サポ終了日：備考          #"
	echo "#  1：debian-8.11.1-amd64-DVD-1       ：2015-04-25：2020-04-xx：oldoldstable  #"
	echo "#  2：debian-9.13.0-amd64-DVD-1       ：2017-06-17：2022-xx-xx：oldstable     #"
	echo "#  3：debian-10.4.0-amd64-DVD-1       ：2019-07-06：20xx-xx-xx：stable        #"
	echo "#  4：debian-testing-amd64-DVD-1      ：20xx-xx-xx：20xx-xx-xx：testing       #"
	echo "#  5：ubuntu-16.04.6-server-amd64     ：2016-04-21：2021-04-xx：Xenial Xerus  #"
	echo "#  6：ubuntu-18.04.4-server-amd64     ：2018-04-26：2023-04-xx：Bionic Beaver #"
	echo "#  7：ubuntu-19.10-server-amd64       ：2019-10-17：2020-07-xx：Eoan Ermine   #"
	echo "#  8：ubuntu-20.04-legacy-server-amd64：2020-04-23：2025-04-xx：Focal Fossa   #"
	echo "#  9：ubuntu-20.04-live-server-amd64  ：2020-04-23：2025-04-xx：Focal Fossa   #"
	echo "# 10：CentOS-8.2.2004-x86_64-dvd1     ：2020-06-15：2029-05-31：RHEL 8.0      #"
	echo "# 11：CentOS-Stream-8-x86_64-20200629-：2019-xx-xx：20xx-xx-xx：RHEL x.x      #"
	echo "# 12：Fedora-Server-dvd-x86_64-32-1.6 ：2020-04-28：20xx-xx-xx：kernel 5.6    #"
	echo "# ----------------------------------------------------------------------------#"
	echo "ID番号+Enterを入力して下さい。"
	read INP_INDX
#	echo "#   ：ubuntu-16.04.6-desktop-amd64    ：2016-04-21：2021-04-xx：Xenial Xerus  #"
#	echo "#   ：ubuntu-18.04.4-desktop-amd64    ：2018-04-26：2023-04-xx：Bionic Beaver #"
#	echo "#   ：ubuntu-19.10-desktop-amd64      ：2019-10-17：2020-07-xx：Eoan Ermine   #"
#	echo "#   ：ubuntu-20.04-desktop-amd64      ：2020-04-23：2025-04-xx：Focal Fossa   #"
}
# -----------------------------------------------------------------------------
funcIsInt () {
	set +e
	expr ${1:-""} + 1 > /dev/null 2>&1
	if [ $? -ge 2 ]; then echo 1; else echo 0; fi
	set -e
}
# -----------------------------------------------------------------------------
funcRemaster () {
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
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || { rm -f "../${DVD_NAME}.iso"; exit 1; }
		else
			curl -L -s --connect-timeout 60 --dump-header "header.txt" "${DVD_URL}"
			local WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
			local WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
			local WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
			local DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ "${WEB_SIZE}" != "${DVD_SIZE}" ] || [ "${WEB_DATE}" != "${DVD_DATE}" ]; then
				curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "../${DVD_NAME}.iso" "${DVD_URL}" || { rm -f "../${DVD_NAME}.iso"; exit 1; }
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
						*live* )	# --- get user-data -------------------------------
							EFI_IMAG="boot/grub/efi.img"
							DVD_NAME+="-nocloud"
							mkdir -p "nocloud"
							touch nocloud/meta-data
							touch nocloud/user-data
							if [ -f "../../../${CFG_NAME}" ]; then
								cp --preserve=timestamps "../../../${CFG_NAME}" "nocloud/user-data"
							else
								curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "nocloud/user-data" "${CFG_URL}" || { rm -f "nocloud/user-data"; exit 1; }
							fi
							;;
						* )			# --- get preseed.cfg -----------------------------
							EFI_IMAG="boot/grub/efi.img"
							DVD_NAME+="-preseed"
							mkdir -p "preseed"
							if [ -f "../../../${CFG_NAME}" ]; then
								cp --preserve=timestamps "../../../${CFG_NAME}" "preseed/preseed.cfg"
							else
								curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "preseed/preseed.cfg" "${CFG_URL}" || { rm -f "preseed/preseed.cfg"; exit 1; }
							fi
#							sed -i "preseed/preseed.cfg"                                   \
#							    -e 's~.*\(d-i debian-installer/language\).*~  \1 string en~' \
#							    -e 's~.*\(d-i debian-installer/locale\).*~  \1 string en_US.UTF-8~' \
#							    -e '/d-i debian-installer\/language/i\  d-i localechooser\/preferred-locale select en_US.UTF-8\n  d-i localechooser\/supported-locales multiselect en_US.UTF-8, ja_JP.UTF-8'
							;;
					esac
					;;
				"centos" | \
				"fedora")	# --- get ks.cfg ----------------------------------
					EFI_IMAG="images/efiboot.img"
					DVD_NAME+="-kickstart"
					mkdir -p "kickstart"
					if [ -f "../../../${CFG_NAME}" ]; then
						cp --preserve=timestamps "../../../${CFG_NAME}" "kickstart/ks.cfg"
					else
						curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "kickstart/ks.cfg" "${CFG_URL}" || { rm -f "kickstart/ks.cfg"; exit 1; }
					fi
					sed -i kickstart/ks.cfg    \
					    -e 's/#\(cdrom\)/\1/g' \
					    -e 's/^\(url \)/repo --name="New_Repository" /g'
#					    -e 's/^\(url \)/#\1/g' \
#					    -e 's/^\(repo \)/#\1/g'
					;;
				* )	;;
			esac
			# --- mrb:txt.cfg / efi:grub.cfg ----------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )	# ･････････････････････････････････････････････････
					sed -i isolinux/txt.cfg  \
					    -e 's/^\(default\) .*$/\1 preseed/' \
					    -e '/menu default/d' \
					    -e '/^label install/i\label preseed\n\tmenu label ^Preseed install\n\tmenu default\n\tkernel /install.amd/vmlinuz\n\tappend vga=788 initrd=/install.amd/initrd.gz --- quiet auto=true file=/cdrom/preseed/preseed.cfg'
					sed -i boot/grub/grub.cfg \
					    -e "/^set theme/a\menuentry --hotkey=p 'Preseed install' {\n    set background_color=black\n    linux    /install.amd/vmlinuz auto=true file=/cdrom/preseed/preseed.cfg priority=critical vga=788 --- quiet\n    initrd   /install.amd/initrd.gz\n}"
					;;
				"ubuntu" )	# ･････････････････････････････････････････････････
					case "${CODE_NAME[1]}" in
						"ubuntu-16.04.6-server-amd64"      )
							sed -i "preseed/preseed.cfg"      \
							    -e 's/fonts-noto-cjk-extra//' \
							    -e 's/gnome-user-docs-ja//'
							;;
						* )	;;
					esac
					case "${CODE_NAME[1]}" in
						*live* )
							sed -i isolinux/txt.cfg  \
							    -e 's/^\(default\) .*$/\1 preseed/' \
							    -e '/menu default/d' \
							    -e '/^default/a\label preseed\n  menu label ^Auto install Ubuntu Server\n  kernel /casper/vmlinuz\n  append  autoinstall "ds=nocloud;s=/cdrom/nocloud/" vga=788 initrd=/casper/initrd quiet ---'
							sed -i boot/grub/grub.cfg \
							    -e '/menuentry "Install Ubuntu Server"/i\menuentry "Auto install Ubuntu Server" {\n\tset gfxpayload=keep\n\tlinux\t/casper/vmlinuz autoinstall "ds=nocloud;s=/cdrom/nocloud/" quiet  ---\n\tinitrd\t/casper/initrd\n}'
							;;
						*server* )
							sed -i isolinux/txt.cfg  \
							    -e 's/^\(default\) .*$/\1 preseed/' \
							    -e '/menu default/d' \
							    -e '/^default/a\label preseed\n  menu label ^Preseed install Server\n  kernel /install/vmlinuz\n  append  auto=true file=/cdrom/preseed/preseed.cfg vga=788 initrd=/install/initrd.gz quiet ---'
							sed -i boot/grub/grub.cfg \
							    -e '/menuentry "Install Ubuntu Server"/i\menuentry "Preseed install Ubuntu Server" {\n\tset gfxpayload=keep\n\tlinux\t/install/vmlinuz  auto=true file=/cdrom/preseed/preseed.cfg quiet ---\n\tinitrd\t/install/initrd.gz\n}'
							;;
						*desktop* )
							;;
						* )	;;
					esac
					;;
				"centos" )	# ･････････････････････････････････････････････････
					case "${VOLID}" in
						"CentOS-8-1-1911-x86_64-dvd      " )
							sed -i isolinux/isolinux.cfg \
							    -e '/menu default/d' \
							    -e '/^label linux/i\label auto\n  menu label ^Auto Install CentOS Linux 8\n  kernel vmlinuz\n  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS-8-1-1911-x86_64-dvd quiet inst.ks=cdrom:/kickstart/ks.cfg\n'
							sed -i EFI/BOOT/grub.cfg \
							    -e 's/\(set default\)="1"/\1="0"/g' \
							    -e '/^### BEGIN \/etc\/grub\.d\/10_linux ###/a\menuentry '\''Auto Install CentOS Linux 8'\'' --class fedora --class gnu-linux --class gnu --class os {\n\tlinuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS-8-1-1911-x86_64-dvd quiet inst.ks=cdrom:/kickstart/ks.cfg\n\tinitrdefi /images/pxeboot/initrd.img\n}\n'
							;;
						"CentOS-Stream-8-x86_64-dvd      " )
							sed -i isolinux/isolinux.cfg \
							    -e '/menu default/d' \
							    -e '/^label linux/i\label auto\n  menu label ^Auto Install CentOS Stream 8-stream\n  kernel vmlinuz\n  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS-Stream-8-x86_64-dvd quiet inst.ks=cdrom:/kickstart/ks.cfg\n'
							sed -i EFI/BOOT/grub.cfg \
							    -e 's/\(set default\)="1"/\1="0"/g' \
							    -e '/^### BEGIN \/etc\/grub\.d\/10_linux ###/a\menuentry '\''Auto Install CentOS Stream 8-stream'\'' --class fedora --class gnu-linux --class gnu --class os {\n\tlinuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS-Stream-8-x86_64-dvd quiet inst.ks=cdrom:/kickstart/ks.cfg\n\tinitrdefi /images/pxeboot/initrd.img\n}\n'
							;;
						* )
							echo "?:[${VOLID}]"
							;;
					esac
					;;
				"fedora" )	# ･････････････････････････････････････････････････
					sed -i isolinux/isolinux.cfg \
					    -e '/menu default/d' \
					    -e '/^label linux/i\label fedora32auto\n  menu label ^Auto Install Fedora 32\n  menu default\n  kernel vmlinuz\n  append initrd=initrd.img inst.stage2=hd:LABEL=Fedora-S-dvd-x86_64-32 inst.ks=cdrom:/kickstart/ks.cfg\n'
					sed -i EFI/BOOT/grub.cfg \
					    -e 's/\(set default\)="1"/\1="0"/g' \
					    -e '/^### BEGIN \/etc\/grub.d\/10_linux ###$/a\menuentry '\''Auto Install Fedora 32'\'' --class fedora --class gnu-linux --class gnu --class os {\n\tlinuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=Fedora-S-dvd-x86_64-32 inst.ks=cdrom:/kickstart/ks.cfg\n\tinitrdefi /images/pxeboot/initrd.img\n}'
					;;
				* )	;;
			esac
			# --- copy EFI directory ------------------------------------------
#			case "${CODE_NAME[0]}" in
#				"debian" )
#					if [ ! -d EFI ]; then
#						echo "--- copy EFI directory --------------------------------------------------------"
#						mount -r -o loop boot/grub/efi.img ../mnt/
#						pushd ../mnt/efi/ > /dev/null
#							find . -depth -print | cpio -pdm ../../image/EFI/
#						popd > /dev/null
#						umount ../mnt/
#					fi
#					;;
#				* )	;;
#			esac
			# --- make iso file -----------------------------------------------
			rm -f md5sum.txt
			case "${CODE_NAME[1]}" in
				"ubuntu-20.04-legacy-server-amd64" | \
				"ubuntu-20.04-desktop-amd64"       | \
				"ubuntu-20.04-live-server-amd64"   )
					find . ! -name "md5sum.txt" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
					;;
				* )
					find . ! -name "md5sum.txt" -type f -exec md5sum {} \; > md5sum.txt
					;;
			esac
			xorriso -as mkisofs \
			    -quiet \
			    -iso-level 3 \
			    -full-iso9660-filenames \
			    -volid "${VOLID}" \
			    -eltorito-boot isolinux/isolinux.bin \
			    -eltorito-catalog isolinux/boot.cat \
			    -no-emul-boot -boot-load-size 4 -boot-info-table \
			    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
			    -eltorito-alt-boot \
			    -e "${EFI_IMAG}" \
			    -no-emul-boot -isohybrid-gpt-basdat \
			    -output "../../${DVD_NAME}.iso" \
			    .
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
	# -------------------------------------------------------------------------
	if [ ${#INP_INDX} -le 0 ]; then							# 引数無しでメニュー表示
		funcMenu
	fi
	# -------------------------------------------------------------------------
	for I in `eval echo "${INP_INDX}"`						# 連番可
	do
		if [ `funcIsInt "$I"` -eq 0 ] && [ $I -ge 1 ] && [ $I -le ${#ARRAY_NAME[@]} ]; then
			funcRemaster "${ARRAY_NAME[$I-1]}"
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
#x  8.0:jessie           :2015-04-25:2018-06-17/2020-06-30[LTS]
#   9.0:stretch          :2017-06-17:2020-xx-xx/2022-06-xx[LTS]
#  10.0:buster           :2019-07-06:
#  11.0:bullseye         :2021(予定):
# --- https://en.wikipedia.org/wiki/Ubuntu_version_history --------------------
# [https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja]
# Ver. :コードネーム     :リリース日:サポート期限
#x 4.10:Warty Warthog    :2004-10-20:2006-04-30
#x 5.04:Hoary Hedgehog   :2005-04-08:2006-10-31
#x 5.10:Breezy Badger    :2005-10-13:2007-04-13
#x 6.06:Dapper Drake     :2006-06-01:2009-07-14
#x 6.10:Edgy Eft         :2006-10-26:2008-04-25
#x 7.04:Feisty Fawn      :2007-04-19:2008-10-19
#x 7.10:Gutsy Gibbon     :2007-10-18:2009-04-18
#x 8.04:Hardy Heron      :2008-04-24:2011-05-12
#x 8.10:Intrepid Ibex    :2008-10-30:2010-04-30
#x 9.04:Jaunty Jackalope :2009-04-23:2010-10-23
#x 9.10:Karmic Koala     :2009-10-29:2011-04-30
#x10.04:Lucid Lynx       :2010-04-29:2013-05-09
#x10.10:Maverick Meerkat :2010-10-10:2012-04-10
#x11.04:Natty Narwhal    :2011-04-28:2012-10-28
#x11.10:Oneiric Ocelot   :2011-10-13:2013-05-09
#x12.04:Precise Pangolin :2012-04-26:2017-04-28
#x12.10:Quantal Quetzal  :2012-10-18:2014-05-16
#x13.04:Raring Ringtail  :2013-04-25:2014-01-27
#x13.10:Saucy Salamander :2013-10-17:2014-07-17
#x14.04:Trusty Tahr      :2014-04-17:2019-04-30
#x14.10:Utopic Unicorn   :2014-10-23:2015-07-23
#x15.04:Vivid Vervet     :2015-04-23:2016-02-04
#x15.10:Wily Werewolf    :2015-10-22:2016-07-28
# 16.04:Xenial Xerus     :2016-04-21:2021-04-xx
#x16.10:Yakkety Yak      :2016-10-13:2017-07-20
#x17.04:Zesty Zapus      :2017-04-13:2018-01-13
#x17.10:Artful Aardvark  :2017-10-19:2018-07-19
# 18.04:Bionic Beaver    :2018-04-26:2023-04-xx
#x18.10:Cosmic Cuttlefish:2018-10-18:2019-07-18
# 19.04:Disco Dingo      :2019-04-18:2020-01-23
# 19.10:Eoan Ermine      :2019-10-17:2020-07-xx
# 20.04:Focal Fossa      :2020-04-23:2025-04-xx
# --- https://ja.wikipedia.org/wiki/CentOS ------------------------------------
# Ver.    :リリース日:RHEL      :メンテナンス更新期限
# 7.4-1708:2017-09-14:2017-08-01:2024-06-30
# 7.5-1804:2018-05-10:2018-04-10:2024-06-30
# 7.6-1810:2018-12-03:2018-10-30:2024-06-30
# 7.7-1908:2019-09-17:2019-08-06:2024-06-30
# 8.0-1905:2019-09-24:2019-05-07:2029-05-31
# 8.1-1911:2020-01-15:2019-11-05:2029-05-31
# 8.2.2004:2020-06-15:2020-04-28:2029-05-31
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# Ver. :コードネーム     :リリース日:サポート期限
#x27   :                 :2017-11-14:2018-11-27
#x28   :                 :2018-05-01:2019-05-29
# 29   :                 :2018-10-30:
# 30   :                 :2019-04-29:
# 31   :                 :2019-10-29:
# 32   :                 :2020-04-28:
# -----------------------------------------------------------------------------
