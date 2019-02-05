#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [debian-live-[version]-[architecture]-lxde.iso]         *
# *****************************************************************************
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "$0 [i386 | amd64] [9.x.0 | testing | ...]"
		exit 1
	fi

	LIVE_ARCH="$1"
	LIVE_VNUM="$2"
	LIVE_FILE="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso"
	LIVE_DEST="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde-custom.iso"
	# -------------------------------------------------------------------------
	case "${LIVE_VNUM}" in
		"testing" | "buster"  | 10* ) LIVE_SUITE="testing";;
		"stable"  | "stretch" | 9*  ) LIVE_SUITE="stable";;
		*                           ) LIVE_SUITE="";;
	esac
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
			1f8b08004d81595c0003ed5afb731bc51dcfafd65ff1adec444ec8e92439
			498b893d64820137cfda4e0b44e9b1ba5b4917dfed1db77bb2050933b6a7
			140a2d8f69c394329d618657a1013a9d32a574e08f1172e87fd1efeee9e4
			d32b7e29433b735f8fa5bb7d7cf6bbdfe73e94d72d5ab109d33815a19fe7
			f523e3a702d28f4f9d52df487ddfa5d3a533c523c59953a533a599995209
			db154b67664e1f81c203e06580422e48007024f03c71bf76bbd5ff9fd2e4
			8ff48acdf40ae1f5cc2468e3a4cc04da1468ee448726a1b5f9cfd6d647ad
			ad3bed97bf6c7ff35e6bf3aded775f69ffe6abd6c6a7ad8d3fb6365fed74
			a161b2cf57adad975a5bff6e6d7e8bcf85efbefea0fdfe9dd6c6c7dbef7e
			d2feec9d7bdffca5fdfe2bdb7ff8a2b5f159fbf5cd7bbffaa8b5f1d1bd7f
			6c7ef7af973213d4ac7b903d315ecac6b8cf5a445078287bf469fda8ab1f
			b5e0e893b3472fcd1e5dce3e0bb320cd4ac0f5a9c28dec0363442a0c040d
			5c9b49560eadb02a331798357d1c5e8859d6c63a8086a2585a5831965796
			e7a68a99cc44dde6c20b9aa09999c9099d0a53b7992df2966e55428e22f4
			7c2c0f5d2f6402305035745f70b8750b3a455ad5e916f7360449830d138d
			78930f6b84c589467ee099431ac9e2cc0f6b5e94590fd8b826e8ba2d60ea
			858ec26e676e47f626356413c77efed0f69034b2f1a14a231301f1211799
			331473508412cc40f1b49c94efa15f5e5d2ece65a7cdba8ceac7013d69a2
			a35e01b1ce771e227d279aa0915495f5741f3a76d36d81b6265c1febbac6
			d831bf640b69ccb063d7094b1ee20a184d22f93b9e391e39f5c87f7ca852
			fe9c5aa0d9a0a6a19069be46190c50393321bf340a39aefff2fa39ed19a2
			3d7f439f84637a2d779fa693509ebe498c9f5ecd5f5b795cfb09a8cff271
			bd5c94fd069a52665c5b1ed634331171a721779989d0972ea7454570f1dc
			e527e61283a05a92d35ab76abab3ce29e7b6c7f48b4f3db6a093507851d8
			ef677db2cbd014791453dcfa6ac5450bd51cd2f4420137f1d1f305028129
			026796af11df249ce6228dbb9e152243364370c7398c86921a1f1faa96ed
			ca26ef05762d125040b9e734f2a6c7aa9d9933e2524e83060da098577f65
			d65356c0bf62aed77c882f74ee85814979dec174811e818b15aa9e63c329
			4fe32216f227945a81794cab0694020e2d02bba2f48c3010e9b7a314edb9
			4173dc9d8e1d93d61581d50262d12e98d63c045835741c2d463c2c58acd1
			4370065d7f1384af6a16e5ab988ba3979bc4270c75d6fbd6dbc6413ef079
			2898b36ef5b5f6039b09ad6305aa84f37acffb1aadc4ef5d301cd8acd312
			7e63dfbab7a661adf4452e4b6c11a2242b26e0e2d67a38fa0c85edf011d3
			ac84b66369e8cc94c934043233b876e8761f34a75840efb4ab5c8b704c87
			b8a43114cc0c03072c7fb5a60514995c85aa653a1e435fc350aeb9def326
			eac8c291c0e6a666d54d3f9e9c8d2e63b3703d01e6d815394389e653c495
			efa1a853a6f9c4ed1651a7aac94c838fb6a7f9a219d5f47386d58ca2b8b8
			434933ee8ce369758a9617708db8d69953e034dc1260c3352f58d55cf4db
			9a127c1f184359989eeb62d4928fab3460d48967c244e46c9e8f9c365c4d
			78dea0f013603dedbae6a1380c789399c0895b21c0dd8ae9d85274fcb910
			f72c386e84cc43cbebb1334e1d68f02ab201eb5e10a064f766f71dda7127
			19d503ea7a0de9eb87f54d0966a2f0552e3c2c5817e8e060b8b045b078a1
			24d7278d81e83d3ca647a949aa0d1a2e444a384c0e49a6a6f1a1cac588bb
			6ad901683ee82e137abd56e59db13406b97c1d53f6acbe5387b118b34bc3
			95cf9a7c068ca5de9ae1a1cf0527a5fe8c90a955dc498b5649e8e0caad00
			05b5ea989f8fc454c5005c8904d40913879a432c20bb0ad77103128d1101
			eb98e8785d3e4789f6c623206343662221cdf1b120a5d9939c8733819248
			2eeb2e7bc2ae36cf63b5a54f1ed3311957ed483818e6adf19c39f4090781
			e5bf65487ed0788789657c830f88a57ff891d427a9f2f455b9d7164bb82b
			b9e8d56c563e8eab1ab9a66952aee746769cc48e84730cd7d639951b846d
			12b99c1cec3fd8518db8e062ce883178b71bf3baa30e74bcc6e9d5739746
			72389455fd49f4b60bb4096529a7b21492fa30a4171ad4b43831566953b7
			72fbeb68954e9f2e3e1c774d769c22c8e7639797712a65b6586318cab120
			b8c0bc3526313956242c52e58bb1d8449f4546a968b4938e6f60658dc20b
			cd7a2718091fa358c0a3f3b4deba0457f7a955bb64432eb8e5815cf4dada
			7cebfb8fffd67efdf3e8e0aeb5f5a13aa2fb527e6e7cd6dafa449ddbbd3c
			1450b2d38143bceddf7d70efcb77b65f7dabfdc6870700ab10c6a8655097
			e0aa6c38de7ffef475fbee1badadf724ded6a7adadaf5b5b6f2ac8cf55c9
			2bbb0ea2d00d3ff60f1ca5fddab7ed377edbdabadbdafca2b5f97e6bebef
			f77eff31e2ec77ac319eb9229a59c75d1d14ce140abdba1fe292ca45064c
			73d7463bb630ba5157bff743ead1dba8467d721fbbbc9241bb2babde4827
			e7ab0e24720f74f4114ad88506f287943ac5b03f973f31855179eef295e1
			41792f2886ed37ceec403dbdb07c5fac0114821bf126ae94b84119a93874
			4f5c0df2224f6306107661a60f05b3d55a600bba4f9841948899d0c5fdc5
			0e48a154da072fe5695c8dbab8d3c44dd53e04338082b66a287684ed1e74
			46e5e9f52aeeb0bcdafe0433808256cba8298c2aee950d79be6a940abb62
			0d4a3766860bcba87a814bc4ee921944b12d871a9d7339430ac70b133833
			85c210a04114dcbc12a333af114003388328849bb66d84bee3116baf321e
			8562e18a65ef38832871e88e4c1823dd1ecc6e348a2d975d7bb4de044a96
			bfd88f52b5638c17116344b279313bcc1bb91150330cf83e1c7bc0767de2
			1af2ccc236a9210f237730222e86c2f4ae3085e91b6b01f17dcc1e72e4dd
			23ee3014a9928458f70c3402c5a2acb90f66923a2a2760a476e6a235777f
			76cfeec68b5a8dec773a0328180950359617f1b27701f7a2f479cf015122
			1118324829c1a0504850d6f13d164f398f2ff7f546e425440fdc89bae837
			7b934c2f0a6ff20360f4a3a8a908dff0034f78a6e7ec15a84f4788a022a6
			0cfe73a5c2c178c1755e23a99fc441815b19d3caabffa0409e2aea083f7a
			67d6ad3cfce06a6746b9f049e082c687b2700bd4b250ee796b8e57218e0e
			68bc1cb75d24903f8e9883f3571f9e299559e71cd4f64d706d06b102b1c1
			e59562b77a5855e7887658956dc97ba9ceb1c509988580b01ac5da62a150
			d0e447a1cc7230df954adf8cbad3981f36396c2c9b5513bd630dcb480f84
			5920c34b0e81a81036ab1d40e8c983c4f1a14add61248295734b4f2cac00
			8a2e1b4d70953a597c96236113cbc339e23ea26ec1d40b51dbdb5216f26a
			97858e2337395df634c8cbdfdd04e6984c6bc22402ce9ed520672c5c5931
			504df3f10899e8c73472ccedb73fd87ef7afdf7ff2e7ed3bbf6edf7dbbfd
			da9dd6c69bedcfbfb977f70e28f129208e790067b0b074e97616671b6fce
			20abee0bb2701c3a37e9ea9af4fc238f745b9cc0ba21d46941398999e900
			3cb172c158bc645cbaf2d8b58b0b73f28aa4b7fe29ac597c7c71616979ee
			51db1dd2e0672bfdfdd5f4fb45ddb0ddb1487a84a83b0328d6a49fb2d0ad
			f4dc9a48e1c15579d525638cbc77a17123b4265c3a638557058a695355e6
			bb508254e44f61e64ef5405d8efa6217ee13937244459e089c5d21957909
			294791590add396482039aef0e66627b9ec0bc284b3169d35958ae7b6b6a
			64201cceaf2c5dd416c1e660d9dc7748935a27e34798028cffc889fc490a
			72d3cbbb1c4785ae39c49a9d37a2719605caa1862c7bd23325b339d930a7
			c6560e2b7d4d4ee0d6acacb805f2a209cb77809927975cfd1358a9238ff1
			557a5dc62e0e6a22745df4b0bf0324ef0ed5b03d408b55c9d5a28c95e224
			2c51ec655240a67e6e734cdf11a37e2805ded9cc811789dc215cf40b018b
			b82022e473a524af141ac409a9949a48306eb32a9632a9d335cc463ba86b
			36c3750c7e390ed449032505116c644dc459234d9e1f6efef252f201469a
			78003567b9c79033512f98626a018a48ab904015c8cb344135b9a38a2424
			2f6f691078419773dff3addeb069798cc6372a94b00306f15ecaf45c928c
			0b55658ae842ad1071bc70e5f171ad5e2661acbff242bcb32eaa631e1f00
			aedbae16a5fe1bea1de0bc7221b840d84d3b8a0bd77fa16c90c32a6dde78
			e8fab20c3dea599bbffe0c65ab6435d49f24ea5b158f9de31ffa07b329a5
			94524a29a594524a29a594524a29a594524a29a594524a29a594524a29a5
			94524a29a594524a29a5f43f44ff051c72de4f00500000
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		case "${LIVE_SUITE}" in
			"testing" ) LIVE_URL="http://cdimage.debian.org/cdimage/weekly-live-builds/${LIVE_ARCH}/iso-hybrid/debian-live-testing-${LIVE_ARCH}-lxde.iso";;
			"stable"  ) LIVE_URL="http://cdimage.debian.org/cdimage/release/current-live/${LIVE_ARCH}/iso-hybrid/debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso";;
			*         ) LIVE_URL="";;
		esac
		wget "${LIVE_URL}"
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
	if [ -d ./debian-live/rpack.${LIVE_SUITE}.${LIVE_ARCH} ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		cp -p ./debian-live/rpack.${LIVE_SUITE}.${LIVE_ARCH}/*.deb ./debian-live/fsimg/var/cache/apt/archives/
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
	if [ "${LIVE_ARCH}" == "i386" ]; then
		sed -i ./debian-live/fsimg/root/debian-setup.sh    \
		    -e 's/linux-headers-amd64/linux-headers-686/g'
	fi
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
	sed -i ./debian-live/cdimg/boot/grub/grub.cfg                                                                                                  \
	    -e 's/\(linux .* components\) \("${loopback}"$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                                                                               \
	    -e 's/\(APPEND .* components$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/'
	# -------------------------------------------------------------------------
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs -mem 1G -noappend -b 4K -comp xz
	ls -lht ./debian-live/cdimg/live/
	# -------------------------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		find . -type f -exec md5sum {} \; > ../md5sum.txt
		mv ../md5sum.txt .
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
