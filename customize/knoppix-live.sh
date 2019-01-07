#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.2-2018-05-10-EN.iso]                        *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V8.2-2018-05-10-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt -y install debootstrap squashfs-tools xorriso cloop-utils isolinux
# == initial processing =======================================================
#	rm -rf   ./knoppix-live
	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	# -------------------------------------------------------------------------
	#	tar -cz ./knoppix-setup.sh | xxd -ps
	if [ ! -f ./knoppix-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b0800bda0315c0003ed5b7d73dbc879f7bfd4a7d850f2d1760c829464
			45471f3d717dba3bd56faa282797983e78092cc93581050ebba044dbf28c
			ed69daf465da74a6ceb473d399ce24736dd2a4ed1fed246de7fa6114f9fa
			31faec2e000224f5621b9aa41dae2d12fbf6c3f3b6cf3e0fb0ac9a03e607
			01dd3338115150e5fd7385971a946fadaeaa6f2813df2b57eadf5a3d575f
			59adafaed4d75656ae9cabd557eaf5fa39542b9e94e91271814384ce85be
			2f8e1b7752ffffd1b2f80db34399d9c1bcbfb0888c22cb42094c0a195e29
			2e8be8e0c5af0e5e7e79f0f2d5e11ffffbe1577f7ff0e2af5e7ff1c3c33f
			f9f5c1f39f1f3cff9b83177f1a4f215176ceaf0f5efee0e0e57f1dbcf86f
			b8aefde63f7f7af8935707cfffe1f5173f3bfce5df7efdd53f1efee487af
			fffa5f0e9efff2f02f5e7cfd875f1e3cfff2eb7f7bf19bfff8c14289d87d
			1f952f155bca09ee43070b82be593eff3df3bc679e77d0f94f1ae76f37ce
			b7ca0f510349b312e8fe52ed41f9cc08910a4382841e65929477565897d9
			1bccb970113d4948360abd8101a2d8ded8b15a3bade6527d61a1d4a75cf8
			e10819f6c262c924c23629a3a2ea984e27e220423f80f6c8f3232690e990
			a119088e9e3e457193d175d3e6fc4024cbf4c0cc203ee2b3064173665010
			faf68c41b279e1b76b5e8439676c5c25b247055a7a122b6c7f615fdb9bd4
			10c52e7dfccef69035b2e250a591891007a8a2cd19d52ba88e96d10aaa5f
			914c053eaccbad56bd59be60f7a557bf8860259562f50a94e87c7ca1f59d
			190246d255d6935ec476938e005b135e007da931c6e6971d218d198ded3a
			63c933960278132d7fd7b78b91534efec5a14af973e2208322c5864226d5
			1e6168aab4174af2cb20a8c2cdcfee5f37be8f8dc70fcc45f49ed9ab1c33
			7411b52f3cc2d6ef6f55efed7c64ac23f5d9be68b6eb72ded450c2ac7bad
			5943174a9a3a03a85b2845815c72866e42b7aedff9b899b9499eab3da767
			ba7b9c704e7d66defaf4c30d1347c2d75eff48ca97f0b76183db1b743cb0
			4fc3c5233f12e8115cfa81001c648bd06df05d1cd898938ad6b7e73b1190
			431960bbeebbe827abefe250a5bebd8143436404c87469c7d4d8dc5cadbe
			5fad19eb06f69cb5d5a4b5ea870e09c762d18be3e4699d88ba82b2fcb421
			0ed554d6e526f7aa1d3c5828018bbb4c2e18e15499df0bfd28983d50ab13
			e8a13dadd39070df1d566d9f75a74d754a930c7b84937008ccd4abea5f9b
			e5da6af0af5e99711f1c0893fb5168035b2eec80b36f7684e97745507508
			fcef50cc00b417b7a4d5c985338df1ac7d01c6a3be1041c334f554234e03
			aae0057cd1cf00b62f3e5b6cd79fc9c5a2d5fc4c320095e1981bf8536203
			777549f79ba0082cd0071f18c8dab8bb63a16bb3795f289532b44cb0a22f
			a52e3b60ab1e06f5339f19dd901004b71321ede8f9060fed77c0c813c189
			1d85548ca6518ca42b8633b5c7e01a36464be1a7492b0c794146c67aa411
			8fbc0cfb1519523fe2ee088132610d608e2a43dfc582bae04c4e2d68e30d
			b97a072c651ac5e71d4e30e801268e1c2ad29ab44fda8b42d8e270f1b704
			bb469ad79356f329577b01e5bdf72498a6ac17622726cd8078db471f8254
			1a8dbb6adfe18d46d330ba3eac4a252687cc74804750760c980f9e7017cc
			7a86508a63b350b0b1ccba91eb1a89e0e6323ba68c65968413aafc4ec94c
			603e301cc2079053ea8abbe7907ccb231c6006fb77be968e99007381e164
			661052268c78e7572d9cf773f55de933757d82320af1bde1f98f6d34e4e0
			4a1dc484f6235dc7767d2663348740ced0a11c22c4ae4bf68e91991f1066
			0c3d43f8becbf3b52c1f2794b3300d191d87c4034d21651a6f57ce8a32db
			2558e527bf5394a55469ca8adfb592182e13f9ce8e87752a22ed090d3da4
			adebdd6e3d4e458a43cda7221e1366bfd7e5f9c4ad2b039302b494cb05aa
			7dc8fc1ae6f89eb07b70521d7af2da90d708dca2bf6b41684dc2cbd2e2ac
			88a9670197c109e2c885fcbf866a71ca67bbd8c3c322949d957371a89329
			be463621a4e37d79ad53a87c727fc717b43bba01bd8eb9f89e19730a6ed2
			29c6a8b39c16873ac92920cb3fc7d2d1e45b180b88624b3e5015dbbe2f6e
			f93d088bab97ccc9a611e4c153795cfeb9c616e67c1792e9eb11d8141314
			d22df90841ce3ca62bf774c4fc04ccf62619a1b664ae2d39531f9634678b
			d80ec7d6808c4c673aa53c3d8ab37ce54afdfdd938b945748f930fefb420
			3968b3cd1e83cd021ac29b32939137e0d03133b39d942eccda0ae910729e
			1e699100878a7965736fa023e0671b0018d1d3379980cd1bbb27c2e4515a
			6ac707acdfa3829f4cc21128dbadeb794d9e12690245aa83cfc6d28b5145
			1f85ac9aec622c0e553dd9f523bb1f7b721180630d79ae51c7507acf9ad5
			ae9ef85afac9c374b7c43bb2b38319238e4520957567de54f55841bcf860
			4881fbb57caee5f90eaaadd56a79f6672b3d2e933239e5c8b1944e18990a
			ec44cc9cf48e1d79b662ccc5028908732b45f2ae1e4157cef0d647e8e48d
			5674fb82943c61ed8bcdeaa525b35d6fdeb97b0abf301bc4a2c1706d8cf4
			bd8dd6b150932098f96c04010db708930f7e4e45d31425f2c9fb14c009a4
			e44116db175422f8862853209a94c883dc6d8c515b5e3e3d25ed0b10887a
			8473dc9ba6e668a14c8280815a8a1841bdb764a77d61af4b42d7efbd9950
			2641c05619b185d50d7dcf926fd1ace5da895053824d48e1c2b12079f7b0
			38592a5320d4718915bf7cb1a460fc2803b352abcdc0990281241b5b3153
			47e04cc14c81606e536a4581eb63e7b4e23d02c48148e7f430532089d3d6
			860b6eed14d67624089591db296d760c52e6cf2641ba3481780610476c32
			cfca331620b742f94c9cbfc1529eb4d8007b967ce8426d62c9573363084d
			c34c945c4c2aecc0da0d7110c02e21ef7bcaf82d0f22959191e8a9716683
			38848dde80948c76da1914a997a68ed727b7f2f20994a840e44d79990451
			cfedc0e43525a7976d0e6462c5bc1d8866df923e4909a52d5f16b64da827
			a26957a172dc02044a225874630f0b6be57452c981f0117f0b880910c587
			08ac20f4856ffbee6971f2da0100e51ea59b6f2ed7de8a1288e08659cdc4
			193ff63ab890a82a97f11786aa920cc205248e1e32789cf64b78937b1d1d
			b03d452a9493b96fdf872dde44d4f139b2fb3894e7d79ae8c6d6fb2bcb6d
			66bb543eb9a5818d3c48ea1395c0803b3bf5b47b5657fca878561775e4e1
			81f8f9c325d44021663d02bdf55aad66c88f5a9b55d035544d09ce73346e
			4f5ecae6d95b28c971ddec7ca539e9ae11660e929ea2c241064250d67b0b
			a96735571caad49c049169921120970e098adf6a43eced755446015d3869
			45062b38c207af86eeb536b6ad3bd76f6f20505e990f885b4665c9257cc5
			3706421d7fa154a25d741f95979ea453f6cba8d94c263db88a64a20ee34a
			6ac027776f6f34cb5a617200741097937cff43bc3b40c647a8d2a8c01aac
			379be54a16bf52464fd4cb0ab4b47675bfa2d5af05f31080ba143e2027ea
			3b289e2541f7a59dc8c3492c725d79bbb1f6aaf2e06868172143c9cfe499
			816bc90d16f4615079cbd73ffee9eb2ffee97f7ef677af5ffdd1e12f7e7c
			f867af0e9effe8f09fbffafa17af90528282e16abf7bb2b3b17d1b844a95
			14956f2abb94457b657411c547c1d4399f1b57afa6232e41df8c128f201c
			6b6ae2e91fefdcb4366f5bb7ef7e78efd64653beccc9f67e0aed9b1f6d6e
			6cb79adfa6de54f71fec4cced56fc4f3321e52af1811cf94718cafc892de
			8b455e27f3964a9532da524603f608eb8a91641058386403d0e1771181c0
			4075565328813bf20c677335077547cf85293cc036e1800a1461f4c10eee
			5c9390f22e722b06271731c111acaa31e6ac033365744bb6c2c2270dd4ea
			fbbbeacef2fcc38d9ded5bc626a21c3994072e1e11e772728996106c7440
			893c4b09d4e46997f7510ebd09588df6354bdda725400e3d20d997fe4a12
			5b91032beadeca8d4917201978da901d4f8107cf83f63130f3654039c9c0
			4e9fcaf775fa14585f7a748e1423644fe4c81f0371e857b7cd016d762555
			9b72071197d1368159364140d47728872045131a4452e071728a7c2d7217
			73312904689227a922de5cced24ad010bb1191521319c229eb422b933add
			05cf3546dda50c6235f8725dd4c7e09731d2b0da9ab0bb8b47bc3ad3f821
			0570cfcec124f88a63993a493e5405b6dd5e0802323a38540df2e5a52086
			cc12b57c40fc0609433f1cd33dcba17f639643cf70b84719a8a35ac43352
			c561fc06ac9ae06ad6581acb7c5aaf9b7bf26ca9998c30d529c7f10c5dd7
			8e541da633b65196a746b6329e966e06b1c3ca8856ef2b7ee0e47712c767
			2479e345307bcb6d3f5ff26fbc8a4235e411611c08a3277f9f30cabccdce
			b4a72f92336d49bd0b2b203e86e8f74c648851004e0e2210484b51fb1204
			937bc446762003af5442e8c93e6ac3b6131f64ae69596ddcfda8a09805f0
			0a3d340e781f7820956b7081d07deac587ae1ea83a423794634337317b44
			b5b7beff5de519381a90d1836fde6fc90d415d1bd7ee7f9fb0011e44e627
			587dabe6c25f81e7289607da78c334a5e7e6330ee9c9e8d25caec102aaad
			9a1eefc1d5da7ab52f3c37371dfc7d007e3587c045088baf3f75feb17aa5
			fa088f2164993ce482268fcc8033cf3631b23bd9e4bb4e0a77ddfe3ca221
			69346ef4893d30be835dea18f798a06e93f929dd8a6b088c0c298d2a0779
			87b80a5bc1a320f98158f26dd9116ceadea3a0b65e836c4355f30cc80377
			c6e711913fecf82ed0253da57ed4d7846074539f11228ed1a28fc97e5b2c
			3dd9c2f60004b62ff316c8ad646464b0102e5d70c039d17e4ea9c0909378
			a64d890b3b09a3a14905f1b8b94e6a36595f71eadd9a7385acaeda2b6b6b
			2949c9724c0e2829124302e63648c774f180a86cc488b2fd68ebe6c7d2d3
			1d41c700124007038f148c3a266565e5fdce3aa9af7656baeb9db52beb9d
			e5f5f51c291e0e07b0bdbb0e3a78f9a383972f0f5efcabfa85d3af0efff2
			cfa70746eca4a1dae54d0f50f7288320e33390b0a7c39fab1f78f293a7c7
			e292083c72fc63602674de959a6ee9014ac51dca70386a6435fd50a3b900
			2e93968af9d97d75fa3fcd5096f72b0fa1b39dd2091b72a09e647d469c48
			efd5655defc983d7c93584577d6a2755f93629bd14fdf89283fd40a092d4
			20d074e2eb2175881f5fef924ef90c5c4eac5fc75367623d2f39186b8201
			32e2a655755ac4973f31495a2221df9e2535206fbce830c4a932ed81cd03
			201cdf46c4a1b04b71940a0b299d41c00ed2814055c6d64a70a8c7c08ac7
			6266b0a441d2892095d53b600c102c07e0c6e41b33a8006581d6307a8487
			587d703ba4814003678c16f394e4dc2eed680ae142867f3c487e7ba24994
			ea425251109e0a1c687b199baa47b98d980aa3f51962538b31ad2a19a435
			2986b4a2784d91d2e698c0b49ebdefb855de131693a23ad54b0a1690d045
			413f40c148f4818b30ea8c506c6310a81317b4a68c4c06f43aa88f983ea5
			ad553ab4c760ca02112817edd5ebe8b11f90b3b1c1ac939b5e8c946656e2
			55588a85470bbfeddfbececbbccccbbccccbbccccbbccccbbccccbbccccb
			bccccbbccccbbcfc7f2fff0b19f95f4f00500000
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "http://ftp.riken.jp/Linux/knoppix/knoppix-dvd/${LIVE_FILE}"
#		wget "http://ftp.kddilabs.jp/.017/Linux/packages/knoppix/knoppix-dvd/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	OS_ARCH=`dpkg --print-architecture`
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
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX1_FS.iso ]; then
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 ./knoppix-live/KNOPPIX1_FS.iso
	fi
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/KNOPPIX1_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	rm -f ./knoppix-live/KNOPPIX_FS.tmp  \
	      ./knoppix-live/KNOPPIX1_FS.tmp \
	      ./knoppix-live/filelist.txt
	# -----------------------------------------------------------------------------
	if [ -d ./knoppix-live/rpack.i386 ]; then
		cp -p ./knoppix-live/rpack.i386/*.deb ./knoppix-live/fsimg/var/cache/apt/archives/
	fi
	if [ -d ./knoppix-live/clamav ]; then
		cp -p ./knoppix-live/clamav/*.cvd     ./knoppix-live/fsimg/var/lib/clamav/
	fi
# =============================================================================
	rm -f ./knoppix-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
	sed -i ./knoppix-live/fsimg/etc/adjtime  -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/rc.local -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 bind9 ssh samba"/g'
	# -------------------------------------------------------------------------
	mount --bind /dev     ./knoppix-live/fsimg/dev
	mount --bind /dev/pts ./knoppix-live/fsimg/dev/pts
	mount --bind /proc    ./knoppix-live/fsimg/proc
#	mount --bind /sys     ./knoppix-live/fsimg/sys
	# -------------------------------------------------------------------------
	cp -p ./knoppix-setup.sh ./knoppix-live/fsimg/root
	chroot ./knoppix-live/fsimg /bin/bash /root/knoppix-setup.sh $1 $2
	RET_STS=$?
	# -------------------------------------------------------------------------
#	umount ./knoppix-live/fsimg/sys     || umount -lf ./knoppix-live/fsimg/sys
	umount ./knoppix-live/fsimg/proc    || umount -lf ./knoppix-live/fsimg/proc
	umount ./knoppix-live/fsimg/dev/pts || umount -lf ./knoppix-live/fsimg/dev/pts
	umount ./knoppix-live/fsimg/dev     || umount -lf ./knoppix-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	find   ./knoppix-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb \
	       ./knoppix-live/fsimg/root/knoppix-setup.sh
# =============================================================================
	if [ "${OS_ARCH}" = "i386" ]; then
		LIVE_VOLID="KNOPPIX_8"
		LIVE_VOLID_FS="KNOPPIX_FS"
		LIVE_VOLID_FS1="KNOPPIX_ADDONS1"
	else
		LIVE_VOLID=`volname ./${LIVE_FILE}`
		LIVE_VOLID_FS=`volname ./knoppix-live/KNOPPIX_FS.iso`
		LIVE_VOLID_FS1=`volname ./knoppix-live/KNOPPIX1_FS.iso`
	fi
	pushd ./knoppix-live/fsimg > /dev/null
		find usr/share/ -maxdepth 1 -type d \
			| grep -v -e "/$" \
			| grep -e "/backgrounds$\|/blender$\|/carddecks$\|/denemo$\|/dia$\|/doc$\|\
				/dvb$\|/edict$\|/emacs$\|/etoys$\|/fonts$\|/foomatic$\|/games$\|/gcompris$\|\
				/gimp$\|/gir-1.0$\|/gnome$\|/help$\|/hplip$\|/i18n$\|/ibus-table$\|/icons$\|\
				/inkscape$\|/java$\|/jitsi$\|/kde4$\|/kdenlive$\|/kf5$\|/kiten$\|/kstars$\|\
				/libreoffice$\|/locale$\|/man$\|/matplotlib$\|/maxima$\|/midi$\|/mlt$\|\
				/mythes$\|/nmap$\|/opencv$\|/perl$\|/perl5$\|/phpmyadmin$\|/pixmaps$\|\
				/poppler$\|/proj$\|/qt4$\|/qt5$\|/scilab$\|/scribus$\|/shutter$\|/sounds$\|\
				/tesseract-ocr$\|/texlive$\|/texmacs$\|/texmf$\|/thunderbird$\|/trans$\|\
				/tuxmath$\|/tuxtype$\|/vim$\|/wallpapers$\|/xfig$\|/xml$\|/xul-ext$\|/zsh$" \
			| grep -v -e "/edict$\|/fonts$\|/icons$\|/kiten$\|/locale$\|/qt4$" \
			| sort -u | awk '{print $1"/";}' > ../filelist.txt
		rm -f ../KNOPPIX_FS.tmp ../KNOPPIX1_FS.tmp
		# ---------------------------------------------------------------------
		xorriso -as mkisofs                 \
		    -D -R -U -V "${LIVE_VOLID_FS}"  \
		    -o ../KNOPPIX_FS.tmp            \
		    -exclude-list ../filelist.txt   \
		    .
		# ---------------------------------------------------------------------
		xorriso -as mkisofs                 \
		    -D -R -U -V "${LIVE_VOLID_FS1}" \
		    -o ../KNOPPIX1_FS.tmp           \
		    -path-list ../filelist.txt
		# ---------------------------------------------------------------------
		rm -f ../filelist.txt
	popd > /dev/null
	# -------------------------------------------------------------------------
	create_compressed_fs -B 128K -t 4 -f ./isotemp  -q -L 9 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX  < ./knoppix-live/KNOPPIX_FS.tmp
	create_compressed_fs -B 128K -t 4 -f ./isotemp1 -q -L 9 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 < ./knoppix-live/KNOPPIX1_FS.tmp
	ls -lh ./knoppix-live/cdimg/KNOPPIX/KNOPPIX*
	# -------------------------------------------------------------------------
	cp ./knoppix-live/efiboot.img ./knoppix-live/cdimg/
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/cdimg/efiboot.img ./knoppix-live/media
	sed -i ./knoppix-live/media/boot/syslinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/media/boot/syslinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		sudo xorriso -as mkisofs                                     \
		             -D -R -U -V "${LIVE_VOLID}"                     \
		             -o ../../${LIVE_DEST}                           \
		             -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin   \
		             -b boot/isolinux/isolinux.bin                   \
		             -c boot/isolinux/boot.cat                       \
		             -no-emul-boot                                   \
		             -boot-load-size 4                               \
		             -boot-info-table                                \
		             -iso-level 4                                    \
		             -eltorito-alt-boot -e efiboot.img -no-emul-boot \
		             .
	popd > /dev/null
	ls -lh KNOPPIX*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
