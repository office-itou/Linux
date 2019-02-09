#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.2-2018-05-10-EN.iso]                        *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V8.2-2018-05-10-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
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
#	rm -rf   ./knoppix-live
	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' > ./knoppix-live/fsimg/knoppix-setup.sh
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
			sed -i /etc/xdg/lxsession/LXDE/autostart               \
			    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
		# -- module install -----------------------------------------------------------
			echo "--- module install ------------------------------------------------------------"
			mkdir -p /lib/modules/4.9.0-8-amd64/modules.order   \
			         /lib/modules/4.9.0-8-amd64/modules.builtin \
			         /var/lib/nfs/sm.bak
			chown statd.nogroup /var/lib/nfs/sm.bak
			sed -i.orig /etc/resolv.conf                      \
			    -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
			sed -i.orig /etc/apt/sources.list                                \
			    -e 's/ftp.de.debian.org/ftp.debian.org/g'                    \
			    -e 's~\(deb http://debian-knoppix.alioth.debian.org\)~#\1~g'
			mkdir ~/apt
			mv /etc/apt/apt.conf.d/* ~/apt/
			cat <<- _EOT_ > /etc/apt/sources.list
				deb http://ftp.debian.org/debian stable main non-free contrib
				deb-src http://ftp.debian.org/debian stable main non-free contrib

				deb http://security.debian.org/debian-security stable/updates main contrib non-free
				deb-src http://security.debian.org/debian-security stable/updates main contrib non-free

				# stable-updates, previously known as 'volatile'
				deb http://ftp.debian.org/debian stable-updates main contrib non-free
				deb-src http://ftp.debian.org/debian stable-updates main contrib non-free
		_EOT_
		# -----------------------------------------------------------------------------
			dpkg --audit
			dpkg --configure -a
		# -----------------------------------------------------------------------------
			apt update                                                                \
			                                                                       && \
			apt upgrade      -y -o Dpkg::Options::=--force-confdef                    \
			                    -o Dpkg::Options::=--force-overwrite                  \
			                                                                          \
			                                                                       && \
			apt full-upgrade -y -o Dpkg::Options::=--force-confdef                    \
			                    -o Dpkg::Options::=--force-overwrite                  \
			                                                                          \
			                                                                       && \
			apt install      -y -o Dpkg::Options::=--force-confdef                    \
			                    -o Dpkg::Options::=--force-overwrite                  \
			    task-desktop task-lxde-desktop task-japanese task-japanese-desktop    \
			    task-laptop task-print-server task-ssh-server task-web-server         \
			    ibus-mozc vsftpd ntpdate fdclone indent bison flex                    \
			    open-vm-tools open-vm-tools-desktop                                   \
			                                                                       && \
			apt autoremove   -y                                                       \
			                                                                       && \
			apt autoclean    -y                                                       \
			                                                                       && \
			apt clean        -y
		# -----------------------------------------------------------------------------
			mv /etc/resolv.conf.orig /etc/resolv.conf
		# -- open vm tools ------------------------------------------------------------
			echo "--- open vm tools -------------------------------------------------------------"
			mkdir -p /mnt/hgfs
			sed -i /etc/fstab                                                                   \
			    -e '$a.host:/ /mnt/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults 0 0'
		# -- clamav -------------------------------------------------------------------
			echo "--- clamav --------------------------------------------------------------------"
			sed -i /etc/clamav/freshclam.conf \
			    -e 's/^NotifyClamd/#&/'
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
			touch /etc/ftpusers
			touch /etc/vsftpd.conf
			touch /etc/vsftpd.chroot_list
			touch /etc/vsftpd.user_list
			touch /etc/vsftpd.banned_emails
			touch /etc/vsftpd.email_passwords
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
		# -- samba --------------------------------------------------------------------
			echo "--- samba ---------------------------------------------------------------------"
			testparm -s /etc/samba/smb.conf | sed -e '/homes/ idos charset = CP932\nclient ipc min protocol = NT1\nclient min protocol = NT1\nserver min protocol = NT1\nidmap config * : range = 1000-10000\n' > ./smb.conf
			testparm -s ./smb.conf > /etc/samba/smb.conf
			rm -f ./smb.conf
		# -- root and user's setting --------------------------------------------------
			echo "--- root and user's setting ---------------------------------------------------"
			usermod -p live knoppix
			smbpasswd -a knoppix -n
			# -------------------------------------------------------------------------
			for USER_NAME in "skel" "root" "knoppix"
			do
				if [ "${USER_NAME}" == "skel" ]; then
					USER_HOME="/etc/skel"
				else
					USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
				fi
				pushd ${USER_HOME} > /dev/null
					echo "--- .bashrc -------------------------------------------------------------------"
					cat <<- _EOT_ >> .bashrc
						# --- 日本語文字化け対策 ---
						case "\${TERM}" in
						    "linux" ) export LANG=C;;
						    * )                    ;;
						esac
						export GTK_IM_MODULE=ibus
						export XMODIFIERS=@im=ibus
						export QT_IM_MODULE=ibus
		_EOT_
					echo "--- .vimrc --------------------------------------------------------------------"
					cat <<- _EOT_ > .vimrc
						set number              " Print the line number in front of each line.
						set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
						set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
						set listchars=tab:\>_   " Strings to use in 'list' mode and for the |:list| command.
						set nowrap              " This option changes how text is displayed.
						set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
						set laststatus=2        " The value of this option influences when the last window will have a status line always.
		_EOT_
					echo "--- .curlrc -------------------------------------------------------------------"
					cat <<- _EOT_ > .curlrc
						location
						progress-bar
						remote-time
						show-error
		_EOT_
					if [ "${USER_NAME}" != "skel" ]; then
						echo "--- xinput.d ------------------------------------------------------------------"
						mkdir .xinput.d
						ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
						chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
					fi
				popd > /dev/null
			done
		# -- cleaning -----------------------------------------------------------------
			echo "--- cleaning ------------------------------------------------------------------"
		#	apt-get -y autoremove
		#	apt-get autoclean
		#	apt-get clean
		#	find /var/log/ -type f -name \* -exec cp -f /dev/null {} \;
			fncEnd 0
		# -- EOF ----------------------------------------------------------------------
		# *****************************************************************************
		# <memo>
		#   [im-config]
		#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
		# -----------------------------------------------------------------------------
		# <memo>
		#   https://lists.debian.org/debian-user/2011/04/msg01168.html
		#   https://manpages.debian.org/stretch/apt/sources.list.5.ja.html
		#       Dpkg::Options::= --force-confdef or --force-confnew or --force-confold
		#       Acquire::Check-Valid-Until=no
		#   http://linux-memo.sakura.ne.jp/knoppix/knoppix_customjp080100_cust.html
		#       dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' | sort -nr | less
		#   https://qiita.com/cielavenir/items/8e0ce83d1f0d5e44c366
		#       apt-get install dpkg-repack
		#       fakeroot -u dpkg-repack PKGNAME
		#   https://qiita.com/komeda-shinji/items/339b8e14b3f8b658b288
		#       apt-mark hold パッケージ名
		#       apt-mark unhold パッケージ名
		#       echo "パッケージ名 hold" | dpkg --set-selections
		#       echo "パッケージ名 install" | sudo dpkg --set-selections
		#   dpkg-query -W -f='${Section}\t${binary:Package}\n' `dpkg -l | awk '/^[a-z]/ {print $2}'` | \
		#       grep -e "^education" -e "^games" -e "^graphics" -e "^mail" -e "^math" -e "^science" -e "^sound" -e "^video" -e "^web"
		# -----------------------------------------------------------------------------
		#       admin comm contrib/kernel contrib/otherosfs contrib/utils contrib/web
		#       database devel doc editors education electronics fonts games gnome
		#       gnustep graphics httpd interpreters introspection java javascript kde
		#       kernel knoppix libdevel libs lisp localization mail math metapackages
		#       misc net non-free/admin non-free/base non-free/doc non-free/games
		#       non-free/kernel non-free/metapackages non-free/net oldlibs otherosfs
		#       perl php python ruby science shells sound tex text unknown utils vcs
		#       video web x11 zope
		# -----------------------------------------------------------------------------
		#    dpkg-repack `dpkg -l | awk '/^ii/ {print $2;}'`
		# *****************************************************************************
_EOT_SH_
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "http://ftp.riken.jp/Linux/knoppix/knoppix-dvd/${LIVE_FILE}"
#		wget "http://ftp.kddilabs.jp/.017/Linux/packages/knoppix/knoppix-dvd/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	OS_ARCH=`dpkg --print-architecture`
	# -------------------------------------------------------------------------
	ISO2_START=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $2; }'`
	ISO2_COUNT=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $4; }'`
	# -------------------------------------------------------------------------
	dd if=./${LIVE_FILE} of=./knoppix-live/efiboot.img bs=512 skip=${ISO2_START} count=${ISO2_COUNT}
	# -------------------------------------------------------------------------
	mount -r -o loop ./${LIVE_FILE} ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/cdimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX_FS.iso ]; then
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/KNOPPIX_FS.iso
	fi
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX1_FS.iso ]; then
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 ./knoppix-live/KNOPPIX1_FS.iso
	fi
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1
	# -------------------------------------------------------------------------
	mount -r -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	mount -r -o loop ./knoppix-live/KNOPPIX1_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	rm -f ./knoppix-live/KNOPPIX_FS.tmp  \
	      ./knoppix-live/KNOPPIX1_FS.tmp \
	      ./knoppix-live/filelist.txt
	# -----------------------------------------------------------------------------
	if [ -d ./knoppix-live/rpack.knoppix82 ]; then
		cp -p ./knoppix-live/rpack.knoppix82/*.deb ./knoppix-live/fsimg/var/cache/apt/archives/
	fi
	if [ -d ./knoppix-live/clamav ]; then
		cp -p ./knoppix-live/clamav/*.cvd     ./knoppix-live/fsimg/var/lib/clamav/
	fi
# =============================================================================
	rm -f ./knoppix-live/fsimg/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
	sed -i ./knoppix-live/fsimg/etc/adjtime  -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/rc.local -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 bind9 ssh samba"/g'
	# -------------------------------------------------------------------------
	mount --bind /dev     ./knoppix-live/fsimg/dev
	mount --bind /dev/pts ./knoppix-live/fsimg/dev/pts
	mount --bind /proc    ./knoppix-live/fsimg/proc
#	mount --bind /sys     ./knoppix-live/fsimg/sys
	# -------------------------------------------------------------------------
#	cp -p ./knoppix-setup.sh ./knoppix-live/fsimg/
	chroot ./knoppix-live/fsimg /bin/bash /knoppix-setup.sh $1 $2
	RET_STS=$?
	# -------------------------------------------------------------------------
#	umount ./knoppix-live/fsimg/sys     || umount -lf ./knoppix-live/fsimg/sys
	umount ./knoppix-live/fsimg/proc    || umount -lf ./knoppix-live/fsimg/proc
	umount ./knoppix-live/fsimg/dev/pts || umount -lf ./knoppix-live/fsimg/dev/pts
	umount ./knoppix-live/fsimg/dev     || umount -lf ./knoppix-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	find   ./knoppix-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb \
	       ./knoppix-live/fsimg/knoppix-setup.sh
# =============================================================================
	if [ "${OS_ARCH}" = "i386" ]; then
		LIVE_VOLID="KNOPPIX_8"
		LIVE_VOLID_FS="KNOPPIX_FS"
		LIVE_VOLID_FS1="KNOPPIX_ADDONS1"
	else
		LIVE_VOLID=`volname ./${LIVE_FILE}`
		LIVE_VOLID_FS=`volname ./knoppix-live/KNOPPIX_FS.iso`
		LIVE_VOLID_FS1=`volname ./knoppix-live/KNOPPIX1_FS.iso`
	fi
	pushd ./knoppix-live/fsimg > /dev/null
		find usr/share/ -maxdepth 1 -type d \
			| grep -v -e "/$" \
			| grep -e "/backgrounds$\|/blender$\|/carddecks$\|/denemo$\|/dia$\|/doc$\|\
				/dvb$\|/edict$\|/emacs$\|/etoys$\|/fonts$\|/foomatic$\|/games$\|/gcompris$\|\
				/gimp$\|/gir-1.0$\|/gnome$\|/help$\|/hplip$\|/i18n$\|/ibus-table$\|/icons$\|\
				/inkscape$\|/java$\|/jitsi$\|/kde4$\|/kdenlive$\|/kf5$\|/kiten$\|/kstars$\|\
				/libreoffice$\|/locale$\|/man$\|/matplotlib$\|/maxima$\|/midi$\|/mlt$\|\
				/mythes$\|/nmap$\|/opencv$\|/perl$\|/perl5$\|/phpmyadmin$\|/pixmaps$\|\
				/poppler$\|/proj$\|/qt4$\|/qt5$\|/scilab$\|/scribus$\|/shutter$\|/sounds$\|\
				/tesseract-ocr$\|/texlive$\|/texmacs$\|/texmf$\|/thunderbird$\|/trans$\|\
				/tuxmath$\|/tuxtype$\|/vim$\|/wallpapers$\|/xfig$\|/xml$\|/xul-ext$\|/zsh$" \
			| grep -v -e "/edict$\|/fonts$\|/icons$\|/kiten$\|/locale$\|/qt4$" \
			| sort -u | awk '{print $1"/";}' > ../filelist.txt
		rm -f ../KNOPPIX_FS.tmp ../KNOPPIX1_FS.tmp
		# ---------------------------------------------------------------------
		xorriso -as mkisofs                 \
		    -D -R -U -V "${LIVE_VOLID_FS}"  \
		    -o ../KNOPPIX_FS.tmp            \
		    -exclude-list ../filelist.txt   \
		    .
		# ---------------------------------------------------------------------
		xorriso -as mkisofs                 \
		    -D -R -U -V "${LIVE_VOLID_FS1}" \
		    -o ../KNOPPIX1_FS.tmp           \
		    -path-list ../filelist.txt
		# ---------------------------------------------------------------------
		rm -f ../filelist.txt
	popd > /dev/null
	# -------------------------------------------------------------------------
	create_compressed_fs -B 128K -t 4 -f ./isotemp  -q -L 9 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX  < ./knoppix-live/KNOPPIX_FS.tmp
	create_compressed_fs -B 128K -t 4 -f ./isotemp1 -q -L 9 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 < ./knoppix-live/KNOPPIX1_FS.tmp
	ls -lh ./knoppix-live/cdimg/KNOPPIX/KNOPPIX*
	# -------------------------------------------------------------------------
	cp ./knoppix-live/efiboot.img ./knoppix-live/cdimg/
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/cdimg/efiboot.img ./knoppix-live/media
	sed -i ./knoppix-live/media/boot/syslinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/media/boot/syslinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		xorriso -as mkisofs                                     \
		        -D -R -U -V "${LIVE_VOLID}"                     \
		        -o ../../${LIVE_DEST}                           \
		        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin   \
		        -b boot/isolinux/isolinux.bin                   \
		        -c boot/isolinux/boot.cat                       \
		        -no-emul-boot                                   \
		        -boot-load-size 4                               \
		        -boot-info-table                                \
		        -iso-level 4                                    \
		        -eltorito-alt-boot -e efiboot.img -no-emul-boot \
		        .
	popd > /dev/null
	ls -lh KNOPPIX*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
