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
	CFG_NAME="preseed_debian.cfg"
#	SUB_PROG="debian-sub_late_command.sh"
	case "${LIVE_VNUM}" in
		"old stable"  | "stretch"  |  9* ) LIVE_SUITE="old stable" ; OBS_SUITE="Stretch";;
		"stable"      | "buster"   | 10* ) LIVE_SUITE="stable"     ; OBS_SUITE="Buster" ;;
		"testing"     | "bullseye" | 11* ) LIVE_SUITE="testing"    ; OBS_SUITE="Sid"    ;;
		*                                ) LIVE_SUITE=""           ; OBS_SUITE=""       ;;
	esac
# == initialize ===============================================================
#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	set -u								# 未定義変数の参照で終了

	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0 ${LIVE_ARCH} ${LIVE_VNUM}]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# =============================================================================
# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=`echo ${INP_ADDR} | awk -F '.' '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
	done
	echo "${OUT_ARRY[@]}"
}
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
	rm -rf   ./debian-live
#	rm -rf   ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg ./debian-live/wkdir
	mkdir -p ./debian-live/media ./debian-live/cdimg ./debian-live/fsimg ./debian-live/wkdir
	# -------------------------------------------------------------------------
	TASK_LIST="standard, desktop, laptop, lxde-desktop,                              \
		       ssh-server, dns-server, file-server, print-server"
	PACK_LIST="network-manager chrony clamav curl wget rsync inxi                    \
		       build-essential indent vim bc                                         \
		       sudo tasksel                                                          \
		       openssh-server                                                        \
		       bind9 bind9utils dnsutils                                             \
		       samba smbclient cifs-utils                                            \
		       isc-dhcp-server                                                       \
		       cups cups-common                                                      \
		       lxde fonts-noto ibus-mozc mozc-utils-gui                              \
		       libreoffice-help-ja libreoffice-l10n-ja                               \
		       firefox-esr-l10n-ja thunderbird thunderbird-l10n-ja"
#		      open-vm-tools open-vm-tools-desktop
	# -------------------------------------------------------------------------
	if [ -f "./${CFG_NAME}" ]; then
		LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' ${CFG_NAME}  | \
		           sed -z 's/\n//g'                                                  | \
		           sed -e 's/.* string *//'                                            \
		               -e 's/[,|\\\\]//g'                                              \
		               -e 's/\t/ /g'                                                   \
		               -e 's/  */ /g'                                                  \
		               -e 's/^ *//'`
		LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' ${CFG_NAME} | \
		           sed -z 's/\n//g'                                                  | \
		           sed -e 's/.* string *//'                                            \
		               -e 's/[,|\\\\]//g'                                              \
		               -e 's/\t/ /g'                                                   \
		               -e 's/  */ /g'                                                  \
		               -e 's/^ *//'`
	fi
#	# -------------------------------------------------------------------------
#	cat <<- _EOT_SH_ > ./debian-live/fsimg/debian-setup.sh
#		#!/bin/bash
#		# -----------------------------------------------------------------------------
#		 	set -m								# ジョブ制御を有効にする
#		 	set -eu								# ステータス0以外と未定義変数の参照で終了
#		 	echo "*******************************************************************************"
#		 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : start [\$0]"
#		 	echo "*******************************************************************************"
#		# -- terminate ----------------------------------------------------------------
#		fncEnd() {
#		 	echo "--- terminate -----------------------------------------------------------------"
#		 	RET_STS=\$1
#		 	history -c
#		 	echo "*******************************************************************************"
#		 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : end [\$0]"
#		 	echo "*******************************************************************************"
#		 	exit \${RET_STS}
#		}
#		# -- initialize ---------------------------------------------------------------
#		 	echo "--- initialize ----------------------------------------------------------------"
#		 	trap 'fncEnd 1' 1 2 3 15
#		 	export PS1="(chroot) "
#		# -- module install -----------------------------------------------------------
#		#	sed -i.orig /etc/resolv.conf -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
#		 	sed -i /etc/apt/sources.list -e 's/^\(deb .*\)/\1 non-free contrib/g'
#		 	echo "--- module install ------------------------------------------------------------"
#		 	apt update       -q                                                    && \\
#		 	apt full-upgrade -q -y                                                 && \\
#		 	apt install      -q -y ${PACK_LIST}                                    && \\
#		 	apt autoremove   -q -y                                                 && \\
#		 	apt autoclean    -q -y                                                 && \\
#		 	apt clean        -q -y                                                 || \\
#		 	fncEnd 1
#		 	echo "--- task install --------------------------------------------------------------"
#		 	tasksel install ${TASK_LIST}                                           || \\
#		 	fncEnd 1
#		 	echo "--- google chrome install -----------------------------------------------------"
#		 	echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
#		 	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#		 	if [ -f Release.key ]; then rm -f Release.key; fi
#		 	apt update                                                             && \\
#		 	apt install      -q -y                                                    \\
#		 	    google-chrome-stable                                               || \\
#		 	fncEnd 1
#		#	chmod 644 /usr/bin/gnome-keyring-daemon
#		#	echo "--- ungoogled chromium install ------------------------------------------------"
#		#	echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/debian_Focal/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
#		#	curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/debian_Focal/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
#		#	if [ -f Release.key ]; then rm -f Release.key; fi
#		#	apt update                                                             && \\
#		#	apt install      -q -y                                                    \\
#		#	    ungoogled-chromium ungoogled-chromium-common                          \\
#		#	    ungoogled-chromium-driver ungoogled-chromium-sandbox                  \\
#		#	    ungoogled-chromium-shell ungoogled-chromium-l10n                   || \\
#		#	fncEnd 1
#		#	# -----------------------------------------------------------------------------
#		#	apt autoremove   -q -y                                                 && \\
#		#	apt autoclean    -q                                                    && \\
#		#	apt clean        -q                                                    || \\
#		#	fncEnd 1
#		#	mv /etc/resolv.conf.orig /etc/resolv.conf
#		 	# -----------------------------------------------------------------------------
#		#	echo "--- systemctl -----------------------------------------------------------------"
#		#	systemctl disable clamav-freshclam
#		#	systemctl  enable ssh
#		#	systemctl disable apache2
#		#	systemctl  enable vsftpd
#		#	if [ "`find /lib/systemd/system/ -name named.service -print`" = "" ]; then
#		#		systemctl  enable bind9
#		#	else
#		#		systemctl  enable named
#		#	fi
#		#	systemctl disable isc-dhcp-server
#		#	systemctl disable isc-dhcp-server6
#		#	systemctl  enable smbd
#		#	systemctl  enable nmbd
#		 	# -----------------------------------------------------------------------------
#		#	echo "--- freshclam -----------------------------------------------------------------"
#		#	freshclam --show-progress
#		# -- localize -----------------------------------------------------------------
#		 	echo "--- localize ------------------------------------------------------------------"
#		 	sed -i /etc/locale.gen                  \
#		 	    -e 's/^[A-Za-z]/# &/g'              \
#		 	    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
#		 	    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
#		 	locale-gen
#		 	update-locale LANG=ja_JP.UTF-8
#		#	sed -i /etc/xdg/lxsession/LXDE/autostart               \
#		#	    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
#		# -- mozc ---------------------------------------------------------------------
#		 	sed -i /usr/share/ibus/component/mozc.xml                                     \\
#		 	    -e '/<engine>/,/<\\/engine>/ s/\\(<layout>\\)default\\(<\\/layout>\\)/\\1jp\\2/g'
#		# -- open vm tools ------------------------------------------------------------
#		#	echo "--- open vm tools -------------------------------------------------------------"
#		#	mkdir -p /mnt/hgfs
#		#	echo -n '.host:/ /mnt/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults 0 0' \\
#		#	> /etc/fstab.vmware-sample
#		# memo: sudo bash -c '/etc/fstab.vmware-sample >> /etc/fstab'
#		# -- clamav -------------------------------------------------------------------
#		 	if [ -f /etc/clamav/freshclam.conf ]; then
#		 		echo "--- clamav --------------------------------------------------------------------"
#		 		sed -i /etc/clamav/freshclam.conf \\
#		 		    -e 's/^NotifyClamd/#&/'
#		 	fi
#		# -- sshd ---------------------------------------------------------------------
#		 	if [ -f /etc/ssh/sshd_config ]; then
#		 		echo "--- sshd ----------------------------------------------------------------------"
#		 		sed -i /etc/ssh/sshd_config                          \\
#		 		    -e 's/^\\(PermitRootLogin\\) .*/\\1 yes/'           \\
#		 		    -e 's/#\\(PasswordAuthentication\\) .*/\\1 yes/'    \\
#		 		    -e 's/#\\(PermitEmptyPasswords\\) .*/\\1 yes/'      \\
#		 		    -e 's/#\\(UsePAM\\) .*/\\1 yes/'                    \\
#		 		    -e '/HostKey \\/etc\\/ssh\\/ssh_host_ecdsa_key/d'   \\
#		 		    -e '/HostKey \\/etc\\/ssh\\/ssh_host_ed25519_key/d' \\
#		 		    -e '\$aUseDNS no\\nIgnoreUserKnownHosts no'
#		 	fi
#		# -- ftpd ---------------------------------------------------------------------
#		 	if [ -f /etc/vsftpd.conf ]; then
#		 		echo "--- ftpd ----------------------------------------------------------------------"
#		 		touch /etc/ftpusers					#
#		 		touch /etc/vsftpd.conf				#
#		 		touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
#		 		touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
#		 		touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
#		 		touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
#		 		# -------------------------------------------------------------------------
#		 		chmod 0600 /etc/ftpusers               \\
#		 				   /etc/vsftpd.conf            \\
#		 				   /etc/vsftpd.chroot_list     \\
#		 				   /etc/vsftpd.user_list       \\
#		 				   /etc/vsftpd.banned_emails   \\
#		 				   /etc/vsftpd.email_passwords
#		 		# -------------------------------------------------------------------------
#		 		sed -i /etc/ftpusers \\
#		 		    -e 's/root/# &/'
#		 		# -------------------------------------------------------------------------
#		 		sed -i /etc/vsftpd.conf                                           \\
#		 		    -e 's/^\\(listen\\)=.*\$/\\1=NO/'                                 \\
#		 		    -e 's/^\\(listen_ipv6\\)=.*\$/\\1=YES/'                           \\
#		 		    -e 's/^\\(anonymous_enable\\)=.*\$/\\1=NO/'                       \\
#		 		    -e 's/^\\(local_enable\\)=.*\$/\\1=YES/'                          \\
#		 		    -e 's/^#\\(write_enable\\)=.*\$/\\1=YES/'                         \\
#		 		    -e 's/^#\\(local_umask\\)=.*\$/\\1=022/'                          \\
#		 		    -e 's/^\\(dirmessage_enable\\)=.*\$/\\1=NO/'                      \\
#		 		    -e 's/^\\(use_localtime\\)=.*\$/\\1=YES/'                         \\
#		 		    -e 's/^\\(xferlog_enable\\)=.*\$/\\1=YES/'                        \\
#		 		    -e 's/^\\(connect_from_port_20\\)=.*\$/\\1=YES/'                  \\
#		 		    -e 's/^#\\(xferlog_std_format\\)=.*\$/\\1=NO/'                    \\
#		 		    -e 's/^#\\(idle_session_timeout\\)=.*\$/\\1=300/'                 \\
#		 		    -e 's/^#\\(data_connection_timeout\\)=.*\$/\\1=30/'               \\
#		 		    -e 's/^#\\(ascii_upload_enable\\)=.*\$/\\1=YES/'                  \\
#		 		    -e 's/^#\\(ascii_download_enable\\)=.*\$/\\1=YES/'                \\
#		 		    -e 's/^#\\(chroot_local_user\\)=.*\$/\\1=NO/'                     \\
#		 		    -e 's/^#\\(chroot_list_enable\\)=.*\$/\\1=NO/'                    \\
#		 		    -e "s~^#\\(chroot_list_file\\)=.*\$~\\1=/etc/vsftpd.chroot_list~" \\
#		 		    -e 's/^#\\(ls_recurse_enable\\)=.*\$/\\1=YES/'                    \\
#		 		    -e 's/^\\(pam_service_name\\)=.*\$/\\1=vsftpd/'                   \\
#		 		    -e '\$atcp_wrappers=YES'                                       \\
#		 		    -e '\$auserlist_enable=YES'                                    \\
#		 		    -e '\$auserlist_deny=YES'                                      \\
#		 		    -e "\\\$auserlist_file=/etc\\/vsftpd.user_list"                  \\
#		 		    -e '\$achmod_enable=YES'                                       \\
#		 		    -e '\$aforce_dot_files=YES'                                    \\
#		 		    -e '\$adownload_enable=YES'                                    \\
#		 		    -e '\$avsftpd_log_file=\\/var\\/log\\/vsftpd\\.log'                \\
#		 		    -e '\$adual_log_enable=NO'                                     \\
#		 		    -e '\$asyslog_enable=NO'                                       \\
#		 		    -e '\$alog_ftp_protocol=NO'                                    \\
#		 		    -e '\$aftp_data_port=20'                                       \\
#		 		    -e '\$apasv_enable=YES'
#		 	fi
#		# -- smb ----------------------------------------------------------------------
#		 	if [ -f /etc/samba/smb.conf ]; then
#		 		echo "--- smb.conf ------------------------------------------------------------------"
#		 		testparm -s /etc/samba/smb.conf | sed -e '/global/ ados charset = CP932\\nclient ipc min protocol = NT1\\nclient min protocol = NT1\\nserver min protocol = NT1\\nidmap config * : range = 1000-10000\\n' > smb.conf
#		 		testparm -s smb.conf > /etc/samba/smb.conf
#		 		rm -f smb.conf
#		 	fi
#		# -- root and user's setting --------------------------------------------------
#		 	echo "--- root and user's setting ---------------------------------------------------"
#		 	for TARGET in "/etc/skel" "/root"
#		 	do
#		 		pushd \${TARGET} > /dev/null
#		 			echo "---- .bashrc ------------------------------------------------------------------"
#		 			cat <<- '_EOT_' >> .bashrc
#		 				# --- 日本語文字化け対策 ---
#		 				case "\\\${TERM}" in
#		 				    "linux" ) export LANG=C;;
#		 				    * )                    ;;
#		 				esac
#		 				# export GTK_IM_MODULE=ibus
#		 				# export XMODIFIERS=@im=ibus
#		 				# export QT_IM_MODULE=ibus
#		_EOT_
#		 			echo "---- .vimrc -------------------------------------------------------------------"
#		 			cat <<- '_EOT_' > .vimrc
#		 				set number              " Print the line number in front of each line.
#		 				set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
#		 				set list                " List mode: Show tabs as CTRL-I is displayed, display \\\$ after end of line.
#		 				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
#		 				set nowrap              " This option changes how text is displayed.
#		 				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
#		 				set laststatus=2        " The value of this option influences when the last window will have a status line always.
#		 				syntax on               " Vim5 and later versions support syntax highlighting.
#		_EOT_
#		 			if [ "`which vim 2> /dev/null`" = "" ]; then
#		 					sed -i .vimrc                    \\
#		 					    -e 's/^\\(syntax on\\)/\\" \\1/'
#		 			fi
#		 			echo "---- .curlrc ------------------------------------------------------------------"
#		 			cat <<- '_EOT_' > .curlrc
#		 				location
#		 				progress-bar
#		 				remote-time
#		 				show-error
#		_EOT_
#		 		popd > /dev/null
#		 	done
#		# -- swap off -----------------------------------------------------------------
#		#	echo "--- swap off ------------------------------------------------------------------"
#		#	swapoff -a
#		# -- cleaning -----------------------------------------------------------------
#		 	echo "--- cleaning ------------------------------------------------------------------"
#		 	fncEnd 0
#		# -- EOF ----------------------------------------------------------------------
#		# *****************************************************************************
#		# <memo>
#		#   [im-config]
#		#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
#		# *****************************************************************************
#_EOT_SH_
#	sed -i ./debian-live/fsimg/debian-setup.sh -e 's/^ //g' -e "s/\${OBS_SUITE}/${OBS_SUITE}/g"
#	sed -i ./debian-live/fsimg/debian-setup.sh -e 's/^ //g'
	# -------------------------------------------------------------------------
	case "${LIVE_SUITE}" in
		"old stable" ) LIVE_URL="http://cdimage.debian.org/cdimage/archive/${LIVE_VNUM}-live/${LIVE_ARCH}/iso-hybrid/debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso";;
		"stable"     ) LIVE_URL="http://cdimage.debian.org/cdimage/release/current-live/${LIVE_ARCH}/iso-hybrid/debian-live-${LIVE_VNUM}-${LIVE_ARCH}-lxde.iso";;
		"testing"    ) LIVE_URL="http://cdimage.debian.org/cdimage/weekly-live-builds/${LIVE_ARCH}/iso-hybrid/debian-live-testing-${LIVE_ARCH}-lxde.iso";;
		*            ) LIVE_URL="";;
	esac
	if [ "${LIVE_URL}" != "" ]; then
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
	fi
	# -------------------------------------------------------------------------
	echo "--- copy media -> cdimg -------------------------------------------------------"
	mount -r -o loop ./${LIVE_FILE} ./debian-live/media
	pushd ./debian-live/media > /dev/null
		find . -depth -print | cpio -pdm --quiet ../cdimg/
	popd > /dev/null
	umount ./debian-live/media
	# -------------------------------------------------------------------------
#	echo "--- copy media -> fsimg -------------------------------------------------------"
#	mount -r -o loop ./debian-live/cdimg/live/filesystem.squashfs ./debian-live/media
#	pushd ./debian-live/media > /dev/null
#		find . -depth -print | cpio -pdm --quiet ../fsimg/
#	popd > /dev/null
#	umount ./debian-live/media
# =============================================================================
#	if [ -d ./debian-live/rpack.${LIVE_ARCH} ]; then
#		echo "--- deb file copy -------------------------------------------------------------"
#		cp -p ./debian-live/rpack.${LIVE_ARCH}/*.deb ./debian-live/fsimg/var/cache/apt/archives/
#	fi
# =============================================================================
#	rm -f ./debian-live/fsimg/etc/localtime
#	ln -s /usr/share/zoneinfo/Asia/Tokyo ./debian-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
#	mount --bind /run     ./debian-live/fsimg/run
#	mount --bind /dev     ./debian-live/fsimg/dev
#	mount --bind /dev/pts ./debian-live/fsimg/dev/pts
#	mount --bind /proc    ./debian-live/fsimg/proc
##	mount --bind /sys     ./debian-live/fsimg/sys
	# -------------------------------------------------------------------------
#	LANG=C chroot ./debian-live/fsimg /bin/bash /debian-setup.sh
#	RET_STS=$?
	# -------------------------------------------------------------------------
##	umount ./debian-live/fsimg/sys     || umount -lf ./debian-live/fsimg/sys
#	umount ./debian-live/fsimg/proc    || umount -lf ./debian-live/fsimg/proc
#	umount ./debian-live/fsimg/dev/pts || umount -lf ./debian-live/fsimg/dev/pts
#	umount ./debian-live/fsimg/dev     || umount -lf ./debian-live/fsimg/dev
#	umount ./debian-live/fsimg/run     || umount -lf ./debian-live/fsimg/run
	# -------------------------------------------------------------------------
#	if [ ${RET_STS} -ne 0 ]; then
#		exit ${RET_STS}
#	fi
	# -------------------------------------------------------------------------
#	find   ./debian-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
#	rm -rf ./debian-live/fsimg/root/.bash_history           \
#	       ./debian-live/fsimg/root/.viminfo                \
#	       ./debian-live/fsimg/tmp/*                        \
#	       ./debian-live/fsimg/var/cache/apt/*.bin          \
#	       ./debian-live/fsimg/var/cache/apt/archives/*.deb \
#	       ./debian-live/fsimg/debian-setup.sh
# =============================================================================
	LIVE_VOLID=`volname "${LIVE_FILE}"`
	BOOT_MBR=`echo ${LIVE_FILE} | sed 's/iso$/mbr/'`
	BOOT_EFI=`echo ${LIVE_FILE} | sed 's/iso$/efi/'`
	FILE_SKP=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $2;}'`
	FILE_CNT=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $4;}'`
	dd if=${LIVE_FILE} of=./debian-live/${BOOT_MBR} bs=1 count=446 status=none
	dd if=${LIVE_FILE} of=./debian-live/${BOOT_EFI} bs=512 skip=${FILE_SKP} count=${FILE_CNT} status=none
	# -------------------------------------------------------------------------
	pushd ./debian-live/cdimg > /dev/null
		INS_CFG="locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp"
		# --- grub.cfg --------------------------------------------------------
		INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
		sed -n '/^menuentry \"Debian GNU\/Linux.*\"/,/^}/p' boot/grub/grub.cfg | \
		sed -e 's/\(Debian GNU\/Linux.*)\)/\1 of Japanese/'                      \
		    -e "s~\(components\)~\1 ${INS_CFG}~"                               | \
		sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       \
		    -e '1i set default=0'                                                \
		    -e '1i set timeout=5'                                                \
		> grub.cfg
		mv grub.cfg boot/grub/
		# --- menu.cfg --------------------------------------------------------
		INS_ROW=$((`sed -n '/^LABEL/ =' isolinux/menu.cfg | head -n 1`-1))
		INS_STR=`sed -n 's/LABEL \(Debian GNU\/Linux Live.*\)/\1 of japanese/p' isolinux/menu.cfg`
		sed -n '/LABEL Debian GNU\/Linux Live.*/,/^$/p' isolinux/menu.cfg | \
		sed -e "s~\(LABEL\) .*~\1 ${INS_STR}~"                              \
		    -e "s~\(SAY\) .*~\1 \"${INS_STR}\.\.\.\"~"                      \
		    -e "s~\(APPEND .* components\) \(.*$\)~\1 ${INS_CFG} \2~"     | \
		sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                 | \
		sed -e "s~^\(DEFAULT\) .*$~\1 ${INS_STR}~"                          \
		> menu.cfg
		mv menu.cfg isolinux/
		# ---------------------------------------------------------------------
		sed -i isolinux/isolinux.cfg     \
		    -e 's/\(timeout\).*$/\1 50/'
		# --- preseed.cfg -----------------------------------------------------
		if [ -f "../../${CFG_NAME}" ]; then
			mkdir -p "preseed"
			cp --preserve=timestamps "../../${CFG_NAME}" "preseed/preseed.cfg"
#			cp --preserve=timestamps "../../${SUB_PROG}" "preseed/sub_cmd.sh"
			# -----------------------------------------------------------------
			LATE_CMD="\      in-target sed -i.orig /etc/apt/sources.list -e '/cdrom/ s/^ *\(deb\)/# \1/g'; \\\\\n"
			LATE_CMD+="      in-target apt -qq    update; \\\\\n"
			LATE_CMD+="      in-target apt -qq -y install ${LIST_PACK}; \\\\\n"
			LATE_CMD+="      in-target tasksel install ${LIST_TASK};"
			mount -r -o loop ./live/filesystem.squashfs ../media
			if [ -f ../media/usr/lib/systemd/system/connman.service ]; then
				LATE_CMD+=" \\\\\n      in-target systemctl disable connman.service;"
			fi
			umount ../media
			sed -i "preseed/preseed.cfg"                  \
			    -e '/preseed\/late_command/ s/#/ /g'      \
			    -e "/preseed\/late_command/a ${LATE_CMD}"
			# -----------------------------------------------------------------
			chmod 444 "preseed/preseed.cfg"
#			chmod 555 "preseed/sub_cmd.sh"
			# -----------------------------------------------------------------
			INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
			# --- grub.cfg ----------------------------------------------------
			INS_ROW=$((`sed -n '/^menuentry "Graphical Debian Installer"/ =' boot/grub/grub.cfg | head -n 1`-1))
			sed -n '/^menuentry "Graphical Debian Installer"/,/^}/p' boot/grub/grub.cfg | \
			sed -e 's/\(menuentry "Graphical Debian\) \(Installer"\)/\1 Auto \2/'         \
			    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                                   | \
			sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                            \
			> grub.cfg
			mv grub.cfg boot/grub/
			# --- menu.cfg ----------------------------------------------------
			INS_ROW=$((`sed -n '/^LABEL Graphical Debian Installer/ =' isolinux/menu.cfg | head -n 1`-1))
			sed -n '/LABEL Graphical Debian Installer$/,/^$/p' isolinux/menu.cfg | \
			sed -e 's/^\(LABEL Graphical Debian\) \(Installer\)/\1 Auto \2/'       \
			    -e "s/\(APPEND.*\$\)/\1 ${INS_CFG}/"                             | \
			sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                      \
			> menu.cfg
			mv menu.cfg isolinux/
		fi
		# -------------------------------------------------------------------------
#		rm -f ./live/filesystem.squashfs
#		mksquashfs ../fsimg ./live/filesystem.squashfs -mem 1G
#		ls -lht ./live/
		FSIMG_SIZE=`LANG=C ls -lh ./live/filesystem.squashfs | awk '{print $5;}'`
		# ---------------------------------------------------------------------
		find . ! -name "md5sum.txt" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
		BOOT_BIN="isolinux/isolinux.bin"
		BOOT_CAT="isolinux/boot.cat"
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
	rm -rf ./debian-live
	ls -lthLgG debian*
	echo メディアは ${FSIMG_SIZE} 以上のメモリーを搭載する PC で使用して下さい。
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0 ${LIVE_ARCH} ${LIVE_VNUM}]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
# sudo bash -c 'for i in `ls debian-live-*-amd64-lxde.iso | sed -e '\''s/debian-live-//'\'' -e '\''s/-amd64-lxde.iso//'\''`; do ./debian-live.sh amd64 $i; done'
# == EOF ======================================================================
