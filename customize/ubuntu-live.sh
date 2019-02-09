#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu-18.10-desktop-amd64.iso]                        *
# *****************************************************************************
	LIVE_VNUM="18.10"
	LIVE_ARCH="amd64"
	LIVE_FILE="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}.iso"
	LIVE_DEST="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}-custom.iso"
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
#	rm -rf   ./ubuntu-live
	rm -rf   ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' > ./ubuntu-live/fsimg/ubuntu-setup.sh
		#!/bin/bash
		# -----------------------------------------------------------------------------
			set -m								# ジョブ制御を有効にする
			set -eu								# ステータス0以外と未定義変数の参照で終了
			echo "*******************************************************************************"
			echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
			echo "*******************************************************************************"
		# -- terminate ----------------------------------------------------------------
		fncEnd() {
			echo "--- terminate -----------------------------------------------------------------"
			RET_STS=$1

			history -c
		#	/etc/init.d/dbus stop
		#	umount /dev/pts || umount -fl /dev/pts
		#	umount /dev     || umount -fl /dev
		#	umount /sys     || umount -fl /sys
		#	umount /proc    || umount -fl /proc

			echo "*******************************************************************************"
			echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
			echo "*******************************************************************************"
			exit ${RET_STS}
		}
		# -- initialize ---------------------------------------------------------------
			echo "--- initialize ----------------------------------------------------------------"
			trap 'fncEnd 1' 1 2 3 15
			export PS1="(chroot) "
		#	mount -t proc     proc     /proc
		#	mount -t sysfs    sysfs    /sys
		#	mount -t devtmpfs /dev     /dev
		#	mount -t devpts   /dev/pts /dev/pts
		#	/etc/init.d/dbus start
		# -- localize -----------------------------------------------------------------
			echo "--- localize ------------------------------------------------------------------"
			sed -i /etc/locale.gen                  \
			    -e 's/^[A-Za-z]/# &/g'              \
			    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
			    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
			locale-gen
			update-locale LANG=ja_JP.UTF-8
		# -- module install -----------------------------------------------------------
			echo "--- module install ------------------------------------------------------------"
		#	sed -i.orig /etc/resolv.conf -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
			sed -i /etc/apt/sources.list -e 's/^\(deb .*\)/\1 universe multiverse/g'
			apt update       -q                                                    && \
			apt upgrade      -q -y                                                 && \
			apt full-upgrade -q -y                                                 && \
			apt install      -q -y                                                    \
			    apache2 bc bind9 bind9utils build-essential chromium-browser          \
			    chromium-browser-l10n cifs-utils clamav curl dpkg-repack              \
			    firefox-locale-ja fonts-noto-cjk-extra gnome-getting-started-docs-ja  \
			    gnome-user-docs-ja hyphen-es ibus-mozc indent isc-dhcp-server         \
			    isolinux language-pack-gnome-ja language-pack-gnome-ja-base           \
			    language-pack-ja language-pack-ja-base libapt-pkg-perl libelf-dev     \
			    libio-pty-perl libnet-ssleay-perl libreoffice-help-ja                 \
			    libreoffice-l10n-ja lvm2 mythes-es network-manager nfs-common         \
			    nfs-kernel-server ntpdate open-vm-tools open-vm-tools-desktop         \
			    openssh-server perl rsync samba smbclient squashfs-tools sudo tasksel \
			    thunderbird-locale-ja vsftpd                                       && \
			apt autoremove   -q -y                                                 && \
			apt autoclean    -q -y                                                 && \
			apt clean        -q -y                                                 || \
			fncEnd 1
		#	mv /etc/resolv.conf.orig /etc/resolv.conf
			# -----------------------------------------------------------------------------
			echo "--- systemctl -----------------------------------------------------------------"
			systemctl  enable clamav-freshclam
			systemctl  enable ssh
			systemctl disable apache2
			systemctl  enable vsftpd
			systemctl  enable bind9
			systemctl disable isc-dhcp-server
		#	systemctl disable isc-dhcp-server6
			systemctl  enable smbd
			systemctl  enable nmbd
			# -----------------------------------------------------------------------------
			echo "--- freshclam -----------------------------------------------------------------"
			freshclam --show-progress
		# -- open vm tools ------------------------------------------------------------
			echo "--- open vm tools -------------------------------------------------------------"
			mkdir -p /mnt/hgfs
			echo -n '.host:/ /mnt/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults 0 0' \
			> /etc/fstab.vmware-sample
		# -- clamav -------------------------------------------------------------------
			if [ -f /etc/clamav/freshclam.conf ]; then
				echo "--- clamav --------------------------------------------------------------------"
				sed -i /etc/clamav/freshclam.conf \
				    -e 's/^NotifyClamd/#&/'
			fi
		# -- sshd ---------------------------------------------------------------------
			if [ -f /etc/ssh/sshd_config ]; then
				echo "--- sshd ----------------------------------------------------------------------"
				sed -i /etc/ssh/sshd_config                          \
				    -e 's/^\(PermitRootLogin\) .*/\1 yes/'           \
				    -e 's/#\(PasswordAuthentication\) .*/\1 yes/'    \
				    -e 's/#\(PermitEmptyPasswords\) .*/\1 yes/'      \
				    -e 's/#\(UsePAM\) .*/\1 yes/'                    \
				    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'   \
				    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d' \
				    -e '$aUseDNS no\nIgnoreUserKnownHosts no'
			fi
		# -- ftpd ---------------------------------------------------------------------
			if [ -f /etc/vsftpd.conf ]; then
				echo "--- ftpd ----------------------------------------------------------------------"
				touch /etc/ftpusers					#
				touch /etc/vsftpd.conf				#
				touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
				touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
				touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
				touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
				# -------------------------------------------------------------------------
				chmod 0600 /etc/ftpusers               \
						   /etc/vsftpd.conf            \
						   /etc/vsftpd.chroot_list     \
						   /etc/vsftpd.user_list       \
						   /etc/vsftpd.banned_emails   \
						   /etc/vsftpd.email_passwords
				# -------------------------------------------------------------------------
				sed -i /etc/ftpusers \
				    -e 's/root/# &/'
				# -------------------------------------------------------------------------
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
				    -e "s~^#\(chroot_list_file\)=.*$~\1=/etc/vsftpd.chroot_list~" \
				    -e 's/^#\(ls_recurse_enable\)=.*$/\1=YES/'                    \
				    -e 's/^\(pam_service_name\)=.*$/\1=vsftpd/'                   \
				    -e '$atcp_wrappers=YES'                                       \
				    -e '$auserlist_enable=YES'                                    \
				    -e '$auserlist_deny=YES'                                      \
				    -e "\$auserlist_file=/etc\/vsftpd.user_list"                  \
				    -e '$achmod_enable=YES'                                       \
				    -e '$aforce_dot_files=YES'                                    \
				    -e '$adownload_enable=YES'                                    \
				    -e '$avsftpd_log_file=\/var\/log\/vsftpd\.log'                \
				    -e '$adual_log_enable=NO'                                     \
				    -e '$asyslog_enable=NO'                                       \
				    -e '$alog_ftp_protocol=NO'                                    \
				    -e '$aftp_data_port=20'                                       \
				    -e '$apasv_enable=YES'
			fi
		# -- smb ----------------------------------------------------------------------
			if [ -f /etc/samba/smb.conf ]; then
				echo "--- smb.conf ------------------------------------------------------------------"
				testparm -s /etc/samba/smb.conf | sed -e '/global/ ados charset = CP932\nclient ipc min protocol = NT1\nclient min protocol = NT1\nserver min protocol = NT1\nidmap config * : range = 1000-10000\n' > smb.conf
				testparm -s smb.conf > /etc/samba/smb.conf
				rm -f smb.conf
			fi
		# -- root and user's setting --------------------------------------------------
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
		# -- cleaning -----------------------------------------------------------------
			echo "--- cleaning ------------------------------------------------------------------"
			fncEnd 0
		# -- EOF ----------------------------------------------------------------------
		# *****************************************************************************
		# <memo>
		#   [im-config]
		#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
		# *****************************************************************************
_EOT_SH_
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "https://ftp.yz.yamagata-u.ac.jp/pub/linux/ubuntu/releases/${LIVE_VNUM}/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./${LIVE_FILE} ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./ubuntu-live/media
	# -------------------------------------------------------------------------
	if [ ! -f ./ubuntu-live/cdimg/casper/filesystem.squashfs.orig ]; then
		mv ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/filesystem.squashfs
	fi
	# -------------------------------------------------------------------------
	mount -r -o loop ./ubuntu-live/filesystem.squashfs ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./ubuntu-live/media
# =============================================================================
	if [ -d ./ubuntu-live/rpack.${LIVE_ARCH} ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		cp -p ./ubuntu-live/rpack.${LIVE_ARCH}/*.deb ./ubuntu-live/fsimg/var/cache/apt/archives/
	fi
# =============================================================================
	rm -f ./ubuntu-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./ubuntu-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./ubuntu-live/fsimg/dev
	mount --bind /dev/pts ./ubuntu-live/fsimg/dev/pts
	mount --bind /proc    ./ubuntu-live/fsimg/proc
#	mount --bind /sys     ./ubuntu-live/fsimg/sys
	# -------------------------------------------------------------------------
#	cp -p ./ubuntu-setup.sh ./ubuntu-live/fsimg/
	LANG=C chroot ./ubuntu-live/fsimg /bin/bash /ubuntu-setup.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
#	umount ./ubuntu-live/fsimg/sys     || umount -lf ./ubuntu-live/fsimg/sys
	umount ./ubuntu-live/fsimg/proc    || umount -lf ./ubuntu-live/fsimg/proc
	umount ./ubuntu-live/fsimg/dev/pts || umount -lf ./ubuntu-live/fsimg/dev/pts
	umount ./ubuntu-live/fsimg/dev     || umount -lf ./ubuntu-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	find   ./ubuntu-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./ubuntu-live/fsimg/root/.bash_history           \
	       ./ubuntu-live/fsimg/root/.viminfo                \
	       ./ubuntu-live/fsimg/tmp/*                        \
	       ./ubuntu-live/fsimg/var/cache/apt/*.bin          \
	       ./ubuntu-live/fsimg/var/cache/apt/archives/*.deb \
	       ./ubuntu-live/fsimg/ubuntu-setup.sh
# =============================================================================
	sed -i ./debian-live/cdimg/boot/grub/grub.cfg                                                                                       \
	    -e 's/\(linux .* casper\) \(quiet.*\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                                                                                          \
	    -e 's/\(append .* casper\) \(initrd.*\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	# -------------------------------------------------------------------------
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs
	ls -lht ./ubuntu-live/cdimg/casper/
	# -------------------------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
		find . ! -name "md5sum.txt" -type f -exec md5sum {} \; > md5sum.txt
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
	ls -lht ubuntu*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
