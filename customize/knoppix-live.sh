#!/bin/bash
#set -evx
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.1-2017-09-05-EN]                            *
# *****************************************************************************
	LIVE_VNUM=V8.1-2017-09-05
# == initialize ===============================================================
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt-get -y install squashfs-tools genisoimage cloop-utils
# == initial processing =======================================================
#	cd ~
	rm -Rf   ./knoppix-live
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz knoppix-setup.sh | xxd -ps
	if [ ! -f ./knoppix-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b0800d8847f5a0003ed186b73db36325fa55fb1953d51e31b889212d7
			39c5729bda8eebc64e5c3fd2cc45ad0622211116093000684b71dcdfde05
			493d28cba9233b737373da198a8bc562b92f00bbea0b19457c4034337154
			d1fea36f0055848d8d8de48d30f3ae3dadad6f3caa3dad3fddd8a8d6eb88
			576bf58d1f9e3d82eab7506616626da80278a4a4345fe2fba7f9ff5158f9
			cee970e174a8f68b2b980440d8c5a0b8028480612ae4821a8683fb41b12b
			dc5de17dff04ae8a058719d7e1829b8ae7789d588336322a16e250c6c280
			e3b10b27321a3e7f868c44bac1989ce3030b37f9263c7aa8e7f12079c213
			29e9cee1b1e4e275ea08ab2ca701ff746f4f140b46d108caa93f5e001b70
			03b532d4a00e4fa1b65e2cb041249581a3935ab3f4bdebdbac7b02a56221
			53cdc048df0992ea3ae140f3ba89dd6324b578cc803e326184536327a66e
			9b66b02180493426fe9f133eaa4ceaa8507a71c0d05f480b82fb380be56d
			862c945b8800f8c644bae13801d746573cd6e15454a4ea39294a62cd9453
			afd66a4ef59913ea1e623f3caff8260c72cb432a22da633909da2834c877
			68641c2d63e5e2b4fd4c65bd724e27222cec44fd5ea3f136325c0add6834
			d1beaec405c495a2ebb12e4895230976394b92813716f7d2fd1873c51a8d
			6d9fb97df20e13cc2367c2f0a029e458efc46a110f88f54645d37eac6845
			b0ca79e4f4d3a37bf46ebb7894c9f03caa3eafd6aad5649837c04303c8c7
			98a92190df512fedcb4bd42da4a6595ebdda4fa3c63c7282997edd32ab57
			47d4eda3c3ae5ba20c9f41dbc42442211a308da9a0990784439211b3fe83
			79d02a16ec8b30286ba76b220cc4742c2ce53c9aa6f4cac5c2cba3d3f6f1
			ee41b36453dbd00e2618628669c345cfa2b1989071fb30c54326d094d23f
			accde6cf8e769aa5d5ab8cf51a88fc7268c6cbf66697cd26c84c7e640bf7
			df9c2cb6f0f8f05db38438ba9af4ec49fd11c810324987efae218a558fcd
			75fc2d90c5234db0347a64ed6b04cc11d673651829ae1796332d8c1939bc
			a7a429cd840c19e9d190dd4764264cb00ba63ab85feea55d264cbb3ca09d
			7b497afcd80acba7c614d0d8488527c8c59df2e386308434cf70b35c431c
			79b62a5854b3071536de01b8adaec737cf9d210b000f93bdc67bc0f14a23
			a1fce4de5dc6acb080771493dd2ec7dde4b32022e734470b6a5561697712
			36bab3ec82299c8c6eeeafd20c0b053c63bd054c9b23acebb981145f75de
			ccc2374fda19616ec0a8584cb33c24828a85e3ddd3ed9de6ea8fc502efc2
			074cc48480473abaa50a7fbc00e333642ba4e51e2269bd572c74795a3005
			d27d90bad2569651ac7d0f9c582b47fb54312711ce1cd84aab37110701aa
			a04220aa0b1db6069dde1ab878167a141f1cdb73b1cbf1516be0e3d847dc
			8fd7809b351078d045f8281ceb3e3e881be4fbe4afe1a7252655ee33e9b7
			6d5144882d070855aecf31909fa1a75804e4c256017f6252db1713edbd9f
			2d86c8d909f20ca8ea699816e2b1801946ba4a862359f90264e0f59c60a0
			b130c14bd43978bfb3ebd89027d5e94cf4a6ca9055fa13363d837e27c4b2
			9c0474286303e788cae43206d7a8a0a12f69e452cdca69d06c4d0eb6e42c
			63f1cb4c5a862c1834971ad8dc24d0de7d7bda4617fee5542e78a8b09c2f
			d8664cc46187a96c80f58b6d959acfb2b1f5eb14ea62d07513991a5bed62
			22ef86f844be6df5920face063cd82526bf5ea74f7f8f0ba84072812ad73
			4a4951508227d9d8c2c1cb377bcded29c28b17d960ed26df396dff7a5439
			3b7d459ecfae609abac966485a1dcb3d19ed9dbe6eef1fb60fdfee9c1dec
			36ed693c997b8fd4fd57fbbbc727cd9f783833f9dbe9ecbad40749c8b212
			f901a2863ec5ec88c681c21ec9c7b2625c8c4fcda78ebe398f55b700723c
			52aa32522ecf38ca83bbb267614d1bd6f175b6585e4e999bebc3b67d2ab0
			c27c4dc539b7cd1e6b7cf89d0b4f5e6ae8b3e11ffffa701251972538d9fa
			f01f26fad8af38bfd0e49d90f1a49ce826200d61d8f7b89ab567c0451463
			938967099aafd34dfe1e5bbc816d3e9dd1b493e4d96d8bd3d9bb3b71fcd1
			c48d6e40437a71ffb3d966cdf45195ca75ba8a69dfe215eb903b5d4bb740
			aeaf5a81a46b016c21c0b6a0585ed18edde6f56760b035d2409136bc9daf
			56cff1f5ca79f9c92a8dd24658ad6e791e4cff3fdf48c3bbc36d748ce7ac
			3cb63d60120d6dafb70788c56c3450ae7dbc7696968b297d64ff2c33c778
			351cc81e17505973664943a6e7382a1fbb23aaf5a554decbd8960e86e301
			6eaf21bbf40b53f91039bfe0adf79a0da165ed6b59e3929fb68ff436733d
			4ddbb8171d6f4ed0ee2ec6abafafd7fe7d8ba0dc0d7ba6d9ce9b1310b225
			f6b107530c09eab5c01d69bfa071228bf0a83c7de808677247ef85b65bce
			2238b5fb63eff014b0a46f89cdbd40622bb8d512ada9704b61c768eb2b13
			598b7542d97432e6725e47542c4e98e6e4962d3870bb26afd16e482ad0c5
			2b8f9caf46e5a98f5584b47f0eb9c5b452ada6dfda7dfbea61361e29feb7
			ffee5ec21296b084252c61094b58c21296b084252ce1ff12fe06b707c476
			00280000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./KNOPPIX_${LIVE_VNUM}-EN.iso ]; then
		wget "http://ftp.riken.jp/Linux/knoppix/knoppix-dvd/KNOPPIX_${LIVE_VNUM}-EN.iso"
#		wget "http://ftp.kddilabs.jp/.017/Linux/packages/knoppix/knoppix-dvd/KNOPPIX_${LIVE_VNUM}-EN.iso"
	fi
	LIVE_VOLID=`volname ./KNOPPIX_${LIVE_VNUM}-EN.iso`
# -----------------------------------------------------------------------------
	mount -o loop ./KNOPPIX_${LIVE_VNUM}-EN.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/cdimg/
	umount ./knoppix-live/media
# -----------------------------------------------------------------------------
	mv ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/cdimg/KNOPPIX/KNOPPIX.orig
	extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX.orig ./knoppix-live/KNOPPIX_FS.iso
# -----------------------------------------------------------------------------
	mount -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
# -----------------------------------------------------------------------------
	cp -p ./knoppix-setup.sh ./knoppix-live/fsimg/root
	mv ./knoppix-live/fsimg/etc/localtime ./knoppix-live/fsimg/etc/localtime.orig
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
	sed -i ./knoppix-live/fsimg/etc/adjtime \
	    -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/rc.local              \
	    -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 ssh"/g'
# -----------------------------------------------------------------------------
	LANG=C chroot ./knoppix-live/fsimg /bin/bash /root/knoppix-setup.sh
	RETCD=$?
	if [ ${RETCD} -ne 0 ]; then
		exit ${RETCD}
	fi
# -----------------------------------------------------------------------------
	rm -rf ./knoppix-live/fsimg/root/knoppix-setup.sh        \
	       ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb
# -- make iso image -----------------------------------------------------------
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	pushd ./knoppix-live/fsimg > /dev/null
		genisoimage -D -R -U -V "KNOPPIX_FS" -o ../KNOPPIX_FS.tmp .
		create_compressed_fs -B 131072 -f ../isotemp -q - ../cdimg/KNOPPIX/KNOPPIX < ../KNOPPIX_FS.tmp
	popd > /dev/null
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -not -name "KNOPPIX.orig" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		genisoimage -l -r -J -V "${LIVE_VOLID}" -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
		    -no-emul-boot -boot-load-size 4 -boot-info-table -o ../../KNOPPIX_${LIVE_VNUM}-JP.iso -x KNOPPIX.orig -allow-limited-size .
		# isohybrid ../../KNOPPIX_${LIVE_VNUM}-JP.iso
	popd > /dev/null
	ls -lh ./knoppix-live/cdimg/KNOPPIX/KNOPPIX*
	ls -lh ./KNOPPIX*.iso
	exit 0
# == EOF ======================================================================
