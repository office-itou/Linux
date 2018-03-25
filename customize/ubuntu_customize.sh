#!/bin/bash
# =============================================================================
# ブータブルCDの作成手順 [ubuntu:amd64:mini.iso]
# =============================================================================
	while :
	do
		cat <<- _EOT_
			# ID:Ver. :コードネーム    :リリース日    :サポート期限
			#--1:12.04:Precise Pangolin:2012年04月26日:2017年04月
			#  2:14.04:Trusty Tahr     :2014年04月17日:2019年04月
			#--3:15.04:Vivid Vervet    :2015年04月23日:2016年01月
			#--4:15.10:Wily Werewolf   :2015年10月22日:2016年07月
			#  5:16.04:Xenial Xerus    :2016年04月21日:2021年04月
			#--6:16.10:Yakkety Yak     :2016年10月13日:2017年07月
			#--7:17.04:Zesty Zapus     :2017年04月13日:2018年01月
			#  8:17.10:Artful Aardvark :2017年10月19日:2018年07月
_EOT_
		echo ID番号+Enterを入力して下さい。
		read DUMMY
		case "${DUMMY}" in
			 1 ) CODE_NAME="precise"; break;;
			 2 ) CODE_NAME="trusty" ; break;;
			 3 ) CODE_NAME="vivid"  ; break;;
			 4 ) CODE_NAME="wily"   ; break;;
			 5 ) CODE_NAME="xenial" ; break;;
			 6 ) CODE_NAME="yakkety"; break;;
			 7 ) CODE_NAME="zesty"  ; break;;
			 8 ) CODE_NAME="artful" ; break;;
		esac
	done

	apt-get -y install xorriso
#	cd ~
	WORK_DIRS=`pwd`
	rm -rf   ${WORK_DIRS}/${CODE_NAME}/image ${WORK_DIRS}/${CODE_NAME}/install ${WORK_DIRS}/${CODE_NAME}/mnt
	mkdir -p ${WORK_DIRS}/${CODE_NAME}/image ${WORK_DIRS}/${CODE_NAME}/install ${WORK_DIRS}/${CODE_NAME}/mnt
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}
	# -------------------------------------------------------------------------
	if [ -f "../preseed_ubuntu.cfg" ]; then
		cp --preserve=timestamps "../preseed_ubuntu.cfg" "preseed.cfg"
	fi
	if [ ! -f "preseed.cfg" ]; then
		wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/preseed_ubuntu.cfg"
		mv "preseed_ubuntu.cfg" "preseed.cfg"
	fi
	# -------------------------------------------------------------------------
	if [ ! -f "mini-${CODE_NAME}-amd64.iso" ]; then
		wget -O "mini-${CODE_NAME}-amd64.iso" "http://ftp.riken.jp/Linux/ubuntu/dists/${CODE_NAME}/main/installer-amd64/current/images/netboot/mini.iso"
	fi
	VOLID=`volname "mini-${CODE_NAME}-amd64.iso"`
	# -------------------------------------------------------------------------
	mount -o loop "mini-${CODE_NAME}-amd64.iso" ${WORK_DIRS}/${CODE_NAME}/mnt
	pushd ${WORK_DIRS}/${CODE_NAME}/mnt > /dev/null
	find . -depth -print | cpio -pdm ${WORK_DIRS}/${CODE_NAME}/image/
	popd > /dev/null
	umount ${WORK_DIRS}/${CODE_NAME}/mnt
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}/install
	gunzip < ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz | cpio -i
	cp --preserve=timestamps ${WORK_DIRS}/${CODE_NAME}/preseed.cfg .
	mv ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz.orig
	find . | cpio -H newc --create | gzip -9 > ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz
# -----------------------------------------------------------------------------
#	cat <<- _EOT_ > ${WORK_DIRS}/${CODE_NAME}/image/syslinux.cfg
#		default vmlinuz
#		append auto=true vga=normal file=/preseed.cfg initrd=initrd.gz priority=critical console-setup/ask_detect=false pkgsel/language-pack-patterns=pkgsel/install-language-support=false quiet --
#_EOT_
# -----------------------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME}/image > /dev/null
	xorriso -as mkisofs \
	    -r -J -V "${VOLID}" \
	    -o ${WORK_DIRS}/${CODE_NAME}/mini-${CODE_NAME}-amd64-preseed.iso \
	    -b isolinux.bin \
	    -c boot.cat \
	    -no-emul-boot \
	    -boot-load-size 4 \
	    -boot-info-table \
	    -m initrd.gz.orig \
	    -iso-level 4 \
	    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
	    .
	popd > /dev/null
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}
	ls -al
# -----------------------------------------------------------------------------
	exit 0
# = eof =======================================================================
# Ver. :コードネーム    :リリース日    :サポート期限
# 10.04:Lucid Lynx      :2010年04月29日:2013年05月09日(デスクトップ)/2015年04月(サーバ)
# 10.10:Maverick Meerkat:2010年10月10日:2012年04月
# 11.04:Natty Narwhal   :2011年04月28日:2012年10月
# 11.10:Oneiric Ocelot  :2011年10月13日:2013年05月
# 12.04:Precise Pangolin:2012年04月26日:2017年04月
# 12.10:Quantal Quetzal :2012年10月18日:2014年04月
# 13.04:Raring Ringtail :2013年04月25日:2014年01月
# 13.10:Saucy Salamander:2013年10月17日:2014年07月
# 14.04:Trusty Tahr     :2014年04月17日:2019年04月
# 14.10:Utopic Unicorn  :2014年10月23日:2015年07月
# 15.04:Vivid Vervet    :2015年04月23日:2016年01月
# 15.10:Wily Werewolf   :2015年10月22日:2016年07月
# 16.04:Xenial Xerus    :2016年04月21日:2021年04月
# 16.10:Yakkety Yak     :2016年10月13日:2017年07月
# 17.04:Zesty Zapus     :2017年04月13日:2018年01月
# 17.10:Artful Aardvark :2017年10月19日:2018年07月
