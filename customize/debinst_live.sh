#!/bin/bash
# *****************************************************************************
# debootstrap for stable/testing cdrom
# *****************************************************************************
#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了

	INP_ARCH=$1
	INP_SUITE=$2
#	INP_NETWORK=$3

	if [ "${INP_ARCH}" = "" ] || [ "${INP_SUITE}" = "" ]; then
		echo "$0 [i386 | amd64] [stable | testing | ...]"
		exit 1
	fi

	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	if [ "`LANG=C dpkg -l debootstrap squashfs-tools xorriso isolinux | awk '$1==\"un\" {print $1;}'`" != "" ]; then
		apt -y install debootstrap squashfs-tools xorriso isolinux
	fi
# =============================================================================
	echo "-- initialize -----------------------------------------------------------------"
	rm -rf   ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg ./debootstrap/_work
	mkdir -p ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg ./debootstrap/_work
# -----------------------------------------------------------------------------
	if [ "${INP_ARCH}" = "i386" ]; then
		IMG_ARCH="686"
	else
		IMG_ARCH="amd64"
	fi
	echo "-- architecture: ${INP_ARCH} --------------------------------------------------------"
# =============================================================================
	echo "--- debootstrap ---------------------------------------------------------------"
	LIVE_VOLID="d-live ${INP_SUITE} lx ${INP_ARCH}"
	echo "---- network install ----------------------------------------------------------"
	mmdebstrap --variant=minbase --mode=sudo --architectures=${INP_ARCH} ${INP_SUITE} ./debootstrap/fsimg/ http://ftp.debian.org/debian
	# -------------------------------------------------------------------------
	case "${INP_SUITE}" in
		"testing" | "bullseye" | 11* ) DEB_SUITE="testing";;
		"stable"  | "buster"   | 10* ) DEB_SUITE="stable";;
		*                            ) DEB_SUITE="";;
	esac
# =============================================================================
	echo "-- make inst-net.sh -----------------------------------------------------------"
	cat <<- _EOT_SH_ > ./debootstrap/fsimg/inst-net.sh
		#!/bin/bash
		# -----------------------------------------------------------------------------
		 	set -m								# ジョブ制御を有効にする
		 	set -eu								# ステータス0以外と未定義変数の参照で終了
		 	echo "*******************************************************************************"
		 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : start [\$0]"
		 	echo "*******************************************************************************"
		# -- terminate ----------------------------------------------------------------
		fncEnd() {
		 	echo "--- terminate -----------------------------------------------------------------"
		 	RET_STS=\$1

		 	history -c

		 	echo "*******************************************************************************"
		 	echo "\`date +"%Y/%m/%d %H:%M:%S"\` : end [\$0]"
		 	echo "*******************************************************************************"
		 	exit \${RET_STS}
		}
		# -- initialize ---------------------------------------------------------------
		 	echo "--- initialize ----------------------------------------------------------------"
		 	trap 'fncEnd 1' 1 2 3 15
		 	export PS1="(chroot) "
		# -- module install -----------------------------------------------------------
		 	echo "--- module install ------------------------------------------------------------"
		 	cat <<- '_EOT_' > /etc/apt/sources.list
		 		deb http://ftp.debian.org/debian ${INP_SUITE} main non-free contrib
		 		deb-src http://ftp.debian.org/debian ${INP_SUITE} main non-free contrib

		 		# deb http://security.debian.org/debian-security ${INP_SUITE}/updates main contrib non-free
		 		# deb-src http://security.debian.org/debian-security ${INP_SUITE}/updates main contrib non-free

		 		# ${INP_SUITE}-updates, previously known as 'volatile'
		 		deb http://ftp.debian.org/debian ${INP_SUITE}-updates main contrib non-free
		 		deb-src http://ftp.debian.org/debian ${INP_SUITE}-updates main contrib non-free
		_EOT_
		# -- module update, upgrade, install ------------------------------------------
		 	echo "---- module update, upgrade, install ------------------------------------------"
		 	apt update                                                             && \\
		 	apt upgrade      -q -y                                                 && \\
		 	apt full-upgrade -q -y                                                 && \\
		 	apt install      -q -y                                                    \\
		 	    acpid apache2 apt-show-versions aptitude bc bind9 bind9utils bison    \\
		 	    btrfs-progs build-essential cifs-utils clamav curl debconf-i18n       \\
		 	    dnsutils dpkg-repack fdclone flex grub-efi ibus-mozc ifupdown indent  \\
		 	    isc-dhcp-server isolinux less libappindicator3-1 libapt-pkg-perl      \\
		 	    libauthen-pam-perl libelf-dev libio-pty-perl libnet-ssleay-perl       \\
		 	    linux-headers-${IMG_ARCH} linux-image-${IMG_ARCH} live-config live-task-base lvm2 \\
		 	    nano network-manager nfs-common nfs-kernel-server ntfs-3g ntp ntpdate \\
		 	    open-vm-tools open-vm-tools-desktop perl powermgmt-base rsync samba   \\
		 	    smbclient snapd squashfs-tools sudo task-desktop task-english         \\
		 	    task-japanese task-japanese-desktop task-laptop task-lxde-desktop     \\
		 	    task-ssh-server task-web-server traceroute usbutils vim vsftpd wget   \\
		 	    wpagui xorriso xterm                                               || \\
		 	fncEnd \$?
		# -- module fix broken --------------------------------------------------------
		 	echo "---- module fix broken --------------------------------------------------------"
		 	apt install      -q -y --fix-broken
		# -- module autoremove, autoclean, clean --------------------------------------
		 	echo "---- module autoremove, autoclean, clean --------------------------------------"
		 	apt autoremove   -q -y                                                 && \\
		 	apt autoclean    -q                                                    && \\
		 	apt clean        -q                                                    || \\
		 	fncEnd \$?
		# -- localize -----------------------------------------------------------------
		 	echo "--- localize ------------------------------------------------------------------"
		 	if [ -f /etc/locale.gen ]; then
		 		sed -i /etc/locale.gen                  \\
		 		    -e 's/^[A-Za-z]/# &/g'              \\
		 		    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \\
		 		    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
		 		locale-gen
		 		update-locale LANG=ja_JP.UTF-8
		 	fi
		 	sed -i /etc/xdg/lxsession/LXDE/autostart               \\
		 	    -e '\$a@setxkbmap -layout jp -option ctrl:swapcase'
		# -- google chrome install ----------------------------------------------------
		 	if [ "${IMG_ARCH}" = "amd64" ]; then
		 		echo "---- chrome install -----------------------------------------------------------"
		 		if [ "${DEB_SUITE}" = "stable" ]; then
		 			VER_CHROM="79.0.3945.117-1.buster1"
		 			if [ ! -f ungoogled-chromium_\${VER_CHROM}_amd64.deb ] || [ ! -f ungoogled-chromium-common_\${VER_CHROM}_amd64.deb ]; then
		 				curl -L -# -R -S -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium-common_\${VER_CHROM}_amd64.deb"  \\
		 				                 -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium-driver_\${VER_CHROM}_amd64.deb"  \\
		 				                 -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium-l10n_\${VER_CHROM}_all.deb"      \\
		 				                 -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium-sandbox_\${VER_CHROM}_amd64.deb" \\
		 				                 -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium-shell_\${VER_CHROM}_amd64.deb"   \\
		 				                 -O "https://github.com/Eloston/ungoogled-chromium-binaries/releases/download/\${VER_CHROM}/ungoogled-chromium_\${VER_CHROM}_amd64.deb"      || \\
		 				fncEnd \$?
		 			fi
		 			apt install      -q -y                             \\
		 			    libminizip1 libre2-5 libevent-2.1-6 libvpx5 && \\
		 			apt autoremove   -q -y                          && \\
		 			apt autoclean    -q                             && \\
		 			apt clean        -q                             && \\
		 			dpkg -i ungoogled-chromium_*.deb                   \\
		 			        ungoogled-chromium-*.deb                && \\
		 			rm -f   ungoogled-chromium*                     || \\
		 			fncEnd \$?
		 		else
		 			curl -L -# -O -R -S "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" && \\
		 			dpkg -i google-chrome-stable_current_amd64.deb                                                  && \\
		 			rm -f   google-chrome-stable_current_amd64.deb                                                  || \\
		 			fncEnd \$?
		 		fi
		 	fi
		# -- systemctl ----------------------------------------------------------------
		 	echo "--- systemctl -----------------------------------------------------------------"
		 	systemctl  enable clamav-freshclam
		 	systemctl  enable ssh
		 	systemctl disable apache2
		 	systemctl disable vsftpd
		 	if [ "\`find /lib/systemd/system/ -name named.service -print\`" = "" ]; then
		 		systemctl  enable bind9
		 	else
		 		systemctl  enable named
		 	fi
		 	systemctl disable isc-dhcp-server
		#	systemctl disable isc-dhcp-server6
		 	systemctl  enable smbd
		 	systemctl  enable nmbd
		# -- freshclam ----------------------------------------------------------------
		 	echo "--- freshclam -----------------------------------------------------------------"
		 	freshclam --show-progress
		# -- network interfaces -------------------------------------------------------
		 	echo "--- network interfaces --------------------------------------------------------"
		 	cat <<- '_EOT_' > /etc/network/interfaces.d/setup
		 		auto lo
		 		iface lo inet loopback

		 		auto eth0
		 		iface eth0 inet dhcp
		_EOT_
		# -- root and user's setting --------------------------------------------------
		 	echo "--- root and user's setting ---------------------------------------------------"
		 	for TARGET in "/etc/skel" "/root"
		 	do
		 		pushd \${TARGET} > /dev/null
		 		echo "---- .bashrc ------------------------------------------------------------------"
		 		cat <<- '_EOT_' >> .bashrc
		 			# --- 日本語文字化け対策 ---
		 			case "\${TERM}" in
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
		 		echo "---- .curlrc ------------------------------------------------------------------"
		 		cat <<- '_EOT_' > .curlrc
		 			location
		 			progress-bar
		 			remote-time
		 			show-error
		_EOT_
		 		popd > /dev/null
		 	done
		 	# -------------------------------------------------------------------------
		 	useradd -m user -s \`which bash\`
		 	smbpasswd -a user -n
		 	echo -e "live\\nlive\\n" | passwd user
		 	echo -e "live\\nlive\\n" | smbpasswd user
		# --- open-vm-tools -----------------------------------------------------------
		 	echo "--- open vm tools -------------------------------------------------------------"
		 	mkdir -p /media/hgfs
		 	chown user.user /media/hgfs
		 	sed -i /etc/fstab                                                                                  \\
		 	    -e '\$a.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,noauto,users,defaults 0 0'
		 	sed -i /etc/fuse.conf                \\
		 	    -e 's/#\(user_allow_other\)/\1/'
		# -- sshd ---------------------------------------------------------------------
		 	echo "--- sshd ----------------------------------------------------------------------"
		 	sed -i /etc/ssh/sshd_config                                        \\
		 	    -e 's/^PermitRootLogin .*/PermitRootLogin yes/'                \\
		 	    -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \\
		 	    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'                 \\
		 	    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d'               \\
		 	    -e '\$aUseDNS no\nIgnoreUserKnownHosts no'                      \\
		 	    -e 's/^UsePrivilegeSeparation/#&/'                             \\
		 	    -e 's/^KeyRegenerationInterval/#&/'                            \\
		 	    -e 's/^ServerKeyBits/#&/'                                      \\
		 	    -e 's/^RSAAuthentication/#&/'                                  \\
		 	    -e 's/^RhostsRSAAuthentication/#&/'
		# -- ftpd ---------------------------------------------------------------------
		 	echo "--- ftpd ----------------------------------------------------------------------"
		 	touch /etc/ftpusers					#
		 	touch /etc/vsftpd.conf				#
		 	touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
		 	touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
		 	touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
		 	touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
		 	chmod 0600 /etc/ftpusers               \\
		 	           /etc/vsftpd.conf            \\
		 	           /etc/vsftpd.chroot_list     \\
		 	           /etc/vsftpd.user_list       \\
		 	           /etc/vsftpd.banned_emails   \\
		 	           /etc/vsftpd.email_passwords
		 	sed -i /etc/ftpusers \\
		 	    -e 's/root/# &/'
		 	sed -i /etc/vsftpd.conf                                           \\
		 	    -e 's/^\(listen\)=.*\$/\1=NO/'                                 \\
		 	    -e 's/^\(listen_ipv6\)=.*\$/\1=YES/'                           \\
		 	    -e 's/^\(anonymous_enable\)=.*\$/\1=NO/'                       \\
		 	    -e 's/^\(local_enable\)=.*\$/\1=YES/'                          \\
		 	    -e 's/^#\(write_enable\)=.*\$/\1=YES/'                         \\
		 	    -e 's/^#\(local_umask\)=.*\$/\1=022/'                          \\
		 	    -e 's/^\(dirmessage_enable\)=.*\$/\1=NO/'                      \\
		 	    -e 's/^\(use_localtime\)=.*\$/\1=YES/'                         \\
		 	    -e 's/^\(xferlog_enable\)=.*\$/\1=YES/'                        \\
		 	    -e 's/^\(connect_from_port_20\)=.*\$/\1=YES/'                  \\
		 	    -e 's/^#\(xferlog_std_format\)=.*\$/\1=NO/'                    \\
		 	    -e 's/^#\(idle_session_timeout\)=.*\$/\1=300/'                 \\
		 	    -e 's/^#\(data_connection_timeout\)=.*\$/\1=30/'               \\
		 	    -e 's/^#\(ascii_upload_enable\)=.*\$/\1=YES/'                  \\
		 	    -e 's/^#\(ascii_download_enable\)=.*\$/\1=YES/'                \\
		 	    -e 's/^#\(chroot_local_user\)=.*\$/\1=NO/'                     \\
		 	    -e 's/^#\(chroot_list_enable\)=.*\$/\1=NO/'                    \\
		 	    -e 's~^#\(chroot_list_file\)=.*\$~\1=/etc/vsftpd.chroot_list~' \\
		 	    -e 's/^#\(ls_recurse_enable\)=.*\$/\1=YES/'                    \\
		 	    -e 's/^\(pam_service_name\)=.*\$/\1=vsftpd/'                   \\
		 	    -e '\$atcp_wrappers=YES'                                       \\
		 	    -e '\$auserlist_enable=YES'                                    \\
		 	    -e '\$auserlist_deny=YES'                                      \\
		 	    -e '\$auserlist_file=/etc/vsftpd.user_list'                    \\
		 	    -e '\$achmod_enable=YES'                                       \\
		 	    -e '\$aforce_dot_files=YES'                                    \\
		 	    -e '\$adownload_enable=YES'                                    \\
		 	    -e '\$avsftpd_log_file=/var/log/vsftpd.log'                    \\
		 	    -e '\$adual_log_enable=NO'                                     \\
		 	    -e '\$asyslog_enable=NO'                                       \\
		 	    -e '\$alog_ftp_protocol=NO'                                    \\
		 	    -e '\$aftp_data_port=20'                                       \\
		 	    -e '\$apasv_enable=YES'
		# -- smb.conf -----------------------------------------------------------------
		 	echo "--- smb.conf ------------------------------------------------------------------"
		 	CMD_UADD=`which useradd`
		 	CMD_UDEL=`which userdel`
		 	CMD_GADD=`which groupadd`
		 	CMD_GDEL=`which groupdel`
		 	CMD_GPWD=`which gpasswd`
		 	CMD_FALS=`which false`
		 	testparm -s -v |                                                                        \\
		 	sed -e 's/\\(dos charset\\) =.*\$/\\1 = CP932/'                                             \\
		 	    -e 's/\\(security\\) =.*\$/\\1 = USER/'                                                 \\
		 	    -e 's/\\(server role\\) =.*\$/\\1 = standalone server/'                                 \\
		 	    -e 's/\\(pam password change\\) =.*\$/\\1 = Yes/'                                       \\
		 	    -e 's/\\(load printers\\) =.*\$/\\1 = No/'                                              \\
		 	    -e 's~\\(log file\\) =.*\$~\\1 = /var/log/samba/log.%m~'                                \\
		 	    -e 's/\\(max log size\\) =.*\$/\\1 = 1000/'                                             \\
		 	    -e 's/\\(min protocol\\) =.*\$/\\1 = NT1/'                                              \\
		 	    -e 's/\\(server min protocol\\) =.*\$/\\1 = NT1/'                                       \\
		 	    -e 's~\\(printcap name\\) =.*\$~\\1 = /dev/null~'                                       \\
		 	    -e "s~\\(add user script\\) =.*\$~\\1 = \${CMD_UADD} %u~"                                \\
		 	    -e "s~\\(delete user script\\) =.*\$~\\1 = \${CMD_UDEL} %u~"                             \\
		 	    -e "s~\\(add group script\\) =.*\$~\\1 = \${CMD_GADD} %g~"                               \\
		 	    -e "s~\\(delete group script\\) =.*\$~\\1 = \${CMD_GDEL} %g~"                            \\
		 	    -e "s~\\(add user to group script\\) =.*\$~\\1 = \${CMD_GPWD} -a %u %g~"                 \\
		 	    -e "s~\\(delete user from group script\\) =.*\$~\\1 = \${CMD_GPWD} -d %u %g~"            \\
		 	    -e "s~\\(add machine script\\) =.*\$~\\1 = \${CMD_UADD} -d /dev/null -s \${CMD_FALS} %u~" \\
		 	    -e 's/\\(logon script\\) =.*\$/\\1 = logon.bat/'                                        \\
		 	    -e 's/\\(logon path\\) =.*\$/\\1 = \\\\\\\\%L\\\\profiles\\\\%U/'                               \\
		 	    -e 's/\\(domain logons\\) =.*\$/\\1 = Yes/'                                             \\
		 	    -e 's/\\(os level\\) =.*\$/\\1 = 35/'                                                   \\
		 	    -e 's/\\(preferred master\\) =.*\$/\\1 = Yes/'                                          \\
		 	    -e 's/\\(domain master\\) =.*\$/\\1 = Yes/'                                             \\
		 	    -e 's/\\(wins support\\) =.*\$/\\1 = Yes/'                                              \\
		 	    -e 's/\\(unix password sync\\) =.*\$/\\1 = No/'                                         \\
		 	    -e '/idmap config \\* : backend =/i \\\\tidmap config \\* : range = 1000-10000'         \\
		 	    -e 's/\\(admin users\\) =.*\$/\\1 = administrator/'                                     \\
		 	    -e 's/\\(printing\\) =.*\$/\\1 = bsd/'                                                  \\
		 	    -e '/map to guest =.*\$/d'                                                           \\
		 	    -e '/null passwords =.*\$/d'                                                         \\
		 	    -e '/obey pam restrictions =.*\$/d'                                                  \\
		 	    -e '/enable privileges =.*\$/d'                                                      \\
		 	    -e '/password level =.*\$/d'                                                         \\
		 	    -e '/client use spnego principal =.*\$/d'                                            \\
		 	    -e '/syslog =.*\$/d'                                                                 \\
		 	    -e '/syslog only =.*\$/d'                                                            \\
		 	    -e '/use spnego =.*\$/d'                                                             \\
		 	    -e '/paranoid server security =.*\$/d'                                               \\
		 	    -e '/dns proxy =.*\$/d'                                                              \\
		 	    -e '/time offset =.*\$/d'                                                            \\
		 	    -e '/usershare allow guests =.*\$/d'                                                 \\
		 	    -e '/idmap backend =.*\$/d'                                                          \\
		 	    -e '/idmap uid =.*\$/d'                                                              \\
		 	    -e '/idmap gid =.*\$/d'                                                              \\
		 	    -e '/winbind separator =.*\$/d'                                                      \\
		 	    -e '/acl check permissions =.*\$/d'                                                  \\
		 	    -e '/only user =.*\$/d'                                                              \\
		 	    -e '/share modes =.*\$/d'                                                            \\
		 	    -e '/nbt client socket address =.*\$/d'                                              \\
		 	    -e '/lsa over netlogon =.*\$/d'                                                      \\
		 	    -e '/.* = \$/d'                                                                      \\
		 	> ./smb.conf
		 	testparm -s ./smb.conf > /etc/samba/smb.conf
		 	rm -f ./smb.conf
		# -----------------------------------------------------------------------------
		 	echo "--- cleaning and exit ---------------------------------------------------------"
		 	fncEnd 0
		# -- EOF ----------------------------------------------------------------------
_EOT_SH_
	case "${INP_SUITE}" in
		"testing" | "bullseye" | 11* ) ;;
		*                            ) sed -i ./debootstrap/fsimg/inst-net.sh -e 's/^\( \t\t\)# \(deb\)/\1\2/g';;
	esac
	sed -i ./debootstrap/fsimg/inst-net.sh -e 's/^ //g'
# =============================================================================
	if [ -d "./debootstrap/rpack.${DEB_SUITE}.${INP_ARCH}/" ]; then
		echo "--- deb file copy -------------------------------------------------------------"
		mkdir -p ./debootstrap/fsimg/var/cache/apt/archives
		cp -p ./debootstrap/rpack.${DEB_SUITE}.${INP_ARCH}/*.deb ./debootstrap/fsimg/var/cache/apt/archives/ > /dev/null 2>&1
	fi
	if [ -d "./debootstrap/ungoogled-chromium/" ]; then
		echo "--- chrome file copy ----------------------------------------------------------"
		cp -p ./debootstrap/ungoogled-chromium/*.deb ./debootstrap/fsimg/ > /dev/null 2>&1
	fi
	# -------------------------------------------------------------------------
	echo "-- chroot ---------------------------------------------------------------------"
	echo "debian-live" >  ./debootstrap/fsimg/etc/hostname
	echo -e "127.0.1.1\tdebian-live" >> ./debootstrap/fsimg/etc/hosts
	rm -f ./debootstrap/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./debootstrap/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ./debootstrap/fsimg/dev
	mount --bind /dev/pts ./debootstrap/fsimg/dev/pts
	mount --bind /proc    ./debootstrap/fsimg/proc
	mount --bind /sys     ./debootstrap/fsimg/sys
	# -------------------------------------------------------------------------
	LC_ALL=C LANG=C LANGUAGE=C chroot ./debootstrap/fsimg/ /bin/bash /inst-net.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount ./debootstrap/fsimg/sys     || umount -lf ./debootstrap/fsimg/sys
	umount ./debootstrap/fsimg/proc    || umount -lf ./debootstrap/fsimg/proc
	umount ./debootstrap/fsimg/dev/pts || umount -lf ./debootstrap/fsimg/dev/pts
	umount ./debootstrap/fsimg/dev     || umount -lf ./debootstrap/fsimg/dev
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
	       ./debootstrap/fsimg/var/cache/apt/archives/*.deb   \
	       ./debootstrap/fsimg/ungoogled-chromium*            \
	       ./debootstrap/fsimg/google-chrome-*.deb
# -----------------------------------------------------------------------------
	echo "--- download system file ------------------------------------------------------"
	pushd ./debootstrap > /dev/null
		TAR_INST=debian-cd_info-${INP_SUITE}-${INP_ARCH}.tar.gz
		if [ ! -f "./${TAR_INST}" ]; then
			TAR_URL="https://cdimage.debian.org/debian/dists/${INP_SUITE}/main/installer-${INP_ARCH}/current/images/cdrom/debian-cd_info.tar.gz"
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
	NOW_TIME=`date +"%Y-%m-%d %H:%M"`
	# ---------------------------------------------------------------------
	echo "--- make .disk's file ---------------------------------------------------------"
	echo -en "Custom Debian GNU/Linux Live ${INP_SUITE}-${INP_ARCH} lxde ${NOW_TIME}" > ./debootstrap/cdimg/.disk/info
	# ---------------------------------------------------------------------
	echo "--- copy system file ----------------------------------------------------------"
	pushd ./debootstrap/_work/grub > /dev/null
		find . -depth -print | cpio -pdm ../../cdimg/boot/grub/
	popd > /dev/null
	if [ ! -f ./debootstrap/cdimg/boot/grub/loopback.cfg ]; then
		echo -n "source /grub/grub.cfg" > ./debootstrap/cdimg/boot/grub/loopback.cfg
	fi
	cp -p  ./debootstrap/_work/splash.png                                 ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/_work/menu.cfg                                   ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/_work/stdmenu.cfg                                ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/_work/isolinux.cfg                               ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/ISOLINUX/isolinux.bin              ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/hdt.c32      ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/ldlinux.c32  ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libcom32.c32 ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libgpl.c32   ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libmenu.c32  ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/libutil.c32  ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/modules/bios/vesamenu.c32 ./debootstrap/cdimg/isolinux/
	cp -p  ./debootstrap/fsimg/usr/lib/syslinux/memdisk                   ./debootstrap/cdimg/isolinux/
	cp -pr ./debootstrap/fsimg/boot/*                                     ./debootstrap/cdimg/live/
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
		  linux  /live/vmlinuz-${VER_KRNL}-${IMG_ARCH} boot=live components locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-model=jp106 keyboard-layouts=jp "\${loopback}" noeject
		  initrd /live/initrd.img-${VER_KRNL}-${IMG_ARCH}
		}

		set timeout=5
_EOT_
	echo "--- edit menu.cfg file --------------------------------------------------------"
	cat <<- _EOT_ > ./debootstrap/cdimg/isolinux/menu.cfg
		INCLUDE stdmenu.cfg
		MENU title Main Menu
		DEFAULT Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		LABEL Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		  SAY "Booting Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})..."
		  linux /live/vmlinuz-${VER_KRNL}-${IMG_ARCH} noeject
		  APPEND initrd=/live/initrd.img-${VER_KRNL}-${IMG_ARCH} boot=live components locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-model=jp106 keyboard-layouts=jp
_EOT_
	echo "--- edit isolinux.cfg file ----------------------------------------------------"
	sed -i ./debootstrap/cdimg/isolinux/isolinux.cfg \
	    -e 's/^\(timeout\) .*/\1 50/'
# -- file compress ------------------------------------------------------------
	echo "-- make file system image -----------------------------------------------------"
	rm -f ./debootstrap/cdimg/live/filesystem.squashfs
	mksquashfs ./debootstrap/fsimg ./debootstrap/cdimg/live/filesystem.squashfs -noappend
	ls -lht ./debootstrap/cdimg/live/
# -- make iso image -----------------------------------------------------------
	echo "-- make iso image -------------------------------------------------------------"
	pushd ./debootstrap/cdimg > /dev/null
		find . ! -name "md5sum.txt" -type f -exec md5sum -b {} \; > md5sum.txt
		xorriso -as mkisofs                                                    \
		    -quiet                                                             \
		    -iso-level 3                                                       \
		    -full-iso9660-filenames                                            \
		    -volid "${LIVE_VOLID}"                                             \
		    -eltorito-boot isolinux/isolinux.bin                               \
		    -eltorito-catalog isolinux/boot.cat                                \
		    -no-emul-boot -boot-load-size 4 -boot-info-table                   \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin                      \
		    -eltorito-alt-boot                                                 \
		    -e boot/grub/efi.img                                               \
		    -no-emul-boot -isohybrid-gpt-basdat                                \
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
