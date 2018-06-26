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
			1f8b0800bc16325b0003ed594f6f1bb915cf55fa14ac6244c976a9911cdb
			0994c8dd2051b2eeda896bc9d960e3544bcd501a5a339c31c9b1e4383af4
			d44b2fbd642f456fbd145df41bf4cb1449fb31fa488ea4194bb0e33f4551
			400f88453e92bf79ef917c7f988a33e0511cb3119654257145fab76e9caa
			400f1e3cd0bfb507ebd5ecaf6eaeadafaeddaaddbf5f5b5babad5637366e
			556babeb1b6bb750f5e64599a7442a2210ba7598f073e75d34fe7f4ab77f
			e1741977ba44fa45380108d3242cde4618234545c83851143ad7a3628fbb
			4deeddbd874e8b85bd66bbd36ab71a2bb562b1e033a9227182b05b2c3854
			b90ee34c553cc7eb2612c1505c2c24619470851c8f1e3bb192e8c30794b2
			702f98b273f390a6f979b339f2442e9a03ecd99c5844ee82399a0d82d311
			5368e53455665c1c5b9b69f11909d8fb6b1bad585082c4a86c4d876a6554
			43abe83eaaadeb8fc7915068b7556b94eebabe8822750f958a85544c8526
			b2cf1a56eed90c50b5676c306d58eda713c05e2a8c61686a506bc2ec04bd
			1d68b633b3bd58b09544286ba220726fc440da44927a0833643e677069a5
			4f399aa3836241ff608acad2f9eddb27f80782dfbf736ea33b4ebf7cced4
			dbe8e0ee21e9fc7ab7b2df7e8e1f22f3f7e09e7350d3ebe6a652ded96f2d
			9a5a2c58e9304807272cf6e05661cb42db4f5ebe68643e522cb844a1c78f
			31ea345fb53b6873d3ea37f2fa4e3092544a167167fbcdb3a643121559cb
			160adfc0e51d0dba219c191c90932851e8109a51ac603a729508ea724862
			97485a34c07637c2c84b4008c6012708aeb32780f738a461b4090d847ca5
			6259779c002eb8ac78b4cb08af44a2efd8264e2415ce6ab55673aa6b4e28
			fbd0da7858f15518e4968784c7a44f73085209b087ef905839324a840bc3
			fa3395f5ca219941687a160ffaf5fa2b630359af3740bf5e040bb01bf19e
			477b28123916a7c3b3ac28f0a6704fdca384095aaf3ff5a93bc0afe11c7b
			789f2b1634783495db68cd9311d6d6a848324804a9705a398c27a176f2db
			7121f844e1615c7d58ad55aba69b57c00305f05142b58bfc1ee4927e3404
			d942a21ae595d32dbb6bd4c32db850e303b572ba4bdc01186c7cc0cbe803
			92da4d602ea019c0c1c95f98b3f69bbf3667af434fc5b011d9bdb09c6957
			9ff427bbedce5e73bb51d25e46912e9c2e68292a15e37ddd4cf88c0d9e8c
			0a16520e7a94ecdafddd678dd2ca690a3386237cbedda7cb5e9c5d7676f7
			cf6c7eba70eb65eb6a0bf7765e374ad0d67b045ba307593f11a0175968ca
			0be8ce1d6d6cd814a6120f408e10864def4dc72757f4ea60a9923bafc728
			4e449f5e42b8f41810ee89086c1fb02ef1bad96e17ce1d042c97e69932d7
			7713d832b9008c8ed41ab683196e6fb527e7b941d43f5f3249cdf5cbb162
			22f2a2247cc820ac5ea8e6dce7df33c0727d767ca1f952b02e536eb4e05b
			97a314accfa310a20809a944032f6dc1d113147bd40d88204a4b0643e908
			111e866843f0a0b77e16ec280cb0f5ff182e2fcee35d5632aa2248aacc5f
			eca549c7d5d58ca567fe603760e01ca4e908addaa461b4fa22b0907a8c80
			9bedce5aa0611842589c313c4235e342b0231a26e60f1e1c87b62183a897
			b64ea4a261b68d8908cf079b4c4c25cab24216cb330ce9e61871ec2e04d3
			e73d3f73f470c3f675e09db530e4febd502d96cc9efd6b500a761cb8fa9f
			fe96f9353ba71b41ad6a397190f419c7c65f64fa476a21d864580ec027ae
			6639c7cca31186dc2786f4678e2fe38029a86a16821d3399e8bc94987c29
			33f0feb8cbced171ded302594f0b916c8c6cb2f785063bc76d43981a5f2e
			06ccd4740976a950acc720b5a457ddd2c97582ec0d7cff3529051bd56a98
			c4f1b54ed9144c1139003728075037dace218909a770a872bde99c0bc182
			9147f38852fa18eecd319c22d31fd2eea47f0e180bd3f400414491e074df
			5fc541ce36c0e4c4a04fb68d2775daa5c020a2091af5e06450ecd320d6a0
			599ebea29a770e2dbc0119d2558a1b50729e77fd62b02f06d204a53b80a5
			15f4caaf6cc5a3ab65a47d5f19ca52aa6c567ac5fa13d242b4df6aee755e
			3ed969c2ed44a534b32fa192fe8ece0e2328cecc9c6f5fed341b3f92e100
			e1e7a85c2fa3f24aadd128411e3f8518974be834160c2aec958d47e3b24d
			d46322e5d0fb1170e244faa0c9e9146f8c366dd9cd9320800905eafa9156
			07558e590831e01a055d46cfc27c4d6af1f550413f1bf124ec52a17b25b4
			6b14503e8593c4693aa4add313110c40b4a4c4f5cd60650a0025817eef69
			ac198897760d4c855006050aa08100043d6e93eea686d2e83d064584abdf
			2324829d9861e96ac68ab2adeb1ac871681db5a074325f4144a2a7edbd6d
			bc8598441e83b0404ea8f7f5a4895610e9e93041e1d48004793935b6eb43
			3ad900acfac16607bed252a0711f848cf4c1d2e295f5b4b2f9b24e1eb578
			46e40f753df001e9680ffc192c8f8682c456e8b60f724d0a779f70b8dfc8
			080f69724ee4d9725d17ea8f99f55b3d2d021487e0f3bf467b1426435e0e
			12bc3631ce4aa52324f80fa80ac17fa0c85a3420529dd51758107454221b
			ab563808d12448a8368dca480a890470b9deaca14f33783ad106e9870c02
			974f208523c802dae3418221399195f451227784dd4404377386171f618b
			6f54d58f315a0dd38945d41760194848846108480e15c50a2a556b183037
			a642446291d8fa2df5bf29b6c53782dc365ffcfcd35f3effe96ffffeeb9f
			3f7ffcfda79f7ffaf4878ffffcdd1f3ffdfd1ffffaf9234a510afae10795
			0e564edbcdbd9d7109b6cbb0b59b2c997aa984eea1f461d13c493d7df468
			3ae32b185b40e90c2a8995265dfea2fd5d676ba7b3f3ead9fe76b3a1235e
			76f40df0b79e6f35f75a8d6f583837fc9bf6d9b5f3169e85d31bb170068e
			a3893ce1c0630255468cc34da9789a157084a575c96f6a3567a41f389dc9
			04c73ce1cd16d8bed940382cb0720f651d7d3ddbc97d268e622fefd5bd88
			531bbb4cf4bb7ac0cae99d86c5aa456ebe7a7e23b1c2bc037e7593947f57
			7c3bddac77e923d953e321d177841f32ebeadf7e6f3c0e54c8f4e4dd2fdf
			b67404316dbcf9f607ca07649038df12f36bd8372ef1fffaff7496b4a425
			2d69494b5ad29296b4a4252d6911fd0747b8d2c200280000
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
