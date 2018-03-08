#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [Debian 9.3.0]                                          *
# *****************************************************************************

	LIVE_VNUM=9.3.0

# == tools install ============================================================
	apt-get -y install debootstrap syslinux syslinux-utils genisoimage squashfs-tools

# == initial processing =======================================================
#	cd ~
	rm -Rf   ./debian-live
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz debian-setup.sh | xxd -ps
	if [ ! -f ./debian-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b080068af405a0003ed576d6fdb3610f657eb575ced22590bc88a9da4
			d996264091b6e96b10b4c9a76933688ab2d848a420524edc61ffbd47498e
			25c7751277d950800f10f3743cde897c4ec78b623a4f7b2a6a3d20b6107b
			7b7bc588581c779ff5775bfdedc160ab3f78b6d7df6e6df551d86ec1d643
			bed40cb9d22403686552ea5576b7cdffa4e83ef2465c7823a222c769b3ab
			54661a4e3ff70f3abfd0c8ecf909749c762273a1c1d590669282c1b5e019
			a966a1a62a5466e25af050aa19046ca29314a73c944a1728340d52ad2abd
			67c499e0b43da6a9c705d7bdc00b46b902c39e76bae0ba60de1672c5b24d
			5433adb918a37a1d386d1a8067fce199f010fe8047e086d09bf024a3f0e7
			3ee88809a7dd663492e032e8603810793262992f8cacc94869991eec948f
			31577a2ed18864ea004d7e3f1c76e0b072ebb443de8c6638c9684f667c5c
			8ba958002e2fb59509fc37f031ba1971c39b8f49d7179428dcbbfff8efb3
			579f3efed3012e7ce1eb4ecc457ed58127e6c1d71f5e9c1c1f1c95f2febe
			199f36a6be90e1bbd3def9d96bf7d7b9115384e26f998dc66cb3389e82e6
			440679cc3018521fc76b325cd14c52ed8e91963c0d8866b0b101338d3b45
			e53823c1a2364006dd6a6aee0027662fa489ba70bf9094e02e58f3c90d98
			bac0bc3047b9e48043caf5959bc8af2b185dbe92c62421935be95ba215ba
			dcfafd57ca9409a522173fb809cbeeb3122b468861d788a992118d39c33a
			4179a8dc5cf358dd6da5296609cf93328778e2522942be6e81a8e750cd97
			28292c63549cfc688032c67555280a60e9da0b33a62223f7cc0bac2a14df
			5fb5928415e45c5702e575e12862f402429981609780f94446a6340c7640
			f3842920a89b7edfae69b6b9e0be58a4d0d94cda41931f41d3fd5f2752f3
			707a84071278dd0daf566930bb837f83bf250ca26bf3170ccbd4b995bb05
			fbfbeff2946509d79ff04afb20c75c40efa9b7a89a3275f36417a83e254a
			5dca2c78919b37d59c12cd65b974c5549352ef8d54fa3d9b826fb6e69b7d
			153fc308f54346034586176cea053769be879b60b0bbdbff6db9a3e64d76
			aed8cb93cf20a42fde8e85cc182ab2f7425e0a1341e1442d278ac2f53039
			81ae4df7a26e4d8699e10239a65fc18f6c96c237fc57657736dead682c5b
			74e72f6de1a0cfcc577efcf10c6418fae2f9712c47243e34b7fe3c0965d1
			432003af757a5e6cd2689e7b95718d091a3322d6eff11a4cd4ae71926b4c
			81444e6ab7bbd115e1e6aaea71493f2a53a79d57cd6c18379bd8a2179eb5
			cc117612329b824b8bce9b6be7fffe67c0c2c2c2c2c2c2c2c2c2c2c2c2c2
			c2c2c2c2c2c2c2c2c2c2c2e2a7c7375433f06800280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ]; then
		wget "http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
#		wget "http://ftp.riken.jp/.2/debian/debian-cd/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ./debian-live/media
	pushd ./debian-live/media
	find . -depth -print | cpio -pdm ../cdimg/
	popd
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/live/filesystem.squashfs.orig ]; then
		  mv ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/cdimg/live/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -o loop ./debian-live/cdimg/live/filesystem.squashfs.orig ./debian-live/media
	pushd ./debian-live/media
	find . -depth -print | cpio -pdm ../fsimg/
	popd
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	cp -p debian-setup.sh ./debian-live/fsimg/root
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
	pushd ./debian-live/cdimg
	genisoimage -J -r -V "Debian ${LIVE_VNUM} amd64" -cache-inodes -l -D -o ../../debian-live-${LIVE_VNUM}-amd64-lxde-custom.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -x *.orig .
	isohybrid ../../debian-live-${LIVE_VNUM}-amd64-lxde-custom.iso
	popd
	ls -l

# =============================================================================
