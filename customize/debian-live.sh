#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [debian-live-[version]-[architecture]-lxde.iso]         *
# *****************************************************************************
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "$0 [i386 | amd64] [10.x | testing | ...]"
		exit 1
	fi

	LIVE_ARCH="$1"
	LIVE_VNUM="$2"
	LIVE_FILE="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso"
	LIVE_DEST="debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde-custom.iso"
	# -------------------------------------------------------------------------
	case "${LIVE_VNUM}" in
		"testing" | "bullseye" | 11* ) LIVE_SUITE="testing"; OBS_SUITE="Sid"   ;;
		"stable"  | "buster"   | 10* ) LIVE_SUITE="stable" ; OBS_SUITE="Buster";;
		*                            ) LIVE_SUITE=""       ; OBS_SUITE=""      ;;
	esac
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	if [ "`LANG=C dpkg -l debootstrap squashfs-tools xorriso isolinux | awk '$1==\"un\" {print $1;}'`" != "" ]; then
		apt -y install debootstrap squashfs-tools xorriso isolinux
	fi
# == initial processing =======================================================
#	rm -rf   ./debian-live
	rm -rf   ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' > ./debian-live/fsimg/debian-setup.sh
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
		#	sed -i /etc/xdg/lxsession/LXDE/autostart               \
		#	    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
		# -- module install -----------------------------------------------------------
		#	sed -i.orig /etc/resolv.conf -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
			sed -i /etc/apt/sources.list -e 's/^\(deb .*\)/\1 non-free contrib/g'
			echo "--- module install ------------------------------------------------------------"
			apt update       -q                                                    && \
			apt upgrade      -q -y                                                 && \
			apt full-upgrade -q -y                                                 && \
			apt install      -q -y                                                    \
			    clamav bind9 bind9utils samba smbclient vsftpd isc-dhcp-server        \
			    ntpdate inxi bc nfs-common nfs-kernel-server ibus-mozc                \
			    open-vm-tools open-vm-tools-desktop                                && \
			apt autoremove   -q -y                                                 && \
			apt autoclean    -q -y                                                 && \
			apt clean        -q -y                                                 || \
			fncEnd 1
			echo "--- task install --------------------------------------------------------------"
			tasksel install                                                           \
			    standard desktop laptop japanese japanese-desktop lxde-desktop        \
			    ssh-server web-server                                              || \
			fncEnd 1
			echo "--- ungoogled chromium install ------------------------------------------------"
			echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_${OBS_SUITE}/ /' > /etc/apt/sources.list.d/home:ungoogled_chromium.list
			wget -nv https://download.opensuse.org/repositories/home:ungoogled_chromium/Debian_${OBS_SUITE}/Release.key -O Release.key
			apt-key add - < Release.key
			apt update       -q                                                    && \
			apt install      -q -y                                                    \
			    ungoogled-chromium ungoogled-chromium-l10n                         && \
			apt autoremove   -q -y                                                 && \
			apt autoclean    -q -y                                                 && \
			apt clean        -q -y                                                 || \
			fncEnd 1
		#	mv /etc/resolv.conf.orig /etc/resolv.conf
			# -----------------------------------------------------------------------------
			echo "--- systemctl -----------------------------------------------------------------"
			systemctl disable clamav-freshclam
			systemctl  enable ssh
			systemctl disable apache2
			systemctl  enable vsftpd
			if [ "`find /usr/lib/ -name named.service -print`" = "" ]; then
				systemctl  enable bind9
			else
				systemctl  enable named
			fi
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
		# memo: sudo bash -c '/etc/fstab.vmware-sample >> /etc/fstab'
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
				    -e 's/#\(PermitEmptyPasswords\) .*/\1 no/'       \
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
	sed -i ./debian-live/fsimg/debian-setup.sh \
	    -e "s/\${OBS_SUITE}/${OBS_SUITE}/g"
	# -------------------------------------------------------------------------
#	if [ ! -f ./${LIVE_FILE} ]; then
#		case "${LIVE_SUITE}" in
#			"testing" ) LIVE_URL="http://cdimage.debian.org/cdimage/weekly-live-builds/${LIVE_ARCH}/iso-hybrid/debian-live-testing-${LIVE_ARCH}-lxde.iso";;
#			"stable"  ) LIVE_URL="http://cdimage.debian.org/cdimage/release/current-live/${LIVE_ARCH}/iso-hybrid/debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso";;
#			*         ) LIVE_URL="";;
#		esac
#		wget "${LIVE_URL}"
#	fi
	case "${LIVE_SUITE}" in
		"testing" ) LIVE_URL="http://cdimage.debian.org/cdimage/weekly-live-builds/${LIVE_ARCH}/iso-hybrid/debian-live-testing-${LIVE_ARCH}-lxde.iso";;
		"stable"  ) LIVE_URL="http://cdimage.debian.org/cdimage/release/current-live/${LIVE_ARCH}/iso-hybrid/debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso";;
		*         ) LIVE_URL="";;
	esac
	if [ ! -f "./${LIVE_FILE}" ]; then
		curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "./${LIVE_FILE}" "${LIVE_URL}" || { rm -f "./${LIVE_FILE}"; exit 1; }
	else
		curl -L -s --connect-timeout 60 --dump-header "header.txt" "${LIVE_URL}"
		WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
		WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
		WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
		DVD_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "./${LIVE_FILE}"`
		DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
		DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
		if [ "${WEB_SIZE}" != "${DVD_SIZE}" ] || [ "${WEB_DATE}" != "${DVD_DATE}" ]; then
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "./${LIVE_FILE}" "${LIVE_URL}" || { rm -f "./${LIVE_FILE}"; exit 1; }
		fi
		if [ -f "header.txt" ]; then
			rm -f "header.txt"
		fi
	fi
	# -------------------------------------------------------------------------
	echo "--- copy media -> cdimg -------------------------------------------------------"
	mount -r -o loop ./${LIVE_FILE} ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../cdimg/
	popd > /dev/null
	umount ./debian-live/media
	# -------------------------------------------------------------------------
	echo "--- copy media -> fsimg -------------------------------------------------------"
	mount -r -o loop ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm ../fsimg/
	popd > /dev/null
	umount ./debian-live/media
# =============================================================================
#	if [ -d ./debian-live/rpack.${LIVE_SUITE}.${LIVE_ARCH} ]; then
#		echo "--- deb file copy -------------------------------------------------------------"
#		cp -p ./debian-live/rpack.${LIVE_SUITE}.${LIVE_ARCH}/*.deb ./debian-live/fsimg/var/cache/apt/archives/
#	fi
# =============================================================================
	rm -f ./debian-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./debian-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./debian-live/fsimg/dev
	mount --bind /dev/pts ./debian-live/fsimg/dev/pts
	mount --bind /proc    ./debian-live/fsimg/proc
	mount --bind /sys     ./debian-live/fsimg/sys
	# -------------------------------------------------------------------------
#	cp -p ./debian-setup.sh ./debian-live/fsimg/
	if [ "${LIVE_ARCH}" == "i386" ]; then
		sed -i ./debian-live/fsimg/debian-setup.sh    \
		    -e 's/linux-headers-amd64/linux-headers-686/g'
	fi
	LANG=C chroot ./debian-live/fsimg /bin/bash /debian-setup.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount ./debian-live/fsimg/sys     || umount -lf ./debian-live/fsimg/sys
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
	       ./debian-live/fsimg/debian-setup.sh
# =============================================================================
	sed -i ./debian-live/cdimg/boot/grub/grub.cfg                                                                                       \
	    -e '1,/linux .* components/ s/\(linux .* components\) \(.*$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	sed -i ./debian-live/cdimg/isolinux/menu.cfg                                                                                         \
	    -e '1,/APPEND .* components/ s/\(APPEND .* components\) \(.*$\)/\1 locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp \2/'
	# ---------------------------------------------------------------------
#	if [ -f ./debian-live/cdimg/boot/grub/efi.img ]; then
#		echo "--- copy EFI directory --------------------------------------------------------"
#		mount -r -o loop ./debian-live/cdimg/boot/grub/efi.img ./debian-live/media/
#		pushd ./debian-live/media/efi/ > /dev/null
#			find . -depth -print | cpio -pdm ../../cdimg/EFI/
#		popd > /dev/null
#		umount ./debian-live/media/
#	fi
	# -------------------------------------------------------------------------
	rm -f ./debian-live/cdimg/live/filesystem.squashfs
	mksquashfs ./debian-live/fsimg ./debian-live/cdimg/live/filesystem.squashfs
	ls -lht ./debian-live/cdimg/live/
	# -------------------------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		find . ! -name "md5sum.txt" -type f -exec md5sum {} \; > md5sum.txt
		xorriso -as mkisofs \
		    -quiet \
		    -iso-level 3 \
		    -full-iso9660-filenames \
		    -volid "${LIVE_VOLID}" \
		    -eltorito-boot isolinux/isolinux.bin \
		    -eltorito-catalog isolinux/boot.cat \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
		    -eltorito-alt-boot \
		    -e boot/grub/efi.img \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "../../${LIVE_DEST}" \
		    .
	popd > /dev/null
	ls -lht debian*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
