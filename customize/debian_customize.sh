#!/bin/bash
# =============================================================================
# ブータブルCDの作成手順 [debian:amd64:mini.iso]
# =============================================================================
	while :
	do
		cat <<- _EOT_
			# ID:コードネーム
			#  1:oldoldstable
			#  2:oldstable
			#  3:stable
			#  4:testing
_EOT_
		echo ID番号+Enterを入力して下さい。
		read DUMMY
		case "${DUMMY}" in
			 1 ) CODE_NAME="oldoldstable"; break;;
			 2 ) CODE_NAME="oldstable"   ; break;;
			 3 ) CODE_NAME="stable"      ; break;;
			 4 ) CODE_NAME="testing"     ; break;;
		esac
	done

	apt-get -y install syslinux mtools mbr genisoimage dvd+rw-tools
#	cd ~
	WORK_DIRS=`pwd`
	rm -rf ${WORK_DIRS}/${CODE_NAME}
	mkdir -p ${WORK_DIRS}/${CODE_NAME}/image
	mkdir -p ${WORK_DIRS}/${CODE_NAME}/install
	mkdir -p ${WORK_DIRS}/${CODE_NAME}/mnt
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}
	# -------------------------------------------------------------------------
	if [ -f "../preseed_debian.cfg" ]; then
		cp -p "../preseed_debian.cfg" "preseed.cfg"
	fi
	if [ ! -f "preseed.cfg" ]; then
		wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/preseed_debian.cfg"
		mv "preseed_debian.cfg" "preseed.cfg"
	fi
	# -------------------------------------------------------------------------
	if [ ! -f "mini-${CODE_NAME}-amd64.iso" ]; then
		wget -O "mini-${CODE_NAME}-amd64.iso" "http://ftp.jp.debian.org/debian/dists/${CODE_NAME}/main/installer-amd64/current/images/netboot/mini.iso"
	fi
	# -------------------------------------------------------------------------
	mount -o loop "mini-${CODE_NAME}-amd64.iso" ${WORK_DIRS}/${CODE_NAME}/mnt
	pushd ${WORK_DIRS}/${CODE_NAME}/mnt
	find . -depth -print | cpio -pdm ${WORK_DIRS}/${CODE_NAME}/image/
	popd
	umount ${WORK_DIRS}/${CODE_NAME}/mnt
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}/install
	gunzip < ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz | cpio -i
	cp -p ${WORK_DIRS}/${CODE_NAME}/preseed.cfg .
	mv ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz.orig
	find . | cpio -H newc --create | gzip -9 > ${WORK_DIRS}/${CODE_NAME}/image/initrd.gz
# -----------------------------------------------------------------------------
	cat <<- _EOT_ > ${WORK_DIRS}/${CODE_NAME}/image/syslinux.cfg
		default vmlinuz
		append auto=true vga=normal file=/preseed.cfg initrd=initrd.gz priority=critical console-setup/ask_detect=false pkgsel/language-pack-patterns=pkgsel/install-language-support=false quiet --
_EOT_
# -----------------------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME}/image
	genisoimage -J -r -R -o ${WORK_DIRS}/${CODE_NAME}/mini-${CODE_NAME}-amd64-preseed.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
	popd
# -----------------------------------------------------------------------------
	cd ${WORK_DIRS}/${CODE_NAME}
	ls -al
# -----------------------------------------------------------------------------
	exit 0
# = eof =======================================================================
