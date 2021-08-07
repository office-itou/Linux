#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [ubuntu-[version]-desktop-[architecture].iso]           *
# *****************************************************************************
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		echo "$0 [amd64] [21.04 | 21.10]"
		exit 1
	fi

	LIVE_ARCH="$1"
	LIVE_VNUM="$2"
	LIVE_FILE="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}.iso"
	LIVE_DEST="ubuntu-${LIVE_VNUM}-desktop-${LIVE_ARCH}-custom.iso"
	CFG_NAME="preseed_ubuntu.cfg"
	SUB_PROG="ubuntu-sub_success_command.sh"
	VERSION=`echo "${LIVE_VNUM}" | awk -F '.' '{print $1"."$2;}'`
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
	rm -rf   ./ubuntu-live
#	rm -rf   ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg ./ubuntu-live/wkdir
	mkdir -p ./ubuntu-live/media ./ubuntu-live/cdimg ./ubuntu-live/fsimg ./ubuntu-live/wkdir
	# -------------------------------------------------------------------------
	TASK_LIST="standard, server, dns-server, openssh-server,                         \
		       print-server, samba-server,                                           \
		       ubuntu-desktop, ubuntu-desktop-minimal"
	PACK_LIST="network-manager chrony clamav curl wget rsync inxi                    \
		       build-essential indent vim bc                                         \
		       sudo tasksel whois                                                    \
		       openssh-server                                                        \
		       bind9 bind9utils dnsutils                                             \
		       samba smbclient cifs-utils                                            \
		       isc-dhcp-server                                                       \
		       cups cups-common                                                      \
		       language-pack-gnome-ja language-pack-ja language-pack-ja-base         \
		       ubuntu-server ubuntu-desktop fonts-noto ibus-mozc mozc-utils-gui      \
		       gnome-getting-started-docs-ja gnome-user-docs-ja                      \
		       libreoffice-help-ja libreoffice-l10n-ja                               \
		       firefox-locale-ja thunderbird-locale-ja"
#		      open-vm-tools open-vm-tools-desktop
	# -------------------------------------------------------------------------
	if [ -f "./${CFG_NAME}" ]; then
		LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' ${CFG_NAME}  | \
		           sed -z 's/\n//g'                                                  | \
		           sed -e 's/.* multiselect *//'                                       \
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
	# -------------------------------------------------------------------------
	if [ `echo "${VERSION} < 20.04" | bc` -eq 1 ]; then
		LIST_TASK=$(echo ${LIST_TASK} | \
		            sed -e 's/ubuntu-desktop-minimal.*[,| ]*//' \
		                -e 's/[,| ]*$//')
	fi
#	# -------------------------------------------------------------------------
#	cat <<- _EOT_SH_ > ./ubuntu-live/fsimg/ubuntu-setup.sh
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
#		#	sed -i.orig /etc/resolv.conf -e '\$anameserver 1.1.1.1\\nnameserver 1.0.0.1'
#		 	sed -i /etc/apt/sources.list -e 's/^\\(deb .*\\)/\\1 universe multiverse/g'
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
#		#	echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
#		#	curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Ubuntu_Focal/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
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
#		#	systemctl  enable clamav-freshclam
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
#		 	sed -i /etc/locale.gen                  \\
#		 	    -e 's/^[A-Za-z]/# &/g'              \\
#		 	    -e 's/# \\(ja_JP.UTF-8 UTF-8\\)/\\1/g' \\
#		 	    -e 's/# \\(en_US.UTF-8 UTF-8\\)/\\1/g'
#		 	locale-gen
#		 	update-locale LANG="ja_JP.UTF-8" LANGUAGE="ja:en"
#		 	localectl set-x11-keymap --no-convert "jp,us" "pc105"
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
#	sed -i ./ubuntu-live/fsimg/ubuntu-setup.sh -e 's/^ //g'
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
#	WALL_URL="http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
	WALL_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
	WALL_FILE="ubuntu_splash.png"
	if [ ! -f "./${WALL_FILE}" ]; then
		curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "./${WALL_FILE}" "${WALL_URL}" || { rm -f "./${WALL_FILE}"; exit 1; }
	else
		curl -L -s --connect-timeout 60 --dump-header "header.txt" "${WALL_URL}"
		WEB_SIZE=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
		WEB_LAST=`cat header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
		WEB_DATE=`date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
		FILE_INFO=`ls -lL --time-style="+%Y%m%d%H%M%S" "./${WALL_FILE}"`
		FILE_SIZE=`echo ${FILE_INFO} | awk '{print $5;}'`
		FILE_DATE=`echo ${FILE_INFO} | awk '{print $6;}'`
		if [ "${WEB_SIZE}" != "${FILE_SIZE}" ] || [ "${WEB_DATE}" != "${FILE_DATE}" ]; then
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 -o "./${WALL_FILE}" "${WALL_URL}" || { rm -f "./${WALL_FILE}"; exit 1; }
		fi
		if [ -f "header.txt" ]; then
			rm -f "header.txt"
		fi
	fi
	# -------------------------------------------------------------------------
	echo "--- copy media -> cdimg -------------------------------------------------------"
	mount -r -o loop ./${LIVE_FILE} ./ubuntu-live/media
	pushd ./ubuntu-live/media > /dev/null
		find . -depth -print | cpio -pdm --quiet ../cdimg/
	popd > /dev/null
	umount ./ubuntu-live/media
	# -------------------------------------------------------------------------
#	echo "--- copy media -> fsimg -------------------------------------------------------"
#	mount -r -o loop ./ubuntu-live/cdimg/casper/filesystem.squashfs ./ubuntu-live/media
#	pushd ./ubuntu-live/media > /dev/null
#		find . -depth -print | cpio -pdm --quiet ../fsimg/
#	popd > /dev/null
#	umount ./ubuntu-live/media
# =============================================================================
#	if [ -d ./ubuntu-live/rpack.${LIVE_ARCH} ]; then
#		echo "--- deb file copy -------------------------------------------------------------"
#		cp -p ./ubuntu-live/rpack.${LIVE_ARCH}/*.deb ./ubuntu-live/fsimg/var/cache/apt/archives/
#	fi
# =============================================================================
#	rm -f ./ubuntu-live/fsimg/etc/localtime
#	ln -s /usr/share/zoneinfo/Asia/Tokyo ./ubuntu-live/fsimg/etc/localtime
	# -------------------------------------------------------------------------
#	mount --bind /run     ./ubuntu-live/fsimg/run
#	mount --bind /dev     ./ubuntu-live/fsimg/dev
#	mount --bind /dev/pts ./ubuntu-live/fsimg/dev/pts
#	mount --bind /proc    ./ubuntu-live/fsimg/proc
##	mount --bind /sys     ./ubuntu-live/fsimg/sys
	# -------------------------------------------------------------------------
#	LANG=C chroot ./ubuntu-live/fsimg /bin/bash /ubuntu-setup.sh
#	RET_STS=$?
	# -------------------------------------------------------------------------
##	umount ./ubuntu-live/fsimg/sys     || umount -lf ./ubuntu-live/fsimg/sys
#	umount ./ubuntu-live/fsimg/proc    || umount -lf ./ubuntu-live/fsimg/proc
#	umount ./ubuntu-live/fsimg/dev/pts || umount -lf ./ubuntu-live/fsimg/dev/pts
#	umount ./ubuntu-live/fsimg/dev     || umount -lf ./ubuntu-live/fsimg/dev
#	umount ./ubuntu-live/fsimg/run     || umount -lf ./ubuntu-live/fsimg/run
	# -------------------------------------------------------------------------
#	if [ ${RET_STS} -ne 0 ]; then
#		exit ${RET_STS}
#	fi
	# -------------------------------------------------------------------------
#	find   ./ubuntu-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
#	rm -rf ./ubuntu-live/fsimg/root/.bash_history           \
#	       ./ubuntu-live/fsimg/root/.viminfo                \
#	       ./ubuntu-live/fsimg/tmp/*                        \
#	       ./ubuntu-live/fsimg/var/cache/apt/*.bin          \
#	       ./ubuntu-live/fsimg/var/cache/apt/archives/*.deb \
#	       ./ubuntu-live/fsimg/ubuntu-setup.sh
# =============================================================================
#	rm ./ubuntu-live/cdimg/casper/filesystem.size                    \
#	   ./ubuntu-live/cdimg/casper/filesystem.manifest-remove         
#	   ./ubuntu-live/cdimg/casper/filesystem.manifest                \
#	   ./ubuntu-live/cdimg/casper/filesystem.manifest-remove         
#	   ./ubuntu-live/cdimg/casper/filesystem.manifest-minimal-remove 
	# -------------------------------------------------------------------------
#	touch ./ubuntu-live/cdimg/casper/filesystem.size
#	touch ./ubuntu-live/cdimg/casper/filesystem.manifest
#	touch ./ubuntu-live/cdimg/casper/filesystem.manifest-remove
#	touch ./ubuntu-live/cdimg/casper/filesystem.manifest-minimal-remove
#	# -------------------------------------------------------------------------
#	printf $(LANG=C chroot ./ubuntu-live/fsimg du -sx --block-size=1 | cut -f1) > ./ubuntu-live/cdimg/casper/filesystem.size
#	LANG=C chroot ./ubuntu-live/fsimg dpkg-query -W --showformat='${Package} ${Version}\n' > ./ubuntu-live/cdimg/casper/filesystem.manifest
#	cp -p ./ubuntu-live/cdimg/casper/filesystem.manifest ./ubuntu-live/cdimg/casper/filesystem.manifest-desktop
#	sed -i ./ubuntu-live/cdimg/casper/filesystem.manifest-desktop \
#	    -e '/^casper.*$/d'                                        \
#	    -e '/^lupin-casper.*$/d'                                  \
#	    -e '/^ubiquity.*$/d'                                      \
#	    -e '/^ubiquity-casper.*$/d'                               \
#	    -e '/^ubiquity-frontend-gtk.*$/d'                         \
#	    -e '/^ubiquity-slideshow-ubuntu.*$/d'                     \
#	    -e '/^ubiquity-ubuntu-artwork.*$/d'
# =============================================================================
	LIVE_VOLID=`volname "${LIVE_FILE}"`
	BOOT_MBR=`echo ${LIVE_FILE} | sed 's/iso$/mbr/'`
	BOOT_EFI=`echo ${LIVE_FILE} | sed 's/iso$/efi/'`
	FILE_SKP=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $2;}'`
	FILE_CNT=`fdisk -l ${LIVE_FILE} | awk '/EFI/ {print $4;}'`
	dd if=${LIVE_FILE} of=./ubuntu-live/${BOOT_MBR} bs=1 count=446 status=none
	dd if=${LIVE_FILE} of=./ubuntu-live/${BOOT_EFI} bs=512 skip=${FILE_SKP} count=${FILE_CNT} status=none
	# -------------------------------------------------------------------------
	pushd ./ubuntu-live/cdimg > /dev/null
#		INS_CFG="locale=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp105 keyboard-layouts=jp"
		INS_CFG="debian-installer/language=ja keyboard-configuration/layoutcode?=jp keyboard-configuration/modelcode?=jp106"
		# --- grub.cfg --------------------------------------------------------
		INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | head -n 1`-1))
		sed -n '/^menuentry \"Try Ubuntu.*\"\|\"Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
		sed -e 's/\"\(Try Ubuntu.*\)\"/\"\1 for Japanese language\"/'                 \
		    -e 's/\"\(Ubuntu\)\"/\"\1 for Japanese language\"/'                     | \
		sed -e "s~\(file\)~${INS_CFG} \1~"                                          | \
		sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                          | \
		sed -e 's/\(set default\)="1"/\1="0"/'                                        \
		    -e 's/\(set timeout\).*$/\1=5/'                                           \
		> grub.cfg
		mv grub.cfg boot/grub/
		# --- txt.cfg ---------------------------------------------------------
		if [ -f isolinux/txt.cfg ]; then
			INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | head -n 1`-1))
			sed -n '/label live$/,/append/p' isolinux/txt.cfg            | \
			sed -e 's/^\(label\) \(.*\)/\1 \2_for_japanese_language/'      \
			    -e 's/\^\(Try Ubuntu.*\)/\1 for \^Japanese language/'    | \
			sed -e "s~\(file\)~${INS_CFG} \1~"                           | \
			sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg             | \
			sed -e 's/^\(default\) .*$/\1 live_for_japanese_language/'     \
			> txt.cfg
			mv txt.cfg isolinux/
			sed -i isolinux/isolinux.cfg                             \
			    -e '/ui gfxboot bootlogo/d'
			sed -i isolinux/stdmenu.cfg                              \
			    -e '/menu vshift .*/d'                               \
			    -e '/menu rows .*/d'
#			    -e '/menu background .*/d'                           \
			sed -i isolinux/menu.cfg                                 \
			    -e 's/\(menu width\) .*/\1 60/'                      \
			    -e 's/\(menu margin\) .*/\1 0/'                      \
			    -e '/\(menu width\) .*/a menu rows 10'               \
			    -e '/\(menu margin\) .*/a menu vshift 10'
			cp -p ../../${WALL_FILE} isolinux/splash.png
		fi
		# --- preseed.cfg -----------------------------------------------------
		if [ -f "../../${CFG_NAME}" -a -f "../../${SUB_PROG}" ]; then
			cp --preserve=timestamps "../../${CFG_NAME}" "preseed/preseed.cfg"
#			cp --preserve=timestamps "../../${SUB_PROG}" "preseed/"
			# -----------------------------------------------------------------
			OLD_IFS=${IFS}
			IFS=$'\n'
#			LATE_CMD="\      /cdrom/preseed/ubuntu-sub_success_command.sh /cdrom/preseed/preseed.cfg /target;"
			LATE_CMD="\      in-target sed -i.orig /etc/apt/sources.list -e '/cdrom/ s/^ *\(deb\)/# \1/g'; \\\\\n"
			LATE_CMD+="      in-target apt -qq    update; \\\\\n"
			LATE_CMD+="      in-target apt -qq -y full-upgrade; \\\\\n"
			LATE_CMD+="      in-target apt -qq -y install ${LIST_PACK}; \\\\\n"
			LATE_CMD+="      in-target tasksel install ${LIST_TASK};"
			mount -r -o loop ./casper/filesystem.squashfs ../media
			if [ -f ../media/usr/lib/systemd/system/connman.service ]; then
				LATE_CMD+=" \\\\\n      in-target systemctl disable connman.service;"
			fi
			IPV4_DHCP=`awk 'BEGIN {result="true";} !/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {if ($4=="true") result="false";} END {print result;}' preseed/preseed.cfg`
			if [ -d ../media/etc/netplan -a "${IPV4_DHCP}" != "true" ]; then
				ENET_NICS=`awk '!/#/&&/netcfg\/choose_interface/ {print $4;}' preseed/preseed.cfg`
				if [ "${ENET_NICS}" = "auto" -o "${ENET_NICS}" = "" ]; then
					ENET_NIC1=ens160
				else
					ENET_NIC1=${ENET_NICS}
				fi
				IPV4_ADDR=`awk '!/#/&&/netcfg\/get_ipaddress/    {print $4;}' preseed/preseed.cfg`
				IPV4_MASK=`awk '!/#/&&/netcfg\/get_netmask/      {print $4;}' preseed/preseed.cfg`
				IPV4_GWAY=`awk '!/#/&&/netcfg\/get_gateway/      {print $4;}' preseed/preseed.cfg`
				IPV4_NAME=`awk '!/#/&&/netcfg\/get_nameservers/  {print $4;}' preseed/preseed.cfg`
				NWRK_WGRP=`awk '!/#/&&/netcfg\/get_domain/       {print $4;}' preseed/preseed.cfg`
				IPV4_BITS=`fncIPv4GetNetmaskBits "${IPV4_MASK}"`
				IPV4_YAML=$(IFS= cat <<- _EOT_ | xxd -ps | sed -z 's/\n//g'
						network:
						  version: 2
						  renderer: NetworkManager
						  ethernets:
						    ${ENET_NIC1}:
						      dhcp4: false
						      addresses: [ ${IPV4_ADDR}/${IPV4_BITS} ]
						      gateway4: ${IPV4_GWAY}
						      nameservers:
						          search: [ ${NWRK_WGRP} ]
						          addresses: [ ${IPV4_NAME} ]
_EOT_
				)
				LATE_CMD+=" \\\\\n      in-target bash -c \'echo \"${IPV4_YAML}\" | xxd -r -p > /etc/netplan/99-network-manager-static.yaml\'"
			fi
			umount ../media
			sed -i "preseed/preseed.cfg"                  \
			    -e '/ubiquity\/success_command/ s/#/ /g'      \
			    -e "/ubiquity\/success_command/a ${LATE_CMD}"
			IFS=${OLD_IFS}
			# -----------------------------------------------------------------
			chmod 444 "preseed/preseed.cfg"
#			chmod 555 "preseed/${SUB_PROG}"
			# -----------------------------------------------------------------
			INS_CFG="\/cdrom\/preseed\/preseed.cfg auto=true"
			# --- grub.cfg ----------------------------------------------------
			INS_ROW=$((`sed -n '/^menuentry "Try Ubuntu without installing"\|menuentry "Ubuntu"/ =' boot/grub/grub.cfg | head -n 1`-1))
			sed -n '/^menuentry \"Install\|Ubuntu\"/,/^}/p' boot/grub/grub.cfg    | \
			sed -e 's/\"Install \(Ubuntu\)\"/\"Auto Install \1\"/'                  \
			    -e 's/\"\(Ubuntu\)\"/\"Auto Install \1\"/'                          \
			    -e "s/\(file\).*seed/\1=${INS_CFG}/"                                \
			    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
			sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                    | \
			sed -e 's/\(set default\)="1"/\1="0"/'                                  \
			    -e 's/\(set timeout\).*$/\1=5/'                                     \
			> grub.cfg
			mv grub.cfg boot/grub/
			# --- txt.cfg -----------------------------------------------------
			if [ -f isolinux/txt.cfg ]; then
				INS_ROW=$((`sed -n '/^label live$/ =' isolinux/txt.cfg | head -n 1`-1))
				sed -n '/label live-install$/,/append/p' isolinux/txt.cfg             | \
				sed -e 's/^\(label\).*/\1 autoinst/'                                    \
				    -e 's/\(Install\)/Auto \1/'                                         \
				    -e "s/\(file\).*seed/\1=${INS_CFG}/"                                \
				    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
				sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg                        \
				> txt.cfg
				mv txt.cfg isolinux/
			fi
		fi
		# -------------------------------------------------------------------------
#		rm -f ./casper/filesystem.squashfs
#		mksquashfs ../fsimg ./casper/filesystem.squashfs -mem 1G
#		ls -lht ./casper/
		FSIMG_SIZE=`LANG=C ls -lh ./casper/filesystem.squashfs | awk '{print $5;}'`
		# ---------------------------------------------------------------------
		if [ `echo "${VERSION} < 20.10" | bc` -eq 1 ]; then
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
	rm -rf ./ubuntu-live
	ls -lthLgG ubuntu*
	echo メディアは ${FSIMG_SIZE} 以上のメモリーを搭載する PC で使用して下さい。
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0 ${LIVE_ARCH} ${LIVE_VNUM}]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
# https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja
# sudo bash -c 'for i in `ls ubuntu-*-desktop-amd64.iso | sed -e '\''s/ubuntu-//'\'' -e '\''s/-desktop-amd64.iso//'\''`; do ./ubuntu-live.sh amd64 $i; done'
# == EOF ======================================================================
