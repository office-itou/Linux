#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V9.1DVD-2021-01-25-EN.iso]                     *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V9.1DVD-2021-01-25-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
#	apt-get update && apt-get -y install debootstrap xorriso isolinux
# == initial processing =======================================================
	umount -lf ./knoppix-live/media         > /dev/null 2>&1
	umount -lf ./knoppix-live/fsimg/sys     > /dev/null 2>&1
	umount -lf ./knoppix-live/fsimg/proc    > /dev/null 2>&1
	umount -lf ./knoppix-live/fsimg/dev/pts > /dev/null 2>&1
	umount -lf ./knoppix-live/fsimg/dev     > /dev/null 2>&1
	# -------------------------------------------------------------------------
	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg ./knoppix-live/_work ./knoppix-live/_wrk0 ./knoppix-live/_wrk1 ./knoppix-live/KNOPPIX_FS.tmp ./knoppix-live/KNOPPIX1_FS.tmp
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg ./knoppix-live/_work ./knoppix-live/_wrk0 ./knoppix-live/_wrk1
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed 's/^ //g' > ./knoppix-live/fsimg/knoppix-setup.sh
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
		# -----------------------------------------------------------------------------
		 	dpkg --audit
		 	dpkg --configure -a
		# -----------------------------------------------------------------------------
		 	export DEBIAN_FRONTEND=noninteractive
		 	APT_OPTIONS="-o Dpkg::Options::=--force-confdef    \
		 	             -o Dpkg::Options::=--force-confnew    \
		 	             -o Dpkg::Options::=--force-overwrite"
		 	apt-mark hold                                                                                           \
		 	    firmware-ipw2x00                                                                                    || fncEnd $?
		 	apt-get update                                                                                          || fncEnd $?
		 	apt-get upgrade      -q -y ${APT_OPTIONS}                                                               || fncEnd $?
		 	apt-get dist-upgrade -q -y ${APT_OPTIONS}                                                               || fncEnd $?
		 	apt-get install      -q -y ${APT_OPTIONS} --auto-remove                                                 \
		 	    chrony bind9utils dnsutils                                                                          \
		 	    task-desktop task-laptop task-lxde-desktop                                                          \
		 	    task-japanese task-japanese-desktop ibus-mozc mozc-utils-gui fonts-noto                             \
		 	    libreoffice-help-ja libreoffice-l10n-ja                                                             \
		 	    open-vm-tools open-vm-tools-desktop                                                                 || fncEnd $?
		 	apt-get autoremove   -q -y                                                                              || fncEnd $?
		 	apt-get autoclean    -q -y                                                                              || fncEnd $?
		 	apt-get clean        -q -y                                                                              || fncEnd $?
		 	export -n DEBIAN_FRONTEND
		# -- open vm tools ------------------------------------------------------------
		 	echo "--- open vm tools -------------------------------------------------------------"
		 	# mkdir -p /media/hgfs
		 	echo -e '# Added by User\n' \
		 	        '.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,noauto,users,defaults 0 0' \
		 	>> /etc/fstab
		# -- clamav -------------------------------------------------------------------
		 	echo "--- clamav --------------------------------------------------------------------"
		 	sed -i /etc/clamav/freshclam.conf \
		 	    -e 's/^NotifyClamd/#&/'
		# -- sshd ---------------------------------------------------------------------
		 	echo "--- sshd ----------------------------------------------------------------------"
		 	mkdir -p /run/sshd
		 	cat /etc/ssh/sshd_config.ucf-dist             | \
		 	sed -e '$a \\n# --- user settings ---'          \
		 	    -e '$a PermitRootLogin no'                  \
		 	    -e '$a PubkeyAuthentication yes'            \
		 	    -e '$a PasswordAuthentication yes'          \
		 	> /etc/ssh/sshd_config
		 	if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
		 		sed -i /etc/ssh/sshd_config                     \
		 		    -e '$a PubkeyAcceptedAlgorithms +ssh-rsa'   \
		 		    -e '$a HostkeyAlgorithms +ssh-rsa'
		 	fi
		#	ssh-keygen -N "" -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key
		#	ssh-keygen -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
		# -- samba --------------------------------------------------------------------
		 	echo "--- samba ---------------------------------------------------------------------"
		 	testparm -s /etc/samba/smb.conf.ucf-dist | sed -e '/global/ ados charset = CP932\nclient ipc min protocol = NT1\nclient min protocol = NT1\nserver min protocol = NT1\n' > ./smb.conf
		 	testparm -s ./smb.conf > /etc/samba/smb.conf
		 	rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
		# -- root and user's setting --------------------------------------------------
		 	echo "--- root and user's setting ---------------------------------------------------"
		 	smbpasswd -a knoppix -n
		 	echo -e "knoppix\nknoppix\n" | passwd knoppix
		 	echo -e "knoppix\nknoppix\n" | smbpasswd knoppix
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
		 				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
		 				set nowrap              " This option changes how text is displayed.
		 				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
		 				set laststatus=2        " The value of this option influences when the last window will have a status line always.
		 				syntax on               " Vim5 and later versions support syntax highlighting.
		_EOT_
		 			if [ "${USER_NAME}" != "skel" ]; then
		 				chown ${USER_NAME}. .vimrc
		 			fi
		 			echo "--- .curlrc -------------------------------------------------------------------"
		 			cat <<- _EOT_ > .curlrc
		 				location
		 				progress-bar
		 				remote-time
		 				show-error
		_EOT_
		 			if [ "${USER_NAME}" != "skel" ]; then
		 				chown ${USER_NAME}. .curlrc
		 			fi
		 			if [ "${USER_NAME}" != "skel" ]; then
		 				echo "--- xinput.d ------------------------------------------------------------------"
		 				mkdir .xinput.d
		 				ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
		 				chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
		 			fi
		 			echo "--- .credentials --------------------------------------------------------------"
		 			cat <<- _EOT_ > .credentials
		 				username=value
		 				password=value
		 				domain=value
		_EOT_
		 			if [ "${USER_NAME}" != "skel" ]; then
		 				chown ${USER_NAME}. .credentials
		 				chmod 0600 .credentials
		 			fi
		 		popd > /dev/null
		 	done
		# -- cleaning -----------------------------------------------------------------
		 	echo "--- cleaning ------------------------------------------------------------------"
		 	fncEnd 0
		# -- EOF ----------------------------------------------------------------------
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
	echo "--- DVD -> HDD ----------------------------------------------------------------"
	mount -r -o loop ./${LIVE_FILE} ./knoppix-live/media
	cp -pr ./knoppix-live/media/* ./knoppix-live/cdimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	echo "--- Change minirt.gz ----------------------------------------------------------"
	pushd ./knoppix-live/_work > /dev/null
		zcat ../cdimg/boot/isolinux/minirt.gz | cpio -idm --quiet
		mkdir -p media/hgfs
		chown knoppix.knoppix media/hgfs
		find . | cpio -H newc -o --quiet | gzip -9 > ../cdimg/boot/isolinux/minirt.gz
	popd > /dev/null
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX_FS.iso ]; then
		echo "--- Extract KNOPPIX -----------------------------------------------------------"
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/KNOPPIX_FS.iso
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX1_FS.iso ]; then
		echo "--- Extract KNOPPIX1 ----------------------------------------------------------"
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 ./knoppix-live/KNOPPIX1_FS.iso
	fi
	# -------------------------------------------------------------------------
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX  \
	      ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1
	rm -f ./knoppix-live/KNOPPIX_FS.txt  \
	      ./knoppix-live/KNOPPIX1_FS.txt
	# -------------------------------------------------------------------------
	echo "--- KNOPPIX_FS.iso -> HDD -----------------------------------------------------"
	mount -r -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	find ./knoppix-live/media/ -print | sort -u | sed -e 's~./knoppix-live/media/~~g' > ./knoppix-live/KNOPPIX_FS.txt
	cp -pr ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	echo "--- KNOPPIX1_FS.iso -> HDD ----------------------------------------------------"
	mount -r -o loop ./knoppix-live/KNOPPIX1_FS.iso ./knoppix-live/media
	find ./knoppix-live/media/ -print |sort -u | sed -e 's~./knoppix-live/media/~~g' > ./knoppix-live/KNOPPIX1_FS.txt
	cp -pr ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
# =============================================================================
	echo "--- Customize HDD [chroot] ----------------------------------------------------"
	# -------------------------------------------------------------------------
#	ln -fs /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
#	sed -i ./knoppix-live/fsimg/etc/adjtime  \
#	    -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/ntp.conf      \
	    -e 's/^\(pool\)/#\1/g'                    \
	    -e '/^# pool:/ a pool ntp.nict.jp iburst'
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/fsimg/etc/rc.local                                      \
	    -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 rsyslog named ssh smbd nmbd"/g'
	# -------------------------------------------------------------------------
	sed -i.orig ./knoppix-live/fsimg/etc/resolv.conf  \
	    -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
	sed -i.orig ./knoppix-live/fsimg/etc/apt/sources.list             \
	    -e 's/ftp.de.debian.org/deb.debian.org/g'                     \
	    -e 's~^\(deb http://debian-knoppix.alioth.debian.org\)~#\1~g' \
	    -e 's~\(security.debian.org\)~\1/debian-security~g'           \
	    -e '/security.debian.org/ s/stable/stable-security/g'         \
	    -e '/security.debian.org/a deb http://security.debian.org/debian-security testing-security main contrib non-free' \
	    -e '/^deb.*oldstable/i deb http://deb.debian.org/debian oldoldstable main contrib non-free' \
	    -e 's~^\(deb .* experimental\)~#\1~g' \
	    -e 's~^\(deb .* unstable\)~#\1~g'
#	    -e 's~^\(deb .* testing\)~#\1~g'
	# -------------------------------------------------------------------------
#	sed -i /etc/NetworkManager/NetworkManager.conf \
#	    -e 's/\(managed\)=.*$/\1=false/'
	# -------------------------------------------------------------------------
	mount --bind /dev     ./knoppix-live/fsimg/dev
	mount --bind /dev/pts ./knoppix-live/fsimg/dev/pts
	mount --bind /proc    ./knoppix-live/fsimg/proc
	mount --bind /sys     ./knoppix-live/fsimg/sys
	# -------------------------------------------------------------------------
	chroot ./knoppix-live/fsimg /bin/bash /knoppix-setup.sh $1 $2
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount ./knoppix-live/fsimg/sys     || umount -lf ./knoppix-live/fsimg/sys
	umount ./knoppix-live/fsimg/proc    || umount -lf ./knoppix-live/fsimg/proc
	umount ./knoppix-live/fsimg/dev/pts || umount -lf ./knoppix-live/fsimg/dev/pts
	umount ./knoppix-live/fsimg/dev     || umount -lf ./knoppix-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	mv ./knoppix-live/fsimg/etc/resolv.conf.orig ./knoppix-live/fsimg/etc/resolv.conf
	find   ./knoppix-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb \
	       ./knoppix-live/fsimg/knoppix-setup.sh
# =============================================================================
	echo "--- Remaster HDD -> Compress --------------------------------------------------"
	# -------------------------------------------------------------------------
	if [ "${OS_ARCH}" = "i386" ] || [ "`which volname`" = "" ]; then
		LIVE_VOLID="KNOPPIX_9"
		LIVE_VOLID_FS="KNOPPIX_FS"
		LIVE_VOLID_FS1="KNOPPIX_ADDONS1"
	else
		LIVE_VOLID=`volname ./${LIVE_FILE}`
		LIVE_VOLID_FS=`volname ./knoppix-live/KNOPPIX_FS.iso`
		LIVE_VOLID_FS1=`volname ./knoppix-live/KNOPPIX1_FS.iso`
	fi
	# -------------------------------------------------------------------------
	rm -rf ./knoppix-live/_work/* \
	       ./knoppix-live/_wrk0/* \
	       ./knoppix-live/_wrk1/*
	# -------------------------------------------------------------------------
	pushd ./knoppix-live/fsimg > /dev/null
		echo "--- Remaster HDD -> Compress [_wrk0] ------------------------------------------"
		while read f
		do
			if [ -e "$f" ]; then
				echo "$f" | cpio -pdlm --quiet "../_wrk0/"
				if [ ! -d "$f" ]; then
					rm -f "$f"
				fi
			fi
		done < ../KNOPPIX_FS.txt
		echo "--- Remaster HDD -> Compress [_wrk1] ------------------------------------------"
		while read f
		do
			if [ -e "$f" ]; then
				echo "$f" | cpio -pdlm --quiet "../_wrk1/"
				if [ ! -d "$f" ]; then
					rm -f "$f"
				fi
			fi
		done < ../KNOPPIX1_FS.txt
		cp -prnd * "../_wrk0/"
		rm -rf *
		echo "--- Remaster HDD -> Compress [xorriso] ----------------------------------------"
		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS}"  -o ../KNOPPIX_FS.tmp  "../_wrk0/" || exit 1
		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS1}" -o ../KNOPPIX1_FS.tmp "../_wrk1/" || exit 1
	popd > /dev/null
	# -------------------------------------------------------------------------
	rm -rf ./knoppix-live/_work/* \
	       ./knoppix-live/_wrk0/* \
	       ./knoppix-live/_wrk1/*
	# -------------------------------------------------------------------------
	echo "--- Remaster HDD -> Compress [create_compressed_fs] -------------------------------"
	create_compressed_fs -L  9 -f ./knoppix-live/isotemp -q ./knoppix-live/KNOPPIX_FS.tmp  ./knoppix-live/cdimg/KNOPPIX/KNOPPIX  || exit 1
	create_compressed_fs -L  9 -f ./knoppix-live/isotemp -q ./knoppix-live/KNOPPIX1_FS.tmp ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 || exit 1
	rm -rf ./knoppix-live/KNOPPIX_FS.tmp  \
	       ./knoppix-live/KNOPPIX1_FS.tmp
	ls -lh ./knoppix-live/cdimg/KNOPPIX/KNOPPIX*
	# -------------------------------------------------------------------------
	cp ./knoppix-live/efiboot.img ./knoppix-live/cdimg/
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 utc tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 utc tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 utc tz=Asia\/Tokyo/g'
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/cdimg/efiboot.img ./knoppix-live/media
	sed -i ./knoppix-live/media/boot/syslinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 utc tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/media/boot/syslinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 utc tz=Asia\/Tokyo/g'
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	echo "--- Remaster HDD -> ISO Image -------------------------------------------------"
	# -------------------------------------------------------------------------
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		xorriso -as mkisofs \
		    -iso-level 3 \
		    -full-iso9660-filenames \
		    -volid "${LIVE_VOLID}" \
		    -eltorito-boot "boot/isolinux/isolinux.bin" \
		    -eltorito-catalog "boot/isolinux/boot.cat" \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr "/usr/lib/ISOLINUX/isohdpfx.bin" \
		    -eltorito-alt-boot \
		    -e "efiboot.img" \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "../../${LIVE_DEST}" \
		    .
	popd > /dev/null
	ls -lh KNOPPIX*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
