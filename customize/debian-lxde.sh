#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [Debian 9.7.0]                                          *
# *****************************************************************************

	LIVE_VNUM=9.7.0

# == tools install ============================================================
	apt-get -y install debootstrap xorriso squashfs-tools

# == initial processing =======================================================
#	cd ~
	rm -Rf   ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
# -----------------------------------------------------------------------------
#	tar -cz debian-setup.sh | xxd -ps
	if [ ! -f ./debian-setup.sh ]; then
		cat <<- _EOT_ | xxd -r -p | tar -xz
			1f8b08008181495c0003ed5b7b73dbc611f7bfd4a7b852b2293b0641cab2
			dbc8a6271e478e553f2bc96d12d3858fc0918409e0101c4089b195194bd3
			3469d2e631ad334d339dc94c1e6e5227e9749a699a4ef26118cae9b7e8ee
			0124019212f5a026d30e576309b8c7eff676f7f66e6f6183954cea2882f9
			819b15d543074139a01fcfcecabf403d7f4fe4f2a7660fe54fcccecc9c80
			b713338772f999d953270f91dc8170d34381f0a947c8218f737fbb76c3ea
			ff4769f2476ac974d41215d58949a28c922652605544b153114d92e6fa3f
			9b1b1f37371eb45ef9b2f5cdfbcdf5b737df7bb5f59baf9af73f6ddeff63
			73fdb5a80b0be27dbe6a6ebcdcdcf87773fd5b78ce7df7f587ad0f1e34ef
			3fdc7cef93d667ef3efee62fad0f5eddfcc317cdfb9fb5de587ffcab8f9b
			f73f7efc8ff5effef5f2448ae9554ed2c7464be936ee6d83fa8c3c913efc
			9c7ad8560f1be4f0c5b9c357e60e2fa56f93398266e5939b53b95be90363
			0415467ce6d9a683acec5b6165479f778ce9a3e46e9b6565a40328208ac5
			f9656d6979a930959f9848554de173af41147d6232a5325f574dc7f4b386
			6a94020122e42e9407360f1c9fa806ababae2fc8bd7b242a52ca56a738d9
			9020f5378c35120d31a81114c71ab91ed70734c2e2891fd6bc98631cb071
			a5d8aae993a9bb91c2d626d6427b430d99d4325fdcb73dc48d6c74a86864
			be475d9209cd99e433244f66c809923f89937239accbeb4bf9427a5aafa2
			573f4a6025a522f5faa4adf3ee43a8ef58133092b2b49ece4364379d1660
			6bbeed425dc71823f38bb74063265dbb8e59f280a500de2494bfc5f5d1c8
			2921ffd1a1a2fc0533886212390d89ccb215e6903e2a4ea4f08fc24846a8
			bfbc794e799e2a2fde5227c911b592d9a6e924294edfa1da4faf676f2c5f
			507e42e4efe251b598c77e7d4d99a3dd581ad474221572a7007713a9c0c5
			25a78445e4f2b9abcf1462832467b56a54546b5530214ceea8979f7d7a5e
			a581cf43afbf25e753f429d8e0566b251bec53b16883073eb9038fdcf501
			87e8be67cd8915eaea54b04ca86f9b1b01b0633a806d59fbd14f5cdfa343
			5570f584a2c972cfac84f2f198e0563dab73a71ccddca13613ccab338fe4
			b3f2a7e824ca72f093079550d727a12a22012a2ff45bce703a7204251f82
			553c6ab00e98d2d8075839b02ca58db85fb0b6f8f7c119e918984f454d31
			98a8c1b619be583046e779d560c95ad7331d5f89c43f104c886abb5ebeaf
			b052e2fd0e75a9030a4cbe7546e98059757b8640ad5e6533440f3c8b78a2
			e1e804fdaf6d06368123a8f164e09b96208e1faade61fe0af76a8a0d8653
			910c466082da254a845dd22d93812fd5cdb250a2bef0a473db8695848f35
			e639cc6a732c02834b4605b33a602020d30f4093259d186eada2780cd8ac
			9152605a8602ab1b46806d89b80c98b6cc12b457b0997cef9519d49b5c71
			fd86d26e0e9300215a8c367a7a0cd7a6096e5fb1f98b3aa98b32c884e816
			b5699d9842578caaeeb6a7851c892a5f51e0057d91206543b7b8c3929c39
			c1aa526560b39e50a86d9c9a45f6985556707fc289057e95398a4bed90d3
			55ee79a6e0301c979d636080cedd48e2e28500220790b5cf39bc721730ea
			f6a0b79855c4396b9b8062e5734e6807b02a0c54ec4ea9bb9cd0037bcce6
			759cfc7ed72682e9a03ab96ded17ac03b4773038830258fb4c8347897a9f
			ab1dec80c37dc460651a58e00dc17032a039e6fba653d98be78fef23a343
			55d271dc2c46a49e3e8a88147075ea93336714a2cd5f5bd6c8d9b3a18844
			8d596a34d004c69a38f0e63b1f6ebef7d7ef3ff9f3e6835fb71ebdd37a1d
			62cdb75a9f7ff3f8d10322e79ec2bd99a48b537797e717afaca5c15ca110
			3594962b254d8e92e894298f10e74f9f8eea8f41cd0092f54c50e421eaf8
			ccf2256de18a76e5dad3372ecf17d01574eb9e85d2850b0bf38b4b85a74c
			bba7f267cbbdfde4941392ad9bf668043b40b271c1ca7180350ce99dc02e
			c57719292e721d7720028e071d146b37321d52f63854f03261b067c8ca6c
			04e4d312868585d904d0d5b0277410e0be99004ce08b9233cbb474160171
			8cb209071e1dcfdfe023b9d746b42006ed55499a5cc6523824b139b204de
			558e4ba820e797172f2b0be01689610a174e70cc38de7e24538496215a96
			c119f012e71b47d1abd41305409a2b9ed5e4284b3e48a002ec725c40c868
			061b66e4c884020c302a99bf378715f7086e6f50de8675f80a863a3dcc2f
			435c4dda47ca2a752a20113909b6ea27586fc3e00622874cc02c9491a305
			0796b67f9c2c32e8a333020cfddc14016c8ab2871ba0a0e11827609b263c
			14b545859f9c3e14c051c70f446126ce2723756a050ca5e5c798369d3294
			3aa8c915d896ba982bb037c044564c38345529f8794a42d8d082a8b5421b
			223bc0e8f1d47150ee246ef4e138306b8c22702ef008e16305dcb1504ad4
			8357dca120ccf04d9ba17470ef669ec7bd886be9ac71eb24759b841be97e
			d88d4b6174a82805bb66981e515ca2da8eaf562b65910c91caa099d26e76
			b82d28113f65ab1063cda9dd31e1402e58b66ee3b382cf6004165fd138d8
			8c771c37712d7064d47d3cdaab04c9915c145c99b6823ba4b9b71d2b21e7
			c9f86dc6c8606574158303dfa89bfe6ac87d7424dcf71868256699dc244a
			39545d08ac96c16aabf81cc671b74ee342448beece74742ca04925ec6730
			13c568338dee0cae72df2c37ce43b5a14e1e51217c2c9ba1702078314673
			a1dd231c00c67f8616e96490584637789f587a87dff92a8acbed3a5eeafa
			8b9cfb977905bc7cf698da5bd46042cd6c0f33799d0a01619a714e860fbe
			19fa3cd9759baa4c0246bd084bfa126b9022ceaf889393bf345cea1ad30d
			41b51a6ba8461f33bb8131664e9ecc3f3918280e33456f08f6f4d525d85a
			8bce42c58180020abc4bb0d33a380244993c666532341b899e7bac2c8cfa
			b65e78a31b585a98cf033869857edb77f1342fc2044cb22ec6d536b5f25a
			55c3030b9eaac3d7e6fadbdf3ffc5beb8dcfc34c4f73e32399d3f9127fdf
			ffacb9f1894cf4bc321010d989e0006ff3771f3efef2ddcdd7de6ebdf9d1
			1ec04ad47198a1319b42003b18ef3f7ffabaf5e8cde6c6fb88b7f16973e3
			ebe6c65b12f27359f2ead04124bae6464b40c028add7bf6dbdf9dbe6c6a3
			e6fa17cdf50f9a1b7f7ffcfb8780b3dbb14698a4c358a60a8738923b95cb
			25753f6081c825d2679a431b756d61eb461dfd6e8794d0db568d7ae43e72
			7925ce376d59257d22ce57de60670e74f42d9430847a7681e2344a9d39c5
			a385ecb129b5982f5cbdd6eff3778aa2996efd5417eab9f9a56db1fa50a8
			c39d061cd584c61c5ab2d88eb8eae705afeffb108630d38332599c5ef14c
			9fed12a61f256426b0a9a87541723333bbe0a5380dc7ec28beda8560fa50
			c05635c90e061e7b9c51717ab5cc3c8b577627983e14b05a87e9be0671be
			ade1c58536931b8ad52fdd3633c2373408946dea0f974c3f8a69584c8b32
			391a0a8707319c13b9dc00a07e1483fa548be6b505501f4e3f0a15ba696a
			816b716aec54c65ba140a0ecec1ca71fa5edba4313064fb703b3db1ac5c4
			43d80ead378692162ff5a2e03d4e88f112606cb1d9bc941eb41a85e63188
			d0c52e16769fedbad4d6f0eeddd49986f9ab2e46c8c54098e409d3d75d0d
			ef6d5cd83d70e4e11e77100aaa2426d61d036d816230a7b10b66e23a2ac6
			60503b85f004debbbba787f1224f23bb9d4e1f0a7802508dc1435e762ee0
			244acfead9234a28020d9d94140c08857a4515dedbe22966e165dbd508bc
			04b002bb5e17d6cdce249344110db1078c5e143915dfd55c8ffb5ce7d64e
			817a740408d263a2f32fcce4f6c60b9cf3ea71fd74c332f403f2fe74df79
			89f8fdd9e85031e6c2abdd1b4bf38bdad57357e6f1a6358df850617098a5
			acb978edca7ce1365da911e502c9cc6560d2f942219d99badbe9b8964993
			bb32954ba64e9d5ecb84a7437902366ee3e5638057115107c45bc30b4bfc
			d4c4092c0bcfd007957449f5a75dbac9969da75bb648b80c4fb90c4fba74
			d22edb275e86a45e86275f5207967ee99331e9a45de289177cdb75baa527
			e12221f69a68e92641425646995ed922c192da677a259e600999de555a25
			995891fd47944fe9cfa884cc1d6c2e257560d9940136dcc9a224f2287d99
			94de5cca806c4a82ef115fcba79217f36d7710e645b2aba603bacc1a5864
			394411a1677e369f5757f1d33eb5dd40951f99753b84ef522e301be8b948
			e2fe7e2efed2edd571de9183e9cad0e5ae91f4f90677583b83c0a8b3d784
			7d822612498151a1a27de0172e15fc2cbc11fbc0a35bdcf94ea35b14bd96
			c1c0091eb8f0bca512c56fb8e09c4055706a27c563708858653ad15d79e7
			da960eb9bb468aa73b1f5ae44239cd5fbb30a29b1cc01be987ba8077c606
			919c8507426e762cf2967c27e4bc7454e41275ee98a1c7bdf90bb9f005a9
			b1c6ad276e2ea12397cfcad99bcf33a7466b817a91cabfb278e41cffd0ff
			e7614c631ad398c634a6318d694c631ad398c634a6318d694c631ad398c6
			34a6318d694c631ad398fe1fe9bf5e589c6a00500000
_EOT_
	fi
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ]; then
		wget "http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
#		wget "http://ftp.riken.jp/.2/debian/debian-cd/current-live/amd64/iso-hybrid/debian-live-${LIVE_VNUM}-amd64-lxde.iso"
	fi
	LIVE_VOLID=`volname ./debian-live-${LIVE_VNUM}-amd64-lxde.iso`
# -----------------------------------------------------------------------------
	mount -r -o loop ./debian-live-${LIVE_VNUM}-amd64-lxde.iso ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/live/filesystem.squashfs.orig ]; then
		mv ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/cdimg/live/filesystem.squashfs.orig
	fi
# -----------------------------------------------------------------------------
	mount -r -o loop ./debian-live/cdimg/live/filesystem.squashfs.orig ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./debian-live/media
# -----------------------------------------------------------------------------
	cp -p debian-setup.sh ./debian-live/fsimg/root
	chmod u+x ./debian-live/fsimg/root/debian-setup.sh
	LANG=C chroot ./debian-live/fsimg /bin/bash /root/debian-setup.sh
	rm -f ./debian-live/fsimg/root/debian-setup.sh
# -----------------------------------------------------------------------------
	rm -rf ./debian-live/fsimg/tmp/* ./debian-live/fsimg/root/.bash_history ./debian-live/fsimg/root/.viminfo ./debian-live/fsimg/var/cache/apt/*.bin ./debian-live/fsimg/var/cache/apt/archives/*.deb
# -- file compress ------------------------------------------------------------
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs -comp xz -wildcards -e *.orig
	ls -lht ./debian-live/cdimg/live/
# -----------------------------------------------------------------------------
	if [ ! -f ./debian-live/cdimg/isolinux/menu.cfg.orig ]; then
		chmod +w ./debian-live/cdimg/isolinux/menu.cfg
		sed -i.orig ./debian-live/cdimg/isolinux/menu.cfg                                                 \
		    -e 's/locales=ja_JP\.UTF-8/& timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp/g'
	fi
# -- make iso image -----------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		xorriso -as mkisofs \
		    -r -J -V "${LIVE_VOLID}" -D \
		    -o ../../debian-live-${LIVE_VNUM}-amd64-lxde-custom.iso \
		    -b isolinux/isolinux.bin \
		    -c isolinux/boot.cat \
		    -cache-inodes \
		    -no-emul-boot \
		    -boot-load-size 4 \
		    -boot-info-table \
		    -m *.orig \
		    -iso-level 4 \
		    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
		    .
	popd > /dev/null
	ls -lht
# =============================================================================
