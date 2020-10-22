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
	if [ "`which mmdebstrap 2> /dev/null`" = "" ]; then
		apt -y install mmdebstrap debootstrap squashfs-tools xorriso isolinux
	fi
# =============================================================================
	if [ "${INP_ARCH}" = "i386" ]; then
		IMG_ARCH="686"
	else
		IMG_ARCH="amd64"
	fi
	echo "-- architecture: ${INP_ARCH} --------------------------------------------------------"
	# -------------------------------------------------------------------------
	case "${INP_SUITE}" in
		"stable"  | "buster"   | 10* ) DEB_SUITE="stable";;
		"testing" | "bullseye" | 11* ) DEB_SUITE="testing";;
		*                            ) DEB_SUITE="";;
	esac
	# -------------------------------------------------------------------------
	DIR_TOP=./${PGM_NAME}/${DEB_SUITE}.${INP_ARCH}
# -----------------------------------------------------------------------------
	echo "-- make directory -------------------------------------------------------------"
	rm -rf   ${DIR_TOP}/media ${DIR_TOP}/cdimg ${DIR_TOP}/fsimg ${DIR_TOP}/_work
	mkdir -p ${DIR_TOP}/media ${DIR_TOP}/cdimg ${DIR_TOP}/fsimg ${DIR_TOP}/_work
# =============================================================================
	echo "--- debootstrap ---------------------------------------------------------------"
	LIVE_VOLID="d-live ${INP_SUITE} lx ${INP_ARCH}"
	echo "---- network install ----------------------------------------------------------"
	mmdebstrap --variant=minbase --mode=sudo --architectures=${INP_ARCH} ${INP_SUITE} ${DIR_TOP}/fsimg/
# =============================================================================
	echo "-- make inst-net.sh -----------------------------------------------------------"
	cat <<- _EOT_SH_ > ${DIR_TOP}/fsimg/inst-net.sh
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
		 	# -------------------------------------------------------------------------
		 	echo "# -----------------------------------------------------------------------------"
		 	cat /etc/apt/sources.list
		 	echo "# -----------------------------------------------------------------------------"
		 	APT_ADDRE="\`awk '(/^deb/) && !(\$2~/security/) && !(\$3~/update/) {print \$2;}' /etc/apt/sources.list | uniq\`"
		 	APT_SUITE="\`awk '(/^deb/) && !(\$2~/security/) && !(\$3~/update/) {print \$3;}' /etc/apt/sources.list | uniq\`"
		 	# -------------------------------------------------------------------------
		 	if [ "\${APT_ADDRE}" = "" ]; then APT_ADDRE="http://ftp.debian.org/debian"; fi
		 	if [ "\${APT_SUITE}" = "" ]; then APT_SUITE="${INP_SUITE}"; fi
		 	# -------------------------------------------------------------------------
		 	cat <<- _EOT_ > /etc/apt/sources.list
		 		deb \${APT_ADDRE} \${APT_SUITE} main non-free contrib
		 		deb-src \${APT_ADDRE} \${APT_SUITE} main non-free contrib

		 		# deb http://security.debian.org/debian-security \${APT_SUITE}/updates main contrib non-free
		 		# deb-src http://security.debian.org/debian-security \${APT_SUITE}/updates main contrib non-free

		 		# ${INP_SUITE}-updates, previously known as 'volatile'
		 		deb \${APT_ADDRE} \${APT_SUITE}-updates main contrib non-free
		 		deb-src \${APT_ADDRE} \${APT_SUITE}-updates main contrib non-free
		_EOT_
		 	# -------------------------------------------------------------------------
		 	if [ "${DEB_SUITE}" != "testing" ]; then
		 		sed -i /etc/apt/sources.list \\
		 		    -e 's/^# \(deb\)/\1/g'
		 	fi
		# -- module update, upgrade, install ------------------------------------------
		 	echo "---- module update, upgrade, install ------------------------------------------"
		 	apt update                                                             && \\
		 	apt upgrade      -q -y                                                 && \\
		 	apt full-upgrade -q -y                                                 && \\
		 	apt install      -q -y                                                    \\
		 	    linux-headers-${IMG_ARCH} linux-image-${IMG_ARCH}                              && \\
		 	apt install      -q -y                                                    \\
		 	    acpid apache2 apt-show-versions aptitude bc bind9 bind9utils bison    \\
		 	    btrfs-progs build-essential cifs-utils clamav curl debconf-i18n       \\
		 	    dnsutils dpkg-repack fdclone flex grub-efi ibus-mozc ifupdown indent  \\
		 	    isc-dhcp-server isolinux less libappindicator3-1 libapt-pkg-perl      \\
		 	    libauthen-pam-perl libelf-dev libio-pty-perl libnet-ssleay-perl       \\
		 	    live-config live-task-base lvm2                                       \\
		 	    nano network-manager nfs-common nfs-kernel-server ntfs-3g ntp ntpdate \\
		 	    open-vm-tools open-vm-tools-desktop perl powermgmt-base rsync samba   \\
		 	    smbclient snapd squashfs-tools sudo task-desktop task-english         \\
		 	    task-japanese task-japanese-desktop task-laptop task-lxde-desktop     \\
		 	    task-ssh-server task-web-server traceroute usbutils vim vsftpd wget   \\
		 	    wpagui xorriso xterm                                               || \\
		 	fncEnd \$?
		# -- source.list custom -------------------------------------------------------
		 	echo "---- source.list custom -------------------------------------------------------"
		 	case "${DEB_SUITE}" in
		 		"stable"  )
		 			echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Buster/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
		 			curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Debian_Buster/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
		 			if [ -f Release.key ]; then rm -f Release.key; fi
		 			;;
		 		"testing" )
		 			echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
		 			curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Debian_Sid/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
		 			if [ -f Release.key ]; then rm -f Release.key; fi
		 			;;
		 		*         )
		 			;;
		 	esac
		# -- module update, upgrade, install ------------------------------------------
		 	echo "---- module update, upgrade, install ------------------------------------------"
		 	apt update                                                             && \\
		 	apt upgrade      -q -y                                                 && \\
		 	apt full-upgrade -q -y                                                 && \\
		 	apt install      -q -y                                                    \\
		 	    ungoogled-chromium                                                 || \\
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
		# -- desktop setting ----------------------------------------------------------
		 	if [ -f /etc/xdg/autostart/diodon-autostart.desktop -a -f /etc/xdg/autostart/clipit-startup.desktop ]; then
		 		rm /etc/xdg/autostart/clipit-startup.desktop
		 	fi
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
		 		if [ "\`which vim 2> /dev/null\`" = "" ]; then
		 				sed -i .vimrc                    \\
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
		 	CMD_UADD="\`which useradd\`"
		 	CMD_UDEL="\`which userdel\`"
		 	CMD_GADD="\`which groupadd\`"
		 	CMD_GDEL="\`which groupdel\`"
		 	CMD_GPWD="\`which gpasswd\`"
		 	CMD_FALS="\`which false\`"
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
	sed -i ${DIR_TOP}/fsimg/inst-net.sh -e 's/^ //g'
# =============================================================================
	echo "-- chroot ---------------------------------------------------------------------"
	echo "debian-live" > ${DIR_TOP}/fsimg/etc/hostname
	echo -e "127.0.1.1\tdebian-live" >> ${DIR_TOP}/fsimg/etc/hosts
	rm -f ${DIR_TOP}/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ${DIR_TOP}/fsimg/etc/localtime
	# -------------------------------------------------------------------------
	mount --bind /dev     ${DIR_TOP}/fsimg/dev
	mount --bind /dev/pts ${DIR_TOP}/fsimg/dev/pts
	mount --bind /proc    ${DIR_TOP}/fsimg/proc
	mount --bind /sys     ${DIR_TOP}/fsimg/sys
	# -------------------------------------------------------------------------
	LC_ALL=C LANG=C LANGUAGE=C chroot ${DIR_TOP}/fsimg/ /bin/bash /inst-net.sh
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount ${DIR_TOP}/fsimg/sys     || umount -lf ${DIR_TOP}/fsimg/sys
	umount ${DIR_TOP}/fsimg/proc    || umount -lf ${DIR_TOP}/fsimg/proc
	umount ${DIR_TOP}/fsimg/dev/pts || umount -lf ${DIR_TOP}/fsimg/dev/pts
	umount ${DIR_TOP}/fsimg/dev     || umount -lf ${DIR_TOP}/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
# -----------------------------------------------------------------------------
	echo "-- cleaning -------------------------------------------------------------------"
	find ${DIR_TOP}/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ${DIR_TOP}/fsimg/inst-net.sh                  \
	       ${DIR_TOP}/fsimg/root/.bash_history           \
	       ${DIR_TOP}/fsimg/root/.viminfo                \
	       ${DIR_TOP}/fsimg/tmp/*                        \
	       ${DIR_TOP}/fsimg/var/cache/apt/*.bin          \
	       ${DIR_TOP}/fsimg/var/cache/apt/archives/*.deb
# -----------------------------------------------------------------------------
	echo "--- download system file ------------------------------------------------------"
	pushd ${DIR_TOP} > /dev/null
		TAR_INST=debian-cd_info-${INP_SUITE}-${INP_ARCH}.tar.gz
		if [ ! -f "./${TAR_INST}" ]; then
			TAR_URL="https://cdimage.debian.org/debian/dists/${INP_SUITE}/main/installer-${INP_ARCH}/current/images/cdrom/debian-cd_info.tar.gz"
			wget -O "./${TAR_INST}" "${TAR_URL}"
		fi
		tar -xzf "./${TAR_INST}" -C ./_work/
	popd > /dev/null
	# ---------------------------------------------------------------------
	echo "--- make cdimg directory ------------------------------------------------------"
	mkdir -p ${DIR_TOP}/cdimg/boot/grub \
	         ${DIR_TOP}/cdimg/isolinux  \
	         ${DIR_TOP}/cdimg/live      \
	         ${DIR_TOP}/cdimg/.disk
	# ---------------------------------------------------------------------
	echo "-- make system loading file ---------------------------------------------------"
	NOW_TIME=`date +"%Y-%m-%d %H:%M"`
	# ---------------------------------------------------------------------
	echo "--- make .disk's file ---------------------------------------------------------"
	echo -en "Custom Debian GNU/Linux Live ${INP_SUITE}-${INP_ARCH} lxde ${NOW_TIME}" > ${DIR_TOP}/cdimg/.disk/info
	# ---------------------------------------------------------------------
	echo "--- copy system file ----------------------------------------------------------"
	pushd ${DIR_TOP}/_work/grub > /dev/null
		find . -depth -print | cpio -pdm ../../cdimg/boot/grub/
	popd > /dev/null
	if [ ! -f ${DIR_TOP}/cdimg/boot/grub/loopback.cfg ]; then
		echo -n "source /grub/grub.cfg" > ${DIR_TOP}/cdimg/boot/grub/loopback.cfg
	fi
	cp -p  ${DIR_TOP}/_work/splash.png                                 ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/_work/menu.cfg                                   ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/_work/stdmenu.cfg                                ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/_work/isolinux.cfg                               ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/ISOLINUX/isolinux.bin              ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/hdt.c32      ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/ldlinux.c32  ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/libcom32.c32 ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/libgpl.c32   ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/libmenu.c32  ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/libutil.c32  ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/modules/bios/vesamenu.c32 ${DIR_TOP}/cdimg/isolinux/
	cp -p  ${DIR_TOP}/fsimg/usr/lib/syslinux/memdisk                   ${DIR_TOP}/cdimg/isolinux/
	cp -pr ${DIR_TOP}/fsimg/boot/*                                     ${DIR_TOP}/cdimg/live/
	# ---------------------------------------------------------------------
	echo "--- copy EFI directory --------------------------------------------------------"
	mount -r -o loop ${DIR_TOP}/cdimg/boot/grub/efi.img ${DIR_TOP}/media/
	pushd ${DIR_TOP}/media/efi/ > /dev/null
		find . -depth -print | cpio -pdm ../../cdimg/EFI/
	popd > /dev/null
	umount ${DIR_TOP}/media/
	# ---------------------------------------------------------------------
	VER_KRNL=`find ${DIR_TOP}/fsimg/boot/ -name "vmlinuz*" -print | sed -e 's/.*vmlinuz-//g' -e 's/-amd64//g' -e 's/-686//g'`
	echo "--- edit grub.cfg file --------------------------------------------------------"
	cat <<- _EOT_ >> ${DIR_TOP}/cdimg/boot/grub/grub.cfg
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
	cat <<- _EOT_ > ${DIR_TOP}/cdimg/isolinux/menu.cfg
		INCLUDE stdmenu.cfg
		MENU title Main Menu
		DEFAULT Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		LABEL Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})
		  SAY "Booting Debian GNU/Linux Live (kernel ${VER_KRNL}-${IMG_ARCH})..."
		  linux /live/vmlinuz-${VER_KRNL}-${IMG_ARCH} noeject
		  APPEND initrd=/live/initrd.img-${VER_KRNL}-${IMG_ARCH} boot=live components locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-model=jp106 keyboard-layouts=jp
_EOT_
	echo "--- edit isolinux.cfg file ----------------------------------------------------"
	sed -i ${DIR_TOP}/cdimg/isolinux/isolinux.cfg \
	    -e 's/^\(timeout\) .*/\1 50/'
# -- file compress ------------------------------------------------------------
	echo "-- make file system image -----------------------------------------------------"
	rm -f ${DIR_TOP}/cdimg/live/filesystem.squashfs
	mksquashfs ${DIR_TOP}/fsimg ${DIR_TOP}/cdimg/live/filesystem.squashfs -noappend
	ls -lht ${DIR_TOP}/cdimg/live/
# -- make iso image -----------------------------------------------------------
	echo "-- make iso image -------------------------------------------------------------"
	pushd ${DIR_TOP}/cdimg > /dev/null
		find . ! -name "md5sum.txt" -type f -exec md5sum -b {} \; > md5sum.txt
		xorriso -as mkisofs                                                         \
		    -quiet                                                                  \
		    -iso-level 3                                                            \
		    -full-iso9660-filenames                                                 \
		    -volid "${LIVE_VOLID}"                                                  \
		    -eltorito-boot isolinux/isolinux.bin                                    \
		    -eltorito-catalog isolinux/boot.cat                                     \
		    -no-emul-boot -boot-load-size 4 -boot-info-table                        \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin                           \
		    -eltorito-alt-boot                                                      \
		    -e boot/grub/efi.img                                                    \
		    -no-emul-boot -isohybrid-gpt-basdat                                     \
		    -output ../../debian-live-${INP_SUITE}-${INP_ARCH}-lxde-debootstrap.iso \
		    .
	popd > /dev/null
	ls -lht ./${PGM_NAME}/
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
