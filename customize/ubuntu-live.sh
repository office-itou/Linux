#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu 18.04.1]                                        *
# *****************************************************************************

	LIVE_VNUM=18.04.1

# == tools install ============================================================
	apt-get -y install debootstrap xorriso squashfs-tools

# == initial processing =======================================================
#	cd ~
	rm -Rf   ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz ubuntu-setup.sh | xxd -ps
	if [ ! -f ./ubuntu-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b080077ce4b5b0003ed186b6fdb36305fed5fc12a45b316a019e7d1b4
			691220c8da6ceb63419b7c9a3783a2288bb1440a2495c4ddf6df77a4ec58
			76eca4719c0ec374b0a5d3f178c7e31dc93b1661216d810db745de32c9ca
			63c03ac0cece8e7bb777b6d7ab6f876e6c6f6faeb43737373676b676daed
			ed95f5f6e6d6cbad15b4fe28a39982c258aa115ac9a8b15ccfe7bbabfd3f
			0aab4f48282409a9499acd06bfca95b6e8e44b7b3ff881255a29fb1c05cd
			46a6204a10b628d78a2107d708715885c30c4c6c5cc3354200ab3044fcc2
			66393411c04a11804c32e4d60ce9c4a123a4d920dc3222a4b0ad88446161
			90f39e6dae228c911b2d2a0cd76b40e6d60ad903f222d06cb00811270fe6
			44c4e837f404e118b52e44a619fafd0db20997cd4683b34421cc5100ea90
			2cb290eb8e74b8a5a1b12adfdf2a3f5361ec186309d5661f58760fba013a
			188a6d366231a9cdf944b396d2a257d1697884b028a94316f47da003dadd
			1b0c5e7b4a573b925103b6779efe79faf6f3c7bf03246447766c900a595c
			05e8b9fbe8d80f879f8ef78f4afccd1bf77e31d1744ebbbf9cb4ce4edfe1
			5763266e288367198d8e6dcd4f8f77b3dfaa50aa184db959d0c14337af36
			acc878442d67367582b1fbfeaa249875680425a7aa3f5010ffa944d8c488
			14461303eee3c43109192b32e6433e38fdc09c18e8e5c738125d7e796bf6
			83d2eac2c6af024f393b3c7eeba8bb5c06d31dafda6ddce7838ce62838cf
			03f768afbf8437fc604bca8404037699d569173477c3bec9af65a0bf900f
			18709921a52bc8f4b493b5199e9ef81e77f7e37c3a46fd88a705ccee1e1c
			0524a8a80da0db4165ce788b2919973ece5454c0e08584e59da60f717275
			45795d34b7c4a842336e5a6e354eaf2f96239ca3d9bcb748703da9457b7b
			1875dffe7ada1d9936cd0c7c8d888728b136df25e43c6f51cd1271c15b85
			3f8961123252a204854249c1504685449a1bab05b33c5a4844013179c1b5
			e18bf42ee4c27d714859df2d63336dc6b5d4870d0e17b95bc037c43f48d4
			52063467d60c678516767053c248c088e30e93ee23689e41f790716d8e8f
			6fbf1f3720ba710f8eb5d264f4ec191a513074c87b9a46d3d40816011e36
			8d0540c368b1f7a4cab823ba031cfbf39d473852cce0733a6c75a7fc35e9
			3e07d80c6a3680956f30382c19e4b007386c39305b9f80b40567eaebf28f
			edd9fa584a337ab1746573f5495b06c3f7d2a7722e8d49205035c4e7e3eb
			837c37061397a9e8567d260b592a38e4c64cc4061756a44b0ad0d9fa684e
			59c23796a3e21bf441f911bd7e046d73ed933619944f0cdb5da6e4e3ea4b
			45a8b98a63c1384e789abb2dab4a4bdbebf25edbd81dfa62a179acae86f9
			a6936c9342465c87424715ead2f429690db6b44f15865cd4954455524fd9
			0452882a299fa049651566e77dccafaca677eb4ba9ec15b4c731c4691f97
			e7819bd29964483f20c1986cbbc13c629bb37f42199c8922c3a15697b0c9
			9419ea70577d48f9312f432d4593180efec4e13e2fbead0c9cdf6b01274f
			d67986aca2a384b33e384b23c92f11ecedd4cfd6c61672658e41146883f9
			7c936c6b53e27d2703c246d8d6cd72e401a3ffe393b2221e1cc1844464f5
			19a9d691268996e1bf191e04d1ee1f759d0f44ef4edf4df1dfdfca135706
			dacf4ad90faa073963eb0599260db89959e8555d7d428db9543a3a2cdc48
			ad808a069240dff596a64997929f94b1eff900759c691d67977f7413a077
			398b0ced42354ba29b6ebe879868637bbbfd7ab6a0c97b8a33c37ffcf405
			49d5913fc3aea03910f47ba92ea5d360a0a11213fe607f9c9800d12e6b35
			7706c38871ca39ee360a16d928846fc81fa625a3f7b76d1ab33a7df34a9b
			9ae853b7ca8f3f9e2238d73a72ef3855214d0fdc9dce380895bf21020fbc
			b3f99937d251f6c890b9e20996722a17bfc19bf044a5c8a0858510c8d445
			a5f67034af6e4c1a7eceb86d5479b3510caf2ae374f28ad2df748e2e4413
			a873941e20ccfcbdaab0cd7ffbaab7861a6aa8a1861a6aa8a1861a6aa8a1
			861a6af89fc23f3fee6f2600280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ]; then
		wget "https://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${LIVE_VNUM}/ubuntu-${LIVE_VNUM}-desktop-amd64.iso"
#		wget "https://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${LIVE_VNUM}/ubuntu-${LIVE_VNUM}-live-server-amd64.iso"
#		wget "http://cdimage.ubuntu.com/releases/${LIVE_VNUM}/release/ubuntu-${LIVE_VNUM}-server-arm64.iso"
	fi
	LIVE_VOLID=`volname ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso`
# -----------------------------------------------------------------------------
	mount -o loop ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ]; then
		  mv ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	cp --preserve=timestamps ubuntu-setup.sh ./ubuntu-live/fsimg/root
	chmod u+x ./ubuntu-live/fsimg/root/ubuntu-setup.sh
	LANG=C chroot ./ubuntu-live/fsimg /bin/bash /root/ubuntu-setup.sh
	rm -f ./ubuntu-live/fsimg/root/ubuntu-setup.sh
# -----------------------------------------------------------------------------
	rm -rf ./ubuntu-live/fsimg/tmp/* ./ubuntu-live/fsimg/root/.bash_history ./ubuntu-live/fsimg/root/.viminfo ./ubuntu-live/fsimg/var/cache/apt/*.bin ./ubuntu-live/fsimg/var/cache/apt/archives/*.deb
# -- file compress ------------------------------------------------------------
	chmod +w ./ubuntu-live/cdimg/casper/filesystem.manifest
	chroot ./ubuntu-live/fsimg dpkg-query -W --showformat='${Package} ${Version}\n' > ./ubuntu-live/cdimg/casper/filesystem.manifest
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs -comp xz -wildcards -e *.orig
	printf $(du -sx --block-size=1 ./ubuntu-live/fsimg | cut -f1) > ./ubuntu-live/cdimg/casper/filesystem.size
	ls -l ./ubuntu-live/cdimg/casper/
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/isolinux/menu.cfg.orig ]; then
		chmod +w ./ubuntu-live/cdimg/isolinux/menu.cfg
		sed -i.orig ./ubuntu-live/cdimg/isolinux/menu.cfg                                                 \
		    -e 's/locales=ja_JP\.UTF-8/& timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	fi
# -- make iso image -----------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
		rm -f md5sum.txt
		find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt
		xorriso -as mkisofs \
		    -r -J -V "${LIVE_VOLID}" -D \
		    -o ../../ubuntu-${LIVE_VNUM}-desktop-amd64-custom.iso \
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
