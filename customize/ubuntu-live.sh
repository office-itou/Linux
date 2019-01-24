#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu 18.10]                                          *
# *****************************************************************************

	LIVE_VNUM=18.10

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
			1f8b08002381495c0003ed5b7b6f1bc711f7bfd4a7d852b2293b3e1e49f9
			d1c8a611c39163d5cf4a729bc474cfcbbb2579e6bd727b4789b115c0129a
			264dda3cd03a681a14089034695227298a064d53241f86a19c7e8bceec1d
			c93b3e443da806056e044b77fbf8edececececccced92ffb96e74b9c79be
			93e5b543074139a0d3274e88bf407d7f0ba74fcf9d38949f3b5128cce572
			73738543b97ce1e4e9538748ee40b8e9239f7bd425e4906bdbde76edc6d5
			ff9fd2f48fe4b26ec965ca6b53d3449a244da540ab8864a6429a26ad8d7f
			b6363f6a6d3e6cbff265fb9bf75b1b6f6fbdf76afbd75fb51e7cda7af087
			d6c66b6117e647fb7cd5da7cb9b5f9efd6c6b7f09cfbeeeb0fdb1f3c6c3d
			f878ebbd4fda9fbdfbf89bbfb43f7875ebf75fb41e7cd67e63e3f12f3f6a
			3df8e8f13f36befbd7cb5329a6d66c923e36594a7770ef68d463e489f4e1
			e7e4c3a67c5823872fcd1fbe3a7f78397d87cc13542b8fdc9ac9dd4e1f18
			23b860c463aea95bc8cabe17ac62a90b96367b94dcebb02c4d74000944b1
			b4b0a22caf2c1767f25353a99ace3ddb6d12499d9a4ec9cc5365ddd2bdac
			266b659f83086d07ca7dd3061b45648d3564c7e3e4fe7d12164915a35b1c
			6f4890061b461af1261fd6088a238d1cd7568734c2e2a91f56bd98a51db0
			72a5d89aee91997be182ad4fad07fa862ba453437f71dffa1055b2c9a1a2
			92792e754826506792cf903c299039923f8993726cd8973796f3c5f4ac5a
			43ab7e94c04e4a85cbeb91ce9af71e82f58e340125a908ede93e847ad36d
			01bae6990ed475953154bf680b5466d2d3eb88260fd90a604d02f91bb63a
			1939c5e43f3954943f671a917422a6219059b6ca2c3240a5a914fe9118c9
			70f917b7ce4bcf53e9c5dbf23439225733db349d26a5d9bb54f9c98deccd
			958bd28f89f85d3a2a97f2d86fa029b3949bcbc39a4ea502ee24e06e2ae5
			3bb8e5a4a0885c397fed996264105896e8b4d6b4aa6cac71c6b96e5bf295
			679f5e90a9efd981d9ef677dbacbd00c7d0a8eb8b57ad9040d950cdab47d
			8fdc8547dbf10088a89e6bccf355eaa894b34cb0e2a6adf9c0906e01b861
			ec6785a22b3e395429dd954dd676f56a20209771db686455dbaa8433b7a8
			c938731bcc25f9acf82959b1b21cfce46151a8e391603142094a2f0ceace
			783a7204552100abba54635d30a9b90fb08a6f18520771bf601df1ef8333
			d2dd1cb6c32cce6b5228d0aa659ba8da9ea75b55496826d324cd56b97497
			86b53eb4ed16c5c00c6a557d5a659243d5ba14b48636c38b257020595f9d
			001c0ad66daf975d66572abacaa41a331c811f2933f239abc7570fac6116
			0805a41a2b10d5770de2f2a6a5127064b5277d4f3738b198b76abb75c904
			a5ab82283835cb9470b3ac1a3ab3bc0898aa57b814768227d5364dd886f8
			5867aec58c8e30b9afd9c4a3bcce9941ca2ad19c7a557219cea70756f675
			4393c026c018709a118701733023586909db77de755b72bc66f03a7235a1
			1d4c43e2dc60346cabc3592099f68b2a69f08ae7684435a8491b44e7aaa4
			d554a7c32c74654645c2b32704d36133ea96bf46f80b3ef8fa303dcfb661
			cea83252c30cdf84044127b550462394160d9dcb4cbbc1f6acb4713015a6
			288e87fd827581f60e06be1e80757c073cb21b03066db8990bacb5c62ad4
			37c0e6c05a64e0e40eb6df5eec6bd45a4f0e554a4771b318f9b9ea24223f
			c055a947ce9e9588b2707d4521e7ce0522e27566c8e1405318d3e1c05bef
			7cb8f5de5fbfffe44f5b0f7fd57ef44efb7588e9de6a7ffecde3470f8998
			7b0a4f40922ecddc5b5958baba9e06b584425ca1b4d0e434394a426f4e1c
			d517ce9c09eb8f41cd1012f58c53e421ecf8ccca6565f1aa72f5fad337af
			2c147177f5ea9e85d2c58b8b0b4bcbc5a774b3aff2a72bfdfdc49463926d
			e8e664043b44b251c18a7180350c9d2ddf2cc3fe8f519adc7075d8cf5e0d
			2daec53a8d748b545c1b2aec0a61604c45653604f26819c3afe28918d0b5
			a02774e060f818074ce08b92b32bb47c0e01718c8a0e6e858a7e2e2715db
			ed201a10ebf52f499a5cc1527045d83c59aed9ab625c4239b9b0b274455a
			04b345349d3be02731ed78e791cc105a81a8540441c04b946f1c45ad5197
			170169be744e11a32c7b20812ab06be306424633d83023462614608051c1
			fcfd79acb84ff01c80f20eac65af6248d1c7fc0ac4afa4e3b8d5e0880389
			8849b0352fc67a078643ad183206b358418e162dd8dade71b2c4a08fca08
			30f4339dfb708a881e8e8f82066789c38146ec40d406e55e7cfa500007bd
			e7f36221ca27230d6af80ca5e54598d6ad0a945ab892ab3516c15c853300
			26b2aa836b52a360e7290960030da2c62a6df2ec10a5c7e3f8a0cc4954e9
			837160d6e8ade35ce011c2b42a98630ece850baf7842813befe92643e980
			e825e6bab61b722d8c351e7fa46192e0f8db0fbb51294c0e15a560d635dd
			25924364d3f2e45ab5c2e301560556a6bc9b136e0445c2a6199aad412833
			2ff7c604b797b36cc3c467099f41090c7b55b14167dce378882bbe25a2db
			e3e159c5498ee4c2104637253c21f5bd9d5831394f476f0d26062b629808
			1cd84655f7d602ee432f6bdf63a096e815728b489560e90260b9025a5bc3
			e7205aba7d0637226a746fa6936301552aa63fc39928858769189b5fb33d
			bdd2bc00d59a3c7d448620ada207c28180439bccc5719f700018ff694ab8
			26c3c432b9c107c4d23ffcce7751546e37f0f2d45bb26def8a5d052b9f3d
			26f71735199733dbc34cdfa09c4340a39df751049e1ed83cd1759baa4c0c
			46be045bfa326b9212ceaf849313bf14dcea0a53354e953a6bcada0033bb
			81d10a274fe69f1c0e148599a137397bfada321cad256b11e2489741817b
			194e5a0b478070cc8e6899887626b2ce7d5a160452a337dee406161ae6d9
			3e785a81ddf61cf4e67990e888d745b8daa6565c5f2ae8b0a0571dbcb636
			defefee3bfb5dff83cc8a8b436ff2c72275fe2ef079fb5363f1109955786
			02223b211ce06dfdf6c3c75fbebbf5dadbed37ffbc07b032b52ca629cca4
			105b0fc7fbcf1fbf6e3f7ab3b5f93ee26d7edadafcbab5f99680fc5c94bc
			3a761081ae38e116e0304afbf56fdb6ffea6b5f9a8b5f1456be383d6e6df
			1fffee63c0d9ed58134c86612c5303278ee44ee572f1b51fb241c4161950
			cdb18d7aba30ba51777db7438aaddba8467d729fb8bc62fe4d4756719b88
			f31537c599031d7dc4228ca1be53a0348b526756e968317b6c462ee58bd7
			ae0fdafc9da228bad338d5837a6e61795bac01146ad956135c35ae308b96
			0db623ae0679c16bf2018431ccf4a14c9766575ddd63bb8419440998f14d
			caeb3d905ca1b00b5e4ab3e06687f1d52e04338002baaa087630f0d8e38c
			4ab36b15e61a76757782194001adb598ea2910e79b0a5e5c2885dc58ac41
			e97698e19ea640a06c526fbc64065174cd604a9830515038b61fc199cbe5
			86000da268d4a34a38af11400338832894abbaaef88e61536da7321e8502
			81b2b5739c41948ee90e54182cdd0ed46e348a8e4ed80eb5378292e62ff5
			a3e03d4e80f112608c386c5e4a0fdb8d5c711944e87c171b7b40771d6a2a
			789dadab4cc12c510f23e062284cdcc3f45447c17b1b074e0f1c79bcc51d
			86824b1211eb8e8146a068cc6aee8299e81a952230b83ac5c003ef3fddd3
			e37811dec86ea733800296009646b3035e762ee0384adfeed9234a200205
			8d94100c0885ba2519de3be22965e165dbdd08bcf8b0037b5617f6cdce24
			1347e14dbe078c7e143115cf511cd7f66cd536760ad4b74680202c261aff
			6221b7375ec0cf6b44d7a71796a11d10f7a7fbce4b44efcf26878a31175e
			edde5c5e5852ae9dbfba8037ad69c4870acd86598a9a4bd7af2e14efd0d5
			3a912e92cc7c06269d2f16d399997bdd8eeb9934b9e7888bf4995367d633
			8177283c60ed0e5e3efa7815117640bc75bcb0c44f3a2cdf30d0873ea8a4
			4b6a30edd24bb6ec3cdd3222e1323ee5323ee9d24dbb6c9f7819937a199f
			7c491d58fa6540c6a49b7689265ef06dd7e996be848b80d86ba2a5970409
			5899647a65448225b5cff44a34c11230bdabb44a3cb122fa4f289f329851
			09983bd85c4aeac0b2294374b89b4589e551063229fdb99421d99418df13
			be964fc52fe63be620c88b64d7740bd632ab61916111890796f9d97c5e5e
			c34fe8e44e03597cccd5eb10bc0bb9c06ca0e71289dafbf9e84baf57d778
			8706a62743c776b4b8cdd76c8b7532088c5a7b4dd8c7682a961498142aea
			077ea452c5cfaf9b910f3c7ac5ddef347a45e16b05149ca0c385fe964c24
			afe9807182a502af9d948e8113b1c654a23ae2ceb5231d726f9d94ce743f
			b4c805725ab87e714237398037d10f6201efac092239070f84dcea6ae46d
			f14ec80561a8c8656addd5038b7bebe762e3735267cddb4fdc5a46432e9e
			a573b79e67569dd67df912157f45f1c439fea1ff6f414209259450420925
			94504209259450420925945042092594504209259450420925945042ff3b
			fa2f690e385200500000
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
	mount -r -o loop ./ubuntu-${LIVE_VNUM}-desktop-amd64.iso ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ]; then
		mv ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -r -o loop ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# -----------------------------------------------------------------------------
	cp -p ubuntu-setup.sh ./ubuntu-live/fsimg/root
	chmod u+x ./ubuntu-live/fsimg/root/ubuntu-setup.sh
	LANG=C chroot ./ubuntu-live/fsimg /bin/bash /root/ubuntu-setup.sh
	rm -f ./ubuntu-live/fsimg/root/ubuntu-setup.sh
# -----------------------------------------------------------------------------
	rm -rf ./ubuntu-live/fsimg/tmp/* ./ubuntu-live/fsimg/root/.bash_history ./ubuntu-live/fsimg/root/.viminfo ./ubuntu-live/fsimg/var/cache/apt/*.bin ./ubuntu-live/fsimg/var/cache/apt/archives/*.deb
# -- file compress ------------------------------------------------------------
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs -comp xz -wildcards -e *.orig
	ls -lht ./ubuntu-live/cdimg/casper/
# -----------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/isolinux/menu.cfg.orig ]; then
		chmod +w ./ubuntu-live/cdimg/isolinux/menu.cfg
		sed -i.orig ./ubuntu-live/cdimg/isolinux/menu.cfg                                                 \
		    -e 's/locales=ja_JP\.UTF-8/& timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	fi
# -- make iso image -----------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
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
	ls -lht
# =============================================================================
