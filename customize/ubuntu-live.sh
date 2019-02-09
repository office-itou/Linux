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
			1f8b080093ea4a5c0003ed5aff6f1cc515cfaff65ff16a3bb113b2f72d09
			14135b8d8201375f1b3b6d21972e73bb737713efce2c3bb3e71c2448b655
			0a85962f6a834a51252428141aa0aa8a4aa9e08f39cea1ff45dfccde9ef7
			be38fe761142da17e5bc375f3ef3e6f3debc79337bb97c5489b88a2c4955
			14e464fdd0e8a580f2c8c993e62f4adfdfd2a952f1e143c513274ba553a7
			4e164f9e385428961e39f1c821283c005d0624928a8400874221d4fddaed
			54ff0395c91fe52b8ce72b44d6c727c11aa58c8fa14f81e58f7564125aeb
			ff6e6d7cd8dab8d37ef98bf6d7efb5d6dfda7cf795f66fbf6cad7dd25afb
			536bfdd54e171aa5fb7cd9da78a9b5f1dfd6fa37f85cf8f6ab0fdaefdf69
			ad7db4f9eec7ed4fdfb9f7f5dfdaefbfb2f9c7cf5b6b9fb65f5fbff7eb0f
			5b6b1fdefbd7fab7ff79697c8c3a750113c7462b1309eeb32e51141e9a38
			fc74feb09f3fecc2e1a7660f5f983dbc34f12ccc82762b05d7a60ad7271e
			9822da60a068e833ae5539b0c1aadc59e0eecc51782151d91ae900165271
			6561d95e5a5e9a9b2a8e8f8fd59954226c82e58c4f8ee5a972f28c339573
			f36e259248a108b03cf2054628c8bbb4910f94845bb7a0536455bd6e716f
			43d032d830d54836e5b046589c6a1484c219d248178f7fbfee45b9fb809d
			6b8cde640aa65ee818ecf6f8edd8dfb48518f1d8f307f687b4938d0e553b
			990a4900d3b13b43711a8a508213503ca52715085c9797978a7313334e5d
			47f5a3802b69ac635e0589cdb71e627ba79aa093548df7741f3a7ed36d81
			bea6fc00ebbaced871bf740bedccb0e5d7294f1eb214309ac4fc7bc2190d
			4f3dfc8f0e55f32fa90b1603330d834c7335ca6140cae363fa8f45615ae6
			7f75ed8cf50cb19ebf9e9f8423f9daf47d9a4e4279e606b17f7a397775f9
			09ebc7603ecb47f3e5a2ee37d09472fbead2b0a6e363b176166a373e1605
			7ac95971119c3f73f1c9b9d42031fbbe7023ac641c2de27907612bcdfee8
			502dedcb31fd3911b25a6c83904ae135728ee05543cb14e1c4a792860d1a
			423167fe95794f5901ff15a77b4d49029597220a1d2a731e86eec470e519
			97562077ccd00a1167082129f891a7e2474335f68698e28e49ade7063d62
			673972441b3806ab85c4a55d30ab7900b06ae47956827850b0c49007d00c
			ba2e4f02e2d469092a0e60aae63e1a7f468a79122a11f35c8b4a49b90e9f
			a0239acf22dfaa8462156d3900d6dfc0f28a050e0eab4a2b46743ce29306
			3851e8811bacd4ac90e2f82b4335abb29056c5cdce8ab16e10a80aaea4c5
			8512967363c5a2373112438d0b5f2f31a518af59269451d7728523759704
			2c6e15699d92aa7a33a8538ed3038641d0f2c5f30e52ebe25c8149c772eb
			4e60751cb64f3386fece7874133cc26b11a9514b4fc28ac740e4e1c516a6
			c174709abd8d077a27fd3c5641db5b9ab380227bf89d7a552bd900123056
			61c20a54b3db88536549e951b255145251ad32875a75ea0586a4e1ae916e
			aa0d69946bf825f09baa4ea5660ed15745b862f9b8e46b4814474b3bc2f7
			05ef07d3352b34e4d44b48e52a5eae22402b347c4b09811ed2f30da72757
			304feb07d38da4ac27486662a16c720724f12b04a45f713ca62d299f8bf0
			f08163c7e832720528225724f51230558fd0ea6185856ecad71ab28afaed
			722d6dad4d1261ca497dd1d0963ee842d7600e9ace907950b02ed0fec130
			5145b024f1d1f94663600718be2fc4db9b361b347c886d71907d28bdbd8d
			0e552717fe8acb42b002c8fb5ce5ebb5aaec8c657198ced58554b3f9ad3a
			0cec92e61abe7eb6f433606016abb6c005121ed7f6b3236eb2b2e32ead12
			dcb22414a060b288f998a52a86ac0a42ac92905ae8be814763b63ab1f240
			134ad86255b886a78b78c418385f45fbd4f573bc735f7f0c57824e5452d4
			8e4e054d6dcf6e3f5c09a4259db35d148a559b67b1dacd4f1ec9e3365f65
			3139b8faddd15c28f49183c0fabf6b6b7dd09387d132bac10768e91f7e5b
			e963aa3c73591fa4d5153c729c1735c6cb473165d2095393cafcf4b61d27
			b123911283b87b26d21355cc218a8921fd073b9a11177cdc6e120c396cd8
			818e5725bd7ce6c2b61a0e5535ff142ebd73b40965cd535993643e6cbd24
			6deab892d82bb49977a7f7d6d12d9d3a557c34e99aee384550cfc72f2e01
			1765be88bb7848b1203cc7c52ad798b8fb8994479aed62243ed1e791f14e
			b4fd221dddc0c61b95889c7a2734a940674c32be2cebad4b69759f5a7304
			b67536af6fdbe2afadf5b7befbe81fedd73f8b6fe55a1b7f35f76f5fe8cf
			b54f5b1b1f9b4bb99787026a753a7088b7f9fb0fee7df1cee6ab6fb5dff8
			eb3ec02a8473eadad427989a0ec7fbdf9fbf6adf7da3b5f19ec6dbf8a4b5
			f1556be34d03f999297965c7410cba1d24eb034769bff64dfb8ddfb536ee
			b6d63f6fadbfdfdaf8e7bd3f7c84387b1d6b8417aa88e6d4f1980885870b
			855edb0f599266890cb8e68e8db67c61fb465dfbde0fa9c76edb35eae37d
			e47ca5837697abde48a7e76b6e1ba61fe8e8db18610719d83f34eb14c3fe
			5ceed81446e5b98b978607e5dda0d82c683cbc05f5f4c2d27db106500817
			bc896993b42927158fee4aab415d74323f80b083327d28b85bad864cd13d
			c20ca2c4ca443e9e3db6400aa5d21e7429cf606aeae3711c8f5a7b206600
			057dd536ea28e6ef7746e5999b553c7589dade88194041afe5d451763514
			bead2f4fed526147ac41761365a472edaa087da27666661085b91eb52512
			8cf98fadc911510ae744a130046810050fb5c4eecc6b1ba0019c4114221d
			c6ec28f0047177cbf176282e662cbbc71944494277ecc218e976e176dba3
			309d76edd27b532813f2c57e942a4b305e448c6d369b172786ad466987d4
			8942b987853de0bb01f16d7d03c11c6aebdbcd2d8c588ba130bd19a67202
			7b35244180bb871e79e7883b0c459b2445ebae81b64171296fee4199b48d
			ca29186d9db938e7eedfdd2776d2c564237b9dce000a4602348d2b625d76
			4f702f4adfead9274a4c81ad83942106492161398fdf137aca39fc72dfd5
			88ba44b802b7a22eae9bdd31d38b229b721f18fd28662a2ab0835028e108
			6fb7407d364204133175f09f2b15f6a70be6798db47d5217057e65449957
			ff4581be69cc23fcf627b36ee5c1073727332a5540421f2c3954855b60d2
			427de6ad79a242bc3ca0f34a3c769150fff2610ece5e7ef444a9cc3b77a3
			2c70c0671c120362838bcbc56ef5b0aace85ebb02ae6fa2480ceb5c53198
			8590f01ac5da62a150b0f447a1cca761becb4adf8cbad3981f36396cac9b
			5553bd130beb480f84bba0c3cb3402c5af02f6417afa567174a8da761889
			60f9cc9527179601a99b8827b842bd097cd623611357e01cf11c517761ea
			85b8ed6dcd857e6fcb23cfd3879cae7a16e4f48f6a426744ae35e61005a7
			4f5b306d2f5c5ab6d14cf3c908e3f12f65f4989b6f7fb0f9eedfbffbf82f
			9b777ed3befb76fbb53badb537db9f7d7defee1d30f4192089fb00ce60e1
			ca85db1338dbe4700613e69dc9041c85ce6b72f30ef4ec638f755b1cc3ba
			21d26941254994e9003cb97cce5ebc605fb8f4f8d5f30b73fa2d4e6ffd2f
			b166f189c5852b4b733f61fe90063f5beeef6fa6df4f7583f923617a1baa
			3b0318d5f43ae5915f49bf5c33e4c1e590e1a2c41803c8234d1aa13761ea
			8c15a20a14b74d5399eb422952d1bf73993bd9037531ee8b5d64401c2a11
			157522707a9954e635a41e45ef52b89c23ae24a0fb6e61a68ee729ccf3ba
			14376d3a0b4b75b16a460622e1ecf295f3d62230092e9381479ad43d9e3c
			c21460fc474df4ef4d509b5eddf5382674cd21d6ecbc1d8fb3a490871aaa
			2cf4cad4ca4eeb86d3666cb360f55ad313b835ab2b6e817e1f85e55bc05c
			e894ab7f02cb75a6df3ee9945d474c8c5d12cc44e84dd5a3fe1690c47a33
			6c0fd062556bb5a863a53a0e5728f67228a0523f6712b7ef58d120d28477
			0e732062ca3d22553f0958241551919c2ba575a5d0205e44356b2aa538e3
			552ce5daa6abb81b6da1ae328e790cfef13ca893063205316cec4dc45b25
			4d991beefefa6ded038c34c90066cefa8ca16762bee016530b9122ab4242
			53a0dfac296ae91355cc101ac0a26128c2aee68108dcdeb0e90ade7da342
			09df6710ef95f19e9724a342353b45fc76ad106bbc70e98951652f9330d2
			9f7021de691fcd318f0f00d7986fc55bff75f31de0ac5942708ef01b2c8e
			0bd77e617c50c20a6d5e7fe8da920e3de6d99abff60ce52b6425ca3f45cc
			5f533c728dbfef5fc3669249269964924926996492492699649249269964
			924926996492492699649249269964924926996492c90f4bfe0f0b0549e9
			00500000
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
	sed -i ./debian-live/cdimg/boot/grub/grub.cfg                                                                                       \
	    -e 's/\(linux .* casper\) \(quiet.*\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                                                                                          \
	    -e 's/\(append .* casper\) \(initrd.*\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	# -------------------------------------------------------------------------
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs
	ls -lht ./ubuntu-live/cdimg/casper/
	# -------------------------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
		find . ! -name "md5sum.txt" -type f -exec md5sum {} \; > md5sum.txt
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
	ls -lht ubuntu*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
