#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu-[version]-desktop-[architecture].iso]           *
# *****************************************************************************
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "$0 [amd64] [20.04 | 20.10]"
		exit 1
	fi

#	LIVE_ARCH="amd64"
#	LIVE_VNUM="20.04.2.0"
#	LIVE_VNUM="20.10"
	LIVE_ARCH="$1"
	LIVE_VNUM="$2"
	LIVE_FILE="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}.iso"
	LIVE_DEST="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}-custom.iso"
	VERSION=`echo "${LIVE_VNUM}" | awk -F '.' '{print $1"."$2;}'`
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# =============================================================================
	echo "-- Initialize -----------------------------------------------------------------"
	#--------------------------------------------------------------------------
	NOW_DATE=`date +"%Y/%m/%d"`													# yyyy/mm/dd
	NOW_TIME=`date +"%Y%m%d%H%M%S"`												# yyyymmddhhmmss
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`									# プログラム名
	#--------------------------------------------------------------------------
	WHO_AMI=`whoami`															# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
	#--------------------------------------------------------------------------
# == tools install ============================================================
	if [ "`which debootstrap 2> /dev/null`" = "" ]; then
		apt -y install debootstrap squashfs-tools xorriso isolinux
	fi
# == initial processing =======================================================
	rm -rf   ./ubuntu-live
#	rm -rf   ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg ./ubuntu-live/wkdir
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg ./ubuntu-live/wkdir
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
		 	echo "*******************************************************************************"
		 	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
		 	echo "*******************************************************************************"
		 	exit ${RET_STS}
		}
		# -- initialize ---------------------------------------------------------------
		 	echo "--- initialize ----------------------------------------------------------------"
		 	trap 'fncEnd 1' 1 2 3 15
		 	export PS1="(chroot) "
		# -- module install -----------------------------------------------------------
		#	sed -i.orig /etc/resolv.conf -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
		 	sed -i /etc/apt/sources.list -e 's/^\(deb .*\)/\1 universe multiverse/g'
		 	echo "--- module install ------------------------------------------------------------"
		 	apt update       -q                                                    && \
		 	apt upgrade      -q -y                                                 && \
		 	apt full-upgrade -q -y                                                 && \
		 	apt install      -q -y                                                    \
		 	    tasksel vim curl                                                      \
		 	    nfs-common nfs-kernel-server                                          \
		 	    mozc-utils-gui fonts-noto-cjk-extra                                   \
		 	    gnome-getting-started-docs-ja gnome-user-docs-ja                      \
		 	    language-pack-gnome-ja language-pack-ja                               \
		 	    libreoffice-help-ja libreoffice-l10n-ja                               \
		 	    firefox-locale-ja thunderbird-locale-ja                               \
		 	    open-vm-tools open-vm-tools-desktop                                && \
		 	apt autoremove   -q -y                                                 && \
		 	apt autoclean    -q -y                                                 && \
		 	apt clean        -q -y                                                 || \
		 	fncEnd 1
		 	echo "--- task install --------------------------------------------------------------"
		 	tasksel install                                                           \
		 	    standard server openssh-server dns-server samba-server             || \
		 	fncEnd 1
		 	echo "--- google chrome install -----------------------------------------------------"
		 	echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
		 	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
		 	if [ -f Release.key ]; then rm -f Release.key; fi
		 	apt update                                                             && \
		 	apt install      -q -y                                                    \
		 	    google-chrome-stable                                               || \
		 	fncEnd 1
		#	chmod 644 /usr/bin/gnome-keyring-daemon
		#	echo "--- ungoogled chromium install ------------------------------------------------"
		#	echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
		#	curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Ubuntu_Focal/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
		#	if [ -f Release.key ]; then rm -f Release.key; fi
		#	apt update                                                             && \
		#	apt install      -q -y                                                    \
		#	    ungoogled-chromium ungoogled-chromium-common                          \
		#	    ungoogled-chromium-driver ungoogled-chromium-sandbox                  \
		#	    ungoogled-chromium-shell ungoogled-chromium-l10n                   || \
		#	fncEnd 1
		#	# -----------------------------------------------------------------------------
		#	apt autoremove   -q -y                                                 && \
		#	apt autoclean    -q                                                    && \
		#	apt clean        -q                                                    || \
		#	fncEnd 1
		#	mv /etc/resolv.conf.orig /etc/resolv.conf
		 	# -----------------------------------------------------------------------------
		#	echo "--- systemctl -----------------------------------------------------------------"
		#	systemctl  enable clamav-freshclam
		#	systemctl  enable ssh
		#	systemctl disable apache2
		#	systemctl  enable vsftpd
		#	if [ "`find /lib/systemd/system/ -name named.service -print`" = "" ]; then
		#		systemctl  enable bind9
		#	else
		#		systemctl  enable named
		#	fi
		#	systemctl disable isc-dhcp-server
		#	systemctl disable isc-dhcp-server6
		#	systemctl  enable smbd
		#	systemctl  enable nmbd
		 	# -----------------------------------------------------------------------------
		#	echo "--- freshclam -----------------------------------------------------------------"
		#	freshclam --show-progress
		# -- localize -----------------------------------------------------------------
		 	echo "--- localize ------------------------------------------------------------------"
		 	sed -i /etc/locale.gen                  \
		 	    -e 's/^[A-Za-z]/# &/g'              \
		 	    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
		 	    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
		 	locale-gen
		 	update-locale LANG="ja_JP.UTF-8" LANGUAGE="ja:en"
		 	localectl set-x11-keymap --no-convert "jp,us" "pc105"
		# -- mozc ---------------------------------------------------------------------
		 	sed -i /usr/share/ibus/component/mozc.xml                                     \
		 	    -e '/<engine>/,/<\/engine>/ s/\(<layout>\)default\(<\/layout>\)/\1jp\2/g'
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
		 				set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
		 				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
		 				set nowrap              " This option changes how text is displayed.
		 				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
		 				set laststatus=2        " The value of this option influences when the last window will have a status line always.
		 				syntax on               " Vim5 and later versions support syntax highlighting.
		_EOT_
		 			if [ "`which vim 2> /dev/null`" = "" ]; then
		 					sed -i .vimrc                    \
		 					    -e 's/^\(syntax on\)/\" \1/'
		 			fi
		 			echo "---- .curlrc ------------------------------------------------------------------"
		 			cat <<- '_EOT_' > .curlrc
		 				location
		 				progress-bar
		 				remote-time
		 				show-error
		_EOT_
		 		popd > /dev/null
		 	done
		# -- swap off -----------------------------------------------------------------
		#	echo "--- swap off ------------------------------------------------------------------"
		#	swapoff -a
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
	sed -i ./ubuntu-live/fsimg/ubuntu-setup.sh -e 's/^ //g'
	# -------------------------------------------------------------------------
	LIVE_URL="https://releases.ubuntu.com/${LIVE_VNUM}/${LIVE_FILE}"
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
	echo "--- copy media -> fsimg -------------------------------------------------------"
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
	mount --bind /run     ./ubuntu-live/fsimg/run
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
	umount ./ubuntu-live/fsimg/run     || umount -lf ./ubuntu-live/fsimg/run
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
	rm -f ./ubuntu-live/cdimg/casper/filesystem.squashfs
	mksquashfs ./ubuntu-live/fsimg ./ubuntu-live/cdimg/casper/filesystem.squashfs
	ls -lht ./ubuntu-live/cdimg/casper/
	# -------------------------------------------------------------------------
	BOOT_MBR=`echo ${LIVE_FILE} | sed 's/iso$/mbr/'`
	BOOT_EFI=`echo ${LIVE_FILE} | sed 's/iso$/efi/'`
	FILE_SKP=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $2;}'`
	FILE_CNT=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $4;}'`
	dd if=${LIVE_FILE} of=./ubuntu-live/${BOOT_MBR} bs=1 count=446
	dd if=${LIVE_FILE} of=./ubuntu-live/${BOOT_EFI} bs=512 skip=${FILE_SKP} count=${FILE_CNT}
	# -------------------------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
		INS_CFG="locale=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp"
		# --- grub.cfg --------------------------------------------------------
		INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
		sed -n '/^menuentry \"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
		sed -n '0,/\}/p'                                          | \
		sed -e 's/\(Ubuntu\)/\1 of Japanese/'                       \
		    -e "s~\(file\)~${INS_CFG} \1~"                        | \
		sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg        | \
		sed -e 's/\(set default\)="1"/\1="0"/'                      \
		    -e 's/\(set timeout\).*$/\1=5/'                         \
		> grub.cfg
		mv grub.cfg boot/grub/
		# ---------------------------------------------------------------------
		if [ `echo "${VERSION} < 20.10" | bc` -eq 1 ]; then
			# --- txt.cfg -----------------------------------------------------
			INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
			sed -n '/label live$/,/append/p' isolinux/txt.cfg    | \
			sed -e 's/^\(label\).*/\1 live_of_japanese/'           \
			    -e 's/\(Try Ubuntu\) \(.*$\)/\1 of Japanese \2/'   \
			    -e "s~\(file\)~${INS_CFG} \1~"                   | \
			sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg     | \
			sed -e 's/^\(default\) .*$/\1 live_of_japanese/'       \
			> txt.cfg
			mv txt.cfg isolinux/
			# -----------------------------------------------------------------
			find . ! -name "md5sum.txt" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
			BOOT_BIN="isolinux/isolinux.bin"
			BOOT_CAT="isolinux/boot.cat"
		else
			find . ! -name "md5sum.txt" ! -name "boot.catalog" ! -path "./EFI/boot/*" ! -path "./boot/grub/i386-pc/*" ! -path "./boot/grub/x86_64-efi/*" -type f -exec md5sum {} \; > md5sum.txt
			BOOT_BIN="boot/grub/i386-pc/eltorito.img"
			BOOT_CAT="boot.catalog"
		fi
		xorriso -as mkisofs \
		    -quiet \
		    -iso-level 3 \
		    -full-iso9660-filenames \
		    -volid "${LIVE_VOLID}" \
		    -partition_offset 16 \
		    --grub2-mbr "../${BOOT_MBR}" \
		    --mbr-force-bootable \
		    -append_partition 2 0xEF "../${BOOT_EFI}" \
		    -appended_part_as_gpt \
		    -eltorito-boot ${BOOT_BIN} \
		    -eltorito-catalog ${BOOT_CAT} \
		    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
		    -eltorito-alt-boot \
		    -e '--interval:appended_partition_2:all::' \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "../../${LIVE_DEST}" \
		    .
	popd > /dev/null
	ls -lht ubuntu*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
	https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja
# == EOF ======================================================================
