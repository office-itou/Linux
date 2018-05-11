#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu 18.04]                                        *
# *****************************************************************************

	LIVE_VNUM=18.04

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
			1f8b0800e812ae5a0003ed186b6fdb36305fed5fc12a45b316a019bb491f
			691220c8da6ceb63419b7c9a3783a2288bb1440a2495c4ddf6df7794ac58
			56eca4719c0ec374b0a5d3f178c7e31dc93b667e266d860db759da31d1da
			43c026c0cbadadfc0d507b777bdbdbcfd7bacf7bbdcdedcdded6f3ee9a23
			bd78b986361f643435c88ca51aa135ad94bd89efb6f6ff28ac3f22be90c4
			a7266ab75bfc3255daa2e32fdd3def0716399b9f22afdd4a144409c216a5
			5a31e4e00a210eab7098b1098d6bb84208601586809fdb24852602582102
			905986d49a099d38b444da2dc22d23420adb0948e0670639efd9f63ac218
			b9d1a2cc70bd01646ead9043202f03ed160b1071f2604e44887e438f100e
			51e75c249aa1dfdf201b71d96eb5388b14c21c79a00ec92cf1b9ee4b875b
			ea1babd2bdade23316c64e3116516df68065677fe0a1fd89d8762b14b3da
			9c4f34eb282d86159d8607088b823a6141df07faa0ddbdc1e08dc774bd2f
			1935607bfff19f276f3f7ffcdb4342f665df7ab190d9a5879eba8fbefd70
			f0e968efb0c0dfbc71ef67334d6774f0cb71e7f4e41d7e3565e286327816
			d1e8d836f2e9c9dd9c6f5528568cc6dc2ce9e0899bd75b56243ca096331b
			3bc1d87d7f5512cc3a30829213351a2b88ff58226c424432a38901f771e2
			98840c1599f2a13c38f3813931d02b1f6329baf8caadd9f30aab331bbef2
			72cae9c1d15b47dde1d2ab77bcec76f1888f139a22ef2cf5dca3bbf902de
			f0b35c274282013bccea78009a07fec8a45732d05f280f18709921852b48
			7ddac9c61c4fcf7c4fbbe7e37c3c45f311d705ccefee1d7ac4aba8f5a0db
			7e65ce78872919163e4e5490c1e08584e51dc7f771727545e5ba686a8951
			9966dc74dc6aacaf2f96229ca2f9bc3748703da945bbbb180ddefe7a3228
			4dab33035f2be03e8aac4d7708394b3b54b3489cf34e969fc43009092950
			82606b0bb318255448a4b9b15a30cb83a544641093e75c1bbe4cef4c2edd
			17fb948ddc32367533aea4de6f70384bdd02be26fe5ea25632a005b36638
			cbb4b0e3eb124a0125c72d26dd45d02283ee20e3ca9c3cbef3fdb805d18d
			8770ac1526a3274f5049c1d0211d6a1ad4a9012c023c699a0a808672b10f
			a54ab823ba031ce7e73b0f70a098c16774d2ea4ef92bd25d0eb039d4640c
			2bdf607058344e610f70d86a60be3e01690b4ed4d7d51fdbf3f5b19826f4
			7ce5ca16ea93b60886efa54fa55c1a1341a06a88cf87d707f96e0826ae52
			d18dfa4ce2b35870c88d99080dceac885714a0f3f5d194b288f756a3e21b
			f441f911bc7e006d0bed93361a174f0cdb5da2e4c3ea8b85afb90a43c138
			8e789cba2dab4a8bbb9bf24edbd82dfa42a179a82e27f9a6936ca34c065c
			fb420715eacaf429690db6744415865cd4954455d250d948b019523a4393
			ca2accce46985f5a4d6fd7175339cce8906388d3112ece0337a573c9907e
			408231db768db9645bb07f42199c882cc1be5617b0c91419ea6457bd4ff9
			b128432d4493100efec8e1795e7c5319b8b8d7124e9eadf30c5947871167
			23709646925f20d8db693e5bbd2de4ca1c8328d0c68bf966d9366ae2f34e
			068495d8d6f572e41ea3ffe393b2221c1fc2840464fd09a9d691260a56e1
			bf391e04d1ee1f0c9c0fc4f056dfd5f8ef6ee5b12b03ed67a5ec0735849c
			b1f38cd449636ee6167a55571f53632e940e0e3237522ba0a211aae87a43
			d3ac4bc94fcad8f77c8cfaceb4beb32b7f0c22a00f380b0c1d40354b82eb
			6ebe8398a0b7bddd7d3d5fd0ec3dc5a9e13f7efa82a4eacb9f6157d01c08
			fabd5417d26930d0508989fc607f989800d12e6b35b70643c958738ebb8d
			82455686f035f993b4a47c7fdba631afd337afb4da449fb8557ef4f104c1
			b9d697bb47b1f269bcefee74a641a8f21b22f0c03b9b9ee6463aca2e9930
			573cc1624ee5f23778339ea8141934b31002893aafd41e8e96ab9b92269f
			736e1b55da6e6593abca309ebda2cc6f3acb0bd108ea1ca5c708b3fc5e55
			d8f6bf7dd5db40030d34d040030d34d040030d34d040030dfc4fe11fcb02
			6f5000280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ]; then
		wget "http://ftp.riken.jp/Linux/ubuntu-releases/artful/ubuntu-${LIVE_VNUM}-desktop-amd64.iso"
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
		isohybrid ../../ubuntu-${LIVE_VNUM}-desktop-amd64-custom.iso
	popd > /dev/null
	ls -l

# =============================================================================
