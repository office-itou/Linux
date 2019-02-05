#!/bin/bash
# *****************************************************************************
# debootstrap for stable/testing cdrom
# *****************************************************************************
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "$0 [i386 | amd64] [stable | testing | ...]"
		exit 1
	fi

#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了

	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# =============================================================================
	echo "-- initialize -----------------------------------------------------------------"
	rm -rf   ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg ./debootstrap/_work
	mkdir -p ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg ./debootstrap/_work
# -----------------------------------------------------------------------------
	INP_ARCH=$1
	INP_SUITE=$2
	INP_NETWORK=$3
	if [ "${INP_ARCH}" = "i386" ]; then
		IMG_ARCH="686"
	else
		IMG_ARCH="amd64"
	fi
	echo "-- architecture: ${INP_ARCH} --------------------------------------------------------"
# =============================================================================
	echo "-- make inst-net.sh -----------------------------------------------------------"
	cat <<- _EOT_SH_ > ./debootstrap/fsimg/inst-net.sh
		echo "--- module install ------------------------------------------------------------"
		cat <<- '_EOT_' > /etc/apt/sources.list
			deb http://ftp.debian.org/debian ${INP_SUITE} main non-free contrib
			deb-src http://ftp.debian.org/debian ${INP_SUITE} main non-free contrib
			
			deb http://security.debian.org/debian-security ${INP_SUITE}/updates main contrib non-free
			deb-src http://security.debian.org/debian-security ${INP_SUITE}/updates main contrib non-free
			
			# ${INP_SUITE}-updates, previously known as 'volatile'
			deb http://ftp.debian.org/debian ${INP_SUITE}-updates main contrib non-free
			deb-src http://ftp.debian.org/debian ${INP_SUITE}-updates main contrib non-free
		_EOT_
		echo "---- module update, upgrade, install ------------------------------------------"
		apt update                                                             && \\
		apt upgrade      -q -y                                                 && \\
		apt full-upgrade -q -y                                                 && \\
		apt install      -q -y                                                    \\
		    apache2 apt-show-versions aptitude bc bind9 bind9utils bison chromium \\
		    chromium-l10n cifs-utils clamav curl dpkg-repack fdclone flex         \\
		    ibus-mozc indent isc-dhcp-server isolinux libapt-pkg-perl             \\
		    libauthen-pam-perl libelf-dev libio-pty-perl lvm2 network-manager     \\
		    nfs-common nfs-kernel-server ntfs-3g ntp ntpdate open-vm-tools        \\
		    open-vm-tools-desktop samba smbclient task-ssh-server task-web-server \\
		    vsftpd xorriso                                                        \\
		    build-essential grub-efi libnet-ssleay-perl perl rsync squashfs-tools \\
		    sudo                                                                  \\
		    task-desktop task-japanese task-japanese-desktop task-laptop          \\
		    task-lxde-desktop task-ssh-server task-web-server                     \\
		    live-task-lxde wpagui blackbox xterm nano                             \\
		    linux-headers-${IMG_ARCH} linux-image-${IMG_ARCH}                     \\
		    vim wget less traceroute btrfs-progs dnsutils ifupdown usbutils       \\
		    powermgmt-base task-english
_EOT_SH_
	cat <<- '_EOT_SH_' >> ./debootstrap/fsimg/inst-net.sh
		echo "---- module fix broken --------------------------------------------------------"
		apt install      -q -y --fix-broken
		echo "---- module autoremove, autoclean, clean --------------------------------------"
		apt autoremove   -q -y                                                 && \
		apt autoclean    -q                                                    && \
		apt clean        -q
		# -----------------------------------------------------------------------------
		systemctl  enable clamav-freshclam
		systemctl  enable ssh
		systemctl disable apache2
		systemctl  enable vsftpd
		systemctl  enable bind9
		systemctl disable isc-dhcp-server
		systemctl disable isc-dhcp-server6
		systemctl  enable smbd
		systemctl  enable nmbd
		# -----------------------------------------------------------------------------
		echo "--- localize ------------------------------------------------------------------"
		if [ -f /etc/locale.gen ]; then
			sed -i /etc/locale.gen                  \
			    -e 's/^[A-Za-z]/# &/g'              \
			    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
			    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
			locale-gen
			update-locale LANG=ja_JP.UTF-8
		fi
		# -----------------------------------------------------------------------------
		echo "--- root and user's setting ---------------------------------------------------"
		for TARGET in "/etc/skel" "/root"
		do
			pushd ${TARGET} > /dev/null
				echo "---- .bashrc ------------------------------------------------------------------"
				cat <<- '_EOT_' >> .bashrc
					# --- 日本語文字化け対策 ---
					case "${TERM}" in
					    "linux" ) export LANG=C;;
					    * )                    ;;
					esac
					# export GTK_IM_MODULE=ibus
					# export XMODIFIERS=@im=ibus
					# export QT_IM_MODULE=ibus
				_EOT_
				echo "---- .vimrc -------------------------------------------------------------------"
				cat <<- '_EOT_' > .vimrc
					set number              " Print the line number in front of each line.
					set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
					set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
					set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
					set nowrap              " This option changes how text is displayed.
					set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
					set laststatus=2        " The value of this option influences when the last window will have a status line always.
				_EOT_
				echo "---- .curlrc ------------------------------------------------------------------"
				cat <<- '_EOT_' > .curlrc
					location
					progress-bar
					remote-time
					show-error
				_EOT_
			popd > /dev/null
		done
		# --- open-vm-tools -----------------------------------------------------------
		echo "--- open vm tools -------------------------------------------------------------"
		mkdir -p /mnt/hgfs
		sed -i /etc/fstab                                                                   \
		    -e '$a.host:/ /mnt/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults 0 0'
		# -- sshd ---------------------------------------------------------------------
		echo "--- sshd ----------------------------------------------------------------------"
		sed -i /etc/ssh/sshd_config                                        \
		    -e 's/^PermitRootLogin .*/PermitRootLogin yes/'                \
		    -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \
		    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'                 \
		    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d'               \
		    -e '$aUseDNS no\nIgnoreUserKnownHosts no'                      \
		    -e 's/^UsePrivilegeSeparation/#&/'                             \
		    -e 's/^KeyRegenerationInterval/#&/'                            \
		    -e 's/^ServerKeyBits/#&/'                                      \
		    -e 's/^RSAAuthentication/#&/'                                  \
		    -e 's/^RhostsRSAAuthentication/#&/'
		# -- ftpd ---------------------------------------------------------------------
		echo "--- ftpd ----------------------------------------------------------------------"
		touch /etc/ftpusers					#
		touch /etc/vsftpd.conf				#
		touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
		touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
		touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
		touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
		chmod 0600 /etc/ftpusers               \
		           /etc/vsftpd.conf            \
		           /etc/vsftpd.chroot_list     \
		           /etc/vsftpd.user_list       \
		           /etc/vsftpd.banned_emails   \
		           /etc/vsftpd.email_passwords
		sed -i /etc/ftpusers \
		    -e 's/root/# &/'
		sed -i /etc/vsftpd.conf                                           \
		    -e 's/^\(listen\)=.*$/\1=NO/'                                 \
		    -e 's/^\(listen_ipv6\)=.*$/\1=YES/'                           \
		    -e 's/^\(anonymous_enable\)=.*$/\1=NO/'                       \
		    -e 's/^\(local_enable\)=.*$/\1=YES/'                          \
		    -e 's/^#\(write_enable\)=.*$/\1=YES/'                         \
		    -e 's/^#\(local_umask\)=.*$/\1=022/'                          \
		    -e 's/^\(dirmessage_enable\)=.*$/\1=NO/'                      \
		    -e 's/^\(use_localtime\)=.*$/\1=YES/'                         \
		    -e 's/^\(xferlog_enable\)=.*$/\1=YES/'                        \
		    -e 's/^\(connect_from_port_20\)=.*$/\1=YES/'                  \
		    -e 's/^#\(xferlog_std_format\)=.*$/\1=NO/'                    \
		    -e 's/^#\(idle_session_timeout\)=.*$/\1=300/'                 \
		    -e 's/^#\(data_connection_timeout\)=.*$/\1=30/'               \
		    -e 's/^#\(ascii_upload_enable\)=.*$/\1=YES/'                  \
		    -e 's/^#\(ascii_download_enable\)=.*$/\1=YES/'                \
		    -e 's/^#\(chroot_local_user\)=.*$/\1=NO/'                     \
		    -e 's/^#\(chroot_list_enable\)=.*$/\1=NO/'                    \
		    -e 's~^#\(chroot_list_file\)=.*$~\1=/etc/vsftpd.chroot_list~' \
		    -e 's/^#\(ls_recurse_enable\)=.*$/\1=YES/'                    \
		    -e 's/^\(pam_service_name\)=.*$/\1=vsftpd/'                   \
		    -e '$atcp_wrappers=YES'                                       \
		    -e '$auserlist_enable=YES'                                    \
		    -e '$auserlist_deny=YES'                                      \
		    -e '$auserlist_file=/etc/vsftpd.user_list'                    \
		    -e '$achmod_enable=YES'                                       \
		    -e '$aforce_dot_files=YES'                                    \
		    -e '$adownload_enable=YES'                                    \
		    -e '$avsftpd_log_file=/var/log/vsftpd.log'                    \
		    -e '$adual_log_enable=NO'                                     \
		    -e '$asyslog_enable=NO'                                       \
		    -e '$alog_ftp_protocol=NO'                                    \
		    -e '$aftp_data_port=20'                                       \
		    -e '$apasv_enable=YES'
		# -----------------------------------------------------------------------------
		echo "--- smb.conf ------------------------------------------------------------------"
		testparm -s /etc/samba/smb.conf | sed -e '/homes/ idos charset = CP932\nclient ipc min protocol = NT1\nclient min protocol = NT1\nserver min protocol = NT1\nidmap config * : range = 1000-10000\n' > smb.conf
		testparm -s smb.conf > /etc/samba/smb.conf
		rm -f smb.conf
		# -----------------------------------------------------------------------------
		echo "--- localize ------------------------------------------------------------------"
		sed -i /etc/xdg/lxsession/LXDE/autostart               \
		    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
		# -----------------------------------------------------------------------------
		echo "--- cleaning and exit ---------------------------------------------------------"
_EOT_SH_
# =============================================================================
	echo "--- debootstrap ---------------------------------------------------------------"
	LIVE_VOLID="d-live ${INP_SUITE} lx ${INP_ARCH}"
	if [ "${INP_NETWORK}" != "" ]; then
		echo "---- network install ----------------------------------------------------------"
		debootstrap --merged-usr --arch=${INP_ARCH} --variant=minbase ${INP_SUITE} ./debootstrap/fsimg/
	else
		echo "---- media install ------------------------------------------------------------"
		case "${INP_SUITE}" in
			"testing" | "buster"  | 10* ) LIVE_MEDIA="./debian-testing-${INP_ARCH}-DVD-1.iso";;
			"stable"  | "stretch" | 9*  ) LIVE_MEDIA="./debian-9.7.0-${INP_ARCH}-DVD-1.iso";;
			*                           ) LIVE_MEDIA="";;
		esac
		FSSQ_MEDIA=""
		mount -r -o loop ${LIVE_MEDIA} ./debootstrap/media/
		debootstrap --no-check-gpg --merged-usr --arch=${INP_ARCH} --variant=minbase ${INP_SUITE} ./debootstrap/fsimg/ file:./debootstrap/media/
		umount ./debootstrap/media/
	fi
	# -------------------------------------------------------------------------
	case "${INP_SUITE}" in
		"testing" | "buster"  | 10* ) DEB_SUITE="testing";;
		"stable"  | "stretch" | 9*  ) DEB_SUITE="stable";;
		*                           ) DEB_SUITE="";;
	esac
	if [ -d ./debootstrap/rpack.${DEB_SUITE}.${INP_ARCH} ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		mkdir -p ./debootstrap/fsimg/var/cache/apt/archives
		cp -p ./debootstrap/rpack.${DEB_SUITE}.${INP_ARCH}/*.deb ./debootstrap/fsimg/var/cache/apt/archives/
	fi
	# -------------------------------------------------------------------------
	echo "-- chroot ---------------------------------------------------------------------"
	echo "debian-live" >  ./debootstrap/fsimg/etc/hostname
	echo -e "127.0.1.1\tdebian-live" >> ./debootstrap/fsimg/etc/hosts
	rm -f ./debootstrap/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./debootstrap/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./debootstrap/fsimg/dev     && \
	mount --bind /dev/pts ./debootstrap/fsimg/dev/pts && \
	mount --bind /proc    ./debootstrap/fsimg/proc
	# -------------------------------------------------------------------------
	LANG=C chroot ./debootstrap/fsimg/ /bin/bash /inst-net.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount -lf ./debootstrap/fsimg/proc    && \
	umount -lf ./debootstrap/fsimg/dev/pts && \
	umount -lf ./debootstrap/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
# -----------------------------------------------------------------------------
	echo "-- cleaning -------------------------------------------------------------------"
	find  ./debootstrap/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./debootstrap/fsimg/inst-net.sh                    \
	       ./debootstrap/fsimg/root/.bash_history             \
	       ./debootstrap/fsimg/root/.viminfo                  \
	       ./debootstrap/fsimg/tmp/*                          \
	       ./debootstrap/fsimg/var/cache/apt/*.bin            \
	       ./debootstrap/fsimg/var/cache/apt/archives/*.deb
# -----------------------------------------------------------------------------
	echo "--- download system file ------------------------------------------------------"
	pushd ./debootstrap > /dev/null
		TAR_INST=debian-cd_info-${INP_SUITE}-${INP_ARCH}.tar.gz
		if [ ! -f "./${TAR_INST}" ]; then
			case "${INP_SUITE}" in
				"testing" | "buster"  ) TAR_URL="https://d-i.debian.org/daily-images/${INP_ARCH}/daily/cdrom/debian-cd_info.tar.gz";;
				"stable"  | "stretch" ) TAR_URL="https://cdimage.debian.org/debian/dists/${INP_SUITE}/main/installer-${INP_ARCH}/current/images/cdrom/debian-cd_info.tar.gz";;
				*                     ) TAR_URL="";;
			esac
			wget -O "./${TAR_INST}" "${TAR_URL}"
		fi
		tar -xzf "./${TAR_INST}" -C ./_work/
	popd > /dev/null
	# ---------------------------------------------------------------------
	echo "--- make cdimg directory ------------------------------------------------------"
	mkdir -p ./debootstrap/cdimg/boot/grub \
	         ./debootstrap/cdimg/isolinux  \
	         ./debootstrap/cdimg/live      \
	         ./debootstrap/cdimg/.disk
	# ---------------------------------------------------------------------
	echo "-- make system loading file ---------------------------------------------------"
	NOW_TIME=`date +"%Y-%m-%dT%H:%M"`
	# ---------------------------------------------------------------------
#	echo "--- make efi.img file ---------------------------------------------------------"
#	dd if=/dev/zero of=./debootstrap/cdimg/boot/grub/efi.img bs=256M count=1
#	mkfs.vfat ./debootstrap/cdimg/boot/grub/efi.img
#	mount -o loop ./debootstrap/cdimg/boot/grub/efi.img ./debootstrap/media/
#	mkdir -p ./debootstrap/media/efi/boot   \
#	         ./debootstrap/media/efi/debian
#	cat <<- '_EOT_' > ./debootstrap/media/efi/debian/grub.cfg
#		search --file --set=root /.disk/info
#		set prefix=($root)/boot/grub
#		source $prefix/x86_64-efi/grub.cfg
#_EOT_
#	cp -p ./debootstrap/fsimg/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi ./debootstrap/media/efi/boot/
#	umount ./debootstrap/media/
	# ---------------------------------------------------------------------
	echo "--- make .disk's file ---------------------------------------------------------"
#	echo -en "main"                                                                   > ./debootstrap/cdimg/.disk/base_components
#	echo -en ""                                                                       > ./debootstrap/cdimg/.disk/base_installable
#	echo -en "live"                                                                   > ./debootstrap/cdimg/.disk/cd_type
	echo -en "Custom Debian GNU/Linux Live ${INP_SUITE}-${INP_ARCH} lxde ${NOW_TIME}" > ./debootstrap/cdimg/.disk/info
#	echo -en "xorriso -output /debian-live-${INP_SUITE}-${INP_ARCH}-lxde-custom.iso"  > ./debootstrap/cdimg/.disk/mkisofs
#	echo -en "netcfg\nethdetect\npcmciautils-udeb\nlive-installer\n"                  > ./debootstrap/cdimg/.disk/udeb_include
	# ---------------------------------------------------------------------
	echo "--- copy system file ----------------------------------------------------------"
	pushd ./debootstrap/_work/grub > /dev/null
		find . -depth -print | cpio -pdm ../../cdimg/boot/grub/
	popd > /dev/null
	if [ ! -f ./debootstrap/cdimg/boot/grub/loopback.cfg ]; then
		echo -n "source /grub/grub.cfg" > ./debootstrap/cdimg/boot/grub/loopback.cfg
	fi
	cp -p ./debootstrap/_work/splash.png                                 ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/_work/menu.cfg                                   ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/_work/stdmenu.cfg                                ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/_work/isolinux.cfg                               ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/ISOLINUX/isolinux.bin              ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/hdt.c32      ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/ldlinux.c32  ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libcom32.c32 ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libgpl.c32   ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libmenu.c32  ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libutil.c32  ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/vesamenu.c32 ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/usr/lib/syslinux/memdisk                   ./debootstrap/cdimg/isolinux/
	cp -p ./debootstrap/fsimg/boot/*                                     ./debootstrap/cdimg/live/
	# ---------------------------------------------------------------------
	echo "--- copy EFI directory --------------------------------------------------------"
	mount -r -o loop ./debootstrap/cdimg/boot/grub/efi.img ./debootstrap/media/
	pushd ./debootstrap/media/efi/ > /dev/null
		find . -depth -print | cpio -pdm ../../cdimg/EFI/
	popd > /dev/null
	umount ./debootstrap/media/
	# ---------------------------------------------------------------------
	VER_KRNL=`find ./debootstrap/fsimg/boot/ -name "vmlinuz*" -print | sed -e 's/.*vmlinuz-//g' -e 's/-amd64//g' -e 's/-686//g'`
	echo "--- edit grub.cfg file --------------------------------------------------------"
	cat <<- _EOT_ >> ./debootstrap/cdimg/boot/grub/grub.cfg
		if [ \${iso_path} ] ; then
		set loopback="findiso=\${iso_path}"
		fi

		menuentry "Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})" {
		  linux  /live/vmlinuz-${VER_KRNL}-${IMG_ARCH} boot=live components locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-model=jp106 keyboard-layouts=jp "\${loopback}"
		  initrd /live/initrd.img-${VER_KRNL}-${IMG_ARCH}
		}
_EOT_
	echo "--- edit menu.cfg file --------------------------------------------------------"
	cat <<- _EOT_ > ./debootstrap/cdimg/isolinux/menu.cfg
		INCLUDE stdmenu.cfg
		MENU title Main Menu
		DEFAULT Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		LABEL Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		  SAY "Booting Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})..."
		  linux /live/vmlinuz-${VER_KRNL}-${IMG_ARCH}
		  APPEND initrd=/live/initrd.img-${VER_KRNL}-${IMG_ARCH} boot=live components locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-model=jp106 keyboard-layouts=jp
_EOT_
# -- file compress ------------------------------------------------------------
	echo "-- make file system image -----------------------------------------------------"
	rm -f ./debootstrap/cdimg/live/filesystem.squashfs
	mksquashfs ./debootstrap/fsimg ./debootstrap/cdimg/live/filesystem.squashfs -mem 1G -noappend -b 4K -comp xz
	ls -lht ./debootstrap/cdimg/live/
# -- make iso image -----------------------------------------------------------
	echo "-- make iso image -------------------------------------------------------------"
	pushd ./debootstrap/cdimg > /dev/null
		find . -type f -exec md5sum {} \; > ../md5sum.txt
		mv ../md5sum.txt .
		xorriso                                                                \
		    -as mkisofs                                                        \
		    -iso-level 3                                                       \
		    -full-iso9660-filenames                                            \
		    -volid "${LIVE_VOLID}"                                             \
		    -eltorito-boot                                                     \
		        isolinux/isolinux.bin                                          \
		        -no-emul-boot                                                  \
		        -boot-load-size 4                                              \
		        -boot-info-table                                               \
		        -eltorito-catalog isolinux/boot.cat                            \
		    -eltorito-alt-boot                                                 \
		        -e boot/grub/efi.img                                           \
		        -no-emul-boot                                                  \
		    -output ../../debian-live-${INP_SUITE}-${INP_ARCH}-lxde-custom.iso \
		    .
	popd > /dev/null
	ls -lht
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
#	sudo bash -c 'mount --bind /dev ./debootstrap/fsimg/dev && mount --bind /dev/pts ./debootstrap/fsimg/dev/pts && mount --bind /proc ./debootstrap/fsimg/proc'
#	sudo bash -c 'LANG=C chroot ./debootstrap/fsimg/'
#	sudo bash -c 'umount -lf ./debootstrap/fsimg/proc && umount -lf ./debootstrap/fsimg/dev/pts && umount -lf ./debootstrap/fsimg/dev'
# -----------------------------------------------------------------------------
#	tar -cz ./debootstrap/fsimg/inst-dvd.sh | xxd -ps
#	cat <<- _EOT_ | xxd -r -p | tar -xz
# -----------------------------------------------------------------------------
#	sudo apt -y install squashfs-tools xorriso cloop-utils isolinux
# == EOF ======================================================================
