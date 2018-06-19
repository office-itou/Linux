#!/bin/bash
#set -evx
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.2-2018-05-10-EN.iso]                        *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V8.2-2018-05-10-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
# == initialize ===============================================================
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt-get -y install squashfs-tools xorriso cloop-utils isolinux
# == initial processing =======================================================
#	rm -rf   ./knoppix-live
	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	# -------------------------------------------------------------------------
	#	tar -cz ./knoppix-setup.sh | xxd -ps
	if [ ! -f ./knoppix-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
		1f8b0800a6b5285b0003ed58cd721bb911d6957c8a0ec532edcd62862359
		968b369555d9b457bb92a58894d7b592c305674012e20c663cc08892251e
		f6944b2eb9782fa9dc7249652b6f909749d9c963a43118fe495cd9a6944a
		a58a7d20f1d3f8d0dd687437c6b27b228c227e4a24534964c9eed2ad5319
		697d7d5dff3beb6be5c97fdd5c7556d7979cd55567c5595d79b0e22ce1d0
		fadaea12946f5f94ab9448456380a5804ac5e25fe6fbd8fcff292dffca6e
		7161b7a8ece6d10380b024c82f032180da065c50c5b07333cab7855b13de
		dd7b709ecfedd71acd7aa35e2d3af97caecba50ae333206e3e6733e5da5c
		706579b6d74a24e05494cf2541980805b6c74eec4849b8b8806c88b4fdd1
		f0141f68baca37e6916772160f0e8f79a2387467f0e861149c9d7205c5f3
		4c99417e606ca6c5e7d4e76f6f6cb47c4ec5348292311d382570600556c1
		59d39b4761ac60afee540b77dd6e1c86ea1e14f2b94c4c0543d9c70d23f7
		9803556da73618358cf62306b4970a229c1a19d4987092411f078c4f667c
		16338e92c6ca98c80fdd5b31903691641e100ee976292eb33a4cc0153aca
		e7f41f615092f6ef0e37c9f794bc7d6d2fc31dbb53ba8675198eee1ed3e6
		377bd641e3197908e9efd13dfbc8d1ebaeb032d13ca8cf62cde78c7404a5
		430f8b3cbc55c40cc1f6e68be7d5894df239972a78fc9840b3b6db68c2c6
		86d1efd4ebd8fea96452f250d8dbaf9ed66c9aa8d0583697fb0a2fef69af
		15a0cf109f9e858982636c869142767055ec57649f462e952c9f029bd308
		422f4121b8401cdfbfc99920dee38005e1063600ba4a45b262db3e5e7069
		79acc5a9b0c2b8639b2649248bed95b2e3d8e5fb76203bd87af0d0eaaac0
		9f5a1e5011d10e9b42902a467b746d1a295b8649ece2b4dec65ab38ee918
		42d3d3a8d7a95476531bc84aa58afab5435c40dc50b43dd686309e1a12ac
		7f7928f4bd11dca6fb26e131ab549e7499db232fd18f3d722014f7ab221c
		c99d6a2d9253a2ad6149da4b626a09661d47c3543bfc6fba987cc2e0382a
		3f2c3be572da9d56c04305c89b84e910f91dca25bb611f650ba8aa968ae7
		5be6d49847ea78a10647aa78be47dd1e1a6c70244a700152870922626cfa
		e838d317e6b2fdae5e9bcbd7a1ad223c88c9b33023a3aef6f4cdbd4673bf
		b65d2de828a3680bbd0b5b8a49c545473713311ec648c6621e30817a14f2
		cbe3c5050374b0f7b45a289e67c303f4e7eb0f61b4ecf9e565975de19227
		640bb75ed4e75bb8bff332155a1f189e939ee49d244625e94cbb7e84eedc
		d196c713e22af110e40d10f480f6687e785fe707cb94dc79398028893bec
		3384cb7ca2cf055bb59ccf51eb97c13a6e18443197a306c11849c73d7454
		e111ef236266604c8598e0d35fe26509707ec9441860e0a6019373024d80
		0976c2e2963eb9510b7d250830448f0752cd3f014cbadca7adec8fb83e1f
		365380611bf5cf9aed04c1b1d8bb068c70e1fada49b22e16803ca033565d
		2f99897f26b890fb96f3c05afb5c835d755a24e3b41814066092e8dc60a3
		1b80377ef079d769aca64b89cb62c5db1c53f6dcee918161aa235e6b4e8c
		cb60a78e436814ddc463c7608aca1e39a611154cb2e91ede48d9c332fdd3
		c178900547e0581892207c3bcffd1cdb2c2d0f509ec9361996ac9f05e6f3
		56ccc2361e26235de6471a7472cc77ca428f5d43339d768274c1e6fa8c7e
		d265fa18d8270369c2570c82658f89e26f4cf1a71f0ea02bb11256e84c99
		043d67298e49110eeab5fde68bcd9d1a5e282864454e010a7a1f9d1b43ac
		53539eaf77776ad51f68bf07e419942a2528159d6ab58025cd0862502ac0
		39867e7c6c141f3c1a944ccd125129fbde0f881325b28b9a9c8ff006b061
		5e2002c31c32e498db0db53a609df020766ffede48f5cc5d2dcf0dbe9eca
		e917b44882168b75af007ba902aacb744864d994b64e3b0e71226c03a36e
		379db44600581de9a76ff57e0af1c2ac41561951acd5100d05a0f0b8415b
		1b1a4aa3b739d653ae7e9a49c0931863e9c2ce88b2ad4b3c2cf75905ea58
		45a6bb0095f0a4b1bf4db60053afc765844f07e67d396c4211685be1ee0c
		bd062598965363bb5d1acb2a62558e369ab84b5da1c61d1432d48ea5c52b
		69b652ba335084d18ea245bea8e8890bd0e90fc7c7b022ece3cbd708dde8
		a25cc3374c970abcdf900acf4ed594c8e3e5ba44d69ba5ebb7da5a04ac93
		314c7f09fb0c995da64bfc975c26d437524589b627e67789f1034263519f
		4a75595f1cc23ca112595d31c23138a17ec2b469d484a45cb47154e8c3ea
		77d9041e964c1e4adfe7986bbaf4040d0206d0b807f5fbf44c5ad9fb6cca
		85dd24f66fc78767bbb0c14f55d5ef52ad46da89e2b013a365488bc6e940
		8c8f1a7cbc2a2cda8d61d0dc84c57118cf125b7f56fa6f8a6df0534196d3
		1d3ffcf4970f7ffadbbffffae70fef7efffee79fdeffe1dd3f7ffce3fbbf
		ffe35f3fbf830c25a7dfc050382a9e376afb3b83021e573aacc36421ad5c
		0a700fb26f2ce9ebfcc9a347238e2f706e06651c4c52234db6fc79e3dbe6
		d64e7367f7e9c176adaa33dee4ec2b1cdf7ab655dbaf57bfe2c195e9df36
		2eafbd6ae1713abd150b4fc00918ca13f43c1e8375ca05de14cbd343be00
		224d487e856ff853fdadc71e32d8e9d78cf102d34f0f109d0557eec364a0
		af4c76a6b689c2c89b8eea5e2898c95d69f69b3f614de99da5c5b241aeed
		3ebb955c917e12f9e23669fa13cbe1e8b05e67df0b9ea41112bea5e2989b
		507ff85d1a7124f4d8d9eb5f1fd6750649db64e3f07b267ab497d85fd3f4
		3f1dbe7589ffd79fb717b4a0052d68410b5ad08216b4a0052d68410b5a10
		d27f00a5c1dc8200280000
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "http://ftp.riken.jp/Linux/knoppix/knoppix-dvd/${LIVE_FILE}"
#		wget "http://ftp.kddilabs.jp/.017/Linux/packages/knoppix/knoppix-dvd/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	LIVE_VOLID=`volname ./${LIVE_FILE}`
	# -------------------------------------------------------------------------
	ISO2_START=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $2; }'`
	ISO2_COUNT=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $4; }'`
	# -------------------------------------------------------------------------
	dd if=./${LIVE_FILE} of=./knoppix-live/efiboot.img bs=512 skip=${ISO2_START} count=${ISO2_COUNT}
	# -------------------------------------------------------------------------
	mount -o loop ./${LIVE_FILE} ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/cdimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX_FS.iso ]; then
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/KNOPPIX_FS.iso
	fi
	rm ./knoppix-live/cdimg/KNOPPIX/KNOPPIX
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
# =============================================================================
	rm ./knoppix-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
	sed -i ./knoppix-live/fsimg/etc/adjtime               \
	    -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/rc.local              \
	    -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 ssh"/g'
	# -------------------------------------------------------------------------
	cp -p ./knoppix-setup.sh ./knoppix-live/fsimg/root
	LANG=C chroot ./knoppix-live/fsimg /bin/bash /root/knoppix-setup.sh || exit $?
	# -------------------------------------------------------------------------
	rm -rf ./knoppix-live/fsimg/root/knoppix-setup.sh        \
	       ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb
# =============================================================================
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'

	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx32.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'

	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx64.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/efiboot.img ./knoppix-live/media

	sed -i ./knoppix-live/media/boot/syslinux/syslnx32.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'

	sed -i ./knoppix-live/media/boot/syslinux/syslnx64.cfg \
	    -e 's/lang=en/lang=ja/'                            \
	    -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'

	umount ./knoppix-live/media
# =============================================================================
	pushd ./knoppix-live/fsimg > /dev/null
		xorriso -as mkisofs \
		    -D -R -U -V "KNOPPIX_FS" \
		    -o ../KNOPPIX_FS.tmp \
		    .
		create_compressed_fs -B 131072 -f ../isotemp -q - ../cdimg/KNOPPIX/KNOPPIX < ../KNOPPIX_FS.tmp
	popd > /dev/null
	# -------------------------------------------------------------------------
	cp ./knoppix-live/efiboot.img ./knoppix-live/cdimg/
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		xorriso -as mkisofs \
		    -D -R -U -V "${LIVE_VOLID}" \
		    -o ../../${LIVE_DEST} \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
		    -b boot/isolinux/isolinux.bin \
		    -c boot/isolinux/boot.cat \
		    -no-emul-boot \
		    -boot-load-size 4 \
		    -boot-info-table \
		    -iso-level 4 \
		    -eltorito-alt-boot -e efiboot.img -no-emul-boot \
		    .
	popd > /dev/null
# =============================================================================
	exit 0
# == EOF ======================================================================
