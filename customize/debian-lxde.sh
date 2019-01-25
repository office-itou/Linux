#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [debian-live-9.7.0-amd64-lxde.iso]                      *
# *****************************************************************************
	LIVE_VNUM="9.7.0"
	LIVE_ARCH="amd64"
	LIVE_FILE="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso"
	LIVE_DEST="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde-custom.iso"
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
#	rm -rf   ./debian-live
	rm -rf   ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	# -------------------------------------------------------------------------
	#	tar -cz ./debian-setup.sh | xxd -ps
	if [ ! -f ./debian-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b08004cce4a5c0003ed5afb731bc51dcfafd65fb1959dc809399da438
			6931b1874c30e0e659db6981283d56772be9e2bbdde3f64eb62061c6f694
			42a1e5316d9852a633ccf02a3440a753a6940efc31420efd2ffafdeee9e4
			d32b7e29433b735f8fa5bb7d7cf6bbdfe73e94d72d56b129d7240b422f2f
			eb47c64f05a01fcfcca86fa0beefd2e9d299e291e2a99952e9f4cc4ce9d4
			99238562e9cc4cf108293c005e06289401f50939e20b11dcafdd6ef5ffa7
			34f923bd6273bd42653d3349b4715266026c8a68ee448726496bf39fadad
			8f5a5b77da2f7fd9fee6bdd6e65bdbefbed2fecd57ad8d4f5b1b7f6c6dbe
			dae9c2c2649faf5a5b2fb5b6fedddafc169e0bdf7dfd41fbfd3bad8d8fb7
			dffda4fdd93bf7bef94bfbfd57b6fff0456be3b3f6eb9bf77ef5516be3a3
			7bffd8fcee5f2f6526985917247b62bc948d719fb568c0c843d9a34feb47
			5dfda8458e3e397bf4d2ecd1e5ecb36496a05905e4fa54e146f68131820a
			2301f35d9b232b875658959b0bdc9a3e4e5e8859d6c63a8006a2585a5831
			965796e7a68a99cc44dd9681f09b44333393133a0b4cdde67690b774ab12
			4a10a1f0a03c7445c8030281aaa17b8124b76e914e915675bac5bd0d09d2
			60c34423d994c31a4171a291e70b7348232ccefcb0e6c5b8f5808d6b82ad
			db01997aa1a3b0db99db91bda1866cead8cf1fda1e9246363e5434b2c0a7
			1ec945e64c8a39522425728a144fe3a43c017e7975b938979d36eb18d58f
			13f0a4898e7a0312eb7ce721d277a209184955594ff7a16337dd16606b81
			eb415dd7183be6976c81c64c76ec3a61c9435c01a249247f4798e391538f
			fcc7878af297cc229a4dd4341432cbd718270354ce4ce097c6484eeabfbc
			7e4e7b866acfdfd027c931bd96bb4fd349529ebe498d9f5ecd5f5b795cfb
			09519fe5e37ab988fd069a326e5c5b1ed634331171a701779989d04397d3
			a22272f1dce527e61283805a92d35ab76abab32e9994b6e0fac5a71e5bd0
			69188828ecf7b33ed965688a3e0a296e7db5e282856a0e6d8a302037e151
			7801001133f09d59b9463d934a968b34ee0a2b04866c0ee08e73180d2535
			3e3e542ddb954d5ef8762d1290cfa4701a7953f06a67e69cba4c32bfc17c
			52ccabbf32ef292bc05f31d76b3ed40b742942df6432ef40ba008f80c50a
			53cfb1e194a761114bf227945a09175cabfa8c11183af0ed8ad233c09048
			bf1da568cf0d9ae3ee74ec185a570456f3a9c5ba605af31060d5d071b418
			f1b060b1460fc119e9fa5b40e5aa6631b90ab9387ab9493dca4167bd6fbd
			6d1ce0039e878239eb565f6bcfb779a075ac40954859ef795f6395f8bd0b
			06039b7556826fe85b176b1ad4a22f4a2cb18310245931092c6ead87a3cf
			30b01d39629a95d0762c0d9c99714c430433836b876ef741738a05f04ebb
			2ab508c774a84b1bf02584d7298ac1ccd07788e5add6349f0193aba46a41
			330ebe06a15c73c5f326e8c88291882d4dcdaa9b5e3c391b5cc6e6e17a82
			33c7aee00c11cd63808bef6150675cf3a8db2d624e55c34c038fb6d0bca0
			19d5f44f13aa3903714987d166dc19c6d3ea0c2ccf971a75ad3333c469b8
			25020dd784bfaab9e0b73525f83e300eb23085eb42d4c2c755e673e6c433
			e141e46cc2034e1bae16083128fc04584fbbae79280e7dd9e42691d4ad50
			22dd8ae9d8283af95c087b1618374296a1257aec4c3287346415d820ebc2
			f741b2fb32ff1d77c2a8ee335734d0d70feb9b086682f0552e3c2c5817e8
			e060b0b005b078a184eb93c640f41e1ed3a3d4846a230d97444a384c0e49
			a6a6f1a1e262c45db56c9f681ed15d1ee8f55a5576c6d238c9e5eb90b267
			f59d3a88c5905d1a2e3e6bf84c20968a354380cff927517f46c8d52aeea4
			c5aa347460e5562005b5ea989f8fc45485005c8904d40913879a432c20bb
			4aaec306241a2302d621d1c93a3e4789f6c623046343662221cdf1b180d2
			ec49cec3990049249775974560579be7a1dad2278fe9908cab76241c08f3
			d678ce1cfa8403c0f86f19c80f18ef30b18c6ff001b1f40f3f92fa24559e
			be8a7bed600976251745cde6e5e3b0aac1354d93493d37b2e32474a45242
			b8b6cea9dc10d826c5e5e460ffc18e6ac4051772468c21bbddb8e88e3ad0
			f19a6457cf5d1ac9e15056f527c1db2eb02629a39cca2824f561a0171acc
			b42435565953b772fbeb68954e9f2e3e1c774d769ca2c0e7639797612a65
			be58e310caa1c0bfc0c51a474c0915098b54f9622c36d16791512a1aeda4
			e31b5859632042b3de0946810751cc97d1795a6f5d82abfbd4aa5db2810b
			6e3c908b5e5b9b6f7dfff1dfdaaf7f1e1ddcb5b63e5447745fe2e7c667ad
			ad4fd4b9ddcb4301919d0e1ce06dffee837b5fbeb3fdea5bed373e3c0058
			8572ce2c83b9149660c3f1fef3a7afdb77df686dbd87785b9fb6b6be6e6d
			bda9203f5725afec3a884237bcd83f6094f66bdfb6dff86d6beb6e6bf38b
			d6e6fbadadbfdffbfdc780b3dfb1c678e60a68661d7675a470a650e8d5fd
			1097542e32609abb36dab185d18dbafabd1f528fde4635ea93fbd8e5950c
			da5d59f5463a9caf3a90c83dd0d1472861171ac81f287506617f2e7f620a
			a2f2dce52bc383f25e500cdb6b9cd9817a7a61f9be5803281436e24d5829
			4983715a71d89eb81ae4054f6306107661a60f05b2d59a6f076c9f308328
			1133a10bfb8b1d9042a9b40f5ecad3b01a7561a7099baa7d086600056cd5
			50ec04b67bd01995a7d7abb0c312b5fd09660005ac96333330aab05736f0
			7cd5281576c51a946ecc8c0c2ca32a7c9706bb4b6610c5b61c6674cee50c
			148e081338a70a8521408328b079a546675e238006700651a8346ddb083d
			47506baf321e8562c18a65ef38832871e88e4c1822dd1ecc6e348a8dcbae
			3d5a6f02252b5fec47a9da31c68b803122d9bc981de68dd2f09919fa721f
			8e3d60bb1e750d3cb3b04d66e061e40e46c4c55098de1566607ac69a4f3d
			0fb2078ebc7bc41d86822a498875cf4023502cc69bfb6026a9a3720206b5
			3317adb9fbb37b76375ed46a64bfd31940814800aab144c4cbde05dc8bd2
			e73d07448944606090528201a150bfacc37b2c9e721e5eeeeb8dc04b081e
			b81375c16ff626995e14d99407c0e8475153093cc3f345204ce1ec15a84f
			4780a0222606ffb952e160bcc03aaf91d44fe2a0c0ad8c69e5d57f5080a7
			8a3ac08fde99752b0f3fb8da99311978d477892687b2708ba86521ee796b
			8ea850472760bc12b65dd4c71f47cc91f3571f3e552af3ce39a8ed99c4b5
			398915080d2eaf14bbd5c3aa3a47b4c3aa6c0befa53ac71627c82cf129af
			31a82d160a050d3f0a659e23f35da9f4cda83b8df9619383c6d8ac9ae81d
			6b18233da1dc22185e7200c482c0e6b503083d7990383e54d41d4422b272
			6ee989851502a2cb46135c654e169e71246862099823ec23ea16997a216a
			7b1b658157bb3c741cdce474d9d3481e7f77e39b6332ad099306e4ec598d
			e48c852b2b06a8693e1e2113fd9806c7dc7efb83ed77fffafd277fdebef3
			ebf6ddb7dbafdd696dbcd9fefc9b7b77ef10253e0524210fc00c16962edd
			cec26ce3cd19c9aafb822c394e3a37e9ea9af4fc238f745b9c80ba21d469
			c1248d99e9003cb172c158bc645cbaf2d8b58b0b737845d25bff14d42c3e
			beb8b0b43cf7a8ed0e69f0b395fefe6afafda26ed8ee58243d42d49d0114
			6be8a73c742b3db726283c7215afba30c6e0bd0b8b1b8135c1d2192a4495
			30489baa32df850a68057f0a3337d3037539ea0b5da4474d26011578a2e4
			ec0aadcc23248e82590adc39e4812460be3b9889ed7902f3229642d266b3
			64b92ed6d4c8844a727e65e9a2b6486c492c5b7a0e6d32eb64fc48a608c4
			7fe0047f9202dcf4f28ee3a8d0350758b3f34634ce720072a801cb023d13
			99cd61c39c1a5b392cfa1a4ee0d62c56dc2278d104e53bc05ce092ab7f02
			2b75e031be4aaf63ec92444d84ad073decef00e1dda11ab60768b18a5c2d
			62ac0c4e922506bd4c4680a99fdb12d277c4a817a2c03b9b392222913b54
			06fd42802219d0209473a524af8c34a81332945a9060dce65528e5a8d335
			c8463ba86b3687750c7c390ea9d306488a44b0913551678d36657eb8f9e3
			a5e4038c34f1006aceb8c7c099a8174831351f44a455a8af0af0322d601a
			eea82209e1e52df37de17739f78467f5864d4b7016dfa830ca0f18c47b29
			d37349322e549529a20bb542c4f1c295c7c7b57a992463fd9517e09d7541
			1df3f040c875dbd5a2d47f43bd13725eb910b940f94d3b8a0bd77fa16c50
			9255d6bcf1d0f5650c3dea599bbffe0ce3ab7435d49fa4ea5b158f9de31f
			fa07b329a594524a29a594524a29a594524a29a594524a29a594524a29a5
			94524a29a594524a29a594524a29a5f43f44ff052b9b03a000500000
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "https://ftp.yz.yamagata-u.ac.jp/pub/linux/debian-cd/current-live/${LIVE_ARCH}/iso-hybrid/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./${LIVE_FILE} ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./debian-live/media
	# -------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/live/filesystem.squashfs.orig ]; then
		mv ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/filesystem.squashfs
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./debian-live/filesystem.squashfs ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./debian-live/media
# =============================================================================
	if [ -d ./debian-live/rpack.${LIVE_ARCH} ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		cp -p ./debian-live/rpack.${LIVE_ARCH}/*.deb ./debian-live/fsimg/var/cache/apt/archives/
	fi
# =============================================================================
	rm -f ./debian-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./debian-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./debian-live/fsimg/dev
	mount --bind /dev/pts ./debian-live/fsimg/dev/pts
	mount --bind /proc    ./debian-live/fsimg/proc
#	mount --bind /sys     ./debian-live/fsimg/sys
	# -------------------------------------------------------------------------
	cp -p ./debian-setup.sh ./debian-live/fsimg/root
	LANG=C chroot ./debian-live/fsimg /bin/bash /root/debian-setup.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
#	umount ./debian-live/fsimg/sys     || umount -lf ./debian-live/fsimg/sys
	umount ./debian-live/fsimg/proc    || umount -lf ./debian-live/fsimg/proc
	umount ./debian-live/fsimg/dev/pts || umount -lf ./debian-live/fsimg/dev/pts
	umount ./debian-live/fsimg/dev     || umount -lf ./debian-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	find   ./debian-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./debian-live/fsimg/root/.bash_history           \
	       ./debian-live/fsimg/root/.viminfo                \
	       ./debian-live/fsimg/tmp/*                        \
	       ./debian-live/fsimg/var/cache/apt/*.bin          \
	       ./debian-live/fsimg/var/cache/apt/archives/*.deb \
	       ./debian-live/fsimg/root/debian-setup.sh
# =============================================================================
	sed -i ./debian-live/cdimg/boot/grub/grub.cfg                                   \
	    -e 's/\(linux .* components\) \("${loopback}"$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                 \
	    -e 's/\(APPEND .* components$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/'
	# -------------------------------------------------------------------------
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs
	ls -lht ./debian-live/cdimg/live/
	# -------------------------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		xorriso                                     \
		    -as mkisofs                             \
		    -iso-level 3                            \
		    -full-iso9660-filenames                 \
		    -volid "${LIVE_VOLID}"                  \
		    -eltorito-boot                          \
		        isolinux/isolinux.bin               \
		        -no-emul-boot                       \
		        -boot-load-size 4                   \
		        -boot-info-table                    \
		        -eltorito-catalog isolinux/boot.cat \
		    -eltorito-alt-boot                      \
		        -e boot/grub/efi.img                \
		        -no-emul-boot                       \
		    -output ../../${LIVE_DEST}              \
		    .
	popd > /dev/null
	ls -lht debian*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
