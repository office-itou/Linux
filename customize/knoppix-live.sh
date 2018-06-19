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
			1f8b0800adb2285b0003ed58cd721bb911d6957c8a0ec532edcd6286942d
			c9459bcaaa6cdaabac642922e575ade470c11990037106331e6044ca122f
			7bdbaa2455a95472c84be4964bde210f92734e39a53118fe495cd9a2b495
			4a15fb40e2a7f1a1bbd1e86e8c65f74418457c4024534964496fe5dea98c
			b4b9b9a9ff2b9bebe5e97fdd7c5c59db58a93cc6bfcadadac6fada0a0e6d
			ae3f5981f2fd8b729d12a9680cb01250a958fcd37c9f9aff3fa5d55fd86d
			2eec36955e1e3d00084b82fc2a1002a86dc005550c3b77a37c473875e13e
			7c0417f9dc61bdd96a341bb562259fcf795caa303e07e2e47336538ecd05
			57966bbbed44024e45f95c1284895060bbeccc8e9484cb4bc88648c71f0f
			cff081a6eb7c131e792ee7f1e0f084278a43670e8f1e46c1d9802b285e64
			ca0cf34363332d3ea73eff7867a3e5732aa611948ce9a052820aacc163a8
			acebcda3305670d0a8d40a0f1d2f0e43f5080af95c26a68291ec9386917b
			c281aa76521b8c1b46fb3103da4b05114e8d0d6a4c38cda08f0326273339
			8b39474963654ce487cebd18489b483217088774bb1497595d26e01a9de4
			73fa8f302849fbb7c7dbe43b4a3ebeb757e181dd2dddc0ba0a270f4f69eb
			d707d651f315790ae9efc923fba4a2d75d6365a275d498c79acf19e9084a
			871e16b978ab881982dded37af6b539be4730e55f0fc3981567dbfd982ad
			2da3dfc0eddafe4032297928ecdd772feb364d54682c9bcb7d859777d06b
			07e833c4a7e761a2e0149b61a4901d1c15fb55d9a7914325cba7c0e63482
			d04d50082e10c7f7ef722688f73c6041b8850d004fa948566ddbc70b2e2d
			97b539155618776dd3248964b1bd56ae54ecf2133b905d6c6d3cb53c15f8
			33cb032a22da65330852c5680fcfa691b26598c40e4eeb6dac75eb944e20
			34bd8c7add6a753fb581ac566ba85f27c405c40945c7651d08e39921c1fa
			578742df1dc36d3b1f121eb36af585c79c1e798b7eec9223a1b85f13e158
			ee546b910c88b68625692f89a92598751a8d52ede8bfe560f20983d3a8fc
			b45c2997d3eeac022e2a403e244c87c86f512ee9857d942da0aa562a5eec
			9853632e69e0851a9ea8e2c501757a68b0e18928c125481d268888b1e9a3
			e3cc5e98abf6bb7e6dae5e878e8af020a6cfc28c8cbbdad3b70f9aadc3fa
			6eada0a38ca26df42e6c292615175ddd4cc4641823198b79c004ea51c8af
			4e16170cd0d1c1cb5aa178910d0fd19f6f3e84f1b2d757975d75852b9e90
			2ddc79d3586ce1e1dedb54687d60784e7a9277931895a473edfa097af040
			5b1e4f88abc445900f40d0033ae3f9d17d5d1c2c5372efed10a224eeb25b
			0897f9449f0bf6d8aadc46ad9f06eb3a6110c55c8e1b0463249df4d05185
			4bdc4f889981311562824f7f899b25c0c525136180819b064c2e08340526
			d8198bdbfae4c62df49520c0103d194835ff0c30e9709fb6b33fe2f87cd4
			4c01466dd43f6b761204c762ef0630c285e36b27c9ba5800f280ce5975b3
			6426fe99e0429e58950d6bfdb606bbeeb448c66931280cc124d185c1c637
			006ffcf076d769a2a64389c362c53b1c53f6c2ee918161aa236e7b418cab
			60834a85d028ba8bc74ec014953d724a232a9864b33dbc91b28765fae783
			f1200b8ec0b1302441f87191fb39b1595a1ea03cd36d322a596f05e6f376
			ccc20e1e26231ef3230d3a3de657ca428fdd40739d768a74c1e6f88c7ed6
			65fa14d8670369c2570c82658f89e2af4cf1a71f0ea02bb11256e84c9904
			bd60298e49118e1af5c3d69bedbd3a5e282864454e010a7a1f9d1b43ac53
			539eaff7f7eab5ef69bf07e41594aa2528152bb55a014b9a31c4b054800b
			0cfdf8d8286e3c1b964ccd125129fbeef7881325d2434d2ec67843d8322f
			1081610e1972ccf142ad0e58673c889dbbbf37523d73d7cb7383afa772fa
			052d92a0cd62dd2bc041aa80f2980e892c9bd2d6e9c4214e841d60d4f1d2
			496b0c80d5917efad69ea4106fcc1a649511c55a0dd150000acf9bb4bda5
			a1347a87633de5e8a799043c8909962eec8c28bbbac4c3729f55a1815564
			ba0b50092f9a87bb640730f5ba5c46f87460ee97a32614817614eeced06b
			5082593935b6e3d158d610ab7ab2d5c25d1a0a35eea290a1762c2d5e49b3
			95d29d81228c76142df265554f5c824e7f383e8115611f5fbe46e8a68772
			8dde301e1578bf21159e0dd48cc893e5ba44d69ba5eb773a5a04ac93314c
			7f09870c991da64bfcb75c26d437524589b627e67789f1034263519f4a75
			555f1cc23ca112595b33c23138a37ec2b469d494a45c747054e8c3ea7b6c
			0a0f4b2617a5ef73cc351e3d4383800134ee41fd3e3d9756f63e9b716127
			89fdfbf1e1f92e6cf05355f5bb54ab9176a238ecc66819d2a6713a10e3a3
			061faf0a8b766318343761711cc6f3c4d69f957e4eb10d7e2ac86abae39f
			fef3978bdffdebcf7fffc35f7ffcc70f7ffbe33f7fff6fc816e7f4d3170a
			27c58b66fd706f58c0534a8775742ca4054b011e41f669257d94bf78f66c
			ccf105cecda18c83496a84c896bf6e7ed3dad96bededbf3cdaadd774a29b
			9e7d87e33baf76ea878dda573cb836fd9be6d5b5d70d3bc9a2f762d82938
			012379829ecb63b0065ce005b15c3de40b20d244e277f8741fe84f3cf688
			c14e3f624c16987e7a6ee823b8f210a6e37b75ba33b34d1446ee6c307743
			c14cca4a93dee2796a46ef2c1b960d727dffd5bda488f44bc817f749b35f
			568ec787f53efb4cf0220d8cf00d15a7dc44f8e36fd34023a1c7cedffff2
			b8a11347da265bc7df31d1a3bdc4fe9aa6ffe9f0bd4bfcbffeaabda4252d
			69494b5ad29296b4a4252d69494b5ad292a6e9bfc56dc67e00280000
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
