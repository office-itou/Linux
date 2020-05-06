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
##	2018/05/11 000.0000 J.Itou         不具合修正
##	2018/06/14 000.0000 J.Itou         不具合修正
##	2018/06/29 000.0000 J.Itou         仕様変更(取得先URLをHTTPS)
##	2018/11/06 000.0000 J.Itou         ubuntu 18.10,19.04 変更
##	2019/02/06 000.0000 J.Itou         不具合修正
##	2019/07/09 000.0000 J.Itou         最新化修正
##	2019/11/23 000.0000 J.Itou         コメント追加：fedora 31
##	2019/11/24 000.0000 J.Itou         ubuntu 20.04 追加
##	2019/11/29 000.0000 J.Itou         USBメモリーでのインストール対応
##	2020/02/22 000.0000 J.Itou         wget -> curl 変更
##	2020/05/05 000.0000 J.Itou         不具合修正
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
	readonly ARRAY_NAME=(      \
	    "debian debian         oldoldstable" \
	    "debian debian         oldstable"    \
	    "debian debian         stable"       \
	    "debian debian         testing"      \
	    "ubuntu ubuntu-archive xenial"       \
	    "ubuntu ubuntu-archive bionic"       \
	    "ubuntu ubuntu-archive disco"        \
	    "ubuntu ubuntu-archive eoan"         \
	    "ubuntu ubuntu-archive focal"        \
	)
# -----------------------------------------------------------------------------
funcMenu () {
	echo "# ---------------------------------------------------------------------------#"
	echo "# ID：Version     ：コードネーム    ：リリース日：サポ終了日：備考           #"
	echo "#  1：Debian  8.xx：jessie          ：2015-04-25：2020-06-30：oldoldstable   #"
	echo "#  2：Debian  9.xx：stretch         ：2017-06-17：2022-06-xx：oldstable      #"
	echo "#  3：Debian 10.xx：buster          ：2019-07-06：          ：stable         #"
	echo "#  4：Debian 11.xx：bullseye        ：2021-xx-xx：          ：testing        #"
	echo "#  5：Ubuntu 16.04：Xenial Xerus    ：2016-04-21：2021-04-xx：LTS            #"
	echo "#  6：Ubuntu 18.04：Bionic Beaver   ：2018-04-26：2023-04-xx：LTS            #"
	echo "#  7：Ubuntu 19.04：Disco Dingo     ：2019-04-18：2020-01-23：               #"
	echo "#  8：Ubuntu 19.10：Eoan Ermine     ：2019-10-17：2020-07-xx：               #"
	echo "#  9：Ubuntu 20.04：Focal Fossa     ：2020-04-23：2025-04-xx：LTS            #"
	echo "# ---------------------------------------------------------------------------#"
	echo "ID番号+Enterを入力して下さい。"
	read INP_INDX
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
	echo "↓処理中：${CODE_NAME[0]}：${CODE_NAME[2]} ---------------------------------------------"
	# --- DVD -----------------------------------------------------------------
#	local CPU_TYPE=i386										# CPUタイプ(32bit)
	local CPU_TYPE=amd64									# CPUタイプ(64bit)
	local DVD_NAME="mini-${CODE_NAME[2]}-${CPU_TYPE}"
	local DVD_URL="https://ftp.yz.yamagata-u.ac.jp/pub/linux/${CODE_NAME[1]}/dists/${CODE_NAME[2]}/main/installer-${CPU_TYPE}/current/images/netboot/mini.iso"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="preseed_${CODE_NAME[0]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}.cfg"
	# -------------------------------------------------------------------------
	rm -rf   ${WORK_DIRS}/${CODE_NAME[2]}/image ${WORK_DIRS}/${CODE_NAME[2]}/decomp ${WORK_DIRS}/${CODE_NAME[2]}/mnt
	mkdir -p ${WORK_DIRS}/${CODE_NAME[2]}/image ${WORK_DIRS}/${CODE_NAME[2]}/decomp ${WORK_DIRS}/${CODE_NAME[2]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[2]} > /dev/null
		# --- get preseed.cfg -------------------------------------------------
		if [ -f "../../${CFG_NAME}.cfg" ]; then
			cp --preserve=timestamps "../../${CFG_NAME}.cfg" "preseed.cfg"
		fi
		if [ ! -f "preseed.cfg" ]; then
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "preseed.cfg" "${CFG_URL}" || { rm -f "preseed.cfg"; exit 1; }
		fi
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
		# --- image -> decomp -> image ----------------------------------------
		pushd decomp > /dev/null							# initrd.gz 展開先
			gunzip < ../image/initrd.gz | cpio -i
			cp --preserve=timestamps ../preseed.cfg ./
			find . | cpio -H newc --create | gzip -9 > ../image/initps.gz
		popd > /dev/null
		pushd image > /dev/null								# 作業用ディスクイメージ
			# --- mrb:txt.cfg -------------------------------------------------
			sed -i txt.cfg  \
			    -e 's/^\(default\) .*$/\1 preseed/' \
			    -e '/menu default/d' \
			    -e "/^label install.*$/i\label preseed\r\n\tmenu label ^Preseed install\r\n\tmenu default\r\n\tkernel linux\r\n\tappend vga=788 initrd=initps.gz --- quiet \r"
			# --- efi:grub.cfg ------------------------------------------------
			sed -i boot/grub/grub.cfg \
			    -e "/^menuentry 'Install'.*$/i\menuentry 'Preseed install' {\n    set background_color=black\n    linux    /linux vga=788 --- quiet\n    initrd   /initps.gz\n}" \
			    -e '/^menuentry "Install".*$/i\menuentry "Preseed install" {\n\tset gfxpayload=keep\n\tlinux\t/linux --- quiet\n\tinitrd\t/initps.gz\n}\n'
			# --- copy EFI directory ------------------------------------------
			case "${CODE_NAME[0]}" in
				"debian" )
					if [ ! -d EFI ]; then
						echo "--- copy EFI directory --------------------------------------------------------"
						mount -r -o loop boot/grub/efi.img ../mnt/
						pushd ../mnt/efi/ > /dev/null
							find . -depth -print | cpio -pdm ../../image/EFI/
						popd > /dev/null
						umount ../mnt/
					fi
					;;
				* )	;;
			esac
			# --- make iso file -----------------------------------------------
			rm -f md5sum.txt
			find . ! -name "md5sum.txt" -type f -exec md5sum -b {} \; > md5sum.txt
			xorriso -as mkisofs \
			    -quiet \
			    -iso-level 3 \
			    -full-iso9660-filenames \
			    -volid "${VOLID}" \
			    -eltorito-boot isolinux.bin \
			    -eltorito-catalog boot.cat \
			    -no-emul-boot -boot-load-size 4 -boot-info-table \
			    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
			    -eltorito-alt-boot \
			    -e boot/grub/efi.img \
			    -no-emul-boot -isohybrid-gpt-basdat \
			    -output "../../${DVD_NAME}-preseed.iso" \
			    .
		popd > /dev/null
	popd > /dev/null
	echo "↑処理済：${CODE_NAME[0]}：${CODE_NAME[2]} ---------------------------------------------"
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
#   8.0:jessie           :2015-04-25:2018-06-17/2020-06-30[LTS]
#   9.0:stretch          :2017-06-17:2020-xx-xx/2022-06-xx[LTS]
#  10.0:buster           :2019-07-06:
#  11.0:bullseye         :2021(予定):
# --- https://en.wikipedia.org/wiki/Ubuntu_version_history --------------------
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
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# Ver. :コードネーム     :リリース日:サポート期限
#x27   :                 :2017-11-14:2018-11-27
#x28   :                 :2018-05-01:2019-05-29
# 29   :                 :2018-10-30:
# 30   :                 :2019-04-29:
# 31   :                 :2019-10-29:
# -----------------------------------------------------------------------------
