#!/bin/bash
#set -evx
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.1-2017-09-05-EN.iso]                        *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V8.1-2017-09-05-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
# == initialize ===============================================================
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt-get -y install squashfs-tools xorriso cloop-utils
# == initial processing =======================================================
	rm -rf   ./knoppix-live
#	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	# -------------------------------------------------------------------------
	#	tar -cz ./knoppix-setup.sh | xxd -ps
	if [ ! -f ./knoppix-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b0800e886bb5a0003ed586d73d33810ee57fb57e84a87c0dd28b6db42
			990ce9c1d0003de0da6bcacb1cdc64145b8995d89291e436a5e47efbad6c
			2771d200a1297377337ebe78bd921eaf7657da4deace908b246123aca84e
			93ba0a376e1c2e606f77377b02169f7b7baeb7e1ed6cdfbbbfe7eeec78db
			1baeb7e3b93b1bc8bd7953ae22559a488436a410fa6bf3be35fe3fc5ad9f
			9c2ee34e97a8d0be052980303d1bd9b710c6485319334e348597f560f7b8
			dfe2c19dbbe8d2b64e5aa79df669bbb9e5d9b61532a585bc40d8b72d876a
			df619ce97ae004dd5421184a6c2b8d45ca3572027ae6245aa1cf9f51a1c2
			bd68aa9e9b870caece9bcd51176ad91c50cfe62452f84be61835184e474c
			a3adcb6233637b9cfbcc98cf48c43eaded34dbd29224a896bb0e7935e4a1
			6db483bc7be6e389901a1db7bde6e61d3f34a979176dda5661a64613db67
			426ef76c066cb597f9602ae4bb9f4e007fe93881a1a943731796279870a0
			596466b158124a2275eea258046944c153a08ba275dc047c0f631a8b7d10
			100ab54e54c371224829550f6897115e17b2efe4224e1595ceb6eb798ebb
			ebc4aa0fd2fd07f550c7d1dcf298f084f4e91c83d21236143a24d18e12a9
			f461d87ca67eaf3e20330a838364d86f348e12cd04578d4613f6d713b000
			fb82f702da4342cea9383d5f54892898d23df63fa64cd246e34948fd217e
			03a915e0d75cb3a8c9c5d4ee6cd73c1d61e38dba22c354923aa7f54132b9
			dd27cf8e0ff79d880789fbc0f55c377b9ddf40001bc01f536a0ee55bb04b
			85e21c6c8b896ed6b62e0ff3a8d100b721c7c71ff4d6e531f187e0b0f107
			5e439f91328989b90431a20a5241d1006186b28c58f41f5a860fb6651e98
			a29a727a3a81409463613483a4ace9d76cebf1f169e7a4f5b2b969525b93
			2e2418489a2acd78df88299fa9e1f850c962ca612b9bf9dad7c707cdcdad
			cb82668cb0f8baeba7cb9e2d2e5b4c8085f8170b0f7f6f5f6fe1c9ab37cd
			4d90c195b86faeeb8fc65939136c628cd2243057f68ab87ddbf8bb44862f
			0a32f8d01825a9ecafcc550a5e9e8d79a8f1cfdf43b084acef8b38914c5d
			9ba74c46b5b85893a964191731c57d12d375280b324ecfa8ecc2e15acbba
			824cf92c22ddb59896a546092485c20dd7cdd94af971850cfd90a4856335
			9e56969551f84c1335c40392104e159d7fc3015543e84656276371767059
			1f31a87f38169ffcd50d5a249bd424b0a72ce34965fe2eb288752515bd1e
			83a319d22831a4655de4b9dce8be821f9e1a0b647e44095f698fdf205b9d
			c8003a3f202b1ab0ad5ff3f62512fe8df477a6c3f389460f1f62d4691d9d
			76d0fe7e5e254741df89460aaa275402e7e5bb8396639c90b75096f508ba
			f4d1b01b437388237221528d06208aac70205fcba8a1ce49e21345ed8c38
			b7db3489c8f44035e8c6a8ceebe2cdd88dfe76ea672c96d05f5ae627044f
			e32e95c50b545dd3c737778b7753f74ba21f12a99a30a9b1df299b5bf42b
			3760f155739d10aeed69677493a62f89e8fcb7ccefacec63450bffecf445
			e7f055e7d5d1c1eb97ada6b92a6663ef407bf8f4b075d26e3e62f1c2e01f
			a78beb4ace9b5d3ed78b70c979732df6939070e8075e103e60a68fa78df7
			6f190fc4b942437af1d72fefdb09f16926e3fdf77f523e8456d4794eb267
			a6b6ad926d1ce57b8a8701938b9e1a319ea4f0fbc1b6228eb0ca8fc63be8
			de47e6778533197606a4f3dbf19716e7a31016686281e56492568d497a7d
			e9a3991bb3dbe2fae7642e078b5bc4cd995b474fd727cd99ffed3f102a54
			a850a142850a152a54a850a142850a152a54a850a1c27f12ff00f3ee7c49
			00280000
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
	extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/KNOPPIX_FS.iso
	rm ./knoppix-live/cdimg/KNOPPIX/KNOPPIX

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
