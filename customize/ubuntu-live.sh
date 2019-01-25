#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu-18.10-desktop-amd64.iso]                        *
# *****************************************************************************
	LIVE_VNUM="18.10"
	LIVE_ARCH="amd64"
	LIVE_FILE="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}.iso"
	LIVE_DEST="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}-custom.iso"
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt -y install debootstrap squashfs-tools xorriso isolinux
# == initial processing =======================================================
#	rm -rf   ./ubuntu-live
	rm -rf   ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
	# -------------------------------------------------------------------------
	#	tar -cz ./ubuntu-setup.sh | xxd -ps
	if [ ! -f ./ubuntu-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b08004c7f4a5c0003ed5b7b931bc511f7bf779f62a23bfb6ce3d54ae7
			0770f85cb9328771fcccdd39012c6759ed8ea4b17667969dddbb931f54f9
			ae422090f0a8c45408952aaa20108881542a540829f830e2cee45ba47b76
			575a492bdf6b0d9594dab6b43b8fdff474f774cf4ccb453dac863c083549
			83d02bcac6befca904f4e8b163ea1ba8effb68f9f88963fbca478f4d4f1f
			7bf4d1e3a513fb4ae5e9478f97f791d243e065804219983e21fb7c218207
			b5dbaafe7f94267ea45719d7aba66c8c4f102d4f1a1f039b229a3b16d304
			69affdb3bdfe617bfdeec6cb5f6c7cfd5e7bedadcd775fd9f8f597ed3b9f
			b4effca1bdf66adc8586e93e5fb6d75f6aafffbbbdf60d3c97befdea838d
			f7efb6ef7cb4f9eec71b9fbe73ffebbf6cbcffcae6ef3f6fdff974e3f5b5
			fbbffcb07de7c3fbff58fbf65f2f8d8f51ab2148e170be5448709fb7cd80
			92470afb9fd5f7bbfa7e9bec7f7a66ff8599fd8b85e7c90c41b30ac8d5c9
			d2b5c2436304154602eabb8c232b7b56588d5bf3dc3e7888dc4c58d6721d
			4003512ccc2f198b4b8bb393e5f1f1b1069381f05b44b3c627c6741a583a
			e32c28daba5d0d25885078501eba023c14d16dbaac7b8124b76e91b848ab
			399de2de860469b061aa916cc9ac46509c6ae4f9c2ca6884c5e33fac7951
			6e3f64e31aa3ab2c2093376385dd1ebf1dd91b6a88990ebbb1677b481b59
			7ea86864816f7a642a3267529e2265324d8e92f2719c9427605d5e5e2ccf
			160e5a0df4ea8708aca4b158bd014974de7d88f49d6a02465253d6d37988
			eda6d3026c2d703da8eb18636c7ee91668cca46bd7294bce580ae04d22f9
			3bc2ca474e3df2cf0f5543693a9c68b246f450faba6c983ed56f084e19af
			097d4e32535f12cd96206a9a6ae480b914bbe133b50287401cd0a237727e
			eee299d9c275d3f8c9e56218d41e2ba8922b7367e6b17486f2c240cfd572
			596bd2960b5650b8ee15f0a35c3a01dff0b7e3ce66acc0770c18dba836a5
			0756138f778b6c4995f131a57e6a43b0225352af1c449e2a87664feb95f2
			6cc4eb95a5a7b4c7f4a9a43152ba314e003a4c461d601ad0940c362e9c2e
			e88514604135ebb0712a25445ab404af610c05b6584f459df2a1b388c6f9
			c5d539ed3953bb714d9f2007f4fad4039a4e90cac11447447d560ec144b0
			df4053ca8d2b8b594d13896bc0ddf858e8a1c3eb517a6a90c8f65d618750
			c938ac07c7d98bada66d3f3f5465fb91f88bc267f548073e95c25956ca51
			629934b9e95249fd65ea937251fda9f09eb212fc294ff5aad2f4025d8ad0
			b7a82c3a103813c5550edab44a8a87955849c81940484adc1056957a54a2
			86de241271625e2f6c6de78374e0002a3802abfba64d3b605a6b0f60b5d0
			71b40471af608922f7c019e998bce99956834e93aa4560a36c3f1e7d8601
			7324a986ccb1352a25e518bc08c6139785ae56f5c50ae87200acbf81e694
			4b9c58ac26b508d1724cd75c2656e83bc4f69a75cda7307e3393b31af369
			4dacc62b46bb6e929ae081d4b80884665d6f6a7415e220a973e1e2120b02
			c6eb9a0a24d4d66c6149ec928045ad42e429a96ab4bc06e5303dc2200469
			aeb86181686d982b61d2d2ec86e569b1c1f671c6c0de190f578963f27a68
			d6a98693d0a2310039bb588343081d9c666fe381de493f875541f71acacc
			a3203d78a74e4d4bc26f02c6aa4c685ed0ea34e2102ea474a8d92df2a9a8
			d59845b506753c25a46cd3483745452ae696dd69e2b68206952839405f11
			7e537361c9d741501c346d09d715bc1f0c6b9ad4e7d44984ca8368b90a0f
			b4b0ec6a811060213d6f303dd9845d723f183692b29120a989f9b2c52d22
			4db76a12e9562d87a126e50b211cfd60ec085d86b62081299b923a0958d0
			0841eb7e95f976cad696650df8dbe65aeaae4d33840d3f75c5326a7aaf0b
			1dc12c509d12e65ec13a40bb078363028025db4edced2d0f4480ecb81085
			379bd64cf0da0497e194c49d0caed9dd04a47478cb0f552ba4718b7869e0
			5b795c1a00ae6506e4e4498d18f397960c722aded7c82675f478a071bc0e
			c08137dffe60f3ddbf7ef7f19f36effe6ae3dedb1bafdd6ddf7973e3b3af
			efdfbb4bd4dc010c3c42a1327973697ee1c2ed02b82d28440d15945f2a90
			43243e08a87dc6e9279e88eb0f434d06a97a2a4de421ee7866e99c71f682
			71e1d29357cecfcfa287ecd63d03a5679f3a3bbfb038fb63e6f655fe74a9
			bf9f9a728f6497999b8f6033249b16ac1a0758c35b171ebad574c852e222
			977d065e02dc19783b4e93468c939a0fc186881aa1101f556531060acc2a
			9edc678ff5005d8c7a4207097e1b5c63d000be4c7272c9ac9e42401ca3c6
			601f66e111494230f31344b5db21fdac9dc752d8bbd119b2d8102b6a5c62
			4a727a69e1bc76168210b199f41cb345ed23c9239924660d4e00eafc0cbc
			a4f9c6512c38abc859409aa99c32d4288b0148a00eec0a5c40c8e814369c
			52231313608051c5fcad19acb845d0bf437902cbc50a9e46fb985f6a30f4
			e50183480083f23a48444d0282760feb098c845a35640fccd91a727496c3
			d20e8e90050a7d2c88183ef9199321ec48540f2f4441c3ee52420c222212
			b563caa077fa5000bb832094b3d3693e2959369d90a2b48214d370968352
			8e9a5c816d42177305f608309115063bb086097ede24116c6441a6b362b6
			6431c3e871d3f3b0dc49dae8a37160d618cc702ef00827fc3ab863097b09
			1f5e3142c159449d4a413a207a8dfabef063ae95b3c6184b965d1205cebd
			b09b96427ea82805b769339f681ed15d1ee88d7a4dc6636960c6c58690c1
			8cdead835db8a4c565179f357c06653962c510a05bff08065b23e4ea02e3
			481c53242991d25422de1ae8b90afd57e0bcafc146c373687c65e46a18e4
			d8ee824e8fa826d27746b9c1aa735b0a0edc9bc582d588fb784fbee73150
			d1ac46ae12ad16c92b02d66b60780d7c8e4e88d79ec0b58446d99d697e2c
			a055f49c2ab399a8c4f1303e625e1401abb54e43b5ad4f1cd0e138596391
			70609769e79336e8130e00e33fdb8875922596fc061f104bfff043a94f52
			958397f17e29581022382fea8c570ec1d11c0fe62d2af5a9a11d27a0a329
			251c16ecb910271ab0c8390df61feca8469c77e1589360c8ac61073a5e91
			f4f2dc85a11c66b2aa3f0d5ee31c6d910acaa98242521f067a13835ab634
			8d266de9f6d4ce3adad3c78f971f4fbaa63b4e9ac0e7931717219256f859
			382dfa140afc7310583962c2294ba42c521d4b72b1893e8b8c4e3cc31769
			7e032b6b0c44081babc8b1061e6ede659412ebad4b71f5805a75d16de0fe
			0437d1d16b7bedadef3efadbc6eb9f45b9b7f6fa9f5596ed0bfcbcf3697b
			fd63957a7b391310d989e1006ff3b71fdcffe29dcd57dfda78e3cfbb00ab
			9a9c53dba0aec91c998df79f3f7eb571ef8df6fa7b88b7fe497bfdabf6fa
			9b0af23355f2ca96832874c34bd6078cb2f1da371b6ffca6bd7eafbdf679
			7bedfdf6fadfefffee23c0d9e95839a64df1e8d2803d1b299d28957a759f
			b124d5121930cd2d1b756d6178a38e7e1f84d4a3b7618dfae49ebbbcd24e
			bb23ab5e4f87f355b7da530f75f4214ad88206e2074a9d82db9f2d1e56b9
			818b97b29df276500ce62d9fe8423d3bbff840ac0114930bde821d9f3428
			37ab0edd165783bce0a5d100c216ccf4a140b45af1594077083388123113
			baa66c76414ad3d33be0a5721076d5f1716a07821940015b353ad9af5dce
			a87270b5467d47d47726980114b05a4eadc08063bd6be03d85315dda126b
			50ba093332b00d3817bb66b0b564065198ed5043828061ff63a0704498c2
			395a2a65000da2d866601af1bc86000de00ca298d262cc083d4798f67665
			3c0c05cec57cfb38832889eb8e4c183cdd36cc6e380ac36dd736ad378552
			902ff6a3e0b54d84f122600c09362f16b256a3347c0a0772b983853d60bb
			9ee91a78d3cd2c6a6016ad8b11719109d3bbc30c2ccfc06b1a0fa2078ebc
			b5c7cd424195a4c4ba6da0212836e5ad1d3093d651250583da998df6dcfd
			d1bdb0152f6a37b2d3e90ca0802700d5d822e265fb02ee45e95b3dbb4489
			4460a093528201a1987e4587f7443c9522bc3c7035022f21acc0aed78575
			b33dc9f4a2c896dc05463f8a9a4ae0199e2f02610967bb407d3a0204e531
			d1f9cf4e9776c70becf396d3fa495d14b8d59c765efd170598d1d2017ef8
			c9ac53b9f7c1d5c98ccac0337d97683293855b9d1f86e80d01fb049d305b
			48a2ee96694066c9e9cb8f1f9daef03805c73c8bb88c93447fd0e0e252b9
			539d5515e7f5b2aa988dbf7a896f2d0e9319e2e3e532d4964ba592861fa5
			0ac72bbb84ddbe097566712a6b6e7837eaa2e8bb058982d1d1abfbf03de7
			99d2f7a1f9a1a2eaf0aa7e696ee1ccfc125e9b173a97c20578c691a0892d
			f03a38c49ba5c99b51dbdb280bfc71160f1d07cf381df6f24c82a16575ae
			ada7d445f314e6c1bad9afede7bf920c586f026ceb14d8d649b04e1a0c99
			79502a2c559f9d0e4b35189a12eb15756e59b16c51934e3a2cc784d8c348
			897d5f49b1acb498ca8aed352d965b62ec7b488dfd90c9b15ef3cf2d3f36
			ccfc3b89b19ed4d84072ac3f3d9691204b739e779a66ac375193789328d5
			555c651c745ab4b148fd08358a62cf94cbfa2afea0564f1ae8eac785dd0e
			d1bb920ccc067a2e80ffbfb238bf605c9cbb307f7b26fdd2edd5f1ffb173
			eacad0139edd1b376cc1699251a226dfed6f307a68bc27499417aa0a95d1
			af584a11c7f3979eca6bf7364172fda13ae09d74c11e4fc10321573bb671
			4dbd13725af91072cee4d759e418affe5c2d42499ab475ed91ab8be87bd5
			b376eaea739437cd66a83f6daa6f559c3bc73ff4fff919d1884634a2118d
			6844231ad1884634a2118d6844231ad1884634a2118d6844231ad1ff2ffd
			170ff7247e00500000
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "https://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${LIVE_VNUM}/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./${LIVE_FILE} ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./ubuntu-live/media
	# -------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ]; then
		mv ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/filesystem.squashfs
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./ubuntu-live/filesystem.squashfs ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# =============================================================================
	if [ -d ./ubuntu-live/rpack.${LIVE_ARCH} ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		cp -p ./ubuntu-live/rpack.${LIVE_ARCH}/*.deb ./ubuntu-live/fsimg/var/cache/apt/archives/
	fi
# =============================================================================
	rm -f ./ubuntu-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./ubuntu-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./ubuntu-live/fsimg/dev
	mount --bind /dev/pts ./ubuntu-live/fsimg/dev/pts
	mount --bind /proc    ./ubuntu-live/fsimg/proc
#	mount --bind /sys     ./ubuntu-live/fsimg/sys
	# -------------------------------------------------------------------------
	cp -p ./ubuntu-setup.sh ./ubuntu-live/fsimg/root
	LANG=C chroot ./ubuntu-live/fsimg /bin/bash /root/ubuntu-setup.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
#	umount ./ubuntu-live/fsimg/sys     || umount -lf ./ubuntu-live/fsimg/sys
	umount ./ubuntu-live/fsimg/proc    || umount -lf ./ubuntu-live/fsimg/proc
	umount ./ubuntu-live/fsimg/dev/pts || umount -lf ./ubuntu-live/fsimg/dev/pts
	umount ./ubuntu-live/fsimg/dev     || umount -lf ./ubuntu-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	find   ./ubuntu-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./ubuntu-live/fsimg/root/.bash_history           \
	       ./ubuntu-live/fsimg/root/.viminfo                \
	       ./ubuntu-live/fsimg/tmp/*                        \
	       ./ubuntu-live/fsimg/var/cache/apt/*.bin          \
	       ./ubuntu-live/fsimg/var/cache/apt/archives/*.deb \
	       ./ubuntu-live/fsimg/root/ubuntu-setup.sh
# =============================================================================
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs
	ls -lht ./ubuntu-live/cdimg/casper/
	# -------------------------------------------------------------------------
	chmod +w ./ubuntu-live/cdimg/isolinux/txt.cfg
	sed -i ./ubuntu-live/cdimg/isolinux/txt.cfg                                                                      \
	    -e 's/\(append .*\)/\1 locales=ja_JP\.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	# -------------------------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
		find . -type f -exec md5sum {} \; > ../md5sum.txt
		mv ../md5sum.txt .
		xorriso -as mkisofs                                           \
		        -D -R -U -V "${LIVE_VOLID}"                           \
		        -o ../../${LIVE_DEST}                                 \
		        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin         \
		        -b isolinux/isolinux.bin                              \
		        -c isolinux/boot.cat                                  \
		        -no-emul-boot                                         \
		        -boot-load-size 4                                     \
		        -boot-info-table                                      \
		        -iso-level 4                                          \
		        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
		        .
	popd > /dev/null
	ls -lh ubuntu*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
