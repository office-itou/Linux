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
		1f8b08006d701f5b0003ed58cd721bb911d6957c8a0ec5326d6731434a6b
		c9459bcaaa6cdaabac642924e575ade470c1199033e20c301e6044ca122f
		b9a52a49552a951cf212b9e59277c883e49c534e690c86bf62bcd6cf566a
		abd8071203343ef41f1a0d58769f8b28f2874432954496f4d6ee9dca48db
		dbdbe93fd2c27f6573e3c9f65a6573b3bcbdb5b5f9647b630dbb2a1b5b6b
		50be7f51ae5322158d01d66221d4a7f87e68fc274aeb3fb33b3eb73b547a
		798c00202c09f3eb40082816873ea78ae1c7dd28dfe54e9dbb0f1fc1653e
		d7a8b7dacd56b356ace4f339cf974ac417409c7cce66cab17dee2bcbb5dd
		4e220187a27c2e0945c215d82e3bb72325e1ea0ab22ed20d26dd737ca0e9
		3adf94475ec8653cd83de58962e12ce1d1dd28381bfa0a8a979932a3fcc8
		d84c8befd3c0ff7867a3e5732aa611948ce9a052820a6cc026549ee8c523
		112b386a566a85878ea723f31114f2b94c4c0563d9a70d23f7940355eda6
		3698348cf61306b4970a231c9a18d498709641bb03a69e99fa62892b69ac
		8c8902e1dc8b81b489247381f8902e97e232abc7385ca3d37c4eff110625
		69fffa64977c47c9c7f7f63a3cb07ba54fb0aec3e9c333dafee59175dc7a
		459e42fa7bfac83eade879d758196f1f3797b1e673463a82d26184452eee
		2a62ba607ff7cdebdacc22f99c43153c7f4ea05d3f6cb56167c7e837747b
		7630944c4a5f707bffddcbba4d13258c6573b9af70f30efb9d10638604f4
		42240aceb0292285ece0a838a8ca018d1c2a593e0536de08859ba0103e47
		9c20b88b4f10ef79c842b1830d004fa948566d3bc00d2e2d97757cca2d11
		f76cd3248964b1bd51ae54ecf29776287bd8da7a6a792a0ce6a6879447b4
		c7e610a48ad11e9e4d23654b91c40e0eeb65ac27d6199d42687a19f57bd5
		ea616a0359add650bfaec009c411bcebb22e8878ae8bb3c1629708dc09dc
		aef321f16356adbef098d3276f318e5d72cc951fd4b898c89d6acd9321d1
		d6b024ed2731b538b3cea2f1513bfe6f3b78f888f02c2a3f2d57cae5f473
		5e011715201f12a653e4b72897f4c400650ba9aa958a977bc66bcc254ddc
		50a35355bc3ca24e1f0d363ae525b802a9d304e13136030c9cf90db368bf
		ebdb66713b7455848e98f585e9997cea48df3d6ab51bf5fd5a416719453b
		185dd8524c2a9ff77433e1d36ecc642cf643c6518f427e7d3ab960808e8f
		5ed60ac5cbac7b84f1fc69274ca6bd5e9cb6180a0b91904ddc7bd3bce144
		744accb2ed9381340edea60a68e7e1b066f47b498c0ad3a536fe017af040
		7b01bd85d903bdf90108064377323cdebab707cbf43d783b8228897bec26
		c265f131f039dbb42a3799f9bfc17a8e08a3d8978fef038c29717147a419
		c9b8083189d390dd053203e3ec9cc51d74dd9da4cbc0a4e307b473573d33
		3093be4c6e20b7c35c166733a44fae18d3e3f96705db35302413b4981f46
		60ced3bb4866c070f38f6eb89d606233871287c5caeffa787c33f9f9f397
		81e1b147dcce2d3116c186950aa151745b91e6c114957d724623ca9964f3
		5fc465b28f25fbe783f961961cc1c7229184e2a3737bc9c6a502ca33db26
		e3f2f5466081df8999e8a23319f1581069d0d9bea052e6baef13f4a3ef80
		053027607449e97b73b0cf07d284d72304cb6e29c55f98aa52df48409778
		252cfd993227ff2d6b7c3c6de1b8596fb4dfec1ed4717b4221ab9e0a50d0
		ebe8835660019cf27c7d7850af7d4f077d20afa0542d41a958a9d50a582b
		4d2046a5025ce2f182b798e2d6b351c91443119572e07e8f3851223dd4e4
		728237821d73b5e1491020438e399ed0ea8075ee87b173f78b4caa67ee7a
		dd6ff0f5504e5fcd79127658acbf0a70942aa03ca69335cb86b475bab1c0
		01d105461d2f1db426005876e93b75edcb14e28d9983ac32a25804221a0a
		40e1798b7676349446effa58a839face27013d31c5d215a311655fd78e78
		8f60556862799aae0254c28b56639fec812fc1f565847712e67e316e4211
		6857e1ea0ca30625989753633b1e8d650db1aaa73b6d5ca5a950e31e0a29
		746069f14a9aad94ae0c146174a06891afaa7ae00aa50e310fb853582e06
		78a53642b73c946b7c39f228c76401a9f06ca8e6449e4ed7b5b75e2c9dbf
		d7d52260018e39ff0b6830647698be3bbcf5654203235594687b62b12031
		198130160da8548bfa62179e3a2a91b50d231c83731a244c9b46cd48eaf3
		2ef672edac81c766f0b0fe7251fa818f27974731a7503080263c6830a017
		d2ca2e7e7321ec2471703f31bc3c840d7eaaaabef06a35d28f2816bd182d
		433a344e3b7432c45bb1c2db80310c9a9bb03816f132b1f57bd58f29b6c1
		4f05594f57fcd37ffe72f9bb7ffdf9ef7ff8eb6ffff19bbffdf19fbfff37
		649373fa4e0d85d3e265abde381815d04b69b7ce8e85b4942ac023c8de6c
		d2dbfe8b67cf261c8f716c09651c4c52234436fd75eb9bf6de41fbe0f0e5
		f17ebda64fcdd9d177d8bff76aafde68d6bef2c36bc3bf6a2dcebd6ed8e9
		917c2f869d81e3309627ecbb7e0cd6d0e7b8412c5777051c883499f85da5
		620ff5db913d66b0d3d791e904f39dfa0d630467366036bf57673fe69689
		44e4ce27735770668eacf4d4bbfd3935a777761a960d72fdf0d5bd1c11e9
		13cbe3fba4f9279b9389b3de67ef0f2fd2c408df507ee69b0c7ff26d9a68
		24f4d9c5fb9f9f34f5c191b6c9cec9778cf7693fb1bfa6e97fda7def12ff
		bf9fcb57b4a215ad68452b5ad18a56b4a215ad68452bfa49d27f0114ab19
		1d00280000
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
