#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu 17.10.1]                                        *
# *****************************************************************************

	LIVE_VNUM=17.10.1

# == tools install ============================================================
	apt-get -y install debootstrap syslinux syslinux-utils genisoimage squashfs-tools

# == initial processing =======================================================
#	cd ~
	rm -Rf   ./ubuntu-live
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz ubuntu-setup.sh | xxd -ps
	if [ ! -f ./ubuntu-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b08002b85425a0003ed185d73db362caff6af60955eb3ee8e66ec264b
			9b26b9cb656db6f563b936799a371f4551166389d491541277db7f1f2859
			b1acd849e338dded269c2d41200810044802ccfc4cda0c1b6eb3b463a2b5
			c7804d809d9d9dfc0d507b777bdbdb2fd6ba2f7abdcdedcdded68bee9a23
			ed6cafa1cd47194d0d3263a946684d2b656fe3bbabfd3f0aeb4f882f24f1
			a989daed16bf4a95b6e8e47377dffb8e45cee6e7c86bb712055182b045a9
			560c39b84688c32a1c666c42e31aae1102588521e0173649a18900568800
			649621b56642270e2d91768b70cb8890c2760212f89941ce7bb6bd8e3046
			6eb428335c6f00995b2be410c8cb40bbc502449c3c981311a2dfd0138443
			d4b9108966e8f7d7c8465cb65b2dce228530471ea843324b7caefbd2e196
			fac6aa747fabf88c85b1538c45549b7d60d93d1878e86022b6dd0ac5ac36
			e713cd3a4a8b6145a7e101c2a2a04e58d0b7813e68776f3078e3295def4b
			460dd8de7ffae7e99b4f1ffef690907dd9b75e2c6476e5a1e7eea36fdf1f
			7e3cde3f2af0d7afddfbfb99a6733af8e5a47376fa16bf9c327143193c8b
			68746c1bf9f4e46eceb72a142b46636e9674f0c4cdeb2d2b121e50cb998d
			9d60ecbebf2809661d1a41c9a91a8d15c47f2c1136212299d1c480fb3871
			4c42868a4cf9501e9cf9c09c18e8958fb1145d7ce5d6ec7b85d5990d5f7a
			39e5ecf0f88da3ee72e9d53b5e75bb78c4c7094d91779e7aeed1ddfc01de
			f0b35c27428201bbccea78009a07fec8a4d732d05f280f18709921852b48
			7ddac9c61c4fcf7c4fbbe7e37c3a45f311d705ccefee1d79c4aba8f5a0db
			4165ce78872919163e4e5490c1e08584e51dc70f71727545e5ba686a8951
			9966dc74dc6aacaf2f96229ca2f9bcb748703da9457b7b180ddefc7a3a28
			4dab33035f2be03e8aac4d7709394f3b54b3485cf04e969fc43009092950
			82606b0bb318255448a4b9b15a30cb83a544641093175c1bbe4cef4c2edd
			17fb948ddc32367533aea53e6c70384bdd02be21fe41a25632a005b36638
			cbb4b0e39b124a0125c71d26dd47d02283ee21e3da9c3cbef3fdb805d18d
			8770ac1526a367cf5049c1d0211d6a1ad4a9012c023c699a0a808672b10f
			a54ab823ba031ce7e73b0f70a098c1e774d2ea4ef96bd27d0eb039d4640c
			2bdf607058344e610f70d86a60be3e01690b4ed497d51fdbf3f5b19826f4
			62e5ca16ea93b608866fa54fa55c1a1341a06a88cfc7d707f96e0826ae52
			d1adfa4ce2b35870c88d99080dceac885714a0f3f5d194b288f756a3e22b
			f441f911bc7a046d0bed93361a174f0cdb5da2e4e3ea8b85afb90a43c138
			8e789cba2dab4a8bbb9bf25edbd81dfa42a179a8ae26f9a6936ca34c065c
			fb420715eacaf429690db6744415865cd4954455d250d948b019523a4393
			ca2accce47985f594defd6175339cce8906388d3112ece0337a573c9907e
			408231db7683b9645bb07f42199c882cc1be5697b0c91419ea64577d48f9
			b128432d4493100efec8e1795e7c5b19b8b8d7124e9eadf30c5947471167
			23709646925f22d8db693e5bbd2de4ca1c8328d0c68bf966d9366ae2f34e
			068495d8d6cd72e401a3ffe3a3b2221c1fc1840464fd19a9d691260a56e1
			bf391e04d1ee1f0c9c0fc4f04edfd5f8ef6fe5892b03ed27a5ec7b35849c
			b1f33da993c6dccc2df4aaae3ea1c65c2a1d1c666ea45640452354d1f596
			a65997929f94b1eff818f59d697d6757fe1844401f7016183a806a960437
			dd7c0f31416f7bbbfb6abea0d97b8a33c37ffcf81949d5973fc3aea03910
			f43ba92ea5d360a0a11213f9c1fe383101a25dd66aee0c8692b1e61c771b
			058bac0ce11bf2276949f9feba4d635ea7af5e69b5893e75abfcf8c32982
			73ad2ff78e63e5d3f8c0dde94c8350e53744e081b7363dcb8d74943d3261
			ae7882c59ccae56ff0663c51293268662104127551a93d1c2d5737254d3e
			e7dc36aab4ddca265795613c7b4599df749617a211d4394a8f1166f9bdaa
			b0ed7ffbaab781061a68a081061a68a081061a68a081061af89fc23fc1aa
			4ebc00280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ]; then
		wget "http://ftp.riken.jp/Linux/ubuntu-releases/artful/ubuntu-${LIVE_VNUM}-desktop-amd64.iso"
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ./ubuntu-live/media
	pushd ./ubuntu-live/media
	find . -depth -print | cpio -pdm ../cdimg/
	popd
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ]; then
		  mv ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ./ubuntu-live/media
	pushd ./ubuntu-live/media
	find . -depth -print | cpio -pdm ../fsimg/
	popd
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	cp -p ubuntu-setup.sh ./ubuntu-live/fsimg/root
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
	pushd ./ubuntu-live/cdimg
	rm -f md5sum.txt
	find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt
	genisoimage -J -r -V "Ubuntu ${LIVE_VNUM} amd64" -cache-inodes -l -D -o ../../ubuntu-${LIVE_VNUM}-desktop-amd64-custom.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -x *.orig .
	isohybrid ../../ubuntu-${LIVE_VNUM}-desktop-amd64-custom.iso
	popd
	ls -l

# =============================================================================
