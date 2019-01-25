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
			1f8b0800868b4a5c0003ed5b7b731cc511f7bfd2a7989c649f6cbcb777f2
			23202c575c4618c7cf587212f039cbdcee9c6e7dbb33cbceee49e7075596
			2a0402098f4aa042a85451c52b1003a954a81052f0618e93c9b748f7ecee
			69f71ed66b0d95aa6b40dadd99f94d4f774ff7f4b428e916abd9946b9205
			a157928d7df95319e8c7478faadf407dbf8f54ca478fefab1c393a3b7bac
			7cecd8d1cabe7265f6f89123fb48f921f03240a10ca84fc83e5f88e041fd
			b66aff3fa5a91fe9359beb352a1b935344cb932627c0a688e64ec434453a
			6bffeaac7fd8597fb3fbe217ddafdfedacbdb1f1ce4bdddf7ed9b9fb49e7
			ee9f3a6b2fc74358981ef36567fd85cefa7f3a6bdfc073f9dbafdeefbef7
			66e7ee471bef7cdcfdf4edfb5fffb5fbde4b1b7ffcbc73f7d3eeab6bf77f
			fd61e7ee87f7ffb9f6edbf5f989c60664390c2a17ca990e03e6bd1809147
			0afb9fd6f7bbfa7e8bec7f6a6eff85b9fd8b8567c91c41b30ac8b5e9f2f5
			c2436304154602e6bb364756f6acb03a3717b8357390dc4a58d6729d4003
			515c595832169716e7a72b9393130d5b06c26f13cd9c9c9ad05960ea36b7
			8392a55bb55082088507df4357843c20e0a85aba174872fb36893f6975a7
			f739db91200d764c75926d39ac137c4e75f27c610ee9849f277f58f362dc
			7ac8c635c156ed804cdf8a157667f24e646fa8219b3af6cd3ddb43dac8f2
			4345230b7cea916264cea4522415324b8e90ca315c9427605f5e5eaccc17
			66cc067af5830476d244acde80243adf7c88f49dea02465257d6d37b88ed
			a6d7036c2d703d68eb19636c7ee91e68cc64d3ae53963c642b803789e4ef
			08331f3965e49f1faa86d27438d1649de8a1f475d9a03ed36f0ace6c5e17
			fa2969537d4934db82a865aa9903db65380c9f99193804e28016bd91f3a7
			2e9e992fdca0c64f2f97c2a0fe68417db97aeacc027e9d63bc303072b552
			d19aaced8215146e7805fc51291f87dff06fcf9dcd9981ef1830b7516b4a
			0fac269eef36d992aa93134afdcc8260458a52afce204fd583f3a7f56a65
			3ee2f5ead293daa37a31e98c94ee8c0b8001d3d10058067425839d0ba70b
			7a21055850dd7a6c9c4c0991954cc1eb1843812d3bd3b0ccf8c85544f3fc
			eada29ed19aaddbcae4f9103fa72f1015da7487526c511513fab07612138
			6ea02be3c6d5c5615d13896bc0dde444e8a1c3cb283d354964fbaeb04268
			b439ec07c7d98bada66d3f3f5465fb91f84bc2b797231df84c0aa7a594a3
			c4324d397599647e8bf9a45252ff5479e65b19fea914b3aaa45ea04b11fa
			269325070267a2b8ea0c1ce149e990122b09b90d10921137845da51e95a8
			613489449c98d7735bdbf9201d38800a8ec0967d6ab11e98d6de03583d74
			1c2d41dc2b58a2c83d70467a261f50d9d42c269b7018895e1c98a3f7bc6a
			b16cabe7db3cd062450e0593b291b4abf71556cbbcdfa01ee5600ad9b7de
			2c3d30a7e5ce1268351b6c9698a1ef105fb6b94930aab976e81238d85b8f
			8581ed48c28348f59c052bc26f6a2e98e0b262307165d4ad5122dd9ae9d8
			0c229469d7a5168f852753b8aee0eab1c97cce9c8463195a42312a99d303
			0301d941089aac99c4f29acb9acf80cd26a985b663694c4a9801823df118
			30edd835e8af6137f5de2f3368b785e6056d2de90e8b00213a8cb6fb466c
			ad4d1b82a9e68a9b2669c93ac884980e75698bd8d2d4ac86e925cb428e64
			43ac68b8816cc125a95ba603212ccb190f57b506039bf5a5465debf85164
			8f39750da33e2e2c0c1a8c6b1e75234e5785efdb52c074420d4e8101baf0
			6289cbe742c8c740d68110f02a3cc068b9c3de525691e62c3101cda99479
			6407b02b2c54ec7669733bc12284cf5cd1c2c5ef756f229809aa53e168af
			603da0dd83c1c91ec09293221ed05a034e7bb82b8f2292c5ea141c2d09c1
			708a120f1f81cd97771343d211293f54ad90c62d619eef9b79e4f9806bd2
			809c38a11163e1d292414ec64711d9648e1e4f3489193c4ebcf1d6fb1bef
			fcedbb8fffb2f1e66fbaf7deeabe0219fcebddcfbebe7fef4da2d60e60e0
			f10ad5e95b4b0b572edc2980b9c247d45041ed94023948e2b3bb3a1a9c7e
			fcf1b8fd10b40c21d5ce24451ee2816796ce19672f18172e3d71f5fcc23c
			ba82cdb65fc2d7b34f9e5db8b238ff13dbed6bfcd952ff38b5e48c645bb6
			9b8f608748362d58350fb08617253c746be928a3c4452e630422e078d041
			b1a493cd49dd17d020ea8441cc508da51828a0354cb6e78f66802e462361
			8004f7cd2460025f949c58a2b593088873d46d383a9998d5808f147e82a8
			0e28a49fb5f3f8158e5b6c8e2c827755f3122ac9e9a52be7b5b3e0168965
			4bcfa16d661d4e1ec934a17538b4ab94177849f38db398905ec879409aab
			9e34d42c8b01486019d815b88190d122762caa990905186054317f7b0e1b
			6e130c6ff03d81e5620513c83ee6971a367adf00c2013858ca9741226a11
			6c35c8b09ec0600051536660ced691a3b31cb67670985c6130c6640418fa
			b92d43088a6a8417a2a0e14028214c131189daa132c82e1f3ec0512708e5
			fc6c9a4f465ad409194a2b48310de9177ce5a8c915084b9b982b101b6021
			2b361c9a1a14fc3c25116c6441d459a16d591a62f478ea7858ee246df4d1
			3cb06acc0e702df00849f932b863a9d5a80faf18a1207d50892448076337
			f37de1c75c2b678da193b45c1205d2bdb09b96427ea82805b769d93ed13c
			a2bb3cd01bcb7519cfa58119971a420673fa661b1c9c252bb55c7cd6f019
			94e5881543806efdc3186c8d90ab3b87c3714c91a44ccac544bc75d0730d
			c6af408aaec119d073587ccbe36a18e4ecdd059d8ca8a6d2d73cb9c1aa54
			2b0507eecdb483d588fbf854b7e73950d1769d5c235a3d925704acd7c1f0
			1af81c2575d71fc7bd8446b9b9d2fc5840abc82482c399a8c6f130ce0a2f
			8ac0aeb74f43b3a54f1dd02103acdb917020ffb0f2b9e9ef130e00e37f96
			11eb649858f29b7c402cfdd38fa43e4955672ee39550704588e0bc58b679
			f52064d3984bb799d48b23074ec1402a25e453d62975ce0fecc8390d8e1f
			1ca8665c7021ad4930646f1817bd5907065e95ecf2a90b23391ccaaafe14
			788d73ac4daa28a72a0a49fd30d09b18ccb424359aacad5bc59d0db4668f
			1dab3c960c4d0f9ca6c0e71317176129557e769943fe001ffc7310583962
			4252295216a932b15c6ca2cf22a3246ff426cd6f62658d8108e1601539d6
			c0c3c3bb8caa58d9b614570f685577d3069e4ff0101dbd76d6def8eea3bf
			775ffd2c2a9775d63f5085b12ff0e7dd4f3beb1fab6ad98b4301919d180e
			f0367efffefd2fdede78f98dee6b1fec02ac46396796c15c0af9ea70bcff
			fef9abeebdd73aebef22defa279df5af3aebaf2bc8cfd49797b69c44a11b
			5eb23f6096ee2bdf745ffb5d67fd5e67edf3ceda7b9df57fdcffc34780b3
			d3b972ac7462ead280331b291f2f97b3ba1fb225d5161930cd2d3b6ddac2
			e84e3dfd3e0829a3b7519dfae49ebbbcd24ebb27abaca7c3f5aa8be8e243
			9d7d8412b6a081f8815267e0f6e74b87d475fec54bc39df276500cdb6b1d
			df847a7a61f181580328940bde86139f3418a735876d8bab415ef0167e00
			610b66fa50205aadf876c076083388123113ba54363741cab3b33be0a53a
			03a7ea389dda81600650c0568d5ec16a972baaceacd699ef88e59d096600
			05ac9633333020ad770dbca73066cb5b620d4a37614606960179b14b83ad
			253388625b0e33240818ce3f060a4784299c23e5f210a041148b06d488d7
			350268006710854ad3b68dd07304b5b62be351289017f3ede30ca224ae3b
			3261f074db30bbd128361ebbb669bd2994827cbe1f05af6d228ce7016344
			b079be306c374ac3679090cb1d6cec01dbf5a86be055bb6d32030b5f9b18
			11174361b227ccc0f40cbca6f1207ae0cc5b7bdc6128a8929458b70d3402
			c562bcbd0366d23aaaa660503bf3d199bb3fba17b6e2459d4676ba9c0114
			f004a01a4b44bc6c5fc05994beddb34b944804063a292518100af5ab3abc
			27e2a996e0e581bb11780961076e7a5dd837db934c1645b6e52e30fa51d4
			5202cff07c11085338db05ead31120288f89ce7f7eb6bc3b5ee09cd74aeb
			277551e0d6723a79f55f1460b15107f8d19959af71ef93abcc8cc9c0a3be
			4b34399485dbbdbfe5d01b02ce093ab12d2189ba5b66019927a72f3f7664
			b6cae3eaa8ed99c4b53949f4071d2e2e557acdc39ae2c2e2b026dbc23f54
			896f2d0e9139e2e3e532b456cae5b2863fca558e577609bb7d0beaade2e4
			b0b5e1dda88ba2dffc9028181dbdba0fdf739d297d1f9a1f2aaa0eafea97
			4e5d39b3b084d7e685dea570019e7126e86209bc0e0ef16669fa56d4f70e
			ca02ff9e8a878e83394e8fbd3c8b606859bd6beba2ba682e621d6cb3fab5
			fdfa575201cb16c0b62e816d5d04eb95c190990795c252edc3cb61a90e23
			4b625951e756151b2e6ad22b87e558107b1825b1efab2836ac2ca6aa627b
			2d8be55618fb1e4a633f64712c6bfeb9d5c746997faf3096298d0d14c7fa
			cb63430a6430467856d66d5a82b3a4a0c228dfed9f206468325323c90b55
			458ae88f38ca11c70b979eccebf0324572fdd36ac03be1823a4ec20321d7
			7a35acebea9d90d36a0b917394dfb023bf70ed17ca062569b2f6f547ae2d
			a2eb51cfdac96bcf30dea4cd507f8aaadfea73ee1cffd0ff97ca98c634a6
			318d694c631ad398c634a6318d694c631ad398c634a6318d694c631ad398
			c634a6edd0ff001c92d88c00500000
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
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs
	ls -lht ./debian-live/cdimg/live/
	# -------------------------------------------------------------------------
	chmod +w ./debian-live/cdimg/isolinux/menu.cfg
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                                                                      \
	    -e 's/\(APPEND .* components$\)/\1 locales=ja_JP\.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	# -------------------------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
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
	ls -lh debian*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
