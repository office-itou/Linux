#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [Debian 9.5.0]                                          *
# *****************************************************************************

	LIVE_VNUM=9.5.0

# == tools install ============================================================
	apt-get -y install debootstrap xorriso squashfs-tools

# == initial processing =======================================================
#	cd ~
	rm -Rf   ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz debian-setup.sh | xxd -ps
	if [ ! -f ./debian-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b08009012ae5a0003ed57516fdb3610f6abf52bae7691ac0564c5aedd
			6c4b13a048d76c6b1b046df2346d062d51161b891448ca8937ecbfef28c9
			b1e4b84ee22e1b0af003629e8ec73b91dfe97809e98411ee2aaaf3aca7e2
			d663600fb13f1c162362751cbdec8f5afd1783c15e7ff072bfffa285e370
			7fd482bd47799b15e44a1309d09242e84d7677cd7fa3e83ef1268c7b13a2
			62c769d3eb4c480d679ffa879def82d8ecf919749c762a72aec1d5904911
			80c18de019a966a1e62a5266e246f050aa198474a6d30ca73c944a172834
			0d32ad2abd67c485e0b43daa038f71a67ba1174e7205863ded74c175c1bc
			2de48aca5d5453ad199fa27a1b38ed2004cff8c3336111fc064fc08da037
			63a90ce0f703d031e54ebb4d8358804ba183e180e7e9844a9f1b599389d2
			223b1c968f09537a29053191ea104d7e3c1a77e0a872ebb423d68c663891
			414f4836adc55434049795daca04fe1bf818dd8cb8e1dda7a4ebf38028dc
			bbfff4aff39f3e7ef8bb038cfbdcd79d84f1fcba03cfcc83afdfbf3e3d39
			3c2ee58303333e6f4c7d26e35fcf7a17e76fddef97465491007fcb6c3466
			bbc5f11434a722cc138ac190fa24d992e18a669269778ab4e4594834859d
			1d5868dc392aa79284abda101974aba9a5039c58bc9026ead2fd4c3282bb
			a0cd2737a4ea12f3c21ce59a038e02a6afdd54fcb981d1f52b8384a46476
			277d6bb45c975b7ff84a9151ae548c57879c51f990955831220cbb454c95
			4e828451ac13018b949b6b96a8fbad34c52c65795ae6104bdd40f0886d5b
			20ea3954f3c54b0acb1815275f1ba08c7153158a0258baf62249556ce49e
			79814d85e2cbab3692b0819c9b4aa0bc2e1cc734b8844848e0f40a309fc8
			c49486c110344ba90282baf997ed9a66bb2bee8b450a9d2da4219a7c0d9a
			eeff38159a45f3633c90d0ebee78b54a83d91dfe1bfcad61105d9bbf705c
			a6ce9ddcadd83f7c976754a64c7fc42bedbd98320ebde7deaa6a4ed5ed93
			5da1fa8c28752564f83a376faa59403413e5d20d534d4abd9f85d2efe81c
			7cb335dfecabf819c7a81fd32054647c49e75e789be607b80907a351ff87
			f58e9a37d985a26f4e3f01173eff65ca85a4a890efb8b8e22682c2895a4e
			1485eb7172025d9bee45dd990c0bc315724cbf821fd922856ff9afcaee62
			bc5fd158b7e8de5fdaca419f9baffce4c3398828f2f9ab93444c4872646e
			fd65128aa2874006deeaeca2d8a4d1bcf22ae31a13414209dfbec76b3051
			bbc649ae31055231abddee4657845baaaac735fda8c89c765e35b351d26c
			628b5e78d132c7d84908390737283a6fa69dfffb9f010b0b0b0b0b0b0b0b
			0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b8b6f1eff0010832c0a00280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ]; then
		wget "http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
#		wget "http://ftp.riken.jp/.2/debian/debian-cd/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
	fi
	LIVE_VOLID=`volname ./debian-live-${LIVE_VNUM}-amd64-lxde.iso`
# -----------------------------------------------------------------------------
	mount -o loop ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/live/filesystem.squashfs.orig ]; then
		  mv ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/cdimg/live/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./debian-live/cdimg/live/filesystem.squashfs.orig ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	cp --preserve=timestamps debian-setup.sh ./debian-live/fsimg/root
	chmod u+x ./debian-live/fsimg/root/debian-setup.sh
	LANG=C chroot ./debian-live/fsimg /bin/bash /root/debian-setup.sh
	rm -f ./debian-live/fsimg/root/debian-setup.sh
# -----------------------------------------------------------------------------
	rm -rf ./debian-live/fsimg/tmp/* ./debian-live/fsimg/root/.bash_history ./debian-live/fsimg/root/.viminfo ./debian-live/fsimg/var/cache/apt/*.bin ./debian-live/fsimg/var/cache/apt/archives/*.deb
# -- file compress ------------------------------------------------------------
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs -comp xz -wildcards -e *.orig
	ls -l ./debian-live/cdimg/live/
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/isolinux/menu.cfg.orig ]; then
		chmod +w ./debian-live/cdimg/isolinux/menu.cfg
		sed -i.orig ./debian-live/cdimg/isolinux/menu.cfg                                                 \
		    -e 's/locales=ja_JP\.UTF-8/& timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	fi
# -- make iso image -----------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		xorriso -as mkisofs \
		    -r -J -V "${LIVE_VOLID}" -D \
		    -o ../../debian-live-${LIVE_VNUM}-amd64-lxde-custom.iso \
		    -b isolinux/isolinux.bin \
		    -c isolinux/boot.cat \
		    -cache-inodes \
		    -no-emul-boot \
		    -boot-load-size 4 \
		    -boot-info-table \
		    -m *.orig \
		    -iso-level 4 \
		    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
		    .
	popd > /dev/null
	ls -l

# =============================================================================
